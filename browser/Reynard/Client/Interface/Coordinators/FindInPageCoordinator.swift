import GeckoView
import UIKit

@MainActor
final class FindInPageCoordinator {
    private weak var browserChrome: BrowserChrome?
    private let sessionProvider: () -> GeckoSession?
    private weak var activeSession: GeckoSession?
    private var queryTask: Task<Void, Never>?
    private var generation = 0

    init(
        browserChrome: BrowserChrome,
        sessionProvider: @escaping () -> GeckoSession?
    ) {
        self.browserChrome = browserChrome
        self.sessionProvider = sessionProvider
    }

    func present() {
        guard let session = sessionProvider() else {
            return
        }
        activeSession = session
        session.finder.setDisplayOptions([.highlightAll])
        browserChrome?.showActionBar(.findInPage, animated: true)
        browserChrome?.updateFindInPageResult(nil)
    }

    func queryChanged(_ query: String) {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            generation += 1
            queryTask?.cancel()
            activeSession?.finder.clear()
            browserChrome?.updateFindInPageResult(nil)
            return
        }
        performFind(query: normalized, direction: .forward, delayNanoseconds: 150_000_000)
    }

    func findPrevious() {
        performFind(query: nil, direction: .backward, delayNanoseconds: 0)
    }

    func findNext() {
        performFind(query: nil, direction: .forward, delayNanoseconds: 0)
    }

    func dismissPresentation(animated: Bool) {
        guard activeSession != nil else {
            return
        }
        browserChrome?.dismissActionBar(animated: animated)
    }

    func actionBarDidDismiss() {
        generation += 1
        queryTask?.cancel()
        queryTask = nil
        activeSession?.finder.clear()
        activeSession = nil
    }

    private func performFind(
        query: String?,
        direction: FindInPageDirection,
        delayNanoseconds: UInt64
    ) {
        guard let session = activeSession else {
            return
        }

        generation += 1
        let requestGeneration = generation
        queryTask?.cancel()
        queryTask = Task { [weak self, weak session] in
            if delayNanoseconds > 0 {
                try? await Task.sleep(nanoseconds: delayNanoseconds)
            }
            guard !Task.isCancelled,
                  let self,
                  let session,
                  self.activeSession === session,
                  self.generation == requestGeneration else {
                return
            }

            do {
                let result = try await session.finder.find(
                    query,
                    direction: direction
                )
                guard !Task.isCancelled,
                      self.activeSession === session,
                      self.generation == requestGeneration else {
                    return
                }
                self.browserChrome?.updateFindInPageResult(result)
            } catch {
                guard !Task.isCancelled else {
                    return
                }
                self.browserChrome?.updateFindInPageResult(nil)
                StabilityDiagnostics.shared.record(
                    .session,
                    name: "findInPage.failed",
                    metadata: ["error": String(describing: error)]
                )
            }
        }
    }
}
