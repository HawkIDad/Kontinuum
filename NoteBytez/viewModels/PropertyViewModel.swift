// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PropertyViewModel.swift
//  Kontinuum
//

import Foundation
import Observation

/// Backs S17's Properties editor block, inline atop S4's document body. Wraps a
/// `DocumentViewModel` rather than duplicating its state — mirrors `JournalViewModel`
/// wrapping a `DocumentViewModel` for the displayed day (MVP Phase 6).
@Observable
final class PropertyViewModel {

    private let documentViewModel: DocumentViewModel

    /// Transient "add a Property" form state — cleared after a successful commit.
    var newKey: String = ""
    var newValue: String = ""
    var newValueType: PropertyValueType = .text

    init(documentViewModel: DocumentViewModel) {
        self.documentViewModel = documentViewModel
    }

    var resolvedProperties: [PropertyDAL.ResolvedProperty] {
        documentViewModel.properties
    }

    func updateValue(key: String, value: String, valueType: PropertyValueType) {
        documentViewModel.setPropertyValue(key: key, value: value, valueType: valueType)
    }

    func removeValue(key: String) {
        documentViewModel.removePropertyValue(key: key)
    }

    /// Commits the in-progress "add a Property" form, then clears it. No-op on an empty name
    /// — never adds a Property from a blank field.
    func commitNewProperty() {
        let trimmedKey = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { return }

        updateValue(key: trimmedKey, value: newValue, valueType: newValueType)
        newKey = ""
        newValue = ""
        newValueType = .text
    }

}
