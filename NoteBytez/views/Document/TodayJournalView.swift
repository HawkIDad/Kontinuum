// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TodayJournalView.swift
//  NoteBytez
//

import SwiftUI
import SwiftData

/// S3 — Today (Journal) view. Owns its `JournalViewModel` via the same
/// construct-once-on-appear `@State` pattern as `RootView`'s `LibraryViewModel`, rather than
/// building it inline in `ContentView`'s destination switch — the journal entry's `TextEditor`
/// holds in-progress, unsaved keystrokes, and re-running that switch on every SwiftUI render
/// pass (as already happens harmlessly for the read-only Tag Browser) would otherwise discard
/// them by constructing a fresh view model each time.
struct TodayJournalView: View {

    let libraryId: UUID

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: JournalViewModel?
    @State private var wikilinkTarget: Document?
    @State private var pendingScrollTargetLineText: String?
    @State private var isPresentingTags = false
    @State private var isPresentingPromote = false
    @State private var isPresentingQuickSwitcher = false
    @State private var isPresentingTasks = false

    var body: some View {
        Group {
            if let viewModel {
                JournalEntryEditor(
                    documentViewModel: viewModel.documentViewModel,
                    date: viewModel.date,
                    canGoToNextDay: viewModel.canGoToNextDay,
                    onPrevious: { viewModel.goToPreviousDay() },
                    onNext: { viewModel.goToNextDay() },
                    wikilinkTarget: $wikilinkTarget,
                    pendingScrollTargetLineText: $pendingScrollTargetLineText,
                    isPresentingTags: $isPresentingTags
                )
                .onDisappear {
                    viewModel.documentViewModel.save()
                }
            } else {
                ProgressView()
            }
        }
        .onDisappear {
            NotificationCenter.default.post(name: .noteBytezActiveDocumentChanged, object: nil)
        }
        .onChange(of: viewModel?.documentViewModel.document) { _, newDocument in
            NotificationCenter.default.post(name: .noteBytezActiveDocumentChanged, object: newDocument)
        }
        .navigationTitle("Today")
        .noteBytezInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingQuickSwitcher = true
                } label: {
                    Label("Quick Switcher", systemImage: "magnifyingglass")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingPromote = true
                } label: {
                    Label("Promote to Notebook", systemImage: "books.vertical")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingTasks = true
                } label: {
                    Label("Tasks", systemImage: "checklist")
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = JournalViewModel(libraryId: libraryId, modelContext: modelContext)
            }
            NotificationCenter.default.post(name: .noteBytezActiveDocumentChanged, object: viewModel?.documentViewModel.document)
        }
        .navigationDestination(item: $wikilinkTarget) { target in
            DocumentView(viewModel: DocumentViewModel(document: target, modelContext: modelContext), scrollTargetLineText: pendingScrollTargetLineText)
        }
        .sheet(isPresented: $isPresentingTags) {
            NavigationStack {
                TagBrowserView(viewModel: TagViewModel(libraryId: libraryId, modelContext: modelContext))
            }
        }
        .sheet(isPresented: $isPresentingPromote) {
            if let viewModel {
                PromoteBlockPickerView(
                    sourceDocument: viewModel.documentViewModel.document,
                    notebookViewModel: NotebookViewModel(libraryId: libraryId, modelContext: modelContext),
                    onPromoted: { document in
                        viewModel.documentViewModel.reload()
                        wikilinkTarget = document
                    }
                )
            }
        }
        .sheet(isPresented: $isPresentingQuickSwitcher) {
            QuickSwitcherView(
                viewModel: SearchViewModel(libraryId: libraryId, modelContext: modelContext),
                onSelect: { document in
                    wikilinkTarget = document
                }
            )
        }
        .sheet(isPresented: $isPresentingTasks) {
            NavigationStack {
                TaskDashboardView(viewModel: TaskDashboardViewModel(libraryId: libraryId, modelContext: modelContext))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .noteBytezTriggerPromote)) { _ in
            isPresentingPromote = true
        }
    }

}

private struct JournalEntryEditor: View {

    @Bindable var documentViewModel: DocumentViewModel
    let date: Date
    let canGoToNextDay: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    @Binding var wikilinkTarget: Document?
    @Binding var pendingScrollTargetLineText: String?
    @Binding var isPresentingTags: Bool

    @State private var isEditing = true

    var body: some View {
        VStack(spacing: 0) {
            JournalDayHeader(date: date, canGoToNextDay: canGoToNextDay, onPrevious: onPrevious, onNext: onNext)

            if !documentViewModel.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(documentViewModel.tags) { tag in
                            TagChip(name: tag.name ?? "") { isPresentingTags = true }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Divider()

            Group {
                if isEditing {
                    TextEditor(text: $documentViewModel.content)
                        .font(.body.monospaced())
                } else {
                    DocumentPreviewView(documentViewModel: documentViewModel)
                }
            }

            if isEditing, let query = documentViewModel.activeWikilinkQuery {
                if let hashIndex = query.firstIndex(of: "#") {
                    let queryTitle = String(query[query.startIndex..<hashIndex])
                    let headingQuery = String(query[query.index(after: hashIndex)...])
                    let suggestions = documentViewModel.headingSuggestions(forDocumentTitled: queryTitle, matching: headingQuery)
                    if !suggestions.isEmpty {
                        Divider()
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestions, id: \.self) { heading in
                                    WikilinkText(title: heading) {
                                        documentViewModel.insertWikilink(title: "\(queryTitle)#\(heading)")
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.noteBytezSecondarySurface)
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }
                } else {
                    let suggestions = documentViewModel.wikilinkSuggestions(matching: query)
                    if !suggestions.isEmpty {
                        Divider()
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestions, id: \.self) { title in
                                    WikilinkText(title: title) {
                                        documentViewModel.insertWikilink(title: title)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.noteBytezSecondarySurface)
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }

            if isEditing, let query = documentViewModel.activeTagQuery {
                let suggestions = documentViewModel.tagSuggestions(matching: query)
                if !suggestions.isEmpty {
                    Divider()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestions, id: \.self) { name in
                                TagChip(name: name) {
                                    documentViewModel.insertTag(name: name)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
            }

            if isEditing, let query = documentViewModel.activeEmbedReferenceQuery {
                let suggestions = documentViewModel.blockReferenceSuggestions(matching: query)
                if !suggestions.isEmpty {
                    Divider()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestions) { block in
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 2) {
                                        Text("!")
                                        BlockReferenceText(anchor: block.anchor ?? "") {
                                            documentViewModel.insertEmbedReference(anchor: block.anchor ?? "")
                                        }
                                    }
                                    if let headingPath = block.headingPath {
                                        Text(headingPath)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
            } else if isEditing, let query = documentViewModel.activeBlockReferenceQuery {
                let suggestions = documentViewModel.blockReferenceSuggestions(matching: query)
                if !suggestions.isEmpty {
                    Divider()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestions) { block in
                                VStack(alignment: .leading, spacing: 2) {
                                    BlockReferenceText(anchor: block.anchor ?? "") {
                                        documentViewModel.insertBlockReference(anchor: block.anchor ?? "")
                                    }
                                    if let headingPath = block.headingPath {
                                        Text(headingPath)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
            }

            Divider()

            HStack {
                Button {
                    isEditing.toggle()
                } label: {
                    Image(systemName: isEditing ? "eye.fill" : "pencil")
                    Text(isEditing ? "Preview" : "Edit")
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding()
        }
        .environment(\.openURL, OpenURLAction { url in
            switch url.scheme {
            case "wikilink":
                guard let title = url.host(percentEncoded: false) else { return .discarded }
                if let heading = url.fragment(percentEncoded: false) {
                    guard let resolved = documentViewModel.resolveSectionLink(title: title, heading: heading) else { return .discarded }
                    pendingScrollTargetLineText = resolved.block?.content
                    wikilinkTarget = resolved.document
                    return .handled
                }
                guard let target = documentViewModel.resolveWikilink(title: title) else { return .discarded }
                pendingScrollTargetLineText = nil
                wikilinkTarget = target
                return .handled
            case "tag":
                isPresentingTags = true
                return .handled
            case "blockref":
                guard let anchor = url.host(percentEncoded: false), let resolved = documentViewModel.resolveBlockReference(anchor: anchor) else {
                    return .discarded
                }
                pendingScrollTargetLineText = nil
                wikilinkTarget = resolved.document
                return .handled
            default:
                return .systemAction
            }
        })
    }

}
