import UIKit

enum BrowserMaterialStyle {
    enum Surface {
        case chrome
        case elevated
        case secondary
        case privateMode
    }

    enum Elevation {
        case none
        case low
        case high
    }

    static func apply(
        surface: Surface,
        elevation: Elevation,
        cornerRadius: CGFloat,
        to view: UIView
    ) {
        view.backgroundColor = backgroundColor(for: surface)
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = cornerRadius
        apply(elevation: elevation, to: view.layer)
    }

    static func apply(elevation: Elevation, to layer: CALayer) {
        layer.shadowColor = BrowserDesignTokens.Color.shadow.cgColor
        layer.shadowOffset = CGSize(width: 0, height: elevation == .high ? 6 : 2)
        layer.shadowRadius = elevation == .high ? 16 : 8

        switch elevation {
        case .none:
            layer.shadowOpacity = 0
        case .low:
            layer.shadowOpacity = 0.12
        case .high:
            layer.shadowOpacity = 0.20
        }
    }

    static func updateShadowPath(for view: UIView) {
        guard view.layer.shadowOpacity > 0 else {
            view.layer.shadowPath = nil
            return
        }
        view.layer.shadowPath = UIBezierPath(
            roundedRect: view.bounds,
            cornerRadius: view.layer.cornerRadius
        ).cgPath
    }

    private static func backgroundColor(for surface: Surface) -> UIColor {
        switch surface {
        case .chrome:
            return BrowserDesignTokens.Color.chromeBackground
        case .elevated:
            return BrowserDesignTokens.Color.elevatedSurface
        case .secondary:
            return BrowserDesignTokens.Color.secondarySurface
        case .privateMode:
            return BrowserDesignTokens.Color.privateBackground
        }
    }
}
