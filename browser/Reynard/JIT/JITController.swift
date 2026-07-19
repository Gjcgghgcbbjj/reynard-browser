//
//  JITController.swift
//  Reynard
//
//  Created by Minh Ton on 11/3/26.
//

import Foundation
import Darwin
import UIKit

final class JITController {
    static let shared = JITController()

    private enum RuntimeState: Equatable {
        case idle
        case attaching
        case failed
        case jitless
    }
    
    private let attachQueue = DispatchQueue(label: "com.minh-ton.Reynard.JITController.AttachQueue", qos: .userInitiated)
    private let watchdogQueue = DispatchQueue(label: "com.minh-ton.Reynard.JITController.WatchdogQueue", qos: .userInitiated)
    private let stateLock = NSLock()
    private var attachedPIDs: Set<Int32> = []
    private var preflightWatchdogs: [Int32: DispatchWorkItem] = [:]
    private var runtimeState = RuntimeState.idle
    private var retryPolicy = JITRetryPolicy()
    private var hasStarted = false
    private var pendingFailureAction: (() -> Void)?
    private let preflightTimeoutSeconds: Int = 5
    private let failurePresentationRetryLimit = 12
    
    private init() {}

    var isJITLessModeActive: Bool {
        currentRuntimeState() == .jitless
    }

    private func currentRuntimeState() -> RuntimeState {
        stateLock.lock()
        defer { stateLock.unlock() }
        return runtimeState
    }

    private func setRuntimeState(_ state: RuntimeState) {
        stateLock.lock()
        runtimeState = state
        stateLock.unlock()
    }

    private func registerFailure(at date: Date) -> JITRetryDecision? {
        stateLock.lock()
        defer { stateLock.unlock() }

        guard runtimeState != .failed, runtimeState != .jitless else {
            return nil
        }

        runtimeState = .failed
        return retryPolicy.decide(at: date)
    }

    private func registerSuccess() {
        stateLock.lock()
        guard runtimeState != .failed, runtimeState != .jitless else {
            stateLock.unlock()
            return
        }
        runtimeState = .idle
        retryPolicy.reset()
        stateLock.unlock()
    }

    private func beginStartIfNeeded() -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard !hasStarted else {
            return false
        }
        hasStarted = true
        return true
    }
    
    // For TrollStore or jailbroken devices
    private func usePtraceJIT() -> Bool {
        getEntitlementValue("com.apple.private.security.no-sandbox")
    }
    
    func start() {
        guard beginStartIfNeeded() else {
            return
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        guard usePtraceJIT() || !isDDIMissing() else {
            setRuntimeState(.failed)
            DispatchQueue.main.async {
                self.presentMissingDDIFailureScreen()
            }
            return
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleChildProcessNotification(_:)),
            name: .geckoRuntimeChildProcessDidStart,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleJITDisconnectNotification(_:)),
            name: .jitEndpointMonitorDidFail,
            object: nil
        )
    }
    
    private func isDDIMissing() -> Bool {
        Prefs.JITSettings.isJITEnabled && !DDIManager.shared.hasRequiredDDIFiles()
    }
    
    private func shouldAttach(to processType: String) -> Bool {
        let normalized = processType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized == "tab"
    }
    
    private func filePath(atPath path: String, withLength length: Int) -> String? {
        guard let file = try? FileManager.default.contentsOfDirectory(atPath: path).first(where: { $0.count == length }) else {
            return nil
        }
        return "\(path)/\(file)"
    }
    
    // Adapted from StikDebug
    private func hasTXMSupport() -> Bool {
        var systemInfo = utsname()
        uname(&systemInfo)
        let hardware = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
        
        if #available(iOS 27.0, *) {
            return hardware != "iPad8,11" && hardware != "iPad8,12"
        }
        
        if #available(iOS 26.0, *) {
            let pattern = hardware.hasPrefix("iPad")
            ? #"iPad(\d+),(\d+)"#
            : #"iPhone(\d+),(\d+)"#
            let threshold: Double = hardware.hasPrefix("iPad") ? 14.5 : 14.2
            
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(
                    in: hardware,
                    range: NSRange(hardware.startIndex..., in: hardware)
                  ),
                  let majorRange = Range(match.range(at: 1), in: hardware),
                  let minorRange = Range(match.range(at: 2), in: hardware),
                  let major = Double(hardware[majorRange]),
                  let minor = Double(hardware[minorRange])
            else {
                return false
            }
            
            let divisor = pow(10.0, Double(String(Int(minor)).count))
            let ver = major + (minor / divisor)
            return ver >= threshold
        }
        
        return false
    }
    
    private func newDeviceOSVersion() -> DeviceOSVersion {
        let operatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
        return DeviceOSVersion(
            majorVersion: Int32(operatingSystemVersion.majorVersion),
            minorVersion: Int32(operatingSystemVersion.minorVersion),
            patchVersion: Int32(operatingSystemVersion.patchVersion)
        )
    }
    
    private func newJITRuntimeInfo() -> JITRuntimeInfo {
        return JITRuntimeInfo(
            hasTXMSupport: hasTXMSupport() ? 1 : 0,
            deviceOSVersion: newDeviceOSVersion()
        )
    }
    
    func childProcessDidStart(pid: Int32, processType: String) {
        guard pid > 0 else {
            return
        }
        
        let state = currentRuntimeState()
        guard state != .jitless, state != .failed else {
            ReportJITStatusForChild(pid, false, newJITRuntimeInfo())
            return
        }
        
        guard usePtraceJIT() || Prefs.JITSettings.isJITEnabled else {
            ReportJITStatusForChild(pid, false, newJITRuntimeInfo())
            return
        }
        
        guard shouldAttach(to: processType) else {
            ReportJITStatusForChild(pid, false, newJITRuntimeInfo())
            return
        }
        
        attachQueue.async {
            if self.attachedPIDs.contains(pid) {
                return
            }
            self.setRuntimeState(.attaching)
            self.attachedPIDs.insert(pid)
            self.schedulePreflightWatchdog(for: pid)
            self.attachToProcess(pid: pid)
        }
    }
    
    private func attachToProcess(pid: Int32) {
        do {
            try JITEnabler.shared.enableJIT(forPID: pid, hasTXMSupport: hasTXMSupport())
            cancelPreflightWatchdog(for: pid)
            ReportJITStatusForChild(pid, true, newJITRuntimeInfo())
            registerSuccess()
            StabilityDiagnostics.shared.record(
                .jit,
                name: "jit.attachmentSucceeded",
                metadata: ["pid": String(pid)]
            )
        } catch {
            let nsError = error as NSError
            cancelPreflightWatchdog(for: pid)
            ReportJITStatusForChild(pid, false, newJITRuntimeInfo())
            handleJITFailure(error: nsError)
        }
    }
    
    private func schedulePreflightWatchdog(for pid: Int32) {
        var watchdog: DispatchWorkItem?
        watchdog = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }
            
            guard let watchdog, !watchdog.isCancelled else {
                return
            }
            
            ReportJITStatusForChild(pid, false, newJITRuntimeInfo())
            self.handleJITFailure(error: NSError(domain: "Reynard.JIT", code: Int(ETIMEDOUT), userInfo: nil))
        }
        
        guard let watchdog else {
            return
        }
        
        preflightWatchdogs[pid] = watchdog
        watchdogQueue.asyncAfter(deadline: .now() + .seconds(preflightTimeoutSeconds), execute: watchdog)
    }
    
    private func cancelPreflightWatchdog(for pid: Int32) {
        preflightWatchdogs[pid]?.cancel()
        preflightWatchdogs.removeValue(forKey: pid)
    }
    
    private func cancelAllPreflightWatchdogs() {
        for pid in preflightWatchdogs.keys {
            cancelPreflightWatchdog(for: pid)
        }
    }
    
    private func handleJITFailure(error: NSError) {
        guard let retryDecision = registerFailure(at: Date()) else {
            return
        }

        StabilityDiagnostics.shared.record(
            .jit,
            name: "jit.attachmentFailed",
            metadata: [
                "code": String(error.code),
                "retryAvailable": retryDecision == .retry ? "true" : "false",
            ]
        )

        DispatchQueue.main.async {
            self.presentEnablementFailureScreen(
                error: error,
                showsErrorDetails: error.code != Int(ETIMEDOUT),
                retryAvailable: retryDecision == .retry
            )
        }
    }
    
    private func presentEnablementFailureScreen(
        error: NSError,
        showsErrorDetails: Bool,
        retryAvailable: Bool,
        retryCount: Int = 0
    ) {
        guard retryCount <= failurePresentationRetryLimit else {
            return
        }
        
        guard Self.canPresentFailureUI() else {
            pendingFailureAction = { [weak self] in
                self?.presentEnablementFailureScreen(
                    error: error,
                    showsErrorDetails: showsErrorDetails,
                    retryAvailable: retryAvailable
                )
            }
            return
        }
        
        guard let presenter = UIApplication.shared.topViewController() else {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150)) {
                self.presentEnablementFailureScreen(
                    error: error,
                    showsErrorDetails: showsErrorDetails,
                    retryAvailable: retryAvailable,
                    retryCount: retryCount + 1
                )
            }
            return
        }
        
        let description = error.localizedDescription.isEmpty ? NSLocalizedString("Unknown error.", comment: "") : error.localizedDescription
        let messageText: String
        if usePtraceJIT() {
            messageText = NSLocalizedString("It's extremely rare that you encounter this issue! Make sure that your TrollStore installation or jailbroken environment is properly configured.\n\nYou may use the browser without JIT temporarily until the next launch by activating JIT-Less Mode.", comment: "Paragraph break intentional")
        } else {
            messageText = NSLocalizedString("Please check that your pairing file is valid, your loopback VPN is on, and you're connected to a stable Wi-Fi network.\n\nYou may use the browser without JIT temporarily until the next launch by activating JIT-Less Mode.", comment: "Paragraph break intentional")
        }
        
        let viewController = JITFailureViewController(
            errorCode: error.code,
            errorDescription: description,
            showsErrorDetails: showsErrorDetails,
            titleText: NSLocalizedString("Failed to enable JIT", comment: ""),
            messageText: messageText,
            primaryButtonTitle: retryAvailable
            ? NSLocalizedString("Retry JIT", comment: "")
            : NSLocalizedString("Export Diagnostics", comment: ""),
            secondaryButtonTitle: NSLocalizedString("Activate JIT-Less Mode", comment: ""),
            onPrimaryAction: { [weak self] in
                guard let self else {
                    return
                }
                retryAvailable ? self.retryJITAfterFailure() : self.exportDiagnostics()
            },
            onSecondaryAction: { [weak self] in
                self?.activateJITLessMode()
            }
        )
        viewController.modalPresentationStyle = .pageSheet
        viewController.modalTransitionStyle = .coverVertical
        presenter.present(viewController, animated: true)
    }
    
    private func presentMissingDDIFailureScreen(retryCount: Int = 0) {
        guard retryCount <= failurePresentationRetryLimit else {
            return
        }
        
        guard Self.canPresentFailureUI() else {
            pendingFailureAction = { [weak self] in
                self?.presentMissingDDIFailureScreen()
            }
            return
        }
        
        guard let presenter = UIApplication.shared.topViewController() else {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150)) {
                self.presentMissingDDIFailureScreen(retryCount: retryCount + 1)
            }
            return
        }
        
        let viewController = JITFailureViewController(
            errorCode: Int(ENOENT),
            errorDescription: NSLocalizedString("Required DDI files are missing.", comment: ""),
            showsErrorDetails: false,
            titleText: NSLocalizedString("Failed to enable JIT", comment: ""),
            messageText: NSLocalizedString("The required Developer Disk Image files for enabling JIT were not found.\n\nJIT has been disabled. Quit the app using the button below, then re-enable JIT from the browser settings.", comment: "Paragraph break intentional"),
            primaryButtonTitle: NSLocalizedString("Quit Reynard", comment: ""),
            onPrimaryAction: {
                self.disableJITAndQuit()
            }
        )
        viewController.modalPresentationStyle = .pageSheet
        viewController.modalTransitionStyle = .coverVertical
        presenter.present(viewController, animated: true)
    }
    
    private func disableJITAndQuit() {
        Prefs.JITSettings.isJITEnabled = false
        quitApp()
    }

    private func retryJITAfterFailure() {
        attachQueue.async {
            self.cancelAllPreflightWatchdogs()
            self.attachedPIDs.removeAll()
            JITEnabler.shared.detachAllJITSessions()
            self.setRuntimeState(.idle)
            StabilityDiagnostics.shared.record(.jit, name: "jit.retryRequested")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .jitRetryRequested, object: nil)
            }
        }
    }

    private func exportDiagnostics() {
        DispatchQueue.main.async {
            guard let presenter = UIApplication.shared.topViewController() else {
                return
            }
            DiagnosticsExportCoordinator.present(from: presenter)
        }
    }
    
    private func quitApp() {
        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            exit(EXIT_SUCCESS)
        }
    }
    
    private func activateJITLessMode() {
        guard !isJITLessModeActive else {
            return
        }
        
        setRuntimeState(.jitless)
        attachQueue.async {
            self.cancelAllPreflightWatchdogs()
            self.attachedPIDs.removeAll()
            JITEnabler.shared.detachAllJITSessions()
            StabilityDiagnostics.shared.record(.jit, name: "jit.jitlessModeActivated")
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .jitlessModeDidActivate, object: nil)
        }
    }
    
    private static func canPresentFailureUI() -> Bool {
        guard UIApplication.shared.applicationState == .active else {
            return false
        }
        
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .contains { $0.activationState == .foregroundActive }
    }
    
    @objc private func handleApplicationDidBecomeActive() {
        let action = pendingFailureAction
        pendingFailureAction = nil
        action?()
    }
    
    @objc private func handleChildProcessNotification(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let pidNumber = userInfo["pid"] as? NSNumber,
            let processType = userInfo["processType"] as? String
        else {
            return
        }
        
        childProcessDidStart(pid: pidNumber.int32Value, processType: processType)
    }
    
    @objc private func handleJITDisconnectNotification(_ notification: Notification) {
        guard Prefs.JITSettings.isJITEnabled, !isJITLessModeActive else {
            return
        }
        
        if let pid = (notification.userInfo?["pid"] as? NSNumber)?.int32Value, pid > 0 {
            ReportJITStatusForChild(pid, false, newJITRuntimeInfo())
        }
        
        handleJITFailure(
            error: NSError(
                domain: "Reynard.JIT",
                code: Int(ETIMEDOUT),
                userInfo: nil
            )
        )
    }
}
