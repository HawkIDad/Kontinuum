// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BackupViewModel.swift
//  NoteBytez
//

import Foundation
import SwiftData
import Observation

@Observable
final class BackupViewModel {

    private(set) var snapshots: [BackupSnapshot] = []

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.loadSnapshots()
    }

    func loadSnapshots() {
        self.snapshots = BackupDAL.listSnapshots()
    }

    func createManualSnapshot() {
        BackupDAL.createSnapshot(cause: .manual, in: self.modelContext)
        self.loadSnapshots()
    }

    func restore(_ snapshot: BackupSnapshot) {
        BackupDAL.restore(snapshot, in: self.modelContext)
        self.loadSnapshots()
    }

}
