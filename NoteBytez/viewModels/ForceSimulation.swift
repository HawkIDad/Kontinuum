// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ForceSimulation.swift
//  Kontinuum
//

import Foundation
import CoreGraphics
import Observation

/// The stepped, stateful counterpart to `ForceDirectedLayout.layout(...)` — `ForceGraphCanvas`
/// drives this one frame at a time via `TimelineView(.animation)` so the simulation is visibly
/// animating toward rest rather than appearing instantly (Decision 4/A5). A reference type
/// (unlike the pure `layout` function) because it accumulates run-to-run state — the engine,
/// settled-ness, pinned nodes — across many `step()` calls from the render loop.
@Observable
final class ForceSimulation {

    private(set) var positions: [UUID: CGPoint] = [:]
    private(set) var isSettled = false
    private(set) var pinnedIds: Set<UUID> = []

    private var engine: ForceDirectedLayout.Engine
    private var iteration = 0

    let idealEdgeLength: Double
    let canvasSize: (width: Double, height: Double)
    let maxIterations: Int
    let settleThreshold: Double

    init(
        nodes: [ForceDirectedLayout.Node],
        edges: [ForceDirectedLayout.Edge],
        idealEdgeLength: Double = 80,
        canvasSize: (width: Double, height: Double) = (600, 600),
        maxIterations: Int = 300,
        settleThreshold: Double = 0.05,
        seed: UInt64 = 42
    ) {
        self.idealEdgeLength = idealEdgeLength
        self.canvasSize = canvasSize
        self.maxIterations = maxIterations
        self.settleThreshold = settleThreshold
        self.engine = ForceDirectedLayout.Engine(nodes: nodes, edges: edges, canvasSize: canvasSize, seed: seed)
        self.positions = engine.positionsById()
    }

    /// Advances the simulation by one iteration. No-op once settled — call `resume()` first if
    /// something changed (a node was pinned/unpinned) that should restart stepping.
    func step() {
        guard !isSettled, iteration < maxIterations else {
            isSettled = true
            return
        }
        let initialTemperature = canvasSize.width / 10
        let temperature = initialTemperature * (1 - Double(iteration) / Double(maxIterations))
        let maxDisplacement = engine.step(idealEdgeLength: idealEdgeLength, canvasSize: canvasSize, temperature: temperature, pinned: pinnedIds)
        iteration += 1
        positions = engine.positionsById()
        if maxDisplacement < settleThreshold {
            isSettled = true
        }
    }

    /// Fixes `id` at `point` — it stops moving on future `step()` calls, but keeps exerting
    /// repulsion on every other node ("the simulation continues around it").
    func pin(_ id: UUID, at point: CGPoint) {
        pinnedIds.insert(id)
        engine.setPosition(of: id, to: point)
        positions[id] = point
        resume()
    }

    func unpin(_ id: UUID) {
        pinnedIds.remove(id)
        resume()
    }

    /// Restarts stepping (e.g. after a pin/unpin changes the equilibrium) without discarding
    /// current positions or the iteration budget already spent.
    func resume() {
        isSettled = false
    }

}
