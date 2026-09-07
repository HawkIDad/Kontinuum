// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  NotebookParserTests.swift
//  KontinuumTests
//

import Testing
@testable import Kontinuum

struct NotebookParserTests {

    @Test func extractFrontmatterNotebooksParsesFlowList() {
        let content = "---\nnotebooks: [\"App Onboarding Revamp\", \"Kontinuum Roadmap\"]\n---\nBody text."
        #expect(NotebookParser.extractFrontmatterNotebooks(from: content) == ["App Onboarding Revamp", "Kontinuum Roadmap"])
    }

    @Test func extractFrontmatterNotebooksParsesBlockList() {
        let content = "---\ntitle: Notes\nnotebooks:\n  - App Onboarding Revamp\n  - Kontinuum Roadmap\n---\nBody text."
        #expect(NotebookParser.extractFrontmatterNotebooks(from: content) == ["App Onboarding Revamp", "Kontinuum Roadmap"])
    }

    @Test func extractFrontmatterNotebooksParsesSingleInlineValue() {
        let content = "---\nnotebooks: App Onboarding Revamp\n---\nBody text."
        #expect(NotebookParser.extractFrontmatterNotebooks(from: content) == ["App Onboarding Revamp"])
    }

    @Test func extractFrontmatterNotebooksReturnsEmptyWithNoFrontmatter() {
        #expect(NotebookParser.extractFrontmatterNotebooks(from: "Just body text.").isEmpty)
    }

    @Test func extractFrontmatterNotebooksPreservesExactCasing() {
        let content = "---\nnotebooks: [App Onboarding Revamp]\n---\nBody text."
        #expect(NotebookParser.extractFrontmatterNotebooks(from: content) == ["App Onboarding Revamp"])
    }

    @Test func extractFrontmatterNotebooksIgnoresUnrelatedFrontmatterKeys() {
        let content = "---\ntags: [roadmap]\n---\nBody text."
        #expect(NotebookParser.extractFrontmatterNotebooks(from: content).isEmpty)
    }

}
