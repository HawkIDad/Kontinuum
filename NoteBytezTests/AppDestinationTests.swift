// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  AppDestinationTests.swift
//  NoteBytezTests
//

import Testing
@testable import NoteBytez

struct AppDestinationTests {

    @Test func everyDestinationBelongsToExactlyOneSectionOrIsSettings() {
        for destination in AppDestination.allCases {
            if destination == .settings {
                #expect(destination.section == .settings)
            } else {
                #expect(AppDestination.sidebarSections.contains(destination.section))
            }
        }
    }

    @Test func sidebarSectionsYieldsCaptureLibraryExploreInOrderWithDocumentedMembers() {
        #expect(AppDestination.sidebarSections == [.capture, .library, .explore])
        #expect(AppDestination.sidebarRows(in: .capture) == [.today])
        #expect(AppDestination.sidebarRows(in: .library) == [.notebooks, .allNotes, .tags])
        #expect(AppDestination.sidebarRows(in: .explore) == [.search, .graph, .insights, .tasks, .savedViews, .canvas])
    }

    @Test func tabBarDestinationsIsTodayNotebooksSearchExploreSettings() {
        #expect(AppDestination.tabBarDestinations == [.today, .notebooks, .search, .explore, .settings])
    }

    @Test func graphIsInExploreNotABarePeer() {
        #expect(AppDestination.graph.section == .explore)
    }

    @Test func exploreIsAValidTabDestination() {
        #expect(AppDestination.tabBarDestinations.contains(.explore))
    }

}
