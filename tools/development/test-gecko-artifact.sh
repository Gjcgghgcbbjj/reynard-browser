#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
HELPER="$SCRIPT_DIR/gecko-artifact.sh"
FIXTURE="$(mktemp -d)"
trap 'rm -rf "$FIXTURE"' EXIT HUP INT TERM

fail() {
	echo "FAIL: $*" >&2
	exit 1
}

mkdir -p \
	"$FIXTURE/engine/firefox/obj-aarch64-apple-ios/dist/bin" \
	"$FIXTURE/engine/firefox/obj-aarch64-apple-ios/dist/include" \
	"$FIXTURE/engine/firefox/toolkit/mozapps/extensions/default-theme" \
	"$FIXTURE/patches/widget" \
	"$FIXTURE/tools/development"

printf '%s\n' 'FIREFOX_TEST_RELEASE' > "$FIXTURE/engine/release.txt"
printf '%s\n' 'patch-v1' > "$FIXTURE/patches/widget/test.patch"
printf '%s\n' '#!/bin/sh' 'echo build' > "$FIXTURE/tools/development/build-gecko.sh"
printf '%s\n' 'xul' > "$FIXTURE/engine/firefox/obj-aarch64-apple-ios/dist/bin/XUL"
printf '%s\n' 'header' > "$FIXTURE/engine/firefox/obj-aarch64-apple-ios/dist/include/test.h"
printf '%s\n' 'generated-header' > "$FIXTURE/generated-header.h"
ln -s "$FIXTURE/generated-header.h" "$FIXTURE/engine/firefox/obj-aarch64-apple-ios/dist/include/generated.h"
printf '%s\n' 'theme' > "$FIXTURE/engine/firefox/toolkit/mozapps/extensions/default-theme/theme.css"

key_one="$(REYNARD_ROOT_DIR="$FIXTURE" "$HELPER" key Xcode_26.4.1.app)"
key_repeat="$(REYNARD_ROOT_DIR="$FIXTURE" "$HELPER" key Xcode_26.4.1.app)"
[ "$key_one" = "$key_repeat" ] || fail "artifact key is not stable"

printf '%s\n' 'patch-v2' > "$FIXTURE/patches/widget/test.patch"
key_changed="$(REYNARD_ROOT_DIR="$FIXTURE" "$HELPER" key Xcode_26.4.1.app)"
[ "$key_one" != "$key_changed" ] || fail "patch change did not change key"

archive="$FIXTURE/gecko.tar.gz"
REYNARD_ROOT_DIR="$FIXTURE" "$HELPER" pack "$archive" Xcode_26.4.1.app
[ -s "$archive" ] || fail "pack did not create archive"

rm -rf "$FIXTURE/engine/firefox"
REYNARD_ROOT_DIR="$FIXTURE" "$HELPER" restore "$archive" Xcode_26.4.1.app
REYNARD_ROOT_DIR="$FIXTURE" "$HELPER" verify Xcode_26.4.1.app
[ -s "$FIXTURE/engine/firefox/obj-aarch64-apple-ios/dist/bin/XUL" ] || fail "XUL was not restored"
[ -s "$FIXTURE/engine/firefox/toolkit/mozapps/extensions/default-theme/theme.css" ] || fail "theme was not restored"
[ ! -L "$FIXTURE/engine/firefox/obj-aarch64-apple-ios/dist/include/generated.h" ] || fail "absolute header symlink was not dereferenced"
grep -Fqx 'generated-header' "$FIXTURE/engine/firefox/obj-aarch64-apple-ios/dist/include/generated.h" || fail "dereferenced header content was not restored"

if REYNARD_ROOT_DIR="$FIXTURE" "$HELPER" verify Xcode_26.5.app >/dev/null 2>&1; then
	fail "mismatched Xcode key was accepted"
fi

printf '%s\n' 'not a gzip archive' > "$FIXTURE/corrupt.tar.gz"
if REYNARD_ROOT_DIR="$FIXTURE" "$HELPER" restore "$FIXTURE/corrupt.tar.gz" Xcode_26.4.1.app >/dev/null 2>&1; then
	fail "corrupt archive was accepted"
fi

python3 - "$FIXTURE/unsafe.tar.gz" <<'PY'
import io
import sys
import tarfile

with tarfile.open(sys.argv[1], "w:gz") as archive:
    info = tarfile.TarInfo("../reynard-artifact-escape")
    payload = b"escape"
    info.size = len(payload)
    archive.addfile(info, io.BytesIO(payload))
PY

rm -f "$FIXTURE/../reynard-artifact-escape"
if REYNARD_ROOT_DIR="$FIXTURE" "$HELPER" restore "$FIXTURE/unsafe.tar.gz" Xcode_26.4.1.app >/dev/null 2>&1; then
	fail "unsafe archive member was accepted"
fi
[ ! -e "$FIXTURE/../reynard-artifact-escape" ] || fail "unsafe archive escaped root"

echo "Gecko artifact contract tests passed."
