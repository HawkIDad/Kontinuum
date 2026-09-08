// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  AppDelegate.swift
//  Kontinuum
//

import OSLog

#if os(iOS)
import UIKit
import CloudKit

/// SwiftUI's `App` protocol has no hook for silent push receipt, which `SyncEngine`'s
/// `CKDatabaseSubscription`-driven incremental sync needs — bridged in via
/// `@UIApplicationDelegateAdaptor` in `NoteBytezApp`. See the `#elseif os(macOS)` branch below
/// for the Mac counterpart.
final class AppDelegate: NSObject, UIApplicationDelegate {

    private let logger = Log.logger(.sync)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.error("Remote notification registration failed: \(error.localizedDescription)")
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task {
            await SyncEngine.shared.handleRemoteNotification()
            completionHandler(.newData)
        }
    }

    /// Phase 10 — the user tapped an iCloud share invitation link (Mail, Messages, or the
    /// system share sheet) and accepted it. `UIApplicationDelegate`'s variant of this hook is
    /// deprecated in favor of `UIWindowSceneDelegate.windowScene(_:userDidAcceptCloudKitShareWith:)`,
    /// which this app doesn't have — adopting it would mean introducing a custom
    /// `UIWindowSceneDelegate`/scene configuration purely for this one callback, a bigger change
    /// than this phase's own scope (`AppDelegate` is documented, per `ARCHITECTURE.md`, as "the
    /// one place with real platform-specific logic"). Kept on the app-delegate hook, which still
    /// fires correctly, with the deprecation noted here rather than silently worked around.
    func application(_ application: UIApplication, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        Task {
            await SyncEngine.shared.acceptShare(cloudKitShareMetadata)
        }
    }

}

#elseif os(macOS)
import AppKit
import CloudKit

/// Mac counterpart to the iOS `AppDelegate` above — same role (bridge silent CloudKit push into
/// `SyncEngine`), bridged in via `@NSApplicationDelegateAdaptor` in `NoteBytezApp`. macOS has no
/// background-fetch-budget concept, so remote-notification receipt here has no completion
/// handler to call back, unlike the iOS path.
final class AppDelegate: NSObject, NSApplicationDelegate {

    private let logger = Log.logger(.sync)

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.registerForRemoteNotifications()
    }

    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.error("Remote notification registration failed: \(error.localizedDescription)")
    }

    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String: Any]) {
        Task {
            await SyncEngine.shared.handleRemoteNotification()
        }
    }

    /// Phase 10's accept-side counterpart to the iOS handler above — not deprecated on macOS,
    /// so no scene-delegate workaround is needed here.
    func application(_ application: NSApplication, userDidAcceptCloudKitShareWith metadata: CKShare.Metadata) {
        Task {
            await SyncEngine.shared.acceptShare(metadata)
        }
    }

}
#endif
