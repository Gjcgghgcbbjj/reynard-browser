# Reynard Browser Frontend Redesign Baseline

Date: `2026-07-20`
Status: `client-source-complete, gecko-runtime-and-external-verification-pending`
Decision record: `docs/aegis/adr/ADR-0001-frontend-surfaces-and-gecko-feature-ownership.md`

## Current frontend owners

- `BrowserViewController` remains the composition root; focused coordinators and views own individual surfaces.
- `BrowserDesignTokens`, `BrowserMotion`, `BrowserMaterialStyle`, and `BrowserFrameMonitor` own semantic presentation, interruptible motion, Reduce Motion behavior, and bounded frame diagnostics.
- `BrowserChrome` owns responsive top/bottom chrome; configurable toolbar actions preserve Back, Tabs, and Menu recovery routes.
- `SessionFinder` and `FindInPageCoordinator` own Gecko-native find-in-page execution and client lifecycle cleanup.
- `TabManager` remains the only live-tab authority. `TabOverview` is the phone card-grid projection; `SidebarTabListViewController` is the iPad projection.
- Homepage order is a validated preference projection over existing bookmark/history/tab owners; promoted recommendation modules no longer exist.
- `BrowserListStyle` owns shared library/settings/site-control presentation without replacing stores.

## Gecko feature contract

- `SessionFeatureBridge` is the only client bridge for night mode, content blocking, user scripts, and privacy application.
- Gecko/WebExtension remains the execution owner; Swift owns validated configuration, per-site overrides, portable metadata/source persistence, diagnostics, and UI.
- The contract events are `Reynard:Features:GetCapabilities`, `NightMode`, `ContentBlocking`, `UserScripts`, and `Privacy`.
- Missing capabilities are user-visible in Web Features settings and diagnostic-visible; there is no WebKit, native proxy, or Swift script-execution fallback.

## Persistence and portability

- Existing stores remain authoritative for tabs, bookmarks, history, downloads, and permissions.
- Browser feature preferences use the existing `BrowserPreferences` owner.
- Portable backup is versioned and limited to feature preferences, user scripts, and filter configuration; private tabs, cookies, credentials, and browser databases are excluded.

## Retirement state

- Retired: homepage performance/donation/update recommendation controllers and donation scheduling preferences.
- Retired: iPad-specific tab-overview presentation/dismissal animation branches.
- Retained: phone card grid, iPad collapsible sidebar, Gecko capability diagnostics, and existing store/session owners.

## Verification state

- Passed: 67 portable tests, parse of 330 Swift files, all JSON/string-catalog validation, Aegis workspace check, anti-WebKit/SwiftUI searches, and legacy-owner searches.
- Pending: macOS/Xcode type checking/build/link/resource validation; pinned Gecko capability response; iOS 16 phone/iPad, VoiceOver, Reduce Motion, recovery, and 60/120 Hz Instruments evidence.
