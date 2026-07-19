# ADR-0001 - Frontend surfaces and Gecko feature execution ownership

Status: `recorded-from-work`
Date: `2026-07-20`

## Source Evidence

- docs/aegis/work/2026-07-20-browser-frontend-redesign/proof-bundle.md and commits ae52c8c..ea199a1
## Context

The redesign needed phone and iPad tab access, Via-like content features, and polished animation without creating parallel tab state or copying web execution into Swift.

## Decision

TabManager remains the single tab authority; phones project it into the card grid, iPads project it into the collapsible sidebar, and page modification/blocking/user-script/privacy execution crosses one explicit Gecko capability contract while UIKit owns configuration and unsupported-state presentation.

## Alternatives Considered

- Keep the existing iPad tab-overview animation alongside the sidebar.
- Implement darkening, blocking, and user scripts directly in Swift or through WebKit.
- Silently assume every pinned Gecko build supports the feature events.
## Consequences

- The old iPad tab-overview animation path and promotional homepage owners are retired, reducing duplicate presentation ownership.
- Pinned Gecko integrations must implement and report the Reynard:Features capability contract; Settings exposes missing capabilities and Swift provides no hidden execution fallback.
- Portable policies remain testable on WSL, while Xcode/device evidence is still required for release readiness.
## Compatibility Boundary

iOS 16 UIKit, Gecko rendering/WebExtension execution, TrollStore, existing SessionManager/TabManager/stores, no WebKit/SwiftUI/CloudKit/IPA scope.

## Retirement Impact

Deleted promotional homepage controllers and obsolete pad tab-overview presentation branches; retained phone grid, iPad sidebar, and capability diagnostics.

## Baseline Sync

- Needed: needed
- Target: docs/aegis/baseline/2026-07-20-frontend-redesign-baseline.md
- Action: create snapshot
- Reason: The ownership map now includes separate phone/iPad tab projections, focused frontend owners, and the explicit Gecko feature capability contract.

## Evidence References

- docs/aegis/work/2026-07-20-browser-frontend-redesign/evidence-bundle-draft-phase7-integrated-source.json
## Boundary

This ADR is an advisory Aegis Method Pack record. It does not grant completion authority or replace project-authoritative architecture sources.
