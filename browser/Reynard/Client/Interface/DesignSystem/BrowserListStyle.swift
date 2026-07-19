import UIKit

enum BrowserListStyle {
    static func apply(to tableView: UITableView) {
        tableView.backgroundColor = BrowserDesignTokens.Color.chromeBackground
        tableView.separatorColor = BrowserDesignTokens.Color.separator
        tableView.rowHeight = UITableView.automaticDimension
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.keyboardDismissMode = .interactive
        tableView.tintColor = BrowserDesignTokens.Color.accent
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }

    static func apply(to cell: UITableViewCell) {
        cell.backgroundColor = BrowserDesignTokens.Color.elevatedSurface
        cell.contentView.backgroundColor = .clear
        cell.tintColor = BrowserDesignTokens.Color.accent
        let selected = UIView()
        selected.backgroundColor = BrowserDesignTokens.Color.accent.withAlphaComponent(0.12)
        cell.selectedBackgroundView = selected
    }

    static func applyNavigation(to navigationBar: UINavigationBar) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = BrowserDesignTokens.Color.chromeBackground
        appearance.shadowColor = BrowserDesignTokens.Color.separator
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        navigationBar.standardAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.tintColor = BrowserDesignTokens.Color.accent
    }
}

final class BrowserSectionHeaderView: UIView {
    private let label = UILabel()

    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = BrowserDesignTokens.Color.chromeBackground
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = BrowserDesignTokens.Typography.sectionTitle
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.text = title
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: BrowserDesignTokens.Spacing.medium),
            label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -BrowserDesignTokens.Spacing.small),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
