# Reynard Browser Frontend Redesign - Intent

## TaskIntentDraft

- Requested outcome: Complete every approved frontend redesign phase and Via daily-use feature slice
- Goal: Deliver the complete Firefox-inspired UIKit frontend redesign while preserving Gecko and existing runtime/data owners
- Success evidence:
- Phase commits, portable tests, UIKit/Gecko source parsing, old-path retirement evidence, Xcode build, iOS 16 functional/accessibility checks, and 60/120 Hz traces
- Stop condition: All sixteen plan tasks have status, or execution records a genuine blocker, needs-verification boundary, or scope-exceeded state
- Non-goals:
- IPA packaging, CloudKit, Via/Firefox asset copying, or persistence rewrites
- Scope: Execute docs/aegis/plans/2026-07-20-browser-frontend-redesign.md
- Change kinds:
- feature
- refactor
- architecture
- Risk hints:
- WSL cannot compile UIKit/Gecko targets or produce physical-device performance evidence
- Oversized current UI owners require delete-after-migration to avoid duplicate responsibility

## BaselineReadSetHint

- docs/aegis/specs/2026-07-20-browser-frontend-redesign-design.md
- docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md
- docs/aegis/baseline/2026-07-19-initial-baseline.md

## BaselineUsageDraft

- Required baseline refs:
- docs/aegis/specs/2026-07-20-browser-frontend-redesign-design.md
- docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md
- docs/aegis/baseline/2026-07-19-initial-baseline.md
- Acknowledged before plan:
- none
- Cited in plan:
- none
- Missing refs:
- docs/aegis/specs/2026-07-20-browser-frontend-redesign-design.md
- docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md
- docs/aegis/baseline/2026-07-19-initial-baseline.md
- Advisory decision: needs-baseline-readback

## ImpactStatementDraft

- Compatibility boundary: iOS 16 UIKit and Gecko; preserve existing user data and regular/private tab behavior
- Affected layers:
- UIKit browser shell, chrome, tabs, homepage, library/settings, Gecko feature bridges, accessibility, localization, and performance evidence
- Owners:
- BrowserViewController composition plus focused UI/feature owners; Gecko, SessionManager, TabManager, and stores remain authoritative
- Invariants:
- No WebKit, SwiftUI, second tab/store owner, permanent dual UI, or loss of recovery access
- Non-goals:
- IPA packaging, CloudKit, Via/Firefox asset copying, or persistence rewrites

These records are Method Pack drafts / hints, not authoritative runtime decisions.

## BaselineUsageDraft

- Required baseline refs:
- docs/aegis/specs/2026-07-20-browser-frontend-redesign-design.md
- docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md
- docs/aegis/baseline/2026-07-19-initial-baseline.md
- Delivered context refs:
- none
- Acknowledged before plan:
- docs/aegis/specs/2026-07-20-browser-frontend-redesign-design.md
- docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md
- docs/aegis/baseline/2026-07-19-initial-baseline.md
- Cited in plan:
- docs/aegis/plans/2026-07-20-browser-frontend-redesign.md
- Missing refs:
- none
- Advisory decision: continue
