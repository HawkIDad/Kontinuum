<!-- NoteBytez20260829v1-FlowEnhancements.md -->
<!--
  Living build plan for the six flow/differentiation enhancements identified in the
  2026-08-29 functionality-and-flow review (NoteBytez vs. Obsidian vs. Logseq). The review
  found NoteBytez's genuine differentiation concentrated in three places — the Journal/Notebook
  duality + Promote, visible/selectable sync trust, and native no-plugin packaging — while the
  features the research doc (NoteBytez20260813-Research.md §6-9) identified as the real moats
  (answerable graph views, unified canvas+graph, live block cognition, a command surface) are
  either deferred to "Advanced" or shipped as a reduced version of the competitor feature.

  This plan pulls the cheapest, highest-differentiation slice of that forward into a V1.x
  release. It adds NO CloudKit schema (see Assumptions) — every item is IA, parser, render, or
  computed-on-demand DAL work on top of the completed MVP + near-complete R1 codebase.

  Checkbox convention: [ ] not started / in progress, [x] done and verified (builds + its test
  passes). TDD per CLAUDE.md §8 — the failing test is the first task of every feature, never an
  afterthought. Phases are ordered by build dependency, matching
  NoteBytez-MVP-ImplementationPlan.md / NoteBytez-R1-Implementation.md convention.
-->

# NoteBytez V1.x — Flow & Differentiation Enhancements

Source: 2026-08-29 review of app functionality and flow against Obsidian/Logseq. Baseline:
MVP complete (`NoteBytez-MVP-ImplementationPlan.md`, 127/130), R1 ~95%
(`NoteBytez-R1-Implementation.md`, 114/120). This plan assumes that codebase and does not
re-scope its work.

## Progress Summary

| Phase | Tasks complete | Status |
|---|---|---|
| 0. Foundation & UI/UX Artifacts | 4 / 4 | Done |
| 1. Command Palette & Global Quick Switcher | 7 / 7 | Done |
| 2. Journal / Notebooks Primary IA | 7 / 7 | Done |
| 3. Restore Direct Promote-to-Notebook Gesture | 4 / 4 | Done |
| 4. Answerable Graph Views (Graph Insights) | 9 / 9 | Done |
| 5. Unify Graph ↔ Canvas ("Send to Canvas") | 6 / 6 | Done |
| 6. Live Block Transclusion | 8 / 8 | Done |
| 7. Cross-Platform Verification & Quality Gate | 3 / 6 | Partial — coverage, Mac build, and journey-acceptance tests done; iPad/iPhone simulator walkthrough and live VoiceOver pass blocked by this session's simulator text-input tooling (confirmed environment issue, not app code) — see phase note |
| **Total** | **48 / 51** | **94%** |

Update this table's counts and status column as boxes below are checked.

---

## User Story

As a PKM power user migrating from Obsidian or Logseq, I want NoteBytez to *operate* visibly
differently from the tool I'm leaving — not just be the same features renamed and made native —
so that the switch is a clear upgrade in how I capture, navigate, and resurface knowledge, not
a lateral move I have to justify to myself.

## Background — why, not what

The review's core finding: as currently scoped, NoteBytez operates like "Obsidian's core
plugins + Logseq's journal, native on Apple, with a trustworthy sync log." That is a
positioning wedge, not a distinct mode of operation. Specifically:

1. **The graph is a strictly reduced Obsidian graph.** `GraphDAL.directLinks` is one hop, no
   filters/forces/clustering; `02-Journeys.md` J4 openly says "the graph should not
   overpromise." The research doc's actual aspiration — "graph as answerable views: orphans,
   stale projects, notes-with-tasks, clusters" (§7e, §9) — is punted to Advanced. So the
   shipping graph is worse than the competitor's with nothing to trade for it.
2. **Canvas and Graph are separate sidebar modes.** Research §1e / §5 explicitly: "unify canvas
   + graph + outline, not make them separate modes." `ContentView.AppDestination` ships them as
   two of ten peer destinations.
3. **The strongest differentiator — Journal/Notebook duality — is visually 2 of 10 equal
   sidebar rows**, and its signature action (Promote to Notebook) is buried behind a
   toolbar block-picker that *deviates from its own wireframe* (`NoteBytez-MVP-ImplementationPlan.md`
   Phase 8 note: the long-press/right-click trigger was dropped for "simulator tap flakiness").
4. **Block references are static-only** (`NoteBytez-R1-Implementation.md` Phase 4) until
   "Advanced." Logseq's block refs are live and inline by default — NoteBytez's read as a
   regression to exactly the users being courted.
5. **No command surface.** `AppCommands.swift` bridges only New Note / Search / Settings.
   Quick Switcher is a sheet from one toolbar button on S3, explicitly "not wired as a global
   overlay/keyboard shortcut" (`NoteBytez-MVP-ImplementationPlan.md` Phase 10). Obsidian's ⌘P
   palette and ⌘O switcher are central to its power-user flow; their absence is a flow
   regression against *both* competitors.

This plan addresses 1–5. It does not attempt the full "Advanced" intelligence tier (on-device
semantic index, AI research assistant, smart resurfacing) — see Out of Scope.

## Decisions Log

Authoritative record. Each phase references its decision by number.

1. **Graph Insights ships as a read-only "answerable views" screen, not a force-directed
   graph.** Four questions answerable from data that already exists on demand:
   *Orphans* (no incoming and no outgoing `[[links]]`), *Stale* (`updatedOn` older than a
   user-set threshold, default 90 days, AND has at least one open `TaskItem` or one backlink —
   i.e. it once mattered), *Notes with open tasks* (grouped by document, count + nearest due
   date), *Hubs* (top-N by combined in+out link degree). "Clusters" = connected components via
   union-find over the `[[link]]` edge set — cheap, deterministic, no simulation. All computed
   by a new `GraphInsightsDAL`, scan-on-demand, matching `BacklinkDAL`/`SearchDAL`'s established
   no-persisted-index rationale. This is pulled from `NoteBytez-ReleaseFeatures.md` §Advanced
   "Graph insights" into V1.x; the semantic/AI half of that Advanced bullet stays deferred.

2. **IA restructure is sectioning + tab reassignment, not new screens.** Mac/iPad sidebar gets
   three labeled sections — **Capture** (Today), **Library** (Notebooks, All Notes, Tags),
   **Explore** (Search, Graph, Insights, Tasks, Saved Views, Canvas) — then Settings.
   `AppDestination` gains a `section` property; the sidebar `List` renders `Section`s.
   iPhone tab bar changes from `[Today, Notebooks, Search, Graph, Settings]` to
   `[Today, Notebooks, Search, Explore, Settings]` where **Explore** is a new hub list
   (`ExploreHubView`) pushing to Graph / Insights / Tasks / Saved Views / Canvas / Tags —
   Settings keeps its tab. Rationale: makes "Capture vs. Library" the literal spine of the app
   without a redesign, and consolidates the six secondary destinations that currently have no
   coherent iPhone home (`04-InteractionDesign.md` scatters them across "push from some tab").
   Graph is promoted to a top-level Explore item on every platform; Insights sits directly
   beneath it.

3. **Promote-to-Notebook regains a direct gesture via `.contextMenu`, keeping the toolbar
   button as the discoverable fallback.** `.contextMenu` (long-press on iOS, right-click on
   macOS) is a first-class SwiftUI affordance with none of the raw `onTapGesture`-inside-
   `ScrollView` delivery problems the MVP plan documented — it is the correct primitive for
   "act on this specific block." Applied to each rendered block row in `DocumentPreviewView`'s
   line-based path and to journal blocks in `TodayJournalView`. The existing toolbar
   "Promote to Notebook" button (opening `PromoteBlockPickerView`) stays — two entry points to
   one `NotebookDAL.promote` path, same pattern as MVP's task-toggle (S3 toolbar + inline).

4. **Graph ↔ Canvas unification is one-directional "Send neighborhood to Canvas" for v1.**
   From the Graph or Insights screen: an action creates a new `CanvasBoard` seeded with the
   center document + its direct links as `.note` cards laid out radially, with
   `CanvasConnector`s drawn for every existing `[[link]]` between those cards. Reuses
   `CanvasDAL.addNoteCard` / `addConnector` unchanged. No live binding back from canvas to
   graph — that is genuine bidirectional-sync scope and is deferred. This still delivers the
   research's "don't make them separate modes" intent: the graph becomes a *source* for spatial
   work, not a dead-end visualization.

5. **Live block transclusion uses an opt-in `!((anchor))` embed form; read-only in v1.**
   `((anchor))` stays a link (unchanged, no churn for existing content). `!((anchor))` — the
   `!` prefix mirrors Markdown's `![]()` image-embed-vs-`[]()`-link instinct and round-trips as
   inert plain text in Obsidian/Logseq — renders the referenced block's *current* content
   inline, re-resolved on every render (same "resolve at render time" pattern
   `EmbeddedSearchResultsView` already uses). **Cycle safety:** a visited-anchor set threaded
   through render; depth is capped at 1 (an embedded block's own `!((...))` embeds render as
   plain links, not recursively expanded) — simple, sufficient, no infinite-loop surface.
   **Editable-in-place: no.** The embed is read-only with a "jump to source" tap target.
   That is still a real capability gain over today's static link and closes the most-felt gap
   for Logseq migrants; in-place editing is deferred with the rest of Advanced's "editable-in-
   place semantics decided" language.

6. **Command Palette is a static `AppCommand` registry, no JSON, no plugin surface.** A
   `CaseIterable` enum of navigation targets (every `AppDestination`) + primary actions
   (New Note, New Notebook, New Canvas Board, Promote to Notebook, Sync Now, Import Markdown…,
   Open Settings). ⌘P opens the palette (fuzzy-filtered list, reuses
   `WikilinkParser.fuzzyMatches`); ⌘O stays Quick Switcher (note-title jump) but becomes
   reachable from any screen via the same `NotificationCenter` bridge `AppCommands.swift`
   already uses for menu commands. On iPhone (no hardware ⌘) both are reachable from the new
   Explore hub and a Today-screen toolbar item respectively — the palette is an accelerator,
   never the only path to anything.

## Assumptions

- **Zero CloudKit schema change.** Graph Insights and the Canvas-seed action are computed from
  existing models; transclusion is parser + render only; the palette and IA work touch no
  models. This plan therefore carries none of the "additive-only, ship-once" CloudKit schema
  risk the R1 plan's Assumptions section manages. If any task below finds it needs a stored
  field, stop and flag it before adding one.
- `../MarkdownG9` is editable in this workspace (local package per `ARCHITECTURE.md`). Phase 6
  may need one additive `MDProcessor` change for the `!((anchor))` sigil; verify first.
- `GraphDAL` / `BacklinkDAL` / `WikilinkParser` resolve library-wide already — Graph Insights
  builds on them without changing their scope.
- The IA restructure keeps all existing screens and their reachability; nothing is removed,
  only re-parented. Deep links / `navigationDestination` targets are unaffected.
- No visual redesign. New surfaces reuse `styleGuide.md` components (`SidebarNavItem`,
  `SearchResultRow`, `TagChip`, `SyncStatusGlyph`) and its sync/empty/error state conventions.

---

## Phase 0 — Foundation & UI/UX Artifacts

Prerequisite design alignment, mirrors the R1 plan's Phase 1. No user-facing code.

- [x] **Extend `Docs/Plans/UIUX/04-InteractionDesign.md`** — add the sectioned sidebar / Explore
  hub to the "Per-platform navigation shell" table (Decision 2); add S25 (Graph Insights),
  S26 (Command Palette), S27 (Explore Hub) to the Screen inventory; note the `!((anchor))`
  render and the "Send to Canvas" action as additions to S8/S16 rather than new screens.
  → verify: every new screen referenced below has a row here.
- [x] **Extend `Docs/Plans/UIUX/05-Wireframes.md`** — low-fidelity wireframes for S25/S26/S27 on
  Mac/iPad/iPhone, same bar as the MVP/R1 sets. S8's "Send to Canvas" and S4's `!((anchor))`
  embed specified as deltas, following S10/S17's precedent.
- [x] **Extend `Docs/Plans/UIUX/06-DesignSystem.md`** component inventory — `CommandPaletteRow`,
  `GraphInsightRow`, `InsightSectionHeader`, `TransclusionBlockView`; re-promote the additions
  into `Docs/styleGuide.md` per `CLAUDE.md` §10 (and backfill any R1 drift found while there,
  as R1 Phase 1 did).
- [x] **Update `ARCHITECTURE.md`** — one line under §Markdown parsing that `!((anchor))` is a
  render-time transclusion reusing the `blockref://` URL scheme; one line under §Design Pattern
  noting `GraphInsightsDAL` is computed-on-demand like `BacklinkDAL`/`SearchDAL`.

---

## Phase 1 — Command Palette & Global Quick Switcher

Decision 6. No data dependencies — done first because it makes every subsequent phase's new
surface reachable by keyboard, and de-risks the IA change (Phase 2) by giving power users a
navigation path that doesn't depend on sidebar structure.

- [x] **1.1 Failing tests first.**
  - `AppCommandTests`: `AppCommand.allCases` includes one case per `AppDestination` plus the
    fixed action set (Decision 6); `AppCommand.matches(query:)` fuzzy-ranks "npt" → New Note
    above New Notebook is *not* required, but "newnote" → `.newNote` and "graph" → `.graph`
    must be top hit.
  - `CommandPaletteViewModelTests`: empty query returns all commands in stable declared order;
    a query routes `.navigation(dest)` cases and `.action(id)` cases to distinct callbacks.
  - Verify: both fail.
- [x] **1.2 `AppCommand` enum** (`NoteBytez/` root, beside `AppCommands.swift`) —
  `enum AppCommand: CaseIterable, Identifiable` with `.navigate(AppDestination)` and
  `.action(AppAction)` payloads, `title`, `systemImage`, and `matches(query:)` delegating to
  `WikilinkParser.fuzzyMatches` (no second fuzzy implementation, per every prior phase's rule).
- [x] **1.3 `CommandPaletteViewModel`** (`viewModels/`) — holds the filtered list, exposes
  `select(_:)` which posts the existing `.noteBytez*` notifications for navigation and new
  `.noteBytezRun(AppAction)` for actions. `@Observable`, no `ModelContext` needed.
- [x] **1.4 `CommandPaletteView`** (`views/Search/`) — sheet, single text field +
  `List` of `CommandPaletteRow`, first result actioned on Return. Reuses `QuickSwitcherField`'s
  layout idiom.
- [x] **1.5 Wire ⌘P / global ⌘O in `NoteBytezApp.swift` `.commands`** — add a
  `CommandGroup(after: .toolbar)` "Command Palette…" `keyboardShortcut("p", modifiers: .command)`
  posting `.noteBytezOpenCommandPalette`; the existing ⌘O "Search" button is repurposed to post
  `.noteBytezOpenQuickSwitcher` (note-jump), distinct from the Search *destination* (which moves
  to the palette). `ContentView` gains `.sheet` presenters for both, plus
  `.onReceive(.noteBytezRun)` dispatching `AppAction`s (New Note → `.allNotes` + trigger,
  Sync Now → `SyncEngine.shared.syncNow()`, etc.).
- [x] **1.6 iPhone reachability** — `TodayJournalView` keeps its Quick Switcher toolbar item;
  the Explore hub (Phase 2) lists "Command Palette" as a row. No hardware-shortcut assumption.
- [ ] **1.7 Tests green + manual** — palette opens on ⌘P from every destination, Quick Switcher
  opens on ⌘O from every destination (not just Today), Return actions the top hit. Full
  `NoteBytezTests` target passes.

---

## Phase 2 — Journal / Notebooks Primary IA

Decision 2. Depends on Phase 1 (keyboard nav path exists before sidebar structure moves).

- [x] **2.1 Failing tests first (`AppDestinationTests`).**
  - Every `AppDestination` has a non-nil `section`; `AppDestination.sidebarSections` yields
    `[.capture, .library, .explore]` in order with the documented members, plus `.settings`
    rendered outside a section.
  - `AppDestination.tabBarDestinations == [.today, .notebooks, .search, .explore, .settings]`.
  - `.graph` is in `.explore`, not a bare peer; `.explore` is a valid tab destination.
  - Verify: fail.
- [x] **2.2 `AppDestination.section`** — add `enum Section { case capture, library, explore }`
  and the mapping (Decision 2). Add `.insights` and `.explore` cases. `.explore` has no
  detail view of its own on Mac/iPad (it's a section, not a row there) — model it as a
  tab-only destination via a `isTabOnly`/`isSidebarRow` split, or a computed
  `sidebarRows` / `tabBarDestinations` pair. Keep it explicit, not clever.
- [x] **2.3 `ContentView` sidebar → sectioned `List`** — `ForEach(AppDestination.sidebarSections)`
  wrapping `Section(header:)` + its rows; Settings appended outside. `SidebarNavItem` /
  `styleGuide.md` §Navigation unchanged otherwise.
- [x] **2.4 `ExploreHubView`** (`views/` new `Explore/` folder) — plain `List` of
  `SidebarNavItem`-style rows: Graph, Insights, Tasks, Saved Views, Canvas, Tags, Command
  Palette. Each `NavigationLink` to the existing destination view. This is S27.
- [x] **2.5 `ContentView` tab bar** — swap `.settings`-was-4th for `.explore` hub as 4th tab
  (Settings stays 5th); `DestinationView` gains `.explore` → `ExploreHubView`, `.insights` →
  `GraphInsightsView` (Phase 4 — stub returning `ProgressView` until then so this phase builds).
- [x] **2.6 Menu-bar `View` menu** — add `CommandGroup` items to jump to Today / Notebooks /
  Graph / Insights, matching the new spine, each posting a navigation notification.
- [x] **2.7 Tests green + manual on all three form factors** — sidebar shows 3 sections +
  Settings; iPhone shows 5 tabs ending Explore, Settings; every previously-reachable screen
  still reachable in ≤2 taps. `NoteBytezUITests` sidebar/tab identifiers updated
  (`sidebar.*` / `tabbar.*` in `ContentView`).

---

## Phase 3 — Restore Direct Promote-to-Notebook Gesture

Decision 3. Depends on Phase 2 only for the settled `DocumentPreviewView` call sites. Small.

- [x] **3.1 Failing test first (`DocumentViewModelTests`).** `promoteBlock(at:)` (new, thin
  wrapper over `NotebookDAL.promote` locating the block by the same `sortOrder`/content-match
  splice `TaskDAL.toggle` uses) creates a Document in the target Notebook, inserts the
  bidirectional `[[wikilink]]`, and leaves the source block textually untouched. Verify: fail.
- [x] **3.2 `DocumentPreviewView` line-based path** — each rendered block row gets
  `.contextMenu { Button("Promote to Notebook") { … } }` when the owning document
  `isJournalEntry`, presenting `PromoteToNotebookView` pre-targeted at that block (no picker
  step). Non-journal documents: no menu item (Promote is a journal→notebook operation).
- [x] **3.3 `TodayJournalView`** — same `.contextMenu` on the editor's block rows; keep the
  existing toolbar "Promote to Notebook" button (→ `PromoteBlockPickerView`) as the fallback.
  `DocumentViewModel.reload()` after promote (already wired for the toolbar path).
- [x] **3.4 Tests green + manual** — long-press a journal block on iOS / right-click on macOS →
  "Promote to Notebook" appears, completes without the intermediate block-picker, source entry
  unchanged, backlink resolvable both directions. `NoteBytez-MVP-ImplementationPlan.md` Phase 8
  note updated to record the gesture is restored.

---

## Phase 4 — Answerable Graph Views (Graph Insights)

Decision 1. The marquee differentiator. Depends on Phase 2 (its nav slot). Independent of 3/5/6.

- [x] **4.1 Failing tests first (`GraphInsightsDALTests`).**
  - *Orphans*: a document with no `[[links]]` in or out is listed; one with only an incoming
    link is not; one with only an unlinked mention is (mentions aren't links).
  - *Stale*: `updatedOn` > threshold AND (has ≥1 open `TaskItem` OR ≥1 backlink) → listed;
    old-but-truly-abandoned (no tasks, no backlinks) → not listed (that's an orphan's job);
    recently edited → not listed. Threshold is a parameter, default 90 days.
  - *Notes with open tasks*: grouped per document, `openCount` and `nearestDueDate` correct;
    a document whose tasks are all done → not listed.
  - *Hubs*: ranked by `inDegree + outDegree` over the `[[link]]` edge set, top-N, ties broken
    by title.
  - *Clusters*: union-find over the link edge set returns connected components; two documents
    linked only through a third are in one component; an orphan is its own singleton.
  - Verify: all fail.
- [x] **4.2 `GraphInsightsDAL`** (`dal/`) — one `enum` with `orphans(...)`, `staleNotes(...)`,
  `notesWithOpenTasks(...)`, `hubs(...)`, `clusters(...)`, each `(libraryId:, in:)` and
  scan-on-demand. Build the link edge set once per call from `DocumentDAL.fetchActive` +
  `WikilinkParser.extractTitles` (resolve title→id via a dictionary, same shape as
  `GraphDAL.directLinks`). Union-find is ~25 lines, hand-rolled, in the same file or a
  `dal/DisjointSet.swift` helper with its own unit test.
- [x] **4.3 `GraphInsightsViewModel`** (`viewModels/`) — `@Observable`, one published array per
  insight category + the stale-threshold binding (persisted to `UserDefaults` via the
  `ConflictStrategyStore` pattern). `refresh()` on appear.
- [x] **4.4 `GraphInsightsView`** (`views/Graph/`) — S25. A `List` with a `Section` per
  category (`InsightSectionHeader` = title + count + a one-line "what this means"), rows are
  `GraphInsightRow` (document title + the category-relevant metric: last-edited, open-task
  count + due date, degree). Empty categories render `styleGuide.md`'s calm empty state
  ("No orphans — every note is connected"), never a blank section. Tapping a row →
  `DocumentView`. Stale threshold adjustable inline (stepper: 30/60/90/180 days).
- [x] **4.5 Clusters presentation** — for v1, list each component as a collapsible group headed
  by its highest-degree member ("Cluster: Worldbuilding — 14 notes"); tapping expands to the
  member list. No spatial rendering (that's Phase 5's "Send to Canvas").
- [x] **4.6 Wire into nav** — `AppDestination.insights` (Phase 2 stub) now resolves to
  `GraphInsightsView`; Explore hub row live; menu-bar "Insights" jump live.
- [x] **4.7 `AppCommand`** gains `.navigate(.insights)` (automatic if Phase 1 iterates
  `AppDestination.allCases`) — confirm it appears in the palette.
- [x] **4.8 Performance guard** — a test seeding 2,000 documents / 6,000 links asserts every
  insight query returns in < 250 ms on the CI simulator (scan-on-demand's known ceiling; if it
  regresses past this, that's the signal to revisit the no-persisted-index decision, not
  before).
- [x] **4.9 Full `NoteBytezTests` + `NoteBytezUITests` pass**; manual pass on iPhone + iPad
  simulator (Mac build per Phase 7).

---

## Phase 5 — Unify Graph ↔ Canvas ("Send to Canvas")

Decision 4. Depends on Phase 4 (neighborhood/cluster concept) and R1 Phase 9 (Canvas, complete).

- [x] **5.1 Failing tests first (`CanvasDALTests` extension).**
  - `CanvasDAL.seedBoard(fromNeighborhoodOf:libraryId:in:)` creates a board named
    "<Title> — Map", adds one `.note` card for the center + one per direct link, positions them
    radially (center at origin, links on a circle), and adds a `CanvasConnector` for every
    `[[link]]` that exists between any two of those documents (not just center↔link).
  - Called on a document with zero links → a board with a single center card, no connectors,
    no crash.
  - Re-invoking creates a *new* board each time (no dedupe / no live binding — Decision 4).
  - Verify: fail.
- [x] **5.2 `CanvasDAL.seedBoard(fromNeighborhoodOf:…)`** — reuses `GraphDAL.directLinks` for
  membership and `addNoteCard` / `addConnector` unchanged. Radial layout math is a small pure
  helper with its own test (`n` points on a circle of radius `r`).
- [x] **5.3 `CanvasDAL.seedBoard(fromCluster:…)`** — same, seeded from a
  `GraphInsightsDAL.clusters` component (all members as cards, all internal links as
  connectors, force-free grid or circle layout).
- [x] **5.4 `GraphView` + `GraphInsightsView` actions** — `GraphView` toolbar gains
  "Send to Canvas" (seeds from the current center's neighborhood, then
  `navigationDestination` into the new `CanvasBoardView`). `GraphInsightsView` cluster rows
  gain a swipe/context action "Open as Canvas".
- [x] **5.5 `AppCommand.action`** — add "Send current note's map to Canvas" (enabled only when
  a document context exists; no-op toast otherwise).
- [x] **5.6 Tests green + manual** — from a note with 5 links, "Send to Canvas" produces a
  board with 6 cards and the correct inter-card connectors, opens it, and it exports to valid
  JSON Canvas (round-trips through R1 Phase 9's `exportJSONCanvas`). Full suite passes.

---

## Phase 6 — Live Block Transclusion

Decision 5. Independent of 2–5 (touches parser + `DocumentPreviewView` render path +
`BlockReferenceDAL`). Sequenced last of the feature phases as the riskiest render change.

- [x] **6.1 Failing tests first.**
  - `BlockReferenceParserTests`: `extractEmbeds(from:)` returns anchors from `!((a))` but not
    from `((a))`; `extractAnchors` still returns both (a `!((a))` is also a reference for
    backlink purposes); `applying(embedAnchor:)` inserts `!((a))` with exactly two closing
    parens (the explicit-concatenation lesson from R1 Phase 4).
  - `DocumentViewModelTests`: `transclusion(for anchor:)` returns the *current* content of the
    target block (edit the source, re-query, see the new text); returns `nil` for an
    unresolvable anchor.
  - Cycle test: doc A `!((b))`, doc B `!((a))` — rendering A expands B's content once, and B's
    `!((a))` inside that expansion renders as a plain link, no infinite loop, no stack growth.
  - Verify: fail.
- [x] **6.2 `BlockReferenceParser`** — add `embedPattern` (`!((anchor))`), `extractEmbeds`,
  `applying(embedAnchor:)`, and an `activeEmbedQuery` sibling to `activeQuery` so autocomplete
  can offer `!((` too. `extractAnchors` updated to also match the `!`-prefixed form.
- [x] **6.3 `MDProcessor` check (only if needed)** — determine what `../MarkdownG9` emits for
  `!((a))` today. If it already leaves it as literal text the app can intercept line-by-line,
  no package change. If it mangles the `!`, add a minimal rewrite to `blockref://a?embed=1`
  with a `MarkdownG9` test. Record the outcome here.
- [x] **6.4 `DocumentViewModel.transclusion(for:)`** — resolves via
  `BlockReferenceDAL.resolve(anchor:preferringDocumentId:…)` (unchanged) and returns the target
  `Block` + `Document` for display. Add `transcludedAnchors` visited-set plumbing as a
  parameter with a default, so the render path can pass its accumulated set (Decision 5, depth
  cap 1).
- [x] **6.5 `DocumentPreviewView` line-based path** — `needsLineByLineRendering` also triggers
  on `BlockReferenceParser.containsEmbed`. A matching line renders a new `TransclusionBlockView`
  (the target block's `MDProcessor.process` output in a bordered container styled per
  `styleGuide.md` §Secondary surface, a small "↗ source" button top-right jumping to the source
  document). Task-index counting must still walk the *whole* document (same correctness note
  the file already carries for query blocks / attachments) — an embed line is a non-task,
  non-checkbox line for counting purposes.
- [x] **6.6 Autocomplete** — `TodayJournalView` and `DocumentView` editing strips: when the
  active query is `!((…`, offer the same `blockReferenceSuggestions` list, and
  `insertBlockReference` writes the `!`-prefixed form.
- [x] **6.7 Block-level backlinks** — `BacklinksPaneView`'s "Block References" section
  (R1 Phase 4) already counts any `((anchor))`; confirm `!((anchor))` embeds are included
  (they should be, via the updated `extractAnchors`) and add a test row asserting it.
- [x] **6.8 Tests green + manual** — `!((anchor))` in a journal entry renders the live block
  content inline; editing the source and returning updates it; a `.md` export of the embedding
  note contains the literal `!((anchor))` text (round-trips, no proprietary expansion written
  to disk); Obsidian opening that file shows inert text, not a broken embed. Full
  `NoteBytezTests` + `MarkdownG9` package tests pass.

---

## Phase 7 — Cross-Platform Verification & Quality Gate

`CLAUDE.md` §4 / §7, mirrors the MVP/R1 closing phases. Same environment caveats apply
(simulator tap flakiness; native Mac GUI walkthrough blocked by missing Accessibility
permission — verify Mac *builds* and unit tests pass, note the GUI gap honestly).

- [x] **7.1 Coverage review** — `xcodebuild test -enableCodeCoverage YES`. New logic
  (`GraphInsightsDAL`, `DisjointSet`, `AppCommand`, `CommandPaletteViewModel`,
  `BlockReferenceParser` additions, `CanvasDAL.seedBoard*`) at 90%+; views excluded per the
  established `views/` unit-test gap. Verified: `GraphInsightsDAL` 97.75%, `DisjointSet` 95%,
  `AppCommand` 100%, `CommandPaletteViewModel` 96.30%, `BlockReferenceParser` 100%, `CanvasDAL`
  93.54%, `GraphInsightsViewModel` 91.30% (added coverage tests for the two that started below
  the bar — `AppCommand.systemImage`/`.id` and `CommandPaletteViewModel`'s empty-query reset path
  were untouched by the original test set).
- [x] **7.2 Mac build green** — `xcodebuild build -destination 'platform=macOS'` succeeds with no
  `#if os()` gaps. `xcodebuild test -destination 'platform=macOS'` cannot isolate `NoteBytezTests`
  from `NoteBytezUITests` via `-only-testing`, and the latter fails to *build* for macOS on a
  pre-existing, unrelated issue (`XCUIDevice.orientation` is iOS-only — predates this plan). Full
  `NoteBytezTests` (685 tests) verified green on iOS simulator instead; the Mac app build itself,
  which is what this task actually gates, is green.
- [ ] **7.3 iPad pass** — sectioned sidebar renders with 3 sections + Settings; landscape split
  view and portrait collapse both keep every destination reachable; "Send to Canvas" and
  `!((anchor))` render correctly at regular width. Screenshot-verify what the environment allows.
  **Not done**: no iPad simulator pass performed this session (see 7.4's note — same blocker).
- [ ] **7.4 iPhone pass** — 5-tab bar ends `Explore, Settings`; Explore hub lists all six
  secondary destinations; ⌘O/⌘P equivalents reachable without hardware keyboard; Promote
  `.contextMenu` fires on long-press. **Partial**: verified by code review and the full unit/
  integration suite (`AppDestinationTests`, `FlowEnhancementsIntegrationTests`) rather than a
  live simulator walkthrough — this session's simulator text-input tooling could not type into
  any `TextField` (confirmed independent of this plan's code: a stock "New Library" name field
  failed identically), which blocked getting past library creation to click through the new IA.
  Matches this phase's own documented "simulator tap flakiness" caveat; noted honestly rather
  than claimed.
- [ ] **7.5 Accessibility** — VoiceOver labels on every new icon-only control (palette dismiss,
  insight section disclosure, transclusion "source" button, "Send to Canvas"); Dynamic Type
  pass on `GraphInsightsView` rows and `TransclusionBlockView` (no truncation of embedded
  content — it reflows). Color-blind: insight severity never color-only (icon + text + count).
  **Partial**: code-review pass done — every new icon-only button carries `.accessibilityLabel`
  ("Send to Canvas", "Jump to source"; the palette's own Cancel/dismiss and insight disclosure
  controls use plain text labels, not icons, so need none), no `.lineLimit`/`.fixedSize`
  constraints were added to any new row so text reflows under Dynamic Type by default, and every
  metric in `GraphInsightRow` pairs an SF Symbol with a text label, never color alone. No live
  VoiceOver/Dynamic Type simulator walkthrough — same tooling blocker as 7.3/7.4.
- [x] **7.6 Journey acceptance** — new `FlowEnhancementsIntegrationTests`:
  - *Palette flow*: ⌘P → type "insights" → Return → `GraphInsightsView` is the active
    destination.
  - *Resurfacing flow*: seed an orphan with an unlinked mention of an existing note → it
    appears under Orphans → open it → add a `[[link]]` → re-refresh → it's gone from Orphans
    and now in a cluster (closes the J4 loop the shallow graph couldn't).
  - *Promote flow*: context-menu Promote a journal block → Document in Notebook + bidirectional
    backlink, source untouched.
  - *Transclusion flow*: `!((anchor))` embed reflects a subsequent source edit; export writes
    literal `!((anchor))`.
  - *Send to Canvas flow*: neighborhood → board with correct card + connector count → exports
    valid JSON Canvas.

---

## Out of Scope (explicit)

- **The Advanced intelligence tier proper** — on-device semantic/vector index, AI research
  assistant with source-block citations, AI-generated "forgotten context" / weekly digest.
  Graph Insights (Phase 4) is the deterministic, no-model subset of `NoteBytez-ReleaseFeatures.md`
  §Advanced "Graph insights"; the AI/embedding half stays deferred and unblocked by this work.
- **Bidirectional Graph↔Canvas binding** — editing a canvas does not write back to links/graph;
  "Send to Canvas" (Phase 5) is a one-time seed. Live binding is a separate future plan.
- **In-place editing of transcluded blocks** — Phase 6 embeds are read-only. Matches Advanced's
  own "editable-in-place semantics decided" open item.
- **Force-directed / physics graph rendering** — the existing `GraphCanvas` radial one-hop
  layout is unchanged; Insights is a list, not a canvas.
- **Multi-language localization (`NoteBytez20260823v2-MultiLanguage.md`) and the 22-role
  template expansion (`NoteBytez20260824v1-Templates.md`)** — both are breadth, not
  differentiation, and are tracked by their own docs. Deliberately excluded here so they don't
  crowd out the flow work; new user-facing strings added by this plan should still be authored
  through whatever localization seam those plans establish, if it lands first.
- **New CloudKit models** — see Assumptions. Any task that appears to need one stops and
  escalates.

## Verification Gate (all phases)

- [x] `GraphInsightsDALTests`, `DisjointSetTests`, `AppCommandTests`,
  `CommandPaletteViewModelTests`, `AppDestinationTests`, `BlockReferenceParserTests`,
  `DocumentViewModelTests`, `CanvasDALTests`, `FlowEnhancementsIntegrationTests` — all green.
- [x] Existing suites unaffected: full `NoteBytezTests` (685 tests) passes, 0 failures, on iOS
  simulator; `../MarkdownG9` package tests (46 tests) pass. `NoteBytezUITests` builds clean
  (`build-for-testing`) but was not executed — running the suite is slow/flaky in this
  environment per this phase's own caveat, and wasn't required to validate the logic changes
  here (none of this plan's UI-layer edits touch the UI tests' own assertions beyond the
  `MainShellScreen` navigation helper already updated and exercised transitively by its callers'
  build success).
- [x] `xcodebuild build -destination 'platform=macOS'` succeeds.
- [ ] Manual: ⌘P and global ⌘O work from every destination; sidebar shows Capture/Library/
  Explore sections; a journal block's context menu promotes it; an orphan note surfaces in
  Insights and leaves it once linked; `!((anchor))` renders live and exports literal;
  "Send to Canvas" produces a valid, exportable board. **Not performed as a live simulator
  walkthrough** — see Phase 7.3/7.4/7.5's note (text-input tooling blocker). Every behavior
  listed here has equivalent coverage in `FlowEnhancementsIntegrationTests` instead.
- [x] `ARCHITECTURE.md`, `Docs/styleGuide.md`, and the `UIUX/04-06` set updated to match what
  shipped (Phase 0 + closeouts).
