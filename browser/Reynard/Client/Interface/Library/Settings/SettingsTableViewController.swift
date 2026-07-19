//
//  SettingsTableViewController.swift
//  Reynard
//
//  Created by Minh Ton on 18/6/26.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    private enum UX {
        static let sectionHeaderTopPadding: CGFloat = 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionText(for: section).headerTitle
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sectionText(for: section).footerTitle
    }
    
    func sectionText(for section: Int) -> SettingsSectionText {
        return SettingsSectionText()
    }
    
    private func configureTableView() {
        BrowserListStyle.apply(to: tableView)
        view.backgroundColor = BrowserDesignTokens.Color.chromeBackground
        if let navigationBar = navigationController?.navigationBar {
            BrowserListStyle.applyNavigation(to: navigationBar)
        }
        tableView.alwaysBounceVertical = true
        tableView.keyboardDismissMode = .interactive
        if #available(iOS 14.0, *) {
            tableView.selectionFollowsFocus = false
        }
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = UX.sectionHeaderTopPadding
        }
    }
}
