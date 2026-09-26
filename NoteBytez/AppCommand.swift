// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  AppCommand.swift
//  NoteBytez
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

/// A command an enabled plugin registered via `noteBytez.addCommand(name)`. Plain `Sendable`
/// values (not a live `Plugin` model) so the palette can hold and route them off `MainActor`.
struct PluginCommand: Equatable, Hashable, Sendable {

    let pluginId: UUID
    let pluginName: String
    let commandName: String

}

/// One entry in the Command Palette: a jump to an `AppDestination`, a primary `AppAction`, or a
/// plugin-registered command. Manually `CaseIterable` (an associated-value enum can't derive
/// it) — `allCases` is every destination followed by the fixed action set; plugin commands are
/// dynamic (per installed plugin), so `CommandPaletteViewModel` appends them at load time. This
/// reverses Decision 6's "no plugin surface" — see `NoteBytez20260924v1-PluginCommands.md`.
enum AppCommand: CaseIterable, Identifiable {

    case navigate(AppDestination)
    case action(AppAction)
    case plugin(PluginCommand)

    static var allCases: [AppCommand] {
        AppDestination.allCases.map(AppCommand.navigate) + AppAction.allCases.map(AppCommand.action)
    }

    var id: String {
        switch self {
        case .navigate(let destination): return "navigate.\(destination.rawValue)"
        case .action(let action): return "action.\(action.rawValue)"
        case .plugin(let command): return "plugin.\(command.pluginId.uuidString).\(command.commandName)"
        }
    }

    var title: String {
        switch self {
        case .navigate(let destination): return destination.rawValue
        case .action(let action): return action.title
        case .plugin(let command): return "\(command.pluginName): \(command.commandName)"
        }
    }

    var systemImage: String {
        switch self {
        case .navigate(let destination): return destination.systemImage
        case .action(let action): return action.systemImage
        case .plugin: return "puzzlepiece.extension"
        }
    }

    /// Reuses `WikilinkParser.fuzzyMatches` rather than a second fuzzy implementation, per every
    /// prior phase's rule (see `NoteBytez20260827v1-Anchors.md`).
    func matches(query: String) -> Bool {
        WikilinkParser.fuzzyMatches(title, query: query)
    }

}
