import Foundation

public enum TranslationProvider: String, CaseIterable, Codable, Sendable {
    case google
    case custom

    public func destination(
        for request: TranslationRequest
    ) -> Result<URL, TranslationRequestError> {
        guard let sourceURL = request.sanitizedSourceURL else {
            return .failure(.unsupportedSourceURL)
        }

        switch self {
        case .google:
            return googleDestination(
                sourceURL: sourceURL,
                targetLanguage: request.normalizedTargetLanguage
            )
        case .custom:
            return customDestination(
                sourceURL: sourceURL,
                targetLanguage: request.normalizedTargetLanguage,
                template: request.customTemplate
            )
        }
    }

    public static func isValidCustomTemplate(_ template: String) -> Bool {
        guard let sourceURL = URL(string: "https://example.com/page?q=reynard") else {
            return false
        }
        return TranslationProvider.custom.destination(
            for: TranslationRequest(
                sourceURL: sourceURL,
                targetLanguage: "en",
                customTemplate: template
            )
        ).isSuccess
    }

    private func googleDestination(
        sourceURL: URL,
        targetLanguage: String
    ) -> Result<URL, TranslationRequestError> {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "translate.google.com"
        components.path = "/translate"
        components.queryItems = [
            URLQueryItem(name: "sl", value: "auto"),
            URLQueryItem(name: "tl", value: targetLanguage),
            URLQueryItem(name: "u", value: sourceURL.absoluteString),
        ]

        guard let destinationURL = components.url else {
            return .failure(.invalidDestination)
        }
        return .success(destinationURL)
    }

    private func customDestination(
        sourceURL: URL,
        targetLanguage: String,
        template: String?
    ) -> Result<URL, TranslationRequestError> {
        guard let template else {
            return .failure(.missingCustomTemplate)
        }

        let normalizedTemplate = template.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedTemplate.contains("{url}") else {
            return .failure(.invalidCustomTemplate)
        }

        let destinationString = normalizedTemplate
            .replacingOccurrences(
                of: "{url}",
                with: Self.percentEncodedTemplateValue(sourceURL.absoluteString)
            )
            .replacingOccurrences(
                of: "{lang}",
                with: Self.percentEncodedTemplateValue(targetLanguage)
            )

        guard !destinationString.contains("{"),
              !destinationString.contains("}"),
              let destinationURL = URL(string: destinationString),
              let components = URLComponents(
                url: destinationURL,
                resolvingAgainstBaseURL: false
              ),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              components.host?.isEmpty == false,
              components.user == nil,
              components.password == nil else {
            return .failure(.invalidCustomTemplate)
        }

        return .success(destinationURL)
    }

    private static func percentEncodedTemplateValue(_ value: String) -> String {
        let unreserved = CharacterSet.alphanumerics.union(
            CharacterSet(charactersIn: "-._~")
        )
        return value.addingPercentEncoding(withAllowedCharacters: unreserved) ?? ""
    }
}

public struct TranslationRequest: Equatable, Sendable {
    public let sourceURL: URL
    public let targetLanguage: String
    public let customTemplate: String?

    public init(
        sourceURL: URL,
        targetLanguage: String,
        customTemplate: String? = nil
    ) {
        self.sourceURL = sourceURL
        self.targetLanguage = targetLanguage
        self.customTemplate = customTemplate
    }

    public var normalizedTargetLanguage: String {
        Self.normalizedLanguage(targetLanguage)
    }

    public static func normalizedLanguage(_ language: String) -> String {
        let normalized = language
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "-")
        guard !normalized.isEmpty else {
            return "en"
        }

        let components = normalized.split(separator: "-").map(String.init)
        guard let languageComponent = components.first else {
            return "en"
        }
        let languageCode = languageComponent.lowercased()
        guard (2...3).contains(languageCode.count),
              languageCode.allSatisfy(\.isLetter) else {
            return "en"
        }

        guard languageCode == "zh" else {
            return languageCode
        }

        let scriptCode = components.dropFirst().first(where: {
            $0.count == 4 && $0.allSatisfy(\.isLetter)
        })?.lowercased()
        let countryCode = components.dropFirst().first(where: {
            ($0.count == 2 && $0.allSatisfy(\.isLetter)) ||
            ($0.count == 3 && $0.allSatisfy(\.isNumber))
        })?.uppercased()
        let usesTraditionalChinese = scriptCode == "hant" || ["TW", "HK", "MO"]
            .contains(countryCode ?? "")
        return usesTraditionalChinese ? "zh-TW" : "zh-CN"
    }

    fileprivate var sanitizedSourceURL: URL? {
        guard var components = URLComponents(
            url: sourceURL,
            resolvingAgainstBaseURL: false
        ),
        let scheme = components.scheme?.lowercased(),
        scheme == "http" || scheme == "https",
        components.host?.isEmpty == false else {
            return nil
        }

        components.scheme = scheme
        components.user = nil
        components.password = nil
        return components.url
    }
}

public enum TranslationRequestError: Error, Equatable, Sendable {
    case unsupportedSourceURL
    case missingCustomTemplate
    case invalidCustomTemplate
    case invalidDestination
}

private extension Result {
    var isSuccess: Bool {
        guard case .success = self else {
            return false
        }
        return true
    }
}
