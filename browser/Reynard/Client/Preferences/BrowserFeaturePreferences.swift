import Foundation

extension BrowserPreferences {
    struct FeatureSettings {
        static var nightMode: BrowserNightMode {
            get { BrowserNightMode(rawValue: BrowserPreferences.shared.string(forSetting: "FeatureSettings", key: "nightMode") ?? "automatic") ?? .automatic }
            set { set(newValue.rawValue, key: "nightMode") }
        }

        static var blockingMode: BrowserBlockingMode {
            get { BrowserBlockingMode(rawValue: BrowserPreferences.shared.string(forSetting: "FeatureSettings", key: "blockingMode") ?? "balanced") ?? .balanced }
            set { set(newValue.rawValue, key: "blockingMode") }
        }

        static var thirdPartyCookiePolicy: ThirdPartyCookiePolicy {
            get { ThirdPartyCookiePolicy(rawValue: BrowserPreferences.shared.string(forSetting: "FeatureSettings", key: "thirdPartyCookiePolicy") ?? "blockTrackers") ?? .blockTrackers }
            set { set(newValue.rawValue, key: "thirdPartyCookiePolicy") }
        }

        static var trackingProtection: Bool {
            get { BrowserPreferences.shared.bool(forSetting: "FeatureSettings", key: "trackingProtection") }
            set { set(newValue, key: "trackingProtection") }
        }

        static var clearSiteDataOnExit: Bool {
            get { BrowserPreferences.shared.bool(forSetting: "FeatureSettings", key: "clearSiteDataOnExit") }
            set { set(newValue, key: "clearSiteDataOnExit") }
        }

        static var customRules: [String] {
            get { decode([String].self, key: "customRules") ?? [] }
            set { encode(ViaFeaturePolicy.sanitizeRules(newValue), key: "customRules") }
        }

        static var subscriptions: [BrowserFilterSubscription] {
            get { decode([BrowserFilterSubscription].self, key: "subscriptions") ?? defaultSubscriptions }
            set { encode(newValue, key: "subscriptions") }
        }

        static var userScripts: [BrowserUserScript] {
            get { decode([BrowserUserScript].self, key: "userScripts") ?? [] }
            set { encode(newValue, key: "userScripts") }
        }

        static var nightOverrides: [String: BrowserSiteOverride] {
            get { decode([String: BrowserSiteOverride].self, key: "nightOverrides") ?? [:] }
            set { encode(newValue, key: "nightOverrides") }
        }

        static var blockingOverrides: [String: BrowserSiteOverride] {
            get { decode([String: BrowserSiteOverride].self, key: "blockingOverrides") ?? [:] }
            set { encode(newValue, key: "blockingOverrides") }
        }

        static let defaultSubscriptions: [BrowserFilterSubscription] = [
            BrowserFilterSubscription(name: "EasyList", sourceURL: URL(string: "https://easylist.to/easylist/easylist.txt")!)!,
            BrowserFilterSubscription(name: "EasyPrivacy", sourceURL: URL(string: "https://easylist.to/easylist/easyprivacy.txt")!)!,
        ]

        private static func set(_ value: String, key: String) {
            BrowserPreferences.shared.set(value, forSetting: "FeatureSettings", key: key)
            changed()
        }

        private static func set(_ value: Bool, key: String) {
            BrowserPreferences.shared.set(value, forSetting: "FeatureSettings", key: key)
            changed()
        }

        private static func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
            guard let data = BrowserPreferences.shared.data(forSetting: "FeatureSettings", key: key) else { return nil }
            return try? JSONDecoder().decode(type, from: data)
        }

        private static func encode<T: Encodable>(_ value: T, key: String) {
            BrowserPreferences.shared.set(try? JSONEncoder().encode(value), forSetting: "FeatureSettings", key: key)
            changed()
        }

        private static func changed() {
            NotificationCenter.default.post(name: .browserFeatureSettingsDidChange, object: nil)
        }
    }
}
