import GeckoView
import UIKit

final class FindInPageActionBar: UIView, UITextFieldDelegate {
    var onQueryChanged: ((String) -> Void)?
    var onPrevious: (() -> Void)?
    var onNext: (() -> Void)?
    var onClose: (() -> Void)?

    private let searchField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = NSLocalizedString("Find in Page", comment: "")
        field.clearButtonMode = .whileEditing
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.returnKeyType = .search
        field.font = BrowserDesignTokens.Typography.address
        return field
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.text = "0 / 0"
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var previousButton = makeButton(
        symbol: "reynard.chevron.backward",
        label: NSLocalizedString("Previous Match", comment: ""),
        action: #selector(previousTapped)
    )
    private lazy var nextButton = makeButton(
        symbol: "reynard.chevron.forward",
        label: NSLocalizedString("Next Match", comment: ""),
        action: #selector(nextTapped)
    )
    private lazy var closeButton = makeButton(
        symbol: "reynard.xmark",
        label: NSLocalizedString("Close", comment: ""),
        action: #selector(closeTapped)
    )

    private let surface = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        configureHierarchy()
        configureConstraints()
        searchField.delegate = self
        searchField.addTarget(self, action: #selector(queryChanged), for: .editingChanged)
        updateResult(nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        BrowserMaterialStyle.updateShadowPath(for: surface)
    }

    var isSearchFocused: Bool {
        searchField.isFirstResponder
    }

    func focus() {
        searchField.becomeFirstResponder()
    }

    func endSearchEditing() {
        searchField.resignFirstResponder()
    }

    func updateResult(_ result: FindInPageResult?) {
        guard let result, result.total > 0 else {
            countLabel.text = "0 / 0"
            previousButton.isEnabled = false
            nextButton.isEnabled = false
            return
        }
        countLabel.text = "\(result.current) / \(result.total)"
        previousButton.isEnabled = result.found
        nextButton.isEnabled = result.found
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onNext?()
        return true
    }

    @objc private func queryChanged() {
        onQueryChanged?(searchField.text ?? "")
    }

    @objc private func previousTapped() { onPrevious?() }
    @objc private func nextTapped() { onNext?() }
    @objc private func closeTapped() { onClose?() }

    private func configureHierarchy() {
        surface.translatesAutoresizingMaskIntoConstraints = false
        BrowserMaterialStyle.apply(
            surface: .elevated,
            elevation: .low,
            cornerRadius: BrowserDesignTokens.Radius.chrome,
            to: surface
        )
        addSubview(surface)
        [searchField, countLabel, previousButton, nextButton, closeButton].forEach {
            surface.addSubview($0)
        }
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: ActionBar.height),
            surface.leadingAnchor.constraint(equalTo: leadingAnchor, constant: BrowserDesignTokens.Spacing.medium),
            surface.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -BrowserDesignTokens.Spacing.medium),
            surface.topAnchor.constraint(equalTo: topAnchor, constant: BrowserDesignTokens.Spacing.small),
            surface.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -BrowserDesignTokens.Spacing.small),

            searchField.leadingAnchor.constraint(equalTo: surface.leadingAnchor, constant: BrowserDesignTokens.Spacing.medium),
            searchField.centerYAnchor.constraint(equalTo: surface.centerYAnchor),

            countLabel.leadingAnchor.constraint(greaterThanOrEqualTo: searchField.trailingAnchor, constant: BrowserDesignTokens.Spacing.small),
            countLabel.centerYAnchor.constraint(equalTo: surface.centerYAnchor),
            countLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 42),

            previousButton.leadingAnchor.constraint(equalTo: countLabel.trailingAnchor, constant: BrowserDesignTokens.Spacing.extraSmall),
            previousButton.centerYAnchor.constraint(equalTo: surface.centerYAnchor),
            previousButton.widthAnchor.constraint(equalToConstant: BrowserDesignTokens.Control.compactHeight),
            previousButton.heightAnchor.constraint(equalToConstant: BrowserDesignTokens.Control.compactHeight),

            nextButton.leadingAnchor.constraint(equalTo: previousButton.trailingAnchor),
            nextButton.centerYAnchor.constraint(equalTo: surface.centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: BrowserDesignTokens.Control.compactHeight),
            nextButton.heightAnchor.constraint(equalToConstant: BrowserDesignTokens.Control.compactHeight),

            closeButton.leadingAnchor.constraint(equalTo: nextButton.trailingAnchor),
            closeButton.trailingAnchor.constraint(equalTo: surface.trailingAnchor, constant: -BrowserDesignTokens.Spacing.extraSmall),
            closeButton.centerYAnchor.constraint(equalTo: surface.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: BrowserDesignTokens.Control.compactHeight),
            closeButton.heightAnchor.constraint(equalToConstant: BrowserDesignTokens.Control.compactHeight),
        ])
    }

    private func makeButton(
        symbol: String,
        label: String,
        action: Selector
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: symbol), for: .normal)
        button.tintColor = .label
        button.accessibilityLabel = label
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
}
