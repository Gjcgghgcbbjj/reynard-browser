# Via Phase 1 Webpage Translation - Checkpoint

- Task ID: 2026-07-19-via-translation
- Current todo: macOS/Xcode and iOS 16 verification for webpage translation
- Active slice: Source implementation complete; external platform verification pending
- Completed todos:
- Task 1: portable translation URL policy (dcf15d4)
- Task 2: translation provider settings (eae6d8e)
- Task 3: Translate Page action (c6b5003)
- Evidence refs:
- docs/aegis/work/2026-07-19-via-translation/evidence-bundle-draft-task1-provider-policy.json
- docs/aegis/work/2026-07-19-via-translation/evidence-bundle-draft-task2-translation-settings.json
- docs/aegis/work/2026-07-19-via-translation/evidence-bundle-draft-task3-translate-page-action.json
- Blocked on: macOS/Xcode and an iOS 16 test device are unavailable on WSL
- Next step: Begin the next bounded Via feature while retaining the translation Xcode/device verification backlog
- Resume instruction: Do not reopen translation source tasks unless Xcode/device evidence exposes a defect; proceed from the next Via feature plan.
- Unsafe to assume: Swift frontend parsing proves UIKit type correctness or provider availability on a physical iOS 16 device.

## DriftCheckDraft

- Scope status: three planned source tasks complete; full platform acceptance pending
- Compatibility status: Gecko-only renderer, HTTP(S)-only provider navigation, credential stripping, same regular/private mode, no proxy/WebKit
- Retirement status: no prior translation path or hidden fallback introduced
- New risk signals:
- UIKit integration and external provider behavior remain unverified on iOS 16
- Advisory decision: needs-verification
