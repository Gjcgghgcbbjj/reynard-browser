import Foundation

public struct StabilityEventBuffer: Sendable {
    private let capacity: Int
    private var storage: [StabilityEvent] = []

    public init(capacity: Int) {
        self.capacity = max(1, capacity)
    }

    public mutating func append(_ event: StabilityEvent) {
        storage.append(event)
        let overflowCount = storage.count - capacity
        if overflowCount > 0 {
            storage.removeFirst(overflowCount)
        }
    }

    public var events: [StabilityEvent] {
        storage
    }
}
