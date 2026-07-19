//
//  TopToolbar.swift
//  Reynard
//
//  Created by Minh Ton on 10/6/26.
//

import UIKit

final class TopToolbar: UIView {
    private enum UX {
        static let topToolbarContentHeight: CGFloat = 52
        static let topToolbarButtonStackHeight = BrowserDesignTokens.Control.compactHeight
        static let topToolbarStandardButtonStackWidth: CGFloat = 126
        static let topToolbarHorizontalInset: CGFloat = 12
        static let topToolbarButtonSpacing: CGFloat = 10
        static let topToolbarAddressBarSpacing: CGFloat = 12
        static let topToolbarAddressBarWidthLimit: CGFloat = 650
    }
    
    enum LayoutState {
        case hidden
        case standard
        case compact
    }
    
    var onSidebar: (() -> Void)?
    var onBack: (() -> Void)?
    var onForward: (() -> Void)?
    var onLibrary: (() -> Void)?
    var onDownloads: (() -> Void)?
    var onShare: (() -> Void)?
    var onNewTab: (() -> Void)?
    var onTabOverview: (() -> Void)?
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var sidebarButton = ToolbarButton(
        buttonType: .sidebar,
        target: self,
        action: #selector(sidebarTapped)
    )
    private lazy var backButton = ToolbarButton(
        buttonType: .back,
        target: self,
        action: #selector(backTapped)
    )
    private lazy var forwardButton = ToolbarButton(
        buttonType: .forward,
        target: self,
        action: #selector(forwardTapped)
    )
    private lazy var libraryButton = ToolbarButton(
        buttonType: .library,
        target: self,
        action: #selector(libraryTapped)
    )
    private lazy var downloadButton = ToolbarButton(
        buttonType: .download,
        target: self,
        action: #selector(downloadsTapped)
    )
    private lazy var shareButton = ToolbarButton(
        buttonType: .share,
        target: self,
        action: #selector(shareTapped)
    )
    private lazy var newTabButton = ToolbarButton(
        buttonType: .newTab,
        target: self,
        action: #selector(newTabTapped)
    )
    private lazy var tabOverviewButton = ToolbarButton(
        buttonType: .tabOverview,
        target: self,
        action: #selector(tabOverviewTapped)
    )
    
    private lazy var leadingButtons: UIStackView = {
        downloadButton.isHidden = true
        let stack = UIStackView(arrangedSubviews: [sidebarButton, downloadButton, backButton, forwardButton, libraryButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = UX.topToolbarButtonSpacing
        stack.distribution = .fillEqually
        return stack
    }()
    
    private lazy var trailingButtons: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [shareButton, newTabButton, tabOverviewButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = UX.topToolbarButtonSpacing
        stack.distribution = .fillEqually
        return stack
    }()
    
    private lazy var contentLayoutGuide: UILayoutGuide = {
        if #available(iOS 26.0, *) {
            return layoutGuide(for: .safeArea(cornerAdaptation: .horizontal))
        }
        
        return safeAreaLayoutGuide
    }()
    
    private var heightConstraint: NSLayoutConstraint!
    private var contentTopConstraint: NSLayoutConstraint!
    private var leadingWidthConstraint: NSLayoutConstraint!
    private var trailingWidthConstraint: NSLayoutConstraint!
    private var standardAddressBarConstraints: [NSLayoutConstraint] = []
    private var compactAddressBarConstraints: [NSLayoutConstraint] = []
    private var widthLimitedStandardAddressBarConstraints: [NSLayoutConstraint] = []
    
    private var layoutState: LayoutState = .hidden
    private var isUsingStandardAddressBarWidthLimit = false
    private var configuredActions: [BrowserToolbarAction] = []
    private var configuredContext: BrowserToolbarContext?
    private var configuredIncludesSidebar = false
    
    // MARK: - Lifecycle
    
    init() {
        super.init(frame: .zero)
        configureAppearance()
        configureHierarchy()
        configureConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateStandardAddressBarLayout()
    }
    
    // MARK: - Layout
    
    func attachAddressBar(_ addressBar: AddressBar) {
        if addressBar.superview !== contentView {
            addressBar.removeFromSuperview()
            contentView.addSubview(addressBar)
        }
        if standardAddressBarConstraints.isEmpty {
            standardAddressBarConstraints = [
                addressBar.leadingAnchor.constraint(equalTo: leadingButtons.trailingAnchor, constant: UX.topToolbarAddressBarSpacing),
                addressBar.trailingAnchor.constraint(equalTo: trailingButtons.leadingAnchor, constant: -UX.topToolbarAddressBarSpacing),
                addressBar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            ]
            widthLimitedStandardAddressBarConstraints = [
                addressBar.centerXAnchor.constraint(equalTo: contentLayoutGuide.centerXAnchor),
                addressBar.widthAnchor.constraint(equalToConstant: UX.topToolbarAddressBarWidthLimit),
                addressBar.leadingAnchor.constraint(greaterThanOrEqualTo: leadingButtons.trailingAnchor, constant: UX.topToolbarAddressBarSpacing),
                addressBar.trailingAnchor.constraint(lessThanOrEqualTo: trailingButtons.leadingAnchor, constant: -UX.topToolbarAddressBarSpacing),
                addressBar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            ]
            compactAddressBarConstraints = [
                addressBar.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor, constant: UX.topToolbarHorizontalInset),
                addressBar.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor, constant: -UX.topToolbarHorizontalInset),
                addressBar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            ]
        }
    }
    
    func detachAddressBar() {
        NSLayoutConstraint.deactivate(standardAddressBarConstraints + widthLimitedStandardAddressBarConstraints + compactAddressBarConstraints)
        isUsingStandardAddressBarWidthLimit = false
    }
    
    func apply(
        state: LayoutState,
        topInset: CGFloat,
        interfaceIdiom: UIUserInterfaceIdiom,
        sidebarButtonVisible: Bool,
        actions: [BrowserToolbarAction]
    ) {
        layoutState = state
        configureActions(
            actions,
            context: state == .compact ? .compactTop : .padTop,
            includesSidebar: interfaceIdiom == .pad && sidebarButtonVisible
        )
        
        UIView.performWithoutAnimation {
            contentTopConstraint.constant = topInset
            heightConstraint.constant = topInset + UX.topToolbarContentHeight
            isHidden = state == .hidden
            guard state != .hidden else { return }
            
            let isCompact = state == .compact
            leadingButtons.isHidden = isCompact
            trailingButtons.isHidden = isCompact
            
            sidebarButton.isHidden = interfaceIdiom != .pad || !sidebarButtonVisible
            downloadButton.isHidden = isCompact || !downloadButton.isShowingDownloads
            leadingWidthConstraint.constant = isCompact ? 0 : stackWidth(for: leadingButtons)
            trailingWidthConstraint.constant = isCompact ? 0 : stackWidth(for: trailingButtons)
            
            NSLayoutConstraint.deactivate(standardAddressBarConstraints + widthLimitedStandardAddressBarConstraints + compactAddressBarConstraints)
            isUsingStandardAddressBarWidthLimit = false
            if isCompact {
                NSLayoutConstraint.activate(compactAddressBarConstraints)
            } else {
                setStandardAddressBarWidthLimitEnabled(shouldLimitStandardAddressBarWidth)
            }
            layoutIfNeeded()
        }
    }
    
    // MARK: - Updates
    
    func updateNavigation(canGoBack: Bool, canGoForward: Bool, canShare: Bool) {
        backButton.isEnabled = canGoBack
        forwardButton.isEnabled = canGoForward
        shareButton.isEnabled = canShare
    }
    
    func updateDownload(_ summary: DownloadStoreSummary) {
        downloadButton.applyDownloadSummary(summary)
        updateDownloadButtonVisibility()
    }
    
    func setMenuButtonIndicatesUpdate(_ hasUpdate: Bool) {
        libraryButton.setImage(
            hasUpdate ? UIImage(named: "reynard.ellipsis.circle.badge") : UIImage(named: "reynard.ellipsis.circle"),
            for: .normal
        )
    }
    
    func syncSidebarButton(splitViewController: UISplitViewController?) {
        sidebarButton.setImage(splitViewController?.displayModeButtonItem.image ?? UIImage(named: "reynard.sidebar.left"), for: .normal)
        sidebarButton.accessibilityLabel = splitViewController?.displayModeButtonItem.accessibilityLabel
    }
    
    func sidebarButtonFrame(in view: UIView) -> CGRect {
        return sidebarButton.convert(sidebarButton.bounds, to: view)
    }
    
    func setSidebarButtonTransition(alpha: CGFloat, hidden: Bool) {
        sidebarButton.alpha = alpha
        sidebarButton.isHidden = hidden
    }
    
    // MARK: - Action Wiring
    
    @objc private func sidebarTapped() { onSidebar?() }
    @objc private func backTapped() { onBack?() }
    @objc private func forwardTapped() { onForward?() }
    @objc private func libraryTapped() { onLibrary?() }
    @objc private func downloadsTapped() { onDownloads?() }
    @objc private func shareTapped() { onShare?() }
    @objc private func newTabTapped() { onNewTab?() }
    @objc private func tabOverviewTapped() { onTabOverview?() }
    
    // MARK: - View Setup
    
    private func configureAppearance() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = BrowserDesignTokens.Color.chromeBackground
    }
    
    private func configureHierarchy() {
        addSubview(contentView)
        contentView.addSubview(leadingButtons)
        contentView.addSubview(trailingButtons)
    }
    
    private func configureConstraints() {
        heightConstraint = heightAnchor.constraint(equalToConstant: UX.topToolbarContentHeight)
        contentTopConstraint = contentView.topAnchor.constraint(equalTo: topAnchor)
        leadingWidthConstraint = leadingButtons.widthAnchor.constraint(equalToConstant: UX.topToolbarStandardButtonStackWidth)
        trailingWidthConstraint = trailingButtons.widthAnchor.constraint(equalToConstant: UX.topToolbarStandardButtonStackWidth)
        
        NSLayoutConstraint.activate([
            heightConstraint,
            contentTopConstraint,
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.heightAnchor.constraint(equalToConstant: UX.topToolbarContentHeight),
            
            leadingButtons.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor, constant: UX.topToolbarHorizontalInset),
            leadingButtons.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            leadingWidthConstraint,
            leadingButtons.heightAnchor.constraint(equalToConstant: UX.topToolbarButtonStackHeight),
            
            trailingButtons.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor, constant: -UX.topToolbarHorizontalInset),
            trailingButtons.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            trailingWidthConstraint,
            trailingButtons.heightAnchor.constraint(equalToConstant: UX.topToolbarButtonStackHeight),
        ])
    }
    
    private func stackWidth(for stack: UIStackView) -> CGFloat {
        let visibleButtonCount = stack.arrangedSubviews.filter { !$0.isHidden }.count
        guard visibleButtonCount > 0 else {
            return 0
        }
        return (CGFloat(visibleButtonCount) * UX.topToolbarButtonStackHeight)
        + (CGFloat(visibleButtonCount - 1) * UX.topToolbarButtonSpacing)
    }
    
    private var shouldLimitStandardAddressBarWidth: Bool {
        let layoutInsets = contentLayoutInsets
        let safeWidth = bounds.width - layoutInsets.left - layoutInsets.right
        guard safeWidth > 0 else { return false }
        
        let leadingBoundary = UX.topToolbarHorizontalInset
        + leadingWidthConstraint.constant
        + UX.topToolbarAddressBarSpacing
        let trailingBoundary = safeWidth
        - UX.topToolbarHorizontalInset
        - trailingWidthConstraint.constant
        - UX.topToolbarAddressBarSpacing
        let centeredWidth = min(
            (safeWidth / 2) - leadingBoundary,
            trailingBoundary - (safeWidth / 2)
        ) * 2
        
        return centeredWidth > UX.topToolbarAddressBarWidthLimit
    }
    
    private var contentLayoutInsets: UIEdgeInsets {
        if #available(iOS 26.0, *) {
            return edgeInsets(for: .safeArea(cornerAdaptation: .horizontal))
        }
        
        return safeAreaInsets
    }
    
    private func updateStandardAddressBarLayout() {
        guard layoutState == .standard else {
            return
        }
        
        setStandardAddressBarWidthLimitEnabled(shouldLimitStandardAddressBarWidth)
    }
    
    private func setStandardAddressBarWidthLimitEnabled(_ isEnabled: Bool) {
        let activeConstraints = isEnabled ? widthLimitedStandardAddressBarConstraints : standardAddressBarConstraints
        guard activeConstraints.contains(where: { !$0.isActive }) || isUsingStandardAddressBarWidthLimit != isEnabled else {
            return
        }
        
        NSLayoutConstraint.deactivate(standardAddressBarConstraints + widthLimitedStandardAddressBarConstraints)
        NSLayoutConstraint.activate(activeConstraints)
        isUsingStandardAddressBarWidthLimit = isEnabled
    }
    
    private func updateDownloadButtonVisibility() {
        let isCompact = layoutState == .compact
        downloadButton.isHidden = layoutState != .standard || !downloadButton.isShowingDownloads
        leadingWidthConstraint.constant = isCompact ? 0 : stackWidth(for: leadingButtons)
        trailingWidthConstraint.constant = isCompact ? 0 : stackWidth(for: trailingButtons)
        updateStandardAddressBarLayout()
        layoutIfNeeded()
    }

    private func configureActions(
        _ requestedActions: [BrowserToolbarAction],
        context: BrowserToolbarContext,
        includesSidebar: Bool
    ) {
        let actions = ToolbarActionPolicy.sanitize(
            requestedActions,
            maximumVisibleActions: 6
        )
        guard actions != configuredActions ||
              context != configuredContext ||
              includesSidebar != configuredIncludesSidebar ||
              leadingButtons.arrangedSubviews.isEmpty else {
            return
        }

        let layout = ToolbarActionPolicy.layout(
            actions: actions,
            context: context,
            maximumVisibleActions: 6
        )
        let leadingViews: [UIView] = (includesSidebar ? [sidebarButton] : [])
        + layout.leading.map { button(for: $0) }
        let trailingViews: [UIView] = layout.trailing.map { button(for: $0) }

        replaceArrangedSubviews(in: leadingButtons, with: leadingViews)
        replaceArrangedSubviews(in: trailingButtons, with: trailingViews)
        configuredActions = actions
        configuredContext = context
        configuredIncludesSidebar = includesSidebar
    }

    private func replaceArrangedSubviews(
        in stack: UIStackView,
        with views: [UIView]
    ) {
        for view in stack.arrangedSubviews {
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        views.forEach(stack.addArrangedSubview)
    }

    private func button(for action: BrowserToolbarAction) -> ToolbarButton {
        switch action {
        case .back: return backButton
        case .forward: return forwardButton
        case .share: return shareButton
        case .menu: return libraryButton
        case .downloads: return downloadButton
        case .tabs: return tabOverviewButton
        case .newTab: return newTabButton
        }
    }
}
