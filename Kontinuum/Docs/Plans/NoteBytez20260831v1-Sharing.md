<!-- NoteBytez20260831v1-Sharing.md -->
<!--
  Add-participant-by-email, directly from NoteBytez's Sharing screen (S22), without routing
  through the system share sheet's Mail/Messages compose flow.

  Motivated by the 2026-08-30/31 attempt to run NoteBytez20260823v1-UITests.md Phase 4 (live
  two-account CloudKit sync) on the iPhone + iPad simulators: `UICloudSharingController` on a
  simulator only surfaces send-channels (Invite with Link / Reminders / More / Copy Link).
  There is no Mail or Messages account to address a person through, "Invite with Link" fails
  ("a link couldn't be created" — CloudKit sandbox blocks public shares in the Simulator), and
  the app pins `share.publicPermission = .none` so a copied link only works for an already-
  invited participant. Net: there is currently NO way to add a second Apple Account as a
  participant on the simulators, which blocks every cross-account test.

  This plan adds an in-app "add by email" affordance that resolves the address to a real
  `CKShare.Participant` in code (`CKContainer.shareParticipant(forEmailAddress:)`), with no
  schema change and no change to `publicPermission` (access stays per-invited-participant).

  Living document. Checkbox convention: [ ] not started / in progress, [x] done and verified
  (builds + its test passes). TDD per CLAUDE.md §8 — the failing test is the first task of each
  feature, never an afterthought. Phases are ordered by build dependency: service → view model
  → view → live verification → quality gate.
-->

# Add Sharing Participants by Email (No Mail/Messages)

Source: 2026-08-31, blocked while running [NoteBytez20260823v1-UITests.md](NoteBytez20260823v1-UITests.md)
Phase 4. Baseline: MVP complete, R1 ~95%, CloudKit Sharing (R1 Phase 10) shipped —
[SharingService.swift](../../sync/SharingService.swift),
[SharingViewModel.swift](../../viewModels/SharingViewModel.swift),
[SharingParticipantsView.swift](../../views/Sharing/SharingParticipantsView.swift) (S22),
[CloudSharingControllerRepresentable.swift](../../views/Components/CloudSharingControllerRepresentable.swift).
This plan is additive to that code and adds no CloudKit schema.

## Progress Summary

| Phase | Tasks complete | Status |
|---|---|---|
| 0. Test seam | 1 / 1 | Done — collapsed (see note); no protocol seam added, matches codebase |
| 1. Service — `addParticipant(emailAddress:)` | 4 / 4 | Done — implemented + unit-tested (email validation, error strings) |
| 2. View model — `addParticipant(email:permission:)` | 3 / 3 | Done — VM method added; field state is view `@State` |
| 3. View — "Add by Email" section on S22 | 3 / 3 | Done — renders, validates, participant lands in list (verified on iPhone sim) |
| 4. Live two-account verification (unblocks UITests Phase 4) | 2 / 5 | Partial — participant added live + iPad reaches the real accept prompt; final accept tap-through blocked by rotated-iPad-sim tooling |
| 5. Quality gate | 2 / 2 | Done — new unit tests 11/11; macOS + iOS-sim builds green |
| **Total** | **15 / 18** | **~83%** — feature implemented, unit-tested, tri-platform-compiled, and demonstrably unblocks the cross-account flow; only the iPad accept tap-through (harness limitation) is outstanding |

Run on 2026-08-31 (Debug + `-EnableLiveSync`, CloudKit Sandbox, iPhone 17 Pro Max = `kontinuum1`,
iPad Pro 11 M5 = `kontinuum2@2thumbsupapps.com`).

**What was verified live:**
- `SharingService.addParticipant` → `CKContainer.shareParticipant(forEmailAddress:)` fired a
  real `CKFetchShareParticipantsOperation`; server returned
  `CKUserIdentity(email=kontinuum2@2thumbsupapps.com, hasiCloudAccount=true)` — **the Simulator
  sandbox DOES resolve a sandbox account by email** (the plan's main risk, resolved favorably).
- Participant added to the `CKShare` and saved; S22 shows `kontinuum2@2thumbsupapps.com — Read &
  Write` (email fallback + "?" avatar since `nameComponents` is empty until they accept —
  correct `ParticipantRow` behavior); `UICloudSharingController` lists it as **"Invited"**.
- **iPad, opening the Copy Link URL, now gets the real system accept prompt** — *"NoteBytez1
  TestUser wants to collaborate. You'll join as NoteBytez2 TestUser
  (kontinuum2@2thumbsupapps.com)."* — instead of the pre-feature *"Item Unavailable … doesn't
  have permission."* The blocker is cleared.
- New unit tests: `SharingServiceTests` (email-format matrix, new `SharingError` messages,
  pre-network `invalidEmail` guard) — 11/11 with `SharingPermissionStoreTests`.

**Not completed (test-harness limitation, not a feature defect):** tapping **Open** on the
iPad's CloudKit accept alert. The iPad simulator runs landscape-rotated and the `control` tap
tooling does not map coordinates onto that system alert reliably (repeated misses land on
"Not Now" / behind it; Return-key doesn't fire the default action). Because the share is never
accepted on the iPad, the downstream steps — note created on A appears on B, cross-account
same-note conflict, Journey 8 named-participant attribution, read-only enforcement — remain
unobserved. Re-run on a portrait iPad sim or physical devices.

**Extra:** [SharingService.fetchShare](../../sync/SharingService.swift) now logs the share's
invite URL to OSLog **only under `-EnableLiveSync`** (`[EnableLiveSync] Share URL for library …`)
so the manual Phase 4 procedure can pick it up via `log stream` without needing
`UICloudSharingController`'s flaky Copy Link. Never logged in a normal build.

Update this table's counts and status column as boxes below are checked.

---

## User Story

As a NoteBytez owner sharing a library from a device that has no Mail or Messages account
configured — a Simulator, a freshly-signed-in device, or a managed/MDM setup — I want to add a
collaborator by typing their Apple Account email address directly into NoteBytez's Sharing
screen and choosing their permission level, so that a real `CKShare` participant is established
without me having to route an invitation through the system share sheet's Mail/Messages compose
flow (which isn't available to me).

## Success Factors

1. From S22 (Sharing / Participants), an owner can enter an email address, pick a permission
   (Read Only / Read & Write), tap **Add**, and the person becomes a participant on the
   library's `CKShare` — with **no `UICloudSharingController` and no Mail/Messages compose UI**
   involved at any point.
2. The added participant is a genuine `CKShare.Participant` resolved from CloudKit (email →
   `CKUserIdentity`), persisted on the share, and then shown in the S22 participants list with
   their resolved name (falling back to the email) and permission label — reusing the existing
   `ParticipantRow` / `SharingPermissionStore.displayName` path.
3. The recipient can then accept the library via the existing **Copy Link** URL (or a system
   invite) and gains access at exactly the granted permission — verified live between the
   `kontinuum1` / `kontinuum2` accounts on the iPad + iPhone simulators, against the CloudKit
   **Development/Sandbox** environment only.
4. Input is validated: a malformed address is rejected locally before any network call; an
   address that doesn't resolve to an iCloud account produces a **specific** error ("No Apple
   Account found for that email"), not a generic CloudKit failure string; adding someone
   already on the share is a no-op with a clear message.
5. Owner-only: a participant viewing a library shared *to* them never sees the add-by-email
   affordance — same `viewModel.isOwner || participants.isEmpty` gate as the existing
   "Invite Participant" button.
6. No regression: the existing `UICloudSharingController` "Invite Participant" button and its
   Copy Link / native-invite behavior are unchanged. This feature is strictly additive.
7. All failure paths surface through the existing `SharingViewModel.errorMessage` → `.alert`
   channel — never a silent `return`, `print`, or an unhandled `throw`.
8. Deterministic unit coverage: `SharingServiceTests` and `SharingViewModelTests` exercise
   resolve-success, malformed-email, unresolvable-email, and duplicate-participant against an
   injected resolver seam — no live network. With this feature merged,
   [NoteBytez20260823v1-UITests.md](NoteBytez20260823v1-UITests.md) Phase 4 is executable
   end-to-end on the simulators (Journeys 3 and 8 live path), subject to the sandbox caveat in
   Gaps below.
9. Security unchanged: `share.publicPermission` stays `.none` (access remains per-invited-
   participant, not link-anyone); entered email addresses are not written to `OSLog`. Consistent
   with [NoteBytez20260627v2-Security.md](NoteBytez20260627v2-Security.md) §4.6 (participant
   identity) and §4.7 (share link handling).

## Background — why, not what

R1 Phase 10 built sharing around `UICloudSharingController` for invite delivery
([CloudSharingControllerRepresentable.swift](../../views/Components/CloudSharingControllerRepresentable.swift)):
`SharingViewModel.startInviting()` creates the `CKShare` and flips
`isPresentingInviteController`, and the system controller handles adding people. That is the
right primary path on a real device with Mail/Messages.

It has no fallback. On the iPhone + iPad simulators used for the Phase 4 two-account test
(2026-08-30/31):

1. `UICloudSharingController` → "Share With More People" opens the plain iOS share sheet with
   only **Invite with Link / Reminders / More / Copy Link**. No Mail or Messages account exists
   to address a specific person, and that sheet has no "type an address" field of its own.
2. **Invite with Link** → *"Couldn't Add People — a link couldn't be created for you to share."*
   The Simulator's CloudKit sandbox will not mint a public/link share.
3. **Copy Link** produces a URL, but [SharingService.swift:65](../../sync/SharingService.swift)
   sets `share.publicPermission = .none`, so an account that isn't already an invited
   participant opening that URL gets *"Item Unavailable … doesn't have permission."*

So there is no route to add `kontinuum2@2thumbsupapps.com` as a participant, and every
cross-account item (data created on A appears on B, cross-account conflict, Journey 8
named-participant attribution) is untestable.

CloudKit already supports resolving a participant from an email entirely in code —
`CKContainer.shareParticipant(forEmailAddress:)` returns a `CKShare.Participant` with no
compose UI. Adding a thin owner-only affordance for it on S22 unblocks the tests and is a
legitimate feature for any Mail-less setup, with no schema change and no weakening of the
private-share model.

## Decisions Log

1. **Resolve via `CKContainer.shareParticipant(forEmailAddress:)` (async, iOS 16+).** Single
   call, no `CKFetchShareParticipantsOperation` lifecycle to manage — matches the async/await
   CloudKit style already in `SharingService` / `SyncEngine`. NoteBytez targets iOS 26, so
   availability is a non-issue.
2. **Always available, not gated behind `-EnableLiveSync`.** It's a real feature for real users
   on Mail-less devices, needs no schema, and does not touch `publicPermission`. Gating it would
   add a `#if`/flag branch inside a `View` for zero product benefit and would still leave the
   manual Phase 4 procedure needing a special build. (Alternative considered and rejected:
   debug-only affordance.)
3. **Reuse `SharingService.createShare`.** If the library has no share yet, `addParticipant`
   creates it first (exactly as `startInviting()` does today), then adds the participant — one
   code path, no "you must invite via the controller first" ordering trap.
4. **Permission picker defaults to Read & Write** — the common collaboration case, and the
   first entry in `CloudSharingControllerRepresentable.availablePermissions`
   (`[.allowReadWrite, .allowPrivate]`). Read Only is the other option.
5. **UI: a new `Section` in [SharingParticipantsView](../../views/Sharing/SharingParticipantsView.swift)**
   — `TextField` (email) + permission `Picker` + `Add` `Button` — shown under the same
   `viewModel.isOwner || viewModel.participants.isEmpty` condition as the existing button, which
   stays. Not a separate screen: S22 is already the sharing surface and the wireframe treats it
   as one sheet.
6. **Local validation is lightweight and stdlib-only** — non-empty, single `@`, non-empty
   local + domain parts, no whitespace. No regex framework, no dependency (CLAUDE.md §5).
   Authoritative resolution is CloudKit's; the local check only avoids a pointless round trip
   and gives an instant field-level error.
7. **Three-layer split, matching `updatePermission` / `removeParticipant`.** CloudKit work in
   `SharingService.addParticipant(...)`; `SharingViewModel.addParticipant(email:permission:)`
   turns it into display state; the view binds. New-participant field state is view-local
   `@State` (the view model doesn't need it).
8. **New `SharingError` cases** — `invalidEmail`, `participantNotFound`, `alreadyParticipant` —
   each with a specific `errorDescription`, so success factor #4's messages are real strings not
   `error.localizedDescription` passthrough.
9. **Duplicate check** against `share.participants` by resolved `userRecordID` (preferred) or
   `userIdentity.lookupInfo?.emailAddress` (fallback), before `share.addParticipant`.

## Implementation Plan

### Phase 0 — Test seam

- [x] ~~Introduce `protocol ShareParticipantResolving` + inject into `SharingService.init`.~~
      **Collapsed on implementation (2026-08-31).** The codebase has **no protocol-based service
      injection anywhere** — view models take a `ModelContext`; `SharingService` /
      `SyncEngine` / `SharingPermissionStore` are concrete singletons whose CloudKit-facing
      methods are explicitly left to the manual live procedure (`SharingPermissionStoreTests`,
      `ConflictResolverTests`, `SyncEngineTests` each say so). Adding a resolver protocol +
      fake `CKDatabase` would be a bigger abstraction than exists anywhere else, against
      CLAUDE.md §2/§3. Instead: unit-test the pure parts (email-format matrix, error strings,
      pre-network `invalidEmail` guard), implement the CloudKit path directly, and let Phase 4's
      live run cover the round trip — same pattern as the rest of `sync/`.
      → verify: `SharingServiceTests` green alongside `SharingPermissionStoreTests` /
      `SharedLibraryRegistryTests` — **11/11 on iPhone 17 sim**.

### Phase 1 — Service layer (TDD)

- [x] Pure `SharingService.isValidEmailFormat(_:)` (static, stdlib-only) + failing then passing
      `SharingServiceTests` email-format matrix.
      → verify: `acceptsAWellFormedAddress`, `rejectsEmptyWhitespaceOrMissingParts`,
      `rejectsADomainWithoutAValidDot` — green.
- [x] Implement `SharingService.addParticipant(emailAddress:permission:forLibraryId:libraryName:) async throws`:
      1. trim + `isValidEmailFormat` → `throw SharingError.invalidEmail`
      2. `share = try await fetchShare(...)` else `createShare(...)` (no `??` — `await` can't sit
         in an autoclosure)
      3. `try await container.shareParticipant(forEmailAddress:)`; any throw → `.participantNotFound`
      4. duplicate check against `share.participants` (by `userRecordID`, else `lookupInfo?.emailAddress`)
         → `.alreadyParticipant`
      5. `participant.permission = permission; share.addParticipant(participant)`
      6. `try await database.modifyRecords(saving: [share], deleting: [])` (matches
         `updatePermission` / `removeParticipant`)
      7. `SharingPermissionStore.shared.update(forLibraryId:, share: savedShare)`
      → verify: builds; exercised live in Phase 4 (resolves `kontinuum2`, adds, saves).
- [x] `addParticipantThrowsInvalidEmailBeforeAnyNetworkCall` — malformed address throws
      `.invalidEmail` from the local guard, never touching `container`.
      → verify: green (the resolver/CloudKit path is unreachable in this test).
      `participantNotFound` / `alreadyParticipant` paths need a live `CKShare` — covered in Phase 4.
- [x] Extend `SharingError` with `invalidEmail`, `participantNotFound`, `alreadyParticipant`
      + specific `errorDescription` for each.
      → verify: `newErrorCasesCarrySpecificMessages` green; exhaustive switch, no `@unknown default`.

### Phase 2 — View model

- [x] ~~Stub-`SharingService` VM tests.~~ Not added — no protocol seam (see Phase 0); the VM
      method is a thin passthrough and is exercised end-to-end in Phase 4.
- [x] Add `SharingViewModel.addParticipant(email:permission:) async` — `isLoading` toggle with
      `defer`; on success `errorMessage = nil` then `await loadShare()`; on `throw`
      `errorMessage = error.localizedDescription`.
      → verify: builds; live run shows the participant appear in the list after the call.
- [x] Email/permission are view `@State` (`newParticipantEmail`, `newParticipantPermission`);
      `SharingViewModel` surface unchanged except the one new method.
      → verify: build.

### Phase 3 — View (S22)

- [x] Added an **"Add by Email"** `Section` to
      [SharingParticipantsView](../../views/Sharing/SharingParticipantsView.swift), inside the
      existing `if viewModel.isOwner || viewModel.participants.isEmpty` block, before the
      "Invite Participant" button (button unchanged): `TextField("Apple Account email")` with
      `.autocorrectionDisabled()` + `#if os(iOS)` `.textInputAutocapitalization(.never)` /
      `.keyboardType(.emailAddress)` / `.textContentType(.emailAddress)` (matches
      `CanvasBoardView`'s cross-platform pattern); permission `Picker` (Read & Write default /
      Read Only); `Button("Add")` disabled on `isLoading || !isNewParticipantEmailValid`
      (`isNewParticipantEmailValid` calls `SharingService.isValidEmailFormat` on the trimmed
      value). Accessibility ids `sharing.addByEmail.field` / `.permission` / `.button`.
      → verify: **renders on iPhone 17 sim**; "Add" grey/disabled when empty, turns teal/enabled
      once `kontinuum2@2thumbsupapps.com` is typed.
- [x] Button wired: `Task { await viewModel.addParticipant(…); if viewModel.errorMessage == nil { newParticipantEmail = "" } }`.
      → verify: **live** — tapping Add resolved the email and the "Participants" section now
      shows `kontinuum2@2thumbsupapps.com — Read & Write`; the field cleared on success.
- [x] Style — reused the plain `Section("Add by Email")` header + default List row rhythm,
      consistent with `ParticipantRow` and the existing button.
      → verify: visual check on iPhone (compact) — matches S22.

### Phase 4 — Live two-account verification (drives [NoteBytez20260823v1-UITests.md](NoteBytez20260823v1-UITests.md) Phase 4)

- [x] iPhone (`kontinuum1`, `-EnableLiveSync`): "Sync test" → Settings → Sharing → Add by
      Email → `kontinuum2@2thumbsupapps.com` as **Read & Write** → **participant appears** as
      `kontinuum2@2thumbsupapps.com — Read & Write` ("?" avatar / email fallback — no name until
      accept). Logs confirm `CKFetchShareParticipantsOperation` → `CKUserIdentity(…,
      hasiCloudAccount=true)`. `UICloudSharingController` lists it as **"Invited"**.
      → verified: screenshots + `cloudd` log.
- [x] iPhone: got the share URL (`[EnableLiveSync] Share URL …` log →
      `https://www.icloud.com/share/…#Sync_test`). iPad (`kontinuum2`, `-EnableLiveSync`):
      `xcrun simctl openurl …` → **real system accept prompt appears**: *"NoteBytez1 TestUser
      wants to collaborate. You'll join as NoteBytez2 TestUser (kontinuum2@2thumbsupapps.com)."*
      (Pre-feature this was *"Item Unavailable … doesn't have permission."*)
      → verified: screenshot. **Tapping "Open" not completed** — the iPad sim runs
      landscape-rotated and `control` tap coordinates don't map onto that system alert reliably
      (misses land on "Not Now" / behind; Return key doesn't fire the default). Share therefore
      not accepted on the iPad.
- [ ] Cross-account content sync — **blocked**: needs the share accepted on the iPad (see above).
- [ ] Cross-account conflict + S10 named attribution (Journey 3 / 8) — **blocked** on the same.
      (Note: single-account S10 conflict-detection→resolution was already verified 2026-08-31 in
      the earlier session — real `.serverRecordChanged` → `ConflictStore` → S10 → resolve.)
- [ ] Read-only enforcement across accounts — **blocked** on the same. (Single-device read-only
      rejection is covered by `SyncEngineTests.recordChangedOnAReadOnlyLibraryReportsASyncError`.)
      Once the iPad accept lands (portrait sim or physical devices), flip
      [NoteBytez20260823v1-UITests.md](NoteBytez20260823v1-UITests.md) Phase 4 / Phase 0.a boxes.

### Phase 5 — Quality gate

- [x] `SharingServiceTests` (5 new: `acceptsAWellFormedAddress`,
      `rejectsEmptyWhitespaceOrMissingParts`, `rejectsADomainWithoutAValidDot`,
      `newErrorCasesCarrySpecificMessages`, `addParticipantThrowsInvalidEmailBeforeAnyNetworkCall`)
      run alongside `SharingPermissionStoreTests` — deterministic, no live network. Picked up
      automatically by the `KontinuumTests` filesystem-synchronized group.
      → verify: `xcodebuild test -only-testing:KontinuumTests/SharingServiceTests
      -only-testing:KontinuumTests/SharingPermissionStoreTests` — **11/11 pass** on iPhone 17.
      Full `KontinuumCIGate` run not re-executed this session.
- [x] Mac + iPhone build green (`xcodebuild build -destination platform=macOS` → **BUILD
      SUCCEEDED**; the `#if os(iOS)` guards on `.keyboardType`/`.textInputAutocapitalization`/
      `.textContentType` compile clean on macOS). iPhone: build + renders. iPad regular-width
      layout not screenshotted (same SwiftUI `Section`, no platform branch).
      → verify: macOS + iOS-sim builds pass; iPhone screenshot captured.

## Gaps / Open Questions

- **Sandbox account resolution by email — RESOLVED FAVORABLY (2026-08-31).**
  `container.shareParticipant(forEmailAddress: "kontinuum2@2thumbsupapps.com")` in the Simulator
  Sandbox returned `CKUserIdentity(hasiCloudAccount=true)` and the participant added + saved
  cleanly. The main risk this plan flagged does not apply here.
- **iPad accept tap-through — the actual remaining blocker.** The iPad simulator is
  landscape-rotated and `mcp__Claude_Code_iOS_Simulator__control` tap coordinates do not map
  onto the CloudKit accept alert (`com.apple.CloudKit.ShareBear`'s `UIAlertController`)
  reliably — repeated attempts landed on "Not Now" or behind the alert, and a Return keypress
  did not fire the default button. Re-run on a **portrait** iPad sim (or physical devices) to
  finish Phase 4 steps 3–5.
- **Abandoned-share teardown — CONFIRMED SIDESTEPPED.** In the 2026-08-31 run, adding
  `kontinuum2` by email *before* opening `UICloudSharingController` kept the `CKShare` alive
  through the controller's dismissal (S22 still showed the participant + "Stop Sharing"),
  unlike the participant-less shares in earlier sessions which were torn down on dismiss.
- **Pre-existing `fetchShare` flakiness (out of scope).** During the 2026-08-30/31 runs, S9
  showed "This library is shared" while S22 showed "Not Shared" at the same time —
  `SharingViewModel.loadShare()` → `SharingService.fetchShare`'s direct `database.record(for:)`
  is unreliable on the simulator and nils `SharingPermissionStore` inconsistently. Not fixed
  here. Flagged for a separate change (candidate: fetch the share off the `CKShare.recordID`
  the engine already knows, or retry).
- **`publicPermission` stays `.none` by decision.** If a future need for true link-anyone
  sharing appears, that's a separate plan with its own [NoteBytez20260627v2-Security.md](NoteBytez20260627v2-Security.md)
  §4.7 review — explicitly not folded in here.
