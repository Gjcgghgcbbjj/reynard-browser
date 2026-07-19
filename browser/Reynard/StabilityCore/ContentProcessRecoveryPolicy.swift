import Foundation

public enum ContentProcessFailureKind: String, Codable, Sendable {
    case crash
    case killed
}

public enum ContentProcessRecoveryDecision: Equatable, Sendable {
    case recreateImmediately
    case recreateWhenSelected
    case showStableFailure
}

public struct ContentProcessRecoveryPolicy: Sendable {
    private var crashWindow: RetryWindow

    public init(crashLimit: Int = 2, crashInterval: TimeInterval = 60) {
        crashWindow = RetryWindow(limit: crashLimit, interval: crashInterval)
    }

    public mutating func decide(
        kind: ContentProcessFailureKind,
        isSelected: Bool,
        at date: Date
    ) -> ContentProcessRecoveryDecision {
        switch kind {
        case .killed:
            return isSelected ? .recreateImmediately : .recreateWhenSelected
        case .crash:
            guard crashWindow.recordAttempt(at: date) else {
                return .showStableFailure
            }
            return isSelected ? .recreateImmediately : .recreateWhenSelected
        }
    }

    public mutating func markSuccessfulComposite() {
        crashWindow.reset()
    }
}
