import XCTest
@testable import ReynardGeckoCore

final class FindInPageResultTests: XCTestCase {
    func testParsesCompleteGeckoPayload() throws {
        let result = try FindInPageResult(payload: [
            "found": true,
            "wrapped": false,
            "current": 3,
            "total": 12,
            "searchString": "reynard",
            "linkURL": "https://example.com/result",
        ])

        XCTAssertTrue(result.found)
        XCTAssertFalse(result.wrapped)
        XCTAssertEqual(result.current, 3)
        XCTAssertEqual(result.total, 12)
        XCTAssertEqual(result.searchString, "reynard")
        XCTAssertEqual(result.linkURL, "https://example.com/result")
    }

    func testUsesGeckoDefaultsForOptionalCountAndLinkFields() throws {
        let result = try FindInPageResult(payload: [
            "found": false,
            "searchString": "missing",
        ])

        XCTAssertFalse(result.found)
        XCTAssertFalse(result.wrapped)
        XCTAssertEqual(result.current, 0)
        XCTAssertEqual(result.total, -1)
        XCTAssertNil(result.linkURL)
    }

    func testAcceptsNSNumberValuesFromObjectiveCBridge() throws {
        let result = try FindInPageResult(payload: [
            "found": NSNumber(value: true),
            "wrapped": NSNumber(value: true),
            "current": NSNumber(value: 1),
            "total": NSNumber(value: 2),
            "searchString": "fox",
        ])

        XCTAssertTrue(result.found)
        XCTAssertTrue(result.wrapped)
        XCTAssertEqual(result.current, 1)
        XCTAssertEqual(result.total, 2)
    }

    func testRejectsPayloadWithoutRequiredFields() {
        XCTAssertThrowsError(
            try FindInPageResult(payload: ["found": true])
        ) { error in
            XCTAssertEqual(error as? FindInPageResultError, .missingSearchString)
        }

        XCTAssertThrowsError(
            try FindInPageResult(payload: ["searchString": "fox"])
        ) { error in
            XCTAssertEqual(error as? FindInPageResultError, .missingFoundState)
        }
    }
}
