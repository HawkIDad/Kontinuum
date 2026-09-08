// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  DisjointSetTests.swift
//  KontinuumTests
//

import Testing
@testable import Kontinuum

struct DisjointSetTests {

    @Test func unrelatedElementsAreEachTheirOwnSingletonComponent() {
        var set = DisjointSet<Int>()
        set.makeSet(1)
        set.makeSet(2)

        let components = Set(set.components().map { Set($0) })

        #expect(components == Set([Set([1]), Set([2])]))
    }

    @Test func unionedElementsShareAComponent() {
        var set = DisjointSet<Int>()
        set.union(1, 2)
        set.makeSet(3)

        let components = set.components()

        #expect(components.contains { Set($0) == Set([1, 2]) })
        #expect(components.contains { Set($0) == Set([3]) })
    }

    @Test func twoDocumentsLinkedOnlyThroughAThirdAreInOneComponent() {
        var set = DisjointSet<Int>()
        set.union(1, 2)
        set.union(2, 3)

        #expect(set.find(1) == set.find(3))
    }

    @Test func findIsIdempotentAfterUnion() {
        var set = DisjointSet<String>()
        set.union("a", "b")

        #expect(set.find("a") == set.find("a"))
        #expect(set.find("a") == set.find("b"))
    }

}
