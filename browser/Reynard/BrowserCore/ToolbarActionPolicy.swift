import Foundation

public enum BrowserToolbarAction: String, CaseIterable, Codable, Sendable {
    case back
    case forward
    case share
    case menu
    case downloads
    case tabs
    case newTab

    public static let requiredActions: [BrowserToolbarAction] = [
        .back,
        .tabs,
        .menu,
    ]

    public static let defaultPhoneActions: [BrowserToolbarAction] = [
        .back,
        .forward,
        .share,
        .menu,
        .tabs,
    ]
}

public enum BrowserToolbarContext: String, Codable, Sendable {
    case phoneBottom
    case compactTop
    case padTop
}

public struct BrowserToolbarLayout: Equatable, Sendable {
    public let leading: [BrowserToolbarAction]
    public let trailing: [BrowserToolbarAction]
    public let overflow: [BrowserToolbarAction]

    public init(
        leading: [BrowserToolbarAction],
        trailing: [BrowserToolbarAction],
        overflow: [BrowserToolbarAction]
    ) {
        self.leading = leading
        self.trailing = trailing
        self.overflow = overflow
    }
}

public enum ToolbarActionPolicy {
    public static func decode(
        rawValues: [String],
        maximumVisibleActions: Int
    ) -> [BrowserToolbarAction] {
        let decoded = rawValues.compactMap(BrowserToolbarAction.init(rawValue:))
        guard !decoded.isEmpty else {
            return sanitize(
                BrowserToolbarAction.defaultPhoneActions,
                maximumVisibleActions: maximumVisibleActions
            )
        }
        return sanitize(
            decoded,
            maximumVisibleActions: maximumVisibleActions
        )
    }

    public static func sanitize(
        _ requestedActions: [BrowserToolbarAction],
        maximumVisibleActions: Int
    ) -> [BrowserToolbarAction] {
        let limit = max(
            maximumVisibleActions,
            BrowserToolbarAction.requiredActions.count
        )
        var actions: [BrowserToolbarAction] = []

        for action in requestedActions where !actions.contains(action) {
            actions.append(action)
        }

        for requiredAction in BrowserToolbarAction.requiredActions
        where !actions.contains(requiredAction) {
            if actions.count >= limit,
               let removableIndex = actions.lastIndex(where: {
                   !BrowserToolbarAction.requiredActions.contains($0)
               }) {
                actions.remove(at: removableIndex)
            }
            actions.append(requiredAction)
        }

        while actions.count > limit,
              let removableIndex = actions.lastIndex(where: {
                  !BrowserToolbarAction.requiredActions.contains($0)
              }) {
            actions.remove(at: removableIndex)
        }

        return Array(actions.prefix(limit))
    }

    public static func layout(
        actions: [BrowserToolbarAction],
        context: BrowserToolbarContext,
        maximumVisibleActions: Int
    ) -> BrowserToolbarLayout {
        let visible = Array(actions.prefix(max(maximumVisibleActions, 0)))
        let overflow = Array(actions.dropFirst(visible.count))

        switch context {
        case .phoneBottom:
            return BrowserToolbarLayout(
                leading: [],
                trailing: visible,
                overflow: overflow
            )
        case .compactTop:
            let essential = visible.filter {
                BrowserToolbarAction.requiredActions.contains($0)
            }
            let compactOverflow = visible.filter { !essential.contains($0) } + overflow
            return BrowserToolbarLayout(
                leading: [],
                trailing: essential,
                overflow: compactOverflow
            )
        case .padTop:
            let leading = visible.filter { $0 == .back || $0 == .forward }
            let trailing = visible.filter { !leading.contains($0) }
            return BrowserToolbarLayout(
                leading: leading,
                trailing: trailing,
                overflow: overflow
            )
        }
    }
}
