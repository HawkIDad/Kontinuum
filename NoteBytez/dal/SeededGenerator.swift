// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SeededGenerator.swift
//  NoteBytez
//

import Foundation

/// A deterministic `RandomNumberGenerator` (splitmix64) — `ForceDirectedLayout`'s initial node
/// placement needs to be reproducible given a fixed seed so its own tests (and "Save as View")
/// snapshots are stable, which `SystemRandomNumberGenerator` can't guarantee.
struct SeededGenerator: RandomNumberGenerator {

    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

}
