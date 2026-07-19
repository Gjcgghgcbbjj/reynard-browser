# Via Phase 1 Webpage Translation Implementation Plan

## Goal

Implement the first bounded Via Phase 1 feature: open a configured translation
provider for the current canonical HTTP(S) page while preserving the original
tab and keeping private browsing behavior explicit.

## Architecture

- Add a Foundation-only browser core target for translation-provider selection,
  source URL sanitization, target-language normalization, custom-template
  validation, and destination construction.
- Keep preferences in the existing `BrowserPreferences` owner.
- Keep the page action in the existing address-bar menu and route it through
  `BrowserViewController` and `TabManager`.
- Open the translated destination in an adjacent tab in the same regular/private
  mode. Swift constructs provider URLs but does not translate page content.

## Tech Stack

- Swift 5.10-compatible Foundation and UIKit
- Swift Package Manager portable tests
- Existing address-bar menu, settings table, preferences, and tab owners

## Baseline/Authority Refs

- `docs/aegis/specs/2026-07-19-ios16-stability-usability-design.md` sections
  7.5 and 9.1 item 6
- `docs/aegis/baseline/2026-07-19-initial-baseline.md`
- `browser/Reynard/Client/Interface/Chrome/AddressBar/AddressBarMenu.swift`
- `browser/Reynard/Client/Interface/BrowserViewController+AddressBar.swift`
- `browser/Reynard/Client/Preferences/BrowserPreferences.swift`
- `browser/Reynard/Client/TabManagement/TabActions.swift`

## Compatibility Boundary

- Preserve Gecko as the only web renderer.
- Do not add WebKit, a project proxy, CloudKit, ad blocking, or user scripts in
  this plan.
- Do not rewrite the current tab URL or regular/private tab persistence.
- Do not send URL credentials to a translation provider.
- Custom templates must be HTTP(S), contain `{url}`, and may contain `{lang}`.

## Verification

- `swift test --package-path .`
- `git diff --check`
- `python -m json.tool browser/Reynard/Resources/Localizable.xcstrings`
- Swift frontend parsing for modified UIKit files
- macOS/Xcode build and iOS 16 manual page-action verification remain required
  before Gate B release claims.

## Plan Basis

- **Fact:** Via Phase 1 requires a configurable translation provider for the
  current canonical URL and a way back to the original page.
- **Fact:** Reynard already owns canonical shareable HTTP(S) URL validation and
  adjacent tab creation.
- **Fact:** the address-bar menu already owns page zoom, desktop mode, and site
  settings actions.
- **Assumption:** opening translation in an adjacent tab is the lowest-risk way
  to preserve the original page and history.
- **Unknown:** provider-side availability varies by network and must remain a
  visible external-service failure rather than an app failure.

## BaselineUsageDraft

- **Required refs:** approved design, initial baseline, address-bar menu,
  preferences, and tab action owners.
- **Acknowledged refs:** Via translation acceptance item, existing custom search
  template UI pattern, canonical `shareableURL`, and `createTab` helper.
- **Cited refs:** header refs and file map below.
- **Missing refs:** physical iOS 16 provider availability evidence.
- **Decision:** `continue`.

## Requirement Ready Check

- **Requirement source:** approved Via parity design and the user's instruction
  to continue Via-like features while deferring packaging.
- **Scenario:** a user explicitly chooses Translate Page for the selected web
  page.
- **Acceptance:** configured provider receives a sanitized canonical URL, the
  original tab remains, and invalid custom configuration produces an actionable
  message.
- **Decision:** `ready`.

## Architecture Integrity Lens

- **Invariant:** Gecko remains the renderer; translation is explicit navigation
  to an external provider.
- **Canonical owners:** translation URL construction in BrowserCore;
  preferences in BrowserPreferences; menu action in AddressBarMenu; tab creation
  in TabManager.
- **Responsibility overlap:** none; Swift does not execute translation scripts.
- **Retirement/falsifier:** no old translation path exists. If a provider cannot
  translate arbitrary page URLs, it must be removed rather than patched with a
  hidden proxy.
- **Verdict:** `proceed`.

## Plan-Time Complexity Check

- **Artifact class:** cross-UI browser action with a small portable policy.
- **Current pressure:** address-bar delegate wiring is established but spans
  menu, view, and controller files.
- **Budget result:** `within-budget` when URL policy is isolated from UIKit.
- **Recommendation:** add one BrowserCore owner and edit existing UI owners in
  place.

## File Map

### Create

- `browser/Reynard/BrowserCore/TranslationProvider.swift`
- `Tests/ReynardBrowserCoreTests/TranslationProviderTests.swift`
- `browser/Reynard/Client/Interface/Library/Settings/Sections/General/Browsing/Translation/TranslationPreferencesViewController.swift`
- `browser/Reynard/Client/Interface/Library/Settings/Sections/General/Browsing/Translation/CustomTranslationTemplateCell.swift`

### Modify

- `Package.swift`
- `browser/Reynard/Client/Preferences/BrowserPreferences.swift`
- `browser/Reynard/Client/Interface/Library/Settings/Sections/General/Browsing/BrowsingPreferencesViewController.swift`
- `browser/Reynard/Client/Interface/Chrome/AddressBar/AddressBarMenu.swift`
- `browser/Reynard/Client/Interface/Chrome/AddressBar/AddressBar.swift`
- `browser/Reynard/Client/Interface/BrowserViewController+AddressBar.swift`
- `browser/Reynard/Resources/Localizable.xcstrings`

## Task 1: Add portable translation URL policy

**Files:** create BrowserCore provider and tests; modify `Package.swift`.

**Interfaces:** `TranslationProvider`, `TranslationRequest`,
`TranslationRequestError`, and `destination(for:)`.

- [ ] Add tests for Google destination construction, credential stripping,
      non-HTTP rejection, language normalization, custom `{url}`/`{lang}`
      replacement, and invalid templates.
- [ ] Run tests and observe RED because BrowserCore does not exist.
- [ ] Add the BrowserCore target and minimal provider implementation.
- [ ] Run all portable tests and expect GREEN.
- [ ] Commit `feat: add translation provider policy`.

## Task 2: Add translation provider preferences

**Files:** modify preferences and Browsing settings; create translation settings
controller/cell; modify localization.

- [ ] Store provider and custom template through existing preferences.
- [ ] Add a Browsing row showing the selected provider.
- [ ] Add Google/custom selection and validate custom templates before selecting
      custom mode.
- [ ] Parse UIKit files and localization JSON.
- [ ] Commit `feat: add translation settings`.

## Task 3: Add Translate Page action

**Files:** modify address-bar menu/view/delegate and localization.

- [ ] Add the menu action only for canonical HTTP(S) pages.
- [ ] Build the configured destination using the preferred language.
- [ ] Open an adjacent tab in the same mode and navigate to the provider.
- [ ] Preserve the original tab and show an actionable alert for invalid custom
      configuration; record a redacted diagnostic event.
- [ ] Run portable tests, parse changed Swift, validate localization, and commit
      `feat: add translate page action`.

## Risks

- Translation providers can be blocked or change URL contracts.
- Custom templates can be malformed; validation must fail closed.
- URLs can contain credentials; sanitization is mandatory before provider
  navigation.
- UIKit/Gecko integration remains uncompiled on WSL.

## Retirement

- No old translation path exists.
- Invalid custom providers fall back to a visible error, not a hidden Google
  fallback or proxy.
