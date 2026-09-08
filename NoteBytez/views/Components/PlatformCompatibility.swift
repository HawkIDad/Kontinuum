// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PlatformCompatibility.swift
//  NoteBytez
//

import SwiftUI

/// Cross-platform stand-ins for iOS/iPadOS-only APIs used throughout `views/` — defined once
/// here rather than repeating `#if os()` at every call site. See
/// Docs/Plans/NoteBytez-MacImplementation.md Phase 3.
extension View {

    /// Stands in for `.navigationBarTitleDisplayMode(.inline)`, which doesn't exist on macOS —
    /// a no-op there, since the Mac title bar has no equivalent display-mode concept.
    @ViewBuilder
    func noteBytezInlineNavigationTitle() -> some View {
#if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
#else
        self
#endif
    }

}

extension Color {

    /// Stands in for `Color(.secondarySystemBackground)`, a `UIColor`-bridged initializer with
    /// no macOS equivalent — `NSColor.controlBackgroundColor` is the closest semantic match.
    static var noteBytezSecondarySurface: Color {
#if os(iOS)
        Color(.secondarySystemBackground)
#else
        Color(nsColor: .controlBackgroundColor)
#endif
    }

}
