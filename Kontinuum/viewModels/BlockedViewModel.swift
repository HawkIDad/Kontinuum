// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BlockedViewModel.swift
//  Kontinuum
//

import Foundation
import Observation
import SwiftData

/// Backs `BlockedView` — the read-only data-export escape hatch shown when the app is blocked
/// (NoteBytez20260907v1-Security.md G16). Resubscribe / restore are handled by the shared
/// `PaywallViewModel`; this only owns the export.
@MainActor
@Observable
final class BlockedViewModel {

    private(set) var exportResultMessage: String?

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func exportAll(to directory: URL) {
        let count = ExportDAL.exportAllActiveLibraries(to: directory, in: modelContext)
        exportResultMessage = "Exported \(count) note\(count == 1 ? "" : "s") to your selected folder."
    }
}
