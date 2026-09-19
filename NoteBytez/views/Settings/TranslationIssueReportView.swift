// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TranslationIssueReportView.swift
//  NoteBytez
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Phase 12.1 (NoteBytez20260823v2-MultiLanguage.md): "no server" reporting affordance for
/// mistranslated or missing strings — G12's "AI-only, fix on report" model has nothing else
/// feeding it today. Delivery channel decision: a `mailto:` link (SwiftUI's `openURL`
/// environment action, identical on iOS and macOS, no `MFMailComposeViewController` dependency)
/// is the primary path, with "Copy Report" always available alongside it — covers a device with
/// no mail account configured, and doubles as the "append to a shared doc" alternative this task
/// also floated, since the copied text can be pasted anywhere.
struct TranslationIssueReportView: View {

    @State private var viewModel = TranslationIssueReportViewModel()
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Section {
                Text("Describe what you saw and, if you know it, what it should say. This is sent by you directly — nothing is collected automatically.")
                    .foregroundStyle(.secondary)
            }
            Section("Where") {
                TextField("Screen (optional)", text: $viewModel.screen)
            }
            Section("What you saw") {
                TextField("Observed text", text: $viewModel.observedText, axis: .vertical)
                    .lineLimit(3...6)
            }
            Section("What it should say (optional)") {
                TextField("Expected text", text: $viewModel.expectedText, axis: .vertical)
                    .lineLimit(3...6)
            }
            Section("Additional details (optional)") {
                TextField("Anything else that would help", text: $viewModel.additionalDetails, axis: .vertical)
                    .lineLimit(3...6)
            }
            Section {
                Button("Send via Email") {
                    guard let url = viewModel.report.mailtoURL else { return }
                    openURL(url)
                }
                .disabled(viewModel.report.mailtoURL == nil)
                Button("Copy Report") {
                    copyToPasteboard(viewModel.report.emailBody)
                    viewModel.didCopyReport = true
                }
                .disabled(viewModel.report.mailtoURL == nil)
            } footer: {
                if viewModel.didCopyReport {
                    Text("Copied to clipboard.")
                }
            }
        }
        .navigationTitle("Report a Translation Issue")
        .noteBytezInlineNavigationTitle()
    }

    private func copyToPasteboard(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }

}

#Preview {
    NavigationStack {
        TranslationIssueReportView()
    }
}
