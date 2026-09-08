// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  MarkdownDiffMergeTests.swift
//  KontinuumTests
//

import Testing
@testable import Kontinuum

struct MarkdownDiffMergeTests {

    @Test func identicalTextsProduceOnlyUnchangedHunks() {
        let hunks = MarkdownDiffMerge.hunks(old: "line one\nline two", new: "line one\nline two")

        #expect(hunks.allSatisfy { $0.kind == .unchanged })
        #expect(MarkdownDiffMerge.merge(hunks: hunks, acceptedHunkIDs: []) == "line one\nline two")
    }

    @Test func pureAdditionProducesAChangedHunkWithNoRemovedLines() {
        let hunks = MarkdownDiffMerge.hunks(old: "line one", new: "line one\nline two")
        let changed = try! #require(hunks.first { $0.kind == .changed })

        #expect(changed.removedLines.isEmpty)
        #expect(changed.addedLines == ["line two"])
    }

    @Test func pureRemovalProducesAChangedHunkWithNoAddedLines() {
        let hunks = MarkdownDiffMerge.hunks(old: "line one\nline two", new: "line one")
        let changed = try! #require(hunks.first { $0.kind == .changed })

        #expect(changed.addedLines.isEmpty)
        #expect(changed.removedLines == ["line two"])
    }

    @Test func aReplacedLineProducesAChangedHunkWithBothSides() {
        let hunks = MarkdownDiffMerge.hunks(old: "- Finalize UI, ship by Friday.", new: "- Finalize UI and sync log.")
        let changed = try! #require(hunks.first { $0.kind == .changed })

        #expect(changed.removedLines == ["- Finalize UI, ship by Friday."])
        #expect(changed.addedLines == ["- Finalize UI and sync log."])
    }

    @Test func acceptingAllChangedHunksReproducesTheNewText() {
        let old = "Title\n- old bullet\nShared line"
        let new = "Title\n- new bullet\nShared line"
        let hunks = MarkdownDiffMerge.hunks(old: old, new: new)
        let allChanged = Set(hunks.filter { $0.kind == .changed }.map(\.id))

        #expect(MarkdownDiffMerge.merge(hunks: hunks, acceptedHunkIDs: allChanged) == new)
    }

    @Test func acceptingNoChangedHunksReproducesTheOldText() {
        let old = "Title\n- old bullet\nShared line"
        let new = "Title\n- new bullet\nShared line"
        let hunks = MarkdownDiffMerge.hunks(old: old, new: new)

        #expect(MarkdownDiffMerge.merge(hunks: hunks, acceptedHunkIDs: []) == old)
    }

    @Test func mixedAcceptanceProducesAPerHunkMerge() {
        let old = "Keep this\nRemove this\nAlso keep"
        let new = "Keep this\nAdd this\nAlso keep"
        let hunks = MarkdownDiffMerge.hunks(old: old, new: new)
        let changed = try! #require(hunks.first { $0.kind == .changed })

        // Explicitly reject the one changed hunk — merge should fall back to the old line.
        #expect(MarkdownDiffMerge.merge(hunks: hunks, acceptedHunkIDs: []) .contains("Remove this"))
        #expect(MarkdownDiffMerge.merge(hunks: hunks, acceptedHunkIDs: [changed.id]).contains("Add this"))
    }

    @Test func emptyOldAndNewProducesNoHunks() {
        let hunks = MarkdownDiffMerge.hunks(old: "", new: "")
        #expect(MarkdownDiffMerge.merge(hunks: hunks, acceptedHunkIDs: []) == "")
    }

}
