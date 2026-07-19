import Foundation
import GeckoView

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

final class StabilityDiagnostics {
    static let shared = StabilityDiagnostics()

    private struct ExportEnvelope: Codable {
        let schemaVersion: Int
        let generatedAt: Date
        let appVersion: String
        let appBuild: String
        let geckoVersion: String
        let operatingSystemVersion: String
        let hardwareIdentifier: String
        let includesCurrentSessionURLs: Bool
        let events: [StabilityEvent]
    }

    private let queue = DispatchQueue(
        label: "com.minh-ton.Reynard.StabilityDiagnostics.Queue",
        qos: .utility
    )
    private let fileManager: FileManager
    private let storageURL: URL?
    private var buffer = StabilityEventBuffer(capacity: 500)
    private var currentSessionURLs: [UUID: String] = [:]

    private init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if UserDataMigration.shared.latestReport?.requiresBlockingRecovery == true {
            storageURL = nil
        } else {
            storageURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent("AppData", isDirectory: true)
                .appendingPathComponent("Diagnostics", isDirectory: true)
                .appendingPathComponent("events.json", isDirectory: false)
        }
        loadPersistedEvents()
    }

    func record(
        _ category: StabilityEvent.Category,
        name: String,
        metadata: [String: String] = [:]
    ) {
        enqueue(
            StabilityEvent(
                id: UUID(),
                timestamp: Date(),
                category: category,
                name: name,
                metadata: sanitized(metadata)
            ),
            fullURL: nil
        )
    }

    func recordURL(
        _ category: StabilityEvent.Category,
        name: String,
        urlString: String?,
        metadata: [String: String] = [:]
    ) {
        var eventMetadata = sanitized(metadata)
        if let redactedURL = URLRedactor.redact(urlString) {
            eventMetadata["url"] = redactedURL
        }

        enqueue(
            StabilityEvent(
                id: UUID(),
                timestamp: Date(),
                category: category,
                name: name,
                metadata: eventMetadata
            ),
            fullURL: normalizedFullURL(urlString)
        )
    }

    func recordMigrationReport(_ report: UserDataMigrationReport) {
        recordMigrationResult(report.appData, area: "appData")
        recordMigrationResult(report.ddi, area: "ddi")
    }

    func exportData(includeFullURLs: Bool) throws -> Data {
        try queue.sync {
            let exportedEvents = buffer.events.map { event in
                guard includeFullURLs,
                      let fullURL = currentSessionURLs[event.id] else {
                    return event
                }

                var metadata = event.metadata
                metadata["fullURL"] = fullURL
                return StabilityEvent(
                    id: event.id,
                    timestamp: event.timestamp,
                    category: event.category,
                    name: event.name,
                    metadata: metadata
                )
            }

            let bundleInfo = Bundle.main.infoDictionary
            let envelope = ExportEnvelope(
                schemaVersion: 1,
                generatedAt: Date(),
                appVersion: bundleInfo?["CFBundleShortVersionString"] as? String ?? "Unknown",
                appBuild: bundleInfo?["CFBundleVersion"] as? String ?? "Unknown",
                geckoVersion: GeckoRuntime.version,
                operatingSystemVersion: ProcessInfo.processInfo.operatingSystemVersionString,
                hardwareIdentifier: Self.hardwareIdentifier(),
                includesCurrentSessionURLs: includeFullURLs,
                events: exportedEvents
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            return try encoder.encode(envelope)
        }
    }

    func clear() {
        queue.sync {
            buffer = StabilityEventBuffer(capacity: 500)
            currentSessionURLs.removeAll(keepingCapacity: true)
            if let storageURL {
                try? fileManager.removeItem(at: storageURL)
            }
        }
    }

    private func enqueue(_ event: StabilityEvent, fullURL: String?) {
        queue.async {
            self.buffer.append(event)
            if let fullURL {
                self.currentSessionURLs[event.id] = fullURL
            }
            self.pruneSensitiveURLsLocked()
            self.persistLocked()
        }
    }

    private func loadPersistedEvents() {
        guard let storageURL,
              let data = try? Data(contentsOf: storageURL) else {
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let events = try? decoder.decode([StabilityEvent].self, from: data) else {
            return
        }

        for event in events.suffix(500) {
            buffer.append(event)
        }
    }

    private func persistLocked() {
        guard let storageURL else {
            return
        }

        do {
            try fileManager.createDirectory(
                at: storageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(buffer.events)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            // Diagnostics must never become a browser launch or browsing blocker.
        }
    }

    private func pruneSensitiveURLsLocked() {
        let retainedIDs = Set(buffer.events.map(\.id))
        currentSessionURLs = currentSessionURLs.filter { retainedIDs.contains($0.key) }
    }

    private func sanitized(_ metadata: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in metadata {
            let sanitizedKey = String(key.prefix(80))
            guard !sanitizedKey.isEmpty else {
                continue
            }
            result[sanitizedKey] = String(value.prefix(512))
        }
        return result
    }

    private func normalizedFullURL(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty,
              URL(string: trimmedValue)?.scheme != nil else {
            return nil
        }
        return String(trimmedValue.prefix(4096))
    }

    private func recordMigrationResult(
        _ result: Result<UserDataMigrationReport.Outcome, UserDataMigrationError>,
        area: String
    ) {
        switch result {
        case let .success(outcome):
            record(
                .startup,
                name: "migration.\(area)",
                metadata: ["outcome": String(describing: outcome)]
            )

        case let .failure(error):
            var metadata = [
                "outcome": "failed",
                "error": String(describing: error),
            ]
            if case let .fileMigration(_, migrationError) = error {
                metadata["stage"] = migrationError.stage.rawValue
                metadata["code"] = String(migrationError.code)
            }
            record(
                .startup,
                name: "migration.\(area)",
                metadata: metadata
            )
        }
    }

    private static func hardwareIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
    }
}
