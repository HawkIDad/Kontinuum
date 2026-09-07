// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ForceDirectedLayout.swift
//  Kontinuum
//

import Foundation
import CoreGraphics

/// Fruchterman-Reingold force simulation for S8's "Force" graph mode (Decision 4). Plain O(n²)
/// pairwise repulsion, not Barnes-Hut: the performance guard (Workstream A7) is 500 nodes /
/// 1,500 edges, which plain repulsion clears comfortably once the hot loop is array-indexed
/// rather than dictionary-keyed (a `[UUID: _]` lookup per pair, tens of millions of times, is
/// the actual bottleneck — not the O(n²) math itself). Adding a quadtree/Barnes-Hut
/// approximation on top of that would be complexity this scale doesn't need (`CLAUDE.md` §2's
/// "would a senior engineer call this overcomplicated?"). Pure function, no SwiftUI/CoreData
/// dependency — unit-testable headless and reused unchanged by the view layer.
enum ForceDirectedLayout {

    struct Node: Hashable {
        let id: UUID
    }

    struct Edge {
        let from: UUID
        let to: UUID
    }

    /// Runs the simulation to rest (or `iterations`, whichever first) and returns each node's
    /// final position. Deterministic for a fixed `seed`: same nodes/edges/parameters always
    /// produce the same positions, so "Save as View" (A6) snapshots reproducibly and this
    /// function's own tests don't flake.
    static func layout(
        nodes: [Node],
        edges: [Edge],
        idealEdgeLength: Double = 80,
        canvasSize: (width: Double, height: Double) = (600, 600),
        iterations: Int = 300,
        settleThreshold: Double = 0.05,
        seed: UInt64 = 42
    ) -> [UUID: CGPoint] {
        guard !nodes.isEmpty else { return [:] }
        guard nodes.count > 1 else {
            return [nodes[0].id: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)]
        }

        var engine = Engine(nodes: nodes, edges: edges, canvasSize: canvasSize, seed: seed)
        let initialTemperature = canvasSize.width / 10

        for iteration in 0..<iterations {
            let temperature = initialTemperature * (1 - Double(iteration) / Double(iterations))
            let maxDisplacement = engine.step(idealEdgeLength: idealEdgeLength, canvasSize: canvasSize, temperature: temperature, pinned: [])
            if maxDisplacement < settleThreshold { break }
        }

        return engine.positionsById()
    }

    /// Array-indexed simulation state — `layout(...)`'s inner loop and `ForceSimulation` (the
    /// stepped, `TimelineView`-driven variant `ForceGraphCanvas` uses) both run on this rather
    /// than keying every position lookup by `UUID` in the hot O(n²) loop.
    struct Engine {
        private(set) var ids: [UUID]
        private var indexById: [UUID: Int]
        private var xs: [Double]
        private var ys: [Double]
        private var edgeIndexPairs: [(Int, Int)]

        init(nodes: [Node], edges: [Edge], canvasSize: (width: Double, height: Double), seed: UInt64) {
            let ids = nodes.map(\.id)
            let indexById = Dictionary(uniqueKeysWithValues: ids.enumerated().map { ($1, $0) })

            var generator = SeededGenerator(seed: seed)
            self.ids = ids
            self.indexById = indexById
            self.xs = ids.map { _ in Double.random(in: 0..<canvasSize.width, using: &generator) }
            self.ys = ids.map { _ in Double.random(in: 0..<canvasSize.height, using: &generator) }
            self.edgeIndexPairs = edges.compactMap { edge in
                guard let from = indexById[edge.from], let to = indexById[edge.to], from != to else { return nil }
                return (from, to)
            }
        }

        func positionsById() -> [UUID: CGPoint] {
            var result: [UUID: CGPoint] = [:]
            result.reserveCapacity(ids.count)
            for i in ids.indices {
                result[ids[i]] = CGPoint(x: xs[i], y: ys[i])
            }
            return result
        }

        func position(of id: UUID) -> CGPoint? {
            guard let i = indexById[id] else { return nil }
            return CGPoint(x: xs[i], y: ys[i])
        }

        /// Directly places a node (e.g. a user drag-to-pin drop point) without waiting for the
        /// next `step()`.
        mutating func setPosition(of id: UUID, to point: CGPoint) {
            guard let i = indexById[id] else { return }
            xs[i] = Double(point.x)
            ys[i] = Double(point.y)
        }

        /// One Fruchterman-Reingold iteration: repulsion between every pair, attraction along
        /// every edge, displacement capped by `temperature`, positions clamped to the canvas. A
        /// node whose index is in `pinned` still exerts repulsion on everything else but is
        /// never itself displaced — "the simulation continues around it" (Decision 4/A5).
        /// Returns the largest displacement applied, the settle signal both callers use.
        @discardableResult
        mutating func step(idealEdgeLength: Double, canvasSize: (width: Double, height: Double), temperature: Double, pinned: Set<UUID>) -> Double {
            let k = idealEdgeLength
            let count = ids.count
            var dxs = [Double](repeating: 0, count: count)
            var dys = [Double](repeating: 0, count: count)

            for i in 0..<count {
                for j in (i + 1)..<count {
                    var dx = xs[i] - xs[j]
                    var dy = ys[i] - ys[j]
                    var distance = (dx * dx + dy * dy).squareRoot()
                    if distance < 0.01 { dx = 0.01; dy = 0; distance = 0.01 }
                    let force = (k * k) / distance
                    let fx = (dx / distance) * force
                    let fy = (dy / distance) * force
                    dxs[i] += fx
                    dys[i] += fy
                    dxs[j] -= fx
                    dys[j] -= fy
                }
            }

            for (from, to) in edgeIndexPairs {
                var dx = xs[from] - xs[to]
                var dy = ys[from] - ys[to]
                var distance = (dx * dx + dy * dy).squareRoot()
                if distance < 0.01 { dx = 0.01; dy = 0; distance = 0.01 }
                let force = (distance * distance) / k
                let fx = (dx / distance) * force
                let fy = (dy / distance) * force
                dxs[from] -= fx
                dys[from] -= fy
                dxs[to] += fx
                dys[to] += fy
            }

            let pinnedIndices: Set<Int> = pinned.isEmpty ? [] : Set(pinned.compactMap { indexById[$0] })
            var maxDisplacement = 0.0
            for i in 0..<count {
                guard !pinnedIndices.contains(i) else { continue }
                let magnitude = (dxs[i] * dxs[i] + dys[i] * dys[i]).squareRoot()
                guard magnitude > 0.0001 else { continue }
                let capped = min(magnitude, temperature)
                xs[i] = min(max(xs[i] + (dxs[i] / magnitude) * capped, 0), canvasSize.width)
                ys[i] = min(max(ys[i] + (dys[i] / magnitude) * capped, 0), canvasSize.height)
                maxDisplacement = max(maxDisplacement, capped)
            }
            return maxDisplacement
        }
    }

}
