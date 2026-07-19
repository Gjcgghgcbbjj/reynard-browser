# Gecko iOS Prebuilt Artifact Pipeline Implementation Plan

## Goal

Split Gecko compilation from IPA packaging and make exact-match prebuilt Gecko
reuse deterministic and verified.

## Architecture

One shell contract owns artifact identity and payload validation. A manual Gecko
producer workflow uploads a 90-day artifact; the IPA consumer workflow locates
that exact artifact through the GitHub Actions API, restores it, then builds only
idevice and the Xcode application.

## Tech Stack

POSIX shell, `tar`, SHA-256, GitHub Actions, GitHub CLI/API, Xcode 26.4.1,
Firefox/Gecko 152, `actionlint`.

## Baseline/Authority Refs

- `docs/aegis/specs/2026-07-20-gecko-artifact-pipeline-brief.md`
- `docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md`
- `docs/aegis/work/2026-07-19-ios16-stability-foundation/20-checkpoint.md`
- `README.md` build and release packaging sections

## Compatibility Boundary

Keep the pinned Gecko tag/patch set, iOS deployment target, archive layout,
bundle IDs, unsigned/TrollStore signing behavior, and three package names.

## Verification

- Fixture tests for key stability/change, safe pack/restore, manifest mismatch,
  and required payload checks.
- `sh -n`, `shellcheck`, `actionlint`, `git diff --check`.
- Existing portable Swift tests and source parsing.
- Remote producer artifact upload followed by remote IPA consumer build.

## Requirement Ready Check

- Requirement source: user-approved recommendation in the active build session.
- Scenario: frequent Swift/UI builds must not rebuild unchanged Gecko.
- Acceptance: exact artifact reuse and successful IPA output.
- Decision: `ready`.

## Architecture Integrity Lens

- Invariant: source tag plus patches remain authoritative.
- Canonical contract owner: `tools/development/gecko-artifact.sh`.
- No responsibility overlap: producer compiles; consumer restores/packages.
- Retirement: remove Gecko fetch/bootstrap/patch/build from the IPA workflow.
- Verdict: aligned.

## Complexity Budget

- Artifact class: CI workflow and release helper.
- Pressure: current IPA workflow owns both multi-hour engine compilation and
  short app packaging.
- Result: `within-budget` by splitting owners and centralizing the artifact
  contract.

## Tasks

### Task 1 — Artifact contract helper

**Files:** create `tools/development/gecko-artifact.sh` and
`tools/development/test-gecko-artifact.sh`.

**Why:** make key and payload behavior independently testable rather than YAML
owned.

**Verification:** run the fixture test plus shell syntax and shellcheck.

- [ ] Write fixture checks that fail before the helper exists.
- [ ] Implement `key`, `pack`, `restore`, and `verify` commands.
- [ ] Verify key changes and safe exact restore.
- [ ] Confirm corrupt/mismatched payloads fail.
- [ ] Commit the helper slice.

### Task 2 — Dedicated Gecko producer workflow

**Files:** create `.github/workflows/build-gecko-ios.yml`.

**Why:** compile the expensive engine only when explicitly requested.

**Verification:** `actionlint`, shell syntax, and remote workflow dispatch.

- [ ] Add deterministic artifact-name output.
- [ ] Reuse the proven macOS 26/Xcode 26.4 SDK bootstrap path.
- [ ] Build and package Gecko.
- [ ] Upload artifact and logs with explicit retention.
- [ ] Commit the producer workflow.

### Task 3 — Convert IPA workflow to exact consumer

**Files:** modify `.github/workflows/build-ipa.yml`.

**Why:** make ordinary app packaging fast and prevent hidden full rebuilds.

**Verification:** `actionlint`, missing-artifact failure-path inspection, and
remote consumer build.

- [ ] Grant read-only Actions artifact permission.
- [ ] Resolve and download the newest exact artifact key.
- [ ] Restore and verify before Xcode steps.
- [ ] Delete Gecko fetch/bootstrap/patch/build steps from this workflow.
- [ ] Commit the consumer workflow.

### Task 4 — Documentation and end-to-end evidence

**Files:** modify `README.md` and the active Aegis checkpoint/evidence records.

**Why:** document regeneration, retention, and the failure boundary.

**Verification:** documentation links, workspace check, remote producer then
consumer outputs and checksums.

- [ ] Document both manual workflows.
- [ ] Run local regression verification.
- [ ] Dispatch producer and record its artifact key/run.
- [ ] Dispatch consumer and verify all packages.
- [ ] Copy packages to the requested E-drive destination and record residual
  physical-device verification risk.

## Risks

- GitHub artifacts expire; the consumer must fail clearly and regeneration must
  remain deterministic.
- A large Gecko archive may approach storage/upload constraints; archive size is
  measured by the first producer run.
- Remote build success does not replace physical iOS 16 arm64/arm64e testing.

## Retirement

- Retire the full Gecko compilation path from `.github/workflows/build-ipa.yml`.
- Retain local `build-gecko.sh` and source build instructions as the producer and
  developer path.
- Regenerate an artifact whenever its deterministic key changes or it expires.
