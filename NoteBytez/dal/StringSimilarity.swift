// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  StringSimilarity.swift
//  NoteBytez
//

import Foundation

/// Bounded Levenshtein-based similarity for `BlockDAL`'s sticky-identity reclaim pass — hand-rolled
/// rather than pulling in a third-party edit-distance package for one ~20-line algorithm.
enum StringSimilarity {

    /// Normalized similarity in `[0, 1]`: `1 - levenshteinDistance / max(length)`. `nil` (not
    /// `0`) when the pair is out of bounds for the O(n*m) DP — length ratio over 2x, or either
    /// string over 4000 characters — so callers can tell "computed and dissimilar" apart from
    /// "not computed" and fall back to a cheaper eligibility test instead.
    static func similarity(_ lhs: String, _ rhs: String) -> Double? {
        let a = Array(lhs)
        let b = Array(rhs)

        guard !a.isEmpty && !b.isEmpty else { return a.isEmpty && b.isEmpty ? 1.0 : 0.0 }

        let longer = max(a.count, b.count)
        let shorter = min(a.count, b.count)
        guard longer <= 4000, Double(longer) / Double(shorter) <= 2.0 else { return nil }

        let distance = levenshteinDistance(a, b)
        return 1 - Double(distance) / Double(longer)
    }

    private static func levenshteinDistance(_ a: [Character], _ b: [Character]) -> Int {
        var previousRow = Array(0...b.count)
        var currentRow = [Int](repeating: 0, count: b.count + 1)

        for i in 1...a.count {
            currentRow[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                currentRow[j] = min(previousRow[j] + 1, currentRow[j - 1] + 1, previousRow[j - 1] + cost)
            }
            previousRow = currentRow
        }
        return previousRow[b.count]
    }

}
