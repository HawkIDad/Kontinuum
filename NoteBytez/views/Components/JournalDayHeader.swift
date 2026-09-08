// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  JournalDayHeader.swift
//  NoteBytez
//

import SwiftUI

/// Date label + prev/next chevrons, per docs/styleGuide.md. `Next` disables at today — journal
/// navigation never moves into the future.
struct JournalDayHeader: View {

    let date: Date
    let canGoToNextDay: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel("Previous day")

            Spacer()

            Text(date.formatted(date: .complete, time: .omitted))
                .font(.headline)

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
            }
            .disabled(!canGoToNextDay)
            .accessibilityLabel("Next day")
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

}
