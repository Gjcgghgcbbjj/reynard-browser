import XCTest
@testable import ReynardStabilityCore

final class URLRedactorTests: XCTestCase {
    func testRedactionRemovesCredentialsPathQueryAndFragment() {
        let value = "https://user:password@Sub.Example.com:8443/private/path?token=secret#fragment"

        XCTAssertEqual(URLRedactor.redact(value), "https://sub.example.com")
    }

    func testRedactionKeepsSchemeForHostlessBrowserURL() {
        XCTAssertEqual(URLRedactor.redact("about:blank"), "about:")
    }

    func testRedactionRejectsValuesWithoutScheme() {
        XCTAssertNil(URLRedactor.redact("example.com/private"))
    }

    func testRedactionHandlesNilAndBlankValues() {
        XCTAssertNil(URLRedactor.redact(nil))
        XCTAssertNil(URLRedactor.redact("  "))
    }
}
