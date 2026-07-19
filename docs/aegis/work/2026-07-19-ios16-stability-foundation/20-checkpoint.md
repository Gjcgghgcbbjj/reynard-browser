# iOS 16 Stability Foundation Execution - Checkpoint

- Task ID: 2026-07-19-ios16-stability-foundation
- Current todo: Task 1: add portable stability core and tests
- Active slice: Task 1 stability policy core
- Blocked on: Swift/Xcode verification unavailable on this host
- Next step: Create Package.swift, policy types, and tests

## Checkpoint Update

- Current todo: Task 2: add privacy-safe runtime diagnostics and startup instrumentation
- Active slice: Task 2 diagnostics and URL redaction
- Completed todos:
- Task 1: portable stability core and 14 tests committed as 511a6cd
- Evidence refs:
- docker swift:6.1-noble swift test: 14 tests, 0 failures
- commit 511a6cd
- Blocked on: Xcode/iOS app compilation and physical device verification remain unavailable on WSL
- Next step: Add URL redaction tests and StabilityDiagnostics runtime owner

## DriftCheckDraft

- Scope status: Task 1 stayed inside the planned Foundation-only stability core
- Compatibility status: No UIKit, Gecko, persistence, iOS minimum, or rendering path changed
- Retirement status: No retirement action was due in Task 1
- New risk signals:
- Initial RED run was unavailable on host; Docker Swift was added before final GREEN verification
- Advisory decision: continue

## Checkpoint Update

- Current todo: Task 3: preserve tabs and recover Gecko content-process failures
- Active slice: Task 3 content process recovery
- Completed todos:
- Task 1: portable stability core, 14 tests, commit 511a6cd
- Task 2: diagnostics/redaction source, 18 tests, commit 0a21668; Xcode/manual verification pending
- Evidence refs:
- Docker Swift tests: 18 tests, 0 failures
- StabilityDiagnostics typechecked with stub GeckoView; modified UIKit files parsed successfully
- Localizable.xcstrings parsed as JSON
- commit 0a21668
- Blocked on: Xcode compile and Settings export manual check require macOS/iOS
- Next step: Replace onCrash/onKill tab deletion with canonical session recovery

## DriftCheckDraft

- Scope status: Task 2 stayed within diagnostics, redaction, startup instrumentation, and settings export scope
- Compatibility status: No rendering/session/persistence schema behavior changed; iOS app compile remains unverified
- Retirement status: No runtime fallback or old owner introduced; diagnostics remains observer-only
- New risk signals:
- UIKit and Gecko integration cannot be typechecked fully without Xcode/macOS
- Advisory decision: continue
