import UIKit
import UniformTypeIdentifiers

final class UserScriptsViewController: SettingsTableViewController, UIDocumentPickerDelegate {
    init() { super.init(style: .insetGrouped); title = NSLocalizedString("User Scripts", comment: ""); navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addScript)) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); tableView.reloadData() }
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { Prefs.FeatureSettings.userScripts.count }
    override func sectionText(for section: Int) -> SettingsSectionText { SettingsSectionText(footerTitle: NSLocalizedString("Scripts execute only through Gecko WebExtension userScripts and require explicit site scopes.", comment: "")) }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let script = Prefs.FeatureSettings.userScripts[safe: indexPath.row] else { return UITableViewCell() }
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil); BrowserListStyle.apply(to: cell)
        cell.textLabel?.text = script.name; cell.detailTextLabel?.text = script.matches.joined(separator: ", ")
        let control = UISwitch(); control.isOn = script.isEnabled; control.tag = indexPath.row; control.addTarget(self, action: #selector(toggle(_:)), for: .valueChanged)
        cell.accessoryView = control; return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        guard let script = Prefs.FeatureSettings.userScripts[safe: indexPath.row] else { return }
        navigationController?.pushViewController(UserScriptEditorViewController(script: script), animated: true)
    }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }; var scripts = Prefs.FeatureSettings.userScripts
        guard scripts.indices.contains(indexPath.row) else { return }; scripts.remove(at: indexPath.row); Prefs.FeatureSettings.userScripts = scripts; tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    @objc private func toggle(_ sender: UISwitch) { var scripts = Prefs.FeatureSettings.userScripts; guard scripts.indices.contains(sender.tag) else { return }; scripts[sender.tag].isEnabled = sender.isOn; Prefs.FeatureSettings.userScripts = scripts }
    @objc private func addScript() {
        let alert = UIAlertController(title: NSLocalizedString("Add User Script", comment: ""), message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: NSLocalizedString("New Script", comment: ""), style: .default) { [weak self] _ in self?.navigationController?.pushViewController(UserScriptEditorViewController(script: nil), animated: true) })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Import File", comment: ""), style: .default) { [weak self] _ in let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.javaScript, .plainText]); picker.delegate = self; self?.present(picker, animated: true) })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)); if let p = alert.popoverPresentationController { p.barButtonItem = navigationItem.rightBarButtonItem }; present(alert, animated: true)
    }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }; let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
        do { let script = try UserScriptParser.parse(String(contentsOf: url)); var scripts = Prefs.FeatureSettings.userScripts; scripts.removeAll { $0.name == script.name && $0.namespace == script.namespace }; scripts.append(script); Prefs.FeatureSettings.userScripts = scripts; tableView.reloadData() }
        catch { let alert = UIAlertController(title: NSLocalizedString("Invalid User Script", comment: ""), message: String(describing: error), preferredStyle: .alert); alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default)); present(alert, animated: true) }
    }
}

private final class UserScriptEditorViewController: UIViewController {
    private var script: BrowserUserScript?; private let textView = UITextView()
    init(script: BrowserUserScript?) { self.script = script; super.init(nibName: nil, bundle: nil); title = script?.name ?? NSLocalizedString("New User Script", comment: "") }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() { super.viewDidLoad(); view.backgroundColor = BrowserDesignTokens.Color.chromeBackground; textView.translatesAutoresizingMaskIntoConstraints = false; textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular); textView.autocorrectionType = .no; textView.text = script?.source ?? "// ==UserScript==\n// @name New Script\n// @match https://example.com/*\n// @grant none\n// ==/UserScript==\n"; view.addSubview(textView); NSLayoutConstraint.activate([textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), textView.leadingAnchor.constraint(equalTo: view.leadingAnchor), textView.trailingAnchor.constraint(equalTo: view.trailingAnchor), textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)]); navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save)) }
    @objc private func save() { do { var parsed = try UserScriptParser.parse(textView.text); if let old = script { parsed = BrowserUserScript(id: old.id, name: parsed.name, namespace: parsed.namespace, version: parsed.version, matches: parsed.matches, grants: parsed.grants, source: parsed.source, isEnabled: old.isEnabled, allowsPrivateBrowsing: old.allowsPrivateBrowsing) }; var scripts = Prefs.FeatureSettings.userScripts; if let index = scripts.firstIndex(where: { $0.id == parsed.id }) { scripts[index] = parsed } else { scripts.append(parsed) }; Prefs.FeatureSettings.userScripts = scripts; navigationController?.popViewController(animated: true) } catch { let alert = UIAlertController(title: NSLocalizedString("Invalid User Script", comment: ""), message: String(describing: error), preferredStyle: .alert); alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default)); present(alert, animated: true) } }
}
