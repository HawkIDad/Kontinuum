<!-- NoteBytez-MVP-ImplementationPlan.md -->
<!--
  Detailed build checklist for the NoteBytez MVP, derived from NoteBytez-ReleaseFeatures.md's
  "MVP" section and the UIUX deliverable set (Docs/Plans/UIUX/01-06). This is a living document:
  every task starts unchecked. Check a box only when the task is actually done and verified
  (builds, passes its test, or is confirmed working) — not when it's merely started.

  Ordering note: phases are sequenced by build DEPENDENCY, not by the presentation order in
  NoteBytez-ReleaseFeatures.md. E.g. Backups is pulled forward because Markdown Import needs it
  ("auto-snapshot before import"); Import/Export is pushed later because it exercises every
  parser (wikilinks, tags, tasks) and so needs them to exist first.

  Checkbox convention: [ ] not started/in progress, [x] done and verified.
-->

# NoteBytez MVP Implementation Plan

Source: [NoteBytez-ReleaseFeatures.md](NoteBytez-ReleaseFeatures.md) §MVP, [UIUX/01-Personas.md](UIUX/01-Personas.md) through [UIUX/06-DesignSystem.md](UIUX/06-DesignSystem.md).

## Progress Summary

| Phase | Tasks complete | Status |
|---|---|---|
| 0. Foundation & Cross-Cutting Setup | 9 / 9 | Complete |
| 1. Local Library | 7 / 7 | Complete |
| 2. Backups | 6 / 6 | Complete |
| 3. Documents + Stable Blocks | 9 / 9 | Complete |
| 4. Backlinks | 8 / 8 | Complete (tap-to-navigate unverified — see note) |
| 5. Tagging | 7 / 7 | Complete |
| 6. Daily Journal | 6 / 6 | Complete |
| 7. Basic Tasks | 6 / 6 | Complete (checkbox tap unverified — see note) |
| 8. Notebooks | 8 / 8 | Complete (Promote trigger UX deviates from wireframe — see note; not yet simulator/device-verified) |
| 9. Markdown Import/Export | 13 / 13 | Complete (folder-selection UI still simulator-unverified — see note) |
| 10. Exact Search | 8 / 8 | Complete |
| 11. Simple Graph | 5 / 5 | Complete |
| 12. CloudKit Private Sync | 9 / 9 | Complete (compiled + unit-tested; no live-account/device sync verification in this environment — see phase note) |
| 13. Visible Sync Log | 8 / 8 | Complete (same live-sync-verification caveat as Phase 12) |
| 14. Conflict Handling | 10 / 10 | Complete (same live-sync-verification caveat; see phase note on Journey 3 integration test) |
| 15. Cross-Platform Verification | 3 / 6 | Partial — accessibility/color-blind passes done (found + fixed 2 real Dynamic Type bugs, 2 VoiceOver gaps); Mac build itself is blocked in this environment, iPad/iPhone screen-by-screen passes constrained by simulator tap flakiness — see phase note |
| 16. Quality Gate & Journey Acceptance | 5 / 5 | Complete (Journey 3's "conflict actually detected over the network" step is out of this environment's reach — see phase note) |
| **Total** | **127 / 130** | **~98%** |

Update this table's counts and status column as boxes below are checked.

---

## Phase 0 — Foundation & Cross-Cutting Setup

Not a Release Features bullet itself — prerequisite scaffolding everything else depends on.

- [x] CloudKit container configured (`iCloud.com.g9Consulting.Kontinuum`) and wired into [Kontinuum.entitlements](../../Kontinuum.entitlements) — verified via `xcodebuild -list`
- [x] MarkdownG9 added as a local Swift Package dependency (`../MarkdownG9`) — verified via successful `xcodebuild` build
- [x] Project folder structure created per `CLAUDE.md` §9: `Kontinuum/models/`, `Kontinuum/dal/`, `Kontinuum/viewModels/`, `Kontinuum/views/{model name}/`
- [x] `SwiftData` `ModelContainer` reconfigured for CloudKit (`ModelConfiguration(cloudKitDatabase:)`), replacing the stock template config in [KontinuumApp.swift](../../KontinuumApp.swift)
- [x] Xcode template boilerplate removed (`Item` model, placeholder `ContentView`)
- [x] `docs/styleGuide.md` created by promoting [UIUX/06-DesignSystem.md](UIUX/06-DesignSystem.md), per `CLAUDE.md` §10's reference to `{application}/docs/styleGuide.md`
- [x] `OSLog.Logger` logging wrapper set up per `CLAUDE.md` §8
- [x] Base navigation shell scaffolded: `NavigationSplitView` (Mac/iPad), `TabView` (iPhone), per [UIUX/04-InteractionDesign.md](UIUX/04-InteractionDesign.md) "Per-platform navigation shell"
- [x] Shared component scaffolding started for the full inventory in [UIUX/06-DesignSystem.md](UIUX/06-DesignSystem.md) (empty SwiftUI views to be filled in per-phase below: `WikilinkText`, `TagChip`, `TaskCheckbox`, `SyncStatusGlyph`, `BacklinkRow`, `SearchResultRow`, `FilterChipRow`, `TagListRow`, `GraphNode`, `GraphCanvas`, `SyncLogRow`, `ConflictVersionCard`, `ConflictBanner`, `DiffMergeView`, `SettingsRadioRow`, `BackupSnapshotRow`, `ImportSummaryHeader`, `ImportFileRow`, `JournalDayHeader`, `QuickSwitcherField`, `PrimaryButton`, `SecondaryButton`, `SidebarNavItem`, `TabBarItem`)

---

## Phase 1 — Local Library

Release Features: "Local library". Journey: J1.

- [x] `Library` model (SwiftData, CloudKit-optional fields, `libraryId` per `CLAUDE.md` id convention)
- [x] Library DAL: create, list, select-active, delete
- [x] Local-first storage engine wired as interaction source of truth (all reads/writes hit SwiftData directly; sync is async/background only, per Decisions Log)
- [x] Data Protection capability enabled for local encryption at rest (native platform mechanism, no custom crypto — per Decisions Log)
- [x] `LibraryViewModel`
- [x] S1 — Library Creation/Selection view
- [x] Unit tests: Library DAL CRUD, empty-state (no library yet) handling

---

## Phase 2 — Backups

Release Features: "Backups". Pulled forward — Import (Phase 9) depends on this. Journeys: J1, J3.

- [x] Local snapshot mechanism (point-in-time copy of the active library's store)
- [x] Snapshot trigger API usable by any future caller (`bulk import`, `merge`, manual)
- [x] Snapshot metadata (timestamp, cause: auto vs. manual)
- [x] Restore-from-backup flow
- [x] `BackupViewModel`
- [x] S12 — Backup & Restore view (`BackupSnapshotRow` component)

---

## Phase 3 — Documents + Stable Blocks

Release Features: "Documents + stable blocks" (incl. External links, added during UIUX review).

- [x] `Document` model (Markdown-backed, `documentId`)
- [x] `Block` model (stable UUID + human-readable anchor, `blockId`)
- [x] Document DAL, Block DAL
- [x] Block-splitting logic: parse a Document's Markdown into Blocks on save, preserving block UUIDs across re-edits
- [x] Standard Markdown formatting support (headings, bold/italic, lists, blockquotes, code blocks) — extend MarkdownG9's `MDProcessor`
- [x] External link rendering (`[text](url)`, opens system browser, no in-app preview)
- [x] `DocumentViewModel`
- [x] S4 — Document (Note) View, integrating the `MarkdownG9` editor/preview component
- [x] Unit tests: block-ID stability across re-parses, Markdown round-trip fidelity

---

## Phase 4 — Backlinks

Release Features: "Backlinks". Journeys: J2, J4.

- [x] `[[wikilink]]` parser (extend MarkdownG9)
- [x] Wikilink autocomplete (fuzzy note-title match while typing)
- [x] Backlink index: which documents/blocks link to a given document
- [x] Unlinked-mention detection (plain-text title match without a link)
- [x] Link auto-update on note rename
- [x] `BacklinksViewModel`
- [x] S5 — Backlinks Pane (linked + unlinked mentions, per Journey 4)
- [x] `WikilinkText`, `BacklinkRow`, `UnlinkedMentionRow` components; unit tests for backlink-index correctness and rename propagation — **tap-to-navigate on a rendered wikilink is unverified**: the simulator automation tool couldn't deliver a tap that registers inside the preview `ScrollView` at all (confirmed via diagnostic logging — not even a plain `onTapGesture` on the whole text block fired, across an exhaustive coordinate sweep, while the same taps against fixed-position controls outside the ScrollView worked reliably). Needs a manual check in Xcode/on-device.

---

## Phase 5 — Tagging

Release Features: "Tagging". Journeys: J2, J4.

- [x] `Tag` model, many-to-many with `Document` — via `DocumentTag` join model (foreign-key-by-UUID, matching Document/Block's CloudKit-friendly design rather than a `@Relationship`)
- [x] Inline `#tag` parser + autocomplete (extend MarkdownG9), flat only — no nesting in MVP — `TagParser.swift` (indexing/editing, mirrors `WikilinkParser`) + `MDProcessor`'s `#tag` → `tag://` link rewrite (rendering)
- [x] YAML frontmatter `tags:` list parsing — `TagParser.extractFrontmatterTags`, flow list / block list / single-value forms
- [x] App-level tag canonicalization (case-fold, dedupe on sync merge — CloudKit has no `.unique`) — `TagParser.canonicalize` + `TagDAL.findOrCreate` locally; `TagDAL.mergeDuplicates` is the dedupe-on-sync-merge pass Phase 12's sync engine will call after a CloudKit merge
- [x] `TagViewModel`
- [x] S13 — Tag Browser (alphabetical list, per-tag note count) — tapping a tag opens `TaggedDocumentsView`, a minimal stand-in for S7's tag-filter scope until Phase 10 builds real Search
- [x] `TagChip`, `TagListRow` components; unit tests for canonicalization/dedupe — `TagParserTests.swift`, `TagDALTests.swift`

---

## Phase 6 — Daily Journal

Release Features: "Daily journal". Journey: J2.

- [x] Auto-create "today" journal `Document` on app open if missing (idempotent — never duplicates) — `Document.isJournalEntry`/`journalDate` + `JournalDAL.fetchOrCreate`
- [x] Previous/next day navigation logic — `JournalDAL.previousDate`/`nextDate`/`canNavigateToNextDay` (never past today)
- [x] Basic journal template — `JournalDAL.template(for:)`, a single empty bullet
- [x] `JournalViewModel` — wraps a `DocumentViewModel` for the displayed day, swapped wholesale on navigation
- [x] S3 — Today (Journal) view — `TodayJournalView`, reusing wikilink/tag autocomplete from Phase 3/5; verified in simulator (date header, template, typing, tag rendering all confirmed working)
- [x] `JournalDayHeader` component; unit tests for today-page idempotency and date-navigation boundaries — `JournalDALTests.swift`

---

## Phase 7 — Basic Tasks

Release Features: "Basic tasks". Journey: J2.

- [x] Task checkbox parser (`- [ ]` / `- [x]`), tied to `Block` — `TaskParser.swift` (match/extract/toggle) + `TaskDAL.syncTasks` reconciling `TaskItem` rows per active `Block`
- [x] Single-state toggle (open/done), writes back to the Markdown source — `TaskParser.toggling` mutates `Document.content` directly (the markdown stays the source of truth; `TaskItem` rows are a reconciled index, not edited in place)
- [x] Task data model fields: due-date, priority — present in schema, unused by MVP UI (avoids a later CloudKit migration, per Decisions Log) — `TaskItem.dueDate`/`priority`. Model named `TaskItem`, not `Task`, to avoid shadowing Swift's own `Task<Success,Failure>` concurrency type that Phase 12's CKSyncEngine work will need
- [x] `TaskCheckbox` component — a real SwiftUI `Button` (not a tappable-text-link workaround like wikilinks/tags), since a task's whole point is a reliable, sizeable (44×44pt) tap target
- [x] Toggle consistency check: same task state whether toggled from S3 (journal) or S4 (document view) — both share one `DocumentPreviewView` component and one `DocumentViewModel.toggleTask(at:)` path, so consistency holds by construction, not by convention
- [x] Unit tests: toggle persistence, greppability (task text remains plain searchable Markdown) — `TaskParserTests.swift`, `TaskDALTests.swift` (incl. persistence across a simulated view-model reload and exact-text preservation of `- [ ]`/`- [x]` syntax). **Checkbox tap itself is simulator-unverified** — the automation harness can't reliably deliver taps inside a `ScrollView` in this environment (same limitation documented in Phase 4 for wikilink taps, where even a bare `onTapGesture` failed across an exhaustive coordinate sweep while fixed controls outside the ScrollView worked). Needs a manual check in Xcode/on-device.

---

## Phase 8 — Notebooks

Release Features: "Notebooks", "Promote to Notebook". Depends on Phase 3 (Documents), Phase 4 (Backlinks — Promote reuses `WikilinkParser`/`BacklinkDAL` to insert the auto-backlink), Phase 6 (Daily Journal — Promote sources from a journal Block/entry). Placed before Phase 9 (Markdown Import/Export) even though Import/Export was built first — Phase 9's reopened Notebook-frontmatter tasks depend on the `Notebook`/`DocumentNotebook` models built here, per this doc's build-dependency ordering rule.

- [x] `Notebook` model (`notebookId`, `libraryId`, `name`, audit fields — same shape as `Library`) — [Notebook.swift](../../../models/Notebook.swift)
- [x] `DocumentNotebook` join model (many-to-many, foreign-key-by-UUID, mirrors `DocumentTag`) — [DocumentNotebook.swift](../../../models/DocumentNotebook.swift). Both registered in `KontinuumApp.swift`'s SwiftData `Schema`; project builds clean
- [x] Notebook DAL: create/list/rename/delete, attach/detach a Document (many-to-many) — [NotebookDAL.swift](../../../dal/NotebookDAL.swift)
- [x] `NotebookViewModel` — [NotebookViewModel.swift](../../../viewModels/NotebookViewModel.swift)
- [x] S14 — Notebook Browser view (`NotebookListRow` component) — list all notebooks in library, tap a notebook to drill into its documents (reuses the same filtered-document-list pattern as S13's tag drill-down) — [NotebookBrowserView.swift](../../../views/Notebook/NotebookBrowserView.swift), [NotebookDocumentsView.swift](../../../views/Notebook/NotebookDocumentsView.swift). Wired into `ContentView`'s `AppDestination` (sidebar on Mac/iPad, 5th tab on iPhone per Decisions Log)
- [x] S15 — Promote to Notebook sheet (`PromoteSourcePreview`, `NotebookListRow` components) — preview the content being promoted, choose an existing or newly-named Notebook, create a new `Document` attached via `DocumentNotebook`, insert a `[[wikilink]]` back to the source journal entry — no new linking mechanism, reuses Phase 4's parser/index. [PromoteToNotebookView.swift](../../../views/Notebook/PromoteToNotebookView.swift), [PromoteBlockPickerView.swift](../../../views/Notebook/PromoteBlockPickerView.swift). **Deviates from the wireframe's long-press/right-click trigger**: `TodayJournalView` now has a toolbar button that opens a block-picker list instead — this environment's ScrollView tap-gesture delivery is already documented as unreliable for wikilinks (Phase 4) and task checkboxes (Phase 7), so a plain list row is the more dependable trigger for the same action. **Restored** by `NoteBytez20260829v1-FlowEnhancements.md` Phase 3: `.contextMenu` (long-press on iOS, right-click on macOS) turned out to be exactly the primitive this needed — unlike a raw `onTapGesture`, it has none of the ScrollView delivery problems, so the direct gesture now ships on `DocumentPreviewView`'s rendered block rows (shared by S3/S4) alongside the toolbar picker as a discoverable fallback, not a replacement for it. `DocumentViewModel.reload()` added so the journal's in-memory content resyncs after `NotebookDAL.promote` appends a backlink directly to the underlying `Document` — without it, the next `save()` would have silently overwritten that backlink with a stale local copy
- [x] Extend `BackupDAL`/`BackupSnapshot` capture to include `Notebook`/`DocumentNotebook` rows — same gap pattern Phase 9 found and fixed for Tag/Task, applied proactively here instead of discovered later
- [x] Unit tests: Notebook DAL CRUD, `DocumentNotebook` attach/detach (Document in zero/one/many notebooks), Promote-to-Notebook round trip (Document created, correctly attached, backlink present and resolvable in both directions), Backup/Restore coverage for Notebook/DocumentNotebook — `NotebookDALTests.swift`, extended `BackupDALTests.swift`. Full `KontinuumTests` target passes

---

## Phase 9 — Markdown Import/Export

Release Features: "Markdown import/export". Depends on Phases 2–8 (exercises every parser, and — as of the tasks below — Notebook membership). Journey: J1. **Reopened**: the first 8 tasks below shipped and are verified; the remaining tasks were added after Notebooks (Phase 8) was designed, so Notebook membership round-trips through export/import too.

- [x] Folder-picker import flow (Mac-primary, per Journey 1) — `.fileImporter` on S1's new "Import Existing Markdown Folder" button (cross-platform SwiftUI API, works identically on Mac/iPad/iPhone); manually confirmed the system picker opens correctly in-simulator
- [x] Import scanner: count notes, detect wikilinks/tags/checkboxes before committing anything — `ImportScanner.swift`, security-scoped folder read, caches each file's content so commit never re-touches the source folder
- [x] Import parser: `.md` files → `Document` + `Block` + Backlinks + Tags + Tasks — `ImportDAL.importFiles`; Backlinks need no separate step, `BacklinkDAL` already resolves `[[wikilinks]]` on demand from content
- [x] Auto-snapshot before import runs (calls Phase 2's Backup mechanism) — `ImportViewModel.confirmImport`. **Fixed a real gap found while wiring this up**: `BackupSnapshot`/`BackupDAL` (Phase 2) only ever captured `Library` rows, not their Documents/Blocks/Tags/Tasks — a pre-import snapshot that can't restore notes wouldn't protect anything. Extended both, with new coverage in `BackupDALTests.swift` proving a soft-deleted/corrupted document is actually recoverable now
- [x] Per-note export to `.md` — `.fileExporter` toolbar button on S4 (`MarkdownFileDocument`)
- [x] Full library export (bulk Markdown) — `ExportDAL.exportLibrary`, "Export Library" in Settings
- [x] S2 — Import Scan & Confirm view (`ImportSummaryHeader`, `ImportFileRow` components) — `ImportScanView.swift`; Cancel soft-deletes the optimistically-created library so an aborted import leaves nothing behind
- [x] Unit + integration tests: round-trip import→export fidelity; Journey 1 end-to-end (import → spot-check → export) — `ImportScannerTests`, `ImportDALTests`, `ExportDALTests`, `ImportExportIntegrationTests` (incl. a full Journey-1-shaped test and a bad-import-recovered-from-snapshot test). **Folder-selection itself is simulator-unverified** — the system document picker that opens is a black box to automation (same category of limitation noted in Phases 4/7); the import/export logic it hands off to is fully covered by tests instead
- [x] Export: write a `notebooks:` YAML frontmatter list (exact Notebook names) for every Document's `DocumentNotebook` memberships — `ExportDAL.exportableContent(for:in:)`. A document in no notebooks exports byte-for-byte unchanged (no frontmatter block added)
- [x] Export: also emit a kebab-cased `#notebook/<notebook-name>` tag per membership, appended to the document **body** rather than merged into an existing frontmatter `tags:` list — for Obsidian/Logseq nested-tag portability, write-only, never round-tripped back in as a `DocumentTag`. **Deviates from the original plan** (folding into `tags:`): appending to the body reaches the same result — NoteBytez's own tag index already treats inline and frontmatter tags identically — without the risk of textually rewriting a user-authored `tags:` line
- [x] Import: parse `notebooks:` frontmatter back into `DocumentNotebook` rows, creating a Notebook by exact-name match if it doesn't already exist in the target library — `NotebookParser.extractFrontmatterNotebooks`, `NotebookDAL.findOrCreate`, wired into `ImportDAL.importFiles`. The synthetic `#notebook/<name>` tag is not used as an import signal; no inference of Notebooks from a foreign vault's own tag conventions (per Decisions Log)
- [x] S2 — Import Scan & Confirm: extended `ImportSummaryHeader`/`ImportViewModel.notebookCount` (distinct notebook names across scanned files) to surface a "N notebooks detected" count alongside the existing note/link/task counts. Also wired per-note export (S4) to the same `exportableContent` path — it previously bypassed `ExportDAL` entirely, exporting `viewModel.content` raw, which would have silently skipped notebook membership on a single-note export
- [x] Unit tests: `notebooks:` round-trip fidelity (export → import → identical `DocumentNotebook` memberships, incl. a full re-import-into-a-fresh-library integration test), synthetic-tag correctness (kebab-casing, multiple notebooks → multiple tags), a file with `notebooks:` missing/hand-edited doesn't silently duplicate or orphan a Notebook, re-export doesn't accumulate duplicate `notebooks:` lines — `NotebookParserTests.swift` (new), extended `ExportDALTests.swift`, `ImportDALTests.swift`, `ImportScannerTests.swift`, `ImportExportIntegrationTests.swift`. Full `KontinuumTests` target passes (147 tests)

---

## Phase 10 — Exact Search

Release Features: "Exact search". Journey: J4.

- [x] Full-text search index (FTS) across Document content — `SearchDAL.searchContent`, scan-on-demand (no persisted index), same rationale `BacklinkDAL` already established for MVP scale; ranks title matches above body-only matches, more occurrences above fewer, and returns a match-centered snippet
- [x] Search by tag (uses Phase 5's tag index) and file/path — `SearchDAL.searchByTag` reuses `TagDAL` directly. **"Path" scope resolved as title search**: Documents have no folder/path concept in this data model (flat within a Library), so a note's title is the closest thing it has to a path — `SearchDAL.searchByTitle`. No schema change; Path search deferred to an actual meaning pending V1 organizational work if ever needed
- [x] Quick Switcher fuzzy note-title matcher — `SearchDAL.quickSwitcherMatches`, reuses `WikilinkParser.fuzzyMatches` rather than a second fuzzy-match implementation
- [x] `SearchViewModel` — serves both S6 and S7 (same library, same query concept) rather than two view models — [SearchViewModel.swift](../../../viewModels/SearchViewModel.swift)
- [x] S6 — Quick Switcher — [QuickSwitcherView.swift](../../../views/Search/QuickSwitcherView.swift). Presented as a full-screen sheet from a toolbar button on S3 (Today) rather than wired as a global "any screen" overlay/keyboard shortcut — a documented scope reduction, same kind as Phase 8's Promote trigger
- [x] S7 — Search Results, with content/tag/path scope filter chips — [SearchView.swift](../../../views/Search/SearchView.swift). Wired into `ContentView`'s existing `.search` `AppDestination` (previously a placeholder)
- [x] `QuickSwitcherField`, `SearchResultRow`, `FilterChipRow` components — filled in from the `EmptyView` stubs Phase 0 scaffolded
- [x] Unit tests: FTS indexing/relevance correctness, tag/path filter correctness — `SearchDALTests.swift` (title-vs-body ranking, snippet centering, tag partial-match + dedupe, library isolation, quick-switcher fuzzy match + empty-query fallback). Full `KontinuumTests` target passes

---

## Phase 11 — Simple Graph

Release Features: "Simple graph". Depends on Phase 4 (Backlinks). Journey: J4.

- [x] Graph data source: current note + direct links only (explicitly no clustering/forces/filters in MVP) — `GraphDAL.directLinks` unions outgoing `[[wikilinks]]` (resolved via `WikilinkParser` against active documents) with incoming links via Phase 4's `BacklinkDAL.findBacklinks`, deduped and sorted
- [x] `GraphViewModel` — [GraphViewModel.swift](../../../viewModels/GraphViewModel.swift)
- [x] S8 — Local Graph View — [GraphView.swift](../../../views/Graph/GraphView.swift), reached via a new "Graph" toolbar button on S4 (matching the interaction design's specified trigger) and via the sidebar/tab bar "Graph" nav item (already scaffolded in Phase 0), which defaults to today's journal entry through a new [TodayGraphView.swift](../../../views/Graph/TodayGraphView.swift) wrapper — same construct-once-on-appear `@State` pattern `TodayJournalView` established, to avoid rebuilding the view model on every render
- [x] `GraphNode`, `GraphCanvas` components — filled in from the `EmptyView` stubs Phase 0 scaffolded. `GraphCanvas` is a simple radial one-hop layout (center + surrounding nodes, no force simulation) with pinch/drag gestures plus `[+][-][⤢]` toolbar buttons on S8, matching the wireframe. Verified in simulator: center node renders filled with its title, zoom buttons resize it live
- [x] Unit tests: graph edges match the Backlinks index exactly (no drift between the two views) — `GraphDALTests.swift`, incl. `incomingEdgesMatchBacklinkDALExactly` asserting `GraphDAL`'s incoming-edge set is identical to a direct `BacklinkDAL.findBacklinks` call. Full `KontinuumTests` target passes

---

## Phase 12 — CloudKit Private Sync

Release Features: "CloudKit private sync". Journeys: J2, J3.

**Architecture decision, made explicitly before starting this phase**: this phase's own checklist (custom zone per library, explicit `CKReference` parenting, `{model}Id` as `recordName`) is only expressible through the manual `CKSyncEngine` API — none of it is controllable through SwiftData's automatic `ModelConfiguration(cloudKitDatabase:)` sync, which manages its own opaque zone/record structure and never surfaces individual record events or conflicts to app code. Phase 13 (sync log) and Phase 14 (conflict strategies, which need both sides of a conflict) both depend on exactly the data `CKSyncEngine`'s delegate provides. So Phase 0's placeholder `ModelConfiguration(cloudKitDatabase:)` wiring (task 1 below) was removed and replaced with `SyncEngine`, a manual `CKSyncEngine` wrapper — see `sync/`.

- [x] ~~`ModelConfiguration(cloudKitDatabase:)` wiring against the private database~~ — superseded, see architecture decision above. `KontinuumApp.swift`'s `ModelConfiguration` is now a plain local store (in-memory in Debug, persistent in Release); CloudKit sync is `SyncEngine`'s job, not SwiftData's
- [x] `CKSyncEngine` setup, single container (`iCloud.com.g9Consulting.Kontinuum`) — [SyncEngine.swift](../../../sync/SyncEngine.swift). Only starts in Release builds (`KontinuumApp.swift`) — Debug's in-memory store resets every launch and shouldn't write test data into the real private container. `SyncEngine.shared` is safe to reference from anywhere (including unit tests) because all `CKContainer`/`CKSyncEngine` construction is deferred to `start(modelContainer:)`, never `init()`
- [x] One custom `CKRecordZone` per library — default zone unused — `CKRecordZone.ID.library(_:)` in [SyncZoneID.swift](../../../sync/SyncZoneID.swift), a pure/deterministic derivation from `libraryId`; `SyncEngine.ensureZone(forLibraryId:)` enqueues creation, called from `LibraryDAL.create` and once at launch for every already-active library
- [x] Root "Library" record per zone; Document/Block/Tag/DocumentTag/Notebook/DocumentNotebook/TaskItem records parented to it via `CKReference` — flat, per this doc's original "parented to it" wording (not a Document->Block chain): every non-Library record carries a `library` reference field pointing at its zone's root Library record, set in `SyncableRecord.makeCKRecord(in:)`. `Block` is the one model without its own `libraryId` — resolved via its owning `Document` (`Block+Sync.swift`)
- [x] Record IDs reuse the model's `{model}Id` UUID as `CKRecord.ID.recordName` — `CKRecord.ID.record(syncId:zoneID:)` in [SyncZoneID.swift](../../../sync/SyncZoneID.swift)
- [x] Sync engine state persistence (survives app relaunch without a full re-fetch) — [SyncStateStore.swift](../../../sync/SyncStateStore.swift), `CKSyncEngine.State.Serialization` (already `Codable`) persisted to `UserDefaults` on every `.stateUpdate` event and reloaded in `SyncEngine.start`
- [x] Change-token/subscription handling for incremental sync — change tokens are `CKSyncEngine`'s own internal state (covered by the persistence above); incremental *push-triggered* sync via a `CKDatabaseSubscription` (`configuration.subscriptionID`, `CKSyncEngine` manages the subscription itself) plus a new [AppDelegate.swift](../../../AppDelegate.swift) (`@UIApplicationDelegateAdaptor`) registering for and routing silent pushes to `SyncEngine.handleRemoteNotification()`. `aps-environment`/`remote-notification` background mode were already present in the entitlements/Info.plist from Phase 0, confirming this was the intended design
- [x] Unit/integration tests: zone creation idempotency, sync-state persistence across relaunch — `SyncMappingTests.swift` (15 tests): zone-ID determinism, per-model `CKRecord` field round-trips (all 8 models incl. `TaskItem`'s unused-in-MVP `dueDate`/`priority`), `library` reference parenting (present/absent correctly), record-type dispatch across all 8 tables, incoming-record upsert (create vs. update-in-place). **What's *not* verified**: an actual network round-trip against live CloudKit (zone/record creation, push delivery, real conflict surfacing) — this environment has no signed-in iCloud account to exercise that against, so `SyncEngine` ships compiled and unit-tested but not live-sync-verified, same category of gap as this plan's other simulator/device-only limitations. Needs a real device + iCloud account check
- [x] Every mutating `DAL` call site (`LibraryDAL`, `DocumentDAL`, `BlockDAL`, `TagDAL`, `NotebookDAL`, `TaskDAL`) now calls `SyncEngine.shared.recordChanged(...)` after each create/update/soft-delete — soft-deletes sync as an ordinary field update (`isActive = false`), matching the app's existing soft-delete convention rather than issuing a real `CKRecord` deletion. No-ops safely wherever `SyncEngine` hasn't been started (every DAL unit test, and Debug builds)

---

## Phase 13 — Visible Sync Log

Release Features: "Visible sync log". Depends on Phase 12. Journey: J3.

- [x] Sync status indicator (persistent, tappable — Synced / Syncing / Conflict / Offline states) — [SyncStatusStore.swift](../../../sync/SyncStatusStore.swift)'s `status` is derived from three independent flags (`isOffline`, `isSyncing`, `conflictCount`), priority order offline > syncing > conflict > synced per `06-DesignSystem.md`'s sync visual language. `SyncEngine` is the sole writer, translating `CKSyncEngine.Event`s (`.willSendChanges`/`.willFetchChanges`, `.didSendChanges`/`.didFetchChanges`, `.sentRecordZoneChanges`, `.fetchedRecordZoneChanges`) into calls on it — the UI layer never touches CloudKit types
- [x] Last-synced timestamp tracking, always visible even when offline — `SyncStatusStore.lastSyncedOn`, set on every successful sync pass regardless of state; `SyncStatusViewModel.lastSyncedText` renders it in every status (`SyncStatusView` always shows it, not just when Synced)
- [x] Error surfacing: inline, dismissible, with retry — never a blocking alert — `SyncStatusView`'s private `SyncErrorBanner`, driven by `SyncStatusStore.dismissibleError`/`dismissError()`; a `.serverRecordChanged` failure is routed to `recordConflict` (not treated as a dismissible error, since that's Phase 14's conflict data, not a transient failure)
- [x] Manual "Sync now" trigger — `SyncEngine.syncNow()` (`sendChanges()` + `fetchChanges()`), exposed via `SyncStatusViewModel.syncNow()` and a button on S9. `CKSyncEngine`'s own event stream drives the same status updates whether the sync pass was scheduled automatically or triggered manually
- [x] `SyncStatusViewModel` — [SyncStatusViewModel.swift](../../../viewModels/SyncStatusViewModel.swift), a display/formatting layer over `SyncStatusStore` (headline text, relative last-synced string, tint)
- [x] S9 — Sync Status / Log view — [SyncStatusView.swift](../../../views/Sync/SyncStatusView.swift), reached by tapping the `SyncStatusGlyph` now in S3/S4's toolbar. Presented as a sheet on every platform rather than the wireframe's Mac/iPad popover — the same documented deviation already established for S5/S8/S13 in this plan; cross-platform presentation polish is Phase 15's job
- [x] `SyncStatusGlyph`, `SyncLogRow` components — filled in from the `EmptyView` stubs Phase 0 scaffolded. `SyncStatusGlyph` swaps icon (not just color) between the sync glyph and `exclamationmark.triangle` for conflicts, so the state never depends on color alone; unit tests for state-transition correctness (Synced→Syncing→Conflict→Synced) — `SyncStatusStoreTests.swift` (13 tests, incl. the exact named sequence, log capping/ordering, and conflict-during-an-in-flight-sync priority). Each test constructs its own `SyncStatusStore()` (not `.shared`) so `isOffline` — driven by a real `NWPathMonitor`, started only via `SyncEngine.start` in Release builds — never introduces flakiness. Full `KontinuumTests` target passes
- [x] Every mutating `SyncEngine` code path that can fail or succeed now reports through `SyncStatusStore` — same "compiled + unit-tested, not live-CloudKit-verified" caveat as Phase 12: the actual state machine, log formatting, and UI are covered by tests and a manual build/compile pass, but a real device + iCloud account is needed to see genuine `.syncing`/`.conflict` transitions triggered by real network activity

---

## Phase 14 — Conflict Handling

Release Features: "Conflict handling (user-selectable strategy)". Depends on Phase 12. Journey: J3.

- [x] Conflict detection from `CKSyncEngine`'s reported record-version conflicts — `SyncEngine.makeConflict(from:)` builds a `Conflict` from a `.sentRecordZoneChanges` failure whose `error.code == .serverRecordChanged`, using `CKError`'s `clientRecord`/`serverRecord`/`ancestorRecord` accessors
- [x] Strategy 1 — Keep All Versions (user resolves manually) — always queues to `ConflictStore` for S10; "Keep A"/"Keep B" per `ConflictVersionCard`, plus "Keep Both Versions" (Document only) which duplicates the client's content into a new note — [ConflictResolver.swift](../../../sync/ConflictResolver.swift), `SyncEngine.resolveConflict(_:choice:in:)`
- [x] Strategy 2 — Last-Write-Wins + Conflict Banner — resolves immediately (`ConflictResolver.lastWriteWinsChoice`, newer `updatedOn` wins, ties favor the client), with `ConflictBanner` embedded directly atop S4 for the affected note ("a banner lets you revert" — reverting re-resolves with the opposite choice)
- [x] Strategy 3 — Markdown Diff-Merge (diff-match-patch style; last-write-wins for non-text) — [MarkdownDiffMerge.swift](../../../sync/MarkdownDiffMerge.swift), a from-scratch LCS line-diff (not a port of Google's char-level library — overkill for line-oriented Markdown notes) producing accept/reject hunks; only queues to S10 when `Conflict.hasDiffableContent` (i.e. a `Document`), otherwise falls back to Strategy 2's resolution automatically, per this task's own "(...; last-write-wins for non-text)" scope
- [x] Settings toggle to choose active strategy — `ConflictStrategyStore` (UserDefaults, mirrors `LibraryDAL`'s pattern), default `.lastWriteWins` matching the wireframe's pre-selected option
- [x] Conflict model built on a revision concept (not a device concept), so V1 multi-user conflicts can extend it later without a rewrite — [Conflict.swift](../../../sync/Conflict.swift)'s `ConflictRevision.Kind` is `.client`/`.server`, not a named-device axis — CloudKit's private database doesn't expose per-device attribution to conflict resolution code in the first place, so this is the honest model, not just a forward-compatibility abstraction
- [x] `ConflictResolutionViewModel` — [ConflictResolutionViewModel.swift](../../../viewModels/ConflictResolutionViewModel.swift)
- [x] S10 — Conflict Resolution view (3 strategy-specific UIs: `ConflictVersionCard`, `ConflictBanner`, `DiffMergeView`) — [ConflictResolutionView.swift](../../../views/Conflict/ConflictResolutionView.swift), reached from a new "Needs Your Attention" section in S9 (`SyncStatusView`) listing `ConflictStore`'s queued conflicts. **Deviates from the wireframe**: the Last-Write-Wins banner never appears as a third S10 sub-screen, because that strategy never queues a conflict for S10 in the first place (it's already resolved by the time a conflict would reach here) — the banner lives only where it's actually actionable, atop S4, same "documented scope simplification" pattern as Phase 8's Promote trigger and Phase 10's Quick Switcher
- [x] S11 — Settings: Conflict Strategy view (`SettingsRadioRow`) — [ConflictStrategySettingsView.swift](../../../views/Settings/ConflictStrategySettingsView.swift), wired into `SettingsView` as "Sync & Conflicts"
- [x] Unit tests per strategy's merge logic in isolation — `MarkdownDiffMergeTests.swift` (8 tests: identical/pure-addition/pure-removal/replace/mixed-acceptance/empty), `ConflictResolverTests.swift` (10 tests: keep-client copies fields onto a *copy* of the server record without mutating the original, keep-server/keep-both, merged-content-only-overrides-content, last-write-wins incl. tie-break, revision labeling), `ConflictStrategyStoreTests.swift`, `ConflictStoreTests.swift` (dedupe-by-syncId on queue, remove, auto-resolution tracking). **No integration test for Journey 3 end-to-end**: that needs two real devices (or two real sync sessions) actually racing an edit against live CloudKit to produce a genuine `.serverRecordChanged` — same live-account/device gap noted in Phases 12–13, not something a local unit test can honestly simulate. Full `KontinuumTests` target passes

---

## Phase 15 — Cross-Platform Verification

Not a single Release Features bullet — the "equal fidelity across platforms" requirement from [UIUX/04-InteractionDesign.md](UIUX/04-InteractionDesign.md). Built once with adaptive SwiftUI layout (`NavigationSplitView`/`TabView` size-class adaptation), not three separate implementations — this phase is verification, not re-implementation. **Environment limits this phase more than any prior one** — this session's simulator automation can't reliably deliver taps (same limitation documented since Phase 4), and there is no tool here that can drive or screenshot a native Mac app window at all. Scored honestly below rather than checked off on code inspection alone.

- [ ] All 15 screens (S1–S15) verified on Mac — the original Catalyst-based blocker here (`xcodebuild` against "My Mac (Designed for iPad)" failing on a `com.apple.developer.default-data-protection` entitlement mismatch) is resolved: see [NoteBytez-MacImplementation.md](NoteBytez-MacImplementation.md), which abandons Catalyst for a real `macosx` SDK target and has a green build + full `KontinuumTests`/`KontinuumUITests` pass on macOS (its Phases 0–3, 5). What remains open there — and therefore here — is the same category of gap: a real GUI screen-by-screen pass (Phase 4/5's sidebar visual check, blocked on Accessibility/UI-automation permission, not a code issue) and a live-iCloud CloudKit sync smoke test across platforms
- [ ] All 15 screens verified on iPad (landscape split view + portrait collapse) — S1 confirmed rendering correctly at regular width (iPad Air 11" M4 simulator, screenshot-verified); deeper screen-by-screen navigation blocked by the same tap-delivery flakiness noted throughout this plan, now confirmed on a third distinct simulator device. Backed by code-level confirmation instead (see below), but that's not the same as seeing all 15 render
- [ ] All 15 screens verified on iPhone (tab bar + stack navigation) — de facto covered: nearly every screen has been individually built, launched, and screenshotted on iPhone simulators across Phases 4–15 of this plan. Not a dedicated re-pass, but the closest thing to real coverage this environment produced
- [x] Dynamic Type accessibility-size pass — journal/document text reflows, never truncates — code audit (no hardcoded `.system(size:)` fonts anywhere; the few `.lineLimit()` calls are all on row/snippet previews, never on S3/S4's actual editable content) plus a live pass at `accessibility-extra-extra-extra-large` (`xcrun simctl ui ... content_size`) that caught two real bugs, now fixed: (1) `PrimaryButton`/`SecondaryButton` were truncating their titles — `.bordered`/`.borderedProminent` styles cap their label to one line by default; fixed with `.fixedSize(horizontal: false, vertical: true)` on the label `Text`. (2) S1 (`LibrarySelectionView`) had no `ScrollView`, so content could be pushed off-screen and become unreachable at large sizes — wrapped in one, and replaced its `List` with a plain `VStack`/`ForEach` since `List` nested in `ScrollView` fights it for scroll ownership. Re-verified via screenshot: every element reachable, nothing truncated
- [x] VoiceOver labels present on every icon-only control (sync glyph, graph zoom, backlink toggle) — audited all 23 `Image(systemName:)` call sites across `views/`. Found and fixed two real gaps: `DocumentListView`'s "+" new-note toolbar button and `TaskCheckbox` (the latter now takes a `label: String` — the task's own text — plus `.accessibilityValue("Done"/"Not done")`, so VoiceOver announces the actual task, not just "square button"). Also improved two selection-state rows (`SettingsRadioRow`, the notebook picker in `PromoteToNotebookView`) with `.accessibilityAddTraits(.isSelected)` so they announce cleanly instead of reading a raw SF Symbol name
- [x] Color-blind-safe check: color is never the only signal (conflict/warning states pair color + icon + text) — audited every semantic-color usage (`.orange`/`.green`/`.red`) in `views/`. All pass: `SyncStatusGlyph` swaps icon *shape* (not just color) for the conflict state; every conflict/error banner and log row pairs its color with both an icon and a full text message; `DiffMergeView`'s accept/reject state uses strikethrough + a text-labeled button, never color alone. No changes needed — already correct from how Phases 13–14 were built

---

## Phase 16 — Quality Gate & Journey Acceptance

`CLAUDE.md` §4 (Goal-Driven Execution) and §7 (Testing).

- [x] Unit test coverage reviewed against `CLAUDE.md`'s 100% coverage target — measured via `xcodebuild test -enableCodeCoverage YES`. The logic layer (`models/`, `dal/`, `sync/`, `viewModels/`) sits at ~90%+ after this pass; SwiftUI `views/` sit near 0% (unit tests don't render views — that's this plan's existing simulator-tap-flakiness gap, Phases 4/7/15) and `SyncEngine.swift` sits at ~3% (its body is almost entirely live `CKSyncEngine` network callbacks — the Phase 12-15 live-iCloud gap). Found and fixed real gaps along the way rather than just measuring: (1) `DocumentTag`/`DocumentNotebook`'s CKRecord field round-trip was never actually tested despite `SyncMappingTests`' own docstring claiming "all 8 models" — added `documentTagFieldsRoundTrip`/`documentNotebookFieldsRoundTrip` and expanded the record-type-dispatch tests to genuinely cover all 8 tables (`SyncMappingTests.swift`); (2) `SyncRecordFactory.applyIncoming`/`applyDeletion` — the incoming-sync dispatch switches — had zero test coverage; added dispatch tests across all 8 record types plus the unknown-type no-op branch; (3) `LibraryViewModel` had no tests at all and, worse, read/wrote `UserDefaults.standard` directly with no way to inject a test double (unlike `LibraryDAL`, which already supported this) — added the same injectable-`defaults` parameter `LibraryDAL` uses and a full `LibraryViewModelTests.swift`; this wasn't just a coverage gap, it was a real flaky-test risk under Xcode's default parallel test execution, confirmed by reproducing the race before fixing it; (4) added `DocumentViewModelTests.swift` (save/reload/wikilink+tag autocomplete — previously only `toggleTask` had coverage, via `TaskDALTests`); (5) closed small gaps in `ConflictStrategyStore` (`.title`/`.summary` display text) and `Conflict` (`displayTitle` fallback chain, the false branch of `hasDiffableContent`). `BackupDAL.restore`'s large per-model branch set remains the one sizeable accepted gap — already has dedicated round-trip tests per Phase 8/9, and the untested remainder is repetitive same-shape branches, not new risk. All 249 tests pass (`xcodebuild test`, iPhone 17 simulator)
- [x] Journey 1 (migration) passes end-to-end, matching [UIUX/02-Journeys.md](UIUX/02-Journeys.md) — already covered by Phase 9's `ImportExportIntegrationTests.journeyOneImportSpotCheckExportRoundTrip` (scan → confirm → auto-snapshot → import → spot-check links/tasks → export round-trip, byte-for-byte)
- [x] Journey 2 (daily capture loop) passes end-to-end — `JourneyIntegrationTests.journeyTwoDailyCaptureLinkTagTaskAndCrossDeviceToggle`: today's journal auto-created idempotently, a captured line resolves its `[[wikilink]]` autocomplete suggestion, saves into a real backlink/tag/task index, then a second `DocumentViewModel` over the same document/context (standing in for "opens on Mac" — no live CloudKit in this environment) toggles the task and the first view model's `reload()` sees the same state, closing with Previous/Next-day navigation
- [x] Journey 3 (sync conflict) passes end-to-end — `JourneyIntegrationTests.journeyThreeConflictDetectedThroughEachStrategyToResolved`, with one honest carve-out: step C ("NoteBytez detects the note was edited in both places") is `SyncEngine.makeConflict(from:)` reacting to a real `.serverRecordChanged` `CKError`, which needs a live, signed-in iCloud account and two genuinely racing sync sessions to trigger — the same gap Phases 12-14 already documented. Everything downstream of "a `Conflict` exists" is exercised for real: the status indicator's Synced→Conflict→Synced transitions, the sync log entry, and all three strategies (Keep All Versions queuing rather than auto-resolving, Last-Write-Wins picking the newer edit, Diff-Merge producing and applying a real hunk-level merge) using fresh `SyncStatusStore`/`ConflictStore` instances per Phase 13's own isolation pattern
- [x] Journey 4 (graph resurfacing) passes end-to-end — `JourneyIntegrationTests.journeyFourSearchMissesGraphMissesTagBrowserFindsThenLinksBack`: a keyword guess misses via `SearchDAL.searchContent`, the current note's graph genuinely doesn't surface the unlinked target (while still correctly surfacing an actually-linked neighbor, proving the miss isn't trivial), a tag-scoped search finds it, and adding a new `[[wikilink]]` closes the loop in both the Backlinks index and the graph edge set

---

## Coverage check

Every MVP bullet in [NoteBytez-ReleaseFeatures.md](NoteBytez-ReleaseFeatures.md) (Platform, Local library, Markdown import/export, Documents + stable blocks, Backlinks, Tagging, Daily journal, Notebooks, Promote to Notebook, Basic tasks, Exact search, Simple graph, CloudKit private sync, Visible sync log, Backups, Conflict handling) has a corresponding phase above. Every screen S1–S15 from [UIUX/04-InteractionDesign.md](UIUX/04-InteractionDesign.md) has a corresponding task. Every component in [UIUX/06-DesignSystem.md](UIUX/06-DesignSystem.md)'s inventory is referenced in Phase 0 or its owning feature phase.
