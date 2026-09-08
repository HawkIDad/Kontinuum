// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  RadialLayoutTests.swift
//  NoteBytezTests
//

import Testing
import Foundation
@testable import NoteBytez

struct RadialLayoutTests {

    @Test func zeroCountReturnsNoPoints() {
        #expect(RadialLayout.points(count: 0, radius: 100).isEmpty)
    }

    @Test func everyPointLiesOnTheCircleAtTheGivenRadius() {
        let points = RadialLayout.points(count: 5, radius: 100)
        #expect(points.count == 5)
        for point in points {
            let distance = (point.x * point.x + point.y * point.y).squareRoot()
            #expect(abs(distance - 100) < 0.0001)
        }
    }

    @Test func pointsAreEvenlySpacedAroundTheCircle() {
        let points = RadialLayout.points(count: 4, radius: 10)
        // 4 points at 90° apart starting at angle 0: (10,0), (0,10), (-10,0), (0,-10).
        #expect(abs(points[0].x - 10) < 0.0001 && abs(points[0].y) < 0.0001)
        #expect(abs(points[1].x) < 0.0001 && abs(points[1].y - 10) < 0.0001)
        #expect(abs(points[2].x + 10) < 0.0001 && abs(points[2].y) < 0.0001)
        #expect(abs(points[3].x) < 0.0001 && abs(points[3].y + 10) < 0.0001)
    }

    @Test func pointsAreOffsetByTheGivenCenter() {
        let points = RadialLayout.points(count: 1, radius: 10, center: (x: 5, y: 5))
        #expect(abs(points[0].x - 15) < 0.0001)
        #expect(abs(points[0].y - 5) < 0.0001)
    }

}
