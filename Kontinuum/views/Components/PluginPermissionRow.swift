// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PluginPermissionRow.swift
//  Kontinuum
//

import SwiftUI

/// Plugin name + enable toggle + explicit list of granted permissions, per docs/styleGuide.md.
/// Never a bare "trust this plugin" toggle — every granted permission is named in the row
/// itself, matching S24's wireframe.
struct PluginPermissionRow: View {

    let plugin: Plugin
    let onToggleEnabled: (Bool) -> Void

    private var isEnabled: Bool { plugin.isEnabled ?? false }

    private var grantedPermissionNames: String {
        let granted = plugin.grantedPermissions
        let ordered = PluginPermission.allCases.filter { granted.contains($0) }
        guard !ordered.isEmpty else { return "No permissions granted" }
        return "Permissions: " + ordered.map(\.displayName).joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: Binding(get: { isEnabled }, set: onToggleEnabled)) {
                Text(plugin.name ?? "Untitled Plugin")
            }

            Text(grantedPermissionNames)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

}
