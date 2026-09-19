// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TranslationIssueReportViewModel.swift
//  NoteBytez
//

import Foundation
import Observation

/// Form state behind `TranslationIssueReportView` (Phase 12.1). Locale and app version are
/// captured automatically; everything else is free text the user supplies.
@Observable
final class TranslationIssueReportViewModel {

    var screen: String = ""
    var observedText: String = ""
    var expectedText: String = ""
    var additionalDetails: String = ""
    var didCopyReport = false

    private let locale: String
    private let appVersion: String

    init(locale: String = Locale.current.identifier, appVersion: String = TranslationIssueReportViewModel.currentAppVersion()) {
        self.locale = locale
        self.appVersion = appVersion
    }

    var report: TranslationIssueReport {
        TranslationIssueReport(locale: locale, screen: screen, observedText: observedText, expectedText: expectedText, additionalDetails: additionalDetails, appVersion: appVersion)
    }

    static func currentAppVersion() -> String {
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(shortVersion) (\(build))"
    }

}
