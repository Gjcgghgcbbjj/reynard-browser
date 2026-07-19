import Foundation

public enum BrowserHomepageModule: String, CaseIterable, Codable, Sendable {
    case search
    case favorites
    case frequentlyVisited
    case recentTabs

    public static let required: [BrowserHomepageModule] = [.search, .favorites]
    public static let defaultOrder: [BrowserHomepageModule] = [
        .search,
        .favorites,
        .frequentlyVisited,
        .recentTabs,
    ]
}

public enum HomepageModulePolicy {
    public static func decode(rawValues: [String]) -> [BrowserHomepageModule] {
        var decoded: [BrowserHomepageModule] = []
        for value in rawValues {
            guard let module = BrowserHomepageModule(rawValue: value),
                  !decoded.contains(module) else { continue }
            decoded.append(module)
        }
        if decoded.isEmpty {
            decoded = BrowserHomepageModule.defaultOrder
        }
        for required in BrowserHomepageModule.required where !decoded.contains(required) {
            decoded.insert(required, at: min(decoded.count, BrowserHomepageModule.required.firstIndex(of: required) ?? 0))
        }
        return decoded
    }

    public static func visibleModules(
        order: [BrowserHomepageModule],
        isPrivateBrowsing: Bool,
        enabled: Set<BrowserHomepageModule>
    ) -> [BrowserHomepageModule] {
        decode(rawValues: order.map(\.rawValue)).filter { module in
            if BrowserHomepageModule.required.contains(module) { return true }
            if isPrivateBrowsing && module == .recentTabs { return false }
            return enabled.contains(module)
        }
    }
}
