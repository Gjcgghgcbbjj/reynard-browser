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

## Checkpoint Update

- Current todo: Task 16: Phase 7 external Xcode/device verification
- Active slice: External platform evidence only
- Completed todos:
- Tasks 1-3: plan and Phase 0 design/motion foundation
- Tasks 4-5: responsive chrome, toolbar, and address-bar decomposition
- Tasks 6-7: Gecko finder bridge and redesigned find surface
- Tasks 8-9: phone tab grid and iPad tab sidebar
- Task 10: modular homepage and promotional owner retirement
- Task 11: unified library, settings, downloads, and site-control styling
- Tasks 12-15: Gecko feature contracts, blocking, user scripts, privacy, and backup
- Task 16 source retirement and portable verification
- Evidence refs:
- docs/aegis/work/2026-07-20-browser-frontend-redesign/evidence-bundle-draft-phase7-integrated-source.json
- Blocked on: macOS/Xcode, pinned Gecko feature implementation response, iOS 16 devices, VoiceOver, and Instruments are unavailable in WSL
- Next step: Build on macOS, confirm Reynard:Features capability contract in the pinned Gecko integration, then run iOS 16 phone/iPad 60/120 Hz accessibility and recovery matrix

## DriftCheckDraft

- Scope status: All planned source phases and retirement work are complete; external platform evidence remains
- Compatibility status: UIKit/iOS 16 and Gecko boundaries retained; no WebKit, SwiftUI, CloudKit, IPA, duplicate tab/store owner, or native proxy blocking path added
- Retirement status: Promotional homepage owners and obsolete iPad tab-overview animation paths are deleted; current tabs route through TabManager-backed phone grid or iPad sidebar
- New risk signals:
- Pinned Gecko must implement and report Reynard:Features capabilities; unsupported capabilities are shown explicitly instead of using a hidden fallback
- UIKit type checking, iOS 16 runtime behavior, VoiceOver, and 60/120 Hz performance are not verifiable on WSL
- Advisory decision: needs-verification
