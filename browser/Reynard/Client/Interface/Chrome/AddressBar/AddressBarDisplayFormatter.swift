import UIKit

enum AddressBarDisplayFormatter {
    static func attributedText(
        currentText: String?,
        locationText: String?,
        locationTitle: String?,
        showsFullAddress: Bool,
        canShowMenu: Bool
    ) -> NSAttributedString? {
        guard let currentText, !currentText.isEmpty else {
            return nil
        }

        guard !showsFullAddress,
              canShowMenu,
              let host = locationHost(
                currentText: currentText,
                locationText: locationText
              ) else {
            return NSAttributedString(
                string: currentText,
                attributes: [.foregroundColor: UIColor.label]
            )
        }

        let attributedText = NSMutableAttributedString(
            string: host,
            attributes: [.foregroundColor: UIColor.label]
        )
        attributedText.append(
            NSAttributedString(
                string: " / ",
                attributes: [.foregroundColor: UIColor.secondaryLabel]
            )
        )
        if let locationTitle, !locationTitle.isEmpty {
            attributedText.append(
                NSAttributedString(
                    string: locationTitle,
                    attributes: [.foregroundColor: UIColor.secondaryLabel]
                )
            )
        }
        return attributedText
    }

    private static func locationHost(
        currentText: String,
        locationText: String?
    ) -> String? {
        let sourceText = locationText ?? currentText
        guard let host = URL(string: sourceText)?.host,
              !host.isEmpty else {
            return nil
        }
        return host
    }
}
