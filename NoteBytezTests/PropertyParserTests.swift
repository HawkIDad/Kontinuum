// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PropertyParserTests.swift
//  NoteBytezTests
//

import Testing
@testable import NoteBytez

struct PropertyParserTests {

    // MARK: - extractFrontmatterProperties: type inference

    @Test func extractFrontmatterPropertiesInfersText() {
        let content = "---\nSpecies: Kethran\n---\nBody."
        let properties = PropertyParser.extractFrontmatterProperties(from: content)
        #expect(properties.count == 1)
        #expect(properties.first?.key == "Species")
        #expect(properties.first?.value == "Kethran")
        #expect(properties.first?.valueType == .text)
    }

    @Test func extractFrontmatterPropertiesInfersNumber() {
        let content = "---\nAge: 34\n---\nBody."
        let properties = PropertyParser.extractFrontmatterProperties(from: content)
        #expect(properties.first?.value == "34")
        #expect(properties.first?.valueType == .number)
    }

    @Test func extractFrontmatterPropertiesInfersCheckbox() {
        let content = "---\nAlive: true\n---\nBody."
        let properties = PropertyParser.extractFrontmatterProperties(from: content)
        #expect(properties.first?.value == "true")
        #expect(properties.first?.valueType == .checkbox)
    }

    @Test func extractFrontmatterPropertiesInfersDate() {
        let content = "---\nBirthdate: 2026-08-20\n---\nBody."
        let properties = PropertyParser.extractFrontmatterProperties(from: content)
        #expect(properties.first?.value == "2026-08-20")
        #expect(properties.first?.valueType == .date)
    }

    @Test func extractFrontmatterPropertiesInfersFlowList() {
        let content = "---\nAliases: [\"Elyra\", \"The Voss\"]\n---\nBody."
        let properties = PropertyParser.extractFrontmatterProperties(from: content)
        #expect(properties.first?.value == "Elyra; The Voss")
        #expect(properties.first?.valueType == .list)
    }

    @Test func extractFrontmatterPropertiesInfersBlockList() {
        let content = "---\nAliases:\n  - Elyra\n  - The Voss\n---\nBody."
        let properties = PropertyParser.extractFrontmatterProperties(from: content)
        #expect(properties.first?.value == "Elyra; The Voss")
        #expect(properties.first?.valueType == .list)
    }

    // MARK: - Reserved keys

    @Test func extractFrontmatterPropertiesExcludesTagsAndNotebooks() {
        let content = "---\ntags: [roadmap]\nnotebooks: [Fiction]\nSpecies: Kethran\n---\nBody."
        let properties = PropertyParser.extractFrontmatterProperties(from: content)
        #expect(properties.count == 1)
        #expect(properties.first?.key == "Species")
    }

    // MARK: - Multiple properties, no frontmatter

    @Test func extractFrontmatterPropertiesReturnsEveryNonReservedKey() {
        let content = "---\nSpecies: Kethran\nHomeworld: Kethra Prime\n---\nBody."
        let properties = PropertyParser.extractFrontmatterProperties(from: content)
        #expect(Set(properties.map { $0.key }) == ["Species", "Homeworld"])
    }

    @Test func extractFrontmatterPropertiesReturnsEmptyWithNoFrontmatter() {
        #expect(PropertyParser.extractFrontmatterProperties(from: "Just body text.").isEmpty)
    }

    // MARK: - applying: write/replace a single key

    @Test func applyingAddsAKeyToExistingFrontmatterWithoutDisturbingOtherLines() {
        let content = "---\ntags: [roadmap]\nSpecies: Kethran\n---\nBody."
        let updated = PropertyParser.applying(key: "Homeworld", value: "Kethra Prime", valueType: .text, to: content)

        #expect(updated.contains("tags: [roadmap]"))
        #expect(updated.contains("Species: Kethran"))
        #expect(updated.contains("Homeworld: \"Kethra Prime\""))
        #expect(updated.contains("Body."))
    }

    @Test func applyingReplacesAnExistingKeyRatherThanDuplicatingIt() {
        let content = "---\nSpecies: \"Kethran\"\n---\nBody."
        let updated = PropertyParser.applying(key: "Species", value: "Human", valueType: .text, to: content)

        let properties = PropertyParser.extractFrontmatterProperties(from: updated)
        #expect(properties.count == 1)
        #expect(properties.first?.value == "Human")
    }

    @Test func applyingCreatesAFrontmatterBlockWhenNoneExists() {
        let updated = PropertyParser.applying(key: "Species", value: "Kethran", valueType: .text, to: "Just body text.")

        #expect(updated.hasPrefix("---\n"))
        #expect(updated.contains("Species: \"Kethran\""))
        #expect(updated.contains("Just body text."))
    }

    @Test func applyingSerializesAListAsAQuotedFlowList() {
        let updated = PropertyParser.applying(key: "Aliases", value: "Elyra; The Voss", valueType: .list, to: "Body.")
        #expect(updated.contains("Aliases: [\"Elyra\", \"The Voss\"]"))
    }

    // MARK: - removingProperty

    @Test func removingPropertyDropsOnlyThatKey() {
        let content = "---\nSpecies: \"Kethran\"\nHomeworld: \"Kethra Prime\"\n---\nBody."
        let updated = PropertyParser.removingProperty(key: "Species", from: content)

        let properties = PropertyParser.extractFrontmatterProperties(from: updated)
        #expect(properties.count == 1)
        #expect(properties.first?.key == "Homeworld")
    }

    @Test func removingTheOnlyPropertyLeavesNoFrontmatterBlock() {
        let content = "---\nSpecies: \"Kethran\"\n---\nBody."
        let updated = PropertyParser.removingProperty(key: "Species", from: content)
        #expect(updated == "Body.")
    }

    // MARK: - Round trip

    @Test func applyingThenExtractingRoundTripsEveryValueType() {
        var content = "Body."
        content = PropertyParser.applying(key: "Species", value: "Kethran", valueType: .text, to: content)
        content = PropertyParser.applying(key: "Age", value: "34", valueType: .number, to: content)
        content = PropertyParser.applying(key: "Alive", value: "true", valueType: .checkbox, to: content)
        content = PropertyParser.applying(key: "Birthdate", value: "2026-08-20", valueType: .date, to: content)
        content = PropertyParser.applying(key: "Aliases", value: "Elyra; The Voss", valueType: .list, to: content)

        let properties = Dictionary(uniqueKeysWithValues: PropertyParser.extractFrontmatterProperties(from: content).map { ($0.key, $0) })

        #expect(properties["Species"]?.value == "Kethran")
        #expect(properties["Species"]?.valueType == .text)
        #expect(properties["Age"]?.value == "34")
        #expect(properties["Age"]?.valueType == .number)
        #expect(properties["Alive"]?.value == "true")
        #expect(properties["Alive"]?.valueType == .checkbox)
        #expect(properties["Birthdate"]?.value == "2026-08-20")
        #expect(properties["Birthdate"]?.valueType == .date)
        #expect(properties["Aliases"]?.value == "Elyra; The Voss")
        #expect(properties["Aliases"]?.valueType == .list)
    }

}
