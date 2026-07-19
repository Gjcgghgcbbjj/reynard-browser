import UIKit

enum ChromePresentationMode {
    case browsing
    case tabOverview
    case fullscreenMedia
}

enum ChromeSearchState {
    case inactive
    case focused
    case scrollingEmbeddedSuggestions
    case scrollingDetachedSuggestions

    var showsAddressBarDismissButton: Bool {
        switch self {
        case .inactive:
            return false
        case .focused, .scrollingEmbeddedSuggestions, .scrollingDetachedSuggestions:
            return true
        }
    }
}

struct ChromePresentationState {
    let position: BrowserChromePosition
    let mode: BrowserChromeMode
    let presentation: ChromePresentationMode
    let search: ChromeSearchState
    let topInset: CGFloat
    let interfaceIdiom: UIUserInterfaceIdiom
    let orientation: BrowserLayout.ViewportOrientation
    let isTwoThirdSplitScreenOrSmaller: Bool
    let sidebarButtonVisible: Bool
    let animatesChromeStateChanges: Bool
    let toolbarActions: [BrowserToolbarAction]
}
