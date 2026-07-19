import XCTest
@testable import ReynardBrowserCore

final class ViaFeaturePolicyTests: XCTestCase {
    func testNightModeSiteOverrideWinsOverGlobalAndSystem() {
        XCTAssertTrue(ViaFeaturePolicy.resolvesNightMode(global: .off, siteOverride: .enabled, systemUsesDarkAppearance: false))
        XCTAssertFalse(ViaFeaturePolicy.resolvesNightMode(global: .on, siteOverride: .disabled, systemUsesDarkAppearance: true))
        XCTAssertTrue(ViaFeaturePolicy.resolvesNightMode(global: .automatic, siteOverride: .inherit, systemUsesDarkAppearance: true))
    }

    func testBlockingSiteResolutionCanDisableOrRestoreBalancedMode() {
        XCTAssertEqual(ViaFeaturePolicy.resolvesBlocking(global: .strict, siteOverride: .disabled), .off)
        XCTAssertEqual(ViaFeaturePolicy.resolvesBlocking(global: .off, siteOverride: .enabled), .balanced)
    }

    func testRulesAreTrimmedDeduplicatedAndCommentsRemoved() {
        XCTAssertEqual(ViaFeaturePolicy.sanitizeRules([" ||ads.example^ ", "! comment", "", "||ads.example^"]), ["||ads.example^"])
    }

    func testFilterSubscriptionRejectsNonWebURLs() {
        XCTAssertNil(BrowserFilterSubscription(name: "Local", sourceURL: URL(fileURLWithPath: "/tmp/list")))
        XCTAssertNotNil(BrowserFilterSubscription(name: "EasyList", sourceURL: URL(string: "https://example.com/list.txt")!))
    }

    func testUserScriptParserReadsMetadataAndPermissions() throws {
        let script = try UserScriptParser.parse("""
        // ==UserScript==
        // @name Example
        // @namespace test
        // @version 1.0
        // @match https://example.com/*
        // @grant GM_getValue
        // ==/UserScript==
        console.log('ok')
        """)
        XCTAssertEqual(script.name, "Example")
        XCTAssertEqual(script.matches, ["https://example.com/*"])
        XCTAssertEqual(script.grants, ["GM_getValue"])
    }

    func testUserScriptParserRejectsMissingScope() {
        XCTAssertThrowsError(try UserScriptParser.parse("// ==UserScript==\n// @name No scope\n// ==/UserScript==")) { error in
            XCTAssertEqual(error as? UserScriptParseError, .missingMatch)
        }
    }

    func testBackupManifestRejectsUnknownVersionAndPayloadMismatch() throws {
        let valid = BrowserBackupManifest(categories: [.preferences], payloads: ["preferences": Data("{}".utf8)])
        XCTAssertNoThrow(try valid.validate())
        XCTAssertThrowsError(try BrowserBackupManifest(version: 2, categories: [], payloads: [:]).validate())
        XCTAssertThrowsError(try BrowserBackupManifest(categories: [.preferences], payloads: [:]).validate())
    }
}
