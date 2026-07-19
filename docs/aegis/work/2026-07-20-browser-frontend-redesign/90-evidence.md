# Reynard Browser Frontend Redesign - Evidence

No evidence has been recorded yet.

## EvidenceBundleDraft

- Artifact key: phase0-motion-policy
- Type: tests-and-source
- Source: commit ae52c8c; RED compile failure; Docker Swift 6.1 focused and full tests
- Summary: Portable motion profiles select Reduce Motion behavior and 60/120 Hz frame budgets; 5 focused tests and 39 total tests pass.
- Verifier: Codex

## EvidenceBundleDraft

- Artifact key: phase0-design-motion-system
- Type: source-parse-and-structural-checks
- Source: commit 9f1e9cc; Docker swiftc frontend parse; structural assertions; Docker Swift tests
- Summary: Semantic design tokens, interruptible UIKit motion mapping, material policy, and bounded DEBUG-only frame monitoring were added without changing runtime/data owners.
- Verifier: Codex

## EvidenceBundleDraft

- Artifact key: phase1-chrome
- Type: source-tests-parse
- Source: commits 5965d7f,b18377f,1d9086b; SwiftPM tests; Swift frontend parse
- Summary: Configurable responsive chrome, toolbar policy, address-bar presentation owners, and settings were implemented while retaining BrowserViewController as composition root.
- Verifier: Codex

## EvidenceBundleDraft

- Artifact key: phase2-find
- Type: tests-parse-structural
- Source: commits 2d90c25,2dfb320; 67-test suite; full Swift source parse
- Summary: Gecko-native finder contract and redesigned action bar provide debounce, stale-result protection, match navigation, keyboard docking, and lifecycle cleanup.
- Verifier: Codex

## EvidenceBundleDraft

- Artifact key: phase3-tabs
- Type: tests-parse-retirement
- Source: commits dbba829,749a3f9,ea199a1; TabPresentationPolicyTests; retirement searches
- Summary: Phone card-grid policy and interruptible transitions are active; iPad uses a collapsible canonical TabManager-backed sidebar; obsolete pad overview animation owners were deleted.
- Verifier: Codex

## EvidenceBundleDraft

- Artifact key: phase4-homepage
- Type: tests-source-retirement
- Source: commit cdd7599; HomepageModulePolicyTests; recommendation owner/reference search
- Summary: Homepage modules have validated order, reorder UI, private filtering, semantic presentation, and no promotional recommendation owners.
- Verifier: Codex

## EvidenceBundleDraft

- Artifact key: phase5-library-settings
- Type: source-parse
- Source: commit a081399; full Swift frontend parse
- Summary: Shared semantic list, navigation, cell, header, tab-bar, and empty-state styling is applied to library, settings, downloads, and site controls.
- Verifier: Codex

## EvidenceBundleDraft

- Artifact key: phase6-via-features
- Type: tests-parse-capability-contract
- Source: commits c34eb59,ebb724b,a7e1589,f251a85,ea199a1; ViaFeaturePolicyTests; Gecko capability UI
- Summary: Night mode, content blocking, user scripts, privacy controls, and versioned portable backup have tested policies, canonical preferences, Gecko-only execution contracts, site overrides, visible capability state, and bounded update retry configuration.
- Verifier: Codex

## EvidenceBundleDraft

- Artifact key: phase7-integrated-source
- Type: full-portable-verification
- Source: 67 SwiftPM tests; parse of 330 Swift files; all JSON/xcstrings validation; anti-WebKit/SwiftUI and retirement searches
- Summary: All client/frontend source phases are integrated and portable verification passes; macOS Xcode, pinned Gecko capability response, iOS 16 devices, accessibility, and 60/120 Hz traces remain external evidence.
- Verifier: Codex
