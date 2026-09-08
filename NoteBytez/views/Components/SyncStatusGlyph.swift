// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SyncStatusGlyph.swift
//  Kontinuum
//

import SwiftUI

/// Persistent, tappable sync status indicator — per `UIUX/06-DesignSystem.md`'s sync visual
/// language: green + `arrow.triangle.2.circlepath` when synced, the same glyph spinning while
/// syncing, gray while offline, or an orange `exclamationmark.triangle` (a distinct icon, not
/// just a color change, so the state reads without relying on color alone) when there's an
/// unresolved conflict. Used in S3/S4's toolbar and again as S9's own headline icon.
struct SyncStatusGlyph: View {

    let viewModel: SyncStatusViewModel
    var action: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Image(systemName: viewModel.statusSystemImage)
                .symbolEffect(.rotate, options: .repeating, isActive: !reduceMotion && viewModel.status == .syncing)
                .foregroundStyle(tintColor)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .overlay(alignment: .topTrailing) {
                    if viewModel.isSharedLibrary {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                }
        }
        .accessibilityLabel(viewModel.isSharedLibrary ? "\(viewModel.statusHeadline), Shared Library" : viewModel.statusHeadline)
        .accessibilityIdentifier("syncStatusGlyph")
    }

    private var tintColor: Color {
        switch viewModel.statusTint {
        case .success: return .green
        case .warning: return .orange
        case .neutral: return .secondary
        }
    }

}
