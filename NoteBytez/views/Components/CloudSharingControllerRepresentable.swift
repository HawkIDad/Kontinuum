// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CloudSharingControllerRepresentable.swift
//  NoteBytez
//

import SwiftUI
import CloudKit
import OSLog

#if os(iOS)
import UIKit

/// Presents `UICloudSharingController` — the system's own invite UI (contact picker, permission
/// toggle, share-link generation) — from a `Binding` rather than a `View` of its own, the
/// standard pattern for wrapping a UIKit *presentation* (not an embeddable view) in SwiftUI: a
/// transparent host controller whose only job is calling `present` when `isPresented` flips true.
struct CloudSharingControllerRepresentable: UIViewControllerRepresentable {

    let share: CKShare
    let container: CKContainer
    let libraryName: String
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard isPresented, uiViewController.presentedViewController == nil else { return }
        let controller = UICloudSharingController(share: share, container: container)
        controller.delegate = context.coordinator
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        uiViewController.present(controller, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(libraryName: libraryName, isPresented: $isPresented)
    }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        private let libraryName: String
        @Binding private var isPresented: Bool

        init(libraryName: String, isPresented: Binding<Bool>) {
            self.libraryName = libraryName
            self._isPresented = isPresented
        }

        func itemTitle(for csc: UICloudSharingController) -> String? { libraryName }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            Log.logger(.sync).error("Failed to save share: \(error.localizedDescription)")
            isPresented = false
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            isPresented = false
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            isPresented = false
        }
    }

}
#else
import AppKit

/// macOS counterpart — no dedicated view controller for CKShare exists on this platform;
/// `NSSharingService(named: .cloudSharing)` is itself the presentation, invoked imperatively.
/// Wrapped the same way (a transparent host, `updateNSViewController` triggering the action)
/// so the call site (`SharingParticipantsView`) stays identical across platforms.
struct CloudSharingControllerRepresentable: NSViewControllerRepresentable {

    let share: CKShare
    let container: CKContainer
    let libraryName: String
    @Binding var isPresented: Bool

    func makeNSViewController(context: Context) -> NSViewController {
        NSViewController()
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        guard isPresented else { return }
        guard let service = NSSharingService(named: .cloudSharing) else {
            isPresented = false
            return
        }
        service.delegate = context.coordinator
        service.perform(withItems: [share])
        DispatchQueue.main.async { isPresented = false }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(container: container, libraryName: libraryName)
    }

    /// The share's own `CKShare.SystemFieldKey.title` (set in `SharingService.createShare`) is
    /// what the system sheet displays — unlike `UICloudSharingController`, this delegate has no
    /// separate `itemTitle`-style hook to override it, so `libraryName` isn't actually consulted
    /// here; kept as a stored property anyway so both platforms' `Coordinator` share the same
    /// initializer shape.
    final class Coordinator: NSObject, NSCloudSharingServiceDelegate {
        private let container: CKContainer
        private let libraryName: String

        init(container: CKContainer, libraryName: String) {
            self.container = container
            self.libraryName = libraryName
        }

        func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
            Log.logger(.sync).error("Failed to save share: \(error.localizedDescription)")
        }
    }

}
#endif
