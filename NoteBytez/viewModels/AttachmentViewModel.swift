// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  AttachmentViewModel.swift
//  NoteBytez
//

import Foundation
import Observation

/// Backs S20's Attachment thumbnail strip atop S4's document body. Wraps a `DocumentViewModel`
/// rather than duplicating its state — mirrors `PropertyViewModel`'s own wrap of a
/// `DocumentViewModel`.
@Observable
final class AttachmentViewModel {

    private let documentViewModel: DocumentViewModel

    /// Set when the most recent `attach(fileURL:mimeType:)` failed (currently only "iCloud is
    /// unavailable") — the view surfaces this rather than silently dropping the attempt.
    var lastErrorMessage: String?

    init(documentViewModel: DocumentViewModel) {
        self.documentViewModel = documentViewModel
    }

    var attachments: [Attachment] {
        documentViewModel.attachments
    }

    func attach(fileURL: URL, mimeType: String) {
        let succeeded = documentViewModel.attach(fileURL: fileURL, mimeType: mimeType)
        lastErrorMessage = succeeded ? nil : "Couldn't attach this file — iCloud is currently unavailable."
    }

    func remove(_ attachment: Attachment) {
        documentViewModel.removeAttachment(attachment)
    }

}
