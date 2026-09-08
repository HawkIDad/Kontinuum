// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ForceLayoutTests.swift
//  NoteBytezTests
//

import Testing
import Foundation
@testable import NoteBytez

struct ForceLayoutTests {

    @Test func twoNodeOneEdgeSystemSettlesNearTheIdealEdgeLength() {
        let a = ForceDirectedLayout.Node(id: UUID())
        let b = ForceDirectedLayout.Node(id: UUID())
        let positions = ForceDirectedLayout.layout(
            nodes: [a, b],
            edges: [ForceDirectedLayout.Edge(from: a.id, to: b.id)],
            idealEdgeLength: 80
        )

        let pa = try! #require(positions[a.id])
        let pb = try! #require(positions[b.id])
        let distance = ((pa.x - pb.x) * (pa.x - pb.x) + (pa.y - pb.y) * (pa.y - pb.y)).squareRoot()

        #expect(abs(distance - 80) < 12)
    }

    @Test func aDisconnectedNodeDriftsToThePeripheryWithoutOverlappingTheConnectedPair() {
        let root = ForceDirectedLayout.Node(id: UUID())
        let peer = ForceDirectedLayout.Node(id: UUID())
        let isolated = ForceDirectedLayout.Node(id: UUID())
        let positions = ForceDirectedLayout.layout(
            nodes: [root, peer, isolated],
            edges: [ForceDirectedLayout.Edge(from: root.id, to: peer.id)],
            idealEdgeLength: 80
        )

        let rootPos = try! #require(positions[root.id])
        let peerPos = try! #require(positions[peer.id])
        let isolatedPos = try! #require(positions[isolated.id])

        func distance(_ p: CGPoint, _ q: CGPoint) -> Double {
            ((p.x - q.x) * (p.x - q.x) + (p.y - q.y) * (p.y - q.y)).squareRoot()
        }

        // No attraction pulls the isolated node in, so repulsion alone should leave it farther
        // from the root than the linked peer is — never overlapping (coincident with) it.
        #expect(distance(isolatedPos, rootPos) > distance(peerPos, rootPos))
        #expect(distance(isolatedPos, rootPos) > 1)
    }

    @Test func layoutIsDeterministicForAFixedSeed() {
        let a = ForceDirectedLayout.Node(id: UUID())
        let b = ForceDirectedLayout.Node(id: UUID())
        let c = ForceDirectedLayout.Node(id: UUID())
        let edges = [ForceDirectedLayout.Edge(from: a.id, to: b.id), ForceDirectedLayout.Edge(from: b.id, to: c.id)]

        let first = ForceDirectedLayout.layout(nodes: [a, b, c], edges: edges, seed: 7)
        let second = ForceDirectedLayout.layout(nodes: [a, b, c], edges: edges, seed: 7)

        #expect(first[a.id] == second[a.id])
        #expect(first[b.id] == second[b.id])
        #expect(first[c.id] == second[c.id])
    }

    @Test func differentSeedsCanProduceDifferentLayouts() {
        let a = ForceDirectedLayout.Node(id: UUID())
        let b = ForceDirectedLayout.Node(id: UUID())
        let c = ForceDirectedLayout.Node(id: UUID())
        let edges = [ForceDirectedLayout.Edge(from: a.id, to: b.id), ForceDirectedLayout.Edge(from: b.id, to: c.id)]

        let first = ForceDirectedLayout.layout(nodes: [a, b, c], edges: edges, seed: 1)
        let second = ForceDirectedLayout.layout(nodes: [a, b, c], edges: edges, seed: 2)

        #expect(first[a.id] != second[a.id] || first[c.id] != second[c.id])
    }

    @Test func singleNodeIsPlacedAtTheCanvasCenter() {
        let a = ForceDirectedLayout.Node(id: UUID())
        let positions = ForceDirectedLayout.layout(nodes: [a], edges: [], canvasSize: (width: 400, height: 300))
        #expect(positions[a.id] == CGPoint(x: 200, y: 150))
    }

    @Test func emptyNodeListReturnsNoPositions() {
        #expect(ForceDirectedLayout.layout(nodes: [], edges: []).isEmpty)
    }

    // MARK: - Performance guard (A7)

    @Test func fiveHundredNodesFifteenHundredEdgesSettleWithinBudget() {
        var nodes: [ForceDirectedLayout.Node] = []
        for _ in 0..<500 { nodes.append(ForceDirectedLayout.Node(id: UUID())) }

        var edges: [ForceDirectedLayout.Edge] = []
        for index in 0..<1500 {
            let from = nodes[index % nodes.count]
            let to = nodes[(index * 7 + 3) % nodes.count]
            edges.append(ForceDirectedLayout.Edge(from: from.id, to: to.id))
        }

        let start = Date()
        let positions = ForceDirectedLayout.layout(nodes: nodes, edges: edges, canvasSize: (width: 2000, height: 2000))
        let elapsed = Date().timeIntervalSince(start)

        #expect(positions.count == 500)
        // Budget calibrated against this sandboxed Debug-configuration test run (no
        // optimizations) — a Release build, and the real UI's per-frame `step()` stepping
        // rather than a single batch `layout()` call, are both substantially faster than this.
        #expect(elapsed < 10.0)
    }

}
