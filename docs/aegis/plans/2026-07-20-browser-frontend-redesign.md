# Reynard Browser Frontend Redesign Implementation Plan

## Goal

Execute every phase of the approved UIKit frontend redesign while continuing
Via Phase 1 functional parity, preserving Gecko and existing runtime/data
owners, and retiring old frontend responsibility after each replacement slice.

## Architecture

- Keep `BrowserViewController` as the browser composition root and reduce its
  responsibility to lifecycle and owner wiring.
- Keep Gecko, `SessionManager`, `TabManager`, preferences, and stores as the
  canonical runtime/data owners.
- Add focused design/motion, chrome, tab-surface, homepage-presentation, and Via
  feature owners only where they replace responsibility currently mixed into an
  oversized UIKit artifact.
- Execute vertical replacement slices. Do not ship or retain a permanent legacy
  UI feature flag.
- Use Gecko/WebExtensions for webpage content behavior. UIKit owns controls and
  presentation only.

## Tech Stack

- Swift 5.10-compatible UIKit and Foundation
- Existing GeckoView bridge and pinned Gecko event contracts
- Swift Package Manager portable policy/state tests
- Xcode/iOS 16 build and physical-device verification when macOS/device access
  becomes available

## Baseline/Authority Refs

- `docs/aegis/specs/2026-07-20-browser-frontend-redesign-design.md`
- `docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md`
- `docs/aegis/baseline/2026-07-19-initial-baseline.md`
- `browser/Reynard/Client/Interface/BrowserViewController.swift`
- `browser/Reynard/Client/Interface/Chrome/BrowserChrome.swift`
- `browser/Reynard/Client/Interface/Chrome/AddressBar/`
- `browser/Reynard/Client/Interface/TabOverview/`
- `browser/Reynard/Client/Interface/Homepage/`
- `browser/Reynard/Client/TabManagement/TabManager.swift`
- `browser/Reynard/Client/SessionManagement/SessionManager.swift`

## Compatibility Boundary

- Preserve Gecko as the only web renderer.
- Preserve existing regular/private tab and user-data schemas.
- Do not introduce SwiftUI, WebKit, a second tab/session model, a second store,
  a project proxy, CloudKit, or packaging work.
- Preserve recovery/JIT/diagnostic access throughout the redesign.
- Use original presentation and assets; do not copy Via or Firefox branding.
- Temporary adapters must be deleted in the same phase or carry an explicit
  next-phase retirement trigger.

## Verification

Run after every source slice:

```bash
git diff --check
python -m json.tool browser/Reynard/Resources/Localizable.xcstrings >/dev/null
docker run --rm -v "$PWD:/workspace" -w /workspace \
  swift:6.1-noble swift test --package-path .
```

Parse every changed Swift file on WSL:

```bash
docker run --rm -v "$PWD:/workspace" -w /workspace \
  swift:6.1-noble swiftc -frontend -parse <changed-swift-files>
```

Before macOS/device readiness claims:

```bash
xcodebuild -project browser/Reynard.xcodeproj \
  -scheme Reynard \
  -destination 'generic/platform=iOS' \
  build
```

Physical iOS 16 verification remains mandatory for keyboard behavior, Gecko
integration, 60/120 Hz animation evidence, VoiceOver, Reduce Motion,
background/resume, JIT recovery, and content-process recovery.

## Plan Basis

- **Fact:** the user approved a complete Firefox-inspired, original UIKit
  redesign with phone bottom chrome, iPad top chrome/sidebar, modular homepage,
  elegant motion, and a 120 Hz ProMotion target.
- **Fact:** current frontend pressure includes `AddressBar.swift` at 1,102
  lines, `BrowserViewController.swift` at 860 lines, and
  `AddressBarGestures.swift` at 840 lines.
- **Fact:** existing stores, tab/session owners, Gecko bridge, address position,
  homepage sections, and much of the browser functionality already exist.
- **Assumption:** vertical replacement with immediate old-path retirement is
  safer than a one-shot rewrite.
- **Unknown:** physical-device frame pacing and UIKit/Gecko integration cannot
  be proven on WSL.

## BaselineUsageDraft

- **Required refs:** approved redesign spec, Via/stability design, initial
  baseline, and current UI/runtime owners.
- **Acknowledged refs:** Gecko-only runtime, existing tab/store authority,
  approved visual behavior, accessibility/performance requirements, and old UI
  retirement requirement.
- **Cited refs:** headers and phase file maps below.
- **Missing refs:** Xcode and physical-device evidence.
- **Decision:** `continue`; final readiness stays `needs-verification` without
  missing platform evidence.

## Requirement Ready Check

- **Requirement source:** approved redesign design and Via Phase 1 acceptance.
- **Scenarios:** one-handed iPhone browsing and iPad browsing with a tab sidebar.
- **Acceptance:** design sections 12–14 and the task acceptance below.
- **Open blocker questions:** none for source execution.
- **Decision:** `ready`.

## Ripple Signal Triage

- Chrome replacement affects keyboard docking, overlays, fullscreen, tab
  transitions, page zoom, menus, downloads, and recovery presentation.
- Tab-surface replacement affects thumbnail capture, transition snapshots,
  regular/private grouping, sidebar hosting, and state persistence.
- Homepage replacement affects bookmarks, history, recently closed tabs,
  private-mode filtering, and homepage preferences.
- Via content features affect Gecko event/WebExtension boundaries, site
  settings, diagnostics, and backup/export schemas.
- Verification must therefore expand by phase rather than relying on isolated
  view parsing.

## Architecture Integrity Lens

- **Invariant:** presentation may change completely while runtime/data truth
  remains owned by Gecko, `SessionManager`, `TabManager`, and existing stores.
- **Canonical owner:** each extracted UI responsibility has one focused owner;
  views do not acquire persistence or Gecko-content execution responsibility.
- **Responsibility overlap:** old owners remain active only during the bounded
  migration commit sequence.
- **Higher-level simplification:** shared semantic design/motion policy and
  action/tab/home presentation contracts replace repeated local constants and
  caller-side state patches.
- **Retirement:** every phase includes old-path searches and deletion criteria.
- **Verdict:** `proceed`.

## Plan Pressure Test

- **Owner/contract/retirement:** explicit in every task.
- **Architecture integrity:** no second tab/store/runtime owner.
- **Verification scope:** portable tests plus parse/structural checks now;
  Xcode/device evidence tracked separately.
- **Task executability:** phases are ordered so later UI consumes earlier design
  and motion owners.
- **Pressure result:** `proceed`.

## Complexity Budget

- **Artifact class:** high-complexity UIKit shell and interaction program.
- **Target artifacts:** browser chrome, address bar, root controller, tab
  presentation, homepage, library/settings, Gecko feature wrappers.
- **Current pressure:** three 800+ line UI owners and multiple 600+ line
  presentation owners.
- **Projected pressure:** over-budget if work is added in place.
- **Budget result:** `at-risk` but governed.
- **Planned governance:** focused owner extraction, per-phase line/responsibility
  movement, and delete-after-migration.

## File Map

### Phase 0 — create

- `browser/Reynard/BrowserCore/MotionPolicy.swift`
- `Tests/ReynardBrowserCoreTests/MotionPolicyTests.swift`
- `browser/Reynard/Client/Interface/DesignSystem/BrowserDesignTokens.swift`
- `browser/Reynard/Client/Interface/DesignSystem/BrowserMotion.swift`
- `browser/Reynard/Client/Interface/DesignSystem/BrowserMaterialStyle.swift`
- `browser/Reynard/Client/Interface/Diagnostics/BrowserFrameMonitor.swift`

### Phase 1 — create/modify

- Create `Chrome/ChromePresentationState.swift`.
- Create `Chrome/Toolbar/ToolbarAction.swift` and
  `Chrome/Toolbar/ToolbarActionLayout.swift`.
- Create address-bar owner files for text/autocomplete state, rendering, and
  transition presentation under `Chrome/AddressBar/`.
- Modify `BrowserChrome.swift`, `AddressBar.swift`, `AddressBarGestures.swift`,
  top/bottom toolbar files, `BrowserViewController.swift`, appearance settings,
  `BrowserPreferences.swift`, and localization.
- Delete migrated constants/state/branches from the old large owners.

### Phase 2 — create/modify

- Create `browser/GeckoView/Session/FindInPage/FindInPageResult.swift`.
- Create `browser/GeckoView/Session/FindInPage/SessionFinder.swift`.
- Create `Tests/ReynardGeckoCoreTests/FindInPageResultTests.swift` and a focused
  SwiftPM target in `Package.swift`.
- Create `Chrome/ActionBar/FindInPage/FindInPageActionBar.swift`.
- Create `Coordinators/FindInPageCoordinator.swift`.
- Modify `GeckoSession.swift`, `ActionBar.swift`, `BrowserChrome.swift`, address
  menu/delegate wiring, `BrowserViewController` action wiring/tab updates,
  keyboard docking, and localization.

### Phase 3 — create/modify

- Create shared tab presentation snapshot/layout/style types under
  `TabOverview/Presentation/`.
- Create a phone card-grid controller/cells and an interactive tab transition
  owner.
- Refactor the existing iPad sidebar into the canonical collapsible tab sidebar.
- Modify `TabOverview`, `TabOverviewCollection`, `TabOverviewPresentation`,
  `SidebarCoordinator`, `BrowserViewController+TabPresentation`, and thumbnail
  routing.
- Delete obsolete duplicated phone/pad animation paths after migration.

### Phase 4 — create/modify/delete

- Create homepage module descriptors/layout and shared section styling under
  `Homepage/Presentation/`.
- Modify `HomepageRootViewController`, favorites, frequently visited, recently
  closed, homepage settings, and preferences to support module order/visibility.
- Delete donation/performance recommendation presentation and its scheduling
  preferences so the redesigned homepage contains no promoted content.
- Preserve bookmark/history/recent-tab store ownership.

### Phase 5 — create/modify

- Create shared library/settings list appearance components under
  `Library/Presentation/`.
- Migrate bookmarks, history, downloads, root settings, site settings, and
  frequently used preference screens to semantic design tokens.
- Split oversized screen-specific action/presentation blocks only when the
  extraction creates one clear owner.
- Do not add generic store/repository wrappers.

### Phase 6 — create/modify

- Night mode: create Gecko/WebExtension-facing dark-mode configuration plus
  per-site UI owned by existing site settings.
- Blocking: create a built-in WebExtension configuration owner, subscription and
  custom-rule stores using existing storage patterns, per-site disable, visible
  count, update diagnostics, and settings UI.
- User scripts: create metadata/import/edit/toggle/scope UI and route execution
  exclusively through Gecko WebExtension `userScripts` capability.
- Privacy: expose approved Gecko cookie/tracker/site-data controls without a
  second settings store.
- Backup: create a versioned local archive exporter/importer for approved
  categories with validation and transactional restore.
- Each large feature receives its own bounded slice card/checkpoint before edit.

### Phase 7 — modify/delete

- Delete old UI owners, temporary adapters, obsolete assets/localization keys,
  recommendation UI, and lingering callbacks proven unused.
- Update architecture/baseline/ADR evidence from the implemented owner graph.
- Add macOS/iOS device checklists and performance evidence slots.

## Task 1: Establish the redesign program checkpoint

**Why:** all later phases need one resumable todo/evidence/drift owner.

**Files:** this plan plus `docs/aegis/work/2026-07-20-browser-frontend-redesign/`.

- [ ] Create the helper-backed work record with all phase todos and non-goals.
- [ ] Record approved spec and baseline usage.
- [ ] Record WSL/Xcode/device evidence boundaries.
- [ ] Run Aegis workspace check.
- [ ] Commit `docs: plan browser frontend redesign`.

## Task 2: Phase 0 — portable motion policy

**Why:** motion selection must be deterministic and testable without UIKit.

**Impact/Compatibility:** add presentation policy only; no runtime/data owner
changes.

- [ ] Add RED tests for full/reduced motion profiles, 60/120 Hz budgets, and
  non-ProMotion fallback.
- [ ] Run focused tests and observe missing policy types.
- [ ] Implement `MotionPolicy` with immutable profiles selected from Reduce
  Motion and maximum refresh-rate inputs.
- [ ] Run all portable tests and expect GREEN.
- [ ] Commit `feat: add browser motion policy`.

## Task 3: Phase 0 — UIKit design and motion owners

**Why:** later views must consume semantic tokens rather than duplicate visual
constants.

**Impact/Compatibility:** new frontend-only owners; existing appearance remains
until consuming slices migrate.

- [ ] Add semantic colors, typography, spacing, radii, controls, and private-mode
  variants.
- [ ] Add `BrowserMotion` helpers that produce interruptible property animators
  and Reduce Motion substitutions from `MotionPolicy`.
- [ ] Add material/shadow application helpers and a DEBUG-only signpost/frame
  monitor with bounded sampling.
- [ ] Parse the new UIKit sources and run all portable tests.
- [ ] Commit `feat: add browser design and motion system`.

## Task 4: Phase 1 — chrome state and toolbar configuration

**Why:** top/bottom/iPad chrome and configurable actions need one transient
presentation contract.

**Impact/Compatibility:** existing address position preference is retained;
toolbar actions add allowlisted preference values in the current preferences
owner.

- [ ] Add portable tests for toolbar validation: back/forward, tab access, menu,
  and recovery routes cannot all be removed.
- [ ] Add `ChromePresentationState`, `ToolbarAction`, and layout resolution.
- [ ] Update top/bottom toolbars to render validated action arrays and semantic
  design tokens.
- [ ] Add toolbar configuration settings and localization.
- [ ] Parse, structurally verify owner routing, run tests, and commit
  `feat: add configurable redesigned browser chrome`.

## Task 5: Phase 1 — decompose address-bar presentation

**Why:** the 1,102-line address bar currently mixes state, rendering, editing,
menus, and transitions.

**Impact/Compatibility:** preserve `AddressBarDelegate`, search behavior,
autocomplete, menu actions, URL display, loading progress, and current gesture
behavior while moving responsibility.

- [ ] Extract text/autocomplete state and pure render-model resolution with
  portable tests.
- [ ] Extract rendering/application and transition presentation into focused
  UIKit owners.
- [ ] Move menu creation/remapping behind the existing menu builder owner.
- [ ] Reduce `AddressBar.swift` and `AddressBarGestures.swift`; delete migrated
  state/branches and verify no duplicate owner remains.
- [ ] Parse, run tests, record line/responsibility delta, and commit
  `refactor: decompose redesigned address bar`.

## Task 6: Phase 2 — Gecko-native finder contract

**Why:** Via parity requires native query, previous/next, match count, and clear
without a Swift JavaScript engine.

**Impact/Compatibility:** mirror pinned Gecko `SessionFinder` events; no Gecko
patch unless device evidence proves the contract unavailable.

- [ ] Add RED portable tests for `found`, `wrapped`, `current`, `total`, query,
  and malformed payload parsing.
- [ ] Add the focused Gecko core test target and `FindInPageResult` parser.
- [ ] Add `SessionFinder` query/display/clear methods and expose one finder from
  `GeckoSession`.
- [ ] Parse GeckoView sources and run all portable tests.
- [ ] Commit `feat: add Gecko find in page bridge`.

## Task 7: Phase 2 — redesigned find action surface

**Why:** users need an immediate Firefox-style browser action with correct
keyboard and tab/session lifetime.

**Impact/Compatibility:** use existing action-bar and browser chrome; all
highlights clear on close, navigation, tab switch, session replacement, or
forced chrome dismissal.

- [ ] Add the find action to canonical page menus and the action-bar item enum.
- [ ] Implement query field, count, previous, next, close, Dynamic Type,
  VoiceOver labels, and semantic design tokens.
- [ ] Implement coordinator debounce, request generation, stale-result rejection,
  selected-session tracking, errors, and diagnostics.
- [ ] Dock bottom chrome above the keyboard when the find field is focused and
  avoid relocating Gecko content as though a webpage input were focused.
- [ ] Parse, run tests/structural checks, and commit
  `feat: add redesigned find in page`.

## Task 8: Phase 3 — shared tab presentation and phone card grid

**Why:** replace mixed phone/pad animation logic with one canonical tab
presentation model and transition owner.

**Impact/Compatibility:** `TabManager` remains authoritative; snapshots are
ephemeral.

- [ ] Add portable layout/state tests for regular/private grouping, selection,
  insertion, reorder projections, and compact-width columns.
- [ ] Implement semantic card style and diffable phone grid from canonical tabs.
- [ ] Implement interruptible open/close/selection/reorder transitions using
  transforms/opacity and bounded snapshots.
- [ ] Route all actions to `TabManager` and retire migrated phone animation paths.
- [ ] Parse, run tests, record complexity/retirement evidence, and commit
  `feat: redesign phone tab grid`.

## Task 9: Phase 3 — iPad collapsible tab sidebar

**Why:** approved iPad behavior requires persistent but collapsible tab access.

**Impact/Compatibility:** reuse existing sidebar host and canonical tab arrays;
no sidebar-specific tab state.

- [ ] Add sidebar presentation state tests for collapsed/expanded widths and
  regular/private grouping.
- [ ] Implement tab rows/cards, pointer/keyboard actions, reorder, close, and
  selection.
- [ ] Add interruptible sidebar motion and split-view adaptation.
- [ ] Delete obsolete iPad tab presentation branches.
- [ ] Parse, run tests, and commit `feat: redesign iPad tab sidebar`.

## Task 10: Phase 4 — modular homepage

**Why:** approved homepage is minimal, reorderable, and contains no promoted
content.

**Impact/Compatibility:** preserve bookmark/history/tab owners; extend current
homepage preferences with validated module order.

- [ ] Add tests for module-order decoding, unknown-value removal, required
  search/favorites behavior, and private-mode filtering.
- [ ] Implement semantic module/card layouts and reorder UI.
- [ ] Migrate favorites, frequent sites, and recent tabs without duplicating
  their stores.
- [ ] Remove recommendation modules and their scheduling preferences/references.
- [ ] Parse, run tests, validate retirement searches, and commit
  `feat: redesign modular homepage`.

## Task 11: Phase 5 — unified library, site settings, and preferences

**Why:** full frontend completion requires consistent navigation/list/card
presentation outside the browser shell.

**Impact/Compatibility:** retain all stores and settings keys unless a key is
explicitly retired with migration-safe default behavior.

- [ ] Add shared semantic list/card/header/empty-state components.
- [ ] Migrate bookmarks and history, preserving actions, folders, selection,
  clear flows, and browser navigation.
- [ ] Migrate downloads, root settings, appearance/browsing/homepage settings,
  and site settings.
- [ ] Split any newly over-budget screen owner and delete superseded local style
  implementations.
- [ ] Parse all touched screens, validate localization, run tests, and commit
  `refactor: unify browser library and settings UI`.

## Task 12: Phase 6 — night mode and per-site controls

**Why:** Via parity requires app theme plus optional Gecko-owned page darkening.

**Impact/Compatibility:** site settings remains the persistent per-site owner;
Swift does not execute page scripts.

- [ ] Write portable tests for global/site resolution and exception precedence.
- [ ] Add Gecko/WebExtension darkening configuration and capability diagnostics.
- [ ] Add toolbar toggle, settings, and per-site exception UI.
- [ ] Verify navigation/tab changes apply the canonical resolved setting and no
  hidden fallback exists.
- [ ] Commit `feat: add Gecko-backed night mode`.

## Task 13: Phase 6 — ad/tracker blocking

**Why:** Via parity requires built-in, user-controlled blocking with visible
state and recovery.

**Impact/Compatibility:** Gecko WebExtension owns request/content blocking;
Swift owns filter configuration, updates, site exceptions, and diagnostics.

- [ ] Add tested filter subscription/custom-rule models and failure states.
- [ ] Add built-in extension installation/configuration and blocked-count event
  bridge.
- [ ] Add global/per-site controls, update UI, custom rules, and visible errors.
- [ ] Add bounded update retry and diagnostics; reject hidden proxy/native
  duplicate blocking.
- [ ] Commit `feat: add Gecko ad and tracker blocking`.

## Task 14: Phase 6 — user scripts

**Why:** Via parity requires Greasemonkey-compatible import/edit/toggle/scope.

**Impact/Compatibility:** execution belongs exclusively to Gecko WebExtension
`userScripts`; Swift persists validated metadata and source text.

- [ ] Add parser/permission/scope tests and migration-safe script records.
- [ ] Add Gecko capability bridge and explicit unsupported-state UI.
- [ ] Add import, permission review, edit, enable/disable, remove, update, and
  per-site exception flows.
- [ ] Add diagnostics and ensure private-mode behavior is explicit.
- [ ] Commit `feat: add Gecko user script management`.

## Task 15: Phase 6 — privacy controls and backup portability

**Why:** users need observable privacy settings and migration between
independently signed TrollStore installations.

**Impact/Compatibility:** approved stores remain authoritative; restore is
validated and transactional; excluded private/sensitive categories stay out.

- [ ] Add tested privacy-setting resolution and Gecko application paths.
- [ ] Add third-party cookie/tracker/site-data controls and reset UI.
- [ ] Define and test a versioned backup manifest for approved categories.
- [ ] Implement export/import validation, transactional restore, conflict/error
  reporting, and excluded-category assertions.
- [ ] Commit `feat: add privacy controls and portable backup`.

## Task 16: Phase 7 — retire old frontend and verify integrated behavior

**Why:** the redesign is incomplete while old owners/fallbacks remain or
platform evidence is missing.

**Impact/Compatibility:** source deletion only; no persistent user data deletion.

- [ ] Search old owners, adapters, selectors, notifications, assets,
  localization, and recommendation references.
- [ ] Delete superseded UI paths and update project/document ownership evidence.
- [ ] Run full portable tests, parse, JSON validation, structural anti-WebKit and
  single-owner checks, Aegis bundle/check, and complexity closure.
- [ ] On macOS/devices, run Xcode build, iOS 16 matrix, 60/120 Hz traces,
  accessibility, lifecycle, JIT, and process-recovery checks.
- [ ] Commit source retirement and final evidence separately; remain
  `needs-verification` where external evidence is unavailable.

## Risks

- Xcode/UIKit type errors can survive WSL parsing.
- Pinned Gecko may expose event contracts differently on the iOS integration
  build; device evidence decides whether a bridge patch is necessary.
- 120 Hz is OS/hardware dependent and cannot be guaranteed by source alone.
- Library/settings visual migration can create scope creep unless data owners
  remain untouched.
- Blocking, scripts, and backup each require independent security and migration
  verification; they must remain bounded slices inside the program.

## Retirement

- No permanent legacy/new UI feature flag.
- Delete old responsibility after every verified migration slice.
- Retain compatibility adapters only for a proven current caller and record the
  exact next deletion trigger.
- Remove donation/performance recommendation UI and scheduling keys during the
  homepage phase.
- Never delete persistent source-of-truth data as part of frontend retirement.
