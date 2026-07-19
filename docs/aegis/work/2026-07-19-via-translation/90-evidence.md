# Via Phase 1 Webpage Translation - Evidence

## EvidenceBundleDraft

- Artifact key: task1-provider-policy
- Type: tests-and-source
- Source: commit dcf15d4 and Docker swift:6.1-noble swift test
- Summary: TranslationProvider policy covers Google/custom destinations, credential stripping, HTTP(S) constraints, placeholders, and language normalization; 6 focused tests pass.
- Verifier: Codex

## EvidenceBundleDraft

- Artifact key: task2-translation-settings
- Type: source-and-localization
- Source: commit eae6d8e; docker swiftc -frontend -parse; JSON validation; Docker swift test
- Summary: Existing BrowserPreferences and Browsing settings own Google/custom selection and validated custom templates; syntax parse and 34 portable tests pass.
- Verifier: Codex

## EvidenceBundleDraft

- Artifact key: task3-translate-page-action
- Type: source-tests-and-structural-checks
- Source: commit c6b5003; docker swiftc -frontend -parse; unique-key localization validation; structural assertions; Docker swift test
- Summary: Translate Page is limited to canonical HTTP(S), creates an adjacent same-mode Gecko tab, preserves the original tab, and records redacted diagnostics; 34 portable tests pass.
- Verifier: Codex
