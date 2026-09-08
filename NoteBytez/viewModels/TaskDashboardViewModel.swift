// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TaskDashboardViewModel.swift
//  NoteBytez
//

import Foundation
import SwiftData
import Observation

/// Drives S19 (Task Dashboard) — the cross-note task query MVP's per-document `TaskItem.fetchActive`
/// couldn't answer. Toggling here goes through `TaskDAL.toggle(_:in:)`, not
/// `DocumentViewModel.toggleTask(at:)` — see that method's own doc comment for why a
/// whole-document-content index doesn't fit a dashboard reaching into documents it hasn't loaded.
@Observable
final class TaskDashboardViewModel {

    enum StatusFilter: String, CaseIterable, Identifiable {
        case open = "Open"
        case done = "Done"
        case all = "All"
        var id: String { rawValue }
    }

    enum DateFilter: String, CaseIterable, Identifiable {
        case any = "Any"
        case overdue = "Overdue"
        case dueToday = "Due Today"
        case dueThisWeek = "Due This Week"
        var id: String { rawValue }
    }

    /// A `TaskItem` paired with its owning document's title — resolved once on `load()` rather
    /// than per-row, since a dashboard can list tasks from many documents at once.
    struct DashboardTask: Identifiable {
        let task: TaskItem
        let documentTitle: String
        var id: UUID { task.taskItemId ?? UUID() }
    }

    private(set) var dashboardTasks: [DashboardTask] = []
    var statusFilter: StatusFilter = .open
    var dateFilter: DateFilter = .any
    /// Filters by the *owning document's* tags — a task has no tagging concept of its own in
    /// this data model, per NoteBytez-ReleaseFeatures.md (no `TaskTag` join exists or is asked
    /// for); reuses `TagDAL` directly rather than inventing one, per this phase's own plan.
    var tagFilter: String = ""

    /// Not `private` — `SavedViewViewModel` (Phase 7) composes a `TaskDashboardViewModel`
    /// directly (setting its filters from a saved definition, reading `filteredTasks` back) to
    /// re-evaluate a saved task query, rather than duplicating this filter logic a second time.
    let libraryId: UUID
    private let modelContext: ModelContext

    init(libraryId: UUID, modelContext: ModelContext) {
        self.libraryId = libraryId
        self.modelContext = modelContext
        load()
    }

    func load() {
        let tasks = TaskDAL.fetchActive(libraryId: libraryId, in: modelContext)
        let titlesByDocumentId = Dictionary(uniqueKeysWithValues: DocumentDAL.fetchActive(libraryId: libraryId, in: modelContext).compactMap { document -> (UUID, String)? in
            guard let documentId = document.documentId else { return nil }
            return (documentId, document.title ?? "Untitled")
        })
        dashboardTasks = tasks.map { task in
            DashboardTask(task: task, documentTitle: task.documentId.flatMap { titlesByDocumentId[$0] } ?? "Untitled")
        }
    }

    var filteredTasks: [DashboardTask] {
        dashboardTasks.filter { matchesStatus($0.task) && matchesDate($0.task) && matchesTag($0.task) }
    }

    func toggle(_ dashboardTask: DashboardTask) {
        TaskDAL.toggle(dashboardTask.task, in: modelContext)
        load()
    }

    private func matchesStatus(_ task: TaskItem) -> Bool {
        switch statusFilter {
        case .all: return true
        case .open: return task.isDone != true
        case .done: return task.isDone == true
        }
    }

    private func matchesDate(_ task: TaskItem) -> Bool {
        guard dateFilter != .any else { return true }
        guard let dueDate = task.dueDate else { return false }

        let calendar = Calendar.current
        switch dateFilter {
        case .any:
            return true
        case .overdue:
            return dueDate < calendar.startOfDay(for: Date()) && task.isDone != true
        case .dueToday:
            return calendar.isDateInToday(dueDate)
        case .dueThisWeek:
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return false }
            return weekInterval.contains(dueDate)
        }
    }

    private func matchesTag(_ task: TaskItem) -> Bool {
        let trimmed = tagFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        guard let documentId = task.documentId else { return false }
        return TagDAL.fetchTags(for: documentId, in: modelContext).contains { ($0.name ?? "").localizedCaseInsensitiveContains(trimmed) }
    }

}
