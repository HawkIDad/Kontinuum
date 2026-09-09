<!-- NoteBytez20260909v1-Bundle.md -->
<!--
  Bundle identifier + CloudKit container re-homing: com.g9Consulting.* -> com.kwicksync.*.
  Follows the completed Kontinuum -> NoteBytez rename (NoteBytez20260908v1-ProjectRename.md),
  which deliberately kept the CloudKit container as the sole legacy identifier. This plan
  removes that last exception too.
  Interview: 2026-09-09 (2 rounds). Resolutions in "Gaps and Resolution".
-->

# Bundle Identifier — `com.g9Consulting` → `com.kwicksync`

## User Story

**As** the Business Owner, **I** have registered the domains for this application —
**`notebytez.com`** (application domain) and **`kwicksync.com`** (business domain) — **and I want**
every build-identity string that currently carries the `com.g9Consulting` organization prefix
moved to `com.kwicksync`, **so that** the shipping app is namespaced under the business that
actually owns it and no `g9Consulting` (or its predecessor `Kontinuum`) identifier survives
anywhere in the tree.

Concretely, this changes:

- the three target bundle identifiers → `com.kwicksync.NoteBytez` / `…NoteBytezTests` / `…NoteBytezUITests`;
- the CloudKit container → a **new** `iCloud.com.kwicksync.NoteBytez` (the previous
  `iCloud.com.g9Consulting.Kontinuum`, retained through the last rename because containers
  cannot be renamed, is abandoned — pre-launch data is disposable);
- every other embedded `com.g9Consulting.*` string — StoreKit product IDs, the entitlement
  Keychain service, the `Logger` subsystem fallback, a `DispatchQueue` label;
- all documentation and the `Scripts/verify-rename.sh` enforcement gate.

The Apple Developer **team is unchanged** (`S4843K7ZH6`, Individual, "David Collison"). This is
an identifier change only — app display name, Swift module, targets, scheme, folders, and the
`rename/notebytez-project` work are all untouched.

## Prerequisites

1. The app has **not** been distributed through TestFlight.
2. The app has **not** been distributed through any Apple App Store (iOS or macOS).
3. The app has only been run on Xcode Simulators and Claude for Mac — no physical devices.
4. **`rename/notebytez-project` is merged to `main`.** This plan branches off the merged
   `main`; it assumes the NoteBytez project identity (project file, targets, folders, bundle
   IDs `com.g9Consulting.NoteBytez{,Tests,UITests}`) is already in place. The loose
   `41a264d "Workspace udpates."` commit rides along with that merge and is left as-is.
5. **Pre-launch, disposable data.** No CloudKit data migration. The old
   `iCloud.com.g9Consulting.Kontinuum` container is left in the Developer portal, unused; it is
   not deleted by this plan.
6. **No domain-ownership proof is required.** A bundle-identifier prefix is reverse-DNS
   *convention* only; Apple verifies domain ownership solely for Associated Domains / universal
   links, which this app does not use. Registering `kwicksync.com` is a business decision, not
   a technical precondition.
7. **Signing is automatic under team `S4843K7ZH6`.** The first `xcodebuild` of each new
   identifier uses `-allowProvisioningUpdates` to mint the App ID / provision the container, as
   was done for `com.g9Consulting.NoteBytez` on 2026-09-08. The Xcode **GUI** signing caveat
   from that session (Xcode signed in as `dlcollison@gmail.com`; only the Individual team is
   offered in the Team dropdown) is unresolved but does **not** block CLI builds and is out of
   scope here — noted as a handoff item.

## Success Factors

Each is objectively checkable; the check is named. All must pass for Definition of Done.

### SF1 — Bundle identifiers are `com.kwicksync.*`
`PRODUCT_BUNDLE_IDENTIFIER` for the app, unit-test, and UI-test targets (Debug **and** Release)
reads `com.kwicksync.NoteBytez`, `com.kwicksync.NoteBytezTests`, `com.kwicksync.NoteBytezUITests`.
**Check:** `xcodebuild -showBuildSettings` for each target.

### SF2 — CloudKit container is `iCloud.com.kwicksync.NoteBytez`
Both entitlement files (`icloud-container-identifiers` + `ubiquity-container-identifiers`),
`SyncEngine.containerIdentifier`, and `AttachmentStorage.ubiquityContainerIdentifier` name the
new container. The packaged entitlements in a real iOS **and** macOS build log contain it and
nothing referencing the old one. **Check:** build-log entitlement dump; `grep` of the two Swift
constants.

### SF3 — Zero `g9Consulting` / `Kontinuum` anywhere
A case-insensitive search of all git-tracked text (`git grep -I -i`) for `g9consulting` or
`kontinuum` returns nothing outside `Scripts/verify-rename.sh`'s own explanatory text.
**Check:** `git grep -nI -iE 'g9consulting|kontinuum'`.

### SF4 — Embedded identifiers and StoreKit products renamed
Keychain service `com.kwicksync.NoteBytez.entitlement`; product IDs
`com.kwicksync.NoteBytez.sub.monthly` / `.sub.annual` in both `Entitlement.swift` and
`NoteBytez.storekit`; `Logger` subsystem fallback and the `SyncStatusStore` `DispatchQueue`
label on `com.kwicksync.*`. **Check:** `grep`; `NoteBytezTests` green (exercises `EntitlementCache`,
`Entitlement`).

### SF5 — Builds succeed, no new warnings
`xcodebuild clean build` for iOS (`-allowProvisioningUpdates`) and macOS
(`-destination 'platform=macOS' -allowProvisioningUpdates`) both report `** BUILD SUCCEEDED **`.
Warning count is unchanged from the Phase 0 baseline — the tree carries pre-existing Swift 6
main-actor-isolation warnings that are **not** in scope here. **Check:** two build logs vs.
baseline.

### SF6 — `NoteBytezTests` green
Up to **3** runs. Target: `✔ Test run with 782 tests in 84 suites passed` (the ProjectRename
Phase 8 baseline). Any residual failure is listed with resolution options.
**Check:** `xcodebuild test -only-testing:NoteBytezTests`.

### SF7 — `NoteBytezUITests` no regression
Up to **3** runs, via the **`NoteBytezCIGate`** test plan, against a Simulator **signed into
iCloud**. Success = no regression versus the Phase 0 baseline. The headless
`Phase1*SmokeTests` failures (~25/39, stall before the main shell; CloudKit
`CKAccountStatusTemporarilyUnavailable` / harness) are **already documented as pre-existing** in
`NoteBytez20260908v1-ProjectRename.md` → "Known issue" and remain out of scope. Any *new*
failure is listed with resolution options. **Check:** UI-test run vs. baseline.

### SF8 — Enforcement gate updated and green
`Scripts/verify-rename.sh` no longer allow-lists any container literal; it exits 1 on any
case-insensitive `g9consulting` or `kontinuum` in tracked text, and confirms
`iCloud.com.kwicksync.NoteBytez` is present. `bash Scripts/verify-rename.sh` exits 0.
**Check:** run it; canary PASS → FAIL → PASS.

### SF9 — Docs consistent
`ARCHITECTURE.md` and repo-root `NoteBytez/CLAUDE.md` reference only the new identifiers.
Dated historical plans carry a one-line "superseded in part" banner; their identifier strings
are swept, their decision text intact. **Check:** `git grep` + review.

### SF10 — Delivered on a branch
`bundle/kwicksync-id` off `main`, phased commits (bundle IDs → container → embedded strings →
docs → gate → verify), one PR to `main`. **Check:** `git log --graph`.

## Gaps and Resolution

### Resolved by interview — 2026-09-09

| # | Gap | Resolution |
|---|-----|------------|
| **R1** | CloudKit container — associate the new App ID with the existing `iCloud.com.g9Consulting.Kontinuum`, or create a fresh one? | **Create `iCloud.com.kwicksync.NoteBytez`.** Data is disposable and pre-launch; a clean end-to-end identity is worth the one-time schema re-create. The old container is abandoned in place, not deleted. |
| **R2** | Sweep breadth — only the three target bundle IDs, or every `com.g9Consulting.*` string? | **Everything.** Target bundle IDs, StoreKit product IDs (`Entitlement.swift` + `.storekit`), entitlement Keychain service (`EntitlementCache.swift`), `Logger` subsystem fallback (`Logging.swift`), `DispatchQueue` label (`SyncStatusStore.swift`), and the container. One consistent org namespace. |
| **R3** | Documentation + the `verify-rename.sh` gate. | **Full `.md` sweep + extend the gate.** Sweep every non-`z_` `.md` (identifier strings, as Phase 5 of the rename did for "Kontinuum"). Extend `verify-rename.sh` to fail on `g9consulting` **and** `kontinuum` with no allow-list, plus a presence check for the new container literal. |
| **R4** | Branch base — the Kontinuum→NoteBytez rename is **not** in `main` (verified: Phase 8 commit `7dd3b71` is not an ancestor of `main`; `main` still has `Kontinuum.xcodeproj`). | **Maintainer merges `rename/notebytez-project` → `main` first.** This plan then cuts `bundle/kwicksync-id` off the updated `main`. Recorded as Prerequisite 4. |
| **R5** | Loose `41a264d "Workspace udpates."` commit on top of Phase 8 (xcuserstate / workspace churn). | **Left as-is.** It merges to `main` with the rest of the rename branch; no rebase or amend. |

### Derived defaults — flag if wrong

| # | Item | Default taken | Rationale |
|---|------|---------------|-----------|
| **DD1** | Bundle-ID casing | `com.kwicksync.NoteBytez` exactly — lowercase org segment, PascalCase app segment; tests `…NoteBytezTests` / `…NoteBytezUITests`. | Mirrors the shape of the current `com.g9Consulting.NoteBytez`; bundle IDs are case-insensitive to Apple but the convention is a lowercase org segment. |
| **DD2** | Old `iCloud.com.g9Consulting.Kontinuum` container | Abandoned in the Developer portal; **not** deleted. | Deleting a container is irreversible and outside a code change. No cost to leaving an unused pre-launch container. Listed as an optional handoff cleanup. |
| **DD3** | Old `com.g9Consulting.NoteBytez*` App IDs | Left in the portal. | Same as DD2 — harmless, and automatic signing simply stops referencing them. |
| **DD4** | Keychain service string change | Any entitlement cached under `com.g9Consulting.NoteBytez.entitlement` is orphaned; `EntitlementCache` uses the new key going forward. | Pre-launch, disposable; the cache is a performance optimization with a StoreKit source of truth. No migration code. |
| **DD5** | StoreKit product IDs | Changed in `NoteBytez.storekit` and `Entitlement.swift` only. | Nothing exists in App Store Connect yet; the local `.storekit` file is the only consumer. `_developerTeamID` and structural keys untouched. |
| **DD6** | New container — **Development** schema | Auto-created from client writes on first run / first `NoteBytezTests` execution (CloudKit Development allows client-driven schema creation). | Standard CloudKit behavior; no console step needed for dev/test. |
| **DD7** | New container — **Production** schema | **Not deployed by this plan.** A maintainer runs "Deploy Schema Changes" in the CloudKit Console before any production use. | Pre-launch; Production is never exercised in Simulator testing. Recorded in Phase 7 handoff. |
| **DD8** | Old container's hand-tuned schema (queryable indexes, per-library `CKRecordZone`s, subscriptions per `NoteBytez20260627v2-Security.md`) | **Not migrated.** `CKSyncEngine` recreates record zones automatically; no `CKQuery` currently depends on a custom index. Re-add indexes only if a query need appears. | Sync is `CKSyncEngine`-driven, not `CKQuery`-driven; zones are recreated on first sync. |
| **DD9** | Container provisioning | Attempt auto-create via `xcodebuild … -allowProvisioningUpdates` (Xcode automatic iCloud management). If it does not auto-create, create once in Apple Developer portal → Identifiers → iCloud Containers, then rebuild. | Matches how `com.g9Consulting.NoteBytez` was provisioned on 2026-09-08; the fallback is a known one-time portal action. |
| **DD10** | SF5 "no warnings" | Reinterpreted as **no new warnings vs. the Phase 0 baseline**. | The tree already emits Swift 6 main-actor-isolation warnings (seen in the 2026-09-08 build); eliminating them is separate work. |
| **DD11** | Historical dated plans (`NoteBytez20260906v1-NameChange.md`, `NoteBytez20260908v1-ProjectRename.md`, `NoteBytez20260627v2-Security.md`, `NoteBytez-MVP-ImplementationPlan.md`, `NoteBytez-MacImplementation.md`, `NoteBytez-R1-Implementation.md`, `NoteBytez-ReleaseFeatures.md`, `NoteBytez20260823v1-UITests.md`) | Identifier **strings** swept to the new names (as rename Phase 5 did for "Kontinuum"); a one-line "superseded in part by `NoteBytez20260909v1-Bundle.md`" banner added to the two rename plans; **decision text not rewritten**. | Keeps `verify-rename.sh` absolute (no path allow-list) while preserving the historical record of *why* each choice was made. |
| **DD12** | Workspace-level `../CLAUDE.md` (outside this repo) | Out of scope. It references a *different* app's container (`iCloud.com.g9consulting.G9WorldPass`); nothing there names this app's identifiers. | Not git-tracked in this repo; shared across projects. |
| **DD13** | `xcuserdata` / `*.xcuserstate` | Left to regenerate; never hand-edited. | Machine-generated UI state; already dirty in `git status`. |
| **DD14** | App display name, Swift module, targets, scheme, folders | Unchanged. | This is an identifier change, not another project rename. |
| **DD15** | Baseline capture | Before any edit, record `xcodebuild` iOS+macOS result, the `NoteBytezTests` count, and the `NoteBytezUITests` headless pass/fail split on the branch point. | "Green before and after" needs a known "before"; SF5/SF7 compare against it. |

## Implementation Plan

Success criterion: every phase's checklist complete and its **verify** line satisfied. Attempt
each verification up to **3 times**; on a third failure, stop and surface the failure with
options (per `CLAUDE.md` §4). The checklist below is the living record — tick items as they land.

### Phase 0 — Branch & baseline
- [ ] Confirm `rename/notebytez-project` is merged: `git merge-base --is-ancestor 7dd3b71 main` exits 0
- [ ] `git checkout main && git pull`
- [ ] `git switch -c bundle/kwicksync-id`
- [ ] Baseline build: `xcodebuild -project NoteBytez.xcodeproj -scheme NoteBytez -destination 'generic/platform=iOS' -allowProvisioningUpdates clean build` → record result + warning count
- [ ] Baseline build: same for `-destination 'platform=macOS'`
- [ ] Baseline `NoteBytezTests` count (expect 782/782)
- [ ] Baseline `NoteBytezUITests` via `NoteBytezCIGate` headless — record pass/fail split (expect ≈14/39 passing, per rename "Known issue")
- **Verify:** baseline figures written into the Execution Log below.

### Phase 1 — Target bundle identifiers (SF1) → `project.pbxproj`
- [ ] App target `PRODUCT_BUNDLE_IDENTIFIER` (Debug + Release) → `com.kwicksync.NoteBytez`
- [ ] `NoteBytezTests` (Debug + Release) → `com.kwicksync.NoteBytezTests`
- [ ] `NoteBytezUITests` (Debug + Release) → `com.kwicksync.NoteBytezUITests`
- [ ] `DEVELOPMENT_TEAM = S4843K7ZH6` and `CODE_SIGN_STYLE = Automatic` unchanged
- **Verify:** `xcodebuild -showBuildSettings` shows the three new IDs; `xcodebuild build -allowProvisioningUpdates` (iOS) `** BUILD SUCCEEDED **` with the new App ID `com.kwicksync.NoteBytez` auto-provisioned.

### Phase 2 — CloudKit container (SF2) → entitlements + Swift
- [ ] `NoteBytez/NoteBytez.entitlements`: `com.apple.developer.icloud-container-identifiers` and `com.apple.developer.ubiquity-container-identifiers` → `iCloud.com.kwicksync.NoteBytez`
- [ ] `NoteBytez/NoteBytez-macOS.entitlements`: same two keys
- [ ] `NoteBytez/sync/SyncEngine.swift` — `static let containerIdentifier` → `iCloud.com.kwicksync.NoteBytez`
- [ ] `NoteBytez/dal/AttachmentStorage.swift` — `private static let ubiquityContainerIdentifier` → same
- [ ] Provision the container: `xcodebuild build -allowProvisioningUpdates` (iOS + macOS). If not auto-created, create once in Apple Developer portal → Identifiers → iCloud Containers, then rebuild (DD9).
- **Verify:** iOS and macOS build-log entitlement dumps contain `iCloud.com.kwicksync.NoteBytez` and no `Kontinuum`; app launches in the Simulator; `SyncEngine` init logs no container error in a Debug run.

### Phase 3 — Remaining embedded identifiers (SF4)
- [ ] `NoteBytez/dal/EntitlementCache.swift` — Keychain `service` default → `com.kwicksync.NoteBytez.entitlement`
- [ ] `NoteBytez/models/Entitlement.swift` — `monthly` / `annual` product-ID constants → `com.kwicksync.NoteBytez.sub.monthly` / `.sub.annual`
- [ ] `NoteBytez/StoreKit/NoteBytez.storekit` — both `productID` values → `com.kwicksync.NoteBytez.sub.*`
- [ ] `NoteBytez/Logging.swift` — `Logger` subsystem fallback string → `com.kwicksync.NoteBytez`
- [ ] `NoteBytez/sync/SyncStatusStore.swift` — `DispatchQueue(label:)` → `com.kwicksync.NoteBytez.SyncStatusStore`
- **Verify:** `git grep -nI -i 'g9consulting' -- '*.swift' '*.storekit'` returns nothing; `NoteBytezTests` 782/782.

### Phase 4 — Documentation sweep (SF9)
- [ ] `git grep -lI -iE 'g9consulting|kontinuum'` → for every non-`z_` `.md`: `iCloud.com.g9Consulting.Kontinuum` → `iCloud.com.kwicksync.NoteBytez`; `com.g9Consulting` → `com.kwicksync`
- [ ] Repo-root `NoteBytez/CLAUDE.md` — CloudKit-container line → new container
- [ ] `NoteBytez/ARCHITECTURE.md` — "Retained Name" section reworked to "Identifier History" (surface rename → internal rename → bundle-ID/container change; nothing now retained)
- [ ] `NoteBytez20260908v1-ProjectRename.md` and `NoteBytez20260906v1-NameChange.md` — add banner: `> Superseded in part by NoteBytez20260909v1-Bundle.md — the CloudKit container and org prefix were subsequently changed to com.kwicksync.` Body identifier strings swept; decision text unchanged.
- [ ] Remaining dated plans (Security, UITests, MVP, MacImplementation, R1, ReleaseFeatures) — string sweep only
- **Verify:** `git grep -I -iE 'g9consulting|kontinuum'` returns only matches inside `Scripts/verify-rename.sh` (handled next).

### Phase 5 — Enforcement gate (SF8) → `Scripts/verify-rename.sh`
- [ ] Remove the `ALLOWED` container allow-list
- [ ] Fail (exit 1) on any case-insensitive `g9consulting` **or** `kontinuum` in `git grep -nI` output, excluding the script itself
- [ ] Replace the "container literal must be present" check with a presence check for `iCloud.com.kwicksync.NoteBytez`
- [ ] Rewrite the header comment to describe the new rule
- **Verify:** `bash Scripts/verify-rename.sh` exits 0; add a tracked canary line containing `com.g9Consulting` → script exits 1 → remove canary → exits 0.

### Phase 6 — Full build, test, run (SF5, SF6, SF7)
- [ ] `xcodebuild -scheme NoteBytez -destination 'generic/platform=iOS' -allowProvisioningUpdates clean build` → `** BUILD SUCCEEDED **`, warning count == baseline
- [ ] `xcodebuild -scheme NoteBytez -destination 'platform=macOS' -allowProvisioningUpdates clean build` → `** BUILD SUCCEEDED **`
- [ ] `NoteBytezTests` — up to 3 runs → 782/782, else list failures + options
- [ ] `NoteBytezUITests` via `-testPlan NoteBytezCIGate`, Simulator signed into iCloud — up to 3 runs → no regression vs. Phase 0, else list failures + options
- [ ] Simulator launch: library-selection screen renders titled "NoteBytez"; in a Release build with a signed-in iCloud account `SyncEngine` connects to `iCloud.com.kwicksync.NoteBytez` (or record the caveat, as prior plans do)
- **Verify:** all five items green or explicitly dispositioned in the Execution Log.

### Phase 7 — Definition of Done & handoff (SF10)
- [ ] `bash Scripts/verify-rename.sh` exit 0; `git grep -iE 'g9consulting|kontinuum'` clean
- [ ] iOS + macOS `xcodebuild build` `** BUILD SUCCEEDED **`
- [ ] `NoteBytezTests` 782/782
- [ ] `NoteBytezUITests` no regression vs. baseline
- [ ] PR `bundle/kwicksync-id` → `main`, phased commits intact
- [ ] Handoff items recorded for the maintainer:
  - CloudKit Console — **deploy the `iCloud.com.kwicksync.NoteBytez` schema to Production** before any real use (DD7)
  - optional — delete the abandoned `iCloud.com.g9Consulting.Kontinuum` container and `com.g9Consulting.NoteBytez*` App IDs from the Developer portal (DD2, DD3)
  - Xcode **GUI** signing — re-authenticate the account / add the team if the Team dropdown still offers only the Individual team (2026-09-08 caveat, Prerequisite 7)

## Definition of Done

SF1–SF10 all satisfied: identifiers on `com.kwicksync.*`, container `iCloud.com.kwicksync.NoteBytez`,
zero `g9Consulting`/`Kontinuum` in tracked text, iOS + macOS builds green with no new warnings,
`NoteBytezTests` 782/782, `NoteBytezUITests` no regression, `verify-rename.sh` exit 0, docs
consistent, delivered as one PR from `bundle/kwicksync-id`.

## Execution Log — 2026-09-09

_Not started._ Prerequisite 4 (`rename/notebytez-project` → `main`) is pending.
