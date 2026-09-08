// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SecondaryButton.swift
//  NoteBytez
//

import SwiftUI

/// Bordered/plain button for cancel or lower-emphasis actions, per docs/styleGuide.md.
struct SecondaryButton: View {

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

}
