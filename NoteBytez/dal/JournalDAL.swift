// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  JournalDAL.swift
//  NoteBytez
//

import Foundation
import SwiftData

/// Journal entries are ordinary `Document`s flagged `isJournalEntry` with a normalized
/// `journalDate` — one per calendar day, looked up idempotently rather than tracked by a
/// separate model.
enum JournalDAL {

    static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    static func previousDate(before date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: -1, to: startOfDay(date, calendar: calendar)) ?? date
    }

    static func nextDate(after date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: 1, to: startOfDay(date, calendar: calendar)) ?? date
    }

    /// Journal navigation never moves past today — there's nothing to write in a future day yet.
    static func canNavigateToNextDay(from date: Date, today: Date = Date(), calendar: Calendar = .current) -> Bool {
        startOfDay(date, calendar: calendar) < startOfDay(today, calendar: calendar)
    }

    static func title(for date: Date) -> String {
        date.formatted(date: .complete, time: .omitted)
    }

    /// Basic journal template: a single empty bullet, ready to capture the first entry —
    /// matches the free-text bullet style shown throughout UIUX/05-Wireframes.md's S3.
    static func template(for date: Date) -> String {
        "- "
    }

    static func fetch(for date: Date, libraryId: UUID, in context: ModelContext) -> Document? {
        let day = startOfDay(date)
        let predicate = #Predicate<Document> { document in
            document.libraryId == libraryId && document.isJournalEntry == true && document.journalDate == day
        }
        let descriptor = FetchDescriptor<Document>(predicate: predicate)
        let candidates = (try? context.fetch(descriptor)) ?? []
        return candidates.first { $0.isActive == true }
    }

    /// Idempotent: repeated calls for the same day (including across separate app opens)
    /// return the same `Document` rather than creating a duplicate.
    @discardableResult
    static func fetchOrCreate(for date: Date, libraryId: UUID, in context: ModelContext) -> Document {
        let day = startOfDay(date)
        if let existing = fetch(for: day, libraryId: libraryId, in: context) {
            return existing
        }

        let document = DocumentDAL.create(title: title(for: day), content: template(for: day), libraryId: libraryId, in: context)
        document.isJournalEntry = true
        document.journalDate = day
        return document
    }

}
