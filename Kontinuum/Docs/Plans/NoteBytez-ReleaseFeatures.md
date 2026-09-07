<!-- NoteBytez-ReleaseFeatures.md -->
<!--
  Feature breakdown for the NoteBytez roadmap, derived from NoteBytez20260813-Research.md §8
  and the linked Obsidian/Logseq how-to guides. Each research roadmap scope tag is expanded into
  distinct, buildable features. Items marked [OPEN] are unresolved by the research doc and need
  a decision — see "Decisions Log" at the bottom.
-->

# NoteBytez Release Features

Source: [NoteBytez20260813-Research.md](NoteBytez20260813-Research.md) §8 Roadmap, expanded into concrete features.

## MVP

**Goal:** Replace Apple Notes for capture and Obsidian/Logseq for core PKM, without a proprietary-only store.

- **Platform** — Native SwiftUI apps: iPhone, iPad, Mac
- **Local library**
  - Local-first storage engine (SwiftData/Core Data) as the interaction source of truth
  - Encryption at rest via platform-native mechanisms only: iOS/macOS Data Protection for the local store, CloudKit's own server-side encryption for synced data — no custom crypto layer
  - Library creation and selection
- **Markdown import/export**
  - Import plain `.md` files into a library
  - Per-note export to Markdown
  - Full library export (bulk Markdown)
  - Notebook membership round-trips via a `notebooks:` YAML frontmatter list (exact Notebook names, list-valued since membership is many-to-many) — this is the field NoteBytez itself reads back on import
  - Each Notebook membership also emits a kebab-cased `#notebook/<notebook-name>` tag, appended inline to the document body (not folded into an existing frontmatter `tags:` list, to avoid textually rewriting a user-authored one) — Obsidian/Logseq both support nested tags natively and treat inline/frontmatter tags identically, so this gives their users a working, zero-config way to browse "everything in this notebook" without knowing NoteBytez exists. Write-only: this synthetic tag is never read back in as a real `DocumentTag`, and never used to infer Notebooks from a foreign vault's own tagging conventions on import (see Decisions Log)
- **Documents + stable blocks**
  - Document model backed by Markdown
  - Block model with stable UUID and human-readable anchor
  - Standard Markdown formatting: headings, bold/italic, lists, blockquotes, code blocks
  - External links: `[text](https://...)` rendered as tappable/clickable, opens in system browser — no in-app preview/embed (that's V1 Attachment handling territory)
- **Backlinks**
  - `[[wikilink]]` parsing with autocomplete
  - Backlinks pane on each note
  - Links auto-update on note rename
- **Tagging**
  - Inline `#tag` parsing (flat, no nesting) plus YAML frontmatter `tags:` list
  - Tag data model, many-to-many with documents
  - App-level canonicalization (case-fold, dedupe on sync merge) — CloudKit disallows `.unique`, so this replaces a schema constraint
  - Tag browser: list all tags in library, jump to tagged notes
  - Backs the "search by tag" capability under Exact search, below
- **Daily journal**
  - Auto-created "today" journal page
  - Previous/next day navigation
  - Basic journal template
- **Notebooks**
  - `Notebook` model: named, user-created container for a focused effort (e.g. a book series, a project)
  - `DocumentNotebook` join model (many-to-many, foreign-key-by-UUID) — a Document can belong to zero, one, or several Notebooks, same join pattern as Tagging's `DocumentTag`
  - Notebook browser: list all notebooks in library, jump to a notebook's documents
  - No nesting/sub-notebooks in MVP (flat, one level)
  - Markdown representation: `notebooks:` frontmatter list (round-trip) plus a synthetic nested tag on export (Obsidian/Logseq portability) — see Markdown import/export, above
- **Promote to Notebook**
  - Turn a Journal block (or the current journal entry) into a new Document, filed into a chosen or newly-named Notebook
  - Auto-inserts a `[[wikilink]]` back to the originating journal entry, so the trail from raw idea to developed entry isn't lost
  - Uses existing wikilink/backlink machinery — no new linking mechanism, just an authoring shortcut
- **Basic tasks**
  - Markdown checkbox syntax (`- [ ]` / `- [x]`)
  - Single-state toggle (open/done)
  - Tasks visible and greppable within notes
  - Data model includes due-date and priority fields (unused by MVP UI, populated starting V1 — avoids a CloudKit schema migration)
- **Exact search**
  - Full-text search (FTS) across the library — implemented as scan-on-demand (title + content, relevance-ranked) rather than a persisted index, same MVP-scale rationale as Backlinks
  - Search by tag and file/path — "path" resolves to title search; Documents have no folder/path concept, so a title is the closest thing one has (see Decisions Log)
  - Quick Switcher for fast note jump — reuses the same fuzzy-match heuristic as wikilink autocomplete
- **Simple graph**
  - Local graph view: current note + direct links only
  - No filters, forces, or clustering (that's V1/Advanced)
  - **Delivered ([NoteBytez20260829v2-Enhancements.md](NoteBytez20260829v2-Enhancements.md) Workstream A):** a "Force" mode alongside the original radial layout — hand-rolled Fruchterman-Reingold layout (no third-party physics dependency), drag-to-pin, node-type/tag filters, and filtered force views save as a `SavedView`
- **CloudKit private sync**
  - CKSyncEngine wiring against the private database
  - Single container (`iCloud.com.g9Consulting.Kontinuum`); one custom `CKRecordZone` per library — default zone unused (can't be shared, mixes library boundaries)
  - Root "Library" record per zone; documents/blocks/tags/links/tasks chain to it via parent references, so V1 hierarchical `CKShare` sharing needs no re-parenting later
  - Record IDs reuse the model's existing `{model}Id` UUID as `CKRecord.ID.recordName` — no separate identity mapping
  - Single-user sync only in MVP (private database only); V1 shared database support reuses this same engine, not a new one
- **Visible sync log**
  - Sync status indicator, last-synced timestamp, error surfacing
  - Manual "Sync now"
- **Backups**
  - Local snapshot before risky operations (e.g. bulk import, merge)
  - Restore from backup
- **Conflict handling (user-selectable strategy)**
  - Settings toggle between three strategies: Keep All Versions (user resolves manually), Last-Write-Wins + Conflict Banner, Markdown Diff-Merge (diff-match-patch style for Markdown, last-write-wins for non-text)
  - Note: this means MVP ships all three resolution engines, not one default — larger MVP scope than a single strategy, but avoids relitigating this later
  - Scoped to single-user (own-device) conflicts in MVP; strategies are defined on a revision/version concept rather than a device concept, so V1 multi-user conflicts extend this engine rather than replacing it — attributing versions to a named collaborator is a V1 UI decision, not an architecture change

## Version 1

**Goal:** Feel simpler than Obsidian and safer than Logseq for Apple-first users.

- **Canvas**
  - Infinite 2D canvas with note/media/web cards
  - Labeled connectors, groups, pan/zoom
  - Export/import via JSON Canvas format
  - **Delivered ([NoteBytez20260829v2-Enhancements.md](NoteBytez20260829v2-Enhancements.md) Workstream C):** a board can bind to a note, tracking that note's direct-link neighborhood live (links → canvas, read-mostly — the canvas never writes layout back into links); drawing a connector between two bound note cards offers to create the underlying `[[link]]` instead of a bare visual line
- **Saved views**
  - Save a filtered search or task query as a named, pinned view
- **Properties**
  - Typed metadata: text, number, date, checkbox, list — stored as frontmatter
  - Search/filter by property
- **Note templates**
  - `TemplateGroup` model: named, user-owned bundle of templates for a domain of work (e.g. "Fiction Writing", "Wedding Planning", "Photography Client Work")
  - `NoteTemplate` model: named preset that pre-fills a document's Properties fields for a given entity type (e.g. Character, Location, Vendor); belongs to exactly one TemplateGroup (`templateGroupId` FK)
  - `NotebookTemplateGroup` join model (many-to-many, same pattern as `DocumentNotebook`) — attaches a TemplateGroup to one or more Notebooks, so a group built once (e.g. "Fiction Writing") is reused across every new book-series Notebook rather than rebuilt per project
  - `JournalTemplateGroup` join model (many-to-many, library-scoped since Journal has no container model) — attaches TemplateGroups directly to a library's journal, for templates meant for daily-capture use (e.g. "Morning Pages", "Idea Capture") rather than a specific project
  - Template picker scoping: inside a Notebook, shows only that Notebook's attached group(s); in the Journal, shows only the library's attached journal group(s); a Document belonging to neither falls back to every template in the library, ungrouped
  - Applied at note creation; existing notes can have a template's fields applied after the fact
  - User-defined — NoteBytez ships no built-in entity types in the schema or app logic. A small set of example TemplateGroups (Author/Fiction Writing, Wedding Planning, Photography Client Work) ship as fully editable/deletable starter content, not hardcoded behavior
  - This is the mechanism for structured, cross-referenceable entity types (see [NoteBytez-PersonaAuthorValidation.md](NoteBytez-PersonaAuthorValidation.md)) without a proprietary schema layer
  - **Delivered ([NoteBytez20260824v1-Templates.md](NoteBytez20260824v1-Templates.md)):** `NoteTemplate.bodyTemplate` (Markdown scaffold + `- [ ]` checklists, not just Property fields); a **Template Gallery** of 16 bundled knowledge-management role packs (Software Engineering, Project Management, People Ops, Legal Operations, …) plus a first-run role picker; versioned packs with non-destructive "Update available". The 3 creative starters are now the same bundled-resource format. English-only pending [NoteBytez20260823v2](NoteBytez20260823v2-MultiLanguage.md)
- **Block references**
  - `((blockId))` reference syntax resolving to a specific block regardless of which document contains it
  - Block-level backlinks — extends MVP's document-level backlinks pane down to block granularity
  - Static reference only: inserts a link/preview, not a live-updating copy (see Advanced: Live block transclusion)
  - Maintained `blockId → document` index in the DAL (CloudKit provides no secondary index)
- **Advanced search**
  - Boolean operators, exact phrase, negation, regex — apply across content, tags, and file/path (e.g. `#character AND #act2 NOT #resolved`), not just note text
  - Embedded search-result blocks
- **Task dashboards**
  - Cross-note task queries
  - Due dates, recurring tasks, priority markers
  - Filter by status/date/tag
- **Attachment handling**
  - iCloud Documents / File Provider–backed attachments
  - Image and PDF embedding/preview
- **CloudKit Sharing**
  - Shared spaces with invited participants
  - Per-participant permission levels
- **Migration assistants**
  - Obsidian importer: wikilinks, YAML properties, Canvas files
  - Logseq importer: blocks, journals, tasks, common query patterns
  - Originals preserved as read-only archive
- **Security-Local Files**
  - Any local files that store information when the iCloud storate is not avaliable, must be encrypted to protect the users information.
- **Plugin SDK (preview)**
  - Permissioned plugin API: read library, write current note, add command
  - Developer docs + sandboxed dev environment

## Advanced

**Goal:** Differentiate on intelligence, reliability, and Apple-native speed — not feature-checklist bloat.

- **Local semantic index** — on-device embeddings, semantic/vector search
- **AI research assistant** — scoped chat, citations to source blocks, redact-before-send, prompt templates, user-controlled cloud model connectors
- **Smart resurfacing** — AI-generated "forgotten context," weekly review digest, orphan/stale-note detection
- **Graph insights** — answerable views: orphans, stale projects, notes-with-tasks, clusters
- **Nested tags** — hierarchical `#parent/child` tags, tree/breadcrumb browser, graph filter integration
- **Collaboration presence** — live cursors/presence indicators within shared spaces
- **CRDT block merge** — per-block CRDT-like merge for concurrent edits, with side-by-side diff fallback
- **Live block transclusion** — embeds that re-render on source-block edit; cycle detection; editable-in-place semantics decided
  - **Delivered ([NoteBytez20260829v2-Enhancements.md](NoteBytez20260829v2-Enhancements.md) Workstream B):** a `!((anchor))` embed is now editable in place — the edit splices back into the *source* document's content (never the derived block cache) and reclaims the same block identity on the source's next resync. Editable-in-place semantics decided as optimistic, last-write-wins (no merge prompt); a lightweight "Undo Edit" mitigates the lack of a full cross-document undo stack
- **Team/family shared spaces** — multi-user spaces beyond basic CloudKit Sharing, roles/permissions at scale
- **Public publishing** — publish selected notes/spaces to a public URL
- **File Provider extension** — full Files.app integration; third-party apps can read library files
- **Automation/Shortcuts integration** — Siri Shortcuts actions, Spotlight indexing, Share Sheet capture

## Decisions Log

- **MVP platforms:** iPhone + iPad + Mac.
- **Local encryption:** rely on platform-native encryption only — Data Protection locally, CloudKit server-side encryption for synced data. No custom crypto layer.
- **CloudKit container:** single container, `iCloud.com.g9Consulting.Kontinuum`.
- **Zone strategy:** one custom `CKRecordZone` per library, root Library record per zone, default zone unused — sets up V1 hierarchical sharing without a schema change.
- **Conflict handling:** user-selectable strategy (Keep All Versions / Last-Write-Wins + Banner / Markdown Diff-Merge), shipped in MVP, single-user scope only. Built on a revision concept so V1 can extend to multi-user without rearchitecting.
- **Task data model:** due-date and priority fields present in MVP schema, surfaced in UI starting V1.
- **Tagging:** flat only in MVP/V1 (inline `#tag` + frontmatter list); nested tags deferred to Advanced.
- **Block linking:** static block references ship in V1; live transclusion deferred to Advanced. Advanced's AI research assistant citations depend on V1 block references existing first.
- **Entity modeling:** no first-class typed models (no built-in Character/Location/Item schema). Structured, cross-referenceable entity types are built by users from generic Documents + Properties + Note templates (V1), not a proprietary schema layer. See [NoteBytez-PersonaAuthorValidation.md](NoteBytez-PersonaAuthorValidation.md).
- **Tag uniqueness:** enforced at app level (case-fold + dedupe on sync merge), not schema level — CloudKit disallows `.unique`.
- **Notebook membership:** many-to-many via `DocumentNotebook` join model, not a `notebookId` FK on Document — a Document (e.g. a Technology entity reused across two book series) isn't locked to one project.
- **Journal has no container model.** It's a single ongoing per-library stream (Documents flagged `isJournalEntry`), asymmetric with Notebooks, which are plural, user-named, and created on demand. Journal and Notebook documents interlink freely — `BacklinkDAL`/`WikilinkParser` already resolve library-wide, not container-scoped, so no changes needed there.
- **Note template grouping:** `NoteTemplate` belongs to exactly one `TemplateGroup` (simple FK, not many-to-many) — a template is authored for one domain; a shared field set becomes its own template rather than joining multiple groups. TemplateGroups attach to Notebooks (`NotebookTemplateGroup`) and to a library's Journal (`JournalTemplateGroup`) via separate many-to-many joins, so the same group can back several Notebooks (or the Journal) at once, and a Notebook/Journal can draw on more than one group.
- **Notebook Markdown representation:** `notebooks:` frontmatter list is the sole field NoteBytez reads on import — authoritative, exact-name round-trip. The export-time `#notebook/<kebab-name>` tag (appended to the body, not merged into an existing `tags:` list) is a one-way portability courtesy for Obsidian/Logseq (their nested-tag support), not a second import path — avoids two sources of truth disagreeing after a file is hand-edited outside NoteBytez, and avoids rewriting a user's own frontmatter text.
- **No notebook inference from foreign vaults:** importing a vault that wasn't previously exported by NoteBytez (e.g. one that already uses a `#project/X` convention) does not auto-create Notebooks from existing tags. Keeps the import parser unambiguous and avoids surprising the user with notebooks they didn't ask for; may revisit as a Migration Assistant (V1) feature.
- **"Path" search scope:** resolved as title search, not a persisted file-path field. NoteBytez has no folder hierarchy in MVP (Documents are flat within a Library), so there is no real "path" to filter by — a title is the closest analog. Revisit only if a genuine folder/path concept is ever added; don't add a `sourcePath` field just to serve this filter.
- **No persisted FTS index:** search (content, tag, and quick-switcher) is computed on demand by scanning active documents, matching `BacklinkDAL`'s established MVP-scale rationale — avoids maintaining a second index's invalidation rules prematurely.
- **Starter TemplateGroups:** a small number of example groups (Author/Fiction Writing, Wedding Planning, Photography Client Work) ship as editable seed data in V1, so new users see the concept populated rather than starting from a blank template list. Content only, not schema — keeps the "no built-in entity types" architectural principle intact; users can edit or delete every shipped template.
