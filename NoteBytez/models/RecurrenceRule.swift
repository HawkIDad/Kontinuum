// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  RecurrenceRule.swift
//  NoteBytez
//

import Foundation

/// Parses/serializes `TaskItem.recurrenceRule`'s opaque `String?` storage (reserved ahead of
/// this phase, per `NoteBytez-R1-Implementation.md` Phase 0) and computes the next occurrence
/// date. Deliberately a small, fixed set of intervals rather than an RFC 5545 RRULE parser —
/// "next-occurrence calculation, not a full calendar engine," per
/// NoteBytez-ReleaseFeatures.md's Version 1 scope for Task Dashboards. Not a `@Model` — a pure
/// value type, same pattern as `PropertyValueType`. `nonisolated`: opted out of this target's
/// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — otherwise its `Equatable` conformance is itself
/// MainActor-isolated, which test assertions (`#expect(a == b)`, generated as nonisolated code)
/// can't call into (a warning today, a Swift 6 language-mode error).
nonisolated enum RecurrenceRule: Equatable {

    case daily
    case weekly
    case monthly
    case everyNDays(Int)

    var rawValue: String {
        switch self {
        case .daily: return "daily"
        case .weekly: return "weekly"
        case .monthly: return "monthly"
        case .everyNDays(let days): return "every:\(days)"
        }
    }

    init?(rawValue: String) {
        switch rawValue {
        case "daily": self = .daily
        case "weekly": self = .weekly
        case "monthly": self = .monthly
        default:
            guard rawValue.hasPrefix("every:"), let days = Int(rawValue.dropFirst("every:".count)), days > 0 else { return nil }
            self = .everyNDays(days)
        }
    }

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .everyNDays(let days): return "Every \(days) day\(days == 1 ? "" : "s")"
        }
    }

    /// `nil` only if `Calendar` itself fails to compute a date (not expected in practice for
    /// these small, fixed offsets).
    func nextOccurrence(after date: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .daily: return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly: return calendar.date(byAdding: .day, value: 7, to: date)
        case .monthly: return calendar.date(byAdding: .month, value: 1, to: date)
        case .everyNDays(let days): return calendar.date(byAdding: .day, value: days, to: date)
        }
    }

}
