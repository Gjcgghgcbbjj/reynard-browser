import UIKit

final class ContentBlockingPreferencesViewController: SettingsTableViewController {
    init() {
        super.init(style: .insetGrouped)
        title = NSLocalizedString("Content Blocking", comment: "")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); tableView.reloadData() }
    override func numberOfSections(in tableView: UITableView) -> Int { 3 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section { case 0: return BrowserBlockingMode.allCases.count; case 1: return Prefs.FeatureSettings.subscriptions.count; default: return 1 }
    }
    override func sectionText(for section: Int) -> SettingsSectionText {
        ["Mode", "Filter Subscriptions", "Custom Rules"][safe: section].map { SettingsSectionText(headerTitle: NSLocalizedString($0, comment: "")) } ?? SettingsSectionText()
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0, let mode = BrowserBlockingMode.allCases[safe: indexPath.row] {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil); BrowserListStyle.apply(to: cell)
            cell.textLabel?.text = mode.rawValue.capitalized
            cell.accessoryType = Prefs.FeatureSettings.blockingMode == mode ? .checkmark : .none
            return cell
        }
        if indexPath.section == 1, let subscription = Prefs.FeatureSettings.subscriptions[safe: indexPath.row] {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil); BrowserListStyle.apply(to: cell)
            cell.textLabel?.text = subscription.name
            cell.detailTextLabel?.text = subscription.lastError ?? subscription.sourceURL.host
            let control = UISwitch(); control.isOn = subscription.isEnabled; control.tag = indexPath.row; control.addTarget(self, action: #selector(subscriptionChanged(_:)), for: .valueChanged)
            cell.accessoryView = control; cell.selectionStyle = .none
            return cell
        }
        let cell = SettingsViewUtils.disclosureCell(title: NSLocalizedString("Edit Custom Rules", comment: ""))
        cell.detailTextLabel?.text = "\(Prefs.FeatureSettings.customRules.count)"
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        if indexPath.section == 0, let mode = BrowserBlockingMode.allCases[safe: indexPath.row] { Prefs.FeatureSettings.blockingMode = mode; tableView.reloadSections(IndexSet(integer: 0), with: .none) }
        if indexPath.section == 2 { navigationController?.pushViewController(CustomRulesViewController(), animated: true) }
    }
    @objc private func subscriptionChanged(_ sender: UISwitch) {
        var values = Prefs.FeatureSettings.subscriptions
        guard values.indices.contains(sender.tag) else { return }
        values[sender.tag].isEnabled = sender.isOn
        Prefs.FeatureSettings.subscriptions = values
    }
}

private final class CustomRulesViewController: UIViewController {
    private let textView = UITextView()
    override func viewDidLoad() {
        super.viewDidLoad(); title = NSLocalizedString("Custom Rules", comment: "")
        view.backgroundColor = BrowserDesignTokens.Color.chromeBackground
        textView.translatesAutoresizingMaskIntoConstraints = false; textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.text = Prefs.FeatureSettings.customRules.joined(separator: "\n")
        view.addSubview(textView)
        NSLayoutConstraint.activate([textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), textView.leadingAnchor.constraint(equalTo: view.leadingAnchor), textView.trailingAnchor.constraint(equalTo: view.trailingAnchor), textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
    }
    @objc private func save() { Prefs.FeatureSettings.customRules = textView.text.components(separatedBy: .newlines); navigationController?.popViewController(animated: true) }
}
