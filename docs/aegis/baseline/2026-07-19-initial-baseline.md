# Reynard Browser Initial Baseline

Date: `2026-07-19`
Status: `initial dual-baseline snapshot`

## 1. Purpose

This baseline records the upstream state selected for an iOS 16 stability and
usability track. Later work should use it to distinguish user-facing reliability
requirements from the existing Gecko/iOS ownership boundaries.

## 2. Workspace Structure

- `browser/Reynard/`: UIKit browser client, browser chrome, tab/session state,
  persistence, JIT control, settings, downloads, and user-facing recovery UI.
- `browser/GeckoView/`: Gecko-facing app extension boundary.
- `browser/Helper/`: helper extension and process bridge.
- `engine/firefox/`: pinned Firefox/Gecko submodule.
- `patches/`: project-owned Gecko integration patches.
- `support/idevice/`: pinned device/JIT support submodule.
- `tools/development/`: Gecko acquisition, patching, and development builds.
- `tools/release/`: app build and IPA/TIPA packaging.

## 3. Current Authority Surfaces

- Product description and supported installation paths: `README.md`.
- Runtime behavior: source under `browser/`, `patches/`, and pinned submodules.
- Upstream issue evidence: `https://github.com/minh-ton/reynard-browser/issues`.
- Current user direction: support iOS 16 without Apple browser-engine
  entitlement, distribute as open source for TrollStore users, and prioritize
  stability and usability over adding features.
- No repository-local ADR, product specification, or automated test suite was
  present before this Aegis workspace was initialized.

## 4. Product / Requirement Baseline

### 4.1 Current Truth

- Reynard is a real Gecko-based browser rather than a `WKWebView` shell.
- The upstream project advertises iOS 13+ and specifically recommends
  TrollStore for iOS 14 through 16.6.1 and iOS 17.0.
- The selected delivery target is iOS 16 with TrollStore packaging.
- The selected phase goal is to make existing browsing behavior dependable:
  predictable startup, recoverable JIT failures, resilient tab/session state,
  controlled memory behavior, and actionable error reporting.
- Existing browser capabilities should be preserved unless a capability is
  proven to be the direct cause of instability.

### 4.2 Non-negotiables

1. Web content rendering remains Gecko-based; WebKit is not introduced as the
   normal rendering path or a silent fallback.
2. The iOS 16/TrollStore build must not depend on Apple's BrowserEngineKit or
   alternative-engine entitlement.
3. The project remains redistributable as open source under the existing GPLv3
   application and MPL 2.0 Gecko-patch boundaries.
4. Stability fixes take priority over new user-facing features.
5. Failure must produce a recoverable state or an actionable diagnostic rather
   than an unexplained crash, blank page, or lost regular browsing session.

### 4.3 Product Non-goals

- App Store eligibility or Apple entitlement acquisition.
- A Blink port.
- Cloud rendering or a proxy service.
- Account sync, password sync, or a new extension ecosystem.
- A visual redesign unrelated to stability or recovery.

## 5. Architecture / Runtime Boundary Baseline

### 5.1 Current Truth

- Gecko remains the canonical owner of HTML/CSS/JavaScript execution and web
  platform behavior.
- Gecko/iOS integration changes belong in `patches/`; the browser client must
  not copy engine behavior into Swift.
- `JITController` and its supporting Objective-C/C code own JIT discovery,
  attachment, watchdog behavior, and the JIT-less fallback decision.
- `SessionManager` owns Gecko session activation, foreground/background state,
  cleanup, permissions, and picture-in-picture lifecycle coordination.
- `TabManagerImpl` owns live tab orchestration; `TabManagementStore` owns the
  persisted tab snapshot and SQLite transaction boundary.
- Store classes own persisted browser data. UI controllers consume stores and
  must not create parallel persistence sources.
- The current client contains about 57,900 lines of Swift/Objective-C/C++
  integration code and has no checked-in unit/UI test target.

### 5.2 Architecture Non-negotiables

1. Each recovery behavior has one canonical owner.
2. Upstream Gecko modifications remain explicit, reviewable patches.
3. JIT-less operation is an explicit degraded mode, not a hidden success state.
4. Persistent state changes are transactional and migration-safe.
5. Diagnostics must avoid storing secrets, form contents, cookies, or full URLs
   unless the user explicitly chooses to include them in an export.

### 5.3 Architecture Non-goals

- Replacing UIKit with SwiftUI.
- Rewriting existing stores solely for style consistency.
- Forking large Gecko subsystems to solve client-layer lifecycle defects.
- Adding a second tab/session recovery database.

## 6. Ownership / Contract Snapshot

| Surface | Canonical owner |
| --- | --- |
| Web rendering and JavaScript | Gecko submodule plus explicit `patches/` |
| Gecko view/process bridge | `browser/GeckoView/`, `browser/Helper/` |
| JIT state and attachment | `browser/Reynard/JIT/JITController.swift` and JIT support code |
| Session foreground/background lifecycle | `Client/SessionManagement/SessionManager.swift` |
| Live tab orchestration | `Client/TabManagement/TabManagerImpl.swift` |
| Persisted tab snapshots | `Client/Stores/TabManagementStore.swift` |
| Bookmarks/history/download persistence | corresponding `Client/Stores/*Store.swift` |
| User-facing browser recovery | browser/session coordinators, with diagnostics supplied by one shared diagnostics owner |

## 7. Current State and Risks

- The upstream project is active and releases working IPA/TIPA artifacts, but
  it is explicitly alpha software.
- Current open issues include lost tabs after backgrounding and a requested JIT
  retry path, both aligned with the selected stability goal.
- Full engine builds require macOS, Xcode, Rust, Python, `ldid`, substantial
  storage, and the Firefox and idevice submodules.
- Private entitlements, helper extensions, JIT timing, memory pressure, and OS
  process termination make device verification mandatory.
- Large store and controller files create change-pressure; stability work should
  add focused owners only where doing so removes duplicated recovery logic.

## 8. Alignment Use

- Read the Product / Requirement Baseline before prioritizing features or
  defining release acceptance.
- Read the Architecture / Runtime Boundary Baseline before changing JIT,
  process/session lifecycle, persistence, or Gecko patches.
- Report `scope: both` when a user-visible failure requires changes across the
  Gecko bridge and browser-client recovery flow.

## 9. Compatibility Boundary

- Preserve existing regular-tab, history, bookmark, download, permission, and
  settings data where schemas remain valid.
- Preserve upstream updateability by keeping local changes small and rebasing
  them onto upstream rather than replacing upstream-owned modules wholesale.
- The primary release boundary is TrollStore-capable iOS 16 devices, including
  both arm64 and arm64e hardware where test access is available.
