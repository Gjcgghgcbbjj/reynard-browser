import Foundation

public final class LifecycleFlushPolicy: @unchecked Sendable {
    public typealias Completion = (Bool) -> Void
    public typealias Start = (@escaping Completion) -> Void
    public typealias ScheduleTimeout = (
        _ timeout: TimeInterval,
        _ action: @escaping () -> Void
    ) -> () -> Void

    private let lock = NSLock()
    private let timeout: TimeInterval
    private let scheduleTimeout: ScheduleTimeout
    private var generation: UInt64 = 0
    private var isFlushInFlight = false
    private var waiters: [Completion] = []
    private var cancelTimeout: (() -> Void)?

    public convenience init(timeout: TimeInterval = 2) {
        self.init(
            timeout: timeout,
            scheduleTimeout: LifecycleFlushPolicy.dispatchTimeout
        )
    }

    public init(
        timeout: TimeInterval = 2,
        scheduleTimeout: @escaping ScheduleTimeout
    ) {
        self.timeout = max(timeout, 0)
        self.scheduleTimeout = scheduleTimeout
    }

    public func requestFlush(
        start: @escaping Start,
        completion: @escaping Completion
    ) {
        lock.lock()
        waiters.append(completion)
        guard !isFlushInFlight else {
            lock.unlock()
            return
        }

        isFlushInFlight = true
        generation &+= 1
        let activeGeneration = generation
        lock.unlock()

        let cancellation = scheduleTimeout(timeout) { [weak self] in
            self?.finish(generation: activeGeneration, success: false)
        }

        lock.lock()
        let shouldRetainCancellation = isFlushInFlight && generation == activeGeneration
        if shouldRetainCancellation {
            cancelTimeout = cancellation
        }
        lock.unlock()

        if !shouldRetainCancellation {
            cancellation()
        }

        start { [weak self] success in
            self?.finish(generation: activeGeneration, success: success)
        }
    }

    private func finish(generation completedGeneration: UInt64, success: Bool) {
        lock.lock()
        guard isFlushInFlight, generation == completedGeneration else {
            lock.unlock()
            return
        }

        isFlushInFlight = false
        let completions = waiters
        waiters.removeAll(keepingCapacity: true)
        let cancellation = cancelTimeout
        cancelTimeout = nil
        lock.unlock()

        cancellation?()
        completions.forEach { $0(success) }
    }

    private static func dispatchTimeout(
        _ timeout: TimeInterval,
        _ action: @escaping () -> Void
    ) -> () -> Void {
        let workItem = DispatchWorkItem(block: action)
        DispatchQueue.global(qos: .utility).asyncAfter(
            deadline: .now() + timeout,
            execute: workItem
        )
        return {
            workItem.cancel()
        }
    }
}
