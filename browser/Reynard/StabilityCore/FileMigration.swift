import Foundation

public enum FileMigrationOutcome: Equatable, Sendable {
    case unchanged
    case migrated
    case recoveredExisting
}

public struct FileMigrationError: Error, Equatable, Sendable, LocalizedError {
    public enum Stage: String, Equatable, Sendable {
        case prepare
        case copy
        case verify
        case install
        case cleanup
    }

    public let stage: Stage
    public let code: Int

    public init(stage: Stage, code: Int) {
        self.stage = stage
        self.code = code
    }

    public var errorDescription: String? {
        "File migration failed during \(stage.rawValue) (error \(code))."
    }
}

public struct FileMigration {
    public typealias CopyItem = (_ source: URL, _ destination: URL) throws -> Void

    private let fileManager: FileManager
    private let copyItem: CopyItem

    public init(
        fileManager: FileManager = .default,
        copyItem: CopyItem? = nil
    ) {
        self.fileManager = fileManager
        self.copyItem = copyItem ?? { source, destination in
            try fileManager.copyItem(at: source, to: destination)
        }
    }

    public func migrateDirectory(
        from sourceURL: URL,
        to destinationURL: URL
    ) -> Result<FileMigrationOutcome, FileMigrationError> {
        let sourceExists = fileManager.fileExists(atPath: sourceURL.path)
        let destinationExists = fileManager.fileExists(atPath: destinationURL.path)

        guard sourceExists else {
            return .success(.unchanged)
        }

        if destinationExists {
            removeSourceIfVerifiedDuplicate(
                sourceURL: sourceURL,
                destinationURL: destinationURL
            )
            return .success(.recoveredExisting)
        }

        let destinationParentURL = destinationURL.deletingLastPathComponent()
        let stagingURL = destinationParentURL.appendingPathComponent(
            ".\(destinationURL.lastPathComponent).reynard-migration",
            isDirectory: true
        )

        do {
            try fileManager.createDirectory(
                at: destinationParentURL,
                withIntermediateDirectories: true
            )
        } catch {
            return .failure(migrationError(stage: .prepare, underlying: error))
        }

        if fileManager.fileExists(atPath: stagingURL.path) {
            do {
                try fileManager.removeItem(at: stagingURL)
            } catch {
                return .failure(migrationError(stage: .cleanup, underlying: error))
            }
        }

        do {
            try copyItem(sourceURL, stagingURL)
        } catch {
            return .failure(migrationError(stage: .copy, underlying: error))
        }

        do {
            guard try inventoriesMatch(sourceURL, stagingURL) else {
                return .failure(FileMigrationError(stage: .verify, code: 1))
            }
        } catch {
            return .failure(migrationError(stage: .verify, underlying: error))
        }

        do {
            try fileManager.moveItem(at: stagingURL, to: destinationURL)
        } catch {
            return .failure(migrationError(stage: .install, underlying: error))
        }

        do {
            guard try inventoriesMatch(sourceURL, destinationURL) else {
                try? fileManager.removeItem(at: destinationURL)
                return .failure(FileMigrationError(stage: .verify, code: 2))
            }
        } catch {
            try? fileManager.removeItem(at: destinationURL)
            return .failure(migrationError(stage: .verify, underlying: error))
        }

        do {
            try fileManager.removeItem(at: sourceURL)
            return .success(.migrated)
        } catch {
            return .success(.recoveredExisting)
        }
    }

    private func removeSourceIfVerifiedDuplicate(
        sourceURL: URL,
        destinationURL: URL
    ) {
        guard (try? inventoriesMatch(sourceURL, destinationURL)) == true else {
            return
        }
        try? fileManager.removeItem(at: sourceURL)
    }

    private func inventoriesMatch(_ firstURL: URL, _ secondURL: URL) throws -> Bool {
        try inventory(at: firstURL) == inventory(at: secondURL)
    }

    private func inventory(at rootURL: URL) throws -> [String] {
        var result: [String] = []
        try appendInventory(
            at: rootURL,
            relativePath: "",
            result: &result
        )
        return result.sorted()
    }

    private func appendInventory(
        at url: URL,
        relativePath: String,
        result: inout [String]
    ) throws {
        let values = try url.resourceValues(forKeys: [
            .isDirectoryKey,
            .isSymbolicLinkKey,
            .fileSizeKey,
        ])

        if values.isSymbolicLink == true {
            let target = try fileManager.destinationOfSymbolicLink(atPath: url.path)
            result.append("link:\(relativePath):\(target)")
            return
        }

        guard values.isDirectory == true else {
            result.append(
                "file:\(relativePath):\(values.fileSize ?? -1):\(try fileFingerprint(at: url))"
            )
            return
        }

        result.append("directory:\(relativePath)")
        let children = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [
                .isDirectoryKey,
                .isSymbolicLinkKey,
                .fileSizeKey,
            ]
        )

        for child in children.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let childRelativePath = relativePath.isEmpty
            ? child.lastPathComponent
            : "\(relativePath)/\(child.lastPathComponent)"
            try appendInventory(
                at: child,
                relativePath: childRelativePath,
                result: &result
            )
        }
    }

    private func fileFingerprint(at url: URL) throws -> String {
        guard let stream = InputStream(url: url) else {
            throw CocoaError(.fileReadUnknown)
        }

        stream.open()
        defer { stream.close() }

        var hash: UInt64 = 14_695_981_039_346_656_037
        var buffer = [UInt8](repeating: 0, count: 64 * 1024)

        while true {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count < 0 {
                throw stream.streamError ?? CocoaError(.fileReadUnknown)
            }
            if count == 0 {
                break
            }
            for byte in buffer.prefix(count) {
                hash ^= UInt64(byte)
                hash &*= 1_099_511_628_211
            }
        }

        return String(hash, radix: 16)
    }

    private func migrationError(
        stage: FileMigrationError.Stage,
        underlying error: Error
    ) -> FileMigrationError {
        FileMigrationError(
            stage: stage,
            code: (error as NSError).code
        )
    }
}
