// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  RadialLayout.swift
//  NoteBytez
//

import Foundation

/// Pure layout math for `CanvasDAL.seedBoard(fromNeighborhoodOf:...)` — `count` points evenly
/// spaced on a circle, independent of any SwiftData/Canvas types so it's trivially unit-tested.
enum RadialLayout {

    static func points(count: Int, radius: Double, center: (x: Double, y: Double) = (0, 0)) -> [(x: Double, y: Double)] {
        guard count > 0 else { return [] }
        return (0..<count).map { index in
            let angle = 2 * Double.pi * Double(index) / Double(count)
            return (x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
        }
    }

}
