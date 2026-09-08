// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PropertyDALTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

struct PropertyDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Property.self, DocumentProperty.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func findOrCreateReusesAnExistingPropertyByExactName() throws {
        let context = try makeContext()
        let libraryId = UUID()

        let first = PropertyDAL.findOrCreate(name: "Species", valueType: .text, libraryId: libraryId, in: context)
        let second = PropertyDAL.findOrCreate(name: "Species", valueType: .text, libraryId: libraryId, in: context)

        #expect(first.propertyId == second.propertyId)
        #expect(PropertyDAL.fetchActive(libraryId: libraryId, in: context).count == 1)
    }

    @Test func setValueCreatesTheDefinitionAndTheDocumentsValueTogether() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Elyra Voss", content: "", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)

        PropertyDAL.setValue(key: "Species", value: "Kethran", valueType: .text, documentId: documentId, libraryId: libraryId, in: context)

        let resolved = PropertyDAL.fetchProperties(for: documentId, in: context)
        #expect(resolved.count == 1)
        #expect(resolved.first?.property.name == "Species")
        #expect(resolved.first?.value == "Kethran")
    }

    @Test func setValueUpdatesInPlaceRatherThanDuplicating() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Elyra Voss", content: "", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)

        PropertyDAL.setValue(key: "Species", value: "Kethran", valueType: .text, documentId: documentId, libraryId: libraryId, in: context)
        PropertyDAL.setValue(key: "Species", value: "Human", valueType: .text, documentId: documentId, libraryId: libraryId, in: context)

        let resolved = PropertyDAL.fetchProperties(for: documentId, in: context)
        #expect(resolved.count == 1)
        #expect(resolved.first?.value == "Human")
    }

    @Test func removeValueSoftDeletesOnlyThatDocumentsValue() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let noteOne = DocumentDAL.create(title: "One", content: "", libraryId: libraryId, in: context)
        let noteTwo = DocumentDAL.create(title: "Two", content: "", libraryId: libraryId, in: context)
        let noteOneId = try #require(noteOne.documentId)
        let noteTwoId = try #require(noteTwo.documentId)

        PropertyDAL.setValue(key: "Species", value: "Kethran", valueType: .text, documentId: noteOneId, libraryId: libraryId, in: context)
        PropertyDAL.setValue(key: "Species", value: "Human", valueType: .text, documentId: noteTwoId, libraryId: libraryId, in: context)

        PropertyDAL.removeValue(key: "Species", documentId: noteOneId, libraryId: libraryId, in: context)

        #expect(PropertyDAL.fetchProperties(for: noteOneId, in: context).isEmpty)
        #expect(PropertyDAL.fetchProperties(for: noteTwoId, in: context).count == 1)
        // The definition itself survives — Two still uses it.
        #expect(PropertyDAL.fetchActive(libraryId: libraryId, in: context).count == 1)
    }

    @Test func deleteSoftDeletesTheDefinitionAndEveryDocumentsValueForIt() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let noteOne = DocumentDAL.create(title: "One", content: "", libraryId: libraryId, in: context)
        let noteTwo = DocumentDAL.create(title: "Two", content: "", libraryId: libraryId, in: context)
        let noteOneId = try #require(noteOne.documentId)
        let noteTwoId = try #require(noteTwo.documentId)

        let property = PropertyDAL.findOrCreate(name: "Species", valueType: .text, libraryId: libraryId, in: context)
        PropertyDAL.setValue(key: "Species", value: "Kethran", valueType: .text, documentId: noteOneId, libraryId: libraryId, in: context)
        PropertyDAL.setValue(key: "Species", value: "Human", valueType: .text, documentId: noteTwoId, libraryId: libraryId, in: context)

        PropertyDAL.delete(property, in: context)

        #expect(PropertyDAL.fetchActive(libraryId: libraryId, in: context).isEmpty)
        #expect(PropertyDAL.fetchProperties(for: noteOneId, in: context).isEmpty)
        #expect(PropertyDAL.fetchProperties(for: noteTwoId, in: context).isEmpty)
    }

    @Test func renameUpdatesTheDefinitionsNameForEveryDocumentUsingIt() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Elyra Voss", content: "", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let property = PropertyDAL.findOrCreate(name: "Species", valueType: .text, libraryId: libraryId, in: context)
        PropertyDAL.setValue(key: "Species", value: "Kethran", valueType: .text, documentId: documentId, libraryId: libraryId, in: context)

        PropertyDAL.rename(property, to: "Homeworld Species", in: context)

        #expect(PropertyDAL.fetchProperties(for: documentId, in: context).first?.property.name == "Homeworld Species")
    }

    @Test func syncPropertiesCreatesValuesFromFrontmatter() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Elyra Voss", content: "---\nSpecies: Kethran\nAge: 34\n---\nBackstory.", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)

        let resolved = PropertyDAL.syncProperties(for: documentId, content: try #require(document.content), libraryId: libraryId, in: context)

        #expect(resolved.count == 2)
        #expect(Set(resolved.map { $0.property.name ?? "" }) == ["Species", "Age"])
    }

    @Test func syncPropertiesRemovesAValueForAKeyNoLongerInFrontmatter() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Elyra Voss", content: "---\nSpecies: Kethran\nAge: 34\n---\n", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)

        PropertyDAL.syncProperties(for: documentId, content: try #require(document.content), libraryId: libraryId, in: context)
        #expect(PropertyDAL.fetchProperties(for: documentId, in: context).count == 2)

        let updatedContent = "---\nSpecies: Kethran\n---\n"
        PropertyDAL.syncProperties(for: documentId, content: updatedContent, libraryId: libraryId, in: context)

        let remaining = PropertyDAL.fetchProperties(for: documentId, in: context)
        #expect(remaining.count == 1)
        #expect(remaining.first?.property.name == "Species")
    }

    @Test func syncPropertiesIsIdempotentAcrossRepeatedSavesWithUnchangedContent() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Elyra Voss", content: "---\nSpecies: Kethran\n---\n", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)

        PropertyDAL.syncProperties(for: documentId, content: try #require(document.content), libraryId: libraryId, in: context)
        PropertyDAL.syncProperties(for: documentId, content: try #require(document.content), libraryId: libraryId, in: context)

        #expect(PropertyDAL.fetchActive(libraryId: libraryId, in: context).count == 1)
        #expect(PropertyDAL.fetchProperties(for: documentId, in: context).count == 1)
    }

}
