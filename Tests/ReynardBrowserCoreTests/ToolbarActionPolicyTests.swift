import XCTest
@testable import ReynardBrowserCore

final class ToolbarActionPolicyTests: XCTestCase {
    func testSanitizePreservesOrderAndRemovesDuplicates() {
        let actions = ToolbarActionPolicy.sanitize(
            [.share, .back, .share, .tabs, .menu],
            maximumVisibleActions: 6
        )

        XCTAssertEqual(actions, [.share, .back, .tabs, .menu])
    }

    func testSanitizeRestoresRequiredNavigationTabAndMenuActions() {
        let actions = ToolbarActionPolicy.sanitize(
            [.share, .newTab, .downloads],
            maximumVisibleActions: 5
        )

        XCTAssertEqual(actions.count, 5)
        XCTAssertTrue(actions.contains(.back))
        XCTAssertTrue(actions.contains(.tabs))
        XCTAssertTrue(actions.contains(.menu))
    }

    func testDecodeIgnoresUnknownValuesAndUsesDefaultsWhenEmpty() {
        XCTAssertEqual(
            ToolbarActionPolicy.decode(
                rawValues: ["share", "future-action", "tabs", "menu", "back"],
                maximumVisibleActions: 6
            ),
            [.share, .tabs, .menu, .back]
        )

        XCTAssertEqual(
            ToolbarActionPolicy.decode(
                rawValues: ["future-action"],
                maximumVisibleActions: 5
            ),
            BrowserToolbarAction.defaultPhoneActions
        )
    }

    func testPhoneLayoutUsesVisibleLimitAndMovesExtrasToOverflow() {
        let layout = ToolbarActionPolicy.layout(
            actions: BrowserToolbarAction.allCases,
            context: .phoneBottom,
            maximumVisibleActions: 5
        )

        XCTAssertEqual(layout.leading, [])
        XCTAssertEqual(layout.trailing.count, 5)
        XCTAssertEqual(
            layout.overflow,
            Array(BrowserToolbarAction.allCases.dropFirst(5))
        )
    }

    func testPadLayoutKeepsNavigationLeadingAndOtherActionsTrailing() {
        let layout = ToolbarActionPolicy.layout(
            actions: [.share, .tabs, .back, .newTab, .menu, .forward],
            context: .padTop,
            maximumVisibleActions: 6
        )

        XCTAssertEqual(layout.leading, [.back, .forward])
        XCTAssertEqual(layout.trailing, [.share, .tabs, .newTab, .menu])
        XCTAssertEqual(layout.overflow, [])
    }
}
