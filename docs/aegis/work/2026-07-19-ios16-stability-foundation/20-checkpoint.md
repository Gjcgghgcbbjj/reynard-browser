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

## Checkpoint Update

- Current todo: Task 4: add bounded JIT retry and two-action failure UI
- Active slice: Task 4 JIT retry state and UI
- Completed todos:
- Task 1: portable stability core, commit 511a6cd
- Task 2: diagnostics/redaction, commit 0a21668; Xcode verification pending
- Task 3: crash/kill session recovery preserves tabs, commit b6ad790; device verification pending
- Evidence refs:
- 18 Swift tests passed
- All modified Swift files parsed with Swift 6.1 frontend
- Structural assertion confirms onCrash/onKill contain no removeTab call
- commit b6ad790
- Blocked on: Xcode compile and physical Gecko crash/kill injection require macOS/iOS
- Next step: Replace terminal JIT failure flag with explicit retry policy and two-action UI

## DriftCheckDraft

- Scope status: Task 3 implemented the planned tab-preserving crash/kill recovery and native stable failure state
- Compatibility status: Tab identity/data owners preserved; no schema change or WebKit fallback; Xcode/device behavior unverified
- Retirement status: removeTab retired from onCrash and onKill with no deletion fallback retained
- New risk signals:
- Replacement session behavior and overlay interaction require physical-device evidence
- Advisory decision: continue

## Checkpoint Update

- Current todo: Task 5: replace recoverable startup migration crashes with typed outcomes
- Active slice: Task 5 typed startup migration outcomes
- Completed todos:
- Task 1: portable stability core, commit 511a6cd
- Task 2: diagnostics/redaction, commit 0a21668; Xcode verification pending
- Task 3: crash/kill session recovery preserves tabs, commit b6ad790; device verification pending
- Task 4: bounded JIT retry and selected-session recreation, commit 2ef79a1; device verification pending
- Evidence refs:
- 19 Swift tests passed
- Modified app Swift files parsed with Swift 6.1 frontend
- Localization JSON and Retry JIT translations validated
- commit 2ef79a1
- Blocked on: Xcode compile and physical JIT retry simulation require macOS/iOS
- Next step: Read UserDataMigration and FileMigration policy, then add temporary-directory tests before replacing migration fatalError paths

## DriftCheckDraft

- Scope status: Task 4 stayed within bounded JIT recovery and selected GeckoSession recreation
- Compatibility status: Tab identity, Gecko rendering, JIT-less mode, and existing persistence owners remain unchanged; Xcode/device behavior is unverified
- Retirement status: Terminal hasHandledFailure state was removed and no parallel retry owner was introduced
- New risk signals:
- Notification-to-session recreation timing and successful JIT reattachment require physical-device evidence
- Advisory decision: continue

## Checkpoint Update

- Current todo: Task 6: harden tab persistence and lifecycle flushing
- Active slice: Task 6 lifecycle persistence flush
- Completed todos:
- Task 1: portable stability core, commit 511a6cd
- Task 2: diagnostics/redaction, commit 0a21668; Xcode verification pending
- Task 3: crash/kill session recovery preserves tabs, commit b6ad790; device verification pending
- Task 4: bounded JIT retry and selected-session recreation, commit 2ef79a1; device verification pending
- Task 5: verified recoverable startup migration, commit 1d47791; Xcode/manual UI verification pending
- Evidence refs:
- 24 Swift tests passed
- Interrupted migration retry harness passed
- Diagnostics migration integration typechecked with Gecko stub
- commit 1d47791
- Blocked on: Xcode compile, startup failure UI inspection, and device migration simulation require macOS/iOS
- Next step: Read TabManagementStore queue/transaction behavior and add pure LifecycleFlushPolicy tests before wiring Scene lifecycle callbacks

## DriftCheckDraft

- Scope status: Task 5 stayed within startup migration reliability and required a dedicated blocking recovery view at the scene root
- Compatibility status: Destination folder names and store schemas remain unchanged; source data is retained until hashed inventory verification; Gecko and WebKit boundaries unchanged
- Retirement status: Recoverable migration fatalError paths were removed; no alternate store or migration database was introduced
- New risk signals:
- The added SceneDelegate recovery-root path and full directory fingerprint cost require Xcode and device timing verification
- Advisory decision: continue

## Checkpoint Update

- Current todo: Task 7: add repeatable CI and iOS 16 device evidence
- Active slice: Task 7 CI workflow, packaging path, and device checklist
- Completed todos:
- Task 1: portable stability core, commit 511a6cd
- Task 2: diagnostics/redaction, commit 0a21668; Xcode verification pending
- Task 3: crash/kill session recovery preserves tabs, commit b6ad790; device verification pending
- Task 4: bounded JIT retry and selected-session recreation, commit 2ef79a1; device verification pending
- Task 5: verified recoverable startup migration, commit 1d47791; Xcode/manual UI verification pending
- Task 6: bounded lifecycle tab persistence flush, commit bba9b72; device termination verification pending
- Evidence refs:
- 28 Swift tests passed
- LifecycleFlushPolicy typechecked and four policy scenarios passed
- Store/TabManager/Scene modified files parsed
- commit bba9b72
- Blocked on: Full Xcode build and ten forced-termination cycles require macOS/iOS
- Next step: Add macOS stability-core workflow, iOS 16 evidence checklist, and README build/test instructions; validate shell, plist, YAML, and package commands locally

## DriftCheckDraft

- Scope status: Task 6 implemented the planned completion-bearing tab transaction and bounded lifecycle flush without changing normal interaction persistence
- Compatibility status: SQLite schema and transaction content remain unchanged; main-thread blocking was not introduced; diagnostics remain observer-only
- Retirement status: Fire-and-forget persistence is retired only at resign-active/background boundaries; normal async persistence remains canonical
- New risk signals:
- UIBackgroundTask and SQLite completion timing require physical forced-termination evidence
- Advisory decision: continue
