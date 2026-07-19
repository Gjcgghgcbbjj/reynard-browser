import Foundation
import XCTest
@testable import ReynardBrowserCore

final class TranslationProviderTests: XCTestCase {
    func testGoogleDestinationKeepsPageButRemovesCredentials() throws {
        let source = try XCTUnwrap(
            URL(string: "https://user:secret@example.com/articles/1?q=swift#result")
        )

        let destination = try TranslationProvider.google.destination(
            for: TranslationRequest(sourceURL: source, targetLanguage: "zh-Hans")
        ).get()
        let components = try XCTUnwrap(
            URLComponents(url: destination, resolvingAgainstBaseURL: false)
        )
        let query = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) }
        )

        XCTAssertEqual(components.host, "translate.google.com")
        XCTAssertEqual(query["sl"] ?? nil, "auto")
        XCTAssertEqual(query["tl"] ?? nil, "zh-CN")
        XCTAssertEqual(
            query["u"] ?? nil,
            "https://example.com/articles/1?q=swift#result"
        )
    }

    func testRejectsNonWebSourceURL() throws {
        let source = try XCTUnwrap(URL(string: "file:///private/page.html"))

        XCTAssertEqual(
            TranslationProvider.google.destination(
                for: TranslationRequest(sourceURL: source, targetLanguage: "en")
            ),
            .failure(.unsupportedSourceURL)
        )
    }

    func testNormalizesPreferredLanguagesForProviders() {
        XCTAssertEqual(TranslationRequest.normalizedLanguage("zh-Hans-CN"), "zh-CN")
        XCTAssertEqual(TranslationRequest.normalizedLanguage("zh-Hant-TW"), "zh-TW")
        XCTAssertEqual(TranslationRequest.normalizedLanguage("fr-CA"), "fr")
        XCTAssertEqual(TranslationRequest.normalizedLanguage(""), "en")
    }

    func testCustomTemplateReplacesEncodedURLAndLanguage() throws {
        let source = try XCTUnwrap(
            URL(string: "https://example.com/path?q=one two&mode=full")
        )
        let template = "https://translator.example/submit?target={lang}&page={url}"

        let destination = try TranslationProvider.custom.destination(
            for: TranslationRequest(
                sourceURL: source,
                targetLanguage: "fr-CA",
                customTemplate: template
            )
        ).get()
        let components = try XCTUnwrap(
            URLComponents(url: destination, resolvingAgainstBaseURL: false)
        )
        let query = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) }
        )

        XCTAssertEqual(query["target"] ?? nil, "fr")
        XCTAssertEqual(
            query["page"] ?? nil,
            "https://example.com/path?q=one%20two&mode=full"
        )
    }

    func testCustomTemplateRequiresURLPlaceholder() {
        XCTAssertFalse(
            TranslationProvider.isValidCustomTemplate(
                "https://translator.example/?language={lang}"
            )
        )
    }

    func testCustomTemplateRejectsNonHTTPDestination() throws {
        let source = try XCTUnwrap(URL(string: "https://example.com"))

        XCTAssertEqual(
            TranslationProvider.custom.destination(
                for: TranslationRequest(
                    sourceURL: source,
                    targetLanguage: "en",
                    customTemplate: "javascript:translate('{url}')"
                )
            ),
            .failure(.invalidCustomTemplate)
        )
    }
}
