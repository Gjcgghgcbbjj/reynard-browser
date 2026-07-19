# Reynard iOS 16 Stability and Usability Design

Date: `2026-07-19`
Status: `proposed for user review`
ArchitectureReviewRequired: `yes`

## 1. TaskIntentDraft

- **Outcome:** produce an open-source Gecko browser track that is dependable on
  TrollStore-capable iOS 16 devices.
- **Goal:** improve startup reliability, JIT recovery, process/session
  resilience, tab persistence, memory behavior, and failure usability before
  adding new features.
- **Success evidence:** repeatable device test runs, preserved regular sessions
  after backgrounding or termination, actionable JIT/error recovery, and an
  exportable privacy-conscious diagnostic bundle.
- **Stop condition:** the release acceptance matrix in section 8 passes on at
  least one arm64 and one arm64e iOS 16 device, with all remaining known issues
  documented and no unresolved data-loss or launch-blocking defect.
- **Non-goals:** App Store support, BrowserEngineKit, Blink, cloud browsing,
  unrelated visual redesign, sync services, or feature expansion.

## 2. BaselineReadSetHint

- `README.md`
- `docs/aegis/baseline/2026-07-19-initial-baseline.md`
- `browser/Reynard/JIT/JITController.swift`
- `browser/Reynard/Client/SessionManagement/SessionManager.swift`
- `browser/Reynard/Client/TabManagement/TabManagerImpl.swift`
- `browser/Reynard/Client/Stores/TabManagementStore.swift`
- `browser/GeckoView/`, `browser/Helper/`, and `patches/`
- Upstream issues concerning JIT retry, background tab loss, crashes, and
  device-specific regressions.

## 3. BaselineUsageDraft

- **Required baseline refs:** initial baseline and current runtime owner files.
- **Delivered context refs:** user requirement for iOS 16, open-source
  TrollStore distribution, stability and usability priority.
- **Acknowledged before plan refs:** upstream README, current source inventory,
  current open issue list, pinned engine/support submodules.
- **Cited in design refs:** initial baseline and the owner files listed above.
- **Missing refs:** physical-device crash logs and a user-specific failing-site
  list; these improve prioritization but do not block the initial reliability
  architecture.
- **Decision:** `continue`.

## 4. Requirement Ready Check

- **Requirement source refs:** current conversation and upstream project facts.
- **Goals and scope refs:** sections 1, 7, and 8 of this design.
- **User / scenario refs:** iOS 16 users whose system WebKit no longer loads
  modern sites reliably, installing through TrollStore.
- **Requirement item refs:** sections 6 through 8.
- **Acceptance / verification criteria refs:** section 8.
- **Open blocker questions:** none for planning; exact test devices and the
  user's highest-priority failing sites are evidence inputs during execution.
- **Decision:** `ready`.

## 5. Decision Review

### First-principles invariants

- **Non-negotiable goal:** browsing must remain available and recoverable when
  WebKit is not suitable on iOS 16.
- **Non-negotiable constraints:** real Gecko, iOS 16, TrollStore, no Apple
  entitlement, open-source licensing, and no silent WebKit fallback.
- **Historical assumptions to delete:** adding more browser features does not
  make an alpha engine integration usable; reliability evidence comes first.

### Owner / retirement matrix

- **New canonical owner:** one small diagnostics subsystem may be added for
  structured lifecycle/JIT/session events and export.
- **Old owner:** existing JIT, session, tab, store, and Gecko-patch owners remain
  canonical for their behavior.
- **Compat-only carrier:** none planned.
- **Delete-first / retirement trigger:** ad-hoc logging or duplicated recovery
  flags encountered during implementation must be consolidated into the
  canonical owner instead of retained as parallel fallbacks.

### Falsification matrix

- **Dependency-removal test:** the stability track must still build from pinned
  upstream Gecko and idevice revisions without a private binary dependency.
- **Counterexample scenario:** if a failure reproduces inside unmodified Gecko
  on supported Apple platforms, it is an engine defect and must not be hidden
  with repeated client reload loops.
- **Must remain correct:** failed JIT, OS memory pressure, background
  termination, corrupt optional cache data, and unreachable sites must degrade
  without destroying regular browsing data.

### Verdict

- **Decision:** adopt an upstream-first Gecko stability track.
- **Blocking gaps:** none at design level.
- **Next evidence:** device logs, repeatable stress runs, and site compatibility
  results.

## 6. Product Risk Lens

- **Value:** old iPhones gain a modern browser engine that behaves predictably
  enough for daily browsing.
- **Non-goals:** feature parity with desktop Firefox or Safari.
- **Trade-offs:** some performance depends on JIT/private entitlement behavior;
  supporting old OS versions increases device-specific testing cost.
- **Decision needed:** approve reliability-first release gates before feature
  work. The user has approved this direction; this document pins its meaning.

## 7. Design

### 7.1 Upstream and branch strategy

- Keep `minh-ton/reynard-browser` as the upstream remote and retain its commit
  history.
- Develop stability changes as small, reviewable commits rather than a wholesale
  client rewrite.
- Keep Gecko changes in `patches/`; prefer upstream Gecko fixes when the defect
  is not specific to the iOS integration.
- Preserve GPLv3 for the application and MPL 2.0 for Gecko-derived patches.

### 7.2 Reliability layers

#### A. Startup and JIT

- Model startup as explicit stages: storage readiness, helper availability,
  JIT capability detection, Gecko initialization, first session creation, and
  first content presentation.
- Record stage transitions and bounded failure metadata.
- Add an in-app retry action for recoverable JIT attachment failures.
- Keep JIT-less mode explicit and visible. It may allow emergency browsing but
  cannot be reported as equivalent performance.
- A failed child-process attachment must time out, clean its watchdog state,
  and offer recovery without leaving a permanent blocking sheet or blank UI.

#### B. Gecko process and session lifecycle

- `SessionManager` remains the sole owner of session active/focused state.
- Child-process exit, session crash, and OS memory pressure must be classified.
- A foreground tab receives a bounded reload/recreation attempt; repeated
  crashes surface a stable error page rather than entering a reload loop.
- Background tabs may be discarded under pressure, but retain enough navigation
  state to reload when selected.
- Picture-in-picture cleanup must not block unrelated session cleanup.

#### C. Tab and data recovery

- `TabManagerImpl` owns the live model; `TabManagementStore` owns durable tab
  snapshots. No second recovery store is introduced.
- Regular tab state is persisted transactionally at lifecycle boundaries and
  after meaningful tab mutations.
- Startup tolerates missing thumbnails, optional cache corruption, and partial
  nonessential metadata while preserving valid tab rows.
- Database/open/migration failures return typed recovery results instead of
  unconditional process termination where recovery is possible.
- Recovery distinguishes essential user data from disposable caches.

#### D. Diagnostics

- Add one diagnostics owner for a bounded ring buffer of startup, JIT, helper,
  Gecko process, session, tab persistence, and memory-warning events.
- Default records contain event type, monotonic time, OS/device class, app and
  Gecko versions, process type, and sanitized error codes.
- Default records exclude cookies, form data, page content, authorization
  headers, and complete URLs.
- Users can export a text/JSON diagnostic bundle from settings. Including
  browsing URLs requires an explicit opt-in at export time.

#### E. Failure usability

- Every blocking failure view provides a primary recovery action and a way to
  view/export diagnostic details.
- Network, TLS, site-policy, engine crash, JIT, and internal persistence failures
  use distinct messages; they are not all presented as “page failed to load.”
- The current page can be retried without closing the tab.
- When automatic recovery is exhausted, the user keeps access to the address
  bar, tab switcher, settings, and diagnostics.

### 7.3 Compatibility boundary

- Target package: TrollStore `.tipa`.
- Target OS: iOS 16.0 through 16.6.1, plus 16.7 RC where a compatible test device
  is available.
- Target architectures: arm64 and arm64e.
- Existing bookmarks, history, downloads, permissions, settings, and regular
  tab data remain readable.
- No normal rendering path may instantiate `WKWebView`.

### 7.4 Test and evidence architecture

- Add test seams around state transitions and stores rather than attempting to
  automate the entire Gecko engine in unit tests.
- Add deterministic tests for URL sanitization, diagnostic redaction, tab-store
  transactions, corrupted optional data, startup state transitions, retry
  budgets, and crash-loop prevention.
- Add a device smoke runner/checklist that emits machine-readable results for
  cold launch, background/resume, forced termination, tab stress, JIT failure,
  memory pressure, downloads, and representative websites.
- Full engine/device verification remains separate from fast client/store tests.

## 8. Release Acceptance Matrix

### 8.1 Required device coverage

- At least one arm64 iOS 16 device.
- At least one arm64e iOS 16 device.
- TrollStore installation and launch from a clean install and an upgrade over
  the selected upstream release.

### 8.2 Launch and JIT

1. Twenty consecutive cold launches with working TrollStore JIT complete without
   an app crash, permanent blank screen, or blocked startup.
2. A deliberately failed JIT attempt reaches an actionable failure screen,
   supports retry, and can enter explicit JIT-less mode without relaunching into
   a crash loop.
3. Diagnostic export identifies the failed startup/JIT stage without exposing
   browsing secrets by default.

### 8.3 Session and persistence

1. With ten regular tabs open, thirty foreground/background cycles preserve the
   selected tab and tab list.
2. Ten forced app terminations preserve all committed regular tab URLs and the
   selected regular tab; missing thumbnails do not prevent restoration.
3. One hundred tab switches across ten tabs produce no app crash or permanently
   unusable content view.
4. A terminated or discarded Gecko content process is recreated or replaced by
   a stable error state without an unbounded reload loop.

### 8.4 Browsing usability

1. Address entry, search, navigation, back/forward, reload, tab creation/closure,
   file download, cookie-based login, and settings remain usable after recovery
   events.
2. The default compatibility smoke set is: `github.com`, `chatgpt.com`,
   `wikipedia.org`, `reddit.com`, `youtube.com`, `bilibili.com`, `zhihu.com`,
   and `apple.com`. Each result records load, scroll/input, navigation, media
   where applicable, and the classified reason for any failure.
3. Network-unreachable and engine-crash cases present different recovery UI.

### 8.5 Data safety

1. Existing upstream user data survives upgrade testing.
2. Corrupt disposable thumbnails/cache data cannot prevent startup.
3. Store mutations used in recovery remain transactional.
4. Diagnostic export omits secrets and full URLs by default.

## 9. ImpactStatementDraft

- **Affected layers:** startup, JIT, Gecko helper/process bridge, session
  lifecycle, tab orchestration, SQLite persistence, failure UI, diagnostics,
  packaging, and tests.
- **Owners:** existing owners remain authoritative; one diagnostics owner is
  added to remove ad-hoc observability.
- **Invariants:** real Gecko rendering, explicit JIT degradation, transactional
  user data, upstream patch isolation, no silent WebKit fallback.
- **Compatibility:** iOS 16 TrollStore, arm64/arm64e, existing user data and
  upstream updateability.
- **Non-goals:** App Store, Blink, cloud proxying, broad redesign, sync, and
  unrelated features.

## 10. Architecture Integrity Lens

- **Invariant:** recovery behavior must be owned where the failing lifecycle or
  data contract is defined.
- **Canonical owner / contract:** JIT in `JITController`, sessions in
  `SessionManager`, live tabs in `TabManagerImpl`, persisted snapshots in
  `TabManagementStore`, engine behavior in Gecko patches.
- **Responsibility overlap:** UI-level reload loops, duplicate tab snapshots,
  and scattered diagnostic flags would create competing owners and are
  prohibited.
- **Higher-level simplification:** add typed lifecycle outcomes at owner
  boundaries instead of adding more controller-specific boolean guards.
- **Retirement / falsifier:** any temporary compatibility branch must name the
  OS/engine condition that removes it; evidence that the defect is upstream
  Gecko moves the fix out of the Swift client.
- **Verdict:** `proceed`, with architecture review during verification.

## 11. Complexity Budget

- **Artifact class:** high-risk cross-boundary reliability work.
- **Target files / artifacts:** JIT controller/support, session manager, tab
  manager/store, Gecko bridge/patches when proven necessary, a new diagnostics
  owner, tests, and release scripts.
- **Current pressure:** several owner files exceed 800–1,500 lines and no test
  target is checked in.
- **Projected post-change pressure:** at risk if recovery logic is added directly
  to large controllers.
- **Budget result:** `at-risk`.
- **Planned governance:** extract focused state machines/diagnostics helpers only
  when they establish a single owner and are independently testable.

### Plan-Time Complexity Check

- **Better file boundary:** diagnostics and deterministic startup/retry state
  transitions should have dedicated small files; existing behavior owners stay
  in place.
- **Recommendation:** `extract helper` for new cross-cutting diagnostics/state
  logic; otherwise `edit-in-place` at the canonical owner.

## 12. ADR Signal

- A durable ADR will be warranted only if implementation introduces a new
  startup state machine contract, changes the Gecko helper/process topology, or
  changes persistent schema/recovery semantics.
- Ordinary bug fixes and diagnostics additions do not by themselves require an
  ADR.
