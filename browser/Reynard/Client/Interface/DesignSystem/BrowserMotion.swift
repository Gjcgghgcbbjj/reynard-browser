import UIKit

enum BrowserMotion {
    static func profile(
        for transition: BrowserMotionTransition,
        in view: UIView? = nil
    ) -> BrowserMotionProfile {
        let screen = view?.window?.screen ?? UIScreen.main
        return MotionPolicy.profile(
            for: transition,
            reduceMotion: UIAccessibility.isReduceMotionEnabled,
            maximumFramesPerSecond: screen.maximumFramesPerSecond
        )
    }

    static func animator(
        for transition: BrowserMotionTransition,
        in view: UIView? = nil,
        animations: @escaping () -> Void
    ) -> UIViewPropertyAnimator {
        let profile = profile(for: transition, in: view)
        let animator: UIViewPropertyAnimator

        if profile.usesSpring {
            let timing = UISpringTimingParameters(
                dampingRatio: CGFloat(profile.dampingRatio),
                initialVelocity: CGVector(
                    dx: CGFloat(profile.initialVelocity),
                    dy: CGFloat(profile.initialVelocity)
                )
            )
            animator = UIViewPropertyAnimator(
                duration: profile.duration,
                timingParameters: timing
            )
        } else {
            animator = UIViewPropertyAnimator(
                duration: profile.duration,
                curve: .easeInOut
            )
        }

        animator.addAnimations(animations)
        return animator
    }

    @discardableResult
    static func animate(
        _ transition: BrowserMotionTransition,
        in view: UIView? = nil,
        animations: @escaping () -> Void,
        completion: ((UIViewAnimatingPosition) -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        let animator = animator(
            for: transition,
            in: view,
            animations: animations
        )
        if let completion {
            animator.addCompletion(completion)
        }
        animator.startAnimation()
        return animator
    }

    static func reducedScale(
        for transition: BrowserMotionTransition,
        in view: UIView? = nil,
        proposedScale: CGFloat
    ) -> CGFloat {
        profile(for: transition, in: view).allowsScale ? proposedScale : 1
    }
}
