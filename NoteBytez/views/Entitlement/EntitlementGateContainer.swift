// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  EntitlementGateContainer.swift
//  Kontinuum
//

import SwiftUI
import Combine

/// Wraps the whole app UI and swaps it for a paywall / blocked screen when the entitlement gate
/// says so (NoteBytez20260907v1-Security.md Phase 4). `RootView` renders
/// `EntitlementGateContainer { <real content> }`.
struct EntitlementGateContainer<Content: View>: View {

    @State private var viewModel: EntitlementGateViewModel
    private let content: () -> Content

    @Environment(\.scenePhase) private var scenePhase

    /// Re-checks entitlement on a slow foreground cadence — `Transaction.updates` and the
    /// scene-phase change cover the important cases; this catches a subscription that simply
    /// expired while the app sat open.
    private let refreshTimer = Timer.publish(every: 6 * 60 * 60, on: .main, in: .common).autoconnect()

    init(
        viewModel: EntitlementGateViewModel,
        @ViewBuilder content: @escaping () -> Content
    ) {
        _viewModel = State(initialValue: viewModel)
        self.content = content
    }

    var body: some View {
        Group {
            if !viewModel.hasEvaluated {
                ProgressView()
                    .controlSize(.large)
            } else {
                switch viewModel.accessLevel {
                case .full:
                    content()

                case .warning(let daysRemaining):
                    content()
                        .safeAreaInset(edge: .top, spacing: 0) {
                            LapsedBanner(daysRemaining: daysRemaining) {
                                Task { await viewModel.evaluate() }
                            }
                        }

                case .blocked(let reason):
                    blockedSurface(for: reason)
                }
            }
        }
        .task { viewModel.startObserving() }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task { await viewModel.evaluate() }
        }
        .onReceive(refreshTimer) { _ in
            Task { await viewModel.evaluate() }
        }
    }

    @ViewBuilder
    private func blockedSurface(for reason: BlockReason) -> some View {
        switch reason {
        case .neverSubscribed:
            PaywallView(onEntitled: { Task { await viewModel.evaluate() } })
        case .provenanceFailed, .subscriptionLapsed, .offlineTooLong:
            BlockedView(reason: reason, onResolved: { Task { await viewModel.evaluate() } })
        }
    }
}
