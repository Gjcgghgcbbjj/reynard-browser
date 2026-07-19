import Foundation
import XCTest
@testable import ReynardStabilityCore

final class ContentProcessRecoveryPolicyTests: XCTestCase {
    func testSelectedCrashRecreatesImmediatelyWithinBudget() {
        var policy = ContentProcessRecoveryPolicy(crashLimit: 2, crashInterval: 60)

        XCTAssertEqual(
            policy.decide(kind: .crash, isSelected: true, at: date(0)),
            .recreateImmediately
        )
    }

    func testBackgroundCrashRecreatesWhenSelectedWithinBudget() {
        var policy = ContentProcessRecoveryPolicy(crashLimit: 2, crashInterval: 60)

        XCTAssertEqual(
            policy.decide(kind: .crash, isSelected: false, at: date(0)),
            .recreateWhenSelected
        )
    }

    func testBackgroundKillDoesNotConsumeCrashBudget() {
        var policy = ContentProcessRecoveryPolicy(crashLimit: 1, crashInterval: 60)

        XCTAssertEqual(
            policy.decide(kind: .killed, isSelected: false, at: date(0)),
            .recreateWhenSelected
        )
        XCTAssertEqual(
            policy.decide(kind: .crash, isSelected: true, at: date(1)),
            .recreateImmediately
        )
    }

    func testRepeatedCrashShowsStableFailure() {
        var policy = ContentProcessRecoveryPolicy(crashLimit: 2, crashInterval: 60)

        XCTAssertEqual(
            policy.decide(kind: .crash, isSelected: true, at: date(0)),
            .recreateImmediately
        )
        XCTAssertEqual(
            policy.decide(kind: .crash, isSelected: true, at: date(1)),
            .recreateImmediately
        )
        XCTAssertEqual(
            policy.decide(kind: .crash, isSelected: true, at: date(2)),
            .showStableFailure
        )
    }

    func testSuccessfulCompositeResetsCrashBudget() {
        var policy = ContentProcessRecoveryPolicy(crashLimit: 1, crashInterval: 60)

        XCTAssertEqual(
            policy.decide(kind: .crash, isSelected: true, at: date(0)),
            .recreateImmediately
        )
        XCTAssertEqual(
            policy.decide(kind: .crash, isSelected: true, at: date(1)),
            .showStableFailure
        )

        policy.markSuccessfulComposite()

        XCTAssertEqual(
            policy.decide(kind: .crash, isSelected: true, at: date(2)),
            .recreateImmediately
        )
    }

    private func date(_ offset: TimeInterval) -> Date {
        Date(timeIntervalSince1970: 100 + offset)
    }
}
