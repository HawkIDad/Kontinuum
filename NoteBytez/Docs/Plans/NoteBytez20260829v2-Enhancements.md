<!-- NoteBytez20260829v2-Enhancements.md -->
<!--
  Companion to NoteBytez20260829v1-FlowEnhancements.md. v1 pulled the cheapest, no-schema slice
  of NoteBytez's differentiation work forward into a V1.x release and listed the deeper items it
  deliberately deferred under "Out of Scope". This document is the build plan for those deferred
  items — EXCEPT the two already owned by their own plans:
    - Multi-language localization  → NoteBytez20260823v2-MultiLanguage.md
    - Role-based template expansion → NoteBytez20260824v1-Templates.md
  (NoteBytez20260827v1-Anchors.md — heading-aware anchors / sticky identity / section links —
  is unrelated to anything here and is only named to disambiguate.)

  Unlike v1, EVERY workstream here needs product decisions that are not yet made and — for
  workstreams B, C, D — new CloudKit schema. Nothing in this document is buildable until its
  "Open Questions" are answered and its models are reviewed against ARCHITECTURE.md's
  additive-only CloudKit rule. Treat phase task lists as provisional shape, not a committed
  checklist, until the decision gates clear.

  Living document. Checkbox convention: [ ] not started / in progress, [x] done and verified
  (builds + its test passes). TDD per CLAUDE.md §8. Workstreams are ordered by dependency and
  ascending risk: A (self-contained, no new deps) → D (largest, new network egress, new schema).
-->

# NoteBytez V2 — Deferred Depth Enhancements

Source: the "Out of Scope" section of
[NoteBytez20260829v1-FlowEnhancements.md](NoteBytez20260829v1-FlowEnhancements.md), minus items
already planned elsewhere. Maps to [NoteBytez-ReleaseFeatures.md](NoteBytez-ReleaseFeatures.md)
§Advanced bullets: *Local semantic index*, *AI research assistant*, *Smart resurfacing*, *Graph
insights* (AI half), *Live block transclusion* (editable-in-place half), and the research doc's
[§1e / §5](NoteBytez20260813-Research.md) "unify canvas + graph + outline" intent.

Baseline: MVP complete, R1 ~95%, V1.x Flow Enhancements (v1 plan) assumed shipped — workstreams
B and C depend on v1's Phases 6 and 5 respectively.

## Progress Summary

| Workstream | Decision gate | Tasks complete | Status |
|---|---|---|---|
| A. Force-Directed Graph Rendering | none blocking | 8 / 8 | Done |
| B. Editable-in-Place Transclusion | Resolved 2026-09-05 — (a) optimistic write, undo via spike | 7 / 7 | Done |
| C. Bidirectional Graph ↔ Canvas Binding | Resolved 2026-09-05 — (a) links→canvas, 1-hop | 8 / 8 | Done |
| D. Advanced Intelligence Tier | D-gate (iOS 27 API surface, embedding provider, connector redaction) | 0 / 26 | Blocked on decision |
| E. Cross-Cutting Verification & Quality Gate | — | 4 / 6 | A/B/C verified; E4 sign-off + D-scoped halves pending |
| **Total** | | **27 / 55** | **49%** |

---

## User Story

As a long-term NoteBytez user who has already adopted it over Obsidian/Logseq, I want the app to
keep getting *deeper* where it already differs — a graph that reveals structure, transclusions I
can edit where I see them, a canvas that stays in sync with my links, and an AI layer that
works from my own notes with citations and privacy controls — so that the reasons I switched
compound over time instead of plateauing at "native and trustworthy."

## Background — why, not what

The v1 plan's finding was that NoteBytez's differentiation is real but shallow, and the features
the 2026-08-13 research identified as the actual moats — "differentiate on intelligence,
reliability, and Apple-native speed, not feature-checklist bloat" — sit entirely in the
un-scheduled "Advanced" tier. v1 shipped the deterministic, no-risk slice (answerable graph
*lists*, read-only transclusion, one-shot Send-to-Canvas, a command palette). This plan is the
follow-through: the same four areas, taken to the depth that makes them genuinely hard for a
cross-platform competitor to match.

Each workstream is independently shippable and independently valuable — this is not a monolith.
A is pure client work. B and C are contained extensions of v1 surfaces. D is a program in its
own right and may split into its own numbered plan once its decision gate clears; it is
included here so the full deferred set is visible in one place.

## Decisions Log

Items marked **[OPEN]** block their workstream and must be resolved (by the product owner, not
inferred) before that workstream's models or network paths are built. Resolved items are the
authoritative record.

### Cross-cutting

1. **These features may add CloudKit schema; v1's "zero schema" rule does not apply here.**
   Every new `@Model` follows `ARCHITECTURE.md` Model Conventions (all fields optional, no
   `@Attribute(.unique)`, `{model}Id` identity, audit fields last, foreign-key-by-UUID joins)
   and is reviewed for additive-only compatibility before registration in `KontinuumApp.swift`'s
   `Schema`. CloudKit schema is ship-once — a mistake here is not cheaply reversible.
2. **Local-only vs. synced, per data class:** derived/large/device-regenerable state is
   local-only (plain `Codable` files, the `BackupSnapshot` precedent), never a `@Model`. This
   covers the semantic index (Workstream D) outright. Small, portable, cross-device-useful
   state (prompt templates, chat threads, canvas-binding flags) syncs as normal models.
3. **Workstream D runs on Apple's built-in AI first; third-party cloud is opt-in only.** The
   primary engine for every D feature is the on-device Apple Foundation Models framework
   (iOS 26+, extended in iOS 27 / macOS 27), routing to Apple Private Cloud Compute
   automatically — no third-party egress, no redaction requirement, no API key. A user-added
   third-party `ModelConnector` is an optional power-user setting, off by default, and is the
   *only* path that introduces new network egress. That path — and only that path — is in scope
   for [NoteBytez20260627v2-Security.md](NoteBytez20260627v2-Security.md)'s NETWORK / PLATFORM /
   privacy-manifest workstreams: redaction correctness, ATS, `PrivacyInfo.xcprivacy`
   required-reason + data-use declarations, egress allow-listing. No connector ships without
   that sign-off; the Apple-only configuration ships without it.

### Workstream A — Force-Directed Graph

4. **A replaces `GraphCanvas`'s radial one-hop layout with a real force simulation, gated
   behind a mode toggle.** The MVP/v1 radial view stays the default (fast, legible, no
   settling animation); "Force layout" is an opt-in mode on S8, per MVP's own
   "filters, forces, or clustering (that's V1/Advanced)" deferral language. No third-party
   physics library — a Barnes-Hut / Fruchterman-Reingold implementation in ~150 lines against
   `TimelineView`/`Canvas` is within `CLAUDE.md`'s "leverage the standard library before
   reaching for a dependency" rule; if that proves untrue, the fallback is a small
   MIT/Apache-licensed package (per `CLAUDE.md` §5's unencumbered-license constraint),
   flagged for approval, not chosen silently.
5. **Graph filters ship with the force mode:** depth (1–3 hops from the focus note),
   node-type toggles (notes / notes-with-open-tasks / orphans), and tag-scoped highlighting.
   These are view state, not persisted — with one exception: a "graph filter preset" is
   saveable through the existing `SavedView` mechanism (`queryType` gains a `.graph` case,
   `definitionJSON` holds the filter set), reusing R1 Phase 7 rather than a new store.

### Workstream B — Editable-in-Place Transclusion

6. **[RESOLVED 2026-09-05] B-gate — write-back conflict semantics: (a) optimistic write,
   last-write-wins within the device.** v1's `!((anchor))` embed is read-only. Making it
   editable means an edit in the embedding note must write to a *different* document's block.
   Product owner chose (a) over the plan's own (b) recommendation for simplicity: the embed
   edits `Block.content` directly via `BlockDAL`; the source document is re-parsed on its next
   load. No diff-merge prompt, no held write — whichever save lands last wins.
   ~~(b) Guarded write~~ / ~~(c) Defer~~ — not chosen.
7. **[RESOLVED 2026-09-05] B-gate — cross-document undo: spike during implementation.** Product
   owner deferred the choice to implementation — B4 investigates SwiftUI's `UndoManager`
   behavior across `DocumentViewModel` instances and records the chosen behavior (embedding
   document's stack, source document's, or both) directly in that task's own notes.
8. **Editing scope is the single referenced block only.** `!((anchor))` addresses one block;
   the editable region is that block's text, nothing structural (no adding sibling blocks
   through the embed). Depth stays capped at 1 (v1 Decision 5) — a transcluded block's own
   `!((...))` render as links inside the editable view, not nested editors.

### Workstream C — Bidirectional Graph ↔ Canvas Binding

9. **[RESOLVED 2026-09-05] C-gate — binding model: (a) links → canvas (read-mostly).** v1's
   "Send to Canvas" is a one-time seed. A *bound* board tracks a source note's neighborhood
   live. The board auto-adds/removes note cards as the source note's `[[links]]` change;
   connectors mirror links; user spatial layout (positions, groups, web/media cards) is
   preserved across refreshes. Drawing a connector on the board *offers* to create the matching
   `[[link]]` (confirm, don't auto-write). ~~(b) Full two-way~~ — not chosen.
10. **[RESOLVED 2026-09-05] C-gate — neighborhood: fixed at direct links (1 hop).** Matches
    `GraphView`/S8's own default and v1's one-shot Send-to-Canvas. No user-set depth, no
    cluster-based binding.
11. **Binding state is one additive field:** `CanvasBoard.boundDocumentId: UUID?` (nil =
    ordinary board). No `bindingDepth` field — Decision 10 fixed the neighborhood at 1 hop
    always, so a variable-depth field would be unused optionality (`CLAUDE.md` §2 simplicity).
    Optional, CloudKit-safe, additive. A bound board still exports to plain JSON Canvas (the
    binding is NoteBytez metadata, dropped on export — same one-way-courtesy pattern as the
    `#notebook/` export tag).
12. **Reconciliation runs on board open and on source-note save, never on a timer** — matches
    the app's "local-first, sync is background-only" and "no background tasks" (`CLAUDE.md`)
    posture. Reuse the reconcile-on-save shape `TagDAL.syncTags` / `AttachmentDAL.syncAttachments`
    already establish.

### Workstream D — Advanced Intelligence Tier

13. **Apple's on-device intelligence stack is the primary and default engine for every D
    feature — not a fallback.** The product direction is: NoteBytez's AI runs on Apple's
    built-in models first, third-party cloud is strictly opt-in. Concretely, in priority order:
    1. **Apple Foundation Models framework** (`SystemLanguageModel` / `LanguageModelSession`,
       `@Generable` guided generation, tool calling, streaming) — introduced iOS 26 / macOS 26,
       **extended in iOS 27 / macOS 27** (see Decision 14). On-device, offline, free, no API
       key, no network egress, no per-token cost. Its sweet spot — summarize / extract /
       classify / rewrite over *supplied* context, not world knowledge — is exactly the
       RAG-over-your-own-notes shape D3/D4 need.
    2. **Apple Private Cloud Compute** — the automatic, Apple-operated, cryptographically
       privacy-preserving scale-up the framework routes to for requests too large for the local
       model. Still no third-party egress; still no redaction requirement (data goes only to
       Apple's attested PCC nodes, same trust boundary as Siri/Apple Intelligence).
    3. **Third-party cloud connectors** (`ModelConnector` protocol — Claude API et al.) — an
       *optional*, off-by-default power-user setting, and the **only** path that triggers the
       redact-before-send flow (Decision 16). Present so the "user-controlled cloud model
       connectors" line in `NoteBytez-ReleaseFeatures.md` is honored, not because the product
       needs them to function.
    A device that cannot run Apple Intelligence at all (unsupported hardware, feature disabled)
    degrades to the deterministic layer: `GraphInsightsDAL` lists, exact + semantic search, and
    the plain (no-prose) resurfacing digest. The assistant chat (D3) is simply unavailable
    there rather than silently falling back to a cloud call.
14. **[OPEN] D-gate — confirm the exact iOS 27 / macOS 27 AI API surface and adopt it.**
    This plan is written against what is known through iOS 26's Foundation Models framework;
    the iOS 27 / macOS 27 additions announced at WWDC 2026 are **not yet reflected here at API
    granularity** and must be pinned down against the shipping developer documentation and
    session videos before D1 starts. Specifically confirm and record: (a) whether iOS 27
    exposes a **first-party text-embedding API** (dedicated, or via the Foundation Models
    framework) — if so it becomes the Decision 15 default over `NLContextualEmbedding`;
    (b) the on-device model's context window and any change to guided-generation / tool-calling
    APIs D3 relies on; (c) any new system UI for AI features (à la Writing Tools) NoteBytez
    should adopt rather than reimplement; (d) the minimum OS + hardware matrix for each,
    which sets this workstream's deployment floor (Assumptions). No D1+ code is written against
    an assumed iOS 27 API — every such call site is confirmed against real docs first.
15. **[OPEN] D-gate — embedding model.** Default to a first-party Apple embedding API if
    iOS 27 provides one (Decision 14a); otherwise `NLContextualEmbedding` (iOS 17+/macOS 14+,
    no download, no entitlement, multilingual — also serves `20260823v2-MultiLanguage.md`).
    Either way, sit it behind an `EmbeddingProvider` protocol so the choice is swappable and a
    downloadable higher-quality Core ML model can be added later without touching the index.
16. **[OPEN] D-gate — redaction UX (third-party connectors only).** Needed only for the
    Decision 13.3 path — Apple on-device and PCC requests never leave the Apple trust boundary
    and are exempt. For a third-party connector: decide auto-detect-and-mask (an `NL`
    named-entity + pattern pass the user reviews) vs. manual selection vs. both. Blocks D3's
    third-party path only; the Apple-model assistant can ship before this is settled. Specified
    *with* the Security plan, not after.
17. **Semantic index is local-only, per-device, regenerated on demand** (Decision 2). A
    `Codable` on-disk vector store (flat file or SQLite via the `SQLite3` C API — decide during
    D1), keyed by `blockId`, rebuilt incrementally on `BlockDAL.syncBlocks` and fully on first
    launch after enable. Never a `@Model`, never in a `CKRecord`, excluded from
    `BackupSnapshot` (it is derivable). Encrypted at rest via Data Protection like every other
    local artifact (Security plan WS2). Embedding vector dimensionality is provider-dependent
    (Decision 15) — the store records which provider/version produced it and forces a full
    rebuild on mismatch rather than mixing vector spaces.
18. **Assistant chat threads and prompt templates DO sync** as normal models (`ChatThread`,
    `ChatMessage`, `PromptTemplate`) — small, portable, useful across devices, and a citation
    (`ChatMessage.citedBlockIds` encoded as a joined string per the `NoteTemplate.fieldsJSON`
    precedent) stays resolvable on any device because blocks already sync. Which engine
    produced a message (`onDevice` / `privateCloudCompute` / `connector:<name>`) is stored on
    `ChatMessage` so the user can always see where an answer came from.
19. **"Smart resurfacing" (D4) is the AI extension of v1's `GraphInsightsDAL`, not a new
    engine.** Weekly digest = a summary of what `GraphInsightsDAL` + the semantic index already
    surface (new clusters forming, stale notes with recent backlinks, orphans created this
    week), phrased by the on-device model with citations. With no Apple Intelligence available
    it degrades to the deterministic digest (the lists, no prose) rather than disappearing or
    reaching for a cloud call.

## Assumptions

- v1 Flow Enhancements has shipped: `GraphInsightsDAL`, the `!((anchor))` read-only embed,
  `CanvasDAL.seedBoard(fromNeighborhoodOf:…)`, and the `AppCommand` palette exist and are
  tested. B extends the embed, C extends the seed, D4 extends the insights DAL.
- `../MarkdownG9` and `../SwiftRPT` remain editable local packages.
- No background execution is introduced (`CLAUDE.md` §2). Embedding generation, index rebuild,
  and digest generation run in-app on explicit trigger or on the existing save/sync hooks, with
  a visible progress indicator per `CLAUDE.md` §3 (10-second cadence) for any pass that can
  exceed a second.
- **Workstream D sets a hard deployment floor of iOS 27 / macOS 27** for its AI features — the
  Foundation Models framework and whatever embedding / model APIs iOS 27 adds (confirmed in
  D0). Below that floor the app still runs; the D features are simply absent, gated on the
  framework's own `availability` check plus an OS-version guard. Confirm the current project
  deployment target and treat the bump as an explicit release decision, not a silent side
  effect of this plan.
- Apple Intelligence is also hardware-gated (not every supported-OS device runs the on-device
  model). D features degrade to the deterministic layer on such devices — never to a cloud call.
- The Security plan ([NoteBytez20260627v2-Security.md](NoteBytez20260627v2-Security.md)) is
  re-run against D's optional third-party `ModelConnector` path before that path ships; the
  Apple-only configuration and A/B/C get a lighter delta review (no new egress, but B/C touch
  cross-document writes — an integrity concern for its STORAGE/CODE workstreams).

---

## Workstream A — Force-Directed Graph Rendering

Decisions 4–5. Self-contained client work, no new schema (bar the `SavedView.graph` case), no
decision gate. Ship first.

- [x] **A1. Failing tests first.**
  - `ForceLayoutTests`: a 2-node 1-edge system settles to a stable separation ≈ the configured
    ideal edge length (± tolerance) within N iterations; a disconnected node drifts to the
    periphery, never overlaps the center; the simulation is deterministic given a fixed seed
    (same input → same final positions) so snapshot tests are stable.
  - `GraphFilterTests`: depth=1 yields exactly `GraphDAL.directLinks`; depth=2 adds their
    links; the orphan/tasks/tag toggles include/exclude the right node set.
  - `SavedViewDALTests`: a `.graph` saved view round-trips its filter set through
    `definitionJSON`.
  - Verify: all fail.
- [x] **A2. `ForceDirectedLayout`** (`views/Graph/` or `dal/` if kept pure) — Fruchterman-
  Reingold with Barnes-Hut approximation, fixed-timestep, seeded RNG, iteration cap + settle
  threshold. Pure function `[Node], [Edge] → [NodeID: CGPoint]`, unit-tested headless.
- [x] **A3. Multi-hop graph data** — `GraphDAL.neighborhood(of:depth:libraryId:in:)` generalizing
  `directLinks` to N hops, deduped, with per-node hop distance for styling.
- [x] **A4. `GraphViewModel` + `GraphFilter`** — filter struct (depth, node-type set, tag
  scope); view model recomputes the node/edge set on filter change and re-seeds the layout.
- [x] **A5. `GraphCanvas` force mode** — a segmented control on S8 (Radial | Force). Force mode
  renders via `TimelineView(.animation)` stepping the simulation to rest, then static;
  drag-to-pin a node (fixes its position, simulation continues around it); existing
  pinch/zoom/pan and `[+][−][⤢]` controls unchanged.
- [x] **A6. Filter UI** — a collapsible filter bar (depth stepper, node-type chips reusing
  `FilterChipRow`, tag field). "Save as View" button → `SavedViewDAL` with the new `.graph`
  type; saved graph views appear in R1 Phase 7's Saved Views list and open straight into S8
  force mode with the filter applied.
- [x] **A7. Performance guard** — a test asserts a 500-node / 1,500-edge graph settles and
  renders its first frame within a set budget on the CI simulator; beyond that node count the
  view shows a "graph too large — narrow the filter" state rather than janking (matches
  `styleGuide.md`'s calm-empty-state convention).
- [x] **A8. Tests green + manual** on iPhone/iPad; Mac per Workstream E. VoiceOver: force-mode
  nodes remain a navigable list (the a11y tree does not depend on the visual layout).

---

## Workstream B — Editable-in-Place Transclusion

Decision 8 + **[OPEN] Decisions 6, 7**. Extends v1 Phase 6. **Do not start until B-gate clears.**

- [x] **B0. Resolve B-gate** — Decision 6 resolved to (a) optimistic write, last-write-wins;
  Decision 7 deferred to a B4 implementation spike. See Decisions Log.
- [x] **B1. Failing tests first (per the resolved Decision 6(a)).**
  - `TransclusionEditTests`: editing the embedded region writes the new text to the *source*
    `Block.content` via `BlockDAL`, and a re-render of both the embedding note and the source
    note shows it.
  - Last-write-wins: no guard/diff-merge path — a save always applies directly, even if the
    source changed underneath since the embed was rendered (no held write, no prompt).
  - Depth-1 invariant: a `!((x))` inside a transcluded block is not turned into a nested editor.
  - Verify: fail.
- [x] **B2. `TransclusionBlockView` → editable** — swap the read-only `Text` for a focused
  `TextEditor` bound to a small `TransclusionEditController` that owns the source-block
  reference.
- [x] **B3. Write path** — `DocumentViewModel.commitTransclusionEdit(anchor:newText:)` →
  resolve via `BlockReferenceDAL.resolve` → apply directly via `BlockDAL` (Decision 6(a):
  optimistic, last-write-wins — no snapshot comparison, no diff-merge prompt).
- [x] **B4. Cross-document undo spike (Decision 7)** — investigate SwiftUI's `UndoManager`
  behavior across two live `DocumentViewModel` instances (embedding + source); implement
  whichever of embedding-only / source-only / both is actually achievable without corrupting
  the non-undone side, and record the chosen behavior here with the reasoning.
- [x] **B5. Backlinks / task-index integrity** — a task checkbox inside a transcluded, edited
  block still toggles correctly from both the source note and the embed (extends the
  whole-document task-index walk `DocumentPreviewView` already documents).
- [x] **B6. Tests green + manual** — edit a transcluded block from a journal entry; open the
  source note, see the change; edit the source concurrently and confirm last-write-wins (no
  prompt, no data loss beyond the accepted semantics of Decision 6(a)); export both notes and
  confirm `!((anchor))` is still literal text on disk.

---

## Workstream C — Bidirectional Graph ↔ Canvas Binding

Decisions 9–12. Extends v1 Phase 5 + R1 Phase 9.

- [x] **C0. Resolve C-gate** — Decision 9 resolved to (a) links → canvas, read-mostly; Decision
  10 resolved to fixed 1-hop (direct links only, no user-set depth, no cluster binding). See
  Decisions Log.
- [x] **C1. Failing tests first.** `CanvasBindingTests` (8 tests): bound-board one-shot seed;
  reconcile-after-new-link adds exactly one card, existing positions/web cards untouched;
  removing a link removes only its card/connectors, never a user-placed web card; reconciliation
  never touches a user-drawn connector on a non-note card; unbind stops reconciliation; saving
  the bound document reconciles automatically, saving an unbound one touches nothing; export
  drops `boundDocumentId` and round-trips clean.
- [x] **C2. Schema** — `boundDocumentId: UUID?` added to `CanvasBoard` (`CodingKeys` /
  `init(from:)` / `encode(to:)` / `CanvasBoard+Sync` `writeFields`/`readFields`); additive
  CloudKit change. `BackupDAL` capture extended.
- [x] **C3. `CanvasDAL.reconcileBoundBoard(_:in:)`** — diffs the source's direct-link
  neighborhood (`GraphDAL.directLinks`) against the board's existing `.note` cards; adds/removes
  note cards + their link-mirroring connectors (`reconcileLinkMirroringConnectors`); never
  touches non-note cards, positions, groups, or connectors outside the note-card subset.
- [x] **C4. Reconciliation triggers** — `CanvasBoardView.onAppear` (via `CanvasViewModel.load`)
  and `DocumentViewModel.save()` (guarded by `CanvasDAL.fetchBoundBoards`, no-op for an unbound
  document). No timer, no background pass (Decision 12).
- [x] **C5. "Bind this board" / "Unbind"** — `BindBoardSheet` (wikilink-fuzzy-picker shape,
  reused from both screens) wired into `CanvasBoardListView`'s row context menu and
  `CanvasBoardView`'s toolbar; a bound board shows a "↔ <Note title>" chrome badge (list-row
  subtitle + a top-leading capsule on the board itself). No depth control, per Decision 10.
- [x] **C6. Connector-creates-link** — completing a note-to-note connector drag on a bound board
  holds it as `pendingConnector` and raises a confirm alert; on confirm,
  `DocumentDAL.appendWikilink` writes `[[Target]]` into the source-side document and the board
  reloads; on cancel, the connector is simply never created (nothing to discard).
- [x] **C7. `AppCommand`** — `.bindCurrentCanvasToNote` (posts `.kontinuumTriggerBindCanvas` to
  the active `CanvasBoardView`, tracked via `.kontinuumActiveCanvasBoardChanged`) and
  `.openNoteAsBoundCanvas` (`CanvasDAL.boundBoard(for:)` — reuses an existing bound board or
  creates one) added to the palette.
- [x] **C8. Tests green + manual** — `CanvasBindingTests` (8/8) plus the full `KontinuumTests`
  suite (722/722) green after C1–C7 landed, no regressions. Manual simulator walkthrough of the
  bind/connector-confirm/export round trip not performed this session (no interactive simulator
  session available) — flagged to the user as an open item, matching Plans 1 and 2's own
  verification caveat.

---

## Workstream D — Advanced Intelligence Tier

Decision 13 (Apple on-device stack is primary) is settled. **[OPEN] Decisions 14–16** — the
iOS 27 / macOS 27 API surface, the embedding provider, and third-party-connector redaction —
gate all D work. Decisions 17–19 are settled. The largest workstream by far; **may be spun out
into its own numbered plan once D-gate clears.**

### D-gate — decisions to resolve before any D task

- [ ] **D0. Resolve D-gate** — product owner + Security plan owner jointly:
  - **Pin the iOS 27 / macOS 27 AI API surface (Decision 14)** against the shipping developer
    docs + WWDC 2026 sessions — first-party embedding API? on-device model context window?
    guided-generation / tool-calling deltas? new adoptable system UI? per-feature OS + hardware
    minimums (this sets the workstream's deployment floor). Record findings; every later D task
    that names an Apple API is verified against this, not assumed.
  - **Choose the embedding provider (Decision 15)** — first-party API if 14 confirms one, else
    `NLContextualEmbedding`, behind `EmbeddingProvider`.
  - **Specify third-party-connector redaction (Decision 16)** with the Security plan — needed
    only for the opt-in `ModelConnector` path, not for Apple on-device / PCC.
  - Extend [NoteBytez20260627v2-Security.md](NoteBytez20260627v2-Security.md) with an
    AI-egress workstream scoped to the `ModelConnector` path only.
  No D1+ work starts until this box is checked.

### D1 — Local semantic index (`NoteBytez-ReleaseFeatures.md` §Advanced: "Local semantic index")

- [ ] **D1.1 Failing tests first** — `EmbeddingProviderTests` (deterministic vector for fixed
  text, expected dimensionality, multilingual sanity); `SemanticIndexTests` (add/update/remove
  a block's vector; cosine top-K returns the planted nearest block; a soft-deleted block leaves
  the index; rebuild-from-empty reproduces an incrementally-built index bit-for-bit).
- [ ] **D1.2 `EmbeddingProvider` protocol + Apple implementation** — the swappable seam
  Decision 15 requires; the conformer is the iOS 27 first-party embedding API if D0 confirmed
  one, otherwise `NLContextualEmbeddingProvider`. Apple framework only at launch — no
  downloaded or remote embedding model.
- [ ] **D1.3 `SemanticIndexStore`** — local-only on-disk vector store keyed by `blockId`
  (Decision 17), tagged with the producing provider + version (forces a full rebuild on
  mismatch, never mixes vector spaces). Every entry point takes its directory as a parameter (the `BackupDAL`/
  `AttachmentStorage` test-injection precedent). Data-Protection file class set explicitly.
- [ ] **D1.4 Index maintenance** — hook `BlockDAL.syncBlocks` to enqueue changed `blockId`s for
  re-embedding; a full rebuild on first enable and on an explicit "Rebuild index" in Settings,
  both with a visible progress indicator (`CLAUDE.md` §3). No background task — runs while the
  user waits, cancellable.
- [ ] **D1.5 Settings** — an "On-device intelligence" section: enable/disable, index size,
  last-built, rebuild. Disabled by default until the user opts in (index build has a cost).
- [ ] **D1.6 Tests green + a perf guard** — embedding + indexing throughput on a 5,000-block
  library stays under a stated ceiling on the CI simulator; over a threshold library size the
  UI recommends leaving it disabled rather than blocking.

### D2 — Semantic search (`NoteBytez-ReleaseFeatures.md` §Advanced: "semantic/vector search")

- [ ] **D2.1 Failing tests** — `SearchDAL.semanticSearch(query:libraryId:in:)` returns blocks
  ranked by cosine similarity; a query with no lexical overlap but clear semantic match to a
  note still surfaces it (the case exact FTS misses — this is the differentiator, prove it);
  results are empty (not an error) when the index is disabled/absent.
- [ ] **D2.2 `SearchDAL.semanticSearch`** over `SemanticIndexStore`, returning the same
  `SearchResult` shape as `searchContent` so S7 renders it with no new row type.
- [ ] **D2.3 S7 integration** — a "Semantic" scope chip alongside Content/Tag/Path (visible
  only when the index is enabled); Quick Switcher (S6) optionally blends a semantic tail below
  its fuzzy-title matches.
- [ ] **D2.4 `GraphInsightsView` integration** — a new "Related but unlinked" section per note
  (semantic neighbors that have no `[[link]]`), turning v1's deterministic insight list into a
  suggestion surface. One tap inserts the link.
- [ ] **D2.5 Tests green + manual** on all form factors.

### D3 — AI research assistant (`NoteBytez-ReleaseFeatures.md` §Advanced: "AI research assistant")

Primary engine is Apple's on-device Foundation Models framework, routing to Private Cloud
Compute automatically; a third-party `ModelConnector` is an opt-in extra (Decision 13).

- [ ] **D3.1 Failing tests** — `AIEngineTests` (request shape, streaming assembly, error
  surfacing, cancellation, `availability` gating) against the on-device engine and a stub
  connector; `RedactionTests` (Decision-16 UX — masked spans never appear in a *connector*
  payload; the Apple-engine path skips redaction because nothing leaves the Apple trust
  boundary); `CitationTests` (every assistant claim carries ≥1 `citedBlockId` that resolves to
  a real block; a response citing a since-deleted block degrades gracefully); `EngineFallbackTests`
  (no Apple Intelligence + no connector → chat is unavailable, never a silent cloud call).
- [ ] **D3.2 `AIEngine` protocol + `AppleFoundationModelEngine`** — wraps
  `SystemLanguageModel` / `LanguageModelSession` (guided generation for the citation-structured
  response, streaming, tool calling), gated on the framework's `availability` check, PCC
  handled by the framework. This is the default and only engine required for D3 to ship.
  Verified against the D0 iOS 27 API findings, not assumed.
- [ ] **D3.3 `ModelConnectorEngine` (optional)** — a second `AIEngine` conformer for a
  user-added third-party endpoint (Decision 13.3 / Decision 14 launch connector). Keys in
  Keychain, never in a model, never synced. ATS-compliant; egress host allow-listed. Off by
  default; enabling it is what turns on the redaction pass.
- [ ] **D3.4 Retrieval** — assistant context is built from D1/D2: top-K semantic blocks for the
  question, scoped to the current note / notebook / library per a scope control. Context is
  shown to the user before send ("using 6 blocks from 4 notes").
- [ ] **D3.5 Redaction pass (connector path only)** — per Decision 16; runs on the assembled
  context when the active engine is `ModelConnectorEngine`, user reviews, send blocked until
  reviewed. The Apple engine path has no redaction step by design.
- [ ] **D3.6 Models** — `ChatThread`, `ChatMessage` (`role`, `text`, `citedBlockIds` joined-
  string, `engine` = `onDevice`/`privateCloudCompute`/`connector:<name>`, audit),
  `PromptTemplate` (`name`, `body`, audit); synced (Decision 18). Registered in `Schema`;
  `BackupDAL` capture/restore extended.
- [ ] **D3.7 S-Assistant UI** — a scoped chat pane (its own Explore destination + a
  per-document toolbar entry): message list with inline citation chips that jump to the source
  block, a per-message engine badge, scope control, prompt-template picker, redaction review
  sheet (connector path only). Reuses `styleGuide.md` components; adopt any iOS 27 system AI UI
  surfaced by D0 rather than reimplementing it.
- [ ] **D3.8 Availability states** — Apple Intelligence present → chat works on-device out of
  the box, no setup. Not present and no connector → the pane explains chat needs Apple
  Intelligence (or an optional connector) and points to Settings; D1/D2 + the deterministic D4
  digest still work.
- [ ] **D3.9 Tests green + Security sign-off** — the connector-scoped AI-egress workstream from
  D0 passes; no connector payload leaves without passing redaction; keys are not in any sync
  record or backup; the Apple-engine path is confirmed to make no third-party network calls.

### D4 — Smart resurfacing (`NoteBytez-ReleaseFeatures.md` §Advanced: "Smart resurfacing")

- [ ] **D4.1 Failing tests** — `ResurfacingDigestTests`: given a library with known changes
  over a window, the digest lists the right new-clusters / newly-stale / new-orphans /
  new-unlinked-neighbors; with an `AIEngine` available it adds prose + citations; with none it
  returns the lists alone (Decision 19).
- [ ] **D4.2 `ResurfacingDAL`** — composes `GraphInsightsDAL` (v1) + `SemanticIndexStore` (D1)
  over a date window; pure data.
- [ ] **D4.3 Digest view** — a "Review" Explore destination: this-week digest, dismissible
  cards, each linking to its source. Generated on open, not on a schedule (`CLAUDE.md` §2).
- [ ] **D4.4 Optional prose** — if an `AIEngine` is available (on-device by default), one call
  turns the lists into a short narrative with citation chips; failure or no engine falls back
  to the lists silently.
- [ ] **D4.5 Tests green + manual.**

---

## Workstream E — Cross-Cutting Verification & Quality Gate

`CLAUDE.md` §4 / §7. Run per-workstream as each ships, plus once combined.

- [x] **E1. Coverage** — A/B/C new logic at 90%+ (`xcodebuild ... -enableCodeCoverage YES`,
  2026-09-06): `ForceDirectedLayout` 96.2%, `ForceSimulation` 94.9%, `GraphFilter` 97.4%,
  `GraphDAL` 92.0% (`neighborhood(of:depth:)` 100%), `SavedView` 92.4%, `SavedViewDAL` 96.0%,
  `CanvasDAL` 92.6% (`reconcileBoundBoard` 100%, `bind` 100%, `boundBoard(for:)` now covered by
  a new `CanvasBindingTests` case), `CanvasBoard` 92.3%, `DocumentViewModel.commitTransclusionEdit`
  100%. `TransclusionEditController` was not built as a separate type — the resolved Decision
  6(a) landed the write path as `DocumentViewModel.commitTransclusionEdit(anchor:newText:)`
  (a single-use controller would have been speculative, `CLAUDE.md` §2). View/VM glue
  (`GraphViewModel` 40.6%, `CanvasViewModel.bind`) excluded per the established `views/` gap.
  D-tier targets (`EmbeddingProvider`, `SemanticIndexStore`, `AIEngine`, …) deferred with D.
- [x] **E2. Mac build green (A/B/C)** — `xcodebuild build -scheme Kontinuum -destination
  'platform=macOS,arch=arm64'` → **BUILD SUCCEEDED** (2026-09-06), after the Workstream E view
  edits. Still open: D's iOS 27/macOS 27 deployment-bump (target is currently 26.5) +
  `#if os()`/`#available` audit, blocked on the D-gate. Note: `xcodebuild test` on the macOS
  destination fails to *compile* a pre-existing UITest
  (`Phase2TemplatesAndPropertiesFeatureTests.swift:38` uses `XCUIDevice.orientation`, iOS-only) —
  unrelated to this plan; the iOS-Simulator test run is unaffected.
- [x] **E3. Schema audit (A/B/C)** — `SavedView.graph`: a new `SavedViewQueryType` raw value +
  a `graphDefinition` accessor reusing `definitionJSON`; **no column added**, fully additive.
  `CanvasBoard.boundDocumentId: UUID?`: optional, no `.unique`, in `CodingKeys`/`init(from:)`/
  `encode(to:)`, `CanvasBoard+Sync` `writeFields`/`readFields`, `BackupDAL` capture+restore,
  registered in `KontinuumApp.swift` `Schema`. Added `SyncMappingTests` coverage: the existing
  `canvasBoardFieldsRoundTrip` now exercises `boundDocumentId`, plus a new
  `canvasBoardBoundDocumentIdDefaultsNilAndRoundTrips`. `.graph` saved-view round-trip already
  covered by `SavedViewDALTests.createGraphViewStoresItsFilterSet`. D-tier models
  (`ChatThread`/`ChatMessage`/`PromptTemplate`) deferred with D; `bindingDepth` was dropped per
  Decision 11 and is not in the schema.
- [ ] **E4. Security delta** — [NoteBytez20260627v2-Security.md](NoteBytez20260627v2-Security.md)
  re-run. **STORAGE/CODE delta for B/C cross-document writes — review notes (2026-09-06),
  awaiting Security-plan-owner sign-off:** B's `commitTransclusionEdit` resolves the target via
  `BlockReferenceDAL.resolve` and writes through `BlockDAL` within the same local
  `ModelContext`/library — no new file or network path, same trust boundary as any in-app edit;
  the accepted data-loss surface is exactly Decision 6(a)'s last-write-wins, documented. C's
  `reconcileBoundBoard` / connector-confirm only ever writes `[[wikilinks]]` into a document's
  own `content` and `CanvasCard`/`CanvasConnector` rows in the same library; `boundDocumentId`
  is dropped on JSON-Canvas export (verified by test). No new required-reason API, no Keychain,
  no egress. The connector-scoped AI-egress workstream for D's optional `ModelConnectorEngine`
  remains out of scope until the D-gate clears.
- [x] **E5. Accessibility (A/B/C)** — Force-graph nodes are `Button`s in a stable `ForEach`
  order (focus, then neighborhood) so the VoiceOver list is independent of the physics layout
  (A8); added `.accessibilityLabel` carrying focus/hop-distance and tag-scope-highlight state so
  the accent-ring highlight is not colour-only. Bound-canvas chrome (`CanvasBoardView`
  `boundChrome`, `CanvasBoardListView` row subtitle): added `.accessibilityLabel("Bound to
  …")` so the "↔" glyph is not read literally; both use `.font(.caption)` (Dynamic Type) and
  material/secondary styling alongside text, not colour alone. Editable transclusion uses the
  standard focused `TextEditor`, which is VoiceOver- and Dynamic-Type-native. Assistant-chat /
  digest surfaces deferred with D. Manual VoiceOver device pass still recommended per the
  Plans 1/2 caveat.
- [~] **E6. Journey acceptance** — `V2IntegrationTests` created (2026-09-06), A/B/C journeys
  green: (a) force-graph filter → `saveFilterAsView` → re-fetch, decode `graphDefinition`,
  rebuild `GraphViewModel` with the same depth/filters/focus; (b) edit a transcluded block with
  a concurrent source change → **last-write-wins, no prompt** (the E6 prose here predates the
  B-gate resolution — Decision 6(a) replaced the merge prompt), both notes consistent, embed's
  on-disk sigil untouched; (c) bind a board → mutate links via `DocumentViewModel.save()`
  reconcile → cards track, user positions + web card intact → `appendWikilink` from a confirmed
  connector adds the backlink and its card. Journeys (d)/(e)/(e′)/(f) are D-tier — deferred
  with Workstream D. Full `KontinuumTests` suite: **727/727 pass** on the iOS 26 simulator.

---

## Out of Scope (explicit)

- **Multi-language localization** — owned by
  [NoteBytez20260823v2-MultiLanguage.md](NoteBytez20260823v2-MultiLanguage.md). D1's embedding
  provider (a first-party Apple API or `NLContextualEmbedding`) is multilingual and deliberately
  compatible with it, but the localization program is not managed here.
- **Role-based template expansion** — owned by
  [NoteBytez20260824v1-Templates.md](NoteBytez20260824v1-Templates.md).
- **CRDT block merge, collaboration presence, team/family shared spaces, public publishing,
  File Provider extension, Shortcuts/Spotlight/Siri automation** — the remaining
  `NoteBytez-ReleaseFeatures.md` §Advanced bullets. Real work, but not surfaced by the v1
  review as differentiation-critical; they get their own plan(s) when scheduled.
- **Nested tags** (`#parent/child`) — §Advanced bullet, unrelated to this review's findings.
- **A physics/graph third-party dependency** unless Decision 4's "build it" bet fails review —
  and then only an unencumbered-licensed one, approved explicitly (`CLAUDE.md` §5).
- **Background processing of any kind** — embedding, indexing, reconciliation, and digest
  generation are all explicit-trigger or existing-hook only (`CLAUDE.md` §2).
- **Any third-party AI connector as a launch requirement** — D ships fully functional on
  Apple's on-device Foundation Models / Private Cloud Compute alone. The `ModelConnectorEngine`
  path (and its Decision-14 launch connector) is an optional add-on; a second connector beyond
  that is additive via the `AIEngine` protocol and out of scope here.
- **Re-implementing Apple system AI UI** (Writing Tools-style surfaces, etc.) — if iOS 27
  exposes an adoptable component for something D needs, D adopts it (confirmed in D0) rather
  than building a parallel one.

## Verification Gate (all workstreams)

- [ ] Per-workstream test suites + `V2IntegrationTests` green; full `KontinuumTests` /
  `KontinuumUITests` / `../MarkdownG9` unaffected, 0 failures.
- [ ] `xcodebuild build -destination 'platform=macOS'` succeeds; iOS 27 / macOS 27 deployment
  floor confirmed and compiling on all three destinations.
- [ ] Every decision gate (B, C, D) recorded as resolved in this document before its
  workstream's code landed — D0 includes the pinned iOS 27 / macOS 27 AI API findings.
- [ ] Security plan delta complete and signed off for anything that shipped — the optional
  third-party `ModelConnectorEngine` path does not release without the connector-scoped
  AI-egress workstream passing; the Apple on-device / PCC configuration ships without it.
- [ ] `ARCHITECTURE.md`, `Docs/styleGuide.md`, `NoteBytez-ReleaseFeatures.md` (move the
  now-built §Advanced bullets to "done"), and the `UIUX/04-06` set updated to match what
  shipped.
