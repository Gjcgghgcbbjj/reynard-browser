import Foundation

public struct RetryWindow: Sendable {
    private let limit: Int
    private let interval: TimeInterval
    private var attempts: [Date] = []

    public init(limit: Int, interval: TimeInterval) {
        self.limit = max(0, limit)
        self.interval = max(0, interval)
    }

    public mutating func recordAttempt(at date: Date) -> Bool {
        let cutoff = date.addingTimeInterval(-interval)
        attempts.removeAll { $0 <= cutoff }

        guard attempts.count < limit else {
            return false
        }

        attempts.append(date)
        return true
    }

    public mutating func reset() {
        attempts.removeAll(keepingCapacity: true)
    }
}
