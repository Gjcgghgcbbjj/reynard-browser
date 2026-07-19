import Foundation
import XCTest
@testable import ReynardStabilityCore

final class StabilityEventBufferTests: XCTestCase {
    func testAppendRetainsNewestEventsWithinCapacity() {
        var buffer = StabilityEventBuffer(capacity: 3)

        for index in 0..<4 {
            buffer.append(event(index))
        }

        XCTAssertEqual(buffer.events.map(\.name), ["event-1", "event-2", "event-3"])
    }

    func testCapacityIsNeverLowerThanOne() {
        var buffer = StabilityEventBuffer(capacity: 0)

        buffer.append(event(0))
        buffer.append(event(1))

        XCTAssertEqual(buffer.events.map(\.name), ["event-1"])
    }

    func testEventsRoundTripThroughJSON() throws {
        var buffer = StabilityEventBuffer(capacity: 2)
        buffer.append(event(0))
        buffer.append(event(1))

        let data = try JSONEncoder().encode(buffer.events)
        let decoded = try JSONDecoder().decode([StabilityEvent].self, from: data)

        XCTAssertEqual(decoded, buffer.events)
    }

    private func event(_ index: Int) -> StabilityEvent {
        StabilityEvent(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!,
            timestamp: Date(timeIntervalSince1970: TimeInterval(index)),
            category: .recovery,
            name: "event-\(index)",
            metadata: ["index": String(index)]
        )
    }
}
