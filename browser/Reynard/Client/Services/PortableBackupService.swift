import Foundation

struct BrowserFeaturePreferencesSnapshot: Codable {
    let nightMode: BrowserNightMode
    let blockingMode: BrowserBlockingMode
    let thirdPartyCookiePolicy: ThirdPartyCookiePolicy
    let trackingProtection: Bool
    let clearSiteDataOnExit: Bool
    let nightOverrides: [String: BrowserSiteOverride]
    let blockingOverrides: [String: BrowserSiteOverride]
}

private struct FilterConfigurationBackup: Codable {
    let subscriptions: [BrowserFilterSubscription]
    let customRules: [String]
}

enum PortableBackupService {
    static func exportData() throws -> Data {
        let preferences = BrowserFeaturePreferencesSnapshot(
            nightMode: Prefs.FeatureSettings.nightMode,
            blockingMode: Prefs.FeatureSettings.blockingMode,
            thirdPartyCookiePolicy: Prefs.FeatureSettings.thirdPartyCookiePolicy,
            trackingProtection: Prefs.FeatureSettings.trackingProtection,
            clearSiteDataOnExit: Prefs.FeatureSettings.clearSiteDataOnExit,
            nightOverrides: Prefs.FeatureSettings.nightOverrides,
            blockingOverrides: Prefs.FeatureSettings.blockingOverrides
        )
        let payloads = [
            BrowserBackupCategory.preferences.rawValue: try JSONEncoder().encode(preferences),
            BrowserBackupCategory.userScripts.rawValue: try JSONEncoder().encode(Prefs.FeatureSettings.userScripts),
            BrowserBackupCategory.filterConfiguration.rawValue: try JSONEncoder().encode(FilterConfigurationBackup(subscriptions: Prefs.FeatureSettings.subscriptions, customRules: Prefs.FeatureSettings.customRules)),
        ]
        let manifest = BrowserBackupManifest(categories: BrowserBackupCategory.allCases, payloads: payloads)
        return try JSONEncoder().encode(manifest)
    }

    static func restore(_ data: Data) throws {
        let manifest = try JSONDecoder().decode(BrowserBackupManifest.self, from: data)
        try manifest.validate()
        guard let preferencesData = manifest.payloads[BrowserBackupCategory.preferences.rawValue],
              let scriptsData = manifest.payloads[BrowserBackupCategory.userScripts.rawValue],
              let filtersData = manifest.payloads[BrowserBackupCategory.filterConfiguration.rawValue],
              let preferences = try? JSONDecoder().decode(BrowserFeaturePreferencesSnapshot.self, from: preferencesData),
              let scripts = try? JSONDecoder().decode([BrowserUserScript].self, from: scriptsData),
              let filters = try? JSONDecoder().decode(FilterConfigurationBackup.self, from: filtersData) else {
            throw BrowserBackupError.invalidPayload
        }
        // Decode and validate every payload before the first write.
        Prefs.FeatureSettings.nightMode = preferences.nightMode
        Prefs.FeatureSettings.blockingMode = preferences.blockingMode
        Prefs.FeatureSettings.thirdPartyCookiePolicy = preferences.thirdPartyCookiePolicy
        Prefs.FeatureSettings.trackingProtection = preferences.trackingProtection
        Prefs.FeatureSettings.clearSiteDataOnExit = preferences.clearSiteDataOnExit
        Prefs.FeatureSettings.nightOverrides = preferences.nightOverrides
        Prefs.FeatureSettings.blockingOverrides = preferences.blockingOverrides
        Prefs.FeatureSettings.userScripts = scripts
        Prefs.FeatureSettings.subscriptions = filters.subscriptions
        Prefs.FeatureSettings.customRules = filters.customRules
    }
}
