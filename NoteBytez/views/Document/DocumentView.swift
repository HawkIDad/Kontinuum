// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  DocumentView.swift
//  Kontinuum
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// S4 — Document (Note) View.
///
/// Uses a bespoke editor/preview toggle instead of MarkdownG9's bundled `MarkdownG9` view:
/// wikilink autocomplete needs to inspect and rewrite `viewModel.content` as the user types,
/// which the bundled component (a plain internal `TextEditor` binding) doesn't expose a hook
/// for. Preview rendering is delegated to `DocumentPreviewView`, shared with S3, which still
/// uses MarkdownG9's `MDProcessor.process(_:)` internally so formatting matches the package.
struct DocumentView: View {

    @Bindable var viewModel: DocumentViewModel

    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    @State private var isPresentingBacklinks = false
    @State private var isPresentingGraph = false
    @State private var isPresentingTags = false
    @State private var isPresentingExport = false
    @State private var wikilinkTarget: Document?
    @State private var pendingScrollTargetLineText: String?
    @State private var propertyViewModel: PropertyViewModel
    @State private var isPresentingTemplatePicker = false
    @State private var templateViewModel: TemplateViewModel?
    @State private var attachmentViewModel: AttachmentViewModel
    @State private var isPresentingAttachmentImporter = false

    /// The raw content of a `[[Note#Heading]]` section link's target block, threaded in by
    /// whichever screen navigated here so the preview can best-effort scroll to it — see
    /// `resolveSectionLink` and Decision 7 (scroll works only on the line-by-line preview path;
    /// otherwise this opens at the top like any other document, no error, no dead link).
    var scrollTargetLineText: String?

    init(viewModel: DocumentViewModel, scrollTargetLineText: String? = nil) {
        self.viewModel = viewModel
        self.scrollTargetLineText = scrollTargetLineText
        self._propertyViewModel = State(initialValue: PropertyViewModel(documentViewModel: viewModel))
        self._attachmentViewModel = State(initialValue: AttachmentViewModel(documentViewModel: viewModel))
    }

    /// A still-open Strategy 2 (Last-Write-Wins) auto-resolution for this document — "a banner
    /// lets you revert," shown as a top-of-note strip rather than requiring a trip through S9/S10.
    private var activeConflictResolution: ConflictAutoResolution? {
        guard let documentId = viewModel.document.documentId else { return nil }
        return ConflictStore.shared.autoResolution(syncId: documentId)
    }

    var body: some View {
        VStack(spacing: 0) {
            if let resolution = activeConflictResolution {
                ConflictBanner(
                    resolution: resolution,
                    onRevert: { Task { await revertConflict(resolution) } },
                    onDismiss: { ConflictStore.shared.clearAutoResolution(syncId: resolution.conflict.syncId) }
                )
                .padding(.horizontal)
                .padding(.top, 8)
            }

            TextField("Title", text: $viewModel.title)
                .font(.title2.bold())
                .padding([.horizontal, .top])

            if !viewModel.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.tags) { tag in
                            TagChip(name: tag.name ?? "") { isPresentingTags = true }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            if !propertyViewModel.resolvedProperties.isEmpty || isEditing {
                VStack(spacing: 0) {
                    ForEach(propertyViewModel.resolvedProperties) { resolved in
                        PropertyEditorRow(
                            name: resolved.property.name ?? "",
                            valueType: PropertyValueType(rawValue: resolved.property.valueType ?? "") ?? .text,
                            value: Binding(
                                get: { resolved.value },
                                set: { propertyViewModel.updateValue(key: resolved.property.name ?? "", value: $0, valueType: PropertyValueType(rawValue: resolved.property.valueType ?? "") ?? .text) }
                            ),
                            onRemove: { propertyViewModel.removeValue(key: resolved.property.name ?? "") }
                        )
                    }

                    if isEditing {
                        HStack {
                            TextField("Property name", text: $propertyViewModel.newKey)
                            Picker("Type", selection: $propertyViewModel.newValueType) {
                                ForEach(PropertyValueType.allCases, id: \.self) { valueType in
                                    Text(valueType.rawValue.capitalized).tag(valueType)
                                }
                            }
                            .labelsHidden()
                            Button("Add") { propertyViewModel.commitNewProperty() }
                                .disabled(propertyViewModel.newKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .frame(minHeight: 44)
                    }
                }
                .padding(.horizontal)
                Divider()
            }

            Group {
                if isEditing {
                    TextEditor(text: $viewModel.content)
                        .font(.body.monospaced())
                } else {
                    DocumentPreviewView(documentViewModel: viewModel, scrollTargetLineText: scrollTargetLineText)
                }
            }

            if isEditing, let query = viewModel.activeWikilinkQuery {
                if let hashIndex = query.firstIndex(of: "#") {
                    let queryTitle = String(query[query.startIndex..<hashIndex])
                    let headingQuery = String(query[query.index(after: hashIndex)...])
                    let suggestions = viewModel.headingSuggestions(forDocumentTitled: queryTitle, matching: headingQuery)
                    if !suggestions.isEmpty {
                        Divider()
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestions, id: \.self) { heading in
                                    WikilinkText(title: heading) {
                                        viewModel.insertWikilink(title: "\(queryTitle)#\(heading)")
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
                    let suggestions = viewModel.wikilinkSuggestions(matching: query)
                    if !suggestions.isEmpty {
                        Divider()
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestions, id: \.self) { title in
                                    WikilinkText(title: title) {
                                        viewModel.insertWikilink(title: title)
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

            if isEditing, let query = viewModel.activeTagQuery {
                let suggestions = viewModel.tagSuggestions(matching: query)
                if !suggestions.isEmpty {
                    Divider()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestions, id: \.self) { name in
                                TagChip(name: name) {
                                    viewModel.insertTag(name: name)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
            }

            if isEditing, let query = viewModel.activeEmbedReferenceQuery {
                let suggestions = viewModel.blockReferenceSuggestions(matching: query)
                if !suggestions.isEmpty {
                    Divider()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestions) { block in
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 2) {
                                        Text("!")
                                        BlockReferenceText(anchor: block.anchor ?? "") {
                                            viewModel.insertEmbedReference(anchor: block.anchor ?? "")
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
            } else if isEditing, let query = viewModel.activeBlockReferenceQuery {
                let suggestions = viewModel.blockReferenceSuggestions(matching: query)
                if !suggestions.isEmpty {
                    Divider()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestions) { block in
                                VStack(alignment: .leading, spacing: 2) {
                                    BlockReferenceText(anchor: block.anchor ?? "") {
                                        viewModel.insertBlockReference(anchor: block.anchor ?? "")
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

                Button {
                    isPresentingExport = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Export")

                Button {
                    isPresentingBacklinks = true
                } label: {
                    Image(systemName: "link")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Backlinks")

                Button {
                    isPresentingGraph = true
                } label: {
                    Image(systemName: "circle.grid.cross")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Graph")

                Button {
                    isPresentingTemplatePicker = true
                } label: {
                    Image(systemName: "doc.badge.plus")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Apply Template")

                Button {
                    isPresentingAttachmentImporter = true
                } label: {
                    Image(systemName: "paperclip")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Add Attachment")
            }
            .padding()
        }
        .navigationTitle(viewModel.title.isEmpty ? "Untitled" : viewModel.title)
        .noteBytezInlineNavigationTitle()
        .onAppear {
            if templateViewModel == nil, let libraryId = viewModel.document.libraryId {
                templateViewModel = TemplateViewModel(libraryId: libraryId, modelContext: modelContext)
            }
            NotificationCenter.default.post(name: .noteBytezActiveDocumentChanged, object: viewModel.document)
        }
        .onDisappear {
            viewModel.save()
            NotificationCenter.default.post(name: .noteBytezActiveDocumentChanged, object: nil)
        }
        .sheet(isPresented: $isPresentingTemplatePicker) {
            if let templateViewModel {
                TemplatePickerView(scope: viewModel.templatePickerScope(), viewModel: templateViewModel, onSelect: { template in
                    guard let template else { return }
                    viewModel.applyTemplateRetroactively(template)
                }, showsStartBlankOption: false)
            }
        }
        .environment(\.openURL, OpenURLAction { url in
            switch url.scheme {
            case "wikilink":
                guard let title = url.host(percentEncoded: false) else { return .discarded }
                if let heading = url.fragment(percentEncoded: false) {
                    guard let resolved = viewModel.resolveSectionLink(title: title, heading: heading) else { return .discarded }
                    pendingScrollTargetLineText = resolved.block?.content
                    wikilinkTarget = resolved.document
                    return .handled
                }
                guard let target = viewModel.resolveWikilink(title: title) else { return .discarded }
                pendingScrollTargetLineText = nil
                wikilinkTarget = target
                return .handled
            case "tag":
                isPresentingTags = true
                return .handled
            case "blockref":
                guard let anchor = url.host(percentEncoded: false), let resolved = viewModel.resolveBlockReference(anchor: anchor) else {
                    return .discarded
                }
                pendingScrollTargetLineText = nil
                wikilinkTarget = resolved.document
                return .handled
            default:
                return .systemAction
            }
        })
        .navigationDestination(item: $wikilinkTarget) { target in
            DocumentView(viewModel: DocumentViewModel(document: target, modelContext: modelContext), scrollTargetLineText: pendingScrollTargetLineText)
        }
        .sheet(isPresented: $isPresentingBacklinks) {
            NavigationStack {
                BacklinksPaneView(viewModel: BacklinksViewModel(document: viewModel.document, modelContext: modelContext))
            }
        }
        .sheet(isPresented: $isPresentingGraph) {
            NavigationStack {
                GraphView(viewModel: GraphViewModel(document: viewModel.document, modelContext: modelContext))
            }
        }
        .sheet(isPresented: $isPresentingTags) {
            NavigationStack {
                TagBrowserView(viewModel: TagViewModel(libraryId: viewModel.document.libraryId ?? UUID(), modelContext: modelContext))
            }
        }
        .fileExporter(
            isPresented: $isPresentingExport,
            document: MarkdownFileDocument(text: ExportDAL.exportableContent(for: viewModel.document, in: modelContext)),
            contentType: UTType(filenameExtension: "md") ?? .plainText,
            defaultFilename: viewModel.title.isEmpty ? "Untitled" : viewModel.title
        ) { _ in }
        .fileImporter(isPresented: $isPresentingAttachmentImporter, allowedContentTypes: [.image, .pdf]) { result in
            guard let fileURL = try? result.get() else { return }
            let mimeType = UTType(filenameExtension: fileURL.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
            attachmentViewModel.attach(fileURL: fileURL, mimeType: mimeType)
        }
    }

    private func revertConflict(_ resolution: ConflictAutoResolution) async {
        let opposite: ConflictResolutionChoice = resolution.kept == .keepClient ? .keepServer : .keepClient
        await SyncEngine.shared.resolveConflict(resolution.conflict, choice: opposite, in: modelContext)
        viewModel.reload()
    }

}
