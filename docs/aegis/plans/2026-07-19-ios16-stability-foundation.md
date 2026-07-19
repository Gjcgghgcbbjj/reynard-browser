# iOS 16 Stability Foundation Implementation Plan

## Goal

Pass Gate A from the approved design: preserve tabs when Gecko content
processes crash or are killed, make JIT failure recoverable, harden startup and
tab persistence, and provide privacy-safe diagnostics for iOS 16 TrollStore
builds.

## Architecture

- Add a small Foundation-only stability core under
  `browser/Reynard/StabilityCore/` for deterministic retry, recovery, event,
  and redaction logic.
- Keep runtime ownership unchanged: `JITController` owns JIT, `SessionManager`
  owns Gecko session lifecycle, `TabManagerImplementation` owns live tabs, and
  `TabManagementStore` owns persisted tab snapshots.
- Add one app-level diagnostics owner under `Client/Stability/`; it observes
  owner events but does not become a second lifecycle or persistence owner.
- Recover a failed Gecko content process by replacing the session attached to
  the existing `Tab`. Never delete a tab merely because its content process
  crashed or was killed.

## Tech Stack

- Swift 5.10-compatible Foundation and UIKit
- GeckoView session/delegate bridge
- SQLite-backed existing stores
- Swift Package Manager for Foundation-only tests
- Xcode 16/macOS for app compilation
- TrollStore iOS 16 device verification

## Baseline/Authority Refs

- `docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md`
- `docs/aegis/baseline/2026-07-19-initial-baseline.md`
- `browser/Reynard/JIT/JITController.swift`
- `browser/Reynard/Client/SessionManagement/SessionManager.swift`
- `browser/Reynard/Client/TabManagement/TabManagerImpl.swift`
- `browser/Reynard/Client/Stores/TabManagementStore.swift`
- `browser/Reynard/Client/Startup/UserDataMigration.swift`

## Compatibility Boundary

- Preserve iOS 13 source compatibility where the upstream project already has
  it; Gate A release verification targets iOS 16.
- Preserve arm64 and arm64e builds.
- Preserve existing bookmarks, history, downloads, settings, site permissions,
  and regular-tab records.
- Do not add `WKWebView`, BrowserEngineKit, or a second tab database.
- Do not change CloudKit, Via parity, or Gecko WebExtension behavior in this
  plan. Those are separate plans after Gate A.

## Verification

- Portable logic: `swift test --package-path .`
- App compile on macOS after Gecko framework preparation:

  ```bash
  ./tools/development/update-gecko.sh
  ./tools/development/apply-patches.sh
  ./tools/development/build-idevice.sh
  ./tools/development/build-gecko.sh
  xcodebuild -project browser/Reynard.xcodeproj \
    -scheme Reynard \
    -configuration Debug \
    -destination 'generic/platform=iOS' \
    CODE_SIGNING_ALLOWED=NO build
  ```

- Device checks use `docs/testing/ios16-stability-checklist.md` and an exported
  diagnostic JSON artifact.
- The current WSL host has no Swift or Xcode installation, so Swift/Xcode
  commands must run on macOS or CI; repository structure, scripts, JSON, and
  patch checks remain locally verifiable.

## Plan Basis

- **Fact:** current `onCrash` and `onKill` handlers remove the affected tab.
- **Fact:** current JIT failure UI offers JIT-less mode but no retry action.
- **Fact:** startup migration and several store initializers use `fatalError`
  for recoverable filesystem failures.
- **Fact:** no checked-in unit/UI test target exists.
- **Assumption:** replacing a failed Gecko session while retaining the `Tab` and
  stored navigation is supported by the existing mutable `Tab.session` and
  session factory boundary.
- **Unknown:** device-specific process termination timing and JIT behavior must
  be verified on physical arm64/arm64e devices.

## BaselineUsageDraft

- **Required baseline refs:** approved design, initial baseline, JIT/session/tab
  owner files.
- **Delivered context refs:** user priority for stability/usability, Via parity,
  iOS 16 TrollStore, and optional CloudKit.
- **Acknowledged before plan refs:** current crash handlers, JIT failure flow,
  migration code, tab store, filesystem-synchronized Xcode groups.
- **Cited in plan refs:** header authority refs and file map below.
- **Missing refs:** physical-device crash logs.
- **Decision:** `continue`; diagnostics and device tests are part of this plan.

## Requirement Ready Check

- **Requirement source refs:** approved design and user confirmation to start.
- **Goals and scope refs:** Gate A in the approved design.
- **User / scenario refs:** iOS 16 TrollStore users using Gecko because system
  WebKit is insufficient.
- **Requirement item refs:** approved design sections 7.2, 7.4, 7.6, and 8.
- **Acceptance / verification criteria refs:** approved design section 8.
- **Open blocker questions:** none for source implementation; physical device
  access is required before release completion.
- **Decision:** `ready`.

## Architecture Integrity Lens

- **Invariant:** a content-process failure cannot delete the user's tab or make
  browser controls inaccessible.
- **Canonical owner / contract:** retry policy is pure logic; session replacement
  remains in `TabManagerImplementation`; activation/cleanup remains in
  `SessionManager`; JIT remains in `JITController`.
- **Responsibility overlap:** diagnostics must not trigger recovery, and UI must
  not mutate tab persistence directly.
- **Higher-level simplification:** replace the session attached to the canonical
  `Tab` instead of creating a fallback tab or duplicate restore store.
- **Retirement / falsifier:** retire tab deletion in `onCrash`/`onKill`; if Gecko
  cannot open a replacement session on device, retain the tab and show a stable
  native recovery page.
- **Verdict:** `proceed`.

## Plan Pressure Test

- **Owner / contract / retirement:** owners are explicit; destructive crash-tab
  deletion is retired.
- **Architecture integrity / higher-level path:** recovery is handled at the tab
  and session owner boundary, not in individual views.
- **Verification scope:** pure tests, app compile, and device stress checks are
  all named.
- **Task executability:** each task has exact files, commands, and stop points.
- **Pressure result:** `proceed`.

## Plan-Time Complexity Check

### Complexity Budget

- **Artifact class:** cross-boundary reliability repair.
- **Target files / artifacts:** new stability core, JIT controller/UI, session/tab
  lifecycle, migration, persistence, diagnostics UI, tests, CI/checklist.
- **Current pressure:** `TabManagerImpl.swift` is over 1,200 lines and
  `JITController.swift` mixes state, attachment, watchdogs, and presentation.
- **Projected post-change pressure:** over-budget if policy/state logic is added
  directly to those files.
- **Budget result:** `at-risk`.
- **Planned governance:** place deterministic policy/state in small testable
  files and leave only orchestration at existing owners.

### Plan-Time Complexity Check

- **Target files:** `TabManagerImpl.swift`, `JITController.swift`,
  `TabManagementStore.swift`, `UserDataMigration.swift`.
- **Existing size / shape signals:** large controllers, asynchronous queues,
  process callbacks, and SQLite transactions.
- **Owner fit:** behavior belongs at these owners, while retry/redaction policy
  belongs in the new Foundation-only core.
- **Add-in-place risk:** additional booleans and timers would create state drift.
- **Better file boundary:** `StabilityCore` policies plus one diagnostics owner.
- **Recommendation:** `extract helper` for policy/diagnostics and
  `edit-in-place` for owner orchestration.

## File Map

### Create

- `Package.swift`
- `browser/Reynard/StabilityCore/StabilityEvent.swift`
- `browser/Reynard/StabilityCore/StabilityEventBuffer.swift`
- `browser/Reynard/StabilityCore/URLRedactor.swift`
- `browser/Reynard/StabilityCore/RetryWindow.swift`
- `browser/Reynard/StabilityCore/ContentProcessRecoveryPolicy.swift`
- `browser/Reynard/StabilityCore/JITRetryPolicy.swift`
- `browser/Reynard/StabilityCore/FileMigration.swift`
- `browser/Reynard/StabilityCore/LifecycleFlushPolicy.swift`
- `browser/Reynard/Client/Stability/StabilityDiagnostics.swift`
- `browser/Reynard/Client/Stability/DiagnosticsExportCoordinator.swift`
- `browser/Reynard/Client/Interface/ContentView/Recovery/ContentRecoveryViewController.swift`
- `Tests/ReynardStabilityCoreTests/StabilityEventBufferTests.swift`
- `Tests/ReynardStabilityCoreTests/URLRedactorTests.swift`
- `Tests/ReynardStabilityCoreTests/RetryWindowTests.swift`
- `Tests/ReynardStabilityCoreTests/ContentProcessRecoveryPolicyTests.swift`
- `Tests/ReynardStabilityCoreTests/JITRetryPolicyTests.swift`
- `Tests/ReynardStabilityCoreTests/FileMigrationTests.swift`
- `Tests/ReynardStabilityCoreTests/LifecycleFlushPolicyTests.swift`
- `.github/workflows/stability-core.yml`
- `docs/testing/ios16-stability-checklist.md`

### Modify

- `browser/Reynard/AppDelegate.swift`
- `browser/Reynard/SceneDelegate.swift`
- `browser/Reynard/JIT/JITController.swift`
- `browser/Reynard/JIT/Interface/JITFailure.swift`
- `browser/Reynard/Client/SessionManagement/SessionManager.swift`
- `browser/Reynard/Client/TabManagement/TabState.swift`
- `browser/Reynard/Client/TabManagement/TabManagerImpl.swift`
- `browser/Reynard/Client/Stores/TabManagementStore.swift`
- `browser/Reynard/Client/Startup/UserDataMigration.swift`
- `browser/Reynard/Client/Interface/ContentView/OverlayContentView.swift`
- `browser/Reynard/Client/Interface/BrowserViewController+ContentOverlay.swift`
- `browser/Reynard/Client/Interface/Library/Settings/Sections/About/AboutSettingsSection.swift`
- `browser/Reynard/Resources/Localizable.xcstrings`

## Tasks

### Task 1: Add the portable stability core and test harness

**Files:** create `Package.swift`, the first five policy/event files under
`browser/Reynard/StabilityCore/`, and the four test files under
`Tests/ReynardStabilityCoreTests/`.

**Why:** retry and recovery decisions must be deterministic and testable without
UIKit, Gecko, or a device.

**Impact/Compatibility:** Foundation-only public types compile into the app via
the filesystem-synchronized Xcode group and into a SwiftPM test module. No
runtime behavior changes in this task.

**Required interfaces:**

```swift
public struct StabilityEvent: Codable, Equatable, Sendable {
    public enum Category: String, Codable, Sendable {
        case startup, jit, process, session, persistence, memory, recovery
    }
    public let id: UUID
    public let timestamp: Date
    public let category: Category
    public let name: String
    public let metadata: [String: String]
}

public struct StabilityEventBuffer: Sendable {
    public init(capacity: Int)
    public mutating func append(_ event: StabilityEvent)
    public var events: [StabilityEvent] { get }
}

public struct RetryWindow: Sendable {
    public init(limit: Int, interval: TimeInterval)
    public mutating func recordAttempt(at date: Date) -> Bool
    public mutating func reset()
}

public enum ContentProcessFailureKind: String, Codable, Sendable {
    case crash, killed
}

public enum ContentProcessRecoveryDecision: Equatable, Sendable {
    case recreateImmediately
    case recreateWhenSelected
    case showStableFailure
}

public struct ContentProcessRecoveryPolicy: Sendable {
    public init(crashLimit: Int = 2, crashInterval: TimeInterval = 60)
    public mutating func decide(
        kind: ContentProcessFailureKind,
        isSelected: Bool,
        at date: Date
    ) -> ContentProcessRecoveryDecision
    public mutating func markSuccessfulComposite()
}

public enum JITRetryDecision: Equatable, Sendable {
    case retry
    case offerJITLess
}

public struct JITRetryPolicy: Sendable {
    public init(limit: Int = 2, interval: TimeInterval = 30)
    public mutating func decide(at date: Date) -> JITRetryDecision
    public mutating func reset()
}
```

**Verification:** `swift test --package-path .`

- [ ] Write tests covering buffer eviction/order, retry-window expiry/reset,
  selected crash recovery, background kill recovery, repeated-crash failure,
  successful-composite reset, and JIT retry exhaustion.
- [ ] Run `swift test --package-path .`; expect compile failures because the
  required production types do not exist.
- [ ] Add the exact interfaces above and minimal deterministic implementations.
- [ ] Run `swift test --package-path .`; expect all tests to pass.
- [ ] Commit with `git commit -am 'test: add stability policy core'` after adding
  the new files with `git add Package.swift browser/Reynard/StabilityCore Tests`.

### Task 2: Add privacy-safe runtime diagnostics and startup instrumentation

**Files:** create `Client/Stability/StabilityDiagnostics.swift` and
`DiagnosticsExportCoordinator.swift`; modify `AppDelegate.swift`,
`SceneDelegate.swift`, `AboutSettingsSection.swift`, and localization.

**Why:** device-only failures cannot be repaired without bounded, exportable
evidence.

**Impact/Compatibility:** diagnostics are local, bounded to 500 events, and
exclude full URLs by default. They do not control lifecycle behavior.

**Required runtime interface:**

```swift
final class StabilityDiagnostics {
    static let shared = StabilityDiagnostics()
    func record(
        _ category: StabilityEvent.Category,
        name: String,
        metadata: [String: String] = [:]
    )
    func recordURL(
        _ category: StabilityEvent.Category,
        name: String,
        urlString: String?,
        metadata: [String: String] = [:]
    )
    func exportData(includeFullURLs: Bool) throws -> Data
    func clear()
}
```

`recordURL` stores only scheme and registrable host by default. Export JSON
contains schema version, app version, Gecko revision from `engine/release.txt`,
OS version, hardware identifier, and the bounded events.

**Verification:** SwiftPM tests for event/redaction primitives; macOS app build;
manual Settings export check.

- [ ] Add failing tests proving URL userinfo, query, fragment, and path are
  absent from default event metadata.
- [ ] Run `swift test --package-path .`; expect the new redaction assertions to
  fail.
- [ ] Implement redaction, atomic event persistence, export, settings share
  sheet, and startup/scene lifecycle event calls.
- [ ] Run `swift test --package-path .` and the documented `xcodebuild` command;
  expect tests and compile to pass.
- [ ] Commit with `git commit -am 'feat: add stability diagnostics'` after
  staging new files and localization changes.

### Task 3: Preserve tabs and recover Gecko content-process failures

**Files:** modify `TabState.swift`, `TabManagerImpl.swift`, `SessionManager.swift`,
`OverlayContentView.swift`, and `BrowserViewController+ContentOverlay.swift`;
create `ContentRecoveryViewController.swift`.

**Why:** the current handlers delete the user's tab on `onCrash` and `onKill`.

**Repair Track:**

- Root cause: process failure is incorrectly treated as user-requested tab
  closure.
- Canonical owner: `TabManagerImplementation` replaces the failed session while
  retaining the `Tab` and persisted navigation.
- Minimal stable repair: selected failures recreate immediately; background
  kills recreate lazily; repeated crashes show a native failure view.
- Compatibility: tab ID, URL, title, history, favicon, thumbnail, private mode,
  and selected index remain unchanged.
- Verification: pure policy tests, delegate-level tests where feasible, app
  compile, and device kill/crash scenarios.

**Retirement Track:**

- Retire `removeTab(at:mode:)` from both `onCrash` and `onKill`.
- Do not keep deletion as a fallback.
- The only remaining tab deletion paths are explicit close requests or user
  actions.

**Required state:** add a `TabContentFailureState` with `.none`, `.recovering`,
and `.failed(kind: ContentProcessFailureKind)` to `TabSessionState`. Add one
recovery policy per tab ID in `TabManagerImplementation`.

**Required orchestration:**

1. Capture the existing tab location and URL.
2. Ask the policy for a decision.
3. Close/deactivate the failed session through `SessionManager` without deleting
   the tab or its navigation history.
4. For immediate recovery, create a new session with the same tab ID/private
   mode, assign it to `tab.session`, notify the delegate of session replacement,
   activate if selected, and load the retained URL.
5. For lazy recovery, set `restoreState` and recreate when selected.
6. For exhausted recovery, present the native recovery view with Retry and
   Diagnostics actions while preserving browser chrome and tab switching.
7. Reset the policy after `onFirstComposite`.

**Verification:** `swift test --package-path .`, app build, and device checklist.

- [ ] Add failing policy/integration tests that assert crash/kill never produce
  a remove-tab action and repeated crashes produce stable failure.
- [ ] Run tests; expect failure against current deletion behavior/policy seam.
- [ ] Implement the session replacement, lazy restore, recovery overlay, retry,
  and diagnostic events.
- [ ] Run Swift tests and app build; on device verify one selected crash, one
  background kill, and three repeated crashes.
- [ ] Stage all changes with
  `git add browser/Reynard/Client browser/Reynard/Resources/Localizable.xcstrings`
  and commit with
  `git commit -m 'fix: recover Gecko process failures without losing tabs'`.

### Task 4: Add bounded JIT retry and two-action failure UI

**Files:** modify `JITController.swift`, `JITFailure.swift`,
`TabManagerImpl.swift`, `Notifications.swift`, and localization.

**Why:** JIT failure currently becomes a one-way choice between a modal and
JIT-less mode.

**Repair Track:**

- Root cause: `hasHandledFailure` is terminal for the launch and attached PID
  state is not reset for a new attempt.
- Canonical owner: `JITController` owns retry state; `TabManagerImplementation`
  only recreates the selected content session when requested.
- Minimal stable repair: offer Retry while policy budget remains, clean
  watchdog/attachment state, detach stale sessions, and request one selected
  session recreation.
- Compatibility: JIT-less mode remains available and explicit.
- Verification: policy tests, UI compile, TrollStore JIT failure simulation.

**Retirement Track:**

- Retire terminal use of `hasHandledFailure` as the sole state machine.
- Replace it with explicit idle/attaching/failed/jitless state plus
  `JITRetryPolicy`.

**Required UI:** `JITFailureViewController` accepts primary and secondary
actions. Primary is Retry while allowed; secondary is Activate JIT-Less Mode.
When retry budget is exhausted, primary becomes Export Diagnostics and secondary
remains JIT-less mode.

**Verification:** `swift test --package-path .`, app build, device JIT test.

- [ ] Add failing tests for two allowed attempts, retry-window expiry, reset
  after successful attachment, and exhausted-state behavior.
- [ ] Run tests; expect failure until controller policy is wired.
- [ ] Implement explicit JIT state, retry cleanup, retry notification, selected
  session recreation, and two-action UI.
- [ ] Run tests/app build; on device break JIT once, retry successfully, then
  force exhaustion and enter JIT-less mode.
- [ ] Commit with `git commit -am 'fix: make JIT failure retryable'`.

### Task 5: Replace recoverable startup migration crashes with typed outcomes

**Files:** create `StabilityCore/FileMigration.swift` and
`FileMigrationTests.swift`; modify `UserDataMigration.swift`, `AppDelegate.swift`,
diagnostics, and localization.

**Why:** filesystem migration failure currently calls `fatalError`, preventing
the browser from showing recovery information.

**Repair Track:**

- Root cause: migration treats all I/O failures as unrecoverable programmer
  errors.
- Canonical owner: `UserDataMigration` returns a typed report; startup decides
  whether to continue with existing destination data or present a blocking
  recovery screen.
- Minimal stable repair: make migration idempotent, retain the source until the
  destination is verified, and return structured errors.
- Compatibility: do not change the destination folder layout or database
  schemas.
- Verification: temporary-directory tests for no source, successful move,
  preexisting destination, interrupted copy, and retry.

**Retirement Track:** remove migration-path `fatalError` calls. UIKit coder
`fatalError` initializers are unrelated and remain unchanged.

**Required interface:**

```swift
struct UserDataMigrationReport: Equatable {
    enum Outcome: Equatable { case unchanged, migrated, recoveredExisting }
    let appData: Result<Outcome, UserDataMigrationError>
    let ddi: Result<Outcome, UserDataMigrationError>
}

func run() -> UserDataMigrationReport
```

**Verification:** `swift test --package-path .` and app build.

- [ ] Add failing temporary-directory migration tests.
- [ ] Run tests; expect failures because migration has no injectable URLs or
  typed result.
- [ ] Add injectable directory URLs, safe copy/verify/swap behavior, report
  generation, diagnostics, and startup failure presentation.
- [ ] Run tests and app build; expect all tests to pass and no migration
  `fatalError` matches from `rg -n 'migration failed' browser/Reynard`.
- [ ] Stage all changes with
  `git add browser/Reynard/StabilityCore browser/Reynard/Client/Startup browser/Reynard/AppDelegate.swift Tests browser/Reynard/Resources/Localizable.xcstrings`
  and commit with
  `git commit -m 'fix: make startup migration recoverable'`.

### Task 6: Harden tab persistence and lifecycle flushing

**Files:** create `StabilityCore/LifecycleFlushPolicy.swift` and
`LifecycleFlushPolicyTests.swift`; modify `TabManagementStore.swift`,
`TabManagerImpl.swift`, `SceneDelegate.swift`, and diagnostics.

**Why:** asynchronous persistence can lose the most recent mutations when the
app backgrounds or is terminated shortly afterward.

**Repair Track:**

- Root cause: normal writes are asynchronous and lifecycle boundaries have no
  explicit flush result.
- Canonical owner: `TabManagementStore` owns queued transaction completion;
  `TabManagerImplementation` supplies a snapshot; `SceneDelegate` requests a
  bounded flush.
- Minimal stable repair: add an async completion-bearing persist API and a
  lifecycle flush that waits only for already-enqueued state work.
- Compatibility: preserve the existing SQLite schema and transaction shape.
- Verification: pure flush-policy tests, transaction completion assertions in
  debug builds, and device forced-termination checks.

**Retirement Track:** keep the nonblocking persist path for normal interaction,
but retire fire-and-forget behavior at background/resign-active boundaries.

**Required interfaces:**

```swift
func persistTabs(..., completion: ((Bool) -> Void)? = nil)
func flush(completion: @escaping (Bool) -> Void)
func persistStateForLifecycleBoundary(completion: @escaping (Bool) -> Void)
```

**Verification:** app build plus ten forced-termination cycles from the device
checklist.

- [ ] Add failing pure tests for one in-flight flush, coalesced waiters, timeout,
  and completion ordering; add debug assertions around store transaction
  completion.
- [ ] Run tests; expect failures because completion/flush APIs do not exist.
- [ ] Implement completion-bearing transactions, flush, lifecycle calls, and
  diagnostic outcomes without blocking the main thread indefinitely.
- [ ] Run tests/app build and execute the ten-cycle device restore check.
- [ ] Stage all changes with
  `git add browser/Reynard/StabilityCore browser/Reynard/Client browser/Reynard/SceneDelegate.swift Tests`
  and commit with
  `git commit -m 'fix: flush tab state at lifecycle boundaries'`.

### Task 7: Add repeatable CI and iOS 16 device evidence

**Files:** create `.github/workflows/stability-core.yml` and
`docs/testing/ios16-stability-checklist.md`; update README build/test section.

**Why:** reliability claims require repeatable evidence independent of one local
machine.

**Impact/Compatibility:** CI runs only Foundation tests on macOS and validates
the project/package shape. Full Gecko/device builds remain explicit manual jobs.

**Required CI commands:**

```yaml
- run: swift test --package-path .
- run: git diff --check
- run: find browser -name '*.plist' -print0 | xargs -0 -n1 plutil -lint
- run: find tools -name '*.sh' -print0 | xargs -0 -n1 bash -n
```

The device checklist records device model, architecture, iOS version, TrollStore
version, app/Gecko revision, JIT mode, 20 cold launches, 30 background cycles,
10 forced terminations, 100 tab switches, crash recovery, JIT retry, and exported
diagnostic filename.

**Verification:** validate workflow YAML, run shell checks locally, and complete
the checklist on arm64 and arm64e devices.

- [ ] Add the workflow/checklist and an intentionally failing package test run
  reference in the first CI execution.
- [ ] Run workflow validation and observe failure until Tasks 1–6 are complete.
- [ ] Finalize commands, README instructions, and artifact retention for test
  output/diagnostic samples with URLs excluded.
- [ ] Run CI to green and complete both device checklists.
- [ ] Stage all changes with
  `git add .github/workflows/stability-core.yml docs/testing/ios16-stability-checklist.md README.md`
  and commit with
  `git commit -m 'ci: verify stability core and device evidence'`.

## Risks

- Recreating Gecko sessions can expose lifecycle assumptions not visible without
  a physical device.
- JIT retry may require content-process recreation; attempting to reattach a
  process that already continued JIT-less must not be treated as success.
- Background execution time is limited; persistence flushes must be bounded and
  nonblocking.
- Full Gecko builds are expensive, and current execution host cannot compile
  Swift/iOS code.
- Diagnostics must remain useful without leaking browsing secrets.

## Retirement

- Delete crash/kill-driven tab removal.
- Delete terminal one-shot JIT failure state once explicit state/policy is live.
- Delete migration `fatalError` paths for filesystem I/O.
- Keep normal asynchronous tab persistence but retire it at lifecycle flush
  boundaries.
- No compatibility fallback to WebKit is introduced.

## ADR and Baseline Sync Signals

- No ADR is required for deterministic policies or diagnostics alone.
- Create an ADR if device evidence requires a new Gecko helper/process topology
  or changes persistent schema.
- After Gate A passes, update the architecture baseline with the final recovery
  owner boundaries and verified device matrix before planning Via Phase 1.
