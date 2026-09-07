// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  DisjointSet.swift
//  Kontinuum
//

import Foundation

/// Hand-rolled union-find (path compression + union by rank) — `GraphInsightsDAL.clusters`'
/// connected-components primitive. No simulation, deterministic, cheap enough to run on every
/// call (Decision 1).
struct DisjointSet<Element: Hashable> {

    private var parent: [Element: Element] = [:]
    private var rank: [Element: Int] = [:]

    mutating func makeSet(_ element: Element) {
        guard parent[element] == nil else { return }
        parent[element] = element
        rank[element] = 0
    }

    @discardableResult
    mutating func find(_ element: Element) -> Element {
        makeSet(element)
        if parent[element] != element {
            parent[element] = find(parent[element]!)
        }
        return parent[element]!
    }

    mutating func union(_ a: Element, _ b: Element) {
        let rootA = find(a)
        let rootB = find(b)
        guard rootA != rootB else { return }

        let rankA = rank[rootA] ?? 0
        let rankB = rank[rootB] ?? 0
        if rankA < rankB {
            parent[rootA] = rootB
        } else if rankA > rankB {
            parent[rootB] = rootA
        } else {
            parent[rootB] = rootA
            rank[rootA] = rankA + 1
        }
    }

    /// Every element added via `makeSet`/`union`, grouped by connected component. An element
    /// that was never unioned with anything is its own singleton component.
    mutating func components() -> [[Element]] {
        var groups: [Element: [Element]] = [:]
        for element in parent.keys {
            groups[find(element), default: []].append(element)
        }
        return Array(groups.values)
    }

}
