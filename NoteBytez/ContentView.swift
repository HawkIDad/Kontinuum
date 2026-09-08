// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ContentView.swift
//  Kontinuum
//

import SwiftUI
import SwiftData

/// Top-level app destinations. Per `UIUX/04-InteractionDesign.md`'s per-platform navigation
/// shell (NoteBytez20260829v1-FlowEnhancements.md Decision 2): Mac/iPad show a sectioned
/// sidebar — **Capture** (Today), **Library** (Notebooks, All Notes, Tags), **Explore**
/// (Search, Graph, Insights, Tasks, Saved Views, Canvas) — then Settings outside any section.
/// iPhone/iPad-compact show a 5-tab bar: Today, Notebooks, Search, Explore (a hub pushing to
/// every Explore-section destination plus Tags and the Command Palette), Settings.
enum AppDestination: String, CaseIterable, Identifiable {

    case today = "Today"
    case notebooks = "Notebooks"
    case allNotes = "All Notes"
    case tags = "Tags"
    case search = "Search"
    case graph = "Graph"
    case insights = "Insights"
    case tasks = "Tasks"
    case savedViews = "Saved Views"
    case canvas = "Canvas"
    case explore = "Explore"
    case settings = "Settings"

    /// The Mac/iPad sidebar grouping (Decision 2). `.explore` and `.settings` are each their
    /// own section of exactly one conceptual member — the destination itself — since neither
    /// gets a sidebar row grouped under another heading: `.explore` is a tab-only hub (its
    /// members render directly under the Explore *section* on Mac/iPad, per `sidebarRows`), and
    /// `.settings` renders outside any section entirely.
    enum Section: CaseIterable, Hashable {
        case capture, library, explore, settings

        var title: String {
            switch self {
            case .capture: return "Capture"
            case .library: return "Library"
            case .explore: return "Explore"
            case .settings: return "Settings"
            }
        }
    }

    var id: String { rawValue }

    var section: Section {
        switch self {
        case .today: return .capture
        case .notebooks, .allNotes, .tags: return .library
        case .search, .graph, .insights, .tasks, .savedViews, .canvas: return .explore
        case .explore: return .explore
        case .settings: return .settings
        }
    }

    var systemImage: String {
        switch self {
        case .today: return "square.and.pencil"
        case .allNotes: return "doc.text"
        case .notebooks: return "books.vertical"
        case .search: return "magnifyingglass"
        case .tags: return "tag"
        case .graph: return "circle.grid.cross"
        case .insights: return "lightbulb"
        case .canvas: return "square.grid.2x2"
        case .tasks: return "checklist"
        case .savedViews: return "pin"
        case .explore: return "ellipsis.circle"
        case .settings: return "gearshape"
        }
    }

    /// Mac/iPad sidebar sections, in display order. `.settings` is deliberately excluded —
    /// it's rendered as its own row outside every section (Decision 2).
    static var sidebarSections: [Section] { [.capture, .library, .explore] }

    /// Sidebar rows for `section`, in declaration order — excludes `.explore` itself (a
    /// tab-only hub with no sidebar row of its own; Mac/iPad show its members directly).
    static func sidebarRows(in section: Section) -> [AppDestination] {
        allCases.filter { $0.section == section && $0 != .explore }
    }

    /// The six destinations `ExploreHubView` (S27) pushes to on iPhone: every Explore-section
    /// destination *except* Search (which already has its own tab) plus `.tags` (under Library
    /// on Mac/iPad, but with no dedicated tab or Library home of its own on iPhone, so the hub
    /// is its iPhone reachability path too).
    static var exploreHubDestinations: [AppDestination] {
        [.graph, .insights, .tasks, .savedViews, .canvas, .tags]
    }

    static var tabBarDestinations: [AppDestination] {
        [.today, .notebooks, .search, .explore, .settings]
    }

}

struct ContentView: View {

    let library: Library

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: AppDestination = .today
    @State private var selectedSidebarDestination: AppDestination? = .today
    @State private var isPresentingSyncStatus = false
    @State private var isPresentingCommandPalette = false
    @State private var isPresentingQuickSwitcher = false
    @State private var quickSwitchTarget: Document?
    @State private var sentCanvasBoard: CanvasBoard?
    @State private var activeDocument: Document?
    @State private var activeCanvasBoard: CanvasBoard?
    @State private var infoAlertMessage: String?

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                TabView(selection: $selectedTab) {
                    ForEach(AppDestination.tabBarDestinations) { destination in
                        NavigationStack {
                            DestinationView(destination: destination, library: library)
                                .toolbar { syncStatusToolbarItem }
                                .navigationDestination(item: $quickSwitchTarget) { document in
                                    DocumentView(viewModel: DocumentViewModel(document: document, modelContext: modelContext))
                                }
                                .navigationDestination(item: $sentCanvasBoard) { board in
                                    CanvasBoardView(viewModel: CanvasViewModel(libraryId: library.libraryId ?? UUID(), modelContext: modelContext), board: board)
                                }
                        }
                        .tabItem {
                            Label(destination.rawValue, systemImage: destination.systemImage)
                                .accessibilityIdentifier("tabbar.\(destination.rawValue)")
                        }
                        .tag(destination)
                    }
                }
                .sheet(isPresented: $isPresentingSyncStatus) { syncStatusSheet }
            } else {
                NavigationSplitView {
                    List(selection: $selectedSidebarDestination) {
                        ForEach(AppDestination.sidebarSections, id: \.self) { section in
                            Section(section.title) {
                                ForEach(AppDestination.sidebarRows(in: section)) { destination in
                                    Label(destination.rawValue, systemImage: destination.systemImage)
                                        .tag(destination)
                                        .accessibilityIdentifier("sidebar.\(destination.rawValue)")
                                }
                            }
                        }
                        Label(AppDestination.settings.rawValue, systemImage: AppDestination.settings.systemImage)
                            .tag(AppDestination.settings)
                            .accessibilityIdentifier("sidebar.\(AppDestination.settings.rawValue)")
                    }
                    .navigationTitle("NoteBytez")
                    .toolbar { syncStatusToolbarItem }
                } detail: {
                    NavigationStack {
                        DestinationView(destination: selectedSidebarDestination ?? .today, library: library)
                            .navigationDestination(item: $quickSwitchTarget) { document in
                                DocumentView(viewModel: DocumentViewModel(document: document, modelContext: modelContext))
                            }
                            .navigationDestination(item: $sentCanvasBoard) { board in
                                CanvasBoardView(viewModel: CanvasViewModel(libraryId: library.libraryId ?? UUID(), modelContext: modelContext), board: board)
                            }
                    }
                }
                .sheet(isPresented: $isPresentingSyncStatus) { syncStatusSheet }
            }
        }
        .sheet(isPresented: $isPresentingCommandPalette) {
            CommandPaletteView(viewModel: CommandPaletteViewModel(
                onNavigate: { navigate(to: $0) },
                onAction: { run($0) }
            ))
        }
        .sheet(isPresented: $isPresentingQuickSwitcher) {
            NavigationStack {
                QuickSwitcherView(
                    viewModel: SearchViewModel(libraryId: library.libraryId ?? UUID(), modelContext: modelContext),
                    onSelect: { document in quickSwitchTarget = document }
                )
            }
        }
        .alert("NoteBytez", isPresented: Binding(
            get: { infoAlertMessage != nil },
            set: { if !$0 { infoAlertMessage = nil } }
        )) {
            Button("OK") { infoAlertMessage = nil }
        } message: {
            Text(infoAlertMessage ?? "")
        }
        // Menu-bar commands (`NoteBytezApp`'s `.commands {}`) live at the `App` level, above
        // this view's navigation state, so they post here rather than calling in directly.
        .onReceive(NotificationCenter.default.publisher(for: .kontinuumNewNote)) { _ in
            navigate(to: .allNotes)
        }
        .onReceive(NotificationCenter.default.publisher(for: .kontinuumOpenSettings)) { _ in
            navigate(to: .settings)
        }
        .onReceive(NotificationCenter.default.publisher(for: .kontinuumOpenCommandPalette)) { _ in
            isPresentingCommandPalette = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .kontinuumOpenQuickSwitcher)) { _ in
            isPresentingQuickSwitcher = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .kontinuumRunAction)) { notification in
            guard let action = notification.object as? AppAction else { return }
            run(action)
        }
        .onReceive(NotificationCenter.default.publisher(for: .kontinuumNavigate)) { notification in
            guard let destination = notification.object as? AppDestination else { return }
            navigate(to: destination)
        }
        .onReceive(NotificationCenter.default.publisher(for: .kontinuumActiveDocumentChanged)) { notification in
            activeDocument = notification.object as? Document
        }
        .onReceive(NotificationCenter.default.publisher(for: .kontinuumActiveCanvasBoardChanged)) { notification in
            activeCanvasBoard = notification.object as? CanvasBoard
        }
    }

    private func navigate(to destination: AppDestination) {
        selectedSidebarDestination = destination
        if AppDestination.tabBarDestinations.contains(destination) {
            selectedTab = destination
        }
    }

    /// Executes a palette/menu `AppAction`. Navigation-then-trigger actions post a
    /// destination-local notification (`.kontinuumTrigger*`) that the freshly-navigated screen
    /// picks up to open the same sheet its own toolbar button would — same two-hop shape
    /// `.kontinuumOpenSettings` already established.
    private func run(_ action: AppAction) {
        switch action {
        case .newNote:
            navigate(to: .allNotes)
        case .newNotebook:
            navigate(to: .notebooks)
            NotificationCenter.default.post(name: .kontinuumTriggerNewNotebook, object: nil)
        case .newCanvasBoard:
            navigate(to: .canvas)
            NotificationCenter.default.post(name: .kontinuumTriggerNewCanvasBoard, object: nil)
        case .promoteToNotebook:
            navigate(to: .today)
            NotificationCenter.default.post(name: .kontinuumTriggerPromote, object: nil)
        case .sendCurrentNoteToCanvas:
            guard let document = activeDocument, let libraryId = document.libraryId else {
                infoAlertMessage = "Open a note first, then send its map to Canvas."
                return
            }
            sentCanvasBoard = CanvasDAL.seedBoard(fromNeighborhoodOf: document, libraryId: libraryId, in: modelContext)
        case .syncNow:
            Task { await SyncEngine.shared.syncNow() }
        case .importMarkdown:
            infoAlertMessage = "Importing a Markdown folder creates a new library — start one from the library picker (available when no library is open)."
        case .openSettings:
            navigate(to: .settings)
        case .bindCurrentCanvasToNote:
            guard activeCanvasBoard != nil else {
                infoAlertMessage = "Open a canvas board first, then bind it to a note."
                return
            }
            NotificationCenter.default.post(name: .kontinuumTriggerBindCanvas, object: nil)
        case .openNoteAsBoundCanvas:
            guard let document = activeDocument, let libraryId = document.libraryId else {
                infoAlertMessage = "Open a note first, then open it as a bound canvas."
                return
            }
            sentCanvasBoard = CanvasDAL.boundBoard(for: document, libraryId: libraryId, in: modelContext)
        }
    }

    /// Persistent across every destination (not just Today/Document) so sync/conflict state —
    /// Kontinuum's own visual language, with no equivalent in Obsidian/Logseq's native UI — stays
    /// visible regardless of where the user is browsing, per `docs/styleGuide.md`'s "Offline"
    /// convention that a timestamp/status should always be on screen.
    private var syncStatusToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            SyncStatusGlyph(viewModel: SyncStatusViewModel(libraryId: library.libraryId)) {
                isPresentingSyncStatus = true
            }
        }
    }

    private var syncStatusSheet: some View {
        NavigationStack {
            SyncStatusView(viewModel: SyncStatusViewModel(libraryId: library.libraryId))
        }
    }

}

private struct DestinationView: View {

    let destination: AppDestination
    let library: Library

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        switch destination {
        case .today:
            if let libraryId = library.libraryId {
                TodayJournalView(libraryId: libraryId)
            } else {
                Text(destination.rawValue)
                    .navigationTitle(destination.rawValue)
            }
        case .allNotes:
            if let libraryId = library.libraryId {
                DocumentListView(libraryId: libraryId)
            } else {
                Text(destination.rawValue)
                    .navigationTitle(destination.rawValue)
            }
        case .tags:
            if let libraryId = library.libraryId {
                TagBrowserView(viewModel: TagViewModel(libraryId: libraryId, modelContext: modelContext))
            } else {
                Text(destination.rawValue)
                    .navigationTitle(destination.rawValue)
            }
        case .notebooks:
            if let libraryId = library.libraryId {
                NotebookBrowserView(viewModel: NotebookViewModel(libraryId: libraryId, modelContext: modelContext))
            } else {
                Text(destination.rawValue)
                    .navigationTitle(destination.rawValue)
            }
        case .search:
            if let libraryId = library.libraryId {
                SearchView(viewModel: SearchViewModel(libraryId: libraryId, modelContext: modelContext))
            } else {
                Text(destination.rawValue)
                    .navigationTitle(destination.rawValue)
            }
        case .graph:
            if let libraryId = library.libraryId {
                TodayGraphView(libraryId: libraryId)
            } else {
                Text(destination.rawValue)
                    .navigationTitle(destination.rawValue)
            }
        case .canvas:
            if let libraryId = library.libraryId {
                CanvasBoardListView(viewModel: CanvasViewModel(libraryId: libraryId, modelContext: modelContext))
            } else {
                Text(destination.rawValue)
                    .navigationTitle(destination.rawValue)
            }
        case .tasks:
            if let libraryId = library.libraryId {
                TaskDashboardView(viewModel: TaskDashboardViewModel(libraryId: libraryId, modelContext: modelContext))
            } else {
                Text(destination.rawValue)
                    .navigationTitle(destination.rawValue)
            }
        case .savedViews:
            if let libraryId = library.libraryId {
                SavedViewsListView(viewModel: SavedViewViewModel(libraryId: libraryId, modelContext: modelContext))
            } else {
                Text(destination.rawValue)
                    .navigationTitle(destination.rawValue)
            }
        case .insights:
            if let libraryId = library.libraryId {
                GraphInsightsView(viewModel: GraphInsightsViewModel(libraryId: libraryId, modelContext: modelContext))
            } else {
                Text(destination.rawValue)
                    .navigationTitle(destination.rawValue)
            }
        case .explore:
            ExploreHubView(library: library)
        case .settings:
            SettingsView(library: library)
        }
    }

}

#Preview {
    ContentView(library: Library(name: "Preview Library"))
}
