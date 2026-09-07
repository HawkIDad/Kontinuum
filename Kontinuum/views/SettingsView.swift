// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SettingsView.swift
//  Kontinuum
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {

    let library: Library

    @Environment(\.modelContext) private var modelContext
    @State private var isPresentingExportFolderPicker = false
    @State private var exportedNoteCount: Int?
    @State private var isPresentingSharing = false

    var body: some View {
        List {
            NavigationLink("Sync & Conflicts") {
                ConflictStrategySettingsView()
            }
            NavigationLink("Backups") {
                BackupRestoreView(viewModel: BackupViewModel(modelContext: modelContext))
            }
            NavigationLink("Templates") {
                TemplateGroupListView(viewModel: TemplateViewModel(libraryId: library.libraryId ?? UUID(), modelContext: modelContext))
            }
            NavigationLink("Template Gallery") {
                TemplateGalleryView(viewModel: TemplateGalleryViewModel(libraryId: library.libraryId ?? UUID(), modelContext: modelContext))
            }
            NavigationLink("Plugins") {
                PluginManagementView(viewModel: PluginViewModel(libraryId: library.libraryId ?? UUID(), modelContext: modelContext))
            }
            Button("Sharing") {
                isPresentingSharing = true
            }
            Button("Export Library") {
                isPresentingExportFolderPicker = true
            }
        }
        .navigationTitle("Settings")
        .fileImporter(isPresented: $isPresentingExportFolderPicker, allowedContentTypes: [.folder]) { result in
            guard case .success(let folderURL) = result, let libraryId = library.libraryId else { return }
            exportedNoteCount = ExportDAL.exportLibrary(libraryId: libraryId, to: folderURL, in: modelContext)
        }
        .alert(
            "Export Complete",
            isPresented: Binding(get: { exportedNoteCount != nil }, set: { isPresented in if !isPresented { exportedNoteCount = nil } })
        ) {
            Button("OK") { exportedNoteCount = nil }
        } message: {
            Text("Exported \(exportedNoteCount ?? 0) note\((exportedNoteCount ?? 0) == 1 ? "" : "s").")
        }
        .sheet(isPresented: $isPresentingSharing) {
            SharingParticipantsView(viewModel: SharingViewModel(libraryId: library.libraryId ?? UUID(), libraryName: library.name ?? "Library"))
        }
    }

}
