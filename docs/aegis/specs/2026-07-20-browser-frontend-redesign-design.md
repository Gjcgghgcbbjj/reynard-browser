# Reynard Browser Frontend Redesign Design

Date: `2026-07-20`
Status: `approved direction; written-spec review pending`
ArchitectureReviewRequired: `yes`

## 1. TaskIntentDraft

- **Requested outcome:** fully redesign the browser frontend while continuing
  Via-like functional parity work.
- **Goal:** deliver an original Firefox-inspired UIKit interface that remains
  stable on iOS 16, preserves Gecko and existing data owners, and targets fluid
  120 Hz interaction on ProMotion devices.
- **Success evidence:** the redesigned browser shell, tabs, homepage, library,
  and settings satisfy the acceptance criteria in this document; existing
  regular/private tab and user-data behavior remains intact; Via Phase 1
  features integrate through their canonical Gecko/client owners; physical
  device performance and accessibility checks pass.
- **Stop condition:** the phased frontend plans finish, or execution stops with
  a documented blocker, scope-exceeded state, or missing iOS/Xcode evidence.
- **Non-goals:** SwiftUI migration, WebKit, a new tab/session database, store
  rewrites, Via branding/assets, IPA packaging, or CloudKit implementation.

## 2. Confirmed Product Direction

- Visual language is Firefox-inspired but original to Reynard.
- Phone address bar defaults to the bottom; iPad defaults to the top. Users can
  change the position in settings.
- Phone tabs use a card grid. iPad uses a collapsible sidebar. Both surfaces
  support regular/private grouping, reorder, selection, and close gestures.
- Homepage is modular and minimal: search, reorderable favorites, frequently
  visited sites, and recent tabs. Every optional module can be disabled. No
  news, promotions, or sponsored content is introduced.
- Motion uses restrained, interruptible spring transitions. ProMotion devices
  target 120 Hz; other devices target stable 60 Hz. Reduce Motion is respected.
- UIKit remains the frontend technology because it is the lowest-risk owner for
  Gecko embedding, interactive transitions, keyboard handling, and iOS 16.

## 3. BaselineReadSetHint

- `docs/aegis/baseline/2026-07-19-initial-baseline.md`
- `docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md`
- `browser/Reynard/Client/Interface/BrowserViewController.swift`
- `browser/Reynard/Client/Interface/Chrome/BrowserChrome.swift`
- `browser/Reynard/Client/Interface/Chrome/AddressBar/AddressBar.swift`
- `browser/Reynard/Client/Interface/Chrome/AddressBar/AddressBarGestures.swift`
- `browser/Reynard/Client/Interface/TabOverview/`
- `browser/Reynard/Client/Interface/Homepage/`
- `browser/Reynard/Client/TabManagement/TabManager.swift`
- `browser/Reynard/Client/SessionManagement/SessionManager.swift`

## 4. BaselineUsageDraft

- **Required refs:** the initial dual baseline, approved stability/Via design,
  and current browser shell, chrome, tab, homepage, and runtime owners.
- **Acknowledged refs:** Gecko-only rendering, iOS 16/TrollStore target,
  existing store and tab/session ownership, Via Phase 1 acceptance, and the
  current UIKit component structure.
- **Cited refs:** section 3 plus the ownership matrix below.
- **Missing refs:** Xcode compilation, 60 Hz device traces, 120 Hz ProMotion
  traces, and physical iOS 16 accessibility evidence.
- **Decision:** `continue` for design/planning; release acceptance remains
  `needs-verification` until device evidence exists.

## 5. Requirement Ready Check

- **Requirement source:** user-approved choices in the 2026-07-20 design
  dialogue and the existing Via Phase 1 design.
- **Primary scenario:** a user browses one-handed on an iPhone, switches between
  regular/private tabs, uses power tools without opening deep settings, and can
  recover from engine or process failures without losing the current task.
- **Secondary scenario:** an iPad user keeps tabs visible in a collapsible
  sidebar and operates the browser with touch, pointer, or keyboard.
- **Acceptance source:** sections 12 through 15 of this document.
- **Open blocker questions:** none for architecture planning.
- **Decision:** `ready`.

## 6. First-Principles Decision Review

### First-principles invariants

- **Non-negotiable goal:** redesign presentation and interaction without
  destabilizing browsing, Gecko lifecycle, or persisted user data.
- **Non-negotiable constraints:** Gecko remains the renderer; UIKit remains the
  UI substrate; existing tab/session/store owners remain authoritative; iOS 16
  remains supported; old frontend paths do not remain as permanent fallbacks.
- **Historical assumptions to delete:** large view classes do not need to own
  gesture policy, rendering, menu construction, async feature state, and data
  orchestration simultaneously; a visual redesign does not require rewriting
  tab or persistence models.

### Owner / retirement matrix

- **New canonical owners:** a small design system, motion policy, focused chrome
  components, tab surfaces, and feature coordinators described in section 9.
- **Old owners:** oversized UIKit views retain responsibility only until their
  corresponding replacement slice is integrated and verified.
- **Compat-only carrier:** temporary adapters are allowed only inside one
  implementation slice and must name their deletion commit/trigger.
- **Retirement trigger:** all callers for a replaced responsibility use the new
  owner and the slice verification passes.

### Verdict

- **Adopt:** phased vertical replacement with delete-after-migration.
- **Reject:** one-shot monolithic rewrite and permanent legacy/new UI feature
  flags.

## 7. Options Considered

### Option A: one-shot frontend rewrite

- **Benefit:** fastest route to visual consistency.
- **Cost:** combines chrome, keyboard, tab, store, Gecko, and transition risks
  into one unreviewable integration point.
- **Decision:** rejected.

### Option B: phased vertical replacement

- **Benefit:** each phase is usable and reviewable, old ownership can be
  deleted promptly, and regressions have a bounded source.
- **Cost:** requires disciplined interface boundaries and repeated device
  checks.
- **Decision:** selected.

### Option C: restyle existing views in place

- **Benefit:** smallest initial diff.
- **Cost:** preserves the current oversized responsibility bundles and cannot
  satisfy the structural-refactor requirement.
- **Decision:** rejected as the primary strategy.

## 8. Product and Visual System

### 8.1 Visual language

- Original Reynard colors and icon usage; no Firefox or Via assets are copied.
- Dense but readable browser chrome, rounded control groups, clear active-tab
  emphasis, and restrained material use.
- System typography remains the base for Dynamic Type and iOS 16 behavior.
- Private mode is visually distinct without reducing contrast or hiding state.

### 8.2 Design tokens

Create one frontend design-system boundary for:

- semantic colors and private-mode variants;
- spacing, corner radii, control sizes, and chrome insets;
- typography roles and Dynamic Type scaling;
- shadow/material policy;
- animation durations, damping, velocity, and Reduce Motion substitutions.

Feature views consume semantic tokens instead of introducing local copies.
Tokens are presentation constants, not a parallel preferences store.

### 8.3 Responsive behavior

- **Phone portrait:** bottom address bar and compact toolbar by default.
- **Phone landscape/compact width:** condensed top chrome with reachable tab
  and menu actions.
- **iPad:** top address bar plus collapsible tab sidebar; constrained split-view
  layouts use compact controls without losing navigation actions.
- User-selected address-bar position overrides the default where the current
  size class can safely represent it.

## 9. Target Architecture

### 9.1 Composition root

`BrowserViewController` remains the canonical browser composition root. It is
reduced to lifecycle, owner wiring, and top-level presentation decisions. It
does not become a second tab/session/store owner.

### 9.2 Browser chrome

`BrowserChrome` remains the browser-chrome container and is decomposed into:

- address presentation and text editing;
- menu construction;
- toolbar layout and user-selected actions;
- action surfaces such as page zoom and find in page;
- responsive positioning driven by `BrowserLayout`.

The current `AddressBar.swift` and `AddressBarGestures.swift` responsibilities
are split by behavior. Gesture transition policy, text/autocomplete state, menu
building, and rendering do not remain in one view class.

### 9.3 Tab surfaces

- `TabManager` remains the sole live-tab authority.
- Phone tab grid and iPad sidebar are two presentations of the same tab arrays
  and selected-mode/index state.
- Presentation snapshots are ephemeral and must not be persisted as a second
  tab model.
- Reorder/close/select actions route back to `TabManager`.
- Interactive transitions are owned by a tab-surface transition coordinator,
  not by individual cells.

### 9.4 Homepage

- Existing bookmark/history/tab/settings owners continue supplying data.
- Homepage modules own presentation and user interaction only.
- Module visibility/order uses the existing browser-preferences owner.
- Favorites reorder mutations route to the existing favorites/bookmark owner.
- No recommendation or promoted-content module is added.

### 9.5 Library and settings

- Bookmarks, history, downloads, site settings, and preferences retain their
  existing data owners.
- Screens migrate to a shared list/card visual system incrementally.
- The redesign does not introduce generic repository/view-model layers solely
  to wrap existing stores.

### 9.6 Via feature coordinators

- **Find in page:** a GeckoView-owned `SessionFinder` wrapper dispatches the
  upstream `GeckoView:FindInPage`, `GeckoView:DisplayMatches`, and
  `GeckoView:ClearMatches` contracts. A client coordinator owns debounce,
  selected-session lifetime, stale-result rejection, and action-bar updates.
- **Night mode:** content darkening remains Gecko/WebExtension-owned; UIKit owns
  the toggle and per-site presentation only.
- **Blocking and user scripts:** Gecko WebExtensions remain the execution
  boundary. Swift owns configuration and diagnostics, not content execution.
- **Toolbar configuration:** preferences store the selected action identifiers;
  browser chrome validates that navigation, tabs, and recovery remain
  reachable.

## 10. Data and Event Flow

```text
Stores / TabManager / SessionManager / Gecko
                    ↓
        BrowserViewController composition
                    ↓
       focused coordinators and presenters
                    ↓
             UIKit component tree

User gesture or action
        ↓
UIKit component callback
        ↓
coordinator / BrowserViewController
        ↓
canonical TabManager, SessionManager, Store, or Gecko owner
```

Views must not mutate persistent state directly unless the existing component
already is the canonical settings/store owner for that mutation.

## 11. Motion and Performance Design

### 11.1 Refresh-rate policy

- UIKit system animations are allowed to use the display's native refresh rate;
  the app must not cap ProMotion devices to 60 Hz.
- Custom display-link work, when unavoidable, uses the active screen's maximum
  frame rate and `preferredFrameRateRange` where supported.
- Standard transitions do not create display links merely to claim 120 Hz.

### 11.2 Animation implementation

- Use interruptible `UIViewPropertyAnimator` transitions for tab cards, sidebar,
  chrome mode changes, and gesture-driven presentation.
- Animate transforms and opacity on hot paths. Avoid constraint churn, live
  shadow rasterization, and continuously recomputed blur during gestures.
- Reuse snapshots only during bounded transitions; never replace live Gecko
  content with a persistent screenshot.
- Cancelled gestures return to a deterministic source state.

### 11.3 Performance targets

- ProMotion devices: core interactive transitions target an 8.33 ms frame
  budget and 120 Hz presentation when the OS permits it.
- 60 Hz devices: core transitions target a 16.67 ms frame budget.
- No sustained hitching during tab-grid open/close, tab selection, toolbar
  position changes, or sidebar interaction.
- Debug/instrumented builds use signposts and bounded frame sampling; production
  builds do not retain continuous performance logging.

### 11.4 Accessibility motion

- Reduce Motion replaces large scale/position transitions with short fades or
  small translations.
- Reduce Transparency replaces material-heavy surfaces with opaque semantic
  colors.
- All interactive animations remain cancellable without trapping focus.

## 12. Functional Acceptance

1. Existing regular/private tabs, navigation, history, bookmarks, downloads,
   permissions, and settings remain available after the redesign.
2. Phone bottom chrome and iPad top/sidebar layouts operate across supported
   orientations and split-view widths.
3. Address-bar position and toolbar actions are configurable without making
   navigation, tab access, or recovery unreachable.
4. Phone tab grid and iPad sidebar select, reorder, and close the same canonical
   tabs and visually distinguish private mode.
5. Homepage modules can be reordered/hidden and contain no promoted content.
6. Find in page reports match count, moves previous/next, and clears Gecko
   matches when closed, navigated, or switched to another tab.
7. Engine/process recovery UI remains reachable from the redesigned shell.
8. Dynamic Type, VoiceOver labels, pointer/keyboard focus, and Reduce Motion
   remain usable.

## 13. Visual and Interaction Acceptance

1. Tab-card selection uses a continuous source-to-destination transition rather
   than an unrelated fade or abrupt replacement.
2. Address-bar position changes preserve editing state and do not duplicate the
   text field or keyboard owner.
3. Toolbar, menu, and action-bar transitions are interruptible and return to a
   correct state after cancellation.
4. Compact layouts never hide all routes to tabs, navigation, settings, or
   recovery.
5. Private-mode styling meets contrast requirements and cannot be confused with
   regular mode solely because an animation is in progress.

## 14. Verification Strategy

### Portable and WSL checks

- Foundation-only policy/state tests through SwiftPM.
- Swift frontend parsing for modified UIKit/Gecko wrapper sources.
- localization JSON validation with duplicate-key detection.
- structural assertions for owner routing, old-path retirement, and forbidden
  WebKit/parallel-store additions.

### macOS/Xcode checks

- build all app and extension targets for an iOS 16 destination;
- run available unit/UI tests;
- verify warnings for concurrency, availability, constraints, and localization;
- inspect memory graph after repeated tab-grid and sidebar transitions.

### Physical device matrix

- at least one 60 Hz iOS 16 phone;
- at least one 120 Hz ProMotion iOS 16 phone when available;
- an iPad/iPadOS 16 device or equivalent device test slot;
- portrait, landscape, split view, Dynamic Type, VoiceOver, Reduce Motion,
  regular/private tabs, background/resume, process recovery, and JIT recovery.

### Performance evidence

- Instruments Core Animation trace for tab-grid open/close and tab selection;
- signpost/frame evidence for interactive chrome and sidebar transitions;
- residual hitches documented with device/build identifiers.

## 15. Delivery Phases

### Phase 0: design system and measurement

- Add semantic visual/motion tokens and debug performance signposts.
- Do not change data/runtime owners.

### Phase 1: browser shell and chrome

- Decompose address-bar and gesture responsibilities.
- Implement responsive Firefox-inspired chrome and configurable toolbar/position.
- Add the redesigned action-surface host.

### Phase 2: find in page

- Add the Gecko-native finder wrapper and client coordinator.
- Add query, previous, next, count, focus, keyboard docking, and close cleanup.

### Phase 3: tabs

- Replace phone tab overview with the new card grid.
- Replace iPad tab presentation with the collapsible sidebar.
- Add continuous interactive transitions and reorder behavior.

### Phase 4: homepage

- Replace homepage presentation with modular, reorderable sections.
- Preserve existing favorites/history/tab owners.

### Phase 5: library, site settings, and preferences

- Apply the design system to bookmarks, history, downloads, settings, and site
  controls without rewriting their stores.

### Phase 6: remaining Via daily-use features

- Night mode, blocking, user scripts, privacy controls, backup portability, and
  other approved items proceed as separate bounded plans through Gecko or the
  existing data owners.

### Phase 7: retirement and integrated verification

- Remove obsolete frontend owners, adapters, assets, and references.
- Run the full Xcode/device/accessibility/performance matrix.

## 16. Complexity Budget

- **Artifact class:** high-complexity UIKit shell and interaction redesign.
- **Current pressure:** `AddressBar.swift` exceeds 1,100 lines;
  `BrowserViewController.swift` and `AddressBarGestures.swift` exceed 800 lines;
  several tab/home/library owners exceed 600 lines.
- **Projected pressure:** over-budget if new visuals and Via features are added
  directly to the current large owners.
- **Budget result:** `at-risk`, governed by focused owner extraction and
  delete-after-migration.
- **Required governance:** each plan records pre/post line and responsibility
  movement, old-path deletion, adapters retained, and their retirement trigger.

## 17. Retirement Plan

- Old UI logic is located before each replacement slice begins.
- A replacement slice is not complete while old and new owners both carry live
  responsibility without a documented external compatibility need.
- Temporary adapters must be internal, behavior-free where possible, and
  deleted at the end of the same phase.
- Existing state/storage is retained; UI source deletion must never delete user
  data or persistent source-of-truth records.
- Lingering selectors, notifications, callbacks, assets, and localization keys
  are searched before each retirement commit.

## 18. ImpactStatementDraft

- **Affected layers:** UIKit browser shell, chrome, action surfaces, tab grid,
  sidebar, homepage, library/settings presentation, Gecko feature wrappers,
  accessibility, localization, and UI performance verification.
- **Canonical owners retained:** Gecko, `SessionManager`, `TabManager`, and
  existing stores/preferences.
- **New owners:** design/motion tokens, focused chrome components, tab-surface
  presentation/transition owners, homepage presentation modules, and bounded
  Via feature coordinators.
- **Invariants:** no WebKit, no second tab/store database, no permanent legacy
  UI fallback, no Via/Firefox asset copying, and no loss of recovery access.

## 19. ADR and Baseline Signals

- The redesign changes durable frontend ownership boundaries and therefore
  carries an ADR backfill signal after implemented architecture is verified.
- ADR evidence must include actual owner movement, retired paths, performance
  traces, and compatibility results rather than this unexecuted design alone.
- The Product / Requirement Baseline remains unchanged: Gecko, iOS 16,
  reliability-first behavior, and functional rather than branded Via parity.
