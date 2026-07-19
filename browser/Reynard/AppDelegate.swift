//
//  AppDelegate.swift
//  Reynard
//
//  Created by Minh Ton on 1/2/26.
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if let report = UserDataMigration.shared.latestReport {
            StabilityDiagnostics.shared.recordMigrationReport(report)
        }
        StabilityDiagnostics.shared.record(
            .startup,
            name: "application.didFinishLaunching",
            metadata: ["hasLaunchOptions": launchOptions == nil ? "false" : "true"]
        )
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        StabilityDiagnostics.shared.record(
            .startup,
            name: "application.configurationForConnectingScene",
            metadata: ["role": connectingSceneSession.role.rawValue]
        )
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        StabilityDiagnostics.shared.record(
            .session,
            name: "application.didDiscardSceneSessions",
            metadata: ["count": String(sceneSessions.count)]
        )
    }
}
