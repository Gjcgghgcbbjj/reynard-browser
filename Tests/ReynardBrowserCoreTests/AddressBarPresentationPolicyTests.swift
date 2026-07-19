import XCTest
@testable import ReynardBrowserCore

final class AddressBarPresentationPolicyTests: XCTestCase {
    func testEditingHidesChromeButtonsAndShowsTypedContent() {
        let model = AddressBarPresentationPolicy.resolve(
            editing: true,
            hasTypedText: true,
            hasPageContent: true,
            isLoading: false,
            isPhoneBottomChrome: true,
            canShowMenu: true
        )

        XCTAssertEqual(model.content, .typedText)
        XCTAssertEqual(model.leadingButton, .hidden)
        XCTAssertEqual(model.trailingButton, .hidden)
    }

    func testLoadingPageShowsMenuPlaceholderAndStop() {
        let model = AddressBarPresentationPolicy.resolve(
            editing: false,
            hasTypedText: false,
            hasPageContent: true,
            isLoading: true,
            isPhoneBottomChrome: true,
            canShowMenu: true
        )

        XCTAssertEqual(model.content, .page)
        XCTAssertEqual(model.leadingButton, .loading)
        XCTAssertEqual(model.trailingButton, .stop)
    }

    func testIdlePageShowsMenuAndReload() {
        let model = AddressBarPresentationPolicy.resolve(
            editing: false,
            hasTypedText: false,
            hasPageContent: true,
            isLoading: false,
            isPhoneBottomChrome: false,
            canShowMenu: true
        )

        XCTAssertEqual(model.leadingButton, .menu)
        XCTAssertEqual(model.trailingButton, .reload)
    }

    func testBottomPhonePlaceholderShowsSearchOnly() {
        let model = AddressBarPresentationPolicy.resolve(
            editing: false,
            hasTypedText: false,
            hasPageContent: false,
            isLoading: false,
            isPhoneBottomChrome: true,
            canShowMenu: false
        )

        XCTAssertEqual(model.content, .placeholder)
        XCTAssertEqual(model.leadingButton, .search)
        XCTAssertEqual(model.trailingButton, .hidden)
    }
}
