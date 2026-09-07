<!-- ARCHITECTURE.md -->
<!--
  Living architecture reference for NoteBytez. Update this when a decision here changes —
  it should always reflect the current system, not the history of how it got there.
-->

# NoteBytez Architecture

## Overview

NoteBytez is a native SwiftUI PKM (personal knowledge management) app for iPhone, iPad, and
Mac — Markdown-backed notes with backlinks, tagging, daily journal, tasks, search, a local
graph view, and CloudKit private sync. Mac is a first-class native destination (see "Platform
Targets" below), not the iPad app running under Mac Catalyst/"Designed for iPad" — that
approach was tried and abandoned (see
[NoteBytez-MacImplementation.md](Docs/Plans/NoteBytez-MacImplementation.md) Phase 0). See
[NoteBytez-ReleaseFeatures.md](Docs/Plans/NoteBytez-ReleaseFeatures.md) for full scope and
[NoteBytez-MVP-ImplementationPlan.md](Docs/Plans/NoteBytez-MVP-ImplementationPlan.md) for build
status.

## Tech Stack

- **UI:** SwiftUI, adaptive layout (`NavigationSplitView` on Mac/iPad, `TabView` on iPhone) —
  one implementation, not per-platform rewrites.
- **Persistence:** SwiftData, local-first (all reads/writes hit SwiftData directly; sync is
  async/background only).
- **Sync:** CloudKit private database via `CKSyncEngine`, single container
  `iCloud.com.g9Consulting.Kontinuum`.
- **Markdown parsing:** local Swift Package `MarkdownG9` (`../MarkdownG9`), extended per-feature
  (wikilinks, tags, task checkboxes). A `[[Title#Heading]]` section link reuses the same
  `wikilink://` URL scheme as a plain `[[Title]]` wikilink, carrying `Heading` as a real
  `URL.fragment` rather than a second scheme. `!((anchor))` is a render-time live-transclusion
  embed reusing the existing `blockref://` URL scheme — resolved fresh on every render, and
  since [NoteBytez20260829v2-Enhancements.md](Docs/Plans/NoteBytez20260829v2-Enhancements.md)
  Workstream B, editable in place: an edit splices back into the *source* document's own
  `content` (never the derived `Block.content` cache) and rejoins via `MarkdownBlockSplitter`,
  so the source's next `BlockDAL.syncBlocks` reclaim pass preserves block identity. Optimistic,
  last-write-wins — no merge prompt.
- **Graph rendering:** two interchangeable layouts behind `GraphViewModel.mode` — the original
  radial layout, and a hand-rolled force-directed layout (`ForceDirectedLayout`, Fruchterman-Reingold,
  seeded RNG for determinism) added by the same v2 plan's Workstream A. No third-party physics
  dependency, consistent with `CLAUDE.md`'s "leverage the Standard Library first" rule. Driven by
  `TimelineView(.animation)` + an array-indexed `Engine` (not dictionary-keyed) — the array
  indexing was a deliberate performance fix (dictionary hashing made 500-node/1500-edge layouts
  too slow; see the plan's Workstream A notes).
- **Report Generation:** local Swift Package 'SwiftRPT' ('../SwiftRPT'), extend as needed to meet
  identified feature requirements.
- **Logging:** `OSLog.Logger`.

## Platform Targets

One Xcode target, one source tree, three destinations — iPhone, iPad, and native Mac
(`SDKROOT = auto`, `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx"`). Not Mac
Catalyst: an earlier attempt ran the app as "My Mac (Designed for iPad)" and failed outright on
a provisioning/entitlement mismatch (`com.apple.developer.default-data-protection`, an iOS-only
key, didn't match the Mac profile). The current approach builds against the real `macosx` SDK
with AppKit-backed SwiftUI instead, which avoids that mismatch by construction and is the only
option consistent with this app's "unapologetically native" stance (`CLAUDE.md`).

Consequences for the code:

- **Platform-conditional app lifecycle.** `AppDelegate.swift` bridges silent CloudKit push into
  `SyncEngine` and is the one place with real platform-specific logic — `#if os(iOS)` keeps the
  `UIApplicationDelegate` path, `#if os(macOS)` adds an `NSApplicationDelegate` counterpart,
  both funneling into the same `SyncEngine.shared.handleRemoteNotification()`. `KontinuumApp.swift`
  gates `@UIApplicationDelegateAdaptor`/`@NSApplicationDelegateAdaptor` the same way. Nothing
  below the view layer (`dal/`, `sync/`, `models/`, `viewModels/`) needs to know which platform
  it's running on.
- **Per-platform entitlements/Info.plist, not per-platform code.** `Kontinuum.entitlements` /
  `Info.plist` (iOS) and `Kontinuum-macOS.entitlements` / `Info-macOS.plist` (Mac, selected via
  `[sdk=macosx*]`-suffixed build settings) both point at the same `iCloud.com.g9Consulting.Kontinuum`
  container, so a library syncs across all three platforms with no extra plumbing. The Mac
  entitlements file omits `com.apple.developer.default-data-protection` — the specific key that
  doesn't exist on macOS and broke the Catalyst attempt.
- **A small cross-platform UI compatibility layer**, not `#if os()` scattered through the view
  layer: a `View` extension standing in for `.navigationBarTitleDisplayMode(.inline)` (a no-op
  on macOS, where the type doesn't exist), and semantic `Color` statics standing in for
  `Color(.systemBackground)`/`.secondarySystemBackground` (`UIColor`-bridged, no macOS
  equivalent) — each defined once and used everywhere, rather than repeated per call site.

Full build-out plan and status: [NoteBytez-MacImplementation.md](Docs/Plans/NoteBytez-MacImplementation.md).

## Design Pattern — MVVM

- `Kontinuum/models/` — SwiftData models
- `Kontinuum/dal/` — data access layer (one DAL per model: create/read/update/soft-delete)
- `Kontinuum/viewModels/`
- `Kontinuum/views/{model name}/`

Views bind to ViewModels; ViewModels talk to the DAL; the DAL is the only layer that touches
`ModelContext` directly. `GraphInsightsDAL` (Orphans/Stale/Notes-with-Open-Tasks/Hubs/Clusters)
is computed-on-demand, same no-persisted-index rationale as `BacklinkDAL`/`SearchDAL`.

`CanvasBoard.boundDocumentId: UUID?` (optional, `nil` for an ordinary board) is a one-directional
binding: `CanvasDAL.reconcileBoundBoard` diffs the bound document's direct-link neighborhood
against the board's `.note` cards and adds/removes cards + link-mirroring connectors to match —
links flow into the canvas, never the reverse (drawing a connector between two bound note cards
prompts to create the underlying `[[link]]` rather than writing canvas layout back as data).
Reconciliation runs only on `CanvasBoardView` appear and from the bound document's own
`DocumentViewModel.save()` (guarded — a no-op unless a board is bound to that document); never a
timer or background pass. See
[NoteBytez20260829v2-Enhancements.md](Docs/Plans/NoteBytez20260829v2-Enhancements.md) Workstream C.

## Model Conventions

All SwiftData models follow this shape, in this field order:

1. Domain fields (feature-specific)
2. Audit fields — always last, always in this order:
   - `createdOn: Date?`
   - `createdBy: String?`
   - `updatedOn: Date?`
   - `updatedBy: String?`
3. `isActive: Bool? = true`

### Identity

Every model declares `{modelName}Id: UUID?` and conforms `id` to it:

```swift
@Model
final class Document: Codable, Identifiable {

    var title: String?
    var content: String?

    var createdOn: Date?
    var createdBy: String?
    var updatedOn: Date?
    var updatedBy: String?

    var isActive: Bool? = true

    var documentId: UUID? = UUID()
    var id: UUID { return self.documentId! }

}
```

### Codable conformance

`@Model` does not synthesize `Encodable`/`Decodable` — every model must implement
`CodingKeys`, `init(from:)` (as a `convenience init` calling the model's own designated
`init`), and `encode(to:)` by hand, covering every stored property. See
[Library.swift](models/Library.swift) for the reference shape.

### Parent references (no `@Relationship`)

A child model (e.g. `Document.libraryId`, `Block.documentId`) stores its parent's `{model}Id`
as a plain `UUID?` field, not a SwiftData `@Relationship`. The DAL fetches by matching this ID
directly (`#Predicate<Child> { $0.parentId == parentId }`). This keeps the CloudKit
parent-reference story (see below) simple and explicit, and avoids `@Relationship`
inverse/delete-rule questions this project hasn't needed to answer. Follow this same pattern
for future parent/child models (Tag, Link, Task, etc.).

Note: when comparing a model's optional `{model}Id` field against a captured value inside
`#Predicate`, unwrap the captured value to non-optional first (`guard let id = ... else {
continue }`) — comparing two Optionals directly in a `#Predicate` can silently fail to match
at runtime. See [BackupDAL.swift](dal/BackupDAL.swift)'s `restore` for where this was caught.

### CloudKit constraints (drive the above)

- All model properties must be optional (CloudKit requirement) — including audit fields and
  `isActive`, despite them conceptually always having a value.
- `@Attribute(.unique)` is not allowed. Uniqueness (e.g. tag canonicalization) is enforced at
  the app/DAL level, not the schema level.
- One custom `CKRecordZone` per library; default zone unused. Root `Library` record per zone;
  Document/Block/Tag/Link/Task records parent to it via `CKReference`.
- Record IDs reuse the model's `{model}Id` UUID as `CKRecord.ID.recordName` — no separate
  identity mapping table.

### Soft delete

- No physical deletes, anywhere. "Delete" means setting `isActive = false` via the DAL.
- All forms, lists, and reports must filter `isActive == true` (or treat `nil` as inactive,
  since CloudKit optionality means the field can be missing on old records).
- `createdBy` / `updatedBy` are currently unpopulated (MVP is single-user, no auth) — the
  fields exist now so V1 multi-user attribution doesn't require a schema migration.

### Local-only data (not everything is a SwiftData model)

Some state must never sync via CloudKit — e.g. backup snapshots (`BackupSnapshot`), which
exist specifically to roll back a device's local data and would be meaningless (or actively
harmful) replicated across devices. These are plain `Codable` structs, not `@Model` classes,
stored as local files (see [BackupDAL.swift](dal/BackupDAL.swift)) rather than through
`ModelContext`. The `{model}Id`/audit-field/`isActive` conventions above apply to SwiftData
models; local-only types are exempt since they aren't part of the CloudKit schema.

A DAL method that returns a value derived from live `@Model` objects (e.g. a snapshot) must
return a detached copy, not a reference into the live `ModelContext` — otherwise later
mutations (including soft-deletes) silently leak into what's supposed to be a frozen
point-in-time capture. `BackupDAL.createSnapshot` does this by encoding then immediately
re-decoding before returning.

## Naming Conventions

(Full detail in `CLAUDE.md`.)

- Types (classes/enums/models): `UpperCamelCase`
- Functions/methods/parameters/variables: `lowerCamelCase`
- Collections: plural names
- Booleans: prefixed `is`/`has`/`can`/`should`
- No single-letter variable names, no global variables

## Legacy Identifiers

The product was renamed **Kontinuum → NoteBytez** pre-launch
([NoteBytez.md](Docs/Plans/NoteBytez.md)). What users and plugin authors see reads
**NoteBytez**: on-screen text, the built app (`NoteBytez.app` — `PRODUCT_NAME`,
`CFBundleName`, `CFBundleExecutable`, `CFBundleDisplayName`, so the macOS app menu too),
documentation, and the plugin SDK's `noteBytez.*` global.

The following identifiers **intentionally keep the `Kontinuum` name** — they are invisible to
users, and changing them would mean a new App Store record, a CloudKit data migration, or
churn across the whole codebase for no user benefit. Do not "fix" these:

- **Xcode project / targets / scheme / source directory**: `Kontinuum.xcodeproj`,
  `Kontinuum.xcscheme` (its `BlueprintName`), targets `Kontinuum` / `KontinuumTests` /
  `KontinuumUITests`, the `Kontinuum/` source folder, `KontinuumApp.swift` (and the
  `KontinuumApp` type).
- **Swift module name**: `import Kontinuum` / `@testable import Kontinuum`. Held explicitly by
  `PRODUCT_MODULE_NAME = Kontinuum` on the app target (so the `NoteBytez` `PRODUCT_NAME` does
  **not** drag the module name with it).
- **Bundle identifier**: `com.g9Consulting.Kontinuum` (and `…KontinuumTests` / `…KontinuumUITests`).
- **CloudKit container**: `iCloud.com.g9Consulting.Kontinuum`, plus the subscription IDs
  `kontinuum-private-changes` / `kontinuum-shared-changes`.
- **Entitlements files**: `Kontinuum.entitlements`, `Kontinuum-macOS.entitlements`.
- **Test plans**: `KontinuumCIGate.xctestplan`, `KontinuumSecurity.xctestplan`.
- **`Notification.Name` raw values** (`kontinuumNewNote`, `kontinuumNavigate`, …),
  `DispatchQueue` labels, and the `Logger` subsystem fallback string.
- **The `//  Kontinuum` second line** in every `.swift` file header.

`Scripts/verify-rename.sh` enforces this split.

## Testing

- Test-driven: reproduce with a test before fixing; a bug isn't fixed until its test passes.
- Unit tests per DAL (CRUD + soft-delete filtering) and per ViewModel.
- Integration tests for cross-feature flows (e.g. Markdown import → parse → save).
- Target: 100% coverage (`CLAUDE.md` §7).

## Template Packs

Bundled, curated `TemplateGroup` + `NoteTemplate` sets for knowledge-management roles, shipped
as an app resource (`Kontinuum/Resources/TemplatePacks.json`, authored via
`Scripts/generate_template_packs.py`) and materialized into a library as ordinary editable rows
by `TemplatePackDAL`. See [Docs/Templates/README.md](Docs/Templates/README.md) and
[NoteBytez20260824v1-Templates.md](Docs/Plans/NoteBytez20260824v1-Templates.md).

- `NoteTemplate.bodyTemplate: String?` — optional Markdown scaffold (headings, prompts, `- [ ]`
  checklists) woven into a new document's body at creation. Additive, CloudKit-safe. Never
  injected by `applyRetroactively` (fields-only).
- `TemplateGroup.sourcePackId: String?` / `sourcePackVersion: Int?` — set when a group was
  materialized from a pack; drive the gallery's non-destructive "Update available".
- English-only for now. When multi-language support resumes
  ([NoteBytez20260823v2](Docs/Plans/NoteBytez20260823v2-MultiLanguage.md)), the pack resource's
  literal strings become String Catalog keys resolved at add-time.

## Security

- Local encryption at rest: platform-native Data Protection only — no custom crypto layer.
- Synced data: CloudKit's server-side encryption.
- All network traffic uses secure protocols (CloudKit handles this by default).

## Copyright

Every generated `.swift` file (except Swift standard control files like `Package.swift`) carries:

```swift
// © Copyright, 2026 David L. Collison, All Rights Reserved.
```

## Related Docs

- [NoteBytez-ReleaseFeatures.md](Docs/Plans/NoteBytez-ReleaseFeatures.md) — MVP/V1/Advanced scope, Decisions Log
- [NoteBytez-MVP-ImplementationPlan.md](Docs/Plans/NoteBytez-MVP-ImplementationPlan.md) — phased build checklist
- [NoteBytez-MacImplementation.md](Docs/Plans/NoteBytez-MacImplementation.md) — native macOS destination build-out plan
- [UIUX/06-DesignSystem.md](Docs/Plans/UIUX/06-DesignSystem.md) — source for `docs/styleGuide.md` (not yet promoted)
- This repo's `CLAUDE.md` — coding standards, enforced on every change
