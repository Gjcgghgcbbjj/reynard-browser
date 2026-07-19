import UIKit

final class ToolbarPreferencesViewController: SettingsTableViewController {
    private var enabledActions = Prefs.AppearanceSettings.toolbarActions

    private var displayedActions: [BrowserToolbarAction] {
        enabledActions + BrowserToolbarAction.allCases.filter {
            !enabledActions.contains($0)
        }
    }

    init() {
        super.init(style: .insetGrouped)
        title = NSLocalizedString("Customize Toolbar", comment: "")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsSelectionDuringEditing = true
        setEditing(true, animated: false)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        displayedActions.count
    }

    override func sectionText(for section: Int) -> SettingsSectionText {
        SettingsSectionText(
            footerTitle: NSLocalizedString(
                "Toolbar keeps Back, Tabs, and Menu available so navigation and recovery remain reachable.",
                comment: ""
            )
        )
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard displayedActions.indices.contains(indexPath.row) else {
            return UITableViewCell()
        }

        let action = displayedActions[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = action.localizedTitle
        cell.imageView?.image = UIImage(named: action.symbolName)
        cell.imageView?.tintColor = .label
        cell.accessoryType = enabledActions.contains(action) ? .checkmark : .none
        cell.detailTextLabel?.text = BrowserToolbarAction.requiredActions.contains(action)
        ? NSLocalizedString("Required", comment: "Toolbar action")
        : nil
        cell.detailTextLabel?.textColor = .secondaryLabel
        return cell
    }

    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        guard displayedActions.indices.contains(indexPath.row) else {
            return
        }

        let action = displayedActions[indexPath.row]
        guard !BrowserToolbarAction.requiredActions.contains(action) else {
            return
        }

        if let enabledIndex = enabledActions.firstIndex(of: action) {
            enabledActions.remove(at: enabledIndex)
        } else {
            enabledActions.append(action)
        }
        persistAndReload()
    }

    override func tableView(
        _ tableView: UITableView,
        canMoveRowAt indexPath: IndexPath
    ) -> Bool {
        displayedActions.indices.contains(indexPath.row) &&
        enabledActions.contains(displayedActions[indexPath.row])
    }

    override func tableView(
        _ tableView: UITableView,
        editingStyleForRowAt indexPath: IndexPath
    ) -> UITableViewCell.EditingStyle {
        .none
    }

    override func tableView(
        _ tableView: UITableView,
        shouldIndentWhileEditingRowAt indexPath: IndexPath
    ) -> Bool {
        false
    }

    override func tableView(
        _ tableView: UITableView,
        moveRowAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath
    ) {
        guard enabledActions.indices.contains(sourceIndexPath.row) else {
            tableView.reloadData()
            return
        }

        let action = enabledActions.remove(at: sourceIndexPath.row)
        let destination = min(destinationIndexPath.row, enabledActions.count)
        enabledActions.insert(action, at: destination)
        persistAndReload()
    }

    private func persistAndReload() {
        enabledActions = ToolbarActionPolicy.sanitize(
            enabledActions,
            maximumVisibleActions: 6
        )
        Prefs.AppearanceSettings.toolbarActions = enabledActions
        tableView.reloadData()
    }
}
