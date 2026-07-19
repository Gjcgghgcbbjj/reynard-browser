import Foundation

public enum JITRetryDecision: Equatable, Sendable {
    case retry
    case offerJITLess
}

public struct JITRetryPolicy: Sendable {
    private var retryWindow: RetryWindow

    public init(limit: Int = 2, interval: TimeInterval = 30) {
        retryWindow = RetryWindow(limit: limit, interval: interval)
    }

    public mutating func decide(at date: Date) -> JITRetryDecision {
        retryWindow.recordAttempt(at: date) ? .retry : .offerJITLess
    }

    public mutating func reset() {
        retryWindow.reset()
    }
}
