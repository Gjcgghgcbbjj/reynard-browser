import UIKit

enum HomepageSection: CaseIterable, Hashable {
    case privateBrowsing
    case favorites
    case frequentlyVisited
    case recentlyClosedTabs

    static var allCases: [HomepageSection] {
        let ordered = Prefs.HomepageSettings.moduleOrder.compactMap { module -> HomepageSection? in
            switch module {
            case .search:
                return nil // Search is owned by the browser chrome.
            case .favorites:
                return .favorites
            case .frequentlyVisited:
                return .frequentlyVisited
            case .recentTabs:
                return .recentlyClosedTabs
            }
        }
        return [.privateBrowsing] + ordered
    }
}

protocol HomepageSectionDelegate: AnyObject {
    func homepageSection(_ viewController: UIViewController, didRequestOpenURL url: URL, disposition: TabOpenDisposition)
    func homepageSection(_ viewController: UIViewController, didRequestShareURL url: URL)
    func homepageSection(_ viewController: UIViewController, didRequestHideFromSuggestions siteID: Int64)
    func homepageSection(_ viewController: UIViewController, didSelectRecentlyClosedTab id: UUID)
    func homepageSectionDidSelectSettings(_ viewController: UIViewController)
}
