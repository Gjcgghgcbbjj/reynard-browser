import UIKit

final class StartupMigrationFailureViewController: UIViewController {
    private let retryMigration: () -> UserDataMigrationReport
    private let onRecovered: () -> Void
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let errorLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private let exportButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private var report: UserDataMigrationReport

    init(
        report: UserDataMigrationReport,
        retryMigration: @escaping () -> UserDataMigrationReport,
        onRecovered: @escaping () -> Void
    ) {
        self.report = report
        self.retryMigration = retryMigration
        self.onRecovered = onRecovered
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        updateErrorDetails()
    }

    private func configureView() {
        view.backgroundColor = .systemBackground

        let symbolView = UIImageView(
            image: UIImage(systemName: "externaldrive.badge.exclamationmark")
        )
        symbolView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: 72,
            weight: .regular
        )
        symbolView.tintColor = .systemOrange
        symbolView.contentMode = .scaleAspectFit

        titleLabel.text = NSLocalizedString("Startup Migration Failed", comment: "")
        titleLabel.font = .preferredFont(forTextStyle: .title1)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        messageLabel.text = NSLocalizedString(
            "Reynard couldn't safely move your existing browser data. The original data was kept. Retry the migration or export diagnostics.",
            comment: ""
        )
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        errorLabel.font = .monospacedSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize,
            weight: .regular
        )
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.textColor = .secondaryLabel
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0

        configureButton(
            retryButton,
            title: NSLocalizedString("Retry Migration", comment: ""),
            backgroundColor: .label,
            titleColor: .systemBackground
        )
        retryButton.addTarget(self, action: #selector(handleRetry), for: .touchUpInside)

        configureButton(
            exportButton,
            title: NSLocalizedString("Export Diagnostics", comment: ""),
            backgroundColor: .secondarySystemBackground,
            titleColor: .label
        )
        exportButton.addTarget(self, action: #selector(handleExport), for: .touchUpInside)

        activityIndicator.hidesWhenStopped = true

        let buttonStack = UIStackView(arrangedSubviews: [
            retryButton,
            exportButton,
        ])
        buttonStack.axis = .vertical
        buttonStack.spacing = 12

        let contentStack = UIStackView(arrangedSubviews: [
            symbolView,
            titleLabel,
            messageLabel,
            errorLabel,
            activityIndicator,
            buttonStack,
        ])
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 20
        contentStack.setCustomSpacing(36, after: symbolView)
        contentStack.setCustomSpacing(32, after: errorLabel)
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        let centeredContentConstraint = contentStack.centerYAnchor.constraint(
            equalTo: scrollView.frameLayoutGuide.centerYAnchor
        )
        centeredContentConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.centerXAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            contentStack.widthAnchor.constraint(lessThanOrEqualToConstant: 620),
            centeredContentConstraint,
            symbolView.heightAnchor.constraint(equalToConstant: 80),
            retryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            exportButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
        ])
    }

    private func configureButton(
        _ button: UIButton,
        title: String,
        backgroundColor: UIColor,
        titleColor: UIColor
    ) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.backgroundColor = backgroundColor
        button.setTitleColor(titleColor, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.cornerCurve = .continuous
        button.contentEdgeInsets = UIEdgeInsets(top: 14, left: 20, bottom: 14, right: 20)
    }

    private func updateErrorDetails() {
        errorLabel.text = report.blockingError?.localizedDescription
    }

    @objc private func handleRetry() {
        retryButton.isEnabled = false
        exportButton.isEnabled = false
        activityIndicator.startAnimating()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else {
                return
            }
            let report = self.retryMigration()
            DispatchQueue.main.async { [weak self] in
                guard let self else {
                    return
                }
                self.report = report
                self.activityIndicator.stopAnimating()
                if report.requiresBlockingRecovery {
                    self.updateErrorDetails()
                    self.retryButton.isEnabled = true
                    self.exportButton.isEnabled = true
                } else {
                    self.onRecovered()
                }
            }
        }
    }

    @objc private func handleExport() {
        DiagnosticsExportCoordinator.present(from: self)
    }
}
