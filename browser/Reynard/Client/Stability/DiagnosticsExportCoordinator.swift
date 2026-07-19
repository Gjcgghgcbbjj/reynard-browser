import UIKit

enum DiagnosticsExportCoordinator {
    static func present(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: NSLocalizedString("Export Diagnostics", comment: ""),
            message: NSLocalizedString(
                "Website URLs are excluded by default. You can include URLs recorded during this app session if needed for debugging.",
                comment: ""
            ),
            preferredStyle: .actionSheet
        )
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString("Export Without URLs", comment: ""),
                style: .default
            ) { _ in
                export(includeFullURLs: false, from: viewController)
            }
        )
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString("Include Current-Session URLs", comment: ""),
                style: .default
            ) { _ in
                export(includeFullURLs: true, from: viewController)
            }
        )
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString("Cancel", comment: ""),
                style: .cancel
            )
        )

        if let popover = alert.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.maxY,
                width: 1,
                height: 1
            )
        }
        viewController.present(alert, animated: true)
    }

    private static func export(includeFullURLs: Bool, from viewController: UIViewController) {
        do {
            let data = try StabilityDiagnostics.shared.exportData(includeFullURLs: includeFullURLs)
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyyMMdd-HHmmss"
            let filename = "reynard-diagnostics-\(formatter.string(from: Date())).json"
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: fileURL, options: .atomic)

            let activityController = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            activityController.completionWithItemsHandler = { _, _, _, _ in
                try? FileManager.default.removeItem(at: fileURL)
            }
            if let popover = activityController.popoverPresentationController {
                popover.sourceView = viewController.view
                popover.sourceRect = CGRect(
                    x: viewController.view.bounds.midX,
                    y: viewController.view.bounds.midY,
                    width: 1,
                    height: 1
                )
            }
            viewController.present(activityController, animated: true)
        } catch {
            let alert = UIAlertController(
                title: NSLocalizedString("Unable to Export Diagnostics", comment: ""),
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(
                UIAlertAction(
                    title: NSLocalizedString("OK", comment: ""),
                    style: .default
                )
            )
            viewController.present(alert, animated: true)
        }
    }
}
