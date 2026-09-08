// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  RecurrenceRuleTests.swift
//  KontinuumTests
//

import Testing
import Foundation
@testable import Kontinuum

struct RecurrenceRuleTests {

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    // MARK: - Round trip

    @Test func rawValueRoundTripsForEveryCase() {
        for rule: RecurrenceRule in [.daily, .weekly, .monthly, .everyNDays(3)] {
            #expect(RecurrenceRule(rawValue: rule.rawValue) == rule)
        }
    }

    @Test func initFromRawValueReturnsNilForUnknownStrings() {
        #expect(RecurrenceRule(rawValue: "fortnightly") == nil)
        #expect(RecurrenceRule(rawValue: "every:") == nil)
        #expect(RecurrenceRule(rawValue: "every:0") == nil)
        #expect(RecurrenceRule(rawValue: "every:-2") == nil)
        #expect(RecurrenceRule(rawValue: "") == nil)
    }

    @Test func everyNDaysRawValueEncodesTheCount() {
        #expect(RecurrenceRule.everyNDays(5).rawValue == "every:5")
        #expect(RecurrenceRule(rawValue: "every:5") == .everyNDays(5))
    }

    // MARK: - nextOccurrence

    @Test func dailyAdvancesByOneDay() {
        let start = utcCalendar.date(from: DateComponents(year: 2026, month: 8, day: 20))!
        let next = RecurrenceRule.daily.nextOccurrence(after: start, calendar: utcCalendar)
        #expect(next == utcCalendar.date(from: DateComponents(year: 2026, month: 8, day: 21)))
    }

    @Test func weeklyAdvancesBySevenDays() {
        let start = utcCalendar.date(from: DateComponents(year: 2026, month: 8, day: 20))!
        let next = RecurrenceRule.weekly.nextOccurrence(after: start, calendar: utcCalendar)
        #expect(next == utcCalendar.date(from: DateComponents(year: 2026, month: 8, day: 27)))
    }

    @Test func monthlyAdvancesByOneCalendarMonth() {
        let start = utcCalendar.date(from: DateComponents(year: 2026, month: 8, day: 20))!
        let next = RecurrenceRule.monthly.nextOccurrence(after: start, calendar: utcCalendar)
        #expect(next == utcCalendar.date(from: DateComponents(year: 2026, month: 9, day: 20)))
    }

    @Test func everyNDaysAdvancesByThatManyDays() {
        let start = utcCalendar.date(from: DateComponents(year: 2026, month: 8, day: 20))!
        let next = RecurrenceRule.everyNDays(10).nextOccurrence(after: start, calendar: utcCalendar)
        #expect(next == utcCalendar.date(from: DateComponents(year: 2026, month: 8, day: 30)))
    }

    @Test func monthlyRolloverCrossesAYearBoundary() {
        let start = utcCalendar.date(from: DateComponents(year: 2026, month: 12, day: 15))!
        let next = RecurrenceRule.monthly.nextOccurrence(after: start, calendar: utcCalendar)
        #expect(next == utcCalendar.date(from: DateComponents(year: 2027, month: 1, day: 15)))
    }

}
