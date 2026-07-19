# Via Phase 1 Webpage Translation - Intent

## TaskIntentDraft

- Requested outcome: Add configurable webpage translation while preserving the original Gecko tab
- Goal: Add configurable webpage translation while preserving the original Gecko tab
- Success evidence:
- Portable provider tests, valid settings/menu source, macOS app build, and iOS 16 manual translation check
- Stop condition: Three plan tasks complete or execution stops with a documented blocker or needs-verification state
- Non-goals:
- Find in page, night mode, ad blocking, user scripts, CloudKit, IPA packaging
- Scope: Execute docs/aegis/plans/2026-07-19-via-translation.md
- Change kinds:
- feature
- Risk hints:
- Provider contracts are external and UIKit integration cannot compile on WSL

## BaselineReadSetHint

- docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md
- docs/aegis/baseline/2026-07-19-initial-baseline.md

## BaselineUsageDraft

- Required baseline refs:
- docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md
- docs/aegis/baseline/2026-07-19-initial-baseline.md
- Acknowledged before plan:
- docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md
- docs/aegis/baseline/2026-07-19-initial-baseline.md
- Cited in plan:
- docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md
- docs/aegis/baseline/2026-07-19-initial-baseline.md
- Missing refs:
- none
- Advisory decision: continue

## ImpactStatementDraft

- Compatibility boundary: HTTP(S) only; no credentials; same regular/private mode; no WebKit or proxy
- Affected layers:
- BrowserCore translation URL policy, preferences, settings UI, address-bar menu, tab navigation
- Owners:
- BrowserCore policy plus existing BrowserPreferences, AddressBarMenu, BrowserViewController, and TabManager owners
- Invariants:
- Gecko remains the renderer and the original tab is preserved
- Non-goals:
- Find in page, night mode, ad blocking, user scripts, CloudKit, IPA packaging

These records are Method Pack drafts / hints, not authoritative runtime decisions.

## BaselineUsageDraft

- Required baseline refs:
- docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md
- docs/aegis/baseline/2026-07-19-initial-baseline.md
- Delivered context refs:
- none
- Acknowledged before plan:
- docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md
- docs/aegis/baseline/2026-07-19-initial-baseline.md
- Cited in plan:
- docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md
- docs/aegis/baseline/2026-07-19-initial-baseline.md
- Missing refs:
- none
- Advisory decision: continue
