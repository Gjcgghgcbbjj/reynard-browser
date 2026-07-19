# Reynard iOS 16 Stability and Usability Design

Date: `2026-07-19`
Status: `proposed for user review; amended for Via functional parity`
ArchitectureReviewRequired: `yes`

## 1. TaskIntentDraft

- **Outcome:** produce an open-source Gecko browser track that is dependable on
  TrollStore-capable iOS 16 devices and functionally aligns with Via Browser's
  publicly documented browser features.
- **Goal:** improve startup reliability, JIT recovery, process/session
  resilience, tab persistence, memory behavior, and failure usability before
  adding new features.
- **Success evidence:** repeatable device test runs, preserved regular sessions
  after backgrounding or termination, actionable JIT/error recovery, and an
  exportable privacy-conscious diagnostic bundle, followed by a passing Via
  functional-parity matrix.
- **Stop condition:** the release acceptance matrix in section 8 passes on at
  least one arm64 and one arm64e iOS 16 device, with all remaining known issues
  documented and no unresolved data-loss or launch-blocking defect.
- **Non-goals:** App Store support, BrowserEngineKit, Blink, cloud browsing,
  copying Via's visual identity/assets, Via's proprietary account services, or
  syncing passwords, cookies, private tabs, downloads, and browsing history.

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
- Via official feature description: `https://viayoo.com/en/`.
- Via iOS public App Store description and version history:
  `https://apps.apple.com/cn/app/id1639085829`.

## 3. BaselineUsageDraft

- **Required baseline refs:** initial baseline and current runtime owner files.
- **Delivered context refs:** user requirement for iOS 16, open-source
  TrollStore distribution, stability and usability priority, and functional
  alignment with Via Browser.
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
- **Requirement item refs:** sections 6 through 9.
- **Acceptance / verification criteria refs:** sections 8 and 9.
- **Open blocker questions:** none for planning; exact test devices and the
  user's highest-priority failing sites are evidence inputs during execution.
- **Decision:** `ready`.

## 5. Decision Review

### First-principles invariants

- **Non-negotiable goal:** browsing must remain available and recoverable when
  WebKit is not suitable on iOS 16, without losing the compact power-user
  capabilities expected from Via Browser.
- **Non-negotiable constraints:** real Gecko, iOS 16, TrollStore, no Apple
  entitlement, open-source licensing, and no silent WebKit fallback.
- **Historical assumptions to delete:** adding more browser features does not
  make an alpha engine integration usable; reliability evidence comes first,
  and parity should reuse Gecko capabilities rather than duplicate them in
  UIKit.

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
  enough for daily browsing and provides Via-style lightweight customization.
- **Non-goals:** feature parity with desktop Firefox or Safari, Via branding,
  or compatibility with Via's private sync services. The project supplies its
  own optional CloudKit synchronization.
- **Trade-offs:** some performance depends on JIT/private entitlement behavior;
  supporting old OS versions increases device-specific testing cost; direct
  feature parity increases scope and must be delivered in gated phases.
- **Decision needed:** approve reliability-first release gates followed by the
  Via parity phases defined below.

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

### 7.5 Via functional-parity strategy

Functional parity uses Via's official public feature descriptions rather than
attempting to clone undocumented internals. The comparison baseline is the
public Via iOS `1.9.0` description/version history plus the official website's
feature list as observed on `2026-07-19`. Existing Reynard functionality is
retained where it already satisfies the behavior.

#### Existing or near-existing capabilities to preserve

- Address/search bar, multiple search engines, suggestions, back/forward,
  reload, desktop/mobile user-agent modes, page zoom, tabs, private browsing,
  bookmarks, history, downloads, homepage favorites, site permissions, and
  Gecko add-ons.
- These capabilities first pass the stability gates; they are not rewritten
  solely to resemble Via's implementation.

#### Parity Phase 1: daily-use core

1. **Minimal configurable chrome:** compact one-hand layout, configurable
   address-bar position, configurable toolbar actions, and no promoted content.
2. **Ad and tracker blocking:** a built-in, user-controllable Gecko WebExtension
   integration with default filter lists, per-site disable, subscription
   updates, custom rules, and visible blocked-request count.
3. **User scripts:** install, enable/disable, edit, remove, update, and scope
   Greasemonkey-compatible scripts using Gecko's `userScripts`/WebExtension
   boundary. Swift must not become a second JavaScript execution engine.
4. **Night mode:** app theme plus optional per-site page darkening, with site
   exceptions and an immediate toolbar toggle.
5. **Find in page:** query, previous/next match, match count, and close action.
6. **Webpage translation:** a configurable translation provider opened from the
   current page, with the original URL retained and no mandatory project-owned
   proxy.
7. **Custom homepage:** reorderable favorites, blank/custom URL options, and
   optional sections without news or advertisements.
8. **Per-site settings:** desktop mode, zoom, permissions, blocking, dark mode,
   and script exceptions owned by the existing site-settings boundary.
9. **Privacy controls:** third-party cookie blocking, tracker blocking,
   clear-site-data controls, and explicit private-mode behavior.
10. **Backup portability:** import/export bookmarks, settings, filter
    subscriptions, site settings, and user-script metadata in a documented,
    versioned archive.
11. **Automatic CloudKit sync:** synchronize the approved data categories
    through a project-owned private CloudKit database when the build has a valid
    Apple Team and iCloud container configuration.

#### Parity Phase 2: extended tools

1. **Save webpage:** export a self-contained offline archive through a Gecko
   engine/extension-owned capture path; saving only a screenshot does not count.
2. **Reader mode:** extract readable content with adjustable typography and
   theme while retaining a return-to-original action.
3. **QR scanner:** scan a URL/text QR code, preview the result, and require user
   confirmation before navigation or external actions.
4. **Manual ad marking:** select and persist page-specific cosmetic blocking
   rules, with undo and site rule management.
5. **Bookmark interchange:** HTML import/export compatible with common desktop
   browsers in addition to the full local backup archive.
6. **Settings portability:** human-readable export/import suitable for moving
   between TrollStore installations.

#### CloudKit synchronization for iOS 16

- Use a CloudKit private database and a custom record zone so each signed-in
  iCloud user owns an isolated sync dataset.
- Because the minimum OS is iOS 16, do not depend on `CKSyncEngine`. Incremental
  synchronization uses `CKFetchRecordZoneChangesOperation`, persisted server
  change tokens, batched `CKModifyRecordsOperation` uploads, and CloudKit
  database/zone subscriptions where push entitlement is available.
- Sync triggers are app activation, meaningful local changes, network recovery,
  opportunistic background refresh, and silent CloudKit pushes in builds that
  have valid push provisioning.
- The open-source tree contains no personal Team ID or container credential.
  `CloudSync.xcconfig`/entitlement values are injected by the builder. Builds
  without a valid CloudKit configuration keep local data and local backup fully
  usable while clearly showing that automatic sync is unavailable.
- Required synchronized categories are bookmarks/folders, homepage favorites,
  an allowlisted set of browser settings, custom search engines, per-site
  settings, filter subscriptions/custom rules, and user scripts when the user
  enables script sync.
- Excluded categories are passwords, cookies, browsing history, private tabs,
  download files/history, diagnostics, form contents, and page cache.
- Each entity has a stable UUID, schema version, modification metadata, and
  deletion tombstone/change event. Offline changes queue locally and retry with
  bounded backoff.
- CloudKit change tags detect conflicts. Collection entities merge by stable
  identity; scalar settings use the newest accepted record; destructive
  conflicts are surfaced in sync diagnostics instead of silently deleting both
  sides.
- Disabling sync stops transfer but does not delete cloud data. Cloud deletion
  is a separate explicit destructive action.

#### Explicit parity boundaries

- Local import/export remains mandatory even when CloudKit is configured, so
  users can migrate between independently built TrollStore packages.
- Via branding, icons, screenshots, copy, proprietary services, and internal
  rule sources are not copied.
- Gecko WebExtensions are the preferred implementation boundary for blocking,
  user scripts, cosmetic page changes, and other web-content modification.
  Native duplicate engines are prohibited.

### 7.6 Delivery gates

- **Gate A — Reliability foundation:** section 8 passes before parity features
  are considered release-ready.
- **Gate B — Daily-use core:** all Phase 1 items pass section 9 acceptance.
- **Gate C — Extended tools:** Phase 2 ships incrementally without reopening
  Gate A regressions.

## 8. Stability Release Acceptance Matrix

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

## 9. Via Functional-Parity Acceptance Matrix

### 9.1 Phase 1

1. Users can customize the primary toolbar without making navigation, tab
   access, or recovery actions unreachable.
2. Blocking can be enabled globally and disabled per site; filter updates and
   custom-rule failures are visible and recoverable.
3. A valid Greasemonkey-compatible script can be imported, scoped to matching
   sites, toggled, edited, and removed; permissions are shown before activation.
4. Night mode, desktop mode, zoom, blocking, and script exceptions persist per
   site without creating parallel settings stores.
5. Find-in-page reports match count and navigates between matches on a long page.
6. Translation opens the configured provider for the current canonical URL and
   can return to the original page.
7. Homepage favorites can be added, removed, reordered, and backed up.
8. Third-party cookie and tracker controls produce observable behavior and can
   be reset per site.
9. A backup created on one clean installation can restore the documented data
   categories on another installation of the same or newer schema version.
10. Two devices signed into the same iCloud account converge bookmarks,
    favorites, allowed settings, site rules, filter configuration, and opted-in
    user scripts after create, edit, reorder, and delete operations.
11. Offline edits upload after connectivity returns; simultaneous edits produce
    a deterministic result or a visible conflict record without data-store
    corruption.
12. Reinstalling the app and enabling the same configured CloudKit container can
    restore synchronized categories without restoring excluded private data.
13. Builds without valid CloudKit entitlements remain functional and explain
    why automatic sync is unavailable.
14. All Phase 1 features remain usable after the background, termination, and
    JIT-recovery scenarios in section 8.

### 9.2 Phase 2

1. Saved pages reopen offline with text, structure, and local resources needed
   for meaningful reading.
2. Reader mode succeeds on representative article pages and exits without
   losing the original tab URL.
3. QR navigation requires confirmation and rejects unsupported or unsafe action
   schemes by default.
4. A manually marked cosmetic rule survives reload, can be inspected, and can
   be undone.
5. Bookmark HTML round-trips retain titles, URLs, and folder hierarchy.
6. Settings/backup import validates schema and reports unsupported records
   without corrupting existing data.

## 10. ImpactStatementDraft

- **Affected layers:** startup, JIT, Gecko helper/process bridge, session
  lifecycle, tab orchestration, SQLite persistence, failure UI, diagnostics,
  Gecko add-ons/WebExtensions, site settings, CloudKit sync,
  backup/import/export, packaging, and tests.
- **Owners:** existing owners remain authoritative; one diagnostics owner is
  added to remove ad-hoc observability; web-content modification remains owned
  by Gecko/WebExtensions rather than UIKit.
- **Invariants:** real Gecko rendering, explicit JIT degradation, transactional
  user data, upstream patch isolation, no silent WebKit fallback.
- **Compatibility:** iOS 16 TrollStore, arm64/arm64e, existing user data,
  upstream updateability, and optional Apple Team/container configuration.
- **Non-goals:** App Store, Blink, cloud proxying, Via branding/private services,
  sensitive browsing-data sync, and unrelated features.

## 11. Architecture Integrity Lens

- **Invariant:** recovery behavior must be owned where the failing lifecycle or
  data contract is defined.
- **Canonical owner / contract:** JIT in `JITController`, sessions in
  `SessionManager`, live tabs in `TabManagerImpl`, persisted snapshots in
  `TabManagementStore`, engine behavior in Gecko patches, and content
  modification in Gecko WebExtensions. A dedicated sync coordinator owns
  CloudKit transport and sync state; existing stores remain canonical for local
  browser data.
- **Responsibility overlap:** UI-level reload loops, duplicate tab snapshots,
  scattered diagnostic flags, native reimplementations of blocking/script
  engines, or a CloudKit-owned parallel browser database would create competing
  owners and are prohibited.
- **Higher-level simplification:** add typed lifecycle outcomes at owner
  boundaries instead of adding more controller-specific boolean guards.
- **Retirement / falsifier:** any temporary compatibility branch must name the
  OS/engine condition that removes it; evidence that the defect is upstream
  Gecko moves the fix out of the Swift client.
- **Verdict:** `proceed`, with architecture review during verification.

## 12. Complexity Budget

- **Artifact class:** high-risk cross-boundary reliability work.
- **Target files / artifacts:** JIT controller/support, session manager, tab
  manager/store, Gecko bridge/patches when proven necessary, diagnostics,
  WebExtension integrations, site settings, CloudKit sync adapters,
  backup/import/export, tests, and release scripts.
- **Current pressure:** several owner files exceed 800–1,500 lines and no test
  target is checked in.
- **Projected post-change pressure:** at risk if recovery logic or Via-parity
  content features are added directly to large controllers.
- **Budget result:** `at-risk`.
- **Planned governance:** extract focused state machines/diagnostics helpers only
  when they establish a single owner and are independently testable.

### Plan-Time Complexity Check

- **Better file boundary:** diagnostics, deterministic startup/retry state
  transitions, backup codecs, CloudKit transport/state, and bundled WebExtension
  coordination should have dedicated small owners; existing behavior owners
  stay in place.
- **Recommendation:** `extract helper` for new cross-cutting diagnostics/state
  logic; otherwise `edit-in-place` at the canonical owner.

## 13. ADR Signal

- A durable ADR will be warranted only if implementation introduces a new
  startup state machine contract, changes the Gecko helper/process topology, or
  changes persistent schema/recovery semantics. The CloudKit record schema,
  local-store adapter boundary, and conflict policy require an ADR when their
  executable form is finalized.
- Ordinary bug fixes and diagnostics additions do not by themselves require an
  ADR.
