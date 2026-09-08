// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PropertyDAL.swift
//  NoteBytez
//

import Foundation
import SwiftData

enum PropertyDAL {

    /// A `Property` definition paired with one document's value for it — the shape most
    /// callers (the editor UI, search) actually want, rather than two separate fetches.
    struct ResolvedProperty: Identifiable {
        let property: Property
        let value: String
        var id: UUID { property.propertyId ?? UUID() }
    }

    static func fetchActive(libraryId: UUID, in context: ModelContext) -> [Property] {
        let predicate = #Predicate<Property> { $0.libraryId == libraryId && $0.isActive == true }
        let descriptor = FetchDescriptor<Property>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Unlike `TagDAL.findOrCreate`, matches by exact (not canonicalized) name — a Property
    /// name is typed once via a Note Template or the Properties editor, not retyped inline
    /// per Decisions Log #1's reasoning for `Property.name` itself.
    static func findOrCreate(name: String, valueType: PropertyValueType, libraryId: UUID, in context: ModelContext) -> Property {
        if let existing = fetchActive(libraryId: libraryId, in: context).first(where: { $0.name == name }) {
            return existing
        }
        let property = Property(name: name, valueType: valueType, libraryId: libraryId)
        context.insert(property)
        SyncEngine.shared.recordChanged(property, in: context)
        return property
    }

    static func rename(_ property: Property, to newName: String, in context: ModelContext) {
        property.name = newName
        property.updatedOn = Date()
        SyncEngine.shared.recordChanged(property, in: context)
    }

    /// Soft-deletes the property definition and every document's value for it — a Property
    /// with no surviving definition shouldn't leave orphaned `DocumentProperty` rows behind.
    static func delete(_ property: Property, in context: ModelContext) {
        guard let propertyId = property.propertyId else { return }
        let predicate = #Predicate<DocumentProperty> { $0.propertyId == propertyId && $0.isActive == true }
        let values = (try? context.fetch(FetchDescriptor<DocumentProperty>(predicate: predicate))) ?? []
        for value in values {
            value.isActive = false
            value.updatedOn = Date()
            SyncEngine.shared.recordChanged(value, in: context)
        }
        property.isActive = false
        property.updatedOn = Date()
        SyncEngine.shared.recordChanged(property, in: context)
    }

    /// Sets a document's value for `key`, creating the `Property` definition on first use.
    /// The DAL-level write path — the Properties editor UI instead goes through
    /// `PropertyParser.applying` on the document's content, so a save's `syncProperties` pass
    /// (which calls this per parsed key) is content's only route back into the index. Kept
    /// as its own entry point for callers that aren't editing through content directly (a
    /// future Migration Assistant import, tests).
    @discardableResult
    static func setValue(key: String, value: String, valueType: PropertyValueType, documentId: UUID, libraryId: UUID, in context: ModelContext) -> DocumentProperty {
        let property = findOrCreate(name: key, valueType: valueType, libraryId: libraryId, in: context)
        guard let propertyId = property.propertyId else {
            let orphan = DocumentProperty(documentId: documentId, propertyId: UUID(), libraryId: libraryId, value: value, valueType: valueType)
            context.insert(orphan)
            return orphan
        }

        let predicate = #Predicate<DocumentProperty> { $0.documentId == documentId && $0.propertyId == propertyId }
        if let existing = (try? context.fetch(FetchDescriptor<DocumentProperty>(predicate: predicate)))?.first {
            existing.value = value
            existing.valueType = valueType.rawValue
            existing.isActive = true
            existing.updatedOn = Date()
            SyncEngine.shared.recordChanged(existing, in: context)
            return existing
        }

        let created = DocumentProperty(documentId: documentId, propertyId: propertyId, libraryId: libraryId, value: value, valueType: valueType)
        context.insert(created)
        SyncEngine.shared.recordChanged(created, in: context)
        return created
    }

    /// Soft-deletes a document's value for `key`, if present. Does not delete the `Property`
    /// definition itself — other documents may still use it.
    static func removeValue(key: String, documentId: UUID, libraryId: UUID, in context: ModelContext) {
        guard let property = fetchActive(libraryId: libraryId, in: context).first(where: { $0.name == key }),
              let propertyId = property.propertyId else { return }

        let predicate = #Predicate<DocumentProperty> { $0.documentId == documentId && $0.propertyId == propertyId && $0.isActive == true }
        guard let existing = (try? context.fetch(FetchDescriptor<DocumentProperty>(predicate: predicate)))?.first else { return }
        existing.isActive = false
        existing.updatedOn = Date()
        SyncEngine.shared.recordChanged(existing, in: context)
    }

    static func fetchProperties(for documentId: UUID, in context: ModelContext) -> [ResolvedProperty] {
        let predicate = #Predicate<DocumentProperty> { $0.documentId == documentId && $0.isActive == true }
        let values = (try? context.fetch(FetchDescriptor<DocumentProperty>(predicate: predicate))) ?? []
        guard let libraryId = values.first?.libraryId else { return [] }

        let propertiesById = Dictionary(uniqueKeysWithValues: fetchActive(libraryId: libraryId, in: context).compactMap { property -> (UUID, Property)? in
            guard let propertyId = property.propertyId else { return nil }
            return (propertyId, property)
        })

        return values.compactMap { value in
            guard let propertyId = value.propertyId, let property = propertiesById[propertyId] else { return nil }
            return ResolvedProperty(property: property, value: value.value ?? "")
        }
    }

    /// Re-parses `content` for its frontmatter Properties and reconciles `DocumentProperty`
    /// rows against them: every parsed key is upserted via `setValue`, and a value for a key
    /// no longer present in `content` is soft-deleted. Content is the single source of truth
    /// — the editor UI writes to it via `PropertyParser.applying` and this reconciles the
    /// index afterward, the same reconcile-on-save shape as `TagDAL.syncTags`.
    @discardableResult
    static func syncProperties(for documentId: UUID, content: String, libraryId: UUID, in context: ModelContext) -> [ResolvedProperty] {
        let parsed = PropertyParser.extractFrontmatterProperties(from: content)

        var resolved: [ResolvedProperty] = []
        var referencedNames: Set<String> = []
        for entry in parsed {
            referencedNames.insert(entry.key)
            let documentProperty = setValue(key: entry.key, value: entry.value, valueType: entry.valueType, documentId: documentId, libraryId: libraryId, in: context)
            guard let propertyId = documentProperty.propertyId,
                  let property = fetchActive(libraryId: libraryId, in: context).first(where: { $0.propertyId == propertyId }) else { continue }
            resolved.append(ResolvedProperty(property: property, value: documentProperty.value ?? ""))
        }

        let predicate = #Predicate<DocumentProperty> { $0.documentId == documentId && $0.isActive == true }
        let existingValues = (try? context.fetch(FetchDescriptor<DocumentProperty>(predicate: predicate))) ?? []
        let propertiesById = Dictionary(uniqueKeysWithValues: fetchActive(libraryId: libraryId, in: context).compactMap { property -> (UUID, Property)? in
            guard let propertyId = property.propertyId else { return nil }
            return (propertyId, property)
        })
        for existing in existingValues {
            guard let propertyId = existing.propertyId, let name = propertiesById[propertyId]?.name, !referencedNames.contains(name) else { continue }
            existing.isActive = false
            existing.updatedOn = Date()
            SyncEngine.shared.recordChanged(existing, in: context)
        }

        return resolved
    }

}
