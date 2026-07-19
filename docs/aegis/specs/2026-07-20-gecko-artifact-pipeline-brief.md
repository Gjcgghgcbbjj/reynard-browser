# Gecko iOS Prebuilt Artifact Pipeline Brief

Date: `2026-07-20`
Status: `approved for implementation`

## Goal

Compile the pinned, patched Gecko iOS arm64 engine once and reuse its verified
`dist` output across later IPA packaging runs, so Swift/UI-only changes do not
repeat a one-to-three-hour Gecko build.

## Requirements

- A dedicated manual GitHub Actions workflow owns Gecko source fetch,
  bootstrap, patch application, compilation, and prebuilt artifact upload.
- The artifact identity must change when `engine/release.txt`, any file under
  `patches/`, the Gecko build script, the artifact contract script, or the
  selected Xcode version changes.
- The IPA workflow must download an exact matching, unexpired artifact. A miss
  is an explicit failure with instructions to run the Gecko workflow; it must
  not silently perform another full Gecko compilation.
- The payload must include `obj-aarch64-apple-ios/dist` and the pinned default
  theme source required by `browser/Scripts/AddGecko.sh`.
- Restore must verify the manifest key, required XUL/include payload, archive
  member safety, and archive integrity before Xcode is invoked.
- Existing unsigned IPA, TrollStore TIPA, jailbroken IPA, iOS deployment target,
  Gecko patches, and app runtime ownership remain unchanged.

## Owners and Contract

- `tools/development/gecko-artifact.sh` is the canonical owner of artifact key,
  pack, restore, and verification semantics.
- `.github/workflows/build-gecko-ios.yml` produces the artifact.
- `.github/workflows/build-ipa.yml` consumes it and owns only application
  packaging after restore.
- GitHub Actions artifact storage is a build cache/distribution surface, not a
  source-of-truth replacement for the pinned Gecko tag and patches.

## Acceptance

- Artifact shell contract passes fixture-based key-change, pack, restore,
  corruption/mismatch, and required-payload checks.
- Both workflows pass `actionlint`; all modified shell scripts pass syntax and
  `shellcheck` where available.
- The dedicated Gecko workflow uploads a named prebuilt artifact, and a later
  IPA workflow restores the same key without running Gecko bootstrap/build.
- A remote IPA run produces the existing three packages and checksum file.

## Non-goals

- Do not cache or publish a signed App Store build.
- Do not change Gecko source ownership, runtime capabilities, or app data.
- Do not promise indefinite artifact retention; regeneration remains manual and
  deterministic.

## Architecture Review Signal

`ArchitectureReviewRequired: yes` because this introduces a durable build
artifact contract and separates producer/consumer workflow ownership.
