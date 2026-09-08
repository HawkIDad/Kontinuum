// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  AppCommands.swift
//  NoteBytez
//

import Foundation

/// Bridges `NoteBytezApp`'s menu-bar `.commands {}` — declared at the `App` level, with no
/// access to `ContentView`'s navigation state — to the views that actually act on them.
extension Notification.Name {

    static let noteBytezNewNote = Notification.Name("noteBytezNewNote")
    static let noteBytezOpenSettings = Notification.Name("noteBytezOpenSettings")

    /// ⌘P — opens the Command Palette (Decision 6). Global, reachable from any screen.
    static let noteBytezOpenCommandPalette = Notification.Name("noteBytezOpenCommandPalette")

    /// ⌘O — opens the Quick Switcher (note-title jump). Repurposed from its MVP role of
    /// navigating to the Search *destination*, which the palette now covers instead.
    static let noteBytezOpenQuickSwitcher = Notification.Name("noteBytezOpenQuickSwitcher")

    /// Posted by `CommandPaletteViewModel`'s action callback (wired in `ContentView`) with an
    /// `AppAction` as the notification's `object`, so any screen can react to a primary action
    /// chosen from the palette the same way it already reacts to a menu-bar command.
    static let noteBytezRunAction = Notification.Name("noteBytezRunAction")

    /// Posted by the menu-bar "View" `CommandMenu` (Decision 2, Phase 2.6) with an
    /// `AppDestination` as the notification's `object`.
    static let noteBytezNavigate = Notification.Name("noteBytezNavigate")

    /// Destination-local triggers a palette `AppAction` navigates to before firing — each
    /// screen owns the sheet/state the action ultimately opens, same shape as the toolbar
    /// button that already does the same thing in place.
    static let noteBytezTriggerNewNotebook = Notification.Name("noteBytezTriggerNewNotebook")
    static let noteBytezTriggerNewCanvasBoard = Notification.Name("noteBytezTriggerNewCanvasBoard")
    static let noteBytezTriggerPromote = Notification.Name("noteBytezTriggerPromote")

    /// C7 (`NoteBytez20260829v2-Enhancements.md`, Workstream C): "Bind current canvas to a note"
    /// — the user is already on `CanvasBoardView`, so this just opens that screen's own bind
    /// picker in place, same shape as `noteBytezTriggerNewCanvasBoard`.
    static let noteBytezTriggerBindCanvas = Notification.Name("noteBytezTriggerBindCanvas")

    /// Posted by `DocumentView`/`TodayJournalView` on appear (with the `Document` as `object`)
    /// and disappear (`object: nil`), so `ContentView` knows whether "Send current note's map
    /// to Canvas" (Decision 4, Phase 5.5) has a document to act on.
    static let noteBytezActiveDocumentChanged = Notification.Name("noteBytezActiveDocumentChanged")

    /// Same shape as `noteBytezActiveDocumentChanged`, posted by `CanvasBoardView` — lets
    /// `ContentView` know whether "Bind current canvas to a note" (C7) has a board to act on.
    static let noteBytezActiveCanvasBoardChanged = Notification.Name("noteBytezActiveCanvasBoardChanged")

}
