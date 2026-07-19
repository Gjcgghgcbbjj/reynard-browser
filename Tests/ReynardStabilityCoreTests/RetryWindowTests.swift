import Foundation
import XCTest
@testable import ReynardStabilityCore

final class RetryWindowTests: XCTestCase {
    func testAllowsAttemptsUpToLimit() {
        var window = RetryWindow(limit: 2, interval: 30)
        let start = Date(timeIntervalSince1970: 100)

        XCTAssertTrue(window.recordAttempt(at: start))
        XCTAssertTrue(window.recordAttempt(at: start.addingTimeInterval(1)))
        XCTAssertFalse(window.recordAttempt(at: start.addingTimeInterval(2)))
    }

    func testAttemptExpiresAtWindowBoundary() {
        var window = RetryWindow(limit: 1, interval: 30)
        let start = Date(timeIntervalSince1970: 100)

        XCTAssertTrue(window.recordAttempt(at: start))
        XCTAssertFalse(window.recordAttempt(at: start.addingTimeInterval(29.999)))
        XCTAssertTrue(window.recordAttempt(at: start.addingTimeInterval(30)))
    }

    func testResetClearsAttemptHistory() {
        var window = RetryWindow(limit: 1, interval: 30)
        let start = Date(timeIntervalSince1970: 100)

        XCTAssertTrue(window.recordAttempt(at: start))
        XCTAssertFalse(window.recordAttempt(at: start.addingTimeInterval(1)))

        window.reset()

        XCTAssertTrue(window.recordAttempt(at: start.addingTimeInterval(2)))
    }
}
