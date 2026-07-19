import Foundation

public enum BrowserMotionTransition: String, CaseIterable, Sendable {
    case chrome
    case tabGrid
    case tabSelection
    case sidebar
    case contentFade
}

public struct BrowserMotionProfile: Equatable, Sendable {
    public let duration: TimeInterval
    public let dampingRatio: Double
    public let initialVelocity: Double
    public let usesSpring: Bool
    public let allowsScale: Bool
    public let targetFramesPerSecond: Int

    public var frameBudget: TimeInterval {
        1.0 / Double(targetFramesPerSecond)
    }

    public init(
        duration: TimeInterval,
        dampingRatio: Double,
        initialVelocity: Double,
        usesSpring: Bool,
        allowsScale: Bool,
        targetFramesPerSecond: Int
    ) {
        self.duration = duration
        self.dampingRatio = dampingRatio
        self.initialVelocity = initialVelocity
        self.usesSpring = usesSpring
        self.allowsScale = allowsScale
        self.targetFramesPerSecond = targetFramesPerSecond
    }
}

public enum MotionPolicy {
    public static func profile(
        for transition: BrowserMotionTransition,
        reduceMotion: Bool,
        maximumFramesPerSecond: Int
    ) -> BrowserMotionProfile {
        let targetFramesPerSecond = targetFramesPerSecond(
            maximumFramesPerSecond: maximumFramesPerSecond
        )

        if reduceMotion {
            return BrowserMotionProfile(
                duration: reducedDuration(for: transition),
                dampingRatio: 1,
                initialVelocity: 0,
                usesSpring: false,
                allowsScale: false,
                targetFramesPerSecond: targetFramesPerSecond
            )
        }

        let timing = standardTiming(for: transition)
        return BrowserMotionProfile(
            duration: timing.duration,
            dampingRatio: timing.dampingRatio,
            initialVelocity: timing.initialVelocity,
            usesSpring: true,
            allowsScale: transition != .contentFade,
            targetFramesPerSecond: targetFramesPerSecond
        )
    }

    public static func targetFramesPerSecond(
        maximumFramesPerSecond: Int
    ) -> Int {
        maximumFramesPerSecond >= 120 ? 120 : 60
    }

    private static func reducedDuration(
        for transition: BrowserMotionTransition
    ) -> TimeInterval {
        switch transition {
        case .chrome, .contentFade:
            return 0.12
        case .tabGrid, .tabSelection, .sidebar:
            return 0.16
        }
    }

    private static func standardTiming(
        for transition: BrowserMotionTransition
    ) -> (duration: TimeInterval, dampingRatio: Double, initialVelocity: Double) {
        switch transition {
        case .chrome:
            return (0.22, 0.90, 0)
        case .tabGrid:
            return (0.32, 0.86, 0)
        case .tabSelection:
            return (0.38, 0.82, 0)
        case .sidebar:
            return (0.30, 0.88, 0)
        case .contentFade:
            return (0.18, 1, 0)
        }
    }
}
