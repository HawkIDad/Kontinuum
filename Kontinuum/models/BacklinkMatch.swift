// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BacklinkMatch.swift
//  Kontinuum
//

import Foundation

/// A document that references another, either via a resolved `[[wikilink]]` or a plain-text
/// mention of its title. Not persisted — computed on demand by `BacklinkDAL`.
struct BacklinkMatch: Identifiable {

    let id = UUID()
    let sourceDocument: Document
    let snippet: String

}
