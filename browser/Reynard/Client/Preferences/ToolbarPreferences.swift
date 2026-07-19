import Foundation

extension BrowserPreferences.AppearanceSettings {
    static var toolbarActions: [BrowserToolbarAction] {
        get {
            let storedValues: [String]
            if let data = BrowserPreferences.shared.data(
                forSetting: "AppearanceSettings",
                key: "toolbarActions"
            ),
            let values = try? JSONDecoder().decode([String].self, from: data) {
                storedValues = values
            } else {
                storedValues = BrowserToolbarAction.defaultPhoneActions.map(\.rawValue)
            }

            return ToolbarActionPolicy.decode(
                rawValues: storedValues,
                maximumVisibleActions: 6
            )
        }
        set {
            let sanitized = ToolbarActionPolicy.sanitize(
                newValue,
                maximumVisibleActions: 6
            )
            let data = try? JSONEncoder().encode(sanitized.map(\.rawValue))
            BrowserPreferences.shared.set(
                data,
                forSetting: "AppearanceSettings",
                key: "toolbarActions"
            )
            NotificationCenter.default.post(
                name: .toolbarActionsDidChange,
                object: nil
            )
        }
    }
}
