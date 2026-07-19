import Foundation
import XCTest
@testable import ReynardStabilityCore

final class JITRetryPolicyTests: XCTestCase {
    func testAllowsRetryWithinBudget() {
        var policy = JITRetryPolicy(limit: 2, interval: 30)

        XCTAssertEqual(policy.decide(at: date(0)), .retry)
        XCTAssertEqual(policy.decide(at: date(1)), .retry)
    }

    func testOffersJITLessAfterBudgetIsExhausted() {
        var policy = JITRetryPolicy(limit: 2, interval: 30)

        XCTAssertEqual(policy.decide(at: date(0)), .retry)
        XCTAssertEqual(policy.decide(at: date(1)), .retry)
        XCTAssertEqual(policy.decide(at: date(2)), .offerJITLess)
    }

    func testResetRestoresRetryBudget() {
        var policy = JITRetryPolicy(limit: 1, interval: 30)

        XCTAssertEqual(policy.decide(at: date(0)), .retry)
        XCTAssertEqual(policy.decide(at: date(1)), .offerJITLess)

        policy.reset()

        XCTAssertEqual(policy.decide(at: date(2)), .retry)
    }

    private func date(_ offset: TimeInterval) -> Date {
        Date(timeIntervalSince1970: 100 + offset)
    }
}
