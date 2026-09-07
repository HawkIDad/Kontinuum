// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  AttachmentParser.swift
//  Kontinuum
//

import Foundation

/// Standard Markdown image syntax (`![alt](fileName)`) as the attachment embed reference —
/// deliberately no proprietary URL scheme, unlike wikilinks/tags/block references, so an
/// Obsidian/Logseq vault's own `![](relative/path.png)` syntax (Phase 12) round-trips through
/// this for free. Pure/stateless, mirroring `PropertyParser`/`TaskParser` — resolving a matched
/// `fileName` to an actual `Attachment` (and its on-disk bytes) is the DAL/view layer's job.
enum AttachmentParser {

    struct AttachmentMatch: Equatable {
        let altText: String
        let fileName: String
    }

    private static let imagePattern = try! NSRegularExpression(pattern: #"!\[([^\]]*)\]\(([^)]+)\)"#)

    /// Whether `content` contains any image-embed syntax at all — mirrors
    /// `EmbeddedSearchBlockParser.containsQueryBlock`, used to opt a document into
    /// `DocumentPreviewView`'s line-based render path. Deliberately not scoped to only *local*
    /// attachment matches: a remote image reference still needs to go through the line-based
    /// path so the render loop can fall back to plain `MDProcessor` rendering per-line.
    static func containsAttachmentEmbed(_ content: String) -> Bool {
        imagePattern.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)) != nil
    }

    /// Matches a single line against the image-embed pattern, the same per-line shape
    /// `TaskParser.match(in:)` already establishes for `LineBasedPreview`.
    static func match(in line: String) -> AttachmentMatch? {
        let nsLine = line as NSString
        guard let match = imagePattern.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)), match.numberOfRanges == 3 else {
            return nil
        }
        let altText = nsLine.substring(with: match.range(at: 1))
        let fileName = nsLine.substring(with: match.range(at: 2))
        return AttachmentMatch(altText: altText, fileName: fileName)
    }

    /// Every image-embed path referenced anywhere in `content` — used by
    /// `AttachmentDAL.syncAttachments`'s reconcile pass to soft-delete an `Attachment` whose
    /// embed line was deleted from content. A path that doesn't match any real `Attachment`
    /// (e.g. a remote URL) is harmless here — it just never matches anything to remove.
    static func referencedFileNames(in content: String) -> [String] {
        let nsContent = content as NSString
        let matches = imagePattern.matches(in: content, range: NSRange(location: 0, length: nsContent.length))
        return matches.compactMap { match -> String? in
            guard match.numberOfRanges == 3 else { return nil }
            return nsContent.substring(with: match.range(at: 2))
        }
    }

    /// Appends a new `![altText](fileName)` embed line to `content` — the DAL-level "attach a
    /// file" write path, mirroring `PropertyParser.applying`/`TagParser.applying`'s "insert into
    /// content, let a `syncX` reconcile pass rebuild the index afterward" shape.
    static func applying(fileName: String, altText: String, to content: String) -> String {
        let embed = "![\(altText)](\(fileName))"
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return embed }
        return content + "\n\n" + embed
    }

    /// Removes every embed line referencing `fileName` — the "detach a file" write path,
    /// mirroring `PropertyParser.removingProperty`'s "content is the single source of truth"
    /// shape. A whole-line removal (not just the matched span) since an embed is always
    /// authored on its own line by `applying(fileName:altText:to:)`.
    static func removingEmbed(fileName: String, from content: String) -> String {
        let lines = content.components(separatedBy: "\n").filter { line in
            guard let match = match(in: line) else { return true }
            return match.fileName != fileName
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

}
