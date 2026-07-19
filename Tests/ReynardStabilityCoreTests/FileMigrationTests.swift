import Foundation
import XCTest
@testable import ReynardStabilityCore

final class FileMigrationTests: XCTestCase {
    private var temporaryRoot: URL!
    private let fileManager = FileManager.default

    override func setUpWithError() throws {
        temporaryRoot = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(
            at: temporaryRoot,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        if let temporaryRoot {
            try? fileManager.removeItem(at: temporaryRoot)
        }
        temporaryRoot = nil
    }

    func testNoSourceReturnsUnchanged() {
        let result = FileMigration(fileManager: fileManager).migrateDirectory(
            from: sourceURL,
            to: destinationURL
        )

        XCTAssertEqual(result, .success(.unchanged))
        XCTAssertFalse(fileManager.fileExists(atPath: destinationURL.path))
    }

    func testSuccessfulMigrationVerifiesDestinationBeforeRemovingSource() throws {
        try createSourceTree()

        let result = FileMigration(fileManager: fileManager).migrateDirectory(
            from: sourceURL,
            to: destinationURL
        )

        XCTAssertEqual(result, .success(.migrated))
        XCTAssertFalse(fileManager.fileExists(atPath: sourceURL.path))
        XCTAssertEqual(try read("settings.json", under: destinationURL), "settings")
        XCTAssertEqual(try read("nested/history.sqlite", under: destinationURL), "history")
    }

    func testMatchingPreexistingDestinationRecoversAndRemovesLegacySource() throws {
        try createSourceTree()
        try fileManager.copyItem(at: sourceURL, to: destinationURL)

        let result = FileMigration(fileManager: fileManager).migrateDirectory(
            from: sourceURL,
            to: destinationURL
        )

        XCTAssertEqual(result, .success(.recoveredExisting))
        XCTAssertFalse(fileManager.fileExists(atPath: sourceURL.path))
        XCTAssertEqual(try read("settings.json", under: destinationURL), "settings")
    }

    func testDifferentPreexistingDestinationIsPreservedWithLegacySource() throws {
        try createSourceTree()
        try write("changed!", to: destinationURL.appendingPathComponent("settings.json"))

        let result = FileMigration(fileManager: fileManager).migrateDirectory(
            from: sourceURL,
            to: destinationURL
        )

        XCTAssertEqual(result, .success(.recoveredExisting))
        XCTAssertTrue(fileManager.fileExists(atPath: sourceURL.path))
        XCTAssertEqual(try read("settings.json", under: destinationURL), "changed!")
        XCTAssertEqual(try read("settings.json", under: sourceURL), "settings")
    }

    func testInterruptedCopyRetainsSourceAndCanRetry() throws {
        try createSourceTree()
        var shouldFailCopy = true
        let migration = FileMigration(
            fileManager: fileManager,
            copyItem: { [fileManager] source, destination in
                if shouldFailCopy {
                    shouldFailCopy = false
                    try fileManager.createDirectory(
                        at: destination,
                        withIntermediateDirectories: true
                    )
                    try "partial".write(
                        to: destination.appendingPathComponent("partial.txt"),
                        atomically: true,
                        encoding: .utf8
                    )
                    throw CocoaError(.fileWriteUnknown)
                }
                try fileManager.copyItem(at: source, to: destination)
            }
        )

        let firstResult = migration.migrateDirectory(from: sourceURL, to: destinationURL)
        guard case let .failure(error) = firstResult else {
            return XCTFail("Expected the interrupted copy to fail")
        }
        XCTAssertEqual(error.stage, .copy)
        XCTAssertTrue(fileManager.fileExists(atPath: sourceURL.path))
        XCTAssertFalse(fileManager.fileExists(atPath: destinationURL.path))

        let retryResult = migration.migrateDirectory(from: sourceURL, to: destinationURL)
        XCTAssertEqual(retryResult, .success(.migrated))
        XCTAssertFalse(fileManager.fileExists(atPath: sourceURL.path))
        XCTAssertEqual(try read("nested/history.sqlite", under: destinationURL), "history")
    }

    private var sourceURL: URL {
        temporaryRoot.appendingPathComponent("Documents/AppData", isDirectory: true)
    }

    private var destinationURL: URL {
        temporaryRoot.appendingPathComponent("Application Support/AppData", isDirectory: true)
    }

    private func createSourceTree() throws {
        try write("settings", to: sourceURL.appendingPathComponent("settings.json"))
        try write("history", to: sourceURL.appendingPathComponent("nested/history.sqlite"))
    }

    private func write(_ value: String, to url: URL) throws {
        try fileManager.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try value.write(to: url, atomically: true, encoding: .utf8)
    }

    private func read(_ relativePath: String, under root: URL) throws -> String {
        try String(
            contentsOf: root.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}
