import UIKit

final class SidebarTabListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    private static let tabsSection = "tabs"
    private weak var tabsDataSource: TabOverviewDataSource?
    private var mode: TabOverview.Mode = .regularTabs
    private var dataSource: UICollectionViewDiffableDataSource<String, UUID>!

    private lazy var modeControl: UISegmentedControl = {
        let control = UISegmentedControl(items: [
            NSLocalizedString("Private", comment: ""),
            NSLocalizedString("Tabs", comment: ""),
        ])
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = mode.rawValue
        control.selectedSegmentTintColor = BrowserDesignTokens.Color.elevatedSurface
        control.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        return control
    }()

    private lazy var collectionView: UICollectionView = {
        let configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.delegate = self
        view.dragDelegate = self
        view.dropDelegate = self
        view.dragInteractionEnabled = true
        view.keyboardDismissMode = .interactive
        return view
    }()

    init(dataSource: TabOverviewDataSource) {
        tabsDataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureDataSource()
        refresh(animated: false)
    }

    func refresh(animated: Bool = true) {
        guard isViewLoaded else { return }
        let tabs = currentTabs
        let selectedID = selectedTabID
        var snapshot = NSDiffableDataSourceSnapshot<String, UUID>()
        snapshot.appendSections([Self.tabsSection])
        snapshot.appendItems(tabs.map(\.id))
        dataSource.apply(snapshot, animatingDifferences: animated)
        if let selectedID,
           let indexPath = dataSource.indexPath(for: selectedID) {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let id = dataSource.itemIdentifier(for: indexPath),
              let index = currentTabs.firstIndex(where: { $0.id == id }) else { return }
        tabsDataSource?.selectTab(at: index, mode: mode.tabMode)
        refresh(animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let id = dataSource.itemIdentifier(for: indexPath) else { return [] }
        let item = UIDragItem(itemProvider: NSItemProvider(object: id.uuidString as NSString))
        item.localObject = id
        return [item]
    }

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        session.localDragSession != nil
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let item = coordinator.items.first,
              let id = item.dragItem.localObject as? UUID,
              let source = currentTabs.firstIndex(where: { $0.id == id }) else { return }
        let destination = min(coordinator.destinationIndexPath?.item ?? source, max(currentTabs.count - 1, 0))
        guard source != destination else { return }
        tabsDataSource?.moveTab(from: source, to: destination, mode: mode.tabMode)
        coordinator.drop(item.dragItem, toItemAt: IndexPath(item: destination, section: 0))
        refresh(animated: true)
    }

    @objc private func modeChanged() {
        mode = modeControl.selectedSegmentIndex == TabOverview.Mode.privateTabs.rawValue ? .privateTabs : .regularTabs
        refresh(animated: true)
    }

    private var currentTabs: [Tab] {
        guard let tabsDataSource else { return [] }
        return mode == .privateTabs ? tabsDataSource.privateTabs : tabsDataSource.regularTabs
    }

    private var selectedTabID: UUID? {
        guard let tabsDataSource,
              tabsDataSource.selectedMode == mode.tabMode,
              currentTabs.indices.contains(tabsDataSource.selectedIndex) else { return nil }
        return currentTabs[tabsDataSource.selectedIndex].id
    }

    private func configureHierarchy() {
        view.backgroundColor = BrowserDesignTokens.Color.chromeBackground
        view.addSubview(modeControl)
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            modeControl.topAnchor.constraint(equalTo: view.topAnchor, constant: BrowserDesignTokens.Spacing.small),
            modeControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: BrowserDesignTokens.Spacing.medium),
            modeControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -BrowserDesignTokens.Spacing.medium),
            collectionView.topAnchor.constraint(equalTo: modeControl.bottomAnchor, constant: BrowserDesignTokens.Spacing.small),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func configureDataSource() {
        let registration = UICollectionView.CellRegistration<UICollectionViewListCell, UUID> { [weak self] cell, _, id in
            guard let self,
                  let tab = self.currentTabs.first(where: { $0.id == id }) else { return }
            var content = cell.defaultContentConfiguration()
            content.text = tab.title.isEmpty ? NSLocalizedString("Homepage", comment: "") : tab.title
            content.secondaryText = URL(string: tab.url ?? "")?.host
            content.image = tab.favicon ?? UIImage(named: "reynard.globe")
            content.imageProperties.tintColor = .secondaryLabel
            content.textProperties.font = BrowserDesignTokens.Typography.cardDetail
            cell.contentConfiguration = content
            let closeAction = UIAction(title: NSLocalizedString("Close", comment: ""), image: UIImage(named: "reynard.xmark")) { [weak self] _ in
                guard let self,
                      let index = self.currentTabs.firstIndex(where: { $0.id == id }) else { return }
                self.tabsDataSource?.closeTab(at: index, mode: self.mode.tabMode)
                self.refresh(animated: true)
            }
            cell.accessories = [.customView(configuration: .init(customView: UIButton(primaryAction: closeAction), placement: .trailing()))]
            cell.accessibilityHint = NSLocalizedString("Double tap to switch tab. Drag to reorder.", comment: "")
        }
        dataSource = UICollectionViewDiffableDataSource<String, UUID>(collectionView: collectionView) { collectionView, indexPath, id in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: id)
        }
    }
}
