// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Plugin.swift
//  NoteBytez
//

import Foundation
import SwiftData

/// The three bridge APIs a plugin script may be granted, per NoteBytez-ReleaseFeatures.md's
/// Version 1 "Plugin SDK (preview)" bullet and NoteBytez-R1-Implementation.md's Decisions Log
/// #3 — no filesystem/network bridge exists at all, so there is no fourth case to add here.
enum PluginPermission: String, Codable, CaseIterable, Identifiable {
    case readLibrary
    case writeCurrentNote
    case addCommand

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .readLibrary: return "Read library"
        case .writeCurrentNote: return "Write current note"
        case .addCommand: return "Add command"
        }
    }
}

/// An installed plugin: a user-authored `JavaScriptCore` script plus the explicit set of bridge
/// permissions the user granted it at install time (**design decision**: a plugin's manifest
/// simply *is* its granted-permissions list — declaring a permission and being granted it are
/// the same install-time approval gesture, matching S24's wireframe, which shows only a single
/// granted-permissions list per plugin, never a separate "requested vs. granted" state).
/// Library-scoped, like `TemplateGroup`/`SavedView` — not an owned child of any one `Document`,
/// since a plugin's commands can act on whichever note is open.
///
/// `permissionsJSON` stores the granted `PluginPermission` raw values as a JSON-encoded
/// `[String]`, the same "flat scalar field over a second table" choice `NoteTemplate.fieldsJSON`/
/// `SavedView.definitionJSON` already made for a small, always-together, never-queried-piecemeal
/// structure.
@Model
final class Plugin: Codable, Identifiable {

    var name: String?
    var libraryId: UUID?
    var entryScript: String?
    var permissionsJSON: String?
    var isEnabled: Bool?

    var createdOn: Date?
    var createdBy: String?
    var updatedOn: Date?
    var updatedBy: String?

    var isActive: Bool? = true

    var pluginId: UUID? = UUID()
    var id: UUID { return self.pluginId! }

    init(name: String, libraryId: UUID, entryScript: String, permissions: Set<PluginPermission>) {
        self.name = name
        self.libraryId = libraryId
        self.entryScript = entryScript
        self.isEnabled = true
        self.createdOn = Date()
        self.updatedOn = Date()
        self.isActive = true
        self.pluginId = UUID()
        self.permissionsJSON = Self.encode(permissions)
    }

    var grantedPermissions: Set<PluginPermission> {
        get { Set(Self.decode(permissionsJSON) ?? []) }
        set { permissionsJSON = Self.encode(newValue) }
    }

    private static func encode(_ permissions: Set<PluginPermission>) -> String? {
        let sorted = permissions.map { $0.rawValue }.sorted()
        return try? String(data: JSONEncoder().encode(sorted), encoding: .utf8)
    }

    private static func decode(_ json: String?) -> [PluginPermission]? {
        guard let json, let data = json.data(using: .utf8) else { return nil }
        guard let rawValues = try? JSONDecoder().decode([String].self, from: data) else { return nil }
        return rawValues.compactMap(PluginPermission.init)
    }

    enum CodingKeys: String, CodingKey {
        case name, libraryId, entryScript, permissionsJSON, isEnabled, createdOn, createdBy, updatedOn, updatedBy, isActive, pluginId
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try container.decodeIfPresent(String.self, forKey: .name) ?? "",
            libraryId: try container.decodeIfPresent(UUID.self, forKey: .libraryId) ?? UUID(),
            entryScript: try container.decodeIfPresent(String.self, forKey: .entryScript) ?? "",
            permissions: []
        )
        self.permissionsJSON = try container.decodeIfPresent(String.self, forKey: .permissionsJSON)
        self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled)
        self.createdOn = try container.decodeIfPresent(Date.self, forKey: .createdOn)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.updatedOn = try container.decodeIfPresent(Date.self, forKey: .updatedOn)
        self.updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        self.pluginId = try container.decodeIfPresent(UUID.self, forKey: .pluginId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.libraryId, forKey: .libraryId)
        try container.encode(self.entryScript, forKey: .entryScript)
        try container.encode(self.permissionsJSON, forKey: .permissionsJSON)
        try container.encode(self.isEnabled, forKey: .isEnabled)
        try container.encode(self.createdOn, forKey: .createdOn)
        try container.encode(self.createdBy, forKey: .createdBy)
        try container.encode(self.updatedOn, forKey: .updatedOn)
        try container.encode(self.updatedBy, forKey: .updatedBy)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.pluginId, forKey: .pluginId)
    }

}
