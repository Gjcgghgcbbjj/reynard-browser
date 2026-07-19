import UIKit

extension BrowserToolbarAction {
    var localizedTitle: String {
        switch self {
        case .back:
            return NSLocalizedString("Back", comment: "Toolbar action")
        case .forward:
            return NSLocalizedString("Forward", comment: "Toolbar action")
        case .share:
            return NSLocalizedString("Share", comment: "Toolbar action")
        case .menu:
            return NSLocalizedString("Menu", comment: "Toolbar action")
        case .downloads:
            return NSLocalizedString("Downloads", comment: "Toolbar action")
        case .tabs:
            return NSLocalizedString("Tabs", comment: "Toolbar action")
        case .newTab:
            return NSLocalizedString("New Tab", comment: "Toolbar action")
        }
    }

    var symbolName: String {
        switch self {
        case .back: return "reynard.chevron.backward"
        case .forward: return "reynard.chevron.forward"
        case .share: return "reynard.square.and.arrow.up"
        case .menu: return "reynard.ellipsis.circle"
        case .downloads: return "reynard.arrow.down.circle"
        case .tabs: return "reynard.square.on.square"
        case .newTab: return "reynard.plus"
        }
    }
}
