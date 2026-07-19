//
//  ActionBar.swift
//  Reynard
//
//  Created by Minh Ton on 28/6/26.
//

import GeckoView
import UIKit

final class ActionBar: UIView {
    static let height: CGFloat = 62
    
    enum Item: Equatable {
        case pageZoom
        case findInPage
    }
    
    var onPageZoomOut: (() -> Void)? {
        get { return pageZoomActionBar.onZoomOut }
        set { pageZoomActionBar.onZoomOut = newValue }
    }
    
    var onPageZoomIn: (() -> Void)? {
        get { return pageZoomActionBar.onZoomIn }
        set { pageZoomActionBar.onZoomIn = newValue }
    }
    
    var onPageZoomReset: (() -> Void)? {
        get { return pageZoomActionBar.onReset }
        set { pageZoomActionBar.onReset = newValue }
    }
    
    var onClose: (() -> Void)? {
        get { return pageZoomActionBar.onClose }
        set {
            pageZoomActionBar.onClose = newValue
            findInPageActionBar.onClose = newValue
        }
    }

    var onFindQueryChanged: ((String) -> Void)? {
        get { findInPageActionBar.onQueryChanged }
        set { findInPageActionBar.onQueryChanged = newValue }
    }

    var onFindPrevious: (() -> Void)? {
        get { findInPageActionBar.onPrevious }
        set { findInPageActionBar.onPrevious = newValue }
    }

    var onFindNext: (() -> Void)? {
        get { findInPageActionBar.onNext }
        set { findInPageActionBar.onNext = newValue }
    }
    
    private(set) var item: Item?
    
    private let pageZoomActionBar = PageZoomActionBar()
    private let findInPageActionBar = FindInPageActionBar()
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureAppearance()
        configureHierarchy()
        configureConstraints()
        setItem(nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Presentation
    
    func setItem(_ item: Item?) {
        self.item = item
        isHidden = item == nil
        pageZoomActionBar.isHidden = item != .pageZoom
        findInPageActionBar.isHidden = item != .findInPage
        if item != .findInPage {
            findInPageActionBar.endSearchEditing()
        }
    }
    
    func setPageZoomLevel(_ level: Int) {
        pageZoomActionBar.setZoomLevel(level)
    }
    
    func nextPageZoomLevel() -> Int {
        return pageZoomActionBar.nextZoomLevel()
    }
    
    func previousPageZoomLevel() -> Int {
        return pageZoomActionBar.previousZoomLevel()
    }

    var isFindSearchFocused: Bool {
        findInPageActionBar.isSearchFocused
    }

    func focusFindInPage() {
        findInPageActionBar.focus()
    }

    func updateFindResult(_ result: FindInPageResult?) {
        findInPageActionBar.updateResult(result)
    }
    
    // MARK: - View Setup
    
    private func configureAppearance() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
    }
    
    private func configureHierarchy() {
        addSubview(pageZoomActionBar)
        addSubview(findInPageActionBar)
    }
    
    private func configureConstraints() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: ActionBar.height),
            
            pageZoomActionBar.topAnchor.constraint(equalTo: topAnchor),
            pageZoomActionBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            pageZoomActionBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            pageZoomActionBar.bottomAnchor.constraint(equalTo: bottomAnchor),

            findInPageActionBar.topAnchor.constraint(equalTo: topAnchor),
            findInPageActionBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            findInPageActionBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            findInPageActionBar.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
