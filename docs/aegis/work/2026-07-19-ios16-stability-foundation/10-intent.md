# iOS 16 Stability Foundation Execution - Intent

## TaskIntentDraft

- Requested outcome: Pass Gate A for iOS 16 TrollStore stability before Via feature work
- Goal: Preserve tabs across Gecko failures, recover JIT failures, harden startup and persistence, and export privacy-safe diagnostics
- Success evidence:
- Portable policy tests, macOS app build, and arm64 plus arm64e device checklist evidence
- Stop condition: All seven plan tasks complete, or execution stops with a documented blocker, needs-verification state, or scope-exceeded finding
- Non-goals:
- Via Phase 1 features, CloudKit implementation, Blink, App Store
- Scope: Execute docs/aegis/plans/2026-07-19-ios16-stability-foundation.md
- Change kinds:
- reliability
- Risk hints:
- No Swift/Xcode on current WSL host; physical iOS devices required for final verification

## BaselineReadSetHint

- docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md
- docs/aegis/baseline/2026-07-19-initial-baseline.md

## BaselineUsageDraft

- Required baseline refs:
- docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md
- docs/aegis/baseline/2026-07-19-initial-baseline.md
- Acknowledged before plan:
- none
- Cited in plan:
- none
- Missing refs:
- docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md
- docs/aegis/baseline/2026-07-19-initial-baseline.md
- Advisory decision: needs-baseline-readback

## ImpactStatementDraft

- Compatibility boundary: iOS 16 TrollStore arm64/arm64e and existing user data
- Affected layers:
- stability core, JIT, Gecko session lifecycle, tabs, persistence, diagnostics
- Owners:
- existing JIT/session/tab/store owners plus one diagnostics owner
- Invariants:
- Gecko process failure never deletes a user tab and no WebKit fallback is introduced
- Non-goals:
- Via Phase 1 features, CloudKit implementation, Blink, App Store

These records are Method Pack drafts / hints, not authoritative runtime decisions.

## BaselineUsageDraft

- Required baseline refs:
- docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md
- docs/aegis/plans/2026-07-19-ios16-stability-foundation.md
- Delivered context refs:
- none
- Acknowledged before plan:
- browser/Reynard/Client/TabManagement/TabManagerImpl.swift
- Cited in plan:
- docs/aegis/plans/2026-07-19-ios16-stability-foundation.md
- Missing refs:
- macOS Xcode build and iOS device evidence
- Advisory decision: continue
