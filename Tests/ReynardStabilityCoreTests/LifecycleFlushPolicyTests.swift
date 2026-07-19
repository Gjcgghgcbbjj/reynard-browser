import Foundation
import XCTest
@testable import ReynardStabilityCore

final class LifecycleFlushPolicyTests: XCTestCase {
    func testOnlyOneFlushStartsWhileOneIsInFlight() {
        let policy = LifecycleFlushPolicy(scheduleTimeout: inertScheduler)
        var startCount = 0
        var finish: ((Bool) -> Void)?

        policy.requestFlush(start: { completion in
            startCount += 1
            finish = completion
        }, completion: { _ in })
        policy.requestFlush(start: { _ in
            startCount += 1
        }, completion: { _ in })

        XCTAssertEqual(startCount, 1)
        finish?(true)
    }

    func testCoalescedWaitersReceiveSharedResult() {
        let policy = LifecycleFlushPolicy(scheduleTimeout: inertScheduler)
        var finish: ((Bool) -> Void)?
        var results: [Bool] = []

        policy.requestFlush(start: { finish = $0 }) { results.append($0) }
        policy.requestFlush(start: { _ in XCTFail("Coalesced request started new work") }) {
            results.append($0)
        }
        finish?(false)

        XCTAssertEqual(results, [false, false])
    }

    func testTimeoutCompletesWaitersAndIgnoresLateWorkCompletion() {
        var timeoutAction: (() -> Void)?
        let policy = LifecycleFlushPolicy(
            timeout: 1,
            scheduleTimeout: { _, action in
                timeoutAction = action
                return {}
            }
        )
        var finish: ((Bool) -> Void)?
        var results: [Bool] = []

        policy.requestFlush(start: { finish = $0 }) { results.append($0) }
        timeoutAction?()
        finish?(true)

        XCTAssertEqual(results, [false])
    }

    func testCompletionOrderingMatchesRequestOrdering() {
        let policy = LifecycleFlushPolicy(scheduleTimeout: inertScheduler)
        var finish: ((Bool) -> Void)?
        var ordering: [Int] = []

        policy.requestFlush(start: { finish = $0 }) { _ in ordering.append(1) }
        policy.requestFlush(start: { _ in }) { _ in ordering.append(2) }
        policy.requestFlush(start: { _ in }) { _ in ordering.append(3) }
        finish?(true)

        XCTAssertEqual(ordering, [1, 2, 3])
    }

    private func inertScheduler(
        _ timeout: TimeInterval,
        _ action: @escaping () -> Void
    ) -> () -> Void {
        {}
    }
}
