import UIKit

final class HomepagePreferencesViewController: SettingsTableViewController {
    private enum Section: CaseIterable {
        case openingScreen
        case moduleOrder
        case includeOnHomepage

        var text: SettingsSectionText {
            switch self {
            case .openingScreen:
                return SettingsSectionText(headerTitle: NSLocalizedString("On Startup", comment: ""))
            case .moduleOrder:
                return SettingsSectionText(
                    headerTitle: NSLocalizedString("Module Order", comment: ""),
                    footerTitle: NSLocalizedString("Search remains available in the browser chrome. Drag modules to reorder the homepage.", comment: "")
                )
            case .includeOnHomepage:
                return SettingsSectionText(headerTitle: NSLocalizedString("Homepage Sections", comment: ""))
            }
        }
    }

    private var reorderableModules: [BrowserHomepageModule] {
        Prefs.HomepageSettings.moduleOrder.filter { $0 != .search }
    }

    init() {
        super.init(style: .insetGrouped)
        title = NSLocalizedString("Homepage", comment: "")
        navigationItem.rightBarButtonItem = editButtonItem
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard Section.allCases.indices.contains(section) else { return 0 }
        switch Section.allCases[section] {
        case .openingScreen:
            return HomepageOpeningScreen.allCases.count
        case .moduleOrder:
            return reorderableModules.count
        case .includeOnHomepage:
            return HomepageSectionPreferencesViewController.OverviewRow.allCases.count
        }
    }

    override func sectionText(for section: Int) -> SettingsSectionText {
        guard Section.allCases.indices.contains(section) else { return SettingsSectionText() }
        return Section.allCases[section].text
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        Section.allCases[safe: indexPath.section] == .moduleOrder
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        Section.allCases[safe: indexPath.section] == .moduleOrder
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        false
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard sourceIndexPath.section == destinationIndexPath.section,
              Section.allCases[safe: sourceIndexPath.section] == .moduleOrder else {
            tableView.reloadData()
            return
        }
        var modules = reorderableModules
        guard modules.indices.contains(sourceIndexPath.row) else { return }
        let module = modules.remove(at: sourceIndexPath.row)
        modules.insert(module, at: min(destinationIndexPath.row, modules.count))
        Prefs.HomepageSettings.moduleOrder = [.search] + modules
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section.allCases[safe: indexPath.section] else { return UITableViewCell() }
        switch section {
        case .openingScreen:
            guard let openingScreen = HomepageOpeningScreen.allCases[safe: indexPath.row] else { return UITableViewCell() }
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = openingScreen.title
            cell.accessoryType = Prefs.HomepageSettings.openingScreen == openingScreen ? .checkmark : .none
            return cell
        case .moduleOrder:
            guard let module = reorderableModules[safe: indexPath.row] else { return UITableViewCell() }
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = module.title
            cell.imageView?.image = UIImage(named: module.symbolName)
            cell.showsReorderControl = true
            return cell
        case .includeOnHomepage:
            guard let row = HomepageSectionPreferencesViewController.OverviewRow.allCases[safe: indexPath.row] else { return UITableViewCell() }
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = row.title
            cell.detailTextLabel?.text = row.isEnabled ? NSLocalizedString("On", comment: "Enabled state") : NSLocalizedString("Off", comment: "Disabled state")
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        guard let section = Section.allCases[safe: indexPath.section] else { return }
        switch section {
        case .openingScreen:
            guard let openingScreen = HomepageOpeningScreen.allCases[safe: indexPath.row] else { return }
            Prefs.HomepageSettings.openingScreen = openingScreen
            tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
        case .moduleOrder:
            setEditing(true, animated: true)
        case .includeOnHomepage:
            guard let row = HomepageSectionPreferencesViewController.OverviewRow.allCases[safe: indexPath.row] else { return }
            navigationController?.pushViewController(HomepageSectionPreferencesViewController(preference: row.preference), animated: true)
        }
    }
}

private extension BrowserHomepageModule {
    var title: String {
        switch self {
        case .search: return NSLocalizedString("Search", comment: "")
        case .favorites: return NSLocalizedString("Favorites", comment: "")
        case .frequentlyVisited: return NSLocalizedString("Frequently Visited", comment: "")
        case .recentTabs: return NSLocalizedString("Recently Closed Tabs", comment: "")
        }
    }

    var symbolName: String {
        switch self {
        case .search: return "reynard.magnifyingglass"
        case .favorites: return "reynard.star"
        case .frequentlyVisited: return "reynard.globe"
        case .recentTabs: return "reynard.clock"
        }
    }
}
