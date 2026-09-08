// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  JournalViewModel.swift
//  NoteBytez
//

import Foundation
import SwiftData
import Observation

/// Drives S3 (Today/Journal): the currently displayed day plus a `DocumentViewModel` for that
/// day's auto-created journal entry, swapped out wholesale on Previous/Next navigation.
@Observable
final class JournalViewModel {

    private(set) var date: Date
    private(set) var documentViewModel: DocumentViewModel

    private let libraryId: UUID
    private let modelContext: ModelContext

    init(libraryId: UUID, modelContext: ModelContext, date: Date = Date()) {
        self.libraryId = libraryId
        self.modelContext = modelContext

        let normalizedDate = JournalDAL.startOfDay(date)
        self.date = normalizedDate
        let document = JournalDAL.fetchOrCreate(for: normalizedDate, libraryId: libraryId, in: modelContext)
        self.documentViewModel = DocumentViewModel(document: document, modelContext: modelContext)
    }

    var canGoToNextDay: Bool {
        JournalDAL.canNavigateToNextDay(from: date)
    }

    func goToPreviousDay() {
        navigate(to: JournalDAL.previousDate(before: date))
    }

    func goToNextDay() {
        guard canGoToNextDay else { return }
        navigate(to: JournalDAL.nextDate(after: date))
    }

    private func navigate(to newDate: Date) {
        documentViewModel.save()
        date = newDate
        let document = JournalDAL.fetchOrCreate(for: newDate, libraryId: libraryId, in: modelContext)
        documentViewModel = DocumentViewModel(document: document, modelContext: modelContext)
    }

}
