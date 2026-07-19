import Foundation

public enum BrowserSiteOverride: String, Codable, Sendable {
    case inherit
    case enabled
    case disabled
}

public enum BrowserNightMode: String, CaseIterable, Codable, Sendable {
    case off
    case automatic
    case on
}

public enum BrowserBlockingMode: String, CaseIterable, Codable, Sendable {
    case off
    case balanced
    case strict
}

public enum ThirdPartyCookiePolicy: String, CaseIterable, Codable, Sendable {
    case allow
    case blockTrackers
    case blockAll
}

public enum ViaFeaturePolicy {
    public static func resolvesNightMode(
        global: BrowserNightMode,
        siteOverride: BrowserSiteOverride,
        systemUsesDarkAppearance: Bool
    ) -> Bool {
        switch siteOverride {
        case .enabled: return true
        case .disabled: return false
        case .inherit:
            switch global {
            case .off: return false
            case .on: return true
            case .automatic: return systemUsesDarkAppearance
            }
        }
    }

    public static func resolvesBlocking(
        global: BrowserBlockingMode,
        siteOverride: BrowserSiteOverride
    ) -> BrowserBlockingMode {
        switch siteOverride {
        case .enabled: return global == .off ? .balanced : global
        case .disabled: return .off
        case .inherit: return global
        }
    }

    public static func sanitizeRules(_ rules: [String], maximumCount: Int = 10_000) -> [String] {
        var result: [String] = []
        for rule in rules {
            let value = rule.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty, !value.hasPrefix("!"), !result.contains(value) else { continue }
            result.append(value)
            if result.count == maximumCount { break }
        }
        return result
    }
}

public struct BrowserFilterSubscription: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var sourceURL: URL
    public var isEnabled: Bool
    public var lastUpdatedAt: Date?
    public var lastError: String?

    public init?(id: UUID = UUID(), name: String, sourceURL: URL, isEnabled: Bool = true, lastUpdatedAt: Date? = nil, lastError: String? = nil) {
        guard ["https", "http"].contains(sourceURL.scheme?.lowercased() ?? ""),
              !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.sourceURL = sourceURL
        self.isEnabled = isEnabled
        self.lastUpdatedAt = lastUpdatedAt
        self.lastError = lastError
    }
}

public struct BrowserUserScript: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var namespace: String?
    public var version: String?
    public var matches: [String]
    public var grants: [String]
    public var source: String
    public var isEnabled: Bool
    public var allowsPrivateBrowsing: Bool

    public init(id: UUID = UUID(), name: String, namespace: String?, version: String?, matches: [String], grants: [String], source: String, isEnabled: Bool = true, allowsPrivateBrowsing: Bool = false) {
        self.id = id
        self.name = name
        self.namespace = namespace
        self.version = version
        self.matches = matches
        self.grants = grants
        self.source = source
        self.isEnabled = isEnabled
        self.allowsPrivateBrowsing = allowsPrivateBrowsing
    }
}

public enum UserScriptParseError: Error, Equatable, Sendable {
    case missingHeader
    case missingName
    case missingMatch
    case sourceTooLarge
}

public enum UserScriptParser {
    public static func parse(_ source: String, maximumBytes: Int = 1_000_000) throws -> BrowserUserScript {
        guard source.utf8.count <= maximumBytes else { throw UserScriptParseError.sourceTooLarge }
        guard let start = source.range(of: "// ==UserScript=="),
              let end = source.range(of: "// ==/UserScript==", range: start.upperBound..<source.endIndex) else {
            throw UserScriptParseError.missingHeader
        }
        let header = source[start.upperBound..<end.lowerBound]
        var values: [String: [String]] = [:]
        for line in header.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("//"), let marker = trimmed.firstIndex(of: "@") else { continue }
            let directive = trimmed[marker...].split(maxSplits: 1, whereSeparator: \.isWhitespace)
            guard directive.count == 2 else { continue }
            let key = String(directive[0].dropFirst())
            values[key, default: []].append(String(directive[1]).trimmingCharacters(in: .whitespaces))
        }
        guard let name = values["name"]?.first, !name.isEmpty else { throw UserScriptParseError.missingName }
        let matches = (values["match"] ?? []) + (values["include"] ?? [])
        guard !matches.isEmpty else { throw UserScriptParseError.missingMatch }
        return BrowserUserScript(
            name: name,
            namespace: values["namespace"]?.first,
            version: values["version"]?.first,
            matches: Array(Set(matches)).sorted(),
            grants: Array(Set(values["grant"] ?? [])).sorted(),
            source: source
        )
    }
}

public enum BrowserBackupCategory: String, CaseIterable, Codable, Sendable {
    case preferences
    case userScripts
    case filterConfiguration
}

public struct BrowserBackupManifest: Codable, Equatable, Sendable {
    public static let currentVersion = 1
    public let version: Int
    public let createdAt: Date
    public let categories: [BrowserBackupCategory]
    public let payloads: [String: Data]

    public init(version: Int = currentVersion, createdAt: Date = Date(), categories: [BrowserBackupCategory], payloads: [String: Data]) {
        self.version = version
        self.createdAt = createdAt
        self.categories = categories
        self.payloads = payloads
    }

    public func validate() throws {
        guard version == Self.currentVersion else { throw BrowserBackupError.unsupportedVersion }
        guard Set(categories.map(\.rawValue)) == Set(payloads.keys), categories.count == Set(categories).count else {
            throw BrowserBackupError.categoryMismatch
        }
    }
}

public enum BrowserBackupError: Error, Equatable, Sendable {
    case unsupportedVersion
    case categoryMismatch
    case invalidPayload
}
