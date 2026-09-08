// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ForceSimulationTests.swift
//  NoteBytezTests
//

import Testing
import Foundation
@testable import NoteBytez

struct ForceSimulationTests {

    @Test func steppingRepeatedlyEventuallySettles() {
        let a = ForceDirectedLayout.Node(id: UUID())
        let b = ForceDirectedLayout.Node(id: UUID())
        let simulation = ForceSimulation(nodes: [a, b], edges: [ForceDirectedLayout.Edge(from: a.id, to: b.id)])

        var stepsTaken = 0
        while !simulation.isSettled, stepsTaken < 1000 {
            simulation.step()
            stepsTaken += 1
        }

        #expect(simulation.isSettled)
    }

    @Test func pinningANodeFreezesItsPositionAcrossFurtherSteps() {
        let a = ForceDirectedLayout.Node(id: UUID())
        let b = ForceDirectedLayout.Node(id: UUID())
        let c = ForceDirectedLayout.Node(id: UUID())
        let simulation = ForceSimulation(
            nodes: [a, b, c],
            edges: [ForceDirectedLayout.Edge(from: a.id, to: b.id), ForceDirectedLayout.Edge(from: b.id, to: c.id)]
        )
        for _ in 0..<20 { simulation.step() }

        let pinnedPoint = CGPoint(x: 300, y: 300)
        simulation.pin(a.id, at: pinnedPoint)

        for _ in 0..<20 { simulation.step() }

        #expect(simulation.positions[a.id] == pinnedPoint)
    }

    @Test func unpinningAllowsTheNodeToMoveAgain() {
        let a = ForceDirectedLayout.Node(id: UUID())
        let b = ForceDirectedLayout.Node(id: UUID())
        let simulation = ForceSimulation(nodes: [a, b], edges: [ForceDirectedLayout.Edge(from: a.id, to: b.id)])
        simulation.pin(a.id, at: CGPoint(x: 0, y: 0))
        for _ in 0..<5 { simulation.step() }
        #expect(simulation.positions[a.id] == CGPoint(x: 0, y: 0))

        simulation.unpin(a.id)
        for _ in 0..<50 { simulation.step() }

        #expect(simulation.positions[a.id] != CGPoint(x: 0, y: 0))
    }

    @Test func pinningAfterSettlingResumesStepping() {
        let a = ForceDirectedLayout.Node(id: UUID())
        let b = ForceDirectedLayout.Node(id: UUID())
        let simulation = ForceSimulation(nodes: [a, b], edges: [ForceDirectedLayout.Edge(from: a.id, to: b.id)])
        while !simulation.isSettled { simulation.step() }
        #expect(simulation.isSettled)

        simulation.pin(a.id, at: CGPoint(x: 500, y: 500))

        #expect(!simulation.isSettled)
    }

}
