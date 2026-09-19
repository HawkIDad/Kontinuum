// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TranslationIssueReportTests.swift
//  NoteBytezTests
//

import Testing
import Foundation
@testable import NoteBytez

struct TranslationIssueReportTests {

    @Test func emailBodyIncludesLocaleAppVersionAndObservedText() {
        let report = TranslationIssueReport(locale: "de", screen: "", observedText: "Falsches Wort", expectedText: "", additionalDetails: "", appVersion: "1.0 (42)")
        #expect(report.emailBody.contains("Language: de"))
        #expect(report.emailBody.contains("App version: 1.0 (42)"))
        #expect(report.emailBody.contains("Falsches Wort"))
    }

    @Test func emailBodyOmitsBlankOptionalSections() {
        let report = TranslationIssueReport(locale: "fr", screen: "", observedText: "x", expectedText: "", additionalDetails: "", appVersion: "1.0")
        #expect(!report.emailBody.contains("Screen:"))
        #expect(!report.emailBody.contains("What it should say:"))
        #expect(!report.emailBody.contains("Additional details:"))
    }

    @Test func emailBodyIncludesScreenExpectedTextAndDetailsWhenProvided() {
        let report = TranslationIssueReport(locale: "es", screen: "Today", observedText: "Hoy", expectedText: "Hoy día", additionalDetails: "Looks truncated", appVersion: "1.0")
        #expect(report.emailBody.contains("Screen: Today"))
        #expect(report.emailBody.contains("What it should say:"))
        #expect(report.emailBody.contains("Hoy día"))
        #expect(report.emailBody.contains("Looks truncated"))
    }

    @Test func emailSubjectIncludesLocale() {
        let report = TranslationIssueReport(locale: "ja", screen: "", observedText: "x", expectedText: "", additionalDetails: "", appVersion: "1.0")
        #expect(report.emailSubject.contains("ja"))
    }

    @Test func mailtoURLUsesTheSupportAddressAndEncodesSubjectAndBody() throws {
        let report = TranslationIssueReport(locale: "pl", screen: "", observedText: "line one\nline two", expectedText: "", additionalDetails: "", appVersion: "1.0")
        let url = try #require(report.mailtoURL)
        #expect(url.absoluteString.hasPrefix("mailto:support@notebytez.app?"))
        #expect(url.absoluteString.contains("subject="))
        #expect(url.absoluteString.contains("body="))
    }

    @Test func mailtoURLIsNilWhenThereIsNothingToReport() {
        let report = TranslationIssueReport(locale: "pl", screen: "", observedText: "   ", expectedText: "", additionalDetails: "", appVersion: "1.0")
        #expect(report.mailtoURL == nil)
    }

}
