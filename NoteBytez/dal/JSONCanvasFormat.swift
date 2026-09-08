// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  JSONCanvasFormat.swift
//  Kontinuum
//

import Foundation

/// Pure [JSON Canvas 1.0](https://jsoncanvas.org) document shape — full spec surface per
/// NoteBytez-ReleaseFeatures.md's Decisions Log #2 (all 4 node types, edges with
/// `fromSide`/`toSide`/`color`/`label`). No `ModelContext`, no Kontinuum-specific meaning — same
/// "pure format, DB-touching resolution lives in the DAL" shape as `AttachmentParser`/
/// `PropertyParser`. `CanvasDAL.exportJSONCanvas`/`importJSONCanvas` are the only callers that
/// should construct or interpret these types. `nonisolated` throughout this file: plain
/// serializable data with no UI/shared-state ties, opted out of this target's
/// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — otherwise each type's `Codable` conformance is
/// itself MainActor-isolated, which `JSONDecoder`/`JSONEncoder`'s nonisolated stdlib entry points
/// can't call into (a warning today, a Swift 6 language-mode error) — same fix already applied
/// to `SavedSearchDefinition`/`NoteTemplateField`/`RecurrenceRule` etc.
nonisolated struct JSONCanvasDocument: Codable {
    var nodes: [JSONCanvasNode]
    var edges: [JSONCanvasEdge]
}

nonisolated enum JSONCanvasNodeType: String, Codable {
    case text
    case file
    case link
    case group
}

/// One field set covers every node type (the spec's own shape — a discriminated union by
/// `type`), with type-specific fields left `nil` when irrelevant. Manual `Codable` (decoding
/// `x`/`y`/`width`/`height` leniently rather than failing the whole document on one malformed
/// node) rather than relying on synthesis, matching this app's existing manual-`Codable`
/// convention for round-trip-critical types.
nonisolated struct JSONCanvasNode: Codable {
    var id: String
    var type: JSONCanvasNodeType
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var color: String?

    /// `.text` node only.
    var text: String?
    /// `.file` node only (a vault-relative path).
    var file: String?
    /// `.link` node only.
    var url: String?
    /// `.group` node only.
    var label: String?

    enum CodingKeys: String, CodingKey {
        case id, type, x, y, width, height, color, text, file, url, label
    }

    init(id: String, type: JSONCanvasNodeType, x: Double, y: Double, width: Double, height: Double, color: String? = nil, text: String? = nil, file: String? = nil, url: String? = nil, label: String? = nil) {
        self.id = id
        self.type = type
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.color = color
        self.text = text
        self.file = file
        self.url = url
        self.label = label
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.type = (try container.decodeIfPresent(JSONCanvasNodeType.self, forKey: .type)) ?? .text
        self.x = try container.decodeIfPresent(Double.self, forKey: .x) ?? 0
        self.y = try container.decodeIfPresent(Double.self, forKey: .y) ?? 0
        self.width = try container.decodeIfPresent(Double.self, forKey: .width) ?? 0
        self.height = try container.decodeIfPresent(Double.self, forKey: .height) ?? 0
        self.color = try container.decodeIfPresent(String.self, forKey: .color)
        self.text = try container.decodeIfPresent(String.self, forKey: .text)
        self.file = try container.decodeIfPresent(String.self, forKey: .file)
        self.url = try container.decodeIfPresent(String.self, forKey: .url)
        self.label = try container.decodeIfPresent(String.self, forKey: .label)
    }
}

/// **Scope cut, stated not silent**: the spec's `fromEnd`/`toEnd` (arrowhead style) fields aren't
/// modeled — NoteBytez-R1-Implementation.md Phase 9 only calls out `fromSide`/`toSide`/`color`/
/// `label`. A foreign vault's arrowhead style is lost on import; every Kontinuum-rendered
/// connector gets a plain arrowhead.
nonisolated struct JSONCanvasEdge: Codable {
    var id: String
    var fromNode: String
    var fromSide: String?
    var toNode: String
    var toSide: String?
    var color: String?
    var label: String?
}
