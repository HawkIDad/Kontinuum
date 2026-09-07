// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  AttachmentDAL.swift
//  Kontinuum
//

import Foundation
import SwiftData

enum AttachmentDAL {

    static func fetchActive(documentId: UUID, in context: ModelContext) -> [Attachment] {
        let predicate = #Predicate<Attachment> { $0.documentId == documentId && $0.isActive == true }
        let descriptor = FetchDescriptor<Attachment>(predicate: predicate, sortBy: [SortDescriptor(\.createdOn)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Every active attachment across the whole library, joined through `Document` — `Attachment`
    /// carries no `libraryId` of its own, same shape as `Block`, and `BlockDAL.fetchActive
    /// (libraryId:in:)` already set this exact join precedent. Added for Phase 9's Canvas media
    /// card picker, which browses attachments across the library rather than one document at a
    /// time.
    static func fetchActive(libraryId: UUID, in context: ModelContext) -> [Attachment] {
        let documentIds = Set(DocumentDAL.fetchActive(libraryId: libraryId, in: context).compactMap { $0.documentId })
        guard !documentIds.isEmpty else { return [] }

        let predicate = #Predicate<Attachment> { $0.isActive == true }
        let all = (try? context.fetch(FetchDescriptor<Attachment>(predicate: predicate))) ?? []
        return all.filter { documentIds.contains($0.documentId ?? UUID()) }
    }

    /// Copies `fileURL`'s bytes into the app's iCloud ubiquity container (via
    /// `AttachmentStorage`), creates the `Attachment` row, and appends the `![altText](fileName)`
    /// embed line to `content` (via `AttachmentParser.applying`) — the DAL owns the file copy;
    /// the caller (`DocumentViewModel`) is responsible for persisting the returned content back
    /// onto the `Document` and saving, the same division `setPropertyValue` already uses.
    /// `containerRoot` defaults to the real ubiquity container and is overridable for tests.
    @discardableResult
    static func attach(fileURL: URL, mimeType: String, documentId: UUID, content: String, in context: ModelContext, containerRoot: URL? = AttachmentStorage.containerRoot()) throws -> (attachment: Attachment, content: String) {
        guard let containerRoot else { throw AttachmentStorageError.iCloudUnavailable }

        let fileName = uniqueFileName(for: fileURL.lastPathComponent, documentId: documentId, in: context)
        let attachmentId = UUID()
        let relativePath = try AttachmentStorage.copyIntoContainer(sourceURL: fileURL, documentId: documentId, attachmentId: attachmentId, fileName: fileName, containerRoot: containerRoot)

        let attachment = Attachment(documentId: documentId, fileName: fileName, relativePath: relativePath, mimeType: mimeType)
        attachment.attachmentId = attachmentId
        context.insert(attachment)
        SyncEngine.shared.recordChanged(attachment, in: context)

        let updatedContent = AttachmentParser.applying(fileName: fileName, altText: fileName, to: content)
        return (attachment, updatedContent)
    }

    /// Reconstructs an attachment's on-disk location, or `nil` if iCloud is currently
    /// unavailable or the row has no stored path.
    static func resolveLocalURL(_ attachment: Attachment, containerRoot: URL? = AttachmentStorage.containerRoot()) -> URL? {
        guard let containerRoot, let relativePath = attachment.relativePath else { return nil }
        return AttachmentStorage.resolve(relativePath: relativePath, containerRoot: containerRoot)
    }

    /// Soft-deletes the row only — the underlying file is left in place, matching the app's
    /// no-physical-deletes rule (`ARCHITECTURE.md`).
    static func remove(_ attachment: Attachment, in context: ModelContext) {
        attachment.isActive = false
        attachment.updatedOn = Date()
        SyncEngine.shared.recordChanged(attachment, in: context)
    }

    /// Re-parses `content` for its `![alt](fileName)` embed lines and reconciles `Attachment`
    /// rows against them: any active attachment whose embed line is no longer present in
    /// `content` is soft-deleted. Content is the single source of truth, the same reconcile-on-
    /// save shape `TagDAL.syncTags`/`PropertyDAL.syncProperties` already establish.
    @discardableResult
    static func syncAttachments(for documentId: UUID, content: String, in context: ModelContext) -> [Attachment] {
        let referenced = Set(AttachmentParser.referencedFileNames(in: content))
        let active = fetchActive(documentId: documentId, in: context)

        for attachment in active {
            guard let fileName = attachment.fileName, !referenced.contains(fileName) else { continue }
            attachment.isActive = false
            attachment.updatedOn = Date()
            SyncEngine.shared.recordChanged(attachment, in: context)
        }

        return active.filter { attachment in
            guard let fileName = attachment.fileName else { return false }
            return referenced.contains(fileName)
        }
    }

    /// Finder-style collision handling: `harbor.jpg`, then `harbor-2.jpg`, `harbor-3.jpg`, ...
    /// against this document's other active attachments — two different files with the same
    /// original name must not collide in `AttachmentParser`'s by-fileName matching.
    private static func uniqueFileName(for fileName: String, documentId: UUID, in context: ModelContext) -> String {
        let existingNames = Set(fetchActive(documentId: documentId, in: context).compactMap { $0.fileName })
        guard existingNames.contains(fileName) else { return fileName }

        let nsFileName = fileName as NSString
        let baseName = nsFileName.deletingPathExtension
        let extensionName = nsFileName.pathExtension

        var suffix = 2
        while true {
            let candidate = extensionName.isEmpty ? "\(baseName)-\(suffix)" : "\(baseName)-\(suffix).\(extensionName)"
            if !existingNames.contains(candidate) { return candidate }
            suffix += 1
        }
    }

}
