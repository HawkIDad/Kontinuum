// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TranslationIssueReport.swift
//  NoteBytez
//

import Foundation

/// Phase 12.1 (NoteBytez20260823v2-MultiLanguage.md): the "Report a Translation Issue"
/// affordance's payload. Free-text fields rather than an automatically-captured catalog key —
/// this app has no reusable `Text` wrapper every label passes through (confirmed absent
/// app-wide), so instrumenting "any label" would mean touching every view file; the user
/// instead describes what they saw, matching G12's "AI-only, fix on report" bar without an
/// invasive refactor.
struct TranslationIssueReport {

    let locale: String
    let screen: String
    let observedText: String
    let expectedText: String
    let additionalDetails: String
    let appVersion: String

    static let recipientEmail = "support@notebytez.app"

    var emailSubject: String {
        "NoteBytez Translation Issue (\(locale))"
    }

    var emailBody: String {
        var lines = ["Language: \(locale)", "App version: \(appVersion)"]
        if !screen.isBlank {
            lines.append("Screen: \(screen)")
        }
        lines.append("")
        lines.append("What I saw:")
        lines.append(observedText)
        if !expectedText.isBlank {
            lines.append("")
            lines.append("What it should say:")
            lines.append(expectedText)
        }
        if !additionalDetails.isBlank {
            lines.append("")
            lines.append("Additional details:")
            lines.append(additionalDetails)
        }
        return lines.joined(separator: "\n")
    }

    /// `nil` when there's nothing worth sending — the observed-text field is the only required
    /// one (screen/expected text/additional details are all optional context).
    var mailtoURL: URL? {
        guard !observedText.isBlank else { return nil }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Self.recipientEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: emailSubject),
            URLQueryItem(name: "body", value: emailBody),
        ]
        return components.url
    }

}

private extension String {
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
