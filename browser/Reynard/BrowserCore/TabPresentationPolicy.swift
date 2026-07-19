import Foundation

public enum BrowserTabMode: String, Codable, Sendable {
    case regular
    case privateBrowsing
}

public struct BrowserTabPresentationItem: Equatable, Identifiable, Sendable {
    public let id: String
    public let mode: BrowserTabMode
    public let isSelected: Bool

    public init(id: String, mode: BrowserTabMode, isSelected: Bool) {
        self.id = id
        self.mode = mode
        self.isSelected = isSelected
    }
}

public struct BrowserTabPresentationSnapshot: Equatable, Sendable {
    public let regular: [BrowserTabPresentationItem]
    public let privateBrowsing: [BrowserTabPresentationItem]

    public init(items: [BrowserTabPresentationItem]) {
        regular = items.filter { $0.mode == .regular }
        privateBrowsing = items.filter { $0.mode == .privateBrowsing }
    }

    public func items(for mode: BrowserTabMode) -> [BrowserTabPresentationItem] {
        mode == .regular ? regular : privateBrowsing
    }
}

public struct BrowserTabGridLayout: Equatable, Sendable {
    public let columns: Int
    public let horizontalInset: Double
    public let spacing: Double

    public init(columns: Int, horizontalInset: Double, spacing: Double) {
        self.columns = columns
        self.horizontalInset = horizontalInset
        self.spacing = spacing
    }
}

public struct BrowserTabMove: Equatable, Sendable {
    public let source: Int
    public let destination: Int

    public init?(source: Int, destination: Int, count: Int) {
        guard count > 0,
              (0..<count).contains(source),
              (0..<count).contains(destination),
              source != destination else {
            return nil
        }
        self.source = source
        self.destination = destination
    }
}

public struct BrowserSidebarPresentation: Equatable, Sendable {
    public let isCollapsed: Bool
    public let width: Double
    public let showsTitles: Bool

    public init(isCollapsed: Bool, width: Double, showsTitles: Bool) {
        self.isCollapsed = isCollapsed
        self.width = width
        self.showsTitles = showsTitles
    }
}

public enum TabPresentationPolicy {
    public static func gridLayout(containerWidth: Double) -> BrowserTabGridLayout {
        switch containerWidth {
        case ..<390:
            return BrowserTabGridLayout(columns: 2, horizontalInset: 12, spacing: 12)
        case ..<700:
            return BrowserTabGridLayout(columns: 2, horizontalInset: 16, spacing: 16)
        default:
            return BrowserTabGridLayout(columns: 3, horizontalInset: 20, spacing: 18)
        }
    }

    public static func sidebar(
        collapsed: Bool,
        availableWidth: Double
    ) -> BrowserSidebarPresentation {
        if collapsed {
            return BrowserSidebarPresentation(isCollapsed: true, width: 72, showsTitles: false)
        }
        let width = min(max(availableWidth * 0.28, 280), 360)
        return BrowserSidebarPresentation(isCollapsed: false, width: width, showsTitles: true)
    }
}
