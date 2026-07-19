import Foundation
import XCTest
@testable import ReynardBrowserCore

final class MotionPolicyTests: XCTestCase {
    func testProMotionProfileTargets120FramesPerSecond() {
        let profile = MotionPolicy.profile(
            for: .tabSelection,
            reduceMotion: false,
            maximumFramesPerSecond: 120
        )

        XCTAssertEqual(profile.targetFramesPerSecond, 120)
        XCTAssertEqual(profile.frameBudget, 1.0 / 120.0, accuracy: 0.000_001)
        XCTAssertTrue(profile.usesSpring)
        XCTAssertTrue(profile.allowsScale)
    }

    func testStandardDisplayFallsBackTo60FramesPerSecond() {
        let profile = MotionPolicy.profile(
            for: .chrome,
            reduceMotion: false,
            maximumFramesPerSecond: 60
        )

        XCTAssertEqual(profile.targetFramesPerSecond, 60)
        XCTAssertEqual(profile.frameBudget, 1.0 / 60.0, accuracy: 0.000_001)
    }

    func testUnknownOrNonProMotionDisplayUses60FramesPerSecond() {
        XCTAssertEqual(
            MotionPolicy.targetFramesPerSecond(maximumFramesPerSecond: 0),
            60
        )
        XCTAssertEqual(
            MotionPolicy.targetFramesPerSecond(maximumFramesPerSecond: 90),
            60
        )
    }

    func testReduceMotionUsesShortNonSpringNonScalingProfile() {
        for transition in BrowserMotionTransition.allCases {
            let profile = MotionPolicy.profile(
                for: transition,
                reduceMotion: true,
                maximumFramesPerSecond: 120
            )

            XCTAssertFalse(profile.usesSpring)
            XCTAssertFalse(profile.allowsScale)
            XCTAssertLessThanOrEqual(profile.duration, 0.16)
            XCTAssertEqual(profile.targetFramesPerSecond, 120)
        }
    }

    func testInteractiveTabMotionIsLongerThanChromeMotion() {
        let chrome = MotionPolicy.profile(
            for: .chrome,
            reduceMotion: false,
            maximumFramesPerSecond: 120
        )
        let tabSelection = MotionPolicy.profile(
            for: .tabSelection,
            reduceMotion: false,
            maximumFramesPerSecond: 120
        )

        XCTAssertGreaterThan(tabSelection.duration, chrome.duration)
        XCTAssertLessThan(tabSelection.dampingRatio, chrome.dampingRatio)
    }
}
