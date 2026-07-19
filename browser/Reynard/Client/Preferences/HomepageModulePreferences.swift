import Foundation

extension BrowserPreferences.HomepageSettings {
    static var moduleOrder: [BrowserHomepageModule] {
        get {
            let values: [String]
            if let data = BrowserPreferences.shared.data(forSetting: "HomepageSettings", key: "moduleOrder"),
               let decoded = try? JSONDecoder().decode([String].self, from: data) {
                values = decoded
            } else {
                values = BrowserHomepageModule.defaultOrder.map(\.rawValue)
            }
            return HomepageModulePolicy.decode(rawValues: values)
        }
        set {
            let sanitized = HomepageModulePolicy.decode(rawValues: newValue.map(\.rawValue))
            BrowserPreferences.shared.set(
                try? JSONEncoder().encode(sanitized.map(\.rawValue)),
                forSetting: "HomepageSettings",
                key: "moduleOrder"
            )
            NotificationCenter.default.post(name: .homepageSettingsDidChange, object: nil)
        }
    }
}
