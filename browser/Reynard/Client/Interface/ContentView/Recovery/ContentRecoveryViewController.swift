import UIKit

final class ContentRecoveryViewController: UIViewController {
    let failureKind: ContentProcessFailureKind

    private let onRetry: () -> Void
    private let onExportDiagnostics: () -> Void

    init(
        failureKind: ContentProcessFailureKind,
        onRetry: @escaping () -> Void,
        onExportDiagnostics: @escaping () -> Void
    ) {
        self.failureKind = failureKind
        self.onRetry = onRetry
        self.onExportDiagnostics = onExportDiagnostics
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    private func configureView() {
        view.backgroundColor = .systemBackground

        let imageView = UIImageView(
            image: UIImage(systemName: failureKind == .crash ? "exclamationmark.triangle" : "arrow.clockwise.circle")
        )
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 54, weight: .regular)
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.text = failureKind == .crash
        ? NSLocalizedString("This Page Crashed", comment: "")
        : NSLocalizedString("This Page Was Closed", comment: "")

        let messageLabel = UILabel()
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.text = NSLocalizedString(
            "The tab and its address were preserved. Retry the page or export diagnostics if the problem continues.",
            comment: ""
        )

        let retryButton = UIButton(type: .system)
        retryButton.setTitle(NSLocalizedString("Retry Page", comment: ""), for: .normal)
        retryButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        retryButton.titleLabel?.adjustsFontForContentSizeCategory = true
        retryButton.backgroundColor = view.tintColor
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.layer.cornerRadius = 12
        retryButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 18, bottom: 12, right: 18)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        let diagnosticsButton = UIButton(type: .system)
        diagnosticsButton.setTitle(NSLocalizedString("Export Diagnostics", comment: ""), for: .normal)
        diagnosticsButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        diagnosticsButton.titleLabel?.adjustsFontForContentSizeCategory = true
        diagnosticsButton.backgroundColor = .secondarySystemBackground
        diagnosticsButton.layer.cornerRadius = 12
        diagnosticsButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 18, bottom: 12, right: 18)
        diagnosticsButton.addTarget(self, action: #selector(exportDiagnosticsTapped), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [retryButton, diagnosticsButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually

        let contentStack = UIStackView(arrangedSubviews: [
            imageView,
            titleLabel,
            messageLabel,
            buttonStack,
        ])
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 16
        contentStack.setCustomSpacing(28, after: imageView)
        contentStack.setCustomSpacing(28, after: messageLabel)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            contentStack.widthAnchor.constraint(lessThanOrEqualToConstant: 520),
            imageView.heightAnchor.constraint(equalToConstant: 64),
            retryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            diagnosticsButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
        ])
    }

    @objc private func retryTapped() {
        onRetry()
    }

    @objc private func exportDiagnosticsTapped() {
        onExportDiagnostics()
    }
}
