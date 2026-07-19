//
//  BrowserViewController+AddressBar.swift
//  Reynard
//
//  Created by Minh Ton on 16/6/26.
//

import UIKit
import GeckoView

extension BrowserViewController: AddressBarDelegate, AddressBarGestureDelegate {
    // MARK: - Address Bar State
    
    func refreshAddressBar() {
        let selectedTab = tabManager.selectedTab
        let displayText: String?
        if case let .pending(text) = selectedTab?.state.displayState {
            displayText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            displayText = nil
        }
        
        let selectedURL = selectedTab?.url
        browserChrome.setAddressBarText(
            displayText?.isEmpty == false ? displayText : selectedURL,
            locationText: selectedURL,
            locationTitle: selectedTab?.title,
            showsBarMenu: displayText?.isEmpty != false && selectedURL?.isEmpty == false
        )
        browserChrome.setAddressBarLoadingProgress(
            selectedTab?.state.loadingState.progress ?? 0,
            isLoading: selectedTab?.state.loadingState.isLoading ?? false
        )
        addonCoordinator.prepareMenuIcons()
        let usesDesktopWebsite = selectedTab.flatMap { tab in
            tab.url.flatMap { url in
                sessionManager.isDesktopMode(for: url, tabID: tab.id)
            }
        }
        browserChrome.updateAddressBarMenu(
            url: selectedURL,
            usesDesktopWebsite: usesDesktopWebsite
        )
    }
    
    // MARK: - AddressBarDelegate
    
    func addressBarDidRequestReloadOrStop(_ addressBar: AddressBar) {
        tabManager.reloadOrStopSelectedTab()
    }
    
    func addressBarAddonItems(_ addressBar: AddressBar) -> [AddressBarMenu.AddonItem] {
        addonCoordinator.currentSiteMenuItems().map { item in
            AddressBarMenu.AddonItem(
                menuItem: item,
                image: addonCoordinator.menuIcon(for: item.addon)
            )
        }
    }
    
    func addressBar(_ addressBar: AddressBar, didSelectAddon item: AddonMenuItem) {
        addonCoordinator.activateMenuItem(item)
    }
    
    func addressBarDidRequestPageZoom(_ addressBar: AddressBar) {
        guard let selectedTab = tabManager.selectedTab else {
            return
        }
        
        browserChrome.setPageZoomLevel(selectedTab.session.settings.pageZoom.level)
        browserChrome.showActionBar(.pageZoom, animated: true)
    }

    func addressBarDidRequestFindInPage(_ addressBar: AddressBar) {
        findInPageCoordinator.present()
    }

    func addressBarDidRequestNightModeToggle(_ addressBar: AddressBar) {
        browserFeatureCoordinator.toggleNightModeForCurrentSite()
        refreshAddressBar()
    }

    func addressBarDidRequestBlockingToggle(_ addressBar: AddressBar) {
        browserFeatureCoordinator.toggleBlockingForCurrentSite()
        refreshAddressBar()
    }

    func addressBarIsNightModeEnabled(_ addressBar: AddressBar) -> Bool {
        browserFeatureCoordinator.isNightModeEnabledForCurrentSite
    }

    func addressBarIsBlockingEnabled(_ addressBar: AddressBar) -> Bool {
        browserFeatureCoordinator.isBlockingEnabledForCurrentSite
    }

    func addressBarDidRequestTranslation(_ addressBar: AddressBar) {
        guard let selectedTab = tabManager.selectedTab,
              let sourceURL = tabManager.shareableURL(for: selectedTab) else {
            return
        }

        let provider = Prefs.BrowsingSettings.translationProvider
        let request = TranslationRequest(
            sourceURL: sourceURL,
            targetLanguage: Locale.preferredLanguages.first ?? "en",
            customTemplate: Prefs.BrowsingSettings.customTranslationTemplate
        )

        switch provider.destination(for: request) {
        case let .success(destination):
            openTranslation(
                destination,
                sourceURL: sourceURL,
                provider: provider
            )
        case let .failure(error):
            StabilityDiagnostics.shared.recordURL(
                .session,
                name: "translation.destinationRejected",
                urlString: sourceURL.absoluteString,
                metadata: [
                    "error": String(describing: error),
                    "mode": tabManager.selectedTabMode.rawValue,
                    "provider": provider.rawValue,
                ]
            )
            presentTranslationError(error)
        }
    }
    
    func addressBarDidRequestWebsiteModeChange(_ addressBar: AddressBar) {
        guard tabManager.changeWebsiteModeForSelectedTab() else {
            return
        }
        
        refreshAddressBar()
    }
    
    func addressBarDidRequestWebsiteSettings(_ addressBar: AddressBar) {
        presentWebsiteSettings()
    }
    
    func addressBar(_ addressBar: AddressBar, didRequestBookmarkInFavorites favorites: Bool) {
        presentBookmarkEditor(addToFavorites: favorites)
    }
    
    func addressBarShareableURL(_ addressBar: AddressBar) -> URL? {
        guard let selectedTab = tabManager.selectedTab else {
            return nil
        }
        
        return tabManager.shareableURL(for: selectedTab)
    }
    
    // MARK: - AddressBarGestureDelegate
    
    var transitionContainerView: UIView {
        return view
    }
    
    var transitionContentView: ContentView {
        return contentView
    }
    
    var chromeMode: BrowserChromeMode {
        return browserLayout.chromeMode
    }
    
    var isSearchFocused: Bool {
        return searchOverlayCoordinator.isFocused
    }
    
    var isTabOverviewPresented: Bool {
        return tabOverview.isPresented
    }
    
    var isTabOverviewTransitionRunning: Bool {
        return tabOverview.isTransitionRunning
    }
    
    var selectedTabIndex: Int {
        return tabManager.selectedTabIndex
    }
    
    var selectedTabMode: TabMode {
        return tabManager.selectedTabMode
    }
    
    var activeTabs: [Tab] {
        return tabManager.activeTabs
    }
    
    func selectTabFromGesture(at index: Int, mode: TabMode) {
        tabManager.selectTab(at: index, mode: mode)
    }
    
    func createTabForSwipe() -> Int {
        let mode = tabManager.selectedTabMode
        captureTabThumbnailIfNeeded()
        homepageOverlayCoordinator.prepareHomepageForNewTab(mode: mode)
        let index = tabManager.createTab(selecting: false)

        if Prefs.NewTabSettings.newTabDisplayOption == .customURL {
            applyNewTabDisplayOption(toTabAt: index)
            return index
        }

        if let tab = tabManager.activeTabs[safe: index],
           let previewImage = homepageOverlayCoordinator.previewImage(for: tab, size: contentView.bounds.size) {
            tabManager.updateThumbnail(previewImage, forTabAt: index, mode: mode)
        }

        return index
    }

    func setPendingTabExpansion(at index: Int?) {
        tabBar.setPendingExpansion(at: index)
    }
    
    func presentTabOverviewFromGesture(animated: Bool) {
        presentTabSurface(animated: animated)
    }
    
    func addressBarGestureWillBegin() {
        browserChrome.dismissActionBar(animated: false)
        captureTabThumbnailIfNeeded()
    }

    private func captureTabThumbnailIfNeeded() {
        if let tab = tabManager.activeTabs[safe: tabManager.selectedTabIndex],
           homepageOverlayCoordinator.needsHomepageThumbnail(for: tab) {
            if let thumbnail = homepageOverlayCoordinator.previewImage(for: tab, size: contentView.bounds.size) {
                tabManager.updateThumbnail(thumbnail, forTabAt: tabManager.selectedTabIndex, mode: tabManager.selectedTabMode)
            }
            return
        }

        captureThumbnail(forTabAt: tabManager.selectedTabIndex, mode: tabManager.selectedTabMode)
    }
    
    func storedContentPreview(from tab: Tab) -> UIImage? {
        guard homepageOverlayCoordinator.needsHomepageThumbnail(for: tab) else {
            return nil
        }

        return tab.thumbnail
    }

    // MARK: - Page Zoom
    
    func setSelectedPageZoomToPreviousLevel() {
        setSelectedPageZoomLevel(browserChrome.previousPageZoomLevel())
    }
    
    func setSelectedPageZoomToNextLevel() {
        setSelectedPageZoomLevel(browserChrome.nextPageZoomLevel())
    }
    
    func setSelectedPageZoomLevel(_ level: Int) {
        guard let selectedTab = tabManager.selectedTab,
              let url = selectedTab.url else {
            return
        }
        
        browserChrome.setPageZoomLevel(level)
        sessionManager.setPageZoom(level, of: selectedTab.session, for: url, tabID: selectedTab.id)
    }
    
    // MARK: - Website Actions
    
    private func presentWebsiteSettings() {
        guard let selectedTab = tabManager.selectedTab,
              let urlString = selectedTab.url?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: urlString),
              let settingsController = SiteSettingsViewController(url: url, session: selectedTab.session) else {
            return
        }
        
        let navigationController = UINavigationController(rootViewController: settingsController)
        navigationController.modalPresentationStyle = .pageSheet
        present(navigationController, animated: true)
    }

    private func openTranslation(
        _ destination: URL,
        sourceURL: URL,
        provider: TranslationProvider
    ) {
        let mode = tabManager.selectedTabMode
        let index = tabManager.createTab(
            selecting: true,
            target: .afterSelected,
            mode: mode
        )
        let tabs = mode == .private ? tabManager.privateTabs : tabManager.regularTabs
        guard let tab = tabs[safe: index] else {
            StabilityDiagnostics.shared.recordURL(
                .session,
                name: "translation.tabCreationFailed",
                urlString: sourceURL.absoluteString,
                metadata: [
                    "mode": mode.rawValue,
                    "provider": provider.rawValue,
                ]
            )
            presentTranslationError(.invalidDestination)
            return
        }

        tabManager.browse(to: destination.absoluteString, in: tab)
        StabilityDiagnostics.shared.recordURL(
            .session,
            name: "translation.opened",
            urlString: sourceURL.absoluteString,
            metadata: [
                "mode": mode.rawValue,
                "provider": provider.rawValue,
            ]
        )
    }

    private func presentTranslationError(_ error: TranslationRequestError) {
        guard presentedViewController == nil else {
            return
        }

        let message: String
        switch error {
        case .unsupportedSourceURL:
            message = NSLocalizedString(
                "Only HTTP and HTTPS pages can be translated.",
                comment: ""
            )
        case .missingCustomTemplate, .invalidCustomTemplate:
            message = NSLocalizedString(
                "The custom translation service is not configured. Open Webpage Translation settings and enter a valid URL containing {url}.",
                comment: "Literal {url} placeholder"
            )
        case .invalidDestination:
            message = NSLocalizedString(
                "The translation service could not create a valid page. Choose another provider in Webpage Translation settings.",
                comment: ""
            )
        }

        let alert = UIAlertController(
            title: NSLocalizedString("Unable to Translate Page", comment: ""),
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
        )
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString("Open Settings", comment: ""),
                style: .default
            ) { [weak self] _ in
                self?.presentTranslationSettings()
            }
        )
        present(alert, animated: true)
    }

    private func presentTranslationSettings() {
        let controller = TranslationPreferencesViewController()
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .pageSheet
        present(navigationController, animated: true)
    }
    
    private func presentBookmarkEditor(addToFavorites: Bool) {
        guard let selectedTab = tabManager.selectedTab,
              let urlString = selectedTab.url?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: urlString) else {
            return
        }
        
        let title = selectedTab.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let bookmarkController: EditBookmarkViewController
        if addToFavorites {
            bookmarkController = EditBookmarkViewController(
                title: title,
                url: url,
                limitsToFavorites: true
            )
        } else if let bookmark = BookmarkStore.shared.bookmark(savedFor: url) {
            bookmarkController = EditBookmarkViewController(bookmark: bookmark)
        } else {
            bookmarkController = EditBookmarkViewController(title: title, url: url)
        }
        
        let navigationController = UINavigationController(rootViewController: bookmarkController)
        navigationController.modalPresentationStyle = .pageSheet
        present(navigationController, animated: true)
    }
}
