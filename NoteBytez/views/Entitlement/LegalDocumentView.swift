// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  LegalDocumentView.swift
//  NoteBytez
//

import SwiftUI
import OSLog

import MarkdownG9

/// Renders one of the app's bundled legal documents from its shipped Markdown resource, using
/// the same `MDProcessor` renderer as document previews elsewhere in the app. Backs the
/// Terms of Use / Privacy Policy links in `PaywallView` so they open the real, shipped text
/// instead of a placeholder marketing-site URL.
struct LegalDocumentView: View {

    enum LegalDocument: Identifiable, Hashable {
        case eula
        case dataUsePolicy

        var id: Self { self }

        var title: String {
            switch self {
            case .eula: return "Terms of Use"
            case .dataUsePolicy: return "Privacy Policy"
            }
        }

        var resourceName: String {
            switch self {
            case .eula: return "NoteBytez-EULA-v1.0"
            case .dataUsePolicy: return "NoteBytez-Data-Use-Policy-v1.0"
            }
        }
    }

    let document: LegalDocument

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(MDProcessor.process(contents))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle(Text(document.title))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var contents: String {
        guard let url = Bundle.main.url(forResource: document.resourceName, withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            Log.logger(.entitlement).error("\(document.resourceName, privacy: .public).md not found in bundle")
            return "This document could not be loaded."
        }
        return text
    }
}
