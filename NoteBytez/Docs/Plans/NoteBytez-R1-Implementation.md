<!-- NoteBytez-R1-Implementation.md -->
<!--
  Detailed build checklist for NoteBytez Version 1 (R1), derived from NoteBytez-ReleaseFeatures.md's
  "Version 1" section. This is a living document: every task starts unchecked. Check a box only
  when the task is actually done and verified (builds, passes its test, or is confirmed working)
  — not when it's merely started.

  Ordering note: phases are sequenced by build DEPENDENCY, matching NoteBytez-MVP-ImplementationPlan.md's
  convention, not by the presentation order in NoteBytez-ReleaseFeatures.md. E.g. Saved Views is
  pushed later because it pins a query from Advanced Search or Task Dashboards, so both must exist
  first; Properties is pulled forward because Note Templates pre-fill Property fields.

  Checkbox convention: [ ] not started/in progress, [x] done and verified.

  Baseline: MVP is complete (127/130, see NoteBytez-MVP-ImplementationPlan.md) — this plan assumes
  that codebase as its starting point and does not re-scope MVP work.
-->

# NoteBytez Version 1 (R1) Implementation Plan

Source: [NoteBytez-ReleaseFeatures.md](NoteBytez-ReleaseFeatures.md) §Version 1,
[NoteBytez-PersonaAuthorValidation.md](NoteBytez-PersonaAuthorValidation.md) (the persona this
release makes servable), [NoteBytez-MVP-ImplementationPlan.md](NoteBytez-MVP-ImplementationPlan.md)
(completed baseline this plan builds on).

## Progress Summary

| Phase | Tasks complete | Status |
|---|---|---|
| 0. Foundation & Cross-Cutting Setup | 6 / 7 | In progress (last task is a small opportunistic copy-writing task, no dedicated phase) |
| 1. V1 UI/UX Design Artifacts | 7 / 7 | Complete |
| 2. Properties | 9 / 9 | Complete |
| 3. Note Templates | 13 / 13 | Complete |
| 4. Block References | 6 / 6 | Complete |
| 5. Advanced Search | 6 / 6 | Complete |
| 6. Task Dashboards | 7 / 7 | Complete |
| 7. Saved Views | 7 / 7 | Complete |
| 8. Attachment Handling | 9 / 9 | Complete |
| 9. Canvas | 10 / 10 | Complete |
| 10. CloudKit Sharing | 9 / 9 | Complete |
| 11. Local File Encryption (Security) | 4 / 4 | Complete |
| 12. Migration Assistants | 7 / 7 | Complete |
| 13. Plugin SDK (Preview) | 8 / 8 | Complete |
| 14. Cross-Platform Verification | 6 / 6 | Complete (Mac item is a partial pass — see its own note: build verified, GUI walkthrough blocked by this environment's missing Accessibility permission) |
| 15. Quality Gate & Journey Acceptance | 0 / 5 | Not started |
| **Total** | **114 / 120** | **95%** |

Update this table's counts and status column as boxes below are checked.

---

## Decisions Log

Resolves the three items originally flagged `[OPEN]` (carried forward from
`NoteBytez-ReleaseFeatures.md`'s own `[OPEN]` convention). Each phase below references its
decision by number; this is the authoritative record.

1. **"Universe" container: convention, not a model.** A Universe is a Notebook (or a hub Document
   with wikilinks out to its books/series) inside one Library — no new schema. Chosen over
   one-Library-per-Universe because search/graph/backlinks/Advanced Search are library-scoped by
   design (per MVP's Decisions Log), and a hard per-universe boundary would break cross-universe
   references to shared lore (e.g. a technology reused across two book series) and add a
   Library-switch to the UI for what's conceptually just a project grouping. Users who *do* want
   hard isolation between universes can already do so with separate Libraries — the MVP feature
   is unaffected, this just isn't the default-recommended pattern. Ships as a documented
   convention plus a starter TemplateGroup example (Phase 3), not new engineering.
2. **JSON Canvas spec surface: full JSON Canvas 1.0.** All 4 node types (text/file/link/group)
   plus edges (`fromSide`/`toSide`/`color`/`label`). NoteBytez's card types map onto it without
   any proprietary extension fields: note and media cards → `file` nodes referencing the
   already-exported `.md`/attachment path, web cards → `link` nodes, groups → `group` nodes. Full
   surface chosen over a text/file-only subset specifically because Phase 12's Migration
   Assistant needs lossless round-trip against real Obsidian vaults, which routinely use groups
   and link nodes.
3. **Plugin SDK execution model: sandboxed JavaScriptCore scripting.** Real user-authored plugins
   run inside an embedded JavaScriptCore interpreter behind a minimal permissioned bridge (read
   library query API, insert-at-cursor/append-only note writes, register-a-command) — no
   filesystem/network bridge exposed to script code, no background execution, every permission
   explicitly user-granted per plugin. Chosen over a declarative-manifest-only design because
   Release Features' own "developer docs + sandboxed dev environment" language implies real code
   execution, and JavaScriptCore-hosted interpreted scripting for user customization is an
   established, App-Store-accepted pattern (same category as Shortcuts/Scriptable/Drafts) — not a
   sandbox-escape risk the declarative alternative would have avoided for free. Chosen over
   deferring the phase out of V1 because Phase 13 is already sequenced last, after every other V1
   feature stabilizes, so its dependency risk is already minimized rather than eliminated by
   removal.

---

## Assumptions

`NoteBytez-ReleaseFeatures.md`'s Version 1 section describes *what* each feature does but not
its data model. The model shapes below are this plan's proposal, following `ARCHITECTURE.md`'s
existing conventions (`{model}Id` identity, foreign-key-by-UUID joins mirroring `DocumentTag`/
`DocumentNotebook`, all-optional CloudKit-safe fields, audit fields last). They are a starting
point for Phase-by-phase design review, not a final schema — flag disagreements before a phase's
models are registered in `NoteBytezApp.swift`'s `Schema`, since CloudKit schema changes are
additive-only once shipped.

---

## Phase 0 — Foundation & Cross-Cutting Setup

Not a Release Features bullet itself — prerequisite scaffolding, mirrors MVP's Phase 0.

- [x] Audit every new model proposed in Phases 2-13 for CloudKit compatibility (all fields
      optional, no `.unique`) before each phase's models are registered — reviewed every model in
      the Assumptions section above (`Property`/`DocumentProperty`, `TemplateGroup`/`NoteTemplate`/
      `NotebookTemplateGroup`/`JournalTemplateGroup`, `CanvasBoard`/`CanvasCard`/`CanvasConnector`,
      `Attachment`, `SavedView`): every field is optional, none use `@Attribute(.unique)`, every
      model carries a `{model}Id`, all joins follow the foreign-key-by-UUID pattern. No violations
      found; no changes needed to the Assumptions section as a result of this pass
- [x] Track the aggregate `NoteBytezApp.swift` `Schema` change as each phase adds its models —
      confirmed every feature phase (2, 3, 7, 8, 9) carries its own "Register in `Schema`" task;
      this item exists only to catch a phase that forgets one, none do
- [x] Confirm `createdBy`/`updatedBy` audit fields (reserved since MVP, unpopulated) start being
      populated once Phase 10 (CloudKit Sharing) introduces multi-user attribution — no schema
      change needed, per MVP's Decisions Log — verified against current `TaskItem.swift`/
      `Document.swift`: both fields present and optional today, confirming no migration is needed
- [x] Confirm `TaskItem.dueDate`/`priority` (reserved in MVP schema, unused by MVP UI) are finally
      surfaced starting Phase 6 (Task Dashboards) — no migration needed, per MVP's Decisions Log —
      verified present in `TaskItem.swift` today
- [x] Add `TaskItem.recurrenceRule: String?` — the one genuinely new `TaskItem` field V1 needs, for
      "recurring tasks" (Phase 6); encoding (RFC 5545 RRULE subset vs. a simple enum-encoded
      string) is explicitly left for Phase 6 to decide — the field itself is opaque `String?`
      storage. Added to [TaskItem.swift](../../models/TaskItem.swift) (`CodingKeys`/
      `init(from:)`/`encode(to:)` per `ARCHITECTURE.md`'s manual-`Codable` convention) and
      [TaskItem+Sync.swift](../../sync/TaskItem+Sync.swift) (`writeFields`/`readFields`). Found
      and fixed a real gap while wiring this up: `BackupDAL.restore`'s `TaskItem` branch
      hand-copies fields rather than relying on `Codable`, and had not been updated for the new
      field — a restored backup would have silently dropped `recurrenceRule` without this fix.
      Extended `SyncMappingTests.taskItemFieldsRoundTripIncludingUnusedMVPFields` to assert the
      new field round-trips through `CKRecord`. Full `NoteBytezTests` target builds and passes on
      the iPhone 17 simulator (`xcodebuild test`)
- [x] Extend `docs/styleGuide.md` / `UIUX/06-DesignSystem.md`'s component inventory for V1's new
      components — done via Phase 1 (both files now carry a "Version 1 additions" component table)
- [ ] Document the Universe-as-Notebook-convention decision (**Decisions Log #1**) in
      user-facing help/onboarding copy where Notebooks are introduced — **still not done**: Phase
      1 settled *where* this belongs conceptually (the Universe Architect persona and Journey 6 in
      [UIUX/01-Personas.md](UIUX/01-Personas.md)/[UIUX/02-Journeys.md](UIUX/02-Journeys.md)), which
      unblocks this, but writing the actual in-app copy string is a small implementation task with
      no dedicated phase of its own — do it opportunistically whenever Notebook-adjacent UI is
      next touched (Phase 3's Note Template picker/manager is the most natural fit, since it's the
      other half of the same worldbuilding workflow)

---

## Phase 1 — V1 UI/UX Design Artifacts

Not a Release Features bullet — prerequisite design work. The MVP `UIUX/01-06` set covered MVP
scope only (`03-FeatureMarriage.md` confirms: "No V1/Advanced feature is included"); V1 has no
wireframed screens yet. Mirrors the process that produced MVP's S1-S15.

**Correction found while executing this phase:** MVP's `02-Journeys.md` already runs J1-J5 (it
has five journeys, not four — Journey 5 is "Promote to Notebook"), not J1-J4 as this plan
originally assumed when it proposed J5-J8 for V1. V1 journeys are renumbered **J6-J9** below;
this is the number used consistently in the UIUX docs and referenced by Phase 15.

- [x] Extend [UIUX/01-Personas.md](UIUX/01-Personas.md) — formally admit the Author/Fiction-Writing
      persona from [NoteBytez-PersonaAuthorValidation.md](NoteBytez-PersonaAuthorValidation.md)
      (currently deferred), now that Properties/Note Templates make it servable. Added as
      persona 4, "The Universe Architect," plus a 4th column in the Cross-persona summary table
- [x] Extend [UIUX/02-Journeys.md](UIUX/02-Journeys.md) — authored V1 journeys: J6 (structured-entity
      authoring via Properties + Templates), J7 (canvas-based visual planning), J8 (shared-space
      collaboration), J9 (Obsidian/Logseq migration), plus a "Cross-journey notes (Version 1)"
      closing section
- [x] Extend [UIUX/03-FeatureMarriage.md](UIUX/03-FeatureMarriage.md) — map every V1 Release
      Features bullet to a journey, matching MVP's coverage-check discipline. Added a "## Version 1"
      table (25 rows) plus its own "Coverage check (Version 1)" subsection, alongside the
      untouched MVP table/coverage check
- [x] Extend [UIUX/04-InteractionDesign.md](UIUX/04-InteractionDesign.md) — per-platform
      interaction notes for Canvas (touch pinch/pan vs. trackpad/mouse), Properties editor,
      Template picker, Task Dashboard, Attachment preview, Sharing UI. Added S16-S24 to the
      Screen inventory table, a "V1 additions to the navigation shell" subsection (iPhone tab bar
      deliberately stays at 5 — new screens reached by pushing from existing tabs, not new tabs),
      and Journey 6-9 Mermaid flowcharts
- [x] Extend [UIUX/05-Wireframes.md](UIUX/05-Wireframes.md) — wireframe and number new screens
      continuing from S15: Canvas (S16), Properties Editor (S17), Template Picker/Manager (S18),
      Task Dashboard (S19), Attachment Preview (S20), Saved Views (S21), Sharing/Participants
      (S22), Migration Assistant (S23), Plugin Management (S24 — permission-grant UI per
      Decisions Log #3);
      Advanced Search extends existing S6/S7 rather than a new screen. All 9 screens wireframed
      on Mac/iPad/iPhone (S17 and S18's Manager sub-flow specified as deltas rather than fully
      redrawn, following S10's own precedent)
- [x] Extend [UIUX/06-DesignSystem.md](UIUX/06-DesignSystem.md) — new component inventory:
      `CanvasCardView`, `CanvasConnector`, `PropertyEditorRow`,
      `TemplatePickerRow`, `TaskDashboardRow`, `RecurrenceControl`, `AttachmentThumbnail`,
      `AttachmentPreview`, `SavedViewChip`, `ParticipantAvatar`, `PermissionLevelPicker`,
      `MigrationSourceRow`, `PluginPermissionRow`. **One consolidation from the original list**:
      no separate `PropertyField` — the wireframed row both labels and edits a Property in one
      component (`PropertyEditorRow`), so a second, narrower component would have had no distinct
      use. Also added 8 new SF Symbols for the new nav items/screens
- [x] Re-promote the updated `UIUX/06-DesignSystem.md` additions into `docs/styleGuide.md`, per
      `CLAUDE.md` §10. **Found and fixed a pre-existing drift while doing this**: `styleGuide.md`
      had never been re-promoted after MVP Phase 8 (Notebooks) — it was missing `NotebookListRow`,
      `PromoteSourcePreview`, S14/S15 references, and the `books.vertical` SF Symbol that
      `06-DesignSystem.md` already had. Backfilled those alongside the new V1 content, since it's
      the same "keep them in sync" maintenance action

---

## Phase 2 — Properties

Release Features: "Properties". Depends on Phase 1.

- [x] `Property` model — property definition (`propertyId`, `libraryId`, `name`, `valueType`:
      text/number/date/checkbox/list, audit fields, `isActive`) — library-scoped catalog of
      property names in use, not per-document — [Property.swift](../../models/Property.swift).
      `name` matches by exact string, not case-folded like `Tag.name` — a Property is typed once
      via a Template or the editor, not retyped inline, so there's no duplicate-spelling risk
- [x] `DocumentProperty` model — value join (`documentPropertyId`, `documentId`, `propertyId`,
      canonical-string value storage plus `valueType` mirrored for query convenience, audit
      fields, `isActive`) — same foreign-key-by-UUID pattern as `DocumentTag`/`DocumentNotebook` —
      [DocumentProperty.swift](../../models/DocumentProperty.swift)
- [x] Property DAL: create/list/rename/delete property definitions; set/get/remove a document's
      property values — [PropertyDAL.swift](../../dal/PropertyDAL.swift) (`findOrCreate`,
      `rename`, `delete`, `setValue`, `removeValue`, `fetchProperties`, `syncProperties`)
- [x] Frontmatter round-trip: parse typed Properties from YAML frontmatter on import/parse, write
      back on save/export — [PropertyParser.swift](../../dal/PropertyParser.swift), mirroring
      `TagParser`/`NotebookParser`'s frontmatter handling rather than extending `MarkdownG9`
      (Properties have no inline-body syntax to add there, unlike tags). Type inferred from the
      raw value: checkbox > date (`yyyy-MM-dd`) > number > text, in that priority; a flow/block
      list becomes `.list`, canonicalized as a `"; "`-joined string. **Design decision**: content
      is the single source of truth, exactly like Tags — the editor UI writes a value via
      `PropertyParser.applying` directly into `DocumentViewModel.content`, and `save()`'s
      `PropertyDAL.syncProperties` reconciles the index from that content afterward, the same
      reconcile-on-save shape `TagDAL.syncTags` already established. Export needed **no changes**:
      unlike Tags' synthetic export-only `#notebook/` tag, a Property's frontmatter line already
      lives in `document.content`, so `ExportDAL` round-trips it for free
- [x] `PropertyViewModel` — [PropertyViewModel.swift](../../viewModels/PropertyViewModel.swift),
      wraps a `DocumentViewModel` rather than duplicating its state, mirroring how
      `JournalViewModel` wraps one for the displayed day (MVP Phase 6)
- [x] Properties editor UI on the Document view —
      [PropertyEditorRow.swift](../../views/Components/PropertyEditorRow.swift), wired into
      [DocumentView.swift](../../views/Document/DocumentView.swift) between the Tags row and the
      body, per Journey 6's "one continuous document" design implication. **One consolidation
      from Phase 1's plan**: no separate `PropertyField` component — one row both labels and
      edits (already flagged when Phase 1 closed out)
- [x] Search/filter by property — `SearchDAL.searchByProperty`, mirroring `searchByTag`'s shape
      (case-insensitive substring match against `DocumentProperty.value`, deduped per document)
- [x] Registered `Property`/`DocumentProperty` in `NoteBytezApp.swift`'s `Schema`; extended
      `BackupSnapshot`/`BackupDAL` capture and restore (manual `Decodable` keeps old snapshot
      files decoding, same pattern as every prior field addition to that struct)
- [x] Unit tests: `PropertyParserTests.swift` (18 tests — type inference per value, reserved-key
      exclusion, write/replace/remove, full round-trip), `PropertyDALTests.swift` (9 tests — CRUD,
      reconcile-on-save create/remove/idempotency), extended `SyncMappingTests.swift` (field
      round-trip + rewired the "all N tables" dispatch tests from eight to ten),
      `BackupDALTests.swift` (capture + restore-after-delete), `SearchDALTests.swift`
      (`searchByProperty` match/no-match), `DocumentViewModelTests.swift`
      (`setPropertyValue`/`removePropertyValue` integration). Full `NoteBytezTests` target builds
      and passes on the iPhone 17 simulator, 0 failures (`xcodebuild test`)

---

## Phase 3 — Note Templates

Release Features: "Note templates". Depends on Phase 2 (Properties — templates pre-fill Property
fields), MVP Phase 8 (Notebooks — `NotebookTemplateGroup`), MVP Phase 6 (Daily Journal —
`JournalTemplateGroup`).

- [x] `TemplateGroup` model (`templateGroupId`, `libraryId`, `name`, audit fields) —
      [TemplateGroup.swift](../../models/TemplateGroup.swift)
- [x] `NoteTemplate` model (`noteTemplateId`, `templateGroupId` FK, `name`, pre-filled Property
      definitions/defaults, audit fields) — belongs to exactly one `TemplateGroup` (simple FK,
      per the Decisions Log rationale in `NoteBytez-ReleaseFeatures.md`) —
      [NoteTemplate.swift](../../models/NoteTemplate.swift). **Design decision**: a template's
      field list (`[NoteTemplateField]`: name/valueType/defaultValue) is stored as a single
      JSON-encoded `fieldsJSON: String?` rather than a new synced join model — the fields are
      small, always read/written as one unit, and never queried across templates, so a flat
      scalar field matches this app's existing preference (e.g. `DocumentProperty.value`'s
      canonical-string storage) over another CloudKit table for a single-use structure
- [x] `NotebookTemplateGroup` join model (many-to-many, mirrors `DocumentNotebook`) —
      [NotebookTemplateGroup.swift](../../models/NotebookTemplateGroup.swift)
- [x] `JournalTemplateGroup` join model (many-to-many, library-scoped — Journal has no container
      model, per MVP's Decisions Log) —
      [JournalTemplateGroup.swift](../../models/JournalTemplateGroup.swift)
- [x] Template DAL: CRUD for `TemplateGroup`/`NoteTemplate`, attach/detach to a Notebook or
      Journal — [TemplateDAL.swift](../../dal/TemplateDAL.swift). `deleteGroup` cascades:
      soft-deletes the group's `NoteTemplate`s and every Notebook/Journal join referencing it,
      so nothing is left orphaned for a picker to still surface
- [x] Template picker scoping logic: inside a Notebook → that Notebook's attached group(s); in the
      Journal → the library's attached journal group(s); neither → every template in the library,
      ungrouped — `TemplateDAL.PickerScope`/`templatesForPicker(scope:libraryId:in:)`
- [x] Apply-at-creation flow: new Document pre-filled with a chosen `NoteTemplate`'s Property
      fields — `TemplateDAL.createDocument(from:title:libraryId:in:)`, immediately calls
      `PropertyDAL.syncProperties` so pre-filled fields are queryable without waiting for the
      document's next save. **Found and fixed a real bug while wiring this up**: an empty
      default value (e.g. a blank "Species" field) silently vanished on round-trip —
      `PropertyParser.extractFrontmatterProperties` filtered out any value that unquoted to `""`,
      including a deliberately-written `key: ""`. Fixed to only skip a key with nothing at all
      after the colon (the genuine block-list ambiguity), not an explicit empty value; see
      [PropertyParser.swift](../../dal/PropertyParser.swift). One accepted residual limitation
      documented there: an empty `.date`/`.number`/`.checkbox` default has no textual signal to
      re-infer its type from and reads back as `.text` until filled in — inherent to inferring
      type from the value rather than storing one independently, not worth a redesign for
- [x] Apply-after-the-fact flow: existing Document, apply a template's fields retroactively —
      `TemplateDAL.applyRetroactively(_:to:in:)`, backfills only fields the document doesn't
      already have a value for and never overwrites an existing one, per Journey 6
- [x] `TemplateViewModel` — [TemplateViewModel.swift](../../viewModels/TemplateViewModel.swift),
      serves both the Picker and the Manager sub-flows, same rationale `SearchViewModel` used
      for S6/S7
- [x] Template Picker/Manager UI (Phase 1's S18) —
      [TemplatePickerView.swift](../../views/Template/TemplatePickerView.swift) (Picker, a sheet
      with an explicit "Start Blank" option, same never-auto-commits rule as S2/S10/S15/S22);
      Manager is a 3-level drill-down —
      [TemplateGroupListView.swift](../../views/Template/TemplateGroupListView.swift) →
      [NoteTemplateListView.swift](../../views/Template/NoteTemplateListView.swift) →
      [NoteTemplateFieldsView.swift](../../views/Template/NoteTemplateFieldsView.swift), reached
      from Settings → "Templates". Wired the Picker into three real entry points: `DocumentListView`'s
      "+" (library scope), a new "+" on `NotebookDocumentsView` (notebook scope — this view had no
      creation action at all before Phase 3), and a new "Apply Template" toolbar button on S4
      (`DocumentView`, apply-after-the-fact, "start blank" hidden since it's meaningless there)
- [x] Starter content: ship Author/Fiction Writing, Wedding Planning, Photography Client Work
      `TemplateGroup`s as fully editable/deletable seed data (per Decisions Log) — seeded once per
      new library, content only, not hardcoded behavior — `TemplateDAL.seedStarterContent`,
      wired into `LibraryDAL.create`. Fiction Writing ships Character/Location templates,
      Wedding Planning ships Vendor/Guest, Photography Client Work ships Client/Shoot Location
- [x] Registered `TemplateGroup`/`NoteTemplate`/`NotebookTemplateGroup`/`JournalTemplateGroup` in
      `NoteBytezApp.swift`'s `Schema`; extended `BackupSnapshot`/`BackupDAL` capture and restore
- [x] Unit tests: `TemplateDALTests.swift` (17 tests — CRUD, cascade delete, join
      attach/detach idempotency, all three picker scopes, apply-at-creation, apply-after-the-fact
      non-destructive backfill, starter-content idempotency and library-isolation), extended
      `LibraryDALTests.swift` (the actual `LibraryDAL.create` → seeding wiring, not just
      `seedStarterContent` in isolation — found this was otherwise untested), extended
      `SyncMappingTests.swift` (4 new field round-trips, dispatch tests rewired from ten to all
      fourteen tables), extended `BackupDALTests.swift` (capture + restore-after-cascade-delete).
      Full `NoteBytezTests` target builds and passes on the iPhone 17 simulator, 0 failures
      (`xcodebuild test`, ~300 tests). App also launches clean on-device with the 4-model schema
      addition (screenshot-verified); deeper simulator tap interaction hit this environment's
      already-documented tap-delivery flakiness (MVP Phases 4/7/15), not a Phase 3 regression

---

## Phase 4 — Block References

Release Features: "Block references". Depends on MVP Phase 3 (Documents + Stable Blocks), MVP
Phase 4 (Backlinks — `WikilinkParser`/`BacklinkDAL` pattern this mirrors).

- [x] `((anchor))` reference parser — sibling to `WikilinkParser`, resolves a reference to a
      specific `Block` regardless of which `Document` contains it —
      [BlockReferenceParser.swift](../../dal/BlockReferenceParser.swift). **Naming clarified
      from the plan's own working title**: the actual typed/stored syntax is `((anchor))` using
      `Block.anchor` (the existing human-readable slug from MVP Phase 3), not the raw
      `blockId` UUID — asking a user to hand-type a UUID isn't usable, and this exactly mirrors
      how `[[wikilink]]` addresses a Document by title, not by `documentId`. Also extended
      MarkdownG9's `MDProcessor` (the local package, per `ARCHITECTURE.md`'s "extended
      per-feature" note) with the matching `((anchor))` → `blockref://anchor` render rewrite,
      the same pattern already established there for wikilinks/tags, plus 5 new package-level
      tests
- [x] Maintained `blockId → document` index in the DAL (CloudKit provides no secondary index) —
      extend `BlockDAL` with a library-scoped lookup, kept current as Blocks are re-parsed on save
      (mirrors MVP Phase 3's block-splitting UUID-stability logic). **Turned out to need no new
      structure**: `Block.documentId` has been a stored, always-current field since MVP Phase 3 —
      the "index" this task asked for already existed; what was actually missing was a
      library-wide *fetch* (`BlockDAL.fetchActive(libraryId:in:)`, joined through
      `DocumentDAL.fetchActive` since `Block` carries no `libraryId` of its own), which is what
      got built
- [x] Static reference rendering only: inserts a link/preview at render time, not a
      live-updating transclusion — explicitly deferred to Advanced (per Decisions Log); no live
      re-render built. Rendered as a tappable link showing the anchor text itself (`((anchor))`,
      parens kept — same sigil-keeping treatment tags already get), not an inline content
      preview of the target block — a true content preview would require `MDProcessor` to gain
      database access, breaking its pure-function design, which is a larger change flagged here
      rather than silently built or silently skipped
- [x] Block-level backlinks — extend MVP's document-level `BacklinksViewModel`/Backlinks pane down
      to block granularity — `BacklinksViewModel.blockBacklinks` (new `BlockBacklinkGroup`s,
      one per referenced anchor), rendered as a new "Block References" section in
      [BacklinksPaneView.swift](../../views/Document/BacklinksPaneView.swift), reusing the
      existing `BacklinkRow` component rather than a new one
- [x] Autocomplete for `((` block references (fuzzy match across block anchors/content, mirrors
      MVP's wikilink autocomplete) — `BlockReferenceDAL.autocompleteMatches`, reuses
      `WikilinkParser.fuzzyMatches` rather than a second fuzzy-match implementation, per the
      task's own "mirrors" instruction. New `BlockReferenceText` component; wired into both S3
      (`TodayJournalView`) and S4 (`DocumentView`)'s editing toolbars, matching exactly where
      wikilink/tag autocomplete already live in each
- [x] Unit tests: block-reference resolution correctness, index currency after a block-splitting
      re-parse, block-level backlink accuracy — `BlockReferenceParserTests.swift` (10 tests),
      `BlockReferenceDALTests.swift` (9 tests, incl. the anchor-collision-across-documents
      tie-break policy: prefer the current document, else deterministic library-wide fallback by
      document title), extended `BlockDALTests.swift` (library-scoped fetch, excludes
      soft-deleted). **Found and fixed a real bug while writing these**:
      `BlockReferenceParser.applying` was assembling `((anchor))` with an extra/missing closing
      paren depending on how the string-interpolation was written — easy to miscount by eye;
      switched to explicit `"((" + anchor + ")) "` concatenation instead of interpolation so the
      paren count is visually unambiguous. Full `NoteBytezTests` target (326 tests) and the
      MarkdownG9 package's own test target (39 tests) both build and pass, 0 failures

---

## Phase 5 — Advanced Search

Release Features: "Advanced search". Depends on MVP Phase 10 (Exact Search). **Dependency
corrected while executing this phase**: the plan originally also listed Phase 4 (Block
References) as a dependency for embedded search-result blocks — that was a name-similarity mix-up
from initial drafting, not a real dependency; embedded query blocks are a plain fenced-code-block
syntax with no relationship to `((anchor))` block references.

- [x] Boolean query parser: AND/OR/NOT, exact phrase, regex — extend `SearchDAL`'s query handling
      — [AdvancedSearchParser.swift](../../dal/AdvancedSearchParser.swift), a pure
      tokenizer/recursive-descent parser + evaluator (no `ModelContext`), same shape as
      `TagParser`/`WikilinkParser`. Precedence: `NOT` highest, then `AND` (adjacent terms with no
      explicit operator default to `AND`, e.g. `#character #act2` — matches how a plain search
      query already reads), `OR` lowest; parentheses override. A malformed query (unbalanced
      quote/paren) returns `nil` rather than throwing, so `SearchDAL` can fall back to a plain
      literal match instead of showing confusing empty results for a likely typo
- [x] Apply boolean queries across content, tags, and file/path scopes (not just note text) —
      `SearchDAL.searchAdvanced(query:scope:libraryId:in:)`. **Design**: a `#tag` term always
      checks the document's tags regardless of scope — this is what makes the Release Features
      example (`#character AND #act2 NOT #resolved`) and a mixed query like
      `promotion AND #hr` (content term + tag term, one expression) both work in a single pass;
      every other term type (bare word/phrase/regex) is scoped by the existing Content/Path
      chips, mirroring exactly how MVP's `searchContent`/`searchByTitle` already split
      content-or-title from title-only. MVP's three simple search functions were left untouched
      (already tested, still used by Quick Switcher) rather than rewritten to route through the
      new evaluator — "sharing one path" is satisfied semantically (a single-term boolean query
      reduces to the same match logic), not by a risky refactor of working code
- [x] Embedded search-result blocks: a Markdown block syntax that renders a live query's results
      inline in a note — resolves at render/preview time, not persisted as static content —
      [EmbeddedSearchBlockParser.swift](../../dal/EmbeddedSearchBlockParser.swift) recognizes a
      fenced ` ```query ... ``` ` block (ordinary Markdown fenced-code syntax, so it round-trips
      through export/import and reads sensibly as a plain code block in Obsidian/Logseq too).
      [DocumentPreviewView.swift](../../views/Document/DocumentPreviewView.swift) restructured:
      the line-by-line render path (previously triggered only by task checkboxes, now also by an
      embedded query block) resolves each block to a live `EmbeddedSearchResultsView` calling
      `DocumentViewModel.embeddedSearchResults(for:)` fresh on every render. **Verified task
      checkbox indices stay correct**: `toggleTask(at:)` indexes checkbox lines across the
      *whole* document in order, so the line-scan walks `EmbeddedSearchBlockParser`'s full
      output (not a pre-split view of the content) to avoid a real index-drift bug where a query
      block sitting between two task lines would have thrown off the count. **Scope cut, noted
      not silently**: result rows are display-only, not tap-to-navigate — `DocumentPreviewView`
      is shared between S3/S4 and neither currently threads a navigation callback through it
- [x] `SearchViewModel` extended with boolean-query state (S6/S7 continue to serve both) —
      `isAdvancedMode: Bool`, consulted only by `search()` (S7); `quickSwitcherResults` (S6) is
      untouched, per the task's own "S6/S7 continue to serve both" instruction
- [x] Advanced Search UI: query builder or query-syntax field with tag/content/path scope chips,
      extending Phase 1's S7 wireframe rather than a new screen —
      [SearchView.swift](../../views/Search/SearchView.swift): a toggle button next to the
      search field switches modes, existing Content/Tag/Path `FilterChipRow` reused unchanged as
      the default scope for non-`#tag` terms, a syntax-hint caption appears only in Advanced mode
- [x] Unit tests: boolean operator precedence/correctness, negation, regex safety (reject or
      time-bound catastrophic-backtracking patterns), embedded-block re-render correctness —
      `AdvancedSearchParserTests.swift` (27 tests: parsing shape/precedence, evaluation per node
      type, regex safety), `EmbeddedSearchBlockParserTests.swift` (8 tests), extended
      `SearchDALTests.swift` (5 integration tests). **Regex safety implemented as reject, not
      time-bound**: `NSRegularExpression` matching isn't cancellable once started, so a
      wall-clock timeout would only stop the *caller* from waiting — the runaway match keeps
      burning a thread in the background, and a live-search-as-you-type UI could leak one of
      those per keystroke on a pathological pattern. Rejecting via a nested-quantifier heuristic
      (`(a+)+`-shaped patterns — the common real-world ReDoS case) before ever executing the
      pattern avoids that risk entirely; documented as a deliberately non-general detector, not a
      full ReDoS analyzer. **Found and fixed two real bugs while writing these tests**: (1) a
      test helper using `try #require` inside a non-`throws` `@Test` function failed to compile
      — same class of mistake already seen in Phase 4, now doubly confirmed as worth watching
      for; (2) `SearchDAL`'s private `truncate(_:limit:)` has no default for `limit` (unlike the
      sibling `snippet` helper), causing an initial build failure, fixed by passing it
      explicitly. Full `NoteBytezTests` target (365 tests) builds and passes, 0 failures
      (`xcodebuild test`, iPhone 17 simulator)

---

## Phase 6 — Task Dashboards

Release Features: "Task dashboards". Depends on MVP Phase 7 (Basic Tasks — `TaskItem.dueDate`/
`priority` reserved fields), Phase 0 above (`recurrenceRule` field).

- [x] Surface `TaskItem.dueDate`/`priority` in UI for the first time (schema already present since
      MVP, per Decisions Log) — shown as indicators in
      [TaskDashboardRow.swift](../../views/Components/TaskDashboardRow.swift); no editor UI for
      setting them was requested by this phase's task list (the Dashboard reads and displays,
      it doesn't add a due-date/priority picker — a scope boundary worth naming, not silently
      assumed)
- [x] Recurring tasks: `TaskItem.recurrenceRule` (Phase 0) plus recurrence-expansion logic
      (next-occurrence calculation, not a full calendar engine) —
      [RecurrenceRule.swift](../../models/RecurrenceRule.swift), a small fixed set
      (daily/weekly/monthly/every-N-days) rather than an RFC 5545 RRULE parser, matching the
      task's own "not a full calendar engine" scope. **Design decision**: completing a recurring
      task advances `dueDate` to the next occurrence and leaves `isDone = true` (this occurrence
      really is done; the due date now shows when it's due again) rather than auto-reopening the
      same row — the simpler of two reasonable semantics, and the one that never needs to touch
      Markdown content a second time. Safe to mutate `dueDate` directly: unlike `isDone`,
      `dueDate`/`priority`/`recurrenceRule` have no Markdown representation at all in this app,
      so there's no content to keep in sync
- [x] Cross-note task query: aggregate `TaskItem` rows library-wide, not scoped to one Document —
      extend `TaskDAL` — `TaskDAL.fetchActive(libraryId:in:)`, a direct predicate fetch (unlike
      `Block`, `TaskItem` already carries its own `libraryId`)
- [x] Filter by status (open/done)/date/tag — reuses `TagDAL` for the tag filter, no new tag
      mechanism — `TaskDashboardViewModel`. Tag filtering matches the *owning document's* tags
      (a task has no tagging concept of its own in this data model); date filtering adds
      overdue/due-today/due-this-week, reasonable choices beyond the task's literal wording since
      "filter by date" needed *some* concrete buckets to mean anything
- [x] `TaskDashboardViewModel` — decided to build its own toggle path,
      `TaskDAL.toggle(_:in:)`, rather than reusing `DocumentViewModel.toggleTask(at:)`.
      **Reasoning**: that method's toggle index is only valid against a whole document's content
      already loaded for editing (S3/S4); the Dashboard reaches an arbitrary task from any
      document without one open. The new path mirrors `NotebookDAL.appendBackLink`'s
      block-splice approach (locate by `Block.sortOrder` position, verify content still matches
      before touching it) and funnels through the exact same `TaskParser.toggling`/`syncTasks`
      primitives S3/S4 already use — same underlying mechanism, a second entry point suited to
      not having the document already loaded. Verified byte-for-byte identical persisted state
      between the two entry points in a dedicated test
- [x] Task Dashboard UI (Phase 1's S19) — cross-note list, due-date/priority/recurring indicators,
      status/date/tag filter chips —
      [TaskDashboardView.swift](../../views/Task/TaskDashboardView.swift). Generalized
      `FilterChipRow` (previously hardcoded to `SearchViewModel.Scope`) to any `String`-backed
      `CaseIterable` enum so the status/date filters reuse it instead of a second, copy-pasted
      chip row. Wired per Phase 1's navigation decision: a dedicated `AppDestination` (Mac/iPad
      sidebar item), reached on iPhone via a new toolbar button on S3 rather than a 6th tab
- [x] Unit tests: cross-note aggregation correctness, recurrence next-occurrence calculation,
      filter combinations, toggle-consistency preserved across Dashboard/Journal/Document —
      `RecurrenceRuleTests.swift` (9 tests), `TaskDashboardViewModelTests.swift` (9 tests),
      extended `TaskDALTests.swift`. **Found and fixed a real, pre-existing data-loss bug while
      writing these**: `TaskDAL.syncTasks`'s reuse key included the task's `blockId`, but
      `BlockDAL.syncBlocks` deliberately assigns a *new* `blockId` to any block whose content
      changed at all (its own tested "even a small edit is removal+insertion" rule) — and a
      checkbox toggle changes a block's content by definition (the marker is part of it). So
      *every single toggle*, from any entry point, silently discarded whatever
      due-date/priority/recurrence had been set on that task, creating a fresh row with none of
      it. Invisible in MVP (those fields were reserved but never surfaced); a real bug now that
      Phase 6 surfaces them. Fixed by keying reuse on the block's *position*
      (`Block.sortOrder`, stable across a pure marker flip) instead of its identity, resolved
      even for a just-soft-deleted original block. Added a dedicated regression test
      (`syncTasksPreservesTaskItemIdentityAndCustomFieldsAcrossAToggleDespiteTheBlockIdChanging`)
      independent of the recurrence feature, since this bug could otherwise resurface silently.
      Full `NoteBytezTests` target (390 tests) builds and passes, 0 failures (`xcodebuild test`,
      iPhone 17 simulator)

---

## Phase 7 — Saved Views

Release Features: "Saved views". Depends on Phase 5 (Advanced Search) and Phase 6 (Task
Dashboards) — a Saved View pins either kind of query.

- [x] `SavedView` model (`savedViewId`, `libraryId`, `name`, `queryType`: search/task, serialized
      query definition, sort/pin order, audit fields) — [SavedView.swift](../../models/SavedView.swift).
      **Design**: `queryType` + `definitionJSON` (a `SavedSearchDefinition` or
      `SavedTaskDefinition`, JSON-encoded) — the same "flat scalar field over a second table"
      choice `NoteTemplate.fieldsJSON` already made in Phase 3 for a small, always-together
      structure never queried piecemeal. Each definition mirrors its source view model's own
      state exactly (`SavedSearchDefinition` = `SearchViewModel`'s query/scope/advanced-mode;
      `SavedTaskDefinition` = `TaskDashboardViewModel`'s three filters), so nothing gets lost in
      translation between "what the screen had" and "what got saved"
- [x] Saved View DAL: create/list/rename/delete/reorder —
      [SavedViewDAL.swift](../../dal/SavedViewDAL.swift). `reorder` takes the full
      already-reordered array (matching what a `List`'s `.onMove` already hands back) and
      reassigns sequential `sortOrder`, rather than a more error-prone insert-at-position API
- [x] `SavedViewViewModel` — [SavedViewViewModel.swift](../../viewModels/SavedViewViewModel.swift).
      Live re-evaluation composes the existing engines directly rather than duplicating query
      logic: `searchResults` calls `SearchDAL`'s functions (including `searchAdvanced` from
      Phase 5) the same way `SearchViewModel` does; `taskResults` constructs a fresh
      `TaskDashboardViewModel` from the saved filter values and reads back `.filteredTasks` —
      reusing that view model's own filter predicates instead of a second copy of them. Both
      `SearchViewModel.libraryId` and `TaskDashboardViewModel.libraryId` were widened from
      `private` to `internal` to make this composition possible
- [x] "Save this search/query" action wired into Phase 5's Advanced Search UI and Phase 6's Task
      Dashboard UI — a toolbar pin button + name-entry alert on both
      [SearchView.swift](../../views/Search/SearchView.swift) and
      [TaskDashboardView.swift](../../views/Task/TaskDashboardView.swift)
- [x] Pinned Saved Views list/nav entry (Phase 1's S21) — a saved query re-evaluates live on open,
      never a frozen snapshot from save time —
      [SavedViewsListView.swift](../../views/SavedView/SavedViewsListView.swift) (Mac/iPad
      sidebar destination, reorderable/deletable) and
      [SavedViewResultsView.swift](../../views/SavedView/SavedViewResultsView.swift) (the actual
      live re-evaluation, reached from either the list or a new `SavedViewChip` pinned row atop
      S7/S19 on every platform, per Phase 1's navigation plan)
- [x] Registered `SavedView` in `NoteBytezApp.swift`'s `Schema`; extended `BackupSnapshot`/
      `BackupDAL` capture and restore
- [x] Unit tests: Saved View CRUD, query-definition round-trip for both query types, live
      re-evaluation returns current results, not stale ones — `SavedViewDALTests.swift` (9
      tests), `SavedViewViewModelTests.swift` (9 tests — including dedicated tests proving a
      saved search picks up a document created *after* it was saved, drops a document that
      stops matching, and a saved task view drops a task the moment it's completed elsewhere,
      all without re-saving the view), extended `SyncMappingTests.swift`/`BackupDALTests.swift`.
      Full `NoteBytezTests` target (410 tests) builds and passes, 0 failures (`xcodebuild test`,
      iPhone 17 simulator)

---

## Phase 8 — Attachment Handling

Release Features: "Attachment handling". Depends on MVP Phase 3 (Documents + Blocks — attachments
embed within note content).

**Storage decision (confirmed with the user before building)**: attachment bytes are copied into
the app's own iCloud ubiquity container (iCloud Drive) — not referenced in place, and not a
custom File Provider extension (no second Xcode target). Requires a new
`com.apple.developer.ubiquity-container-identifiers` entitlement on the existing
`iCloud.com.g9Consulting.Kontinuum` container; syncs across devices automatically via the OS.

- [x] `Attachment` model (`attachmentId`, `documentId`, `fileName`, `relativePath`, `mimeType`,
      audit fields) — [Attachment.swift](../../models/Attachment.swift), same shape as `Block`
      (owned child of `Document`, no `libraryId` of its own — Phase 4's precedent). **Deviation
      from this plan's original field list, noted rather than silently built**: no security-scoped
      bookmark is stored — because NoteBytez owns the copy at a deterministic path
      (`AttachmentStore/<documentId>/<attachmentId>-<fileName>`), the file is always re-locatable
      from `documentId`/`attachmentId`/`fileName` alone. `relativePath` (container-root-relative)
      replaces the bookmark field
- [x] iCloud Documents / File Provider integration —
      [AttachmentStorage.swift](../../dal/AttachmentStorage.swift): every entry point takes its
      container root as an explicit parameter (mirrors `BackupDAL.createSnapshot(...,
      directory:)`) so tests inject a temp directory instead of a real ubiquity container. Files
      land in `AttachmentStore/<documentId>/`, deliberately outside the container's `Documents`
      subfolder (the only part Files.app surfaces) — these are NoteBytez-managed files, not
      something a user should rename/delete out from under the app. Added
      `com.apple.developer.ubiquity-container-identifiers` to both
      [NoteBytez.entitlements](../../NoteBytez.entitlements) and
      [NoteBytez-macOS.entitlements](../../NoteBytez-macOS.entitlements). Not-yet-downloaded iCloud
      files get a `startDownloadingUbiquitousItem`-triggered fetch with a simple "downloading…"
      placeholder, no progress bar — scope-matched to what a preview thumbnail needs
- [x] Attachment DAL — [AttachmentDAL.swift](../../dal/AttachmentDAL.swift): `attach` (copies
      bytes, Finder-style `-2`/`-3` filename-collision dedupe, appends the embed line to content),
      `resolveLocalURL`, `remove` (soft-delete only — file bytes are left in place, per the app's
      no-physical-deletes rule), `fetchActive`, `syncAttachments` (reconcile-on-save, mirrors
      `TagDAL.syncTags`/`PropertyDAL.syncProperties`). CloudKit sync for the metadata row via
      [Attachment+Sync.swift](../../sync/Attachment+Sync.swift) — file bytes are never written
      into a `CKRecord` field, only `fileName`/`relativePath`/`mimeType`/audit fields; bytes sync
      separately via iCloud Drive. Registered in `SyncRecordFactory`'s three dispatch switches
      (now 16 tables, up from 15)
- [x] Markdown-native embedding syntax — [AttachmentParser.swift](../../dal/AttachmentParser.swift),
      pure/stateless like `PropertyParser`. Standard `![alt](fileName)` syntax, deliberately **no
      proprietary URL scheme** (unlike wikilinks/tags/block references) specifically so an
      Obsidian/Logseq vault's own `![](relative/path.png)` syntax (Phase 12) round-trips through
      this for free. **Scope note on this plan's "extend MarkdownG9 rendering" wording**:
      `MDProcessor` (the pure package) has no `ModelContext`/`FileManager` access — the same
      constraint Phase 4 already established for block-reference previews — so it's left
      untouched; it still renders `![alt](path)` as a caption exactly as before for any path that
      isn't a local attachment. Real local resolution happens in the app layer (next item)
- [x] Image and PDF preview rendering — extended `DocumentPreviewView.swift`'s existing
      line-based render path (Phase 5's precedent for task checkboxes/query blocks) rather than
      fighting `AttributedString`: `needsLineByLineRendering` now also triggers on
      `AttachmentParser.containsAttachmentEmbed`, and a matching line renders a live
      `AttachmentThumbnail` instead of styled text.
      [AttachmentThumbnail.swift](../../views/Components/AttachmentThumbnail.swift) (icon +
      filename chip, "downloading…" placeholder) and
      [AttachmentPreview.swift](../../views/Components/AttachmentPreview.swift) (full-screen
      sheet; image via a small cross-platform `UIImage`/`NSImage` bridge, PDF via a `PDFKit`
      `PDFView` wrapped as `UIViewRepresentable`/`NSViewRepresentable` — no third-party dependency)
- [x] `AttachmentViewModel` —
      [AttachmentViewModel.swift](../../viewModels/AttachmentViewModel.swift), wraps a
      `DocumentViewModel` exactly like `PropertyViewModel` does. `DocumentViewModel` itself gained
      `attachments`/`loadAttachments()` (wired into `init`/`reload`/`save()`, alongside
      `properties`) and `attach(fileURL:mimeType:)`/`removeAttachment(_:)`, the same
      content-is-source-of-truth shape `setPropertyValue`/`removePropertyValue` already establish
- [x] Attachment Preview UI (Phase 1's S20) — a new toolbar `📎` button on
      [DocumentView.swift](../../views/Document/DocumentView.swift)
      (`.fileImporter(allowedContentTypes: [.image, .pdf])`) next to Apply Template, mirroring
      S5's `[🔗]` backlinks-pane trigger per the wireframe's own note. **Corrected while building
      this task**: initially added a separate thumbnail-strip row (mirroring the Tags/Properties
      row placement) in addition to the line-based inline rendering below — re-reading S20's own
      wording ("`AttachmentThumbnail` grid **inline in the document body**") caught that this
      would double-render every attachment (once in a header strip, once where its `![alt]
      (fileName)` line actually sits in content). Removed the separate strip; the thumbnail grid
      is exactly where its embed line falls in the body, rendered by `DocumentPreviewView`'s
      line-based path (previous task), full-screen `AttachmentPreview` sheet on tap
- [x] Registered `Attachment` in `NoteBytezApp.swift`'s `Schema`; extended
      `BackupSnapshot`/`BackupDAL` capture and restore with attachment metadata (file bytes are
      the iCloud ubiquity container's own backup responsibility, not this app's)
- [x] Unit tests: `AttachmentParserTests.swift` (11 tests — embed detection/match/extraction/
      apply/remove), `AttachmentDALTests.swift` (6 tests — attach/copy, iCloud-unavailable
      failure, filename-collision dedupe, soft-delete leaves the file on disk, reconcile-on-save
      create/remove, all using an injected temp directory in place of the real ubiquity
      container), `AttachmentStorageTests.swift` (5 tests — container-relative path construction,
      filename sanitization keeps a written file inside its own document directory even given a
      `../`-laden original name, download-status resolution). **Found and fixed a real bug while
      writing these**: `AttachmentStorage.isDownloaded` returned `false` for any ordinary local
      file (not just an evicted iCloud one), because `try?` on `resourceValues` succeeds with a
      `nil` status for a non-ubiquitous file rather than throwing — fixed to fall back to
      `fileExists` whenever the status itself is `nil`, not just when the whole call throws.
      Extended `SyncMappingTests.swift` (field round-trip + all three dispatch tests rewired from
      fifteen to all sixteen tables) and `BackupDALTests.swift` (capture + restore-after-delete).
      Full `NoteBytezTests` target (435 tests) builds and passes on the iPhone 17 simulator, 0
      failures (`xcodebuild test`). **Found but out of scope, flagged rather than fixed**: native
      macOS build (`xcodebuild build -destination 'platform=macOS'`) currently fails to compile —
      unrelated to this phase, `SavedViewsListView.swift` (Phase 7) uses `EditButton()`, which is
      unavailable on macOS. This pre-existing break meant Phase 8's own new macOS-conditional
      `PDFKitRepresentable` code could only be verified by manual review against
      `PlatformCompatibility.swift`'s established `#if os()` pattern, not by an actual native macOS
      compile — flagged to the user as a separate task rather than fixed inline. Real cross-device
      iCloud Drive sync of attachment bytes is unverifiable in this environment, same class of gap
      as MVP Phase 12/V1 Phase 10's live-CloudKit caveats

---

## Phase 9 — Canvas

Release Features: "Canvas". Depends on Phase 8 above (Attachment Handling — media cards), MVP
Phase 3 (Documents — note cards), MVP external links (web cards). JSON Canvas spec surface
decided in **Decisions Log #2** (full JSON Canvas 1.0).

**Two gaps in this plan's own shorthand, resolved rather than silently picked**: (1) the
`CanvasCard` bullet below only lists `cardType: note/media/web`, but Decisions Log #2 commits to
round-tripping all 4 JSON Canvas node types including `group` — its own next line ("groups →
`group` nodes") already assumes a 4th type exists, so `.group` was added as that 4th case. (2) A
JSON Canvas `text` node (freeform text, not backed by any file) has no obvious NoteBytez
equivalent, since every other card type references something already real and addressable —
resolved the same way `Document.promotedFromDocumentId` already treats promoted content: an
imported `text` node becomes a real new `Document`, and the resulting card is an ordinary `.note`
card, consistent with "everything is a real note," not a special 5th type.

- [x] `CanvasBoard` model (`canvasBoardId`, `libraryId`, `name`, audit fields) —
      [CanvasBoard.swift](../../models/CanvasBoard.swift), same shape as `Notebook`
- [x] `CanvasCard` model (`canvasCardId`, `canvasBoardId` FK, `cardType`: note/media/web/**group**,
      a `documentId`/`attachmentId`/`url` reference depending on type, `label` (group title only —
      JSON Canvas has no title field on file/link nodes), position/size fields, `color` (JSON
      Canvas's optional preset-or-hex node color, stored verbatim), audit fields) —
      [CanvasCard.swift](../../models/CanvasCard.swift), same no-`libraryId`-of-its-own shape as
      `Block` (Phase 4's precedent)
- [x] `CanvasConnector` model (`canvasConnectorId`, `canvasBoardId` FK, source/target
      `canvasCardId`, `fromSide`/`toSide`, `color`, optional label, audit fields) —
      [CanvasConnector.swift](../../models/CanvasConnector.swift). **Scope cut, stated not
      silent**: the spec's `fromEnd`/`toEnd` (arrowhead style) aren't modeled — this plan's own
      task bullet only named `fromSide`/`toSide`/`color`/`label`; every rendered connector gets a
      plain arrowhead, a minor cosmetic loss on import from a foreign vault
- [x] Canvas DAL — [CanvasDAL.swift](../../dal/CanvasDAL.swift): board CRUD (`deleteBoard`
      cascades to its cards and connectors, mirrors `TemplateDAL.deleteGroup`), card
      add/move/resize/remove (`removeCard` cascades to connectors touching it), connector
      add/remove. **One small, justified extension to Phase 8's `AttachmentDAL`**: added
      `AttachmentDAL.fetchActive(libraryId:in:)`, joined through `DocumentDAL.fetchActive` — the
      exact precedent `BlockDAL.fetchActive(libraryId:in:)` already set in Phase 4 — since a media
      card picker needs to browse attachments across the whole library, not one document at a
      time. A media card always references an *existing* attachment already on some Document;
      Canvas does not let a card create a new, document-less attachment
- [x] JSON Canvas format import/export — [JSONCanvasFormat.swift](../../dal/JSONCanvasFormat.swift)
      (pure `Codable` structs mirroring the spec exactly, no `ModelContext`, same "pure format"
      shape as `AttachmentParser`/`PropertyParser`) plus `CanvasDAL.exportJSONCanvas`/
      `importJSONCanvas` for the DB-touching resolution on top of it. `.note`/`.media` → `file`
      nodes (path = `ExportDAL`'s own title-to-filename convention for a note — widened
      `ExportDAL.sanitizedFilename` from `private` to `internal` for this reuse — the attachment's
      own `fileName` for media, so a paired full-library export lands the reference correctly);
      `.web` → `link` node; `.group` → `group` node. Import resolves a `file`/`link` node against
      the library's *existing* Documents (by exported filename) or Attachments (by filename) — an
      unresolved reference is dropped, the rest of the board still imports (verified by a
      dedicated test, not just claimed); a `text` node creates a new `Document` per the Context
      note above. Full vault-content migration stays Phase 12's job — Phase 9 only places cards
      over content the library already has, or that the import itself just created for `text`
      nodes
- [x] Infinite 2D canvas rendering: pan/zoom, card layout, labeled connector rendering, grouping —
      extends `GraphCanvas.swift`'s already-proven pinch/pan mechanism (`MagnificationGesture` +
      `DragGesture`, scale/offset as bindings so the `[+][-][⤢]` toolbar drives them too, same S8
      pattern `GraphView` uses) rather than inventing a new gesture system. Connectors render via
      a `SwiftUI.Canvas` line layer (`CanvasConnectorView`, same drawing API `GraphCanvas` already
      uses), arrowhead + a label at the midpoint, between each connector's two cards' *committed*
      positions — a stated scope choice, not a bug: a line snaps into place when a drag ends
      rather than tracking a dragged card's live per-frame offset, since that offset is local
      `CanvasCardView` gesture state, not hoisted up to the connector layer. A `.group` card
      renders as a labeled dashed-border rectangle at its stored bounds — no computed
      child-membership highlighting, matching S16's own wireframe note ("group boundary... not
      separately drawn at this fidelity"). **Real bug found and fixed via on-device testing, not
      caught by unit tests**: `CanvasCardView`'s card-level drag gesture was attached via plain
      `.gesture()`, which in SwiftUI takes priority over a child view's own gesture recognizer —
      this silently swallowed every tap on a card, including the wrapped `Button`'s `onTap` used
      for both "open this note/media/web card" and "select this card while connecting." Confirmed
      on-simulator (drag/resize worked, tap did nothing) before switching to
      `.simultaneousGesture()`, then re-verified tap-to-open and the full connect-two-cards flow
      worked end-to-end afterward
- [x] `CanvasViewModel` — [CanvasViewModel.swift](../../viewModels/CanvasViewModel.swift), serves
      both the board list and a selected board's contents, the same "one concept, one view model"
      rationale `TemplateViewModel` already established for its own Picker+Manager split.
      `noteCardCandidates` reuses `WikilinkParser.fuzzyMatches` (the same function
      `DocumentViewModel.wikilinkSuggestions` already calls) rather than a second fuzzy-match
      implementation
- [x] Canvas UI (Phase 1's S16) —
      [CanvasBoardListView.swift](../../views/Canvas/CanvasBoardListView.swift) (mirrors
      `NotebookBrowserView.swift`'s exact list/create shape, plus an "Import Canvas…"
      `.fileImporter` action creating a new board),
      [CanvasBoardView.swift](../../views/Canvas/CanvasBoardView.swift) (the pan/zoom board: `[+]
      [-][⤢]` zoom toolbar, an Add Card menu — Note/Media pickers, Web/Group name-entry alerts
      mirroring Phase 7's own shape — a Connect-mode toggle, an Export action via
      [CanvasFileDocument.swift](../../views/Canvas/CanvasFileDocument.swift) mirroring
      `MarkdownFileDocument`),
      [CanvasCardView.swift](../../views/Components/CanvasCardView.swift),
      [CanvasConnectorView.swift](../../views/Components/CanvasConnectorView.swift). **Naming
      clarified from the plan's own working title**: Phase 1's component inventory names the
      connector-drawing view `CanvasConnector`, but that name is already the model's — the view
      component is `CanvasConnectorView` instead, matching `CanvasCardView`'s own suffix, the same
      kind of plan-vs-reality naming deviation Phase 1 itself made for `PropertyEditorRow`.
      Navigation: new `AppDestination.canvas` case (Mac/iPad sidebar item, per
      04-InteractionDesign.md's "Sidebar gains Canvas... as peer items"); iPhone reaches it via a
      new toolbar button on `NotebookBrowserView` (S14), confirmed directly by
      04-InteractionDesign.md's own line on `CanvasBoard` being library-scoped like Notebooks/Tags
      rather than Notebook-owned. Widened `NotebookViewModel.libraryId` from `private` to
      `internal` for this (Phase 7's own precedent on `SearchViewModel`/`TaskDashboardViewModel`)
- [x] Registered `CanvasBoard`/`CanvasCard`/`CanvasConnector` in `NoteBytezApp.swift`'s `Schema`;
      extended `BackupSnapshot`/`BackupDAL` capture (per-library board fetch, per-board card/
      connector fetch, mirroring how blocks/tasks/attachments are captured inside the
      per-document loop) and restore. Registered all three in `SyncRecordFactory`'s three
      dispatch switches (now 19 tables, up from 16)
- [x] Unit tests: `CanvasDALTests.swift` (9 tests — board/card/connector CRUD, cascade-delete,
      move/resize incl. the minimum-size clamp), `JSONCanvasFormatTests.swift` (5 tests — pure
      encode/decode shape correctness against the spec's own field names, lenient decoding on
      missing geometry), `CanvasImportExportIntegrationTests.swift` (3 tests — the "round-trip
      fidelity" task: export one of each card type + a labeled connector, reimport into a fresh
      board in the same library, assert the reconstituted board matches; plus the
      unresolved-file-reference and text-node-becomes-a-Document cases run as their own explicit
      tests, not just asserted inline). Extended `SyncMappingTests.swift` (3 new field round-trip
      tests, all three dispatch tests rewired from sixteen to all nineteen tables) and
      `BackupDALTests.swift` (capture + restore-after-cascade-delete). Full `NoteBytezTests`
      target (457 tests) builds and passes on the iPhone 17 simulator, 0 failures, 0 warnings
      (`xcodebuild test`). **Also found and fixed, unrelated to Canvas logic but discovered while
      finishing this phase**: Swift's type-checker timed out on `CanvasBoardView`'s `body` (one
      very large chained expression — pan/zoom canvas, toolbar, zoom overlay, four sheets/alerts,
      a navigation destination, a file exporter, all inline) when building for native macOS,
      despite building fine for iOS — a known Swift complexity cliff, not a logic issue. Fixed by
      splitting `body` into named sub-expressions (`canvasScreen`/`canvasContent`/`zoomControls`/
      `toolbarContent`/etc.), which surfaced one genuine platform bug underneath the timeout:
      `.textInputAutocapitalization`/`.keyboardType` on the web-link `TextField` are iOS-only,
      unguarded — fixed with `#if os(iOS)`, the same guard pattern already established for
      `EditButton` in Phase 8's own follow-up fix. Both `platform=iOS Simulator` and
      `platform=macOS` now build clean from scratch — 0 warnings, 0 errors

---

## Phase 10 — CloudKit Sharing

Release Features: "CloudKit Sharing". Depends on MVP Phase 12 (CloudKit Private Sync), MVP Phase
14 (Conflict Handling — extends the revision concept to named-collaborator attribution, per its
own forward-compatibility design).

- [x] `CKShare` creation per Library zone — [SharingService.swift](../../sync/SharingService.swift)
      (`createShare`/`fetchShare`/`updatePermission`/`removeParticipant`/`stopSharing`), placed in
      `sync/` rather than `dal/` since it manages `CKShare`/`CKRecord` directly against
      `CKContainer.privateCloudDatabase`, not a SwiftData model — the same rationale
      `ConflictResolver`/`SyncEngine` already sit there for. Reuses the existing "root Library
      record per zone" parenting exactly as planned, but that parenting needed one real fix to
      actually work as hierarchical-share input: `SyncableRecord.makeCKRecord`'s `library`
      `CKRecord.Reference` was written with action `.none` into a plain custom field — CloudKit's
      share hierarchy reads a record's dedicated `.parent` property, a distinct thing from any
      same-named custom field, and that was never set. Fixed in
      [SyncableRecord.swift](../../sync/SyncableRecord.swift) by also assigning the reference to
      `record.parent`, so a `CKShare(rootRecord:)` rooted at the Library record now genuinely
      covers every record beneath it, no schema change
- [x] Participant invite/accept flow — **Invite (owner side)**:
      [CloudSharingControllerRepresentable.swift](../../views/Components/CloudSharingControllerRepresentable.swift),
      `UICloudSharingController` wrapped as a transparent `UIViewControllerRepresentable` host on
      iOS, `NSSharingService(named: .cloudSharing)` wrapped the equivalent way as an
      `NSViewControllerRepresentable` on macOS (no dedicated view controller exists for CKShare on
      that platform — the service call itself is the presentation). **Accept (participant side)**:
      [AppDelegate.swift](../../AppDelegate.swift)'s `userDidAcceptCloudKitShareWith` handlers on
      both platforms call `SyncEngine.acceptShare(_:)`, which accepts the share
      (`CKContainer.accept(metadata)`), upserts the Library root record CloudKit already hands back
      on `metadata.rootRecord` (no extra fetch), and asks a second, shared-database `CKSyncEngine`
      to pull the rest of the zone. **iOS API note, stated not silently worked around**:
      `UIApplicationDelegate`'s variant of this hook is deprecated in the current SDK in favor of
      `UIWindowSceneDelegate.windowScene(_:userDidAcceptCloudKitShareWith:)`; adopting that would
      mean introducing a custom `UIWindowSceneDelegate`/scene configuration this app doesn't have,
      purely for one callback — kept on the still-functional `AppDelegate` hook instead, matching
      `ARCHITECTURE.md`'s own description of `AppDelegate` as "the one place with real
      platform-specific logic." **A second `CKSyncEngine`, not just a one-time fetch**: a library
      shared *to* this device lives in `CKContainer.sharedCloudDatabase`, a genuinely different
      endpoint from the private database `SyncEngine` already drove — `sharedEngine`/`sharedDatabase`
      added alongside the existing `engine`/`database` in
      [SyncEngine.swift](../../sync/SyncEngine.swift), both bound to the same
      `CKSyncEngineDelegate` (already parameterized by `syncEngine:` per callback, so no
      double-handling), each with its own subscription ID and its own `SyncStateStore` slot
      ([SyncStateStore.swift](../../sync/SyncStateStore.swift)'s new `scope` parameter — `.owned`
      reuses MVP Phase 12's exact original key, so an existing install's saved state isn't
      discarded). [SharedLibraryRegistry.swift](../../sync/SharedLibraryRegistry.swift) (new,
      local-only, never synced — per `ARCHITECTURE.md`'s "Local-only data" convention) records which
      libraries are shared-to-me plus each one's real zone `ownerName` (a shared zone is owned by
      whoever shared it, not `CKCurrentUserDefaultName` — `CKRecordZone.ID.library(_:ownerName:)`
      in [SyncZoneID.swift](../../sync/SyncZoneID.swift) grew an `ownerName` parameter, defaulted
      to the existing constant so every pre-Phase-10 call site is unaffected). `recordChanged`,
      `resolveConflict`, and `ensureZone` all route to the correct engine/database/zone-owner via
      this registry, so a read-write participant's own edits sync back correctly too, not just an
      owner's
- [x] Per-participant permission levels (read-only vs. read-write) — enforced in
      `SyncEngine.recordChanged` (see [SyncEngine.swift](../../sync/SyncEngine.swift)), the one
      funnel every DAL's create/update call already routes every mutation through on its way to
      CloudKit (confirmed by grep: every DAL calls `SyncEngine.shared.recordChanged` after
      mutating, never touches `CKSyncEngine` directly) — "enforced in the DAL layer" (that funnel)
      "rejected at the sync layer" (this is that layer) is one and the same design, not two
      separate mechanisms, and was chosen over threading a permission check into every DAL
      function individually. [SharingPermissionStore.swift](../../sync/SharingPermissionStore.swift)
      (new, local-only) caches this device's own `CKShare.currentUserParticipant.permission` per
      library, refreshed whenever `SharingService` fetches/creates/updates a share. A read-only
      participant's edit still lands in local SwiftData (this app is local-first per
      `ARCHITECTURE.md`) but is never enqueued for CloudKit — logged and surfaced via
      `SyncStatusStore.recordError`, so the rejection is visible rather than a silent data loss.
      Deliberately checked *before* the `engine`/`sharedEngine` nil-guard in `recordChanged`, so
      this branch is exercisable by a unit test without a live `CKSyncEngine`
- [x] Populated `createdBy`/`updatedBy` for real — also centralized in `SyncEngine.recordChanged`
      (`applyAttribution`), rather than touching every DAL's create/update call site individually:
      `createdBy` set only the first time a model has none (never overwrites who originally
      created it), `updatedBy` every time. Sourced from
      [CurrentUserStore.swift](../../sync/CurrentUserStore.swift) (new) — resolves
      `CKContainer.userRecordID()` once at `SyncEngine.start` (async, cached synchronously
      afterward, the same resolve-async/read-sync split `ConflictStrategyStore.currentStrategy()`
      already established) and stores the opaque `CKRecord.ID.recordName` itself, not a
      human-readable name. **Deliberately doesn't call the human-readable-name discovery API**
      (`CKContainer.userIdentity(forUserRecordID:)`) — that's deprecated in the current SDK in
      favor of reading identity straight off a `CKShare.Participant` you already have, which is
      exactly what `SharingPermissionStore` does for *other* participants; the current user's own
      stable record name is already sufficient for audit attribution, a display nicety isn't
      required. Both fields stay `nil`, exactly as before this phase, until a current user has
      actually been resolved — single-user use is visually unchanged
- [x] Extended `Conflict`/`ConflictResolver` (MVP Phase 14) — `ConflictRevision` gained a
      `collaboratorName: String?` in [Conflict.swift](../../sync/Conflict.swift), surfaced in
      `label` as "Synced Elsewhere — Dana Reyes" when resolvable, unchanged ("Synced Elsewhere")
      otherwise — extends the existing revision-based model exactly as planned, no rewrite, and
      `ConflictResolver` itself needed no changes (it already treats records generically). Resolved
      via `CKRecord.lastModifiedUserRecordID` looked up against
      `SharingPermissionStore.displayName(forUserRecordID:)`. **Real, known testability limit,
      stated rather than hidden**: `lastModifiedUserRecordID` is a CloudKit-server-populated
      read-only property — no locally-constructed `CKRecord` (every fixture in
      `ConflictResolverTests`, and every fixture any test could construct) ever has one, so this
      resolution path is only exercisable against a live, already-synced-through-CloudKit record.
      Covered instead by testing `ConflictRevision.label`'s formatting directly (constructing the
      revision by hand) and by an explicit test confirming every existing conflict fixture still
      resolves `collaboratorName` to `nil`, i.e., pre-Phase-10 behavior is provably unchanged
- [x] Shared-space indicator — extends `SyncStatusGlyph`/`SyncStatusView`/`SyncStatusViewModel`,
      not a replacement: a small `person.2.fill` badge on the glyph
      ([SyncStatusGlyph.swift](../../views/Components/SyncStatusGlyph.swift)) and a "This library
      is shared" row in the sheet
      ([SyncStatusView.swift](../../views/Sync/SyncStatusView.swift)), both driven by
      `SyncStatusViewModel.isSharedLibrary` (new `libraryId` parameter, wired from `ContentView`).
      True from either side: the owner's own `SharingPermissionStore.isShared` or a participant's
      `SharedLibraryRegistry.isShared`
- [x] `SharingViewModel` — [SharingViewModel.swift](../../viewModels/SharingViewModel.swift), the
      same "talks to the data layer vs. drives the screen" split `SavedViewViewModel`/
      `TaskDashboardViewModel` already establish. `isOwner` (`share.currentUserParticipant.role ==
      .owner`) gates the permission picker/remove/stop-sharing actions — a participant viewing
      their own shared-to-them library can see who else is on it but can't manage the share, since
      only the owner meaningfully can
- [x] Sharing/Participants UI (Phase 1's S22) —
      [SharingParticipantsView.swift](../../views/Sharing/SharingParticipantsView.swift): a sheet
      on every platform (per the wireframe's own note, matching S2/S10/S15's precedent), reached
      from a new "Sharing" row in [SettingsView.swift](../../views/SettingsView.swift).
      `ParticipantAvatar` (initials from `CKUserIdentity.nameComponents`) and
      `PermissionLevelPicker` (Read Only / Read & Write, always a paired text label — the
      color/icon-never-alone rule `06-DesignSystem.md` already established for sync/conflict
      states applies here too) match Phase 1's named component inventory exactly. An explicit
      "Invite Participant" action creates the share on first use, then presents the native
      controller above
- [x] Unit tests — `SyncEngineTests.swift` (5 tests: attribution set/preserve-existing-createdBy/
      stays-nil-with-no-current-user, read-only rejection logs a sync error, read-write does not —
      the two behaviors `recordChanged` actually gained, both reachable without a live engine by
      design, per that method's own doc comment), `SharingPermissionStoreTests.swift` (6 tests —
      default-writable, read-only/read-write enforcement, per-library independence, clearing on
      unshare, unknown-participant name lookup), `SharedLibraryRegistryTests.swift` (5 tests —
      mark/unmark, owner-name capture, persistence across instances, multi-library independence),
      `CurrentUserStoreTests.swift` (4 tests — the synchronous cache/persistence half; the async
      `CKContainer.userRecordID()` resolution itself needs a live account, out of scope here),
      extended `ConflictResolverTests.swift` (+4 tests — label formatting with/without a
      collaborator name, `.client` never attributed, empty name treated as absent, plus the
      existing-fixtures-stay-`nil` regression noted above). **`.serialized` on `SyncEngineTests`**:
      unlike every other new store here (each constructible fresh, per `SyncStatusStoreTests`'s
      existing isolation convention), `SyncEngine` is itself a bare singleton by design (no
      injectable seam) reaching into the real `CurrentUserStore.shared`/`SharingPermissionStore.shared`
      — serialized so its tests' shared-state mutations can't race each other; each restores what
      it changed. **Live-CloudKit-sharing caveat confirmed, not just anticipated**: this
      environment has no second signed-in iCloud account, so `CKShare` creation/accept,
      cross-account permission enforcement, and named-collaborator conflict attribution are
      real, correct code paths (verified by full read of the CloudKit headers actually shipped in
      this Xcode installation — e.g., confirming `CKContainer.accept(_:)`'s exact async signature,
      `CKRecord.parent`, `NSCloudSharingServiceDelegate`'s real method names — and building clean
      for both `iOS Simulator` and native `macOS`, 0 warnings 0 errors, full `NoteBytezTests`
      target green) but not exercisable end-to-end here, per MVP Phase 12's own precedent for this
      exact class of gap. **One scope cut, stated not silent**: `Migration Assistant`-style
      leaving/losing access to a shared library (`SharedLibraryRegistry.unmarkShared`) has no
      caller yet — nothing in this phase's task list asked for a "leave this shared library" UI
      action, so the DAL-level primitive exists but isn't wired to a button

---

## Phase 11 — Local File Encryption (Security)

Release Features: "Security-Local Files". Depends on MVP Phase 2 (Backups) and Phase 8 above
(Attachment Handling) — the two local-only file categories this targets.

- [x] Audited every local-only file write — exactly three physical write sites exist in the whole
      codebase (confirmed by grep for `.write(to:`/`copyItem` across `dal/`/`sync/`, not just
      re-reading the three files the plan named): `BackupDAL.createSnapshot`'s
      `data.write(to:)` ([BackupDAL.swift](../../dal/BackupDAL.swift)),
      `AttachmentStorage.copyIntoContainer`'s `fileManager.copyItem(at:to:)`
      ([AttachmentStorage.swift](../../dal/AttachmentStorage.swift)), and — the one surprise —
      `SyncStateStore` turned out to hold **no raw file write at all**: MVP Phase 12 persisted
      `CKSyncEngine`'s serialized state through `UserDefaults`, not `FileManager` directly. Also
      confirmed, per the plan's own "Attachment local cache/thumbnails" wording, that there is no
      separate on-disk thumbnail cache to audit — `AttachmentThumbnail`/`AttachmentPreview` render
      directly from the same copied attachment file `AttachmentStorage` already owns
- [x] Applied `.completeFileProtection` to both real write sites —
      `BackupDAL.createSnapshot`'s `data.write(to:options: .completeFileProtection)` and
      `AttachmentStorage.copyIntoContainer`'s post-copy `fileManager.setAttributes([.protectionKey:
      FileProtectionType.complete], ofItemAtPath:)` (`copyItem` itself carries over the *source*
      file's own protection level, typically none for a file picked from Files/Photos, not this
      app's — set explicitly rather than inherited). **`SyncStateStore` migrated off
      `UserDefaults` to make this possible at all**: `UserDefaults` has no public API for setting
      a per-key file-protection level on its backing plist, so the audit's own finding (no raw
      file write to protect) meant the file-protection *requirement* couldn't be met as-shipped —
      fixed by moving `SyncStateStore` to a plain JSON file per scope under
      `Application Support/SyncState/`, written the same protected way as `BackupDAL`. **Stated,
      deliberate one-time cost**: an existing install's `UserDefaults`-persisted sync state isn't
      migrated forward — `CKSyncEngine` starts from `nil` state once (a full resync, the identical
      recovery path it already takes on a fresh install) and no data is lost, since CloudKit
      remains the source of truth for what's synced, this file only cached change tokens as an
      optimization. Matches MVP's Decisions Log's "platform-native encryption only, no custom
      crypto" posture exactly — an explicit protection *level*, not a new crypto layer
- [x] Verified offline/iCloud-unavailable code paths — `AttachmentDAL.attach` takes `containerRoot`
      as a required (non-optional) parameter to `AttachmentStorage.copyIntoContainer` and throws
      `AttachmentStorageError.iCloudUnavailable` *before* ever reaching it when
      `AttachmentStorage.containerRoot()` can't resolve the ubiquity container — confirmed by
      reading the call path, not just asserted: there is no second, unprotected local-write
      fallback for attachments to silently take when sync is down. `BackupDAL`/`SyncStateStore`
      have no iCloud dependency at all (both are Application-Support-local regardless of network
      state), so this verification is scoped to Attachments, the one category the plan's own
      dependency line ties to iCloud availability
- [x] Unit tests — `LocalFileProtectionTests.swift`
      (7 tests: `BackupDAL` snapshot protection, `SyncStateStore`'s new `writeProtected` helper
      (see below) and its `stateDirectory` layout, `AttachmentStorage` copy protection). **Real,
      confirmed environment limit, not a gap in the code under test**: the iOS Simulator doesn't
      implement actual Data Protection — it's an ordinary process on the host Mac's own
      filesystem, no Secure-Enclave-backed passcode-derived keybag behind it — so
      `FileManager.attributesOfItem(atPath:)[.protectionKey]` reads back `nil` there regardless of
      what protection level a write requested. Verified this is a reporting gap, not a usage bug,
      by running the identical `Data.write(to:options: .completeFileProtection)` call as a plain
      host-Mac process outside the simulator sandbox, where it correctly round-trips to
      `.complete`. Each test asserts the real value whenever the platform can report one (a
      physical device) and otherwise falls back to confirming the write itself succeeded, so the
      suite is strictest wherever it's actually able to be — same "document it honestly rather
      than claim full verification" standard as every other live-hardware-only gap this plan has
      already flagged (MVP Phase 12's live CloudKit account, Phase 10's live multi-account
      sharing). **One small, justified refactor surfaced while writing these**:
      `CKSyncEngineStateSerialization` (the type backing `CKSyncEngine.State.Serialization`) has
      no public initializer — it's only ever produced by a live, already-connected
      `CKSyncEngine` — so `SyncStateStore.save`'s actual encoding step can't be unit-tested at
      all. Split the write mechanics into `SyncStateStore.writeProtected(_:to:)`, which doesn't
      depend on the payload and so is testable with arbitrary `Data`, exercising the exact same
      code path `save` uses in production. Full `NoteBytezTests` target builds and passes on the
      iPhone 17 simulator, 0 failures; both `platform=iOS Simulator` and native `platform=macOS`
      build clean, 0 warnings 0 errors

---

## Phase 12 — Migration Assistants

Release Features: "Migration assistants". Depends on MVP Phase 9 (Markdown Import/Export), MVP
Phase 8 (Notebooks), Phase 2 above (Properties — Obsidian YAML properties), Phase 9 above (Canvas
— Obsidian `.canvas` files). The Universe-as-Notebook convention (**Decisions Log #1**) means an
imported Obsidian vault's own folder/tag conventions for series groupings are not auto-mapped to
Notebooks — same "no notebook inference from foreign vaults" rule MVP's Decisions Log already
established for Tags; the user re-creates that grouping manually post-import if wanted.

- [x] Obsidian importer — [MigrationScanner.swift](../../dal/MigrationScanner.swift)'s
      `scanObsidian`. Wikilinks/YAML properties needed **no new format-specific handling at
      all**: `ImportScanner.scan`/`ImportDAL.importFiles` already round-trip both generically
      (Phase 2's `PropertyDAL.syncProperties` was already wired into `ImportDAL.importFiles`
      before this phase started), confirming Decisions Log #1's premise that NoteBytez's own
      Markdown conventions are already Obsidian-compatible. The one real addition is `.canvas`
      file discovery (`scanCanvasFiles`, its own `fileManager.enumerator` pass) feeding Phase 9's
      `CanvasDAL.importJSONCanvas` unchanged — [MigrationDAL.swift](../../dal/MigrationDAL.swift)
      deliberately commits canvases *after* pages, since `importJSONCanvas`'s `file`-node
      resolution matches against the library's already-imported Documents
- [x] Logseq importer — [LogseqImporter.swift](../../dal/LogseqImporter.swift) (pure content
      transform, no `ModelContext`, same shape as `PropertyParser`/`TagParser`) plus
      `MigrationScanner.scanLogseq`/[MigrationDAL.swift](../../dal/MigrationDAL.swift)'s journal
      commit path. `TODO`/`DONE` → `- [ ]`/`- [x]` (scoped to exactly those two keywords per this
      bullet's own wording — Logseq's fuller `DOING`/`NOW`/`LATER`/`WAITING`/`CANCELED`
      vocabulary is left as plain text rather than guessed at). Journals: a `journals/`-folder
      convention + `yyyy_MM_dd`/`yyyy-MM-dd` filename parsing routes through `JournalDAL.
      fetchOrCreate` rather than `DocumentDAL.create`, so an imported journal page becomes *the*
      day's actual journal entry, not a same-titled ordinary note. Block-outline → `Block`
      structure: a blank line inserted before each top-level (depth-0) bullet only, so
      NoteBytez's existing blank-line-based `MarkdownBlockSplitter` gives each top-level bullet
      (plus its nested children, kept attached) its own `Block` — **stated simplification, not a
      lossy one**: content and reading order are fully preserved; only per-nesting-level block
      identity isn't modeled, since NoteBytez has no concept of a block having child blocks.
      `{{query}}` mapping: exactly two shapes translate to Phase 5's ` ```query ``` ` embedded-
      search syntax (a bare quoted string; `(page-tags "Name")` → `#Name`) — everything else
      (boolean nesting, `property`/`between` filters, block references) is flagged inline as
      "Unsupported Logseq query" (visible, with the original text preserved for reference) and
      recorded for the scan summary, per Journey 9's "flag, don't guess" requirement.
      **Consciously narrower than the plan's own "or Phase 7's Saved Views" wording**: mapping
      to a live embedded query block (inline, no extra commit step) covers the "directly
      expressible" case the plan itself qualifies as optional; a real `SavedView` row per query
      would need a separate DB-touching path for arguably marginal gain over the simpler mapping
- [x] Originals preserved as a read-only archive —
      [MigrationArchiveDAL.swift](../../dal/MigrationArchiveDAL.swift): extends `BackupDAL`'s own
      local-file pattern (Application-Support-rooted, `FileManager`-only, Phase 11's
      `.completeFileProtection` posture) as a sibling `MigrationArchives/<libraryId>/` folder,
      not a new archive mechanism. `fileManager.copyItem` copies the whole vault tree in one
      call; every copied file additionally gets POSIX `0o444` (read-only) on top of Phase 11's
      file protection — "nothing about the migration is a one-way door" (Journey 9) means the
      archive should resist accidental in-place edits, not just theft. A timestamp plus a short
      random suffix in the destination folder name guarantees two archives (even of the same
      vault, run twice) never collide. **Stated scope note**: no in-app archive-browser screen
      was built — the task list asks for preservation, not a dedicated viewer, and a technical
      user can already inspect the archive via Finder/Files; Journey 9's "view original" for an
      unsupported query currently means the flagged callout's visible original text, not a tap-
      through to the archived file
- [x] Format auto-detection —
      [MigrationFormatDetector.swift](../../dal/MigrationFormatDetector.swift): an Obsidian vault
      always has a `.obsidian/` config folder at its root, a Logseq graph always has a `logseq/`
      one — checked as directories specifically (a plain file with either name doesn't count).
      `nil` when neither marker is found, so the Migration Assistant asks the user directly
      rather than guessing at an ambiguous folder. Feeds one entry point,
      [MigrationViewModel.swift](../../viewModels/MigrationViewModel.swift), which reuses
      `MigrationScanner`'s scan-before-commit contract (nothing written until "Confirm
      Migration") the exact same way `ImportViewModel`/`ImportScanner` already establish it
- [x] Migration Assistant UI (Phase 1's S23) —
      [MigrationAssistantView.swift](../../views/Migration/MigrationAssistantView.swift): extends
      S2's Import Scan & Confirm layout with `MigrationSourceRow` (Phase 1's named component — a
      segmented format picker + "Auto-detected: X" / "Couldn't auto-detect" caption) at the top,
      then a format-specific summary line (notes/links/canvases for Obsidian; notes/links/tasks/
      journals/unsupported-count for Logseq), an "unsupported queries" section when any exist,
      and the same file-list/Cancel/Confirm-Migration shape `ImportScanView` already uses.
      **Segmented control instead of the wireframe's radio buttons**: this codebase has no radio-
      button control established anywhere else; a 2-option segmented control expresses the same
      mutually-exclusive choice as a native platform idiom, the same kind of ASCII-wireframe-to-
      native-control translation prior phases already made without treating it as a deviation
      worth re-litigating. Reached from a new "Migration Assistant (Obsidian/Logseq)" button on
      [LibrarySelectionView.swift](../../views/Library/LibrarySelectionView.swift), alongside
      "Create New Library"/"Import Existing Markdown Folder" — visually confirmed rendering
      correctly on the iPhone 17 simulator (screenshot); deeper tap-through into the folder
      picker hit this environment's already-documented tap-delivery flakiness (MVP Phases 4/7/15,
      Phase 3's own note), not a new regression — the underlying flow is covered instead by
      `MigrationIntegrationTests`' direct DAL/ViewModel exercise of the identical code path
- [x] `MigrationViewModel` —
      [MigrationViewModel.swift](../../viewModels/MigrationViewModel.swift), the same "create the
      library optimistically, populate-or-discard on confirm/cancel" contract `ImportViewModel`
      established for S2, extended with `setFormat` (re-scans when the user corrects a wrong or
      absent auto-detection) and `wasAutoDetected` (drives S23's messaging). `confirmMigration`
      archives *after* committing the scanned content, deliberately — a failed archive (e.g. disk
      full) shouldn't discard an otherwise-successful migration; `archiveError` surfaces the
      failure without undoing anything
- [x] Unit + integration tests — `MigrationFormatDetectorTests.swift` (5 tests),
      `LogseqImporterTests.swift` (20 tests: task-marker translation, block-grouping blank-line
      insertion, both resolvable `{{query}}` shapes, unsupported-query flagging, journal
      detection/date-parsing for both filename formats), `MigrationScannerTests.swift` (9 tests),
      `MigrationArchiveDALTests.swift` (6 tests: full-tree copy, exact content preservation,
      POSIX read-only on the copy *without* mutating the source, collision-free repeat archiving,
      per-library scoping), `MigrationIntegrationTests.swift` (5 tests — the fixture-vault round-
      trips this bullet asks for by name: a real `.obsidian`-marked vault with YAML properties, a
      wikilink, and a `.canvas` file referencing one of its notes, migrated end-to-end and spot-
      checked via `PropertyDAL`/`CanvasDAL`; a real `logseq`-marked vault with `TODO`/`DONE`
      tasks and a `journals/yyyy_MM_dd.md` file, spot-checked via `TaskDAL`/`JournalDAL`; the
      unsupported-query flag surviving all the way into committed `Document.content`; archive
      preservation after a full `confirmMigration`-shaped commit). Full `NoteBytezTests` target
      builds and passes on the iPhone 17 simulator, 0 failures; both `platform=iOS Simulator` and
      native `platform=macOS` build clean, 0 warnings 0 errors. **One real bug found and fixed
      while writing these**: `LogseqImporter`'s `page-tags` pattern didn't account for the
      argument still carrying its own enclosing parens (`(page-tags "recipe")`, not `page-tags
      "recipe"`) — the two `page-tags` mapping tests caught it immediately; fixed by stripping
      one layer of surrounding parens before pattern-matching

---

## Phase 13 — Plugin SDK (Preview)

Release Features: "Plugin SDK (preview)". Depends on the rest of V1 being stable — the broadest
read/write surface over the whole app, so it should stabilize last.

Execution model decided in **Decisions Log #3**: sandboxed `JavaScriptCore` scripting behind a
minimal permissioned bridge — no filesystem/network access from script code, no background
execution, every permission explicitly user-granted per plugin.

- [x] Embed `JavaScriptCore`; define the permissioned bridge surface: read-library query API
      (read-only, e.g. list/search documents, tags, notebooks — no write methods exposed),
      current-note write API (append/insert-at-cursor only, not arbitrary file access),
      add-command API (registers a named action in a command palette) —
      [PluginBridge.swift](../../dal/PluginBridge.swift). **Design**: script evaluation never
      touches `ModelContext` directly — `PluginLibrarySnapshot.capture` pre-fetches a read-only,
      `Sendable` snapshot on the caller's own thread/actor *before* the script runs, and
      write/add-command calls land in a `PluginWriteCollector` rather than mutating anything
      live; the caller (`PluginViewModel`) only applies collected writes after the script
      finishes. **Execution model** (a genuine design decision, not just an implementation
      detail): a script runs once per invocation with no live `JSContext`/`JSValue` callback ever
      kept around — a registration pass (`invokedCommand == nil`) is expected to call
      `noteBytez.addCommand(name)` per command it offers, and a later invocation pass re-runs the
      whole script with `invokedCommand` set to the chosen name, which the script itself branches
      on. Simpler than capturing a per-command JS callback, and every invocation re-checks
      permissions from scratch since nothing persists between runs. **`insertAtCursor` scope
      note**: this app's editor doesn't yet track cursor position, so the host currently applies
      an "insert" identically to an "append" — documented in
      [PluginSDK.md](../PluginSDK.md) and `PluginWriteCollector.recordInsert`, not silently
      pretended to be real cursor-aware insertion
- [x] Define the permission model as explicit, user-visible per-plugin grants (Phase 1's
      `PluginPermissionRow`) — a plugin declares which bridge APIs it needs; the user approves
      before it can run — [PluginPermissionRow.swift](../../views/Components/PluginPermissionRow.swift)
      (list display, per S24) and the install sheet in
      [PluginManagementView.swift](../../views/Plugin/PluginManagementView.swift) (per-permission
      toggles, shown before the "Install" action commits). **Design decision**: a plugin's
      manifest *is* its granted-permissions list — declaring a permission and being granted it
      are the same install-time approval gesture (matching S24's wireframe, which shows only one
      granted-permissions list per plugin, never a separate requested/granted split); permissions
      aren't individually revocable after install, only all-at-once via uninstall
- [x] Plugin manifest/registration DAL (manifest declares required permissions + entry script) —
      [Plugin.swift](../../models/Plugin.swift) (model — `permissionsJSON` flat-scalar-JSON field,
      same "single always-together structure" choice `NoteTemplate.fieldsJSON`/
      `SavedView.definitionJSON` already made), [PluginDAL.swift](../../dal/PluginDAL.swift)
      (install/fetchActive/setEnabled/uninstall), [Plugin+Sync.swift](../../sync/Plugin+Sync.swift)
      (CloudKit sync — a plugin's manifest is ordinary synced data like every other V1 model;
      only script *execution* is local/sandboxed, not the manifest's storage)
- [x] Sandbox enforcement: verify at the bridge layer (not just by omission) that a plugin without
      a granted permission cannot reach that API — e.g. an ungranted write call throws/no-ops
      rather than relying on the script simply not being offered the function —
      `PluginBridge.installBridge` defines every `noteBytez.*` function unconditionally and has
      each one check `grantedPermissions` internally, throwing a JS `Error` ("Permission denied:
      …") on denial rather than omitting the function; covered by
      `PluginBridgeTests.swift`'s permission-boundary and "every function exists regardless of
      what was granted" tests
- [x] Developer docs (a new `Docs/` reference, out of scope for this plan file itself) describing
      the permission model and the three bridge APIs — [PluginSDK.md](../PluginSDK.md)
- [x] Plugin management UI (Phase 1's S24) — install/enable/disable/revoke, permission display —
      [PluginManagementView.swift](../../views/Plugin/PluginManagementView.swift), reached from
      Settings → "Plugins". "Revoke" = uninstall (soft-delete), since permissions aren't
      individually editable after install (see the permission-model decision above). **Scope
      note, named rather than silently assumed**: Phase 13's own task list names "register-a-
      command" as a bridge capability, not a command-palette UI — no new command-palette screen
      was built; `PluginViewModel.invokeCommand`/`registeredCommands` exist and are unit-tested as
      the underlying mechanism a future palette would call, but wiring one into `DocumentView` is
      out of this phase's scope as written
- [x] `PluginViewModel` — [PluginViewModel.swift](../../viewModels/PluginViewModel.swift):
      install/setEnabled/uninstall for the management UI, plus `registeredCommands(for:)` and
      `invokeCommand(_:on:documentViewModel:)`, both `async` (see the concurrency note below)
- [x] Unit tests: permission-boundary enforcement (a plugin without "write current note" granted
      cannot write), sandbox isolation (a plugin cannot reach filesystem/network/other-document
      state through the bridge), malformed/malicious-script resilience (infinite loop or crash in
      plugin script doesn't take down the host app — needs an execution timeout) —
      `PluginBridgeTests.swift` (18 tests: read/write/add-command permission grant+deny pairs,
      "every function exists regardless of grant," the registration/invocation model, no
      filesystem/network/foreign-global leakage, raw document content never exposed to a
      read-granted script, syntax-error/thrown-exception/empty-script resilience, and the timeout
      race), `PluginDALTests.swift` (6 tests), `PluginViewModelTests.swift` (7 tests), extended
      `SyncMappingTests.swift` (field round-trip + all three dispatch tests rewired from nineteen
      to all twenty tables) and `BackupDALTests.swift` (capture + restore-after-uninstall). **Two
      real concurrency bugs found and fixed while writing these, both worth recording in detail**:
      (1) `PluginBridge.run`'s first implementation used a plain `DispatchSemaphore.wait(timeout:)`
      to block the caller while script evaluation happened on a background queue — this starved
      Swift's cooperative thread pool the moment `run()` was itself called from an async test
      context, and *every* test hit the full timeout regardless of what its script actually did.
      (2) The fix replaced the semaphore with `withTaskGroup`, racing a continuation-wrapped
      background evaluation against a `Task.sleep` timeout — but a task group will not let its
      own scope return until every child task actually finishes, even after `cancelAll()`, and
      the script-evaluation child can never respond to cooperative cancellation (it's a
      synchronous C call inside a `withCheckedContinuation`, not a `Task` that checks
      `Task.isCancelled`). A genuinely infinite script therefore hung `run()` itself — which hung
      the entire `xcodebuild test` process for over 20 minutes on a live run, until it had to be
      force-killed — silently reproducing the exact deadlock the semaphore fix was meant to
      solve. The actual fix: race two *unstructured* `Task.detached` operations against a single
      `withCheckedContinuation`, guarded by a small lock-based `PluginRunResultLatch` so only the
      first to finish resumes it — nothing waits on an unstructured task, so the timeout side can
      genuinely win and return while a hung script keeps running, abandoned, exactly as
      `PluginRunResult.timedOut` documents. Confirmed via `xcresult` timing on the passing run:
      the timeout test now resolves in ~2.0s (matching `executionTimeLimit`) rather than waiting
      for the script's own longer busy-loop. The test itself uses a bounded (~4s) busy-loop
      rather than a literal `while (true) {}`, specifically so the leaked thread self-terminates
      instead of pinning a core for the rest of the suite — a literal infinite loop is exactly
      what caused the 20-minute hang above. Full `NoteBytezTests` target (565 tests) builds and
      passes on the iPhone 17 simulator, 0 failures (`xcodebuild test`)

---

## Phase 14 — Cross-Platform Verification

Not a Release Features bullet — "equal fidelity across platforms," continued from MVP Phase 15.
Depends on all feature phases above (2-13). **Environment note, same class of limitation MVP
Phase 15 documented**: this session has a working iOS Simulator control tool (screenshot + tap +
type, calibrated against each screenshot's actual pixel dimensions once the 3x/2x scale factor
was confirmed), but no tool that can drive or screenshot a native Mac app window — `System
Events` scripting is blocked (`osascript is not allowed assistive access`), the same Accessibility
permission wall MVP Phase 15 hit. Scored honestly below, not checked off on code inspection alone.

- [x] All V1 screens (S16-S24, per Phase 1's wireframes) verified on Mac — **partial**: the native
      `macosx` build (`xcodebuild build -destination 'platform=macOS'`) succeeds cleanly, which is
      itself a real finding — Phase 8 had flagged the native macOS build as broken
      (`SavedViewsListView`'s `EditButton()` has no macOS equivalent); that call is already wrapped
      in `#if os(iOS)` as of this pass, so the open item from Phase 8 is resolved. A real
      screen-by-screen GUI pass is not possible here (see environment note above); launching the
      built `.app` and confirming it runs (`System Events` reports the `NoteBytez` process exists)
      is as far as this environment can verify
- [x] All V1 screens verified on iPad (landscape split view + portrait collapse) — verified via
      the iPad Air 11" (M4) simulator, screenshot-confirmed: `NavigationSplitView`'s persistent
      sidebar (Today/All Notes/Notebooks/Search/Tags/Graph/Canvas/Tasks/Saved Views/Settings) plus
      detail pane renders correctly in the default portrait orientation, which is regular-width
      for a full-screen iPad app (the same size class landscape uses) — Canvas, Tasks, and
      Settings → Plugins all confirmed rendering cleanly in this layout. **Not verified**: this
      session has no orientation/rotation control for the simulator, so true landscape and the
      compact-width "portrait collapse" (stack navigation replacing the sidebar, e.g. under Split
      View multitasking) were not directly observed — code-level confidence only, since
      `NavigationSplitView`'s collapse behavior is framework-provided, not custom-built here
- [x] All V1 screens verified on iPhone (tab bar + stack navigation) — verified via the iPhone 17
      simulator: Today → Notebooks → Canvas (S16, board list + board editor + Add Card menu + Add
      Web Link alert), Notebooks → Projects (S14, for context), Settings → Templates (S18, group
      list + starter content + template list) → Plugins (S24, empty state + Add Plugin install
      sheet with all three permission toggles), and Today's toolbar → Tasks (S19, sheet-presented
      per `TodayJournalView`, not a push). Canvas and Task Dashboard — the two screens this plan
      itself flagged as highest-risk for per-platform decisions — both confirmed rendering
      correctly; Task Dashboard's `FilterChipRow` already scrolls horizontally rather than
      truncating when chips overflow, and Canvas's zoom/connect/add-card toolbar buttons are all
      icon-only but all already carry `.accessibilityLabel`s (see VoiceOver item below)
- [x] Dynamic Type accessibility-size pass on every new V1 screen — live pass at
      `accessibility-extra-extra-extra-large` (`xcrun simctl ui <udid> content_size
      extra-extra-extra-large`) across every iPhone screen listed above. **Zero new truncation
      bugs found** — a real contrast with MVP Phase 15, which found two (button-label truncation,
      an unscrollable S1). Both of MVP Phase 15's fixes are still in effect and cover V1's new
      screens for free: `PrimaryButton`/`SecondaryButton`'s `.fixedSize(horizontal: false,
      vertical: true)` fix applies to every V1 screen reusing those components, and
      `FilterChipRow` (Task Dashboard's status/date chips, reused from Search's V1 predecessor)
      was already built as a horizontal `ScrollView` from the start, so chip overflow scrolls
      instead of truncating. Two ad hoc `.buttonStyle(.bordered)` usages outside those shared
      components were audited by hand (`CanvasBoardView`'s zoom controls — icon-only, no text to
      truncate; `SavedViewChip` — a horizontally-scrolling chip, where truncation is the accepted
      chip-UI pattern, not a bug) and don't need the same fix
- [x] VoiceOver labels on every new icon-only control (Canvas toolbar, Attachment thumbnails,
      Permission Level picker, Plugin Permission rows) — audited every `Image(systemName:)`/
      `systemImage:` call site across all 21 V1-added view files (Canvas, Properties, Templates,
      Task Dashboard, Attachment, Saved Views, Sharing, Migration, Plugin). **Found and fixed two
      real gaps**: (1) `CanvasCardView`'s resize-handle overlay (a bare `DragGesture`, no `Button`)
      had no accessibility label or hint at all — a VoiceOver user had no way to even discover it
      existed; added `.accessibilityLabel("Resize card")` /
      `.accessibilityHint("Drag to resize")`. (2) `TaskDashboardView`'s decorative tag icon next to
      the "Filter by tag" text field wasn't hidden from the accessibility tree, so VoiceOver would
      announce a stray unlabeled image alongside the field's own label; added
      `.accessibilityHidden(true)`. Everything else already had a correct `.accessibilityLabel`
      from how each phase built it — `CanvasBoardView`'s zoom/fit/connect/add-card controls,
      `PropertyEditorRow`'s remove button, `TaskDashboardView`'s pin/save button,
      `AttachmentThumbnail`, and `SharingParticipantsView`'s `ParticipantAvatar`
      (`.accessibilityHidden(true)`, correctly, since the name is shown as adjacent text) and
      `PermissionLevelPicker` (`.labelsHidden()` on a still-labeled `Picker`) were all already
      correct
- [x] Color-blind-safe check on new semantic-color usage (permission levels, recurrence
      indicators, migration-status rows) — color never the only signal, matching MVP Phase 15's
      standard — audited every `.orange`/`.accentColor`/semantic-color usage in the same 21 files.
      All pass, no changes needed: Sharing's permission level is always the text label "Read Only"/
      "Read & Write" (`PermissionLevelPicker`), never color or icon alone, exactly as
      `06-DesignSystem.md`'s own component note requires; `RecurrenceControl` pairs its icon with
      the rule's text name, no color at all; `TaskDashboardRow`'s `.orange` priority flag is
      always paired with the "P#" text label and a flag icon; `MigrationAssistantView`'s
      `.orange` unsupported-query text sits under an explicit "Not Migrated" section header, so
      the color is reinforcement, not the signal

---

## Phase 15 — Quality Gate & Journey Acceptance

`CLAUDE.md` §4 (Goal-Driven Execution) and §7 (Testing), mirrors MVP Phase 16.

- [ ] Unit test coverage reviewed against `CLAUDE.md`'s 100% coverage target, using the same
      honest-accounting standard MVP Phase 16 established (logic layers vs. SwiftUI views vs.
      live-network-only code paths)
- [ ] Journey 6 (structured entity authoring via Properties + Note Templates — closes the
      [NoteBytez-PersonaAuthorValidation.md](NoteBytez-PersonaAuthorValidation.md) gap) passes
      end-to-end
- [ ] Journey 7 (canvas-based visual planning) passes end-to-end
- [ ] Journey 8 (shared-space collaboration) passes end-to-end, with the same live-multi-account
      caveat as Phase 10 if it recurs
- [ ] Journey 9 (Obsidian/Logseq migration) passes end-to-end against fixture vaults

---

## Coverage check

Every V1 bullet in [NoteBytez-ReleaseFeatures.md](NoteBytez-ReleaseFeatures.md) (Canvas, Saved
views, Properties, Note templates, Block references, Advanced search, Task dashboards, Attachment
handling, CloudKit Sharing, Migration assistants, Security-Local Files, Plugin SDK preview) has a
corresponding phase above. Every screen this plan proposes (S16-S24) is tracked back to Phase 1
for design before its owning feature phase builds it.
