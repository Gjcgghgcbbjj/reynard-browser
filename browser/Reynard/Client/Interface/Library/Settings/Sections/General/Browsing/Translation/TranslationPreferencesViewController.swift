import UIKit

extension TranslationProvider {
    var displayName: String {
        switch self {
        case .google:
            return "Google"
        case .custom:
            return NSLocalizedString("Custom", comment: "Translation provider option")
        }
    }
}

final class TranslationPreferencesViewController: SettingsTableViewController, UITextFieldDelegate {
    private enum Section: CaseIterable {
        case provider

        var text: SettingsSectionText {
            SettingsSectionText(
                headerTitle: NSLocalizedString("Translation Provider", comment: ""),
                footerTitle: NSLocalizedString(
                    "Custom translation URLs must use HTTP or HTTPS and include {url}. The optional {lang} placeholder uses your preferred language.",
                    comment: "Literal {url} and {lang} placeholders"
                )
            )
        }
    }

    init() {
        super.init(style: .insetGrouped)
        title = NSLocalizedString("Webpage Translation", comment: "")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(
            CustomSearchTemplateCell.self,
            forCellReuseIdentifier: "CustomTranslationTemplateCell"
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        normalizeSelectedProvider()
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        TranslationProvider.allCases.count
    }

    override func sectionText(for section: Int) -> SettingsSectionText {
        guard Section.allCases.indices.contains(section) else {
            return SettingsSectionText()
        }
        return Section.allCases[section].text
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard TranslationProvider.allCases.indices.contains(indexPath.row) else {
            return UITableViewCell()
        }

        let provider = TranslationProvider.allCases[indexPath.row]
        switch provider {
        case .google:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = provider.displayName
            cell.accessoryType = selectedProvider == provider ? .checkmark : .none
            return cell

        case .custom:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "CustomTranslationTemplateCell",
                for: indexPath
            ) as? CustomSearchTemplateCell else {
                return UITableViewCell()
            }
            cell.textField.delegate = self
            cell.textField.placeholder = NSLocalizedString("Custom Translation URL", comment: "")
            cell.textField.text = Prefs.BrowsingSettings.customTranslationTemplate
            cell.accessoryType = selectedProvider == .custom ? .checkmark : .none
            return cell
        }
    }

    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        guard TranslationProvider.allCases.indices.contains(indexPath.row) else {
            return
        }

        switch TranslationProvider.allCases[indexPath.row] {
        case .google:
            Prefs.BrowsingSettings.translationProvider = .google
            tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
        case .custom:
            if TranslationProvider.isValidCustomTemplate(
                Prefs.BrowsingSettings.customTranslationTemplate
            ) {
                Prefs.BrowsingSettings.translationProvider = .custom
                tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
            } else {
                focusCustomTemplateField()
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        saveCustomTemplate(from: textField, resignOnSuccess: true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        _ = saveCustomTemplate(from: textField, resignOnSuccess: false)
    }

    private func saveCustomTemplate(
        from textField: UITextField,
        resignOnSuccess: Bool
    ) -> Bool {
        let template = (textField.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !template.isEmpty else {
            Prefs.BrowsingSettings.customTranslationTemplate = ""
            Prefs.BrowsingSettings.translationProvider = .google
            tableView.reloadSections(IndexSet(integer: 0), with: .none)
            if resignOnSuccess {
                textField.resignFirstResponder()
            }
            return true
        }

        guard TranslationProvider.isValidCustomTemplate(template) else {
            Prefs.BrowsingSettings.customTranslationTemplate = template
            Prefs.BrowsingSettings.translationProvider = .google
            presentInvalidTemplateAlert()
            tableView.reloadSections(IndexSet(integer: 0), with: .none)
            return false
        }

        Prefs.BrowsingSettings.customTranslationTemplate = template
        Prefs.BrowsingSettings.translationProvider = .custom
        textField.text = template
        if resignOnSuccess {
            textField.resignFirstResponder()
        }
        tableView.reloadSections(IndexSet(integer: 0), with: .none)
        return true
    }

    private func normalizeSelectedProvider() {
        if Prefs.BrowsingSettings.translationProvider == .custom,
           !TranslationProvider.isValidCustomTemplate(
            Prefs.BrowsingSettings.customTranslationTemplate
           ) {
            Prefs.BrowsingSettings.translationProvider = .google
        }
    }

    private func focusCustomTemplateField() {
        guard let row = TranslationProvider.allCases.firstIndex(of: .custom),
              let cell = tableView.cellForRow(
                at: IndexPath(row: row, section: 0)
              ) as? CustomSearchTemplateCell else {
            return
        }
        cell.textField.becomeFirstResponder()
    }

    private func presentInvalidTemplateAlert() {
        guard presentedViewController == nil else {
            return
        }
        let alert = UIAlertController(
            title: NSLocalizedString("Invalid Translation Template", comment: ""),
            message: NSLocalizedString(
                "The custom translation URL must use HTTP or HTTPS and include {url}.",
                comment: "Literal {url} placeholder"
            ),
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default)
        )
        present(alert, animated: true)
    }

    private var selectedProvider: TranslationProvider {
        guard Prefs.BrowsingSettings.translationProvider == .custom else {
            return Prefs.BrowsingSettings.translationProvider
        }
        return TranslationProvider.isValidCustomTemplate(
            Prefs.BrowsingSettings.customTranslationTemplate
        ) ? .custom : .google
    }
}
