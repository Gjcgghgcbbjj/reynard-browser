//
//  SceneDelegate.swift
//  Reynard
//
//  Created by Minh Ton on 1/2/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        StabilityDiagnostics.shared.record(
            .startup,
            name: "scene.willConnect",
            metadata: ["activationState": String(scene.activationState.rawValue)]
        )
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = AppAppearanceController.userInterfaceStyle(for: Prefs.AppearanceSettings.appAppearance)
        window.backgroundColor = .systemBackground
        installInitialRoot(in: window, activationState: scene.activationState)
        window.makeKeyAndVisible()
        self.window = window
        
        handleIncomingURLContexts(connectionOptions.urlContexts)
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        handleIncomingURLContexts(URLContexts)
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        StabilityDiagnostics.shared.record(.session, name: "scene.didDisconnect")
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        StabilityDiagnostics.shared.record(.session, name: "scene.didBecomeActive")
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        StabilityDiagnostics.shared.record(.session, name: "scene.willResignActive")
        (window?.rootViewController as? BrowserViewController)?
            .sessionManager.applicationWillResignActive()
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        StabilityDiagnostics.shared.record(.session, name: "scene.willEnterForeground")
        (window?.rootViewController as? BrowserViewController)?
            .sessionManager.setApplicationForeground(true)
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        StabilityDiagnostics.shared.record(.session, name: "scene.didEnterBackground")
        (window?.rootViewController as? BrowserViewController)?
            .sessionManager.setApplicationForeground(false)
    }
    
    private func handleIncomingURLContexts(_ urlContexts: Set<UIOpenURLContext>) {
        guard let incomingURL = urlContexts.first?.url else {
            return
        }
        handleIncomingURL(incomingURL)
    }
    
    private func handleIncomingURL(_ incomingURL: URL) {
        StabilityDiagnostics.shared.recordURL(
            .session,
            name: "scene.handleIncomingURL",
            urlString: incomingURL.absoluteString
        )
        guard let browserViewController = window?.rootViewController as? BrowserViewController,
              let resolvedURL = resolvedBrowserURL(from: incomingURL) else {
            return
        }
        
        DispatchQueue.main.async {
            browserViewController.loadViewIfNeeded()
            browserViewController.sidebarCoordinator.loadContentIfNeeded()
            browserViewController.sidebarCoordinator.openExternalURL(resolvedURL)
        }
    }
    
    private func resolvedBrowserURL(from incomingURL: URL) -> URL? {
        guard let scheme = incomingURL.scheme?.lowercased() else {
            return nil
        }
        
        if scheme == "http" || scheme == "https" {
            return incomingURL
        }
        
        guard scheme == "reynard",
              let components = URLComponents(url: incomingURL, resolvingAgainstBaseURL: false),
              let encodedURL = components.queryItems?.first(where: { $0.name == "url" })?.value else {
            return nil
        }
        
        return URL(string: encodedURL)
    }

    private func installInitialRoot(
        in window: UIWindow,
        activationState: UIScene.ActivationState
    ) {
        guard let report = UserDataMigration.shared.latestReport,
              report.requiresBlockingRecovery else {
            installBrowserRoot(in: window, activationState: activationState)
            return
        }

        window.rootViewController = StartupMigrationFailureViewController(
            report: report,
            retryMigration: {
                let retryReport = UserDataMigration.shared.run()
                StabilityDiagnostics.shared.recordMigrationReport(retryReport)
                return retryReport
            },
            onRecovered: { [weak self, weak window] in
                guard let self, let window else {
                    return
                }
                JITController.shared.start()
                self.installBrowserRoot(
                    in: window,
                    activationState: window.windowScene?.activationState ?? .foregroundInactive
                )
            }
        )
    }

    private func installBrowserRoot(
        in window: UIWindow,
        activationState: UIScene.ActivationState
    ) {
        let browserViewController = BrowserViewController()
        browserViewController.sessionManager.setApplicationForeground(
            activationState != .background
        )
        window.rootViewController = browserViewController
    }
}
