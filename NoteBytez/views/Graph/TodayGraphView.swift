// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TodayGraphView.swift
//  NoteBytez
//

import SwiftUI
import SwiftData

/// Entry point for the sidebar/tab bar "Graph" nav item, which (unlike S4's toolbar trigger)
/// has no specific note already in view — defaults to today's journal entry, the same document
/// S3 shows on open. Owns `GraphViewModel` via the construct-once-on-appear `@State` pattern
/// `TodayJournalView` already established, so re-running `ContentView`'s destination switch on
/// every render doesn't rebuild it.
struct TodayGraphView: View {

    let libraryId: UUID

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: GraphViewModel?

    var body: some View {
        Group {
            if let viewModel {
                GraphView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                let document = JournalDAL.fetchOrCreate(for: Date(), libraryId: libraryId, in: modelContext)
                viewModel = GraphViewModel(document: document, modelContext: modelContext)
            }
        }
    }

}
