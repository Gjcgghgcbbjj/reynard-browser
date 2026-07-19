import GeckoView
import UIKit

@MainActor
final class BrowserFeatureCoordinator {
    private let sessionProvider: () -> GeckoSession?
    private let urlProvider: () -> URL?
    private let interfaceStyleProvider: () -> UIUserInterfaceStyle
    private var checkedSessions = Set<ObjectIdentifier>()

    init(
        sessionProvider: @escaping () -> GeckoSession?,
        urlProvider: @escaping () -> URL?,
        interfaceStyleProvider: @escaping () -> UIUserInterfaceStyle
    ) {
        self.sessionProvider = sessionProvider
        self.urlProvider = urlProvider
        self.interfaceStyleProvider = interfaceStyleProvider
    }

    var isNightModeEnabledForCurrentSite: Bool {
        ViaFeaturePolicy.resolvesNightMode(
            global: Prefs.FeatureSettings.nightMode,
            siteOverride: siteOverride(from: Prefs.FeatureSettings.nightOverrides),
            systemUsesDarkAppearance: interfaceStyleProvider() == .dark
        )
    }

    var isBlockingEnabledForCurrentSite: Bool {
        ViaFeaturePolicy.resolvesBlocking(
            global: Prefs.FeatureSettings.blockingMode,
            siteOverride: siteOverride(from: Prefs.FeatureSettings.blockingOverrides)
        ) != .off
    }

    func toggleNightModeForCurrentSite() {
        updateOverride(
            isCurrentlyEnabled: isNightModeEnabledForCurrentSite,
            values: Prefs.FeatureSettings.nightOverrides
        ) { Prefs.FeatureSettings.nightOverrides = $0 }
        applyCurrentConfiguration()
    }

    func toggleBlockingForCurrentSite() {
        updateOverride(
            isCurrentlyEnabled: isBlockingEnabledForCurrentSite,
            values: Prefs.FeatureSettings.blockingOverrides
        ) { Prefs.FeatureSettings.blockingOverrides = $0 }
        applyCurrentConfiguration()
    }

    func applyCurrentConfiguration() {
        guard let session = sessionProvider() else { return }
        let host = normalizedHost
        session.features.applyNightMode(enabled: isNightModeEnabledForCurrentSite, host: host)
        let blocking = ViaFeaturePolicy.resolvesBlocking(
            global: Prefs.FeatureSettings.blockingMode,
            siteOverride: siteOverride(from: Prefs.FeatureSettings.blockingOverrides)
        )
        session.features.applyContentBlocking(
            mode: blocking.rawValue,
            disabledHosts: Prefs.FeatureSettings.blockingOverrides.compactMap { $0.value == .disabled ? $0.key : nil },
            subscriptions: Prefs.FeatureSettings.subscriptions.map {
                ["id": $0.id.uuidString, "name": $0.name, "url": $0.sourceURL.absoluteString, "enabled": $0.isEnabled]
            },
            customRules: Prefs.FeatureSettings.customRules
        )
        let scripts = Prefs.FeatureSettings.userScripts.filter { script in
            script.isEnabled && (!session.isPrivateMode || script.allowsPrivateBrowsing)
        }.map { script in
            [
                "id": script.id.uuidString,
                "name": script.name,
                "matches": script.matches,
                "grants": script.grants,
                "source": script.source,
            ] as [String: Any]
        }
        session.features.applyUserScripts(scripts, privateMode: session.isPrivateMode)
        session.features.applyPrivacy(
            cookiePolicy: Prefs.FeatureSettings.thirdPartyCookiePolicy.rawValue,
            trackingProtection: Prefs.FeatureSettings.trackingProtection,
            clearSiteDataOnExit: Prefs.FeatureSettings.clearSiteDataOnExit
        )
        checkCapabilitiesIfNeeded(session)
    }

    private var normalizedHost: String? {
        urlProvider()?.host?.lowercased()
    }

    private func siteOverride(from values: [String: BrowserSiteOverride]) -> BrowserSiteOverride {
        guard let normalizedHost else { return .inherit }
        return values[normalizedHost] ?? .inherit
    }

    private func updateOverride(
        isCurrentlyEnabled: Bool,
        values: [String: BrowserSiteOverride],
        save: ([String: BrowserSiteOverride]) -> Void
    ) {
        guard let normalizedHost else { return }
        var values = values
        values[normalizedHost] = isCurrentlyEnabled ? .disabled : .enabled
        save(values)
    }

    private func checkCapabilitiesIfNeeded(_ session: GeckoSession) {
        let identifier = ObjectIdentifier(session)
        guard checkedSessions.insert(identifier).inserted else { return }
        Task { @MainActor in
            let capabilities = await session.features.capabilities()
            let missing = Set(GeckoFeatureCapability.allCases).subtracting(capabilities.supported)
            guard !missing.isEmpty else { return }
            StabilityDiagnostics.shared.record(
                .session,
                name: "browserFeatures.unsupported",
                metadata: ["capabilities": missing.map(\.rawValue).sorted().joined(separator: ",")]
            )
        }
    }
}
