// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  DriftReport.swift
//  translate-strings
//

import Foundation

/// Phase 0.7 (G13) — lists keys that are missing, `new`, or `stale` for each shipped locale.
/// **Non-blocking by design**: this always exits 0 and is meant to be surfaced as a CI
/// *annotation/warning*, not a failing check — a missing translation falls back to `en-US` at
/// runtime (G13), so it is never a broken build, only unfinished work worth flagging.
enum DriftReport {

    struct LocaleReport {
        let locale: String
        let missing: [String]
        let stale: [String]
        var isClean: Bool { missing.isEmpty && stale.isEmpty }
    }

    /// `locales` is the set of locales to report on — typically "every locale a Tier/Phase has
    /// already shipped" (`SupportedLocales`, once Phase 5 exists), not the full 24-locale target
    /// list, so an as-yet-unshipped locale doesn't show as 100% "missing" noise.
    static func generate(catalog: StringCatalog, locales: [String]) -> [LocaleReport] {
        let translatableEntries = catalog.entries.filter { !$0.isPluralVariant }

        return locales.map { locale in
            var missing: [String] = []
            var stale: [String] = []
            for entry in translatableEntries {
                guard let state = entry.state(for: locale) else {
                    missing.append(entry.key)
                    continue
                }
                if state == "needs_review" || state == "stale" {
                    stale.append(entry.key)
                }
            }
            return LocaleReport(locale: locale, missing: missing.sorted(), stale: stale.sorted())
        }
    }

    static func printReport(_ reports: [LocaleReport]) {
        for report in reports {
            if report.isClean {
                print("✔ \(report.locale): clean (no missing/stale keys)")
                continue
            }
            print("⚠ \(report.locale): \(report.missing.count) missing, \(report.stale.count) stale")
            for key in report.missing.prefix(20) { print("    missing: \(key)") }
            if report.missing.count > 20 { print("    … and \(report.missing.count - 20) more") }
            for key in report.stale.prefix(20) { print("    stale:   \(key)") }
            if report.stale.count > 20 { print("    … and \(report.stale.count - 20) more") }
        }
    }

}
