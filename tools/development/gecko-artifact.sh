#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DEFAULT_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
ROOT_DIR="${REYNARD_ROOT_DIR:-$DEFAULT_ROOT}"
GECKO_DIST_REL="engine/firefox/obj-aarch64-apple-ios/dist"
DEFAULT_THEME_REL="engine/firefox/toolkit/mozapps/extensions/default-theme"
MANIFEST_REL="dist/gecko-artifact-manifest.txt"
FORMAT_VERSION="1"

usage() {
	cat >&2 <<'EOF'
Usage:
  gecko-artifact.sh key <xcode-app>
  gecko-artifact.sh pack <archive.tar.gz> <xcode-app>
  gecko-artifact.sh restore <archive.tar.gz> <xcode-app>
  gecko-artifact.sh verify <xcode-app>
EOF
	exit 64
}

die() {
	echo "Gecko artifact error: $*" >&2
	exit 1
}

require_file() {
	[ -f "$1" ] || die "missing file: $1"
}

require_directory() {
	[ -d "$1" ] || die "missing directory: $1"
}

artifact_key() {
	xcode_app="$1"
	require_file "$ROOT_DIR/engine/release.txt"
	require_file "$ROOT_DIR/tools/development/build-gecko.sh"
	require_file "$SCRIPT_DIR/gecko-artifact.sh"
	require_directory "$ROOT_DIR/patches"

	digest="$({
		printf 'format=%s\n' "$FORMAT_VERSION"
		printf 'xcode=%s\n' "$xcode_app"
		printf 'release=' && tr -d '\000\r\n' < "$ROOT_DIR/engine/release.txt" && printf '\n'
		(
			cd "$ROOT_DIR"
			find patches -type f -name '*.patch' -print | LC_ALL=C sort | while IFS= read -r patch; do
				printf '%s ' "$patch"
				shasum -a 256 "$patch"
			done
		)
		printf 'build-script ' && shasum -a 256 "$ROOT_DIR/tools/development/build-gecko.sh"
		printf 'artifact-contract ' && shasum -a 256 "$SCRIPT_DIR/gecko-artifact.sh"
	} | shasum -a 256 | awk '{print $1}')"

	printf 'reynard-gecko-ios-arm64-v%s-%s\n' "$FORMAT_VERSION" "$digest"
}

manifest_value() {
	key="$1"
	manifest="$2"
	sed -n "s/^${key}=//p" "$manifest" | tail -n 1
}

verify_payload() {
	payload_root="$1"
	expected_key="$2"
	manifest="$payload_root/$MANIFEST_REL"

	require_file "$manifest"
	actual_format="$(manifest_value format "$manifest")"
	actual_key="$(manifest_value key "$manifest")"
	[ "$actual_format" = "$FORMAT_VERSION" ] || die "unsupported manifest format: $actual_format"
	[ "$actual_key" = "$expected_key" ] || die "artifact key mismatch: expected $expected_key, got $actual_key"

	require_file "$payload_root/$GECKO_DIST_REL/bin/XUL"
	require_directory "$payload_root/$GECKO_DIST_REL/include"
	find "$payload_root/$GECKO_DIST_REL/include" -type f -print -quit | grep -q . || die "Gecko include payload is empty"
	require_directory "$payload_root/$DEFAULT_THEME_REL"
	find "$payload_root/$DEFAULT_THEME_REL" -type f -print -quit | grep -q . || die "default theme payload is empty"
}

pack_artifact() {
	archive="$1"
	xcode_app="$2"
	expected_key="$(artifact_key "$xcode_app")"

	require_file "$ROOT_DIR/$GECKO_DIST_REL/bin/XUL"
	require_directory "$ROOT_DIR/$GECKO_DIST_REL/include"
	require_directory "$ROOT_DIR/$DEFAULT_THEME_REL"

	mkdir -p "$ROOT_DIR/dist" "$(dirname -- "$archive")"
	cat > "$ROOT_DIR/$MANIFEST_REL" <<EOF
format=$FORMAT_VERSION
key=$expected_key
xcode=$xcode_app
release=$(tr -d '\000\r\n' < "$ROOT_DIR/engine/release.txt")
EOF

	tar -czf "$archive" \
		-C "$ROOT_DIR" \
		"$GECKO_DIST_REL" \
		"$DEFAULT_THEME_REL" \
		"$MANIFEST_REL"

	[ -s "$archive" ] || die "archive was not created: $archive"
	verify_payload "$ROOT_DIR" "$expected_key"
}

restore_artifact() {
	archive="$1"
	xcode_app="$2"
	require_file "$archive"
	expected_key="$(artifact_key "$xcode_app")"
	stage="$(mktemp -d "$ROOT_DIR/.gecko-artifact-stage.XXXXXX")"
	trap 'rm -rf "$stage"' EXIT HUP INT TERM

	python3 - "$archive" "$stage" <<'PY'
from pathlib import PurePosixPath
import sys
import tarfile

archive_path, destination = sys.argv[1:]
allowed = (
    PurePosixPath("engine/firefox/obj-aarch64-apple-ios/dist"),
    PurePosixPath("engine/firefox/toolkit/mozapps/extensions/default-theme"),
    PurePosixPath("dist/gecko-artifact-manifest.txt"),
)

def is_allowed(path: PurePosixPath) -> bool:
    return any(path == prefix or prefix in path.parents for prefix in allowed)

with tarfile.open(archive_path, "r:gz") as archive:
    for member in archive.getmembers():
        path = PurePosixPath(member.name)
        if path.is_absolute() or ".." in path.parts or not is_allowed(path):
            raise SystemExit(f"unsafe or unexpected archive member: {member.name}")
    archive.extractall(destination, filter="data")
PY

	verify_payload "$stage" "$expected_key"

	rm -rf \
		"$ROOT_DIR/$GECKO_DIST_REL" \
		"$ROOT_DIR/$DEFAULT_THEME_REL" \
		"$ROOT_DIR/$MANIFEST_REL"
	mkdir -p \
		"$(dirname -- "$ROOT_DIR/$GECKO_DIST_REL")" \
		"$(dirname -- "$ROOT_DIR/$DEFAULT_THEME_REL")" \
		"$(dirname -- "$ROOT_DIR/$MANIFEST_REL")"
	mv "$stage/$GECKO_DIST_REL" "$ROOT_DIR/$GECKO_DIST_REL"
	mv "$stage/$DEFAULT_THEME_REL" "$ROOT_DIR/$DEFAULT_THEME_REL"
	mv "$stage/$MANIFEST_REL" "$ROOT_DIR/$MANIFEST_REL"

	verify_payload "$ROOT_DIR" "$expected_key"
	rm -rf "$stage"
	trap - EXIT HUP INT TERM
}

[ "$#" -ge 1 ] || usage
command="$1"
shift

case "$command" in
	key)
		[ "$#" -eq 1 ] || usage
		artifact_key "$1"
		;;
	pack)
		[ "$#" -eq 2 ] || usage
		pack_artifact "$1" "$2"
		;;
	restore)
		[ "$#" -eq 2 ] || usage
		restore_artifact "$1" "$2"
		;;
	verify)
		[ "$#" -eq 1 ] || usage
		verify_payload "$ROOT_DIR" "$(artifact_key "$1")"
		;;
	*)
		usage
		;;
esac
