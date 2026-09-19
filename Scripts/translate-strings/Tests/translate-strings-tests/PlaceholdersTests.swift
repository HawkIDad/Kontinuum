// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PlaceholdersTests.swift
//  translate-strings-tests
//

import Testing
@testable import translate_strings

struct PlaceholdersTests {

    @Test func identicalStringsAreSafe() {
        #expect(Placeholders.isSafe(source: "Hello, %@!", translated: "¡Hola, %@!"))
    }

    @Test func droppedPlaceholderIsUnsafe() {
        #expect(!Placeholders.isSafe(source: "Hello, %@!", translated: "Hola!"))
    }

    @Test func reorderedPositionalPlaceholdersAreSafe() {
        // Phase 2.4 explicitly allows a translator to reorder positional specifiers.
        #expect(Placeholders.isSafe(source: "%1$@ in %2$@", translated: "%2$@ から %1$@"))
    }

    @Test func mismatchedPositionalIndexIsUnsafe() {
        // Same *count* of specifiers, but "%2$@" became "%3$@" — still a real mismatch.
        #expect(!Placeholders.isSafe(source: "%1$@ in %2$@", translated: "%1$@ in %3$@"))
    }

    @Test func duplicatedPlaceholderIsUnsafe() {
        #expect(!Placeholders.isSafe(source: "%@ notes", translated: "%@ %@ notes"))
    }

    @Test func pluralSubstitutionMarkerIsPreserved() {
        #expect(Placeholders.isSafe(source: "%#@count@ notes", translated: "%#@count@ Notizen"))
    }

    @Test func noPlaceholdersIsTriviallySafe() {
        #expect(Placeholders.isSafe(source: "Settings", translated: "Einstellungen"))
    }

}
