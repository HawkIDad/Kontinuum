<!-- 03-FeatureMarriage.md -->
<!--
  Part of the NoteBytez UIUX Research deliverable set. See ../../../NoteBytez20260813-UIUX-Research.md for scope/plan.
  Every bullet below is copied from the "MVP" section of NoteBytez-ReleaseFeatures.md. None are added or dropped.
-->

# Feature / Function to User Marriage

Maps every MVP feature bullet from [NoteBytez-ReleaseFeatures.md](../NoteBytez-ReleaseFeatures.md) to the persona need(s) it solves. Personas: **A** = Obsidian Archivist, **O** = Logseq Outliner, **M** = Dual-Tool Migrator ([01-Personas.md](01-Personas.md)). Journeys: **J1–J5** ([02-Journeys.md](02-Journeys.md)).

| Feature (MVP) | Need it solves | Persona(s) | Journey |
|---|---|---|---|
| **Platform** — Native SwiftUI: iPhone, iPad, Mac | No compromise between capture device (phone) and deep-work device (desktop) | A, O, M | J2 |
| Local-first storage engine as interaction source of truth | Works with no network dependency — matches Obsidian's local-first trust model | A, O, M | J1 |
| Encryption at rest via platform-native mechanisms (Data Protection locally, CloudKit encryption for synced data) | Data protected using the same OS-level protections Apple already secures the device with — no proprietary crypto scheme to trust or audit | A, O, M | — |
| Library creation and selection | Supports the archivist's single-large-library model and the migrator's need to keep libraries separate during transition | A, M | J1 |
| Import plain `.md` files into a library | Direct migration path from Obsidian without re-typing | A, M | J1 |
| Per-note export to Markdown | Escape hatch — proves no lock-in, one note at a time | A, M | J1 |
| Full library export (bulk Markdown) | Escape hatch at library scale — the ultimate trust test | A, M | J1 |
| Notebook membership round-trips via `notebooks:` frontmatter | No-lock-in extends to project organization, not just content/tags/links — a full export doesn't quietly drop which notebook a note belonged to | A, M | — |
| Synthetic `notebook/<name>` nested tag on export | Obsidian/Logseq both read nested tags natively, so notebook organization is immediately usable outside NoteBytez too, not just present as inert data the other tool can't interpret | A, O, M | — |
| Document model backed by Markdown | Preserves Obsidian's file-first durability | A, M | J1 |
| Block model with stable UUID + human-readable anchor | Preserves Logseq's block-level addressability inside a file-first model | O, M | J1, J4 |
| Standard Markdown formatting (headings, bold/italic, lists, blockquotes, code blocks) | Baseline authoring parity with both source tools — nothing regresses on migration | A, O, M | J1, J2 |
| `[[wikilink]]` parsing with autocomplete | Fast linking without breaking capture flow | A, O, M | J2 |
| Backlinks pane on each note | Surfaces connections the user forgot they made — core resurfacing tool | A, O, M | J4 |
| Links auto-update on note rename | Prevents the "renamed and broke everything" fear that erodes trust | A, M | — |
| Inline `#tag` parsing (flat) + YAML frontmatter `tags:` list | Fast categorization without leaving the flow — matches how tag-first organizers already work in Obsidian/Logseq | A, O, M | J2 |
| Tag data model, many-to-many with documents | Protects future nested-tag support (Advanced tier) without a schema migration later | O | — |
| App-level tag canonicalization (case-fold, dedupe on sync merge) | Prevents fragmented duplicate tags (`#Project` vs `#project`) from silently splitting the user's own organization system | A, O, M | — |
| Tag browser: list all tags in library, jump to tagged notes | Lets tag-first organizers browse by their own taxonomy instead of remembering titles | A, O | J4 |
| Auto-created "today" journal page | Removes "where does this go" friction — Logseq's core capture advantage | O, M | J2 |
| Previous/next day navigation | Lets the user review recent open threads without search | O | J2 |
| Basic journal template | Reduces blank-page friction on first open each day | O | J2 |
| `Notebook` model — named, user-created container for a focused effort | Recreates the Archivist/Migrator's "durable reference vault" concept inside NoteBytez, distinct from daily capture | A, M | J5 |
| `DocumentNotebook` join (many-to-many) | A Document isn't locked into one project — matches how power users' notes already serve more than one context | A, O, M | — |
| Notebook browser: list notebooks, jump to a notebook's documents | Structured entry point into project work, parallel to how Today/Journal is the entry point for capture | A, M | J5 |
| Promote to Notebook: journal block → new Document in a Notebook, with auto-backlink | Lets the Outliner keep capturing without deciding where something belongs, then turn a good idea into structured project work without retyping or losing the trail back to its origin | O, M | J5 |
| Markdown checkbox syntax (`- [ ]` / `- [x]`) | Tasks live inside notes, not a separate silo — matches both source tools | A, O, M | J2 |
| Single-state toggle (open/done) | Immediate, unambiguous task state — no config needed on day one | O | J2 |
| Tasks visible and greppable within notes | Tasks stay searchable/exportable, reinforcing no-lock-in | A, O | J2 |
| Task data model includes due-date/priority (unused in MVP UI) | Protects the Outliner's future workflow (LATER/NOW-style) without a schema migration later | O | — |
| Full-text search (FTS) across the library | Primary resurfacing tool when links/graph don't help | A, O, M | J4 |
| Search by tag and file/path | Matches how users who tag-first (rather than title-first) actually organize | A, O | J4 |
| Quick Switcher for fast note jump | Keyboard-first navigation the Archivist and Migrator expect from Obsidian | A, M | J4 |
| Local graph view: current note + direct links only | Lightweight resurfacing/orientation without the complexity Logseq/Obsidian power users say they don't trust anyway | A, O | J4 |
| No filters/forces/clustering (explicit MVP limit) | Sets correct expectations — graph is orientation, not analysis, in MVP | A, O | J4 |
| CKSyncEngine wiring against the private database | Notes available across all owned devices without manual file-syncing tools (Syncthing, etc.) that caused the Outliner's past data loss | O, M | J2, J3 |
| Single-user sync only (no sharing yet) | Correctly scopes trust-building to personal data before introducing multi-user risk | O | J3 |
| Sync status indicator, last-synced timestamp, error surfacing | Directly answers the Outliner's core fear: "is my data safe right now?" | O, M | J3 |
| Manual "Sync now" | Gives the anxious user a way to force certainty instead of waiting | O | J3 |
| Local snapshot before risky operations (bulk import, merge) | Safety net for the Archivist's high-scrutiny first import | A, M | J1 |
| Restore from backup | Recovery path if a conflict resolution or import goes wrong | A, O, M | J1, J3 |
| Conflict handling: user-selectable strategy (Keep All / Last-Write-Wins+Banner / Diff-Merge) | Directly resolves the Outliner's documented fear of silent data loss during sync | O, M | J3 |

## Coverage check

Every MVP bullet in [NoteBytez-ReleaseFeatures.md](../NoteBytez-ReleaseFeatures.md) appears exactly once above. No V1/Advanced feature is included. No persona need from [01-Personas.md](01-Personas.md) is left unaddressed:

- Archivist → portability/no-lock-in: covered by import/export bullets, backups.
- Outliner → trustworthy sync/no data loss: covered by CloudKit sync, sync log, conflict handling, backups.
- Dual-Tool Migrator → one tool instead of two: covered by documents+blocks, wikilinks+backlinks, tagging, journal, tasks, and now Notebooks (the Obsidian-vault half) sitting alongside Journal (the Logseq-journal half) in one library.

---

## Version 1

Every bullet below is copied from the "Version 1" section of [NoteBytez-ReleaseFeatures.md](../NoteBytez-ReleaseFeatures.md). None are added or dropped. Adds a fourth persona code: **U** = Universe Architect ([01-Personas.md](01-Personas.md) §4). Journeys: **J6–J9** ([02-Journeys.md](02-Journeys.md)); earlier journeys (J1–J5) are cited where a V1 feature directly extends an MVP one.

| Feature (V1) | Need it solves | Persona(s) | Journey |
|---|---|---|---|
| Infinite 2D canvas with note/media/web cards | Gives spatial, non-linear thinkers a home outside pure Markdown — matches Obsidian's own most-loved visual layer, not a NoteBytez-only concept | A, U | J7 |
| Labeled connectors, groups, pan/zoom | Lets relationships between plot threads/suspects/entities be seen, not just linked | A, U | J7 |
| Export/import via JSON Canvas format | Escape hatch for visual work — same no-lock-in promise as Markdown export | A | J7 |
| Saved views: pin a filtered search or task query | Turns a one-off compound question ("Act 2 antagonists") into a reusable, one-tap view instead of retyping it | U, O | J6 |
| Properties: typed metadata (text/number/date/checkbox/list) | Gives structured, filterable fields without a proprietary built-in schema — the Universe Architect's core unmet MVP need | U | J6 |
| Search/filter by property | Makes typed fields actually queryable, not just decorative | U | J6 |
| `TemplateGroup`/`NoteTemplate` models | Reusable field sets for a domain of work (Character, Location, Vendor) built once, applied repeatedly | U | J6 |
| Template picker scoping (Notebook / Journal / fallback) | Templates surface only where relevant instead of one long undifferentiated list | U | J6 |
| Apply-at-creation and apply-after-the-fact | New notes start structured; older notes aren't stranded outside the system once templates exist | U | J6 |
| Starter TemplateGroups (Fiction Writing, Wedding Planning, Photography) | New users see the concept already populated instead of starting from a blank template list | U | J6 |
| `((blockId))` block references + block-level backlinks | Extends Obsidian/Logseq's own valued feature (block addressability) down past the document level MVP already covers | A, O | — |
| Advanced search: boolean operators, exact phrase, negation, regex, across content/tags/path | Answers compound questions ("`#character AND #act2 NOT #resolved`") flat tag browsing in MVP can't | U, A | J6 |
| Embedded search-result blocks | A live query result can live inside a note itself, not just a separate search screen | A, U | — |
| Cross-note task queries, due dates, recurring tasks, priority | Matches Logseq's built-in LATER/NOW task workflow the Outliner already expects, surfaced for the first time (fields reserved since MVP) | O | — |
| Filter by status/date/tag | Task Dashboards become genuinely queryable, not just a checklist per note | O | — |
| iCloud Documents / File Provider attachments | Notes stop being text-only — matches Obsidian's own image/PDF embedding | A, U | — |
| Image and PDF embed/preview | Research material (reference photos, PDFs) lives next to the notes about it | A, U | J7 |
| `CKShare` per Library zone, participant invite/accept | Collaboration becomes possible without a second sync system or a new trust model | A, M | J8 |
| Per-participant permission levels (read-only / read-write) | Owner keeps control over what a collaborator can change | A, M | J8 |
| Conflict attribution extended to a named collaborator | Multi-user conflicts inherit the same "never silently lose an edit" guarantee MVP already earned for single-user conflicts | O, M | J8 |
| Obsidian importer (wikilinks, YAML properties, `.canvas` files) | Format-aware migration beats MVP's generic Markdown import for a deliberate, full-commitment move | M, A | J9 |
| Logseq importer (blocks, journals, tasks, query patterns) | Same trust-building for the Logseq half of the Dual-Tool Migrator's old setup | M, O | J9 |
| Originals preserved as read-only archive | Migration is never a one-way door — same principle as MVP's Backup-before-import | M | J9 |
| Local file encryption beyond default Data Protection (Security-Local Files) | Closes the one local-only gap (backups, attachment cache) MVP's platform-native-encryption posture didn't yet cover explicitly | A, O, M | — |
| Plugin SDK preview: sandboxed permissioned API (read library, write current note, add command) | Answers the Archivist's documented MVP-era complaint that Obsidian's advanced workflows require third-party plugins, without recreating Obsidian's unrestricted-mutation risk | A | — |

### Coverage check (Version 1)

Every V1 bullet in [NoteBytez-ReleaseFeatures.md](../NoteBytez-ReleaseFeatures.md) §Version 1 appears exactly once above. No Advanced-tier feature is included. The Universe Architect's need from [01-Personas.md](01-Personas.md) §4 — structured, filterable entity modeling — is fully addressed by Properties + Note templates (J6); the other three personas' MVP needs (portability, trustworthy sync, one tool instead of two) extend naturally into Canvas/Sharing/Migration without requiring new needs to be invented for them.
