// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  JournalDALTests.swift
//  KontinuumTests
//

import Testing
import SwiftData
import Foundation
@testable import Kontinuum

struct JournalDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Tag.self, DocumentTag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private var referenceDate: Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 13, hour: 15))!
    }

    @Test func fetchOrCreateReturnsTheSameDocumentOnRepeatedCallsForTheSameDay() throws {
        let context = try makeContext()
        let libraryId = UUID()

        let first = JournalDAL.fetchOrCreate(for: referenceDate, libraryId: libraryId, in: context)
        let second = JournalDAL.fetchOrCreate(for: referenceDate, libraryId: libraryId, in: context)

        #expect(first.documentId == second.documentId)
    }

    @Test func fetchOrCreateIsIdempotentAcrossDifferentTimesOnTheSameCalendarDay() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let morning = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 13, hour: 7))!
        let evening = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 13, hour: 22))!

        let first = JournalDAL.fetchOrCreate(for: morning, libraryId: libraryId, in: context)
        let second = JournalDAL.fetchOrCreate(for: evening, libraryId: libraryId, in: context)

        #expect(first.documentId == second.documentId)
    }

    @Test func fetchOrCreateScopesByLibrary() throws {
        let context = try makeContext()
        let libraryOne = UUID()
        let libraryTwo = UUID()

        let first = JournalDAL.fetchOrCreate(for: referenceDate, libraryId: libraryOne, in: context)
        let second = JournalDAL.fetchOrCreate(for: referenceDate, libraryId: libraryTwo, in: context)

        #expect(first.documentId != second.documentId)
    }

    @Test func fetchOrCreateMarksTheDocumentAsAJournalEntryWithANormalizedDate() throws {
        let context = try makeContext()
        let libraryId = UUID()

        let document = JournalDAL.fetchOrCreate(for: referenceDate, libraryId: libraryId, in: context)

        #expect(document.isJournalEntry == true)
        #expect(document.journalDate == JournalDAL.startOfDay(referenceDate))
    }

    @Test func fetchReturnsNilWhenNoEntryExistsYet() throws {
        let context = try makeContext()
        let libraryId = UUID()

        #expect(JournalDAL.fetch(for: referenceDate, libraryId: libraryId, in: context) == nil)
    }

    @Test func previousAndNextDateCrossAMonthBoundary() {
        let lastDayOfAugust = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 31))!
        let firstDayOfSeptember = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 1))!

        #expect(JournalDAL.nextDate(after: lastDayOfAugust) == firstDayOfSeptember)
        #expect(JournalDAL.previousDate(before: firstDayOfSeptember) == lastDayOfAugust)
    }

    @Test func previousAndNextDateCrossAYearBoundary() {
        let lastDayOfYear = Calendar.current.date(from: DateComponents(year: 2026, month: 12, day: 31))!
        let firstDayOfNextYear = Calendar.current.date(from: DateComponents(year: 2027, month: 1, day: 1))!

        #expect(JournalDAL.nextDate(after: lastDayOfYear) == firstDayOfNextYear)
        #expect(JournalDAL.previousDate(before: firstDayOfNextYear) == lastDayOfYear)
    }

    @Test func canNavigateToNextDayIsFalseAtToday() {
        let today = referenceDate
        #expect(JournalDAL.canNavigateToNextDay(from: today, today: today) == false)
    }

    @Test func canNavigateToNextDayIsTrueForAPastDay() {
        let today = referenceDate
        let yesterday = JournalDAL.previousDate(before: today)
        #expect(JournalDAL.canNavigateToNextDay(from: yesterday, today: today) == true)
    }

    @Test func canNavigateToNextDayIgnoresTimeOfDayWithinToday() {
        let morning = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 13, hour: 7))!
        let evening = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 13, hour: 22))!
        #expect(JournalDAL.canNavigateToNextDay(from: morning, today: evening) == false)
    }

}
