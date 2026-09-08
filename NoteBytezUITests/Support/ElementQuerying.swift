// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ElementQuerying.swift
//  KontinuumUITests
//

import XCTest

/// Shared lookup helpers for elements that carry no explicit `.accessibilityIdentifier` — most
/// stock `Button`/`Text` elements in this codebase, which only `PrimaryButton`, the sidebar/tab
/// bar rows, and a handful of other controls (see `SyncStatusGlyph`) set one for. Falls back to
/// matching on `label`, the same convention `KontinuumUITests.swift`'s own foundation test
/// already established for "Search" before any page objects existed.
extension XCUIApplication {

    /// Any element (button, staticText, or otherwise) whose accessibility label exactly matches.
    func element(labeled label: String) -> XCUIElement {
        descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    /// Any element whose accessibility label contains the given substring — for elements whose
    /// full label is a combined accessibility tree (e.g. `ConflictVersionCard`'s
    /// `.accessibilityElement(children: .combine)`), where an exact match is impractical.
    func element(labeledContaining substring: String) -> XCUIElement {
        descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", substring)).firstMatch
    }

    /// A tappable button: prefers an identifier match (this codebase's own controls, e.g.
    /// `PrimaryButton`), falling back to a label match for stock `Button("X")`s. Always
    /// resolved via `.firstMatch` — `buttons[label]`'s plain subscript form can report
    /// `.exists == true` against more than one match (e.g. a `List` row's `NavigationLink`
    /// sometimes surfaces two identically-labeled accessibility elements for the same row) and
    /// then fail to resolve at all on `.tap()`, so it's never returned directly.
    func button(labeled label: String) -> XCUIElement {
        let byIdentifier = buttons.matching(NSPredicate(format: "identifier == %@", label)).firstMatch
        if byIdentifier.exists { return byIdentifier }
        return descendants(matching: .button).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    /// A `ContentView` sidebar row (Mac/iPad or landscape-regular-width iPhone only) by its
    /// destination name. Scoped to `.staticText`, not the bare identifier subscript over `.any`:
    /// the `Label`'s icon and text both inherit the row's `.accessibilityIdentifier`, so an
    /// unscoped query matches two elements — and even picking `.firstMatch` from those risks
    /// landing on the icon `Image`, which reports `.exists == true` but fails `.tap()` as "not
    /// hittable". The text element is always the reliably-hittable one.
    func sidebarRow(_ destination: String) -> XCUIElement {
        staticTexts.matching(NSPredicate(format: "identifier == %@", "sidebar.\(destination)")).firstMatch
    }

    /// Resigns keyboard focus after typing into a field on a screen that stays put afterward
    /// (an inline "New X" row in a `List`, e.g. `TemplateGroupListView`) — a plain tap
    /// elsewhere on such a screen doesn't reliably resign a `Form`/`List` `TextField`'s focus,
    /// confirmed repeatedly: the very next tap (a list row, a tab bar item) silently no-ops
    /// while the keyboard is still up, rather than hitting what's underneath it.
    func dismissKeyboard() {
        let returnKey = keyboards.buttons["return"]
        if returnKey.exists { returnKey.tap() }
    }

    /// Dismisses a `.sheet` that has no explicit Cancel/Done control (`BacklinksPaneView`,
    /// `GraphView`, `SyncStatusView`, `TaskDashboardView`) by dragging down from very near the
    /// top of the screen. Plain `app.swipeDown()` starts its drag inside the sheet's own
    /// content area when that content is a `List`/`ScrollView` already at the top — iOS then
    /// treats it as a scroll-position rubber-band, not an interactive dismiss, and the sheet
    /// stays put. Starting the drag above the content (right below the status bar, on the
    /// sheet's own drag-handle area) reliably triggers the system dismiss instead.
    func dismissSheetByDragging() {
        // Empirically, a drag starting inside the status bar (roughly the top 5% of the
        // screen) doesn't register as a sheet-dismiss gesture at all — it has to start right
        // at the sheet's own top edge/grabber area, just below the status bar.
        let start = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08))
        let end = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

}
