// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TagDAL.swift
//  NoteBytez
//

import Foundation
import SwiftData

enum TagDAL {

    static func fetchActive(libraryId: UUID, in context: ModelContext) -> [Tag] {
        let predicate = #Predicate<Tag> { $0.libraryId == libraryId && $0.isActive == true }
        let descriptor = FetchDescriptor<Tag>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    static func findOrCreate(name: String, libraryId: UUID, in context: ModelContext) -> Tag {
        let canonicalName = TagParser.canonicalize(name)
        if let existing = fetchActive(libraryId: libraryId, in: context).first(where: { $0.name == canonicalName }) {
            return existing
        }
        let tag = Tag(name: canonicalName, libraryId: libraryId)
        context.insert(tag)
        SyncEngine.shared.recordChanged(tag, in: context)
        return tag
    }

    /// Re-parses `content` for its tags and reconciles `DocumentTag` join rows against them:
    /// referenced tags are created/reused and (re)activated, join rows for tags no longer
    /// referenced are soft-deleted. Mirrors `BlockDAL.syncBlocks`'s reconcile-on-save shape.
    @discardableResult
    static func syncTags(for documentId: UUID, content: String, libraryId: UUID, in context: ModelContext) -> [Tag] {
        let names = TagParser.extractAllTags(from: content)

        var resultTags: [Tag] = []
        var referencedTagIds: Set<UUID> = []
        for name in names {
            let tag = findOrCreate(name: name, libraryId: libraryId, in: context)
            guard let tagId = tag.tagId, !referencedTagIds.contains(tagId) else { continue }
            referencedTagIds.insert(tagId)
            resultTags.append(tag)
            upsertDocumentTag(documentId: documentId, tagId: tagId, libraryId: libraryId, in: context)
        }

        let predicate = #Predicate<DocumentTag> { $0.documentId == documentId && $0.isActive == true }
        let existingJoins = (try? context.fetch(FetchDescriptor<DocumentTag>(predicate: predicate))) ?? []
        for join in existingJoins {
            guard let tagId = join.tagId, !referencedTagIds.contains(tagId) else { continue }
            join.isActive = false
            join.updatedOn = Date()
            SyncEngine.shared.recordChanged(join, in: context)
        }

        return resultTags
    }

    static func fetchTags(for documentId: UUID, in context: ModelContext) -> [Tag] {
        let predicate = #Predicate<DocumentTag> { $0.documentId == documentId && $0.isActive == true }
        let joins = (try? context.fetch(FetchDescriptor<DocumentTag>(predicate: predicate))) ?? []
        guard let libraryId = joins.first?.libraryId else { return [] }

        let tagIds = Set(joins.compactMap { $0.tagId })
        return fetchActive(libraryId: libraryId, in: context).filter { tag in
            guard let tagId = tag.tagId else { return false }
            return tagIds.contains(tagId)
        }
    }

    static func fetchDocuments(for tag: Tag, in context: ModelContext) -> [Document] {
        guard let tagId = tag.tagId, let libraryId = tag.libraryId else { return [] }

        let predicate = #Predicate<DocumentTag> { $0.tagId == tagId && $0.isActive == true }
        let joins = (try? context.fetch(FetchDescriptor<DocumentTag>(predicate: predicate))) ?? []
        let documentIds = Set(joins.compactMap { $0.documentId })

        return DocumentDAL.fetchActive(libraryId: libraryId, in: context).filter { document in
            guard let documentId = document.documentId else { return false }
            return documentIds.contains(documentId)
        }
    }

    /// App-level dedupe for tags that end up with the same canonical name after a CloudKit
    /// sync merge (CloudKit disallows `.unique`, so two devices can independently create the
    /// "same" tag offline). For each duplicate name, keeps the first tag found as the
    /// survivor, re-points every other duplicate's `DocumentTag` joins onto it, and
    /// soft-deletes the duplicate. Called locally today (findOrCreate already prevents new
    /// duplicates within one context); Phase 11's sync engine will call this after a merge.
    @discardableResult
    static func mergeDuplicates(libraryId: UUID, in context: ModelContext) -> [Tag] {
        var survivorByName: [String: Tag] = [:]
        var survivors: [Tag] = []

        for tag in fetchActive(libraryId: libraryId, in: context) {
            guard let name = tag.name else { continue }
            if let survivor = survivorByName[name] {
                mergeDuplicate(tag, into: survivor, in: context)
            } else {
                survivorByName[name] = tag
                survivors.append(tag)
            }
        }
        return survivors
    }

    private static func mergeDuplicate(_ duplicate: Tag, into survivor: Tag, in context: ModelContext) {
        guard let duplicateId = duplicate.tagId, let survivorId = survivor.tagId else { return }

        let predicate = #Predicate<DocumentTag> { $0.tagId == duplicateId && $0.isActive == true }
        let joins = (try? context.fetch(FetchDescriptor<DocumentTag>(predicate: predicate))) ?? []
        for join in joins {
            join.tagId = survivorId
            join.updatedOn = Date()
            SyncEngine.shared.recordChanged(join, in: context)
        }

        duplicate.isActive = false
        duplicate.updatedOn = Date()
        SyncEngine.shared.recordChanged(duplicate, in: context)
    }

    private static func upsertDocumentTag(documentId: UUID, tagId: UUID, libraryId: UUID, in context: ModelContext) {
        let predicate = #Predicate<DocumentTag> { $0.documentId == documentId && $0.tagId == tagId }
        let descriptor = FetchDescriptor<DocumentTag>(predicate: predicate)
        if let existing = (try? context.fetch(descriptor))?.first {
            if existing.isActive != true {
                existing.isActive = true
                existing.updatedOn = Date()
                SyncEngine.shared.recordChanged(existing, in: context)
            }
            return
        }
        let join = DocumentTag(documentId: documentId, tagId: tagId, libraryId: libraryId)
        context.insert(join)
        SyncEngine.shared.recordChanged(join, in: context)
    }

}
