// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SharingServiceTests.swift
//  NoteBytezTests
//

import Testing
import CloudKit
import Foundation
@testable import NoteBytez

/// Covers the parts of the add-participant-by-email feature
/// (Docs/Plans/NoteBytez20260831v1-Sharing.md) that don't need a live CloudKit account: the
/// local email sanity check `SharingService.addParticipant` gates on, and the new
/// `SharingError` messages the S22 alert surfaces. The CloudKit round trip itself
/// (`shareParticipant(forEmailAddress:)`, `share.addParticipant`, `modifyRecords`) is exercised
/// by that plan's Phase 4 manual two-account procedure — the same live-account gap
/// `SharingPermissionStoreTests` / `ConflictResolverTests` already accept.
struct SharingServiceTests {

    // MARK: - isValidEmailFormat

    @Test func acceptsAWellFormedAddress() {
        #expect(SharingService.isValidEmailFormat("kontinuum2@2thumbsupapps.com"))
        #expect(SharingService.isValidEmailFormat("a.b+tag@example.co.uk"))
    }

    @Test func rejectsEmptyWhitespaceOrMissingParts() {
        #expect(SharingService.isValidEmailFormat("") == false)
        #expect(SharingService.isValidEmailFormat("   ") == false)
        #expect(SharingService.isValidEmailFormat("has space@example.com") == false)
        #expect(SharingService.isValidEmailFormat("no-at-sign.com") == false)
        #expect(SharingService.isValidEmailFormat("@example.com") == false)
        #expect(SharingService.isValidEmailFormat("local@") == false)
        #expect(SharingService.isValidEmailFormat("two@@example.com") == false)
    }

    @Test func rejectsADomainWithoutAValidDot() {
        #expect(SharingService.isValidEmailFormat("local@example") == false)
        #expect(SharingService.isValidEmailFormat("local@.com") == false)
        #expect(SharingService.isValidEmailFormat("local@example.") == false)
    }

    // MARK: - SharingError messages

    @Test func newErrorCasesCarrySpecificMessages() {
        #expect(SharingError.invalidEmail.errorDescription == "Enter a valid email address.")
        #expect(SharingError.participantNotFound.errorDescription == "No Apple Account was found for that email address.")
        #expect(SharingError.alreadyParticipant.errorDescription == "That person is already a participant on this library.")
    }

    @Test func addParticipantThrowsInvalidEmailBeforeAnyNetworkCall() async {
        // A malformed address must fail the local guard — never reaching `container` /
        // `createShare` — so this is safe to call without a CloudKit account.
        do {
            try await SharingService.shared.addParticipant(
                emailAddress: "not-an-email",
                permission: .readWrite,
                forLibraryId: UUID(),
                libraryName: "Research"
            )
            Issue.record("Expected SharingError.invalidEmail")
        } catch SharingError.invalidEmail {
            // expected
        } catch {
            Issue.record("Expected SharingError.invalidEmail, got \(error)")
        }
    }

}
