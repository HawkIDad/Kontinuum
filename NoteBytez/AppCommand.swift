// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  AppCommand.swift
//  Kontinuum
//

import Foundation

/// The Command Palette's fixed primary-action set (Decision 6) — a static registry, not a
/// plugin surface. Each case is wired to existing app plumbing (a `NotificationCenter` post or
/// a direct `SyncEngine` call) rather than new capability of its own.
enum AppAction: String, CaseIterable, Identifiable {

    case newNote
    case newNotebook
    case newCanvasBoard
    case promoteToNotebook
    case sendCurrentNoteToCanvas
    case syncNow
    case importMarkdown
    case openSettings
    case bindCurrentCanvasToNote
    case openNoteAsBoundCanvas

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newNote: return "New Note"
        case .newNotebook: return "New Notebook"
        case .newCanvasBoard: return "New Canvas Board"
        case .promoteToNotebook: return "Promote to Notebook"
        case .sendCurrentNoteToCanvas: return "Send Note's Map to Canvas"
        case .syncNow: return "Sync Now"
        case .importMarkdown: return "Import Markdown…"
        case .openSettings: return "Open Settings"
        case .bindCurrentCanvasToNote: return "Bind Current Canvas to a Note"
        case .openNoteAsBoundCanvas: return "Open Note as Bound Canvas"
        }
    }

    var systemImage: String {
        switch self {
        case .newNote: return "square.and.pencil"
        case .newNotebook: return "books.vertical"
        case .newCanvasBoard: return "square.grid.2x2"
        case .promoteToNotebook: return "arrow.up.forward.app"
        case .sendCurrentNoteToCanvas: return "point.3.connected.trianglepath.dotted"
        case .syncNow: return "arrow.triangle.2.circlepath"
        case .importMarkdown: return "square.and.arrow.down"
        case .openSettings: return "gearshape"
        case .bindCurrentCanvasToNote: return "link.badge.plus"
        case .openNoteAsBoundCanvas: return "link.circle"
        }
    }

}

/// One entry in the Command Palette: either a jump to an `AppDestination` or a primary
/// `AppAction`. Manually `CaseIterable` (an associated-value enum can't derive it) — `allCases`
/// is every destination followed by the fixed action set, matching Decision 6's "static
/// registry, no plugin surface."
enum AppCommand: CaseIterable, Identifiable {

    case navigate(AppDestination)
    case action(AppAction)

    static var allCases: [AppCommand] {
        AppDestination.allCases.map(AppCommand.navigate) + AppAction.allCases.map(AppCommand.action)
    }

    var id: String {
        switch self {
        case .navigate(let destination): return "navigate.\(destination.rawValue)"
        case .action(let action): return "action.\(action.rawValue)"
        }
    }

    var title: String {
        switch self {
        case .navigate(let destination): return destination.rawValue
        case .action(let action): return action.title
        }
    }

    var systemImage: String {
        switch self {
        case .navigate(let destination): return destination.systemImage
        case .action(let action): return action.systemImage
        }
    }

    /// Reuses `WikilinkParser.fuzzyMatches` rather than a second fuzzy implementation, per every
    /// prior phase's rule (see `NoteBytez20260827v1-Anchors.md`).
    func matches(query: String) -> Bool {
        WikilinkParser.fuzzyMatches(title, query: query)
    }

}
