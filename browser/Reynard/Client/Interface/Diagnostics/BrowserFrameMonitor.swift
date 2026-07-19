import QuartzCore
import UIKit
import os.log

#if DEBUG
final class BrowserFrameMonitor: NSObject {
    private static let log = OSLog(
        subsystem: "com.minh-ton.Reynard",
        category: "BrowserAnimation"
    )

    private var displayLink: CADisplayLink?
    private var previousTimestamp: CFTimeInterval?
    private var remainingSamples = 0
    private var droppedFrames = 0
    private var label = ""
    private var expectedFrameDuration: CFTimeInterval = 1.0 / 60.0

    func start(
        label: String,
        in view: UIView?,
        sampleLimit: Int = 240
    ) {
        stop()

        let profile = BrowserMotion.profile(for: .contentFade, in: view)
        self.label = label
        remainingSamples = max(sampleLimit, 1)
        expectedFrameDuration = profile.frameBudget
        droppedFrames = 0
        previousTimestamp = nil

        os_signpost(
            .begin,
            log: Self.log,
            name: "BrowserAnimation",
            "%{public}@",
            label as NSString
        )

        let link = CADisplayLink(target: self, selector: #selector(sampleFrame(_:)))
        if #available(iOS 15.0, *) {
            let target = Float(profile.targetFramesPerSecond)
            link.preferredFrameRateRange = CAFrameRateRange(
                minimum: min(60, target),
                maximum: target,
                preferred: target
            )
        } else {
            link.preferredFramesPerSecond = profile.targetFramesPerSecond
        }
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        guard displayLink != nil else {
            return
        }

        displayLink?.invalidate()
        displayLink = nil
        os_signpost(
            .end,
            log: Self.log,
            name: "BrowserAnimation",
            "%{public}@ droppedFrames=%{public}d",
            label as NSString,
            droppedFrames
        )
        previousTimestamp = nil
        remainingSamples = 0
    }

    @objc private func sampleFrame(_ displayLink: CADisplayLink) {
        defer {
            previousTimestamp = displayLink.timestamp
            remainingSamples -= 1
            if remainingSamples <= 0 {
                stop()
            }
        }

        guard let previousTimestamp else {
            return
        }

        let elapsed = displayLink.timestamp - previousTimestamp
        let representedFrames = max(Int((elapsed / expectedFrameDuration).rounded()), 1)
        droppedFrames += max(representedFrames - 1, 0)
    }

    deinit {
        displayLink?.invalidate()
    }
}
#else
final class BrowserFrameMonitor {
    func start(label: String, in view: UIView?, sampleLimit: Int = 240) {}
    func stop() {}
}
#endif
