import GeckoView
import UIKit
import UniformTypeIdentifiers

final class ViaFeaturesPreferencesViewController: SettingsTableViewController, UIDocumentPickerDelegate {
    private enum Section: CaseIterable { case display, blocking, privacy, tools }
    private enum Row {
        case nightMode, contentBlocking, cookies, trackingProtection, clearOnExit, userScripts, exportBackup, importBackup
    }
    private var capabilityMessage: String?

    private var rows: [[Row]] {
        [
            [.nightMode],
            [.contentBlocking],
            [.cookies, .trackingProtection, .clearOnExit],
            [.userScripts, .exportBackup, .importBackup],
        ]
    }

    init() {
        super.init(style: .insetGrouped)
        title = NSLocalizedString("Web Features", comment: "")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        refreshCapabilities()
    }

    override func numberOfSections(in tableView: UITableView) -> Int { rows.count }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows[safe: section]?.count ?? 0 }

    override func sectionText(for section: Int) -> SettingsSectionText {
        let titles = ["Display", "Blocking", "Privacy", "Portability"]
        return SettingsSectionText(
            headerTitle: titles[safe: section].map { NSLocalizedString($0, comment: "") },
            footerTitle: section == 0 ? capabilityMessage : nil
        )
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = rows[safe: indexPath.section]?[safe: indexPath.row] else { return UITableViewCell() }
        switch row {
        case .nightMode:
            return valueCell(title: NSLocalizedString("Night Mode", comment: ""), value: title(for: Prefs.FeatureSettings.nightMode))
        case .contentBlocking:
            return valueCell(title: NSLocalizedString("Content Blocking", comment: ""), value: title(for: Prefs.FeatureSettings.blockingMode))
        case .cookies:
            return valueCell(title: NSLocalizedString("Third-Party Cookies", comment: ""), value: title(for: Prefs.FeatureSettings.thirdPartyCookiePolicy))
        case .trackingProtection:
            return switchCell(title: NSLocalizedString("Tracking Protection", comment: ""), isOn: Prefs.FeatureSettings.trackingProtection, action: #selector(trackingChanged(_:)))
        case .clearOnExit:
            return switchCell(title: NSLocalizedString("Clear Site Data on Exit", comment: ""), isOn: Prefs.FeatureSettings.clearSiteDataOnExit, action: #selector(clearOnExitChanged(_:)))
        case .userScripts:
            let cell = valueCell(title: NSLocalizedString("User Scripts", comment: ""), value: "\(Prefs.FeatureSettings.userScripts.count)")
            return cell
        case .exportBackup:
            return SettingsViewUtils.actionCell(title: NSLocalizedString("Export Backup", comment: ""), tintColor: view.tintColor)
        case .importBackup:
            return SettingsViewUtils.actionCell(title: NSLocalizedString("Import Backup", comment: ""), tintColor: view.tintColor)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        guard let row = rows[safe: indexPath.section]?[safe: indexPath.row] else { return }
        switch row {
        case .nightMode: presentNightModePicker()
        case .contentBlocking: navigationController?.pushViewController(ContentBlockingPreferencesViewController(), animated: true)
        case .cookies: presentCookiePicker()
        case .userScripts: navigationController?.pushViewController(UserScriptsViewController(), animated: true)
        case .exportBackup: exportBackup()
        case .importBackup: importBackup()
        case .trackingProtection, .clearOnExit: break
        }
    }

    @objc private func trackingChanged(_ sender: UISwitch) { Prefs.FeatureSettings.trackingProtection = sender.isOn }
    @objc private func clearOnExitChanged(_ sender: UISwitch) { Prefs.FeatureSettings.clearSiteDataOnExit = sender.isOn }

    private func presentNightModePicker() {
        presentPicker(title: NSLocalizedString("Night Mode", comment: ""), values: BrowserNightMode.allCases, current: Prefs.FeatureSettings.nightMode, title: { [weak self] in self?.title(for: $0) ?? $0.rawValue }) { Prefs.FeatureSettings.nightMode = $0 }
    }

    private func presentCookiePicker() {
        presentPicker(title: NSLocalizedString("Third-Party Cookies", comment: ""), values: ThirdPartyCookiePolicy.allCases, current: Prefs.FeatureSettings.thirdPartyCookiePolicy, title: { [weak self] in self?.title(for: $0) ?? $0.rawValue }) { Prefs.FeatureSettings.thirdPartyCookiePolicy = $0 }
    }

    private func presentPicker<T: Equatable>(title: String, values: [T], current: T, title valueTitle: @escaping (T) -> String, select: @escaping (T) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        values.forEach { value in
            alert.addAction(UIAlertAction(title: valueTitle(value), style: .default) { [weak self] _ in
                select(value)
                self?.tableView.reloadData()
            })
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        if let popover = alert.popoverPresentationController { popover.sourceView = view; popover.sourceRect = view.bounds }
        present(alert, animated: true)
    }

    private func valueCell(title: String, value: String) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        BrowserListStyle.apply(to: cell)
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = value
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    private func switchCell(title: String, isOn: Bool, action: Selector) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        BrowserListStyle.apply(to: cell)
        cell.textLabel?.text = title
        let control = UISwitch()
        control.isOn = isOn
        control.addTarget(self, action: action, for: .valueChanged)
        cell.accessoryView = control
        cell.selectionStyle = .none
        return cell
    }

    private func exportBackup() {
        do {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("Reynard-Backup-\(Int(Date().timeIntervalSince1970)).json")
            try PortableBackupService.exportData().write(to: url, options: .atomic)
            present(UIDocumentPickerViewController(forExporting: [url]), animated: true)
        } catch { presentError(error) }
    }

    private func importBackup() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.delegate = self
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            try PortableBackupService.restore(Data(contentsOf: url))
            tableView.reloadData()
        } catch { presentError(error) }
    }

    private func presentError(_ error: Error) {
        let alert = UIAlertController(title: NSLocalizedString("Backup Failed", comment: ""), message: String(describing: error), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
        present(alert, animated: true)
    }

    private func refreshCapabilities() {
        guard let browser = LibrarySharedUtils.resolvedBrowserViewController(from: self),
              let session = browser.tabManager.selectedTab?.session else {
            capabilityMessage = NSLocalizedString("Open a webpage to check Gecko feature support.", comment: "")
            tableView.reloadSections(IndexSet(integer: 0), with: .none)
            return
        }
        Task { @MainActor [weak self] in
            let capabilities = await session.features.capabilities()
            let missing = Set(GeckoFeatureCapability.allCases).subtracting(capabilities.supported)
            self?.capabilityMessage = missing.isEmpty
            ? NSLocalizedString("All Gecko web features are available.", comment: "")
            : String(format: NSLocalizedString("Unavailable in this Gecko build: %@", comment: ""), missing.map(\.rawValue).sorted().joined(separator: ", "))
            self?.tableView.reloadSections(IndexSet(integer: 0), with: .none)
        }
    }

    private func title(for mode: BrowserNightMode) -> String {
        switch mode { case .off: return NSLocalizedString("Off", comment: ""); case .automatic: return NSLocalizedString("Automatic", comment: ""); case .on: return NSLocalizedString("On", comment: "") }
    }

    private func title(for mode: BrowserBlockingMode) -> String {
        switch mode { case .off: return NSLocalizedString("Off", comment: ""); case .balanced: return NSLocalizedString("Balanced", comment: ""); case .strict: return NSLocalizedString("Strict", comment: "") }
    }

    private func title(for policy: ThirdPartyCookiePolicy) -> String {
        switch policy { case .allow: return NSLocalizedString("Allow", comment: ""); case .blockTrackers: return NSLocalizedString("Block Trackers", comment: ""); case .blockAll: return NSLocalizedString("Block All", comment: "") }
    }
}
