// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SharingParticipantsView.swift
//  NoteBytez
//

import SwiftUI
import CloudKit

/// S22 — Sharing / Participants. A decision-bearing screen, so it's a sheet on every platform,
/// per the wireframe's own note (same rule S2/S10/S15 already follow) — presented from
/// `SettingsView`.
struct SharingParticipantsView: View {

    @State var viewModel: SharingViewModel
    @State private var newParticipantEmail = ""
    @State private var newParticipantPermission: CKShare.ParticipantPermission = .readWrite
    @Environment(\.dismiss) private var dismiss

    private var isNewParticipantEmailValid: Bool {
        SharingService.isValidEmailFormat(newParticipantEmail.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.participants.isEmpty {
                    ContentUnavailableView(
                        "Not Shared",
                        systemImage: "person.2",
                        description: Text("Invite someone to collaborate on \"\(viewModel.libraryName)\".")
                    )
                } else {
                    Section("Participants") {
                        ForEach(viewModel.participants, id: \.userIdentity.userRecordID) { participant in
                            ParticipantRow(
                                participant: participant,
                                isOwner: viewModel.isOwner,
                                onChangePermission: { permission in
                                    Task { await viewModel.updatePermission(permission, for: participant) }
                                },
                                onRemove: {
                                    Task { await viewModel.removeParticipant(participant) }
                                }
                            )
                        }
                    }
                }

                if viewModel.isOwner || viewModel.participants.isEmpty {
                    Section("Add by Email") {
                        TextField("Apple Account email", text: $newParticipantEmail)
                            .autocorrectionDisabled()
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
#endif
                            .accessibilityIdentifier("sharing.addByEmail.field")

                        Picker("Permission", selection: $newParticipantPermission) {
                            Text("Read & Write").tag(CKShare.ParticipantPermission.readWrite)
                            Text("Read Only").tag(CKShare.ParticipantPermission.readOnly)
                        }
                        .accessibilityIdentifier("sharing.addByEmail.permission")

                        Button("Add") {
                            Task {
                                await viewModel.addParticipant(email: newParticipantEmail, permission: newParticipantPermission)
                                if viewModel.errorMessage == nil { newParticipantEmail = "" }
                            }
                        }
                        .disabled(viewModel.isLoading || !isNewParticipantEmailValid)
                        .accessibilityIdentifier("sharing.addByEmail.button")
                    }

                    Section {
                        Button {
                            Task { await viewModel.startInviting() }
                        } label: {
                            Label("Invite Participant", systemImage: "person.badge.plus")
                        }
                        .disabled(viewModel.isLoading)

                        if !viewModel.participants.isEmpty, viewModel.isOwner {
                            Button("Stop Sharing", role: .destructive) {
                                Task { await viewModel.stopSharing() }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Share \"\(viewModel.libraryName)\"")
            .noteBytezInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await viewModel.loadShare() }
            .overlay {
                if viewModel.isLoading, viewModel.participants.isEmpty {
                    ProgressView()
                }
            }
            .alert(
                "Couldn't Update Sharing",
                isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { isPresented in if !isPresented { viewModel.dismissError() } })
            ) {
                Button("OK") { viewModel.dismissError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .background {
                if let share = viewModel.share {
                    CloudSharingControllerRepresentable(
                        share: share,
                        container: SharingService.shared.cloudKitContainer,
                        libraryName: viewModel.libraryName,
                        isPresented: $viewModel.isPresentingInviteController
                    )
                }
            }
        }
    }

}

/// `ParticipantAvatar` + name, `PermissionLevelPicker` (per `06-DesignSystem.md`'s S22 component
/// inventory) — the permission level is always a paired text label, never an icon/color alone,
/// per the same accessibility rule Sync Status already follows.
private struct ParticipantRow: View {

    let participant: CKShare.Participant
    let isOwner: Bool
    let onChangePermission: (CKShare.ParticipantPermission) -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack {
            ParticipantAvatar(participant: participant)
            VStack(alignment: .leading) {
                Text(displayName)
                if !isOwner {
                    Text(permissionLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isOwner {
                PermissionLevelPicker(permission: participant.permission, onChange: onChangePermission)
            }
        }
        .swipeActions {
            if isOwner {
                Button("Remove", role: .destructive, action: onRemove)
            }
        }
    }

    private var displayName: String {
        SharingPermissionStore.shared.displayName(forUserRecordID: participant.userIdentity.userRecordID ?? CKRecord.ID(recordName: UUID().uuidString))
            ?? participant.userIdentity.lookupInfo?.emailAddress
            ?? "Pending Invitation"
    }

    private var permissionLabel: String {
        switch participant.permission {
        case .readOnly: return "Read Only"
        case .readWrite: return "Read & Write"
        default: return "Pending"
        }
    }

}

private struct ParticipantAvatar: View {

    let participant: CKShare.Participant

    var body: some View {
        Circle()
            .fill(Color.accentColor.opacity(0.2))
            .frame(width: 36, height: 36)
            .overlay {
                Text(initials)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .accessibilityHidden(true)
    }

    private var initials: String {
        guard let components = participant.userIdentity.nameComponents else { return "?" }
        let formatted = PersonNameComponentsFormatter().string(from: components)
        let letters = formatted.split(separator: " ").compactMap(\.first)
        return letters.isEmpty ? "?" : String(letters.prefix(2))
    }

}

private struct PermissionLevelPicker: View {

    let permission: CKShare.ParticipantPermission
    let onChange: (CKShare.ParticipantPermission) -> Void

    var body: some View {
        Picker("Permission", selection: Binding(get: { permission }, set: onChange)) {
            Text("Read Only").tag(CKShare.ParticipantPermission.readOnly)
            Text("Read & Write").tag(CKShare.ParticipantPermission.readWrite)
        }
        .labelsHidden()
    }

}
