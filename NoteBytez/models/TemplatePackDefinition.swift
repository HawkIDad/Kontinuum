// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TemplatePackDefinition.swift
//  Kontinuum
//

import Foundation

/// A bundled Template Pack — a curated `TemplateGroup` (+ its `NoteTemplate`s) for a domain of
/// knowledge work, shipped as an app resource and materialized into a library as ordinary
/// editable rows by `TemplatePackDAL`. Per NoteBytez20260824v1-Templates.md.
///
/// `nonisolated`: plain serializable data with no UI/shared-state ties — same opt-out as
/// `NoteTemplateField`, so `JSONDecoder`/`Equatable` can be used off the main actor.
nonisolated struct TemplatePackDefinition: Codable, Identifiable, Equatable {

    /// Stable kebab-case identifier — the join key between a bundled pack and a materialized
    /// `TemplateGroup.sourcePackId`. Never changes across versions.
    let packId: String
    /// Monotonically increasing. A bundled `version` greater than a library's applied
    /// `TemplateGroup.sourcePackVersion` surfaces "Update available".
    let version: Int
    /// Gallery grouping, e.g. "Engineering & Data", "People", "Essentials".
    let category: String
    /// User-facing group name (also becomes `TemplateGroup.name` when added).
    let displayName: String
    /// One-line gallery description.
    let summary: String
    /// Optional caveat shown in the pack preview (e.g. Healthcare's administrative-only scope).
    let note: String?
    /// Original role titles this pack serves — searched by the gallery and onboarding so a
    /// user finds "their" job title even after roles were merged into fewer packs.
    let roleAliases: [String]
    let templates: [PackTemplateDefinition]

    var id: String { packId }
}

nonisolated struct PackTemplateDefinition: Codable, Identifiable, Equatable {
    let name: String
    let fields: [PackFieldDefinition]
    /// Markdown scaffold woven into a new document's body (see `NoteTemplate.bodyTemplate`).
    let bodyTemplate: String?

    var id: String { name }

    var noteTemplateFields: [NoteTemplateField] {
        fields.map { NoteTemplateField(name: $0.name, valueType: $0.valueType, defaultValue: $0.defaultValue) }
    }
}

nonisolated struct PackFieldDefinition: Codable, Equatable {
    let name: String
    let valueType: PropertyValueType
    let defaultValue: String
}

// MARK: - Canonical fields

/// The small set of field names reused verbatim across packs, so cross-role Saved Views and
/// Advanced Search work. Packs must use these exact spellings and value types where the concept
/// applies — `TemplatePackLint` flags near-misses. Per NoteBytez20260824v1-Templates.md
/// "Proposed canonical shared fields".
nonisolated enum CanonicalField: String, CaseIterable {
    case status = "Status"
    case owner = "Owner"
    case priority = "Priority"
    case startDate = "Start Date"
    case dueDate = "Due Date"
    case stakeholders = "Stakeholders"
    case reviewed = "Reviewed"

    var valueType: PropertyValueType {
        switch self {
        case .status, .owner, .priority: return .text
        case .startDate, .dueDate: return .date
        case .stakeholders: return .list
        case .reviewed: return .checkbox
        }
    }

    /// Lowercased, non-alphanumeric stripped — the form used to detect a near-miss spelling.
    static func normalize(_ raw: String) -> String {
        raw.lowercased().unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }.map(String.init).joined()
    }
}

// MARK: - Original role list

/// The roles from NoteBytez20260824v1-Templates.md §Success Factors (23 knowledge-management
/// roles plus the three culinary roles added by the 2026-08-30 remediation). Every one must
/// appear in exactly one pack's `roleAliases` — asserted by `TemplatePackLint`.
nonisolated enum TemplateRoles {
    static let all: [String] = [
        "Information Architect", "Data Architect", "Software Engineer", "Technical Writer",
        "Project Manager", "Product Manager", "Customer Success Manager",
        "Human Resources Specialist", "Human Resources Manager",
        "Learning and Development Specialist", "Corporate Trainer", "Business Analyst",
        "Management Consultant", "Research Analyst", "Librarian", "Records Manager",
        "Legal Operations Specialist", "Healthcare Administrator", "IT Service Desk Analyst",
        "Data Governance Manager", "Sales Specialist", "Marketing Specialist", "Operations Manager",
        "Chef", "Confectioner", "Chocolatier"
    ]
}

// MARK: - Lint

/// Pure validation of the bundled pack set — run as a test (and, ideally, a CI step) so a pack
/// authoring mistake is caught before it ships. Per NoteBytez20260824v1-Templates.md R3.
nonisolated enum TemplatePackLint {

    static func issues(in packs: [TemplatePackDefinition]) -> [String] {
        var issues: [String] = []

        // Unique packIds.
        let ids = packs.map(\.packId)
        for duplicate in Set(ids.filter { id in ids.filter { $0 == id }.count > 1 }) {
            issues.append("duplicate packId '\(duplicate)'")
        }

        let canonicalByNormalized = Dictionary(uniqueKeysWithValues: CanonicalField.allCases.map { (CanonicalField.normalize($0.rawValue), $0) })

        for pack in packs {
            if pack.templates.isEmpty {
                issues.append("[\(pack.packId)] has no templates")
            }
            for template in pack.templates {
                if template.name.trimmingCharacters(in: .whitespaces).isEmpty {
                    issues.append("[\(pack.packId)] a template has an empty name")
                }
                for field in template.fields {
                    if field.name.trimmingCharacters(in: .whitespaces).isEmpty {
                        issues.append("[\(pack.packId)/\(template.name)] a field has an empty name")
                    }
                    let normalized = CanonicalField.normalize(field.name)
                    if let canonical = canonicalByNormalized[normalized] {
                        if field.name != canonical.rawValue {
                            issues.append("[\(pack.packId)/\(template.name)] field '\(field.name)' is a near-miss of canonical '\(canonical.rawValue)' — use the canonical spelling")
                        }
                        if field.valueType != canonical.valueType {
                            issues.append("[\(pack.packId)/\(template.name)] canonical field '\(canonical.rawValue)' must be \(canonical.valueType.rawValue), got \(field.valueType.rawValue)")
                        }
                    }
                }
                // Task lines in a body must be plain `- [ ]` so TaskParser picks them up.
                if let body = template.bodyTemplate, body.contains("[ ]"), !body.contains("- [ ]"), !body.contains("- [x]") {
                    issues.append("[\(pack.packId)/\(template.name)] body has a checkbox that isn't a `- [ ]` task line")
                }
            }
        }

        // Every original role covered exactly once across all packs.
        let allAliases = packs.flatMap(\.roleAliases)
        for role in TemplateRoles.all {
            let count = allAliases.filter { $0 == role }.count
            if count == 0 { issues.append("role '\(role)' is not covered by any pack's roleAliases") }
            if count > 1 { issues.append("role '\(role)' is covered by \(count) packs (must be exactly one)") }
        }
        for alias in Set(allAliases) where !TemplateRoles.all.contains(alias) {
            issues.append("roleAlias '\(alias)' is not one of the 23 documented roles")
        }

        return issues
    }
}
