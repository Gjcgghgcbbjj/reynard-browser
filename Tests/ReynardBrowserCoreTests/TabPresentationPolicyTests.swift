import XCTest
@testable import ReynardBrowserCore

final class TabPresentationPolicyTests: XCTestCase {
    func testSnapshotGroupsModesWithoutChangingCanonicalOrder() {
        let snapshot = BrowserTabPresentationSnapshot(items: [
            .init(id: "r1", mode: .regular, isSelected: false),
            .init(id: "p1", mode: .privateBrowsing, isSelected: true),
            .init(id: "r2", mode: .regular, isSelected: false),
        ])

        XCTAssertEqual(snapshot.regular.map(\.id), ["r1", "r2"])
        XCTAssertEqual(snapshot.privateBrowsing.map(\.id), ["p1"])
        XCTAssertEqual(snapshot.privateBrowsing.filter(\.isSelected).count, 1)
    }

    func testMoveProjectionRejectsInvalidAndNoOpMoves() {
        XCTAssertEqual(BrowserTabMove(source: 0, destination: 2, count: 3), .init(source: 0, destination: 2, count: 3))
        XCTAssertNil(BrowserTabMove(source: 1, destination: 1, count: 3))
        XCTAssertNil(BrowserTabMove(source: -1, destination: 1, count: 3))
        XCTAssertNil(BrowserTabMove(source: 0, destination: 3, count: 3))
    }

    func testCompactPhoneGridUsesTwoColumns() {
        XCTAssertEqual(TabPresentationPolicy.gridLayout(containerWidth: 375).columns, 2)
        XCTAssertEqual(TabPresentationPolicy.gridLayout(containerWidth: 430).columns, 2)
        XCTAssertEqual(TabPresentationPolicy.gridLayout(containerWidth: 820).columns, 3)
    }

    func testSidebarUsesBoundedExpandedWidthAndCompactCollapsedWidth() {
        XCTAssertEqual(TabPresentationPolicy.sidebar(collapsed: true, availableWidth: 1024).width, 72)
        XCTAssertEqual(TabPresentationPolicy.sidebar(collapsed: false, availableWidth: 900).width, 280)
        XCTAssertEqual(TabPresentationPolicy.sidebar(collapsed: false, availableWidth: 1400).width, 360)
        XCTAssertTrue(TabPresentationPolicy.sidebar(collapsed: false, availableWidth: 1200).showsTitles)
    }
}
