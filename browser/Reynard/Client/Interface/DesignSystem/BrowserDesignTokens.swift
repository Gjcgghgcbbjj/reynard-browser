import UIKit

enum BrowserDesignTokens {
    enum Spacing {
        static let extraSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
        static let section: CGFloat = 32
    }

    enum Radius {
        static let control: CGFloat = 10
        static let chrome: CGFloat = 16
        static let card: CGFloat = 18
        static let largeCard: CGFloat = 24
        static let capsule: CGFloat = 999
    }

    enum Control {
        static let compactHeight: CGFloat = 36
        static let standardHeight: CGFloat = 44
        static let prominentHeight: CGFloat = 52
        static let minimumHitSize: CGFloat = 44
        static let iconPointSize: CGFloat = 17
    }

    enum Typography {
        static var address: UIFont {
            UIFont.preferredFont(forTextStyle: .body)
        }

        static var toolbarLabel: UIFont {
            UIFont.preferredFont(forTextStyle: .caption1)
        }

        static var cardTitle: UIFont {
            UIFont.preferredFont(forTextStyle: .headline)
        }

        static var cardDetail: UIFont {
            UIFont.preferredFont(forTextStyle: .subheadline)
        }

        static var sectionTitle: UIFont {
            UIFont.preferredFont(forTextStyle: .title3)
        }
    }

    enum Color {
        static let accent = UIColor { traits in
            traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.54, green: 0.68, blue: 1, alpha: 1)
            : UIColor(red: 0.20, green: 0.38, blue: 0.88, alpha: 1)
        }

        static let chromeBackground = UIColor { traits in
            traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.08, blue: 0.11, alpha: 0.96)
            : UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 0.96)
        }

        static let elevatedSurface = UIColor { traits in
            traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.13, green: 0.14, blue: 0.18, alpha: 1)
            : .systemBackground
        }

        static let secondarySurface = UIColor { traits in
            traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.19, blue: 0.24, alpha: 1)
            : UIColor(red: 0.91, green: 0.93, blue: 0.97, alpha: 1)
        }

        static let privateAccent = UIColor { traits in
            traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.76, green: 0.58, blue: 1, alpha: 1)
            : UIColor(red: 0.43, green: 0.24, blue: 0.72, alpha: 1)
        }

        static let privateBackground = UIColor { traits in
            traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.06, blue: 0.12, alpha: 1)
            : UIColor(red: 0.94, green: 0.91, blue: 0.98, alpha: 1)
        }

        static let separator = UIColor.separator.withAlphaComponent(0.28)
        static let shadow = UIColor.black.withAlphaComponent(0.18)
    }
}
