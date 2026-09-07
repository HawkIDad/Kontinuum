// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BlockDAL.swift
//  Kontinuum
//

import Foundation
import SwiftData

enum BlockDAL {

    static func fetchActive(documentId: UUID, in context: ModelContext) -> [Block] {
        let predicate = #Predicate<Block> { $0.documentId == documentId && $0.isActive == true }
        let descriptor = FetchDescriptor<Block>(predicate: predicate, sortBy: [SortDescriptor(\.sortOrder)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Every active Block across the whole library, regardless of which Document it belongs
    /// to — Phase 4's block references resolve library-wide, so this is the library-scoped
    /// lookup that work needs. `Block` carries no `libraryId` of its own (see
    /// `ARCHITECTURE.md`'s Model Conventions — it resolves via its owning `Document`), so this
    /// joins through `DocumentDAL.fetchActive` rather than a direct predicate. `block.documentId`
    /// is itself the "blockId → document" index Phase 4's plan calls for — already a stored,
    /// always-current field since MVP, not a structure that needed building.
    static func fetchActive(libraryId: UUID, in context: ModelContext) -> [Block] {
        let documentIds = Set(DocumentDAL.fetchActive(libraryId: libraryId, in: context).compactMap { $0.documentId })
        guard !documentIds.isEmpty else { return [] }

        let predicate = #Predicate<Block> { $0.isActive == true }
        let all = (try? context.fetch(FetchDescriptor<Block>(predicate: predicate))) ?? []
        return all.filter { documentIds.contains($0.documentId ?? UUID()) }
    }

    /// Re-splits `markdown` into blocks and reconciles against the document's existing
    /// blocks: a chunk whose text exactly matches an existing active block reuses that
    /// block's `blockId` (so backlinks/references survive an edit elsewhere in the
    /// document); unmatched existing blocks are soft-deleted; unmatched chunks become
    /// new blocks. Every resulting block's `headingPath` is (re)written from the ATX
    /// headings enclosing it — see `MarkdownBlockSplitter.split(withHeadingContext:)`.
    @discardableResult
    static func syncBlocks(for documentId: UUID, markdown: String, in context: ModelContext) -> [Block] {
        let chunks = MarkdownBlockSplitter.split(withHeadingContext: markdown)

        let predicate = #Predicate<Block> { $0.documentId == documentId }
        let descriptor = FetchDescriptor<Block>(predicate: predicate)
        let existingBlocks = (try? context.fetch(descriptor)) ?? []

        var availableByContent: [String: [Block]] = [:]
        for block in existingBlocks where block.isActive == true {
            availableByContent[block.content ?? "", default: []].append(block)
        }

        var usedAnchors: Set<String> = []
        var consumedBlockIds: Set<UUID> = []
        var reusedByIndex: [Int: Block] = [:]
        var newChunksByIndex: [Int: (content: String, headingPath: [String])] = [:]

        for (index, chunk) in chunks.enumerated() {
            if var candidates = availableByContent[chunk.content], !candidates.isEmpty {
                let reused = candidates.removeFirst()
                availableByContent[chunk.content] = candidates

                reused.sortOrder = index
                reused.headingPath = joinedHeadingPath(chunk.headingPath)
                reused.updatedOn = Date()
                if let anchor = reused.anchor {
                    usedAnchors.insert(anchor)
                }
                reusedByIndex[index] = reused
                if let blockId = reused.blockId {
                    consumedBlockIds.insert(blockId)
                }
            } else {
                newChunksByIndex[index] = (content: chunk.content, headingPath: chunk.headingPath)
            }
        }

        let unmatchedExistingBlocks = existingBlocks.filter { block in
            guard block.isActive == true, let blockId = block.blockId else { return false }
            return !consumedBlockIds.contains(blockId)
        }
        for (index, block) in reclaimMatches(newChunks: newChunksByIndex, existingBlocks: unmatchedExistingBlocks) {
            guard let chunk = newChunksByIndex[index] else { continue }

            block.content = chunk.content
            block.sortOrder = index
            block.headingPath = joinedHeadingPath(chunk.headingPath)
            block.updatedOn = Date()
            if let anchor = block.anchor {
                usedAnchors.insert(anchor)
            }
            reusedByIndex[index] = block
            if let blockId = block.blockId {
                consumedBlockIds.insert(blockId)
            }
            newChunksByIndex.removeValue(forKey: index)
        }

        let anchorsByIndex = assignAnchors(for: newChunksByIndex, used: &usedAnchors)

        var resultBlocks: [Block] = []
        for (index, chunk) in chunks.enumerated() {
            if let reused = reusedByIndex[index] {
                resultBlocks.append(reused)
            } else if let anchor = anchorsByIndex[index] {
                let newBlock = Block(content: chunk.content, anchor: anchor, sortOrder: index, documentId: documentId)
                newBlock.headingPath = joinedHeadingPath(chunk.headingPath)
                context.insert(newBlock)
                resultBlocks.append(newBlock)
            }
        }

        for block in existingBlocks where block.isActive == true {
            guard let blockId = block.blockId, !consumedBlockIds.contains(blockId) else { continue }
            block.isActive = false
            block.updatedOn = Date()
            SyncEngine.shared.recordChanged(block, in: context)
        }

        for block in resultBlocks {
            SyncEngine.shared.recordChanged(block, in: context)
        }

        return resultBlocks
    }

    /// Backfills `headingPath` for any active `Block` predating this field (see `ARCHITECTURE.md`
    /// Model Conventions — CloudKit schema additions are optional/nullable, so older synced
    /// blocks land with `nil`) by re-running `syncBlocks` for each of their owning documents.
    /// Exact-content-match reuse means this never touches `blockId` or `anchor` — it only ever
    /// fills in the derived `headingPath` field. Meant to run once at app launch; cheap to call
    /// repeatedly since a fully up-to-date document is a same-content no-op resync.
    static func backfillHeadingPathsIfNeeded(in context: ModelContext) {
        let predicate = #Predicate<Block> { $0.isActive == true && $0.headingPath == nil }
        let staleBlocks = (try? context.fetch(FetchDescriptor<Block>(predicate: predicate))) ?? []
        guard !staleBlocks.isEmpty else { return }

        let documentIds = Set(staleBlocks.compactMap { $0.documentId })
        for documentId in documentIds {
            guard let document = Document.fetch(syncId: documentId, in: context) else { continue }
            syncBlocks(for: documentId, markdown: document.content ?? "", in: context)
        }
    }

    private static func joinedHeadingPath(_ headingPath: [String]) -> String? {
        headingPath.isEmpty ? nil : headingPath.joined(separator: " > ")
    }

    /// Sticky identity's second reconciliation pass, run after exact-content-match: pairs each
    /// still-unmatched new chunk with a still-unmatched existing block when they're "clearly the
    /// same" — same flat index *and* heading path (an in-place rewrite), or Levenshtein
    /// similarity ≥ 0.7 (a block that moved and was lightly edited) — so it keeps its `blockId`
    /// and `anchor` instead of being soft-deleted-and-reinserted. Greedy, ranked by
    /// `(similarity desc, |Δindex| asc, old sortOrder asc)` for a deterministic 1:1 mapping when
    /// more than one candidate is eligible.
    private static func reclaimMatches(newChunks: [Int: (content: String, headingPath: [String])], existingBlocks: [Block]) -> [(index: Int, block: Block)] {
        struct Candidate {
            let index: Int
            let block: Block
            let similarity: Double
            let deltaIndex: Int
        }

        var candidates: [Candidate] = []
        for (index, chunk) in newChunks {
            let newHeadingPath = joinedHeadingPath(chunk.headingPath)
            for block in existingBlocks {
                let oldIndex = block.sortOrder ?? -1
                let sameIndexAndPath = oldIndex == index && block.headingPath == newHeadingPath
                let similarity = StringSimilarity.similarity(block.content ?? "", chunk.content) ?? 0

                guard sameIndexAndPath || similarity >= 0.7 else { continue }
                candidates.append(Candidate(index: index, block: block, similarity: similarity, deltaIndex: abs(oldIndex - index)))
            }
        }

        candidates.sort {
            if $0.similarity != $1.similarity { return $0.similarity > $1.similarity }
            if $0.deltaIndex != $1.deltaIndex { return $0.deltaIndex < $1.deltaIndex }
            return ($0.block.sortOrder ?? 0) < ($1.block.sortOrder ?? 0)
        }

        var usedIndices: Set<Int> = []
        var usedBlockIds: Set<UUID> = []
        var result: [(index: Int, block: Block)] = []
        for candidate in candidates {
            guard !usedIndices.contains(candidate.index),
                  let blockId = candidate.block.blockId, !usedBlockIds.contains(blockId)
            else { continue }
            usedIndices.insert(candidate.index)
            usedBlockIds.insert(blockId)
            result.append((index: candidate.index, block: candidate.block))
        }
        return result
    }

    /// Anchors for this sync's newly-inserted chunks. A base slug unique among them keeps that
    /// bare slug (no churn for the common case — Decision 3). A base slug shared by more than
    /// one new chunk is disambiguated for *every* chunk that shares it by walking up that
    /// chunk's own `headingPath`, innermost segment first, rather than the old positional
    /// `-2`/`-3` suffix. Numeric suffix remains only as the last resort, for chunks with no
    /// heading path to disambiguate with (or whose full path still collides) — i.e. genuinely
    /// identical text under an identical heading path.
    private static func assignAnchors(for newChunksByIndex: [Int: (content: String, headingPath: [String])], used: inout Set<String>) -> [Int: String] {
        let orderedIndices = newChunksByIndex.keys.sorted()

        var baseByIndex: [Int: String] = [:]
        var frequency: [String: Int] = [:]
        for index in orderedIndices {
            let base = anchor(for: newChunksByIndex[index]!.content)
            baseByIndex[index] = base
            frequency[base, default: 0] += 1
        }

        var result: [Int: String] = [:]
        for index in orderedIndices {
            let base = baseByIndex[index]!
            if frequency[base] == 1 {
                result[index] = uniqueAnchor(base: base, used: &used)
            } else {
                result[index] = pathDisambiguatedAnchor(base: base, headingPath: newChunksByIndex[index]!.headingPath, used: &used)
            }
        }
        return result
    }

    private static func pathDisambiguatedAnchor(base: String, headingPath: [String], used: inout Set<String>) -> String {
        if !headingPath.isEmpty {
            for segmentCount in 1...headingPath.count {
                let segments = headingPath.suffix(segmentCount).map(slugify)
                let candidate = (segments + [base]).joined(separator: "-")
                if !used.contains(candidate) {
                    used.insert(candidate)
                    return candidate
                }
            }
        }
        return uniqueAnchor(base: base, used: &used)
    }

    private static func uniqueAnchor(base: String, used: inout Set<String>) -> String {
        var candidate = base
        var suffix = 2
        while used.contains(candidate) {
            candidate = "\(base)-\(suffix)"
            suffix += 1
        }
        used.insert(candidate)
        return candidate
    }

    private static func anchor(for chunkContent: String) -> String {
        guard let firstLine = chunkContent.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: true).first else {
            return "block"
        }

        var text = String(firstLine)
        if text.hasPrefix("#") {
            text = text.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces)
        }

        let words = text.split(separator: " ").prefix(6).joined(separator: " ")
        return slugify(words)
    }

    /// Not `private`: also used by `DocumentViewModel.resolveSectionLink`/`headingSuggestions`
    /// to slug a `[[Title#Heading]]` heading the same way a block's own anchor is slugged.
    static func slugify(_ text: String) -> String {
        let allowed = CharacterSet.alphanumerics
        var scalars: [Unicode.Scalar] = []
        var lastWasHyphen = false

        for scalar in text.lowercased().unicodeScalars {
            if allowed.contains(scalar) {
                scalars.append(scalar)
                lastWasHyphen = false
            } else if !lastWasHyphen {
                scalars.append("-")
                lastWasHyphen = true
            }
        }

        var slug = String(String.UnicodeScalarView(scalars)).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        if slug.count > 60 {
            slug = String(slug.prefix(60))
        }

        return slug.isEmpty ? "block" : slug
    }

}
