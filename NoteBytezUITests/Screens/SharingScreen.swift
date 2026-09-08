// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SharingScreen.swift
//  NoteBytezUITests
//

import XCTest

/// S22 — Sharing / Participants. Reached from Settings → "Sharing". Without a live CloudKit
/// share (no signed-in test account here — see Phase 0.a), this always renders the
/// "Not Shared" empty state, which is enough to confirm the screen itself renders correctly.
struct SharingParticipantsScreen {

    let app: XCUIApplication

    var doneButton: XCUIElement { app.button(labeled: "Done") }
    var invited: XCUIElement { app.button(labeled: "Invite Participant") }
    var notSharedEmptyState: XCUIElement { app.element(labeledContaining: "Not Shared") }

}
