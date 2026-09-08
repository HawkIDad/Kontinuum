// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  AttachmentScreen.swift
//  NoteBytezUITests
//

import XCTest

/// S20 — Attachment Preview. Full end-to-end coverage (attaching a real file via the system
/// file importer, then opening its preview) needs a driven system picker — the same
/// simulator/system-UI automation gap noted for S2/S23. This page object covers what's
/// reachable without it: confirming `DocumentScreen.addAttachmentButton` opens the importer.
struct AttachmentPreviewScreen {

    let app: XCUIApplication

    var closeButton: XCUIElement { app.button(labeled: "Close") }

}
