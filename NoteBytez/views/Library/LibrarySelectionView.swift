// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  LibrarySelectionView.swift
//  Kontinuum
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// S1 — Library Creation / Selection. First-run entry point; also reachable whenever no
/// library is currently selected.
struct LibrarySelectionView: View {

    var viewModel: LibraryViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var isPresentingCreateLibrary = false
    @State private var isPresentingFolderImporter = false
    @State private var isPresentingMigrationFolderImporter = false
    @State private var pendingImport: PendingImport?
    @State private var pendingMigration: PendingImport?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.libraries.isEmpty {
                        ContentUnavailableView(
                            "No Libraries Yet",
                            systemImage: "shippingbox",
                            description: Text("Create a library to start capturing notes.")
                        )
                    } else {
                        // A plain VStack, not `List` — this screen is now scrollable (large
                        // Dynamic Type sizes can push the buttons below off-screen otherwise),
                        // and nesting `List` inside a `ScrollView` fights it for scroll/gesture
                        // ownership.
                        VStack(spacing: 0) {
                            ForEach(viewModel.libraries) { library in
                                Button {
                                    viewModel.select(library)
                                } label: {
                                    Text(library.name ?? "Untitled Library")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 8)
                                Divider()
                            }
                        }
                        .padding(.horizontal)
                    }

                    VStack(spacing: 12) {
                        PrimaryButton(title: "Create New Library") {
                            isPresentingCreateLibrary = true
                        }

                        Button {
                            isPresentingFolderImporter = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Import Existing Markdown Folder")
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        Button {
                            isPresentingMigrationFolderImporter = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.triangle.branch")
                                Text("Migration Assistant (Obsidian/Logseq)")
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.bottom)
                }
                .padding(.top, 40)
            }
            .navigationTitle("NoteBytez")
            .sheet(isPresented: $isPresentingCreateLibrary) {
                CreateLibrarySheet(viewModel: viewModel, isPresented: $isPresentingCreateLibrary)
            }
            .fileImporter(isPresented: $isPresentingFolderImporter, allowedContentTypes: [.folder]) { result in
                guard case .success(let folderURL) = result else { return }
                let library = viewModel.createLibraryForImport(named: folderURL.lastPathComponent)
                pendingImport = PendingImport(library: library, folderURL: folderURL)
            }
            .sheet(item: $pendingImport) { pending in
                ImportScanView(
                    viewModel: ImportViewModel(library: pending.library, folderURL: pending.folderURL, modelContext: modelContext),
                    onConfirm: {
                        viewModel.select(pending.library)
                        pendingImport = nil
                    },
                    onCancel: {
                        viewModel.loadLibraries()
                        pendingImport = nil
                    }
                )
            }
            .fileImporter(isPresented: $isPresentingMigrationFolderImporter, allowedContentTypes: [.folder]) { result in
                guard case .success(let folderURL) = result else { return }
                let library = viewModel.createLibraryForImport(named: folderURL.lastPathComponent)
                pendingMigration = PendingImport(library: library, folderURL: folderURL)
            }
            .sheet(item: $pendingMigration) { pending in
                MigrationAssistantView(
                    viewModel: MigrationViewModel(library: pending.library, folderURL: pending.folderURL, modelContext: modelContext),
                    onConfirm: {
                        viewModel.select(pending.library)
                        pendingMigration = nil
                    },
                    onCancel: {
                        viewModel.loadLibraries()
                        pendingMigration = nil
                    }
                )
            }
        }
    }

}

private struct PendingImport: Identifiable {
    let id = UUID()
    let library: Library
    let folderURL: URL
}

private struct CreateLibrarySheet: View {

    var viewModel: LibraryViewModel
    @Binding var isPresented: Bool
    @State private var name: String = ""

    private var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Library Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                PrimaryButton(title: "Create") {
                    viewModel.createLibrary(named: name)
                    isPresented = false
                }
                .disabled(!isNameValid)

                SecondaryButton(title: "Cancel") {
                    isPresented = false
                }
            }
            .padding(.top, 24)
            .navigationTitle("New Library")
            .noteBytezInlineNavigationTitle()
        }
    }

}

#Preview {
    LibrarySelectionView(viewModel: LibraryViewModel(modelContext: try! ModelContainer(for: Library.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext))
}
