import XCTest
@testable import ReynardBrowserCore

final class HomepageModulePolicyTests: XCTestCase {
    func testDecodeRemovesUnknownAndDuplicateValues() {
        XCTAssertEqual(
            HomepageModulePolicy.decode(rawValues: ["recentTabs", "future", "favorites", "recentTabs", "search"]),
            [.recentTabs, .favorites, .search]
        )
    }

    func testDecodeRestoresRequiredSearchAndFavorites() {
        let modules = HomepageModulePolicy.decode(rawValues: ["frequentlyVisited"])
        XCTAssertTrue(modules.contains(.search))
        XCTAssertTrue(modules.contains(.favorites))
    }

    func testEmptyOrderUsesMinimalDefaultOrder() {
        XCTAssertEqual(HomepageModulePolicy.decode(rawValues: []), BrowserHomepageModule.defaultOrder)
    }

    func testPrivateBrowsingFiltersRecentTabsAndDisabledOptionalModules() {
        let modules = HomepageModulePolicy.visibleModules(
            order: BrowserHomepageModule.defaultOrder,
            isPrivateBrowsing: true,
            enabled: [.frequentlyVisited, .recentTabs]
        )
        XCTAssertEqual(modules, [.search, .favorites, .frequentlyVisited])
    }
}
