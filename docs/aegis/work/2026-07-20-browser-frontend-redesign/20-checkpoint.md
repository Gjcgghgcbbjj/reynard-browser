# Reynard Browser Frontend Redesign - Checkpoint

- Task ID: 2026-07-20-browser-frontend-redesign
- Current todo: Task 2: Phase 0 portable motion policy
- Active slice: Design and motion foundation
- Blocked on: Xcode/device evidence unavailable on WSL but source execution can continue
- Next step: Write RED MotionPolicy tests and implement the minimal portable policy

## Checkpoint Update

- Current todo: Task 4: Phase 1 chrome state and toolbar configuration
- Active slice: Phase 1 configurable browser chrome
- Completed todos:
- Task 1: redesign program plan and checkpoint (e583612)
- Task 2: portable motion policy (ae52c8c)
- Task 3: UIKit design and motion owners (9f1e9cc)
- Evidence refs:
- docs/aegis/work/2026-07-20-browser-frontend-redesign/evidence-bundle-draft-phase0-motion-policy.json
- docs/aegis/work/2026-07-20-browser-frontend-redesign/evidence-bundle-draft-phase0-design-motion-system.json
- Blocked on: Xcode/device evidence unavailable on WSL; source execution continues
- Next step: Add RED toolbar validation tests, then implement canonical toolbar actions and layout resolution

## DriftCheckDraft

- Scope status: Phase 0 complete; Phase 1 next
- Compatibility status: UIKit/Gecko/data owners unchanged; no WebKit, SwiftUI, persistence, or dual-UI path added
- Retirement status: No old frontend path replaced in Phase 0; new owners are additive prerequisites with consuming phases scheduled
- New risk signals:
- UIKit type checking and physical refresh-rate evidence remain unavailable
- Advisory decision: continue
