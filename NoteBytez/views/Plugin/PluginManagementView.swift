// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PluginManagementView.swift
//  NoteBytez
//

import SwiftUI

/// S24 — Plugin Management. Reached from Settings → "Plugins". Install/enable/disable/revoke,
/// with every granted permission always visible via `PluginPermissionRow` — per Decisions Log
/// #3, a plugin never runs with a permission the user didn't see and approve at install time.
struct PluginManagementView: View {

    var viewModel: PluginViewModel

    @State private var isPresentingInstallSheet = false

    var body: some View {
        List {
            if viewModel.plugins.isEmpty {
                ContentUnavailableView(
                    "No Plugins Installed",
                    systemImage: "puzzlepiece.extension",
                    description: Text("Install a plugin to add custom commands to NoteBytez.")
                )
            } else {
                ForEach(viewModel.plugins) { plugin in
                    PluginPermissionRow(plugin: plugin) { isEnabled in
                        viewModel.setEnabled(plugin, isEnabled: isEnabled)
                    }
                }
                .onDelete { offsets in
                    for index in offsets { viewModel.uninstall(viewModel.plugins[index]) }
                }
            }
        }
        .navigationTitle("Plugins (Preview)")
        .noteBytezInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") {
                    isPresentingInstallSheet = true
                }
            }
        }
        .sheet(isPresented: $isPresentingInstallSheet) {
            PluginInstallSheet(viewModel: viewModel)
        }
    }

}

/// The install approval flow — per Decisions Log #3, the user sees and grants every permission
/// individually before the plugin can run, never a single bare "trust this plugin" toggle.
private struct PluginInstallSheet: View {

    var viewModel: PluginViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var entryScript = ""
    @State private var grantedPermissions: Set<PluginPermission> = []

    private var canInstall: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !entryScript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Plugin") {
                    TextField("Name", text: $name)
                    TextEditor(text: $entryScript)
                        .frame(minHeight: 160)
                        .font(.system(.body, design: .monospaced))
                }

                Section {
                    ForEach(PluginPermission.allCases) { permission in
                        Toggle(permission.displayName, isOn: Binding(
                            get: { grantedPermissions.contains(permission) },
                            set: { isOn in
                                if isOn { grantedPermissions.insert(permission) } else { grantedPermissions.remove(permission) }
                            }
                        ))
                    }
                } header: {
                    Text("Permissions")
                } footer: {
                    Text("Only grant what this plugin actually needs. The sandbox enforces each permission individually — a permission left off here can never be reached by the script, no matter what it asks for.")
                }
            }
            .navigationTitle("Add Plugin")
            .noteBytezInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Install") {
                        viewModel.install(name: name, entryScript: entryScript, permissions: grantedPermissions)
                        dismiss()
                    }
                    .disabled(!canInstall)
                }
            }
        }
    }

}
