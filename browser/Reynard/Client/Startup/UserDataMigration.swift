//
//  UserDataMigration.swift
//  Reynard
//
//  Created by Minh Ton on 17/5/26.
//

import Foundation

struct UserDataMigrationReport: Equatable {
    enum Outcome: Equatable {
        case unchanged
        case migrated
        case recoveredExisting
    }

    let appData: Result<Outcome, UserDataMigrationError>
    let ddi: Result<Outcome, UserDataMigrationError>

    var blockingError: UserDataMigrationError? {
        guard case let .failure(error) = appData else {
            return nil
        }
        return error
    }

    var requiresBlockingRecovery: Bool {
        blockingError != nil
    }
}

enum UserDataMigrationError: Error, Equatable, LocalizedError {
    enum Directory: String, Equatable {
        case documents
        case applicationSupport
    }

    enum Area: String, Equatable {
        case appData
        case ddi
    }

    case directoryUnavailable(Directory)
    case fileMigration(area: Area, error: FileMigrationError)

    var errorDescription: String? {
        switch self {
        case let .directoryUnavailable(directory):
            return "The \(directory.rawValue) directory is unavailable."
        case let .fileMigration(area, error):
            return "\(area.rawValue) migration failed: \(error.localizedDescription)"
        }
    }
}

final class UserDataMigration {
    static let shared = UserDataMigration()

    private let fileManager: FileManager
    private let documentsDirectoryURL: URL?
    private let applicationSupportDirectoryURL: URL?
    private let fileMigration: FileMigration
    private(set) var latestReport: UserDataMigrationReport?

    private convenience init(fileManager: FileManager = .default) {
        self.init(
            fileManager: fileManager,
            documentsDirectoryURL: fileManager.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first,
            applicationSupportDirectoryURL: fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
        )
    }

    init(
        fileManager: FileManager,
        documentsDirectoryURL: URL?,
        applicationSupportDirectoryURL: URL?,
        fileMigration: FileMigration? = nil
    ) {
        self.fileManager = fileManager
        self.documentsDirectoryURL = documentsDirectoryURL
        self.applicationSupportDirectoryURL = applicationSupportDirectoryURL
        self.fileMigration = fileMigration ?? FileMigration(fileManager: fileManager)
    }

    @discardableResult
    func run() -> UserDataMigrationReport {
        let report = UserDataMigrationReport(
            appData: migrateDirectory(named: "AppData", area: .appData),
            ddi: migrateDirectory(named: "DDI", area: .ddi)
        )

        if case .success = report.appData,
           let applicationSupportDirectoryURL {
            removeLegacyStoreFolders(
                in: applicationSupportDirectoryURL.appendingPathComponent(
                    "AppData",
                    isDirectory: true
                )
            )
        }
        removeLegacyUserAgentOverride()
        latestReport = report
        return report
    }

    private func migrateDirectory(
        named name: String,
        area: UserDataMigrationError.Area
    ) -> Result<UserDataMigrationReport.Outcome, UserDataMigrationError> {
        guard let applicationSupportDirectoryURL else {
            return .failure(.directoryUnavailable(.applicationSupport))
        }

        let destinationURL = applicationSupportDirectoryURL.appendingPathComponent(
            name,
            isDirectory: true
        )

        guard let documentsDirectoryURL else {
            if fileManager.fileExists(atPath: destinationURL.path) {
                return .success(.recoveredExisting)
            }
            return .failure(.directoryUnavailable(.documents))
        }

        let sourceURL = documentsDirectoryURL.appendingPathComponent(
            name,
            isDirectory: true
        )

        return fileMigration.migrateDirectory(from: sourceURL, to: destinationURL)
            .map { outcome in
                switch outcome {
                case .unchanged:
                    return .unchanged
                case .migrated:
                    return .migrated
                case .recoveredExisting:
                    return .recoveredExisting
                }
            }
            .mapError { error in
                .fileMigration(area: area, error: error)
            }
    }

    private func removeLegacyUserAgentOverride() {
        guard let documentsDirectoryURL else {
            return
        }
        try? fileManager.removeItem(
            at: documentsDirectoryURL.appendingPathComponent(
                "ua-override.json",
                isDirectory: false
            )
        )
    }

    private func removeLegacyStoreFolders(in appDataDirectoryURL: URL) {
        for folderName in ["TabManagement", "Favicons"] {
            let folderURL = appDataDirectoryURL.appendingPathComponent(
                folderName,
                isDirectory: true
            )
            try? fileManager.removeItem(at: folderURL)
        }
    }
}
