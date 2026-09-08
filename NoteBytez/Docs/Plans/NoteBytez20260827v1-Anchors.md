<!-- 20260827v1-Anchors.md -->
<!--
  Three related improvements to how blocks are anchored and referenced. Keeps the current
  blank-line block model (see MarkdownBlockSplitter) — this does NOT move blocks to a
  heading-scoped/nested structure. It layers heading awareness, identity stability, and a
  section-link syntax on top of the model that already ships.

  Living document. Checkbox convention: [ ] not started / in progress, [x] done and verified
  (builds + its test passes). TDD per CLAUDE.md — the failing test is the first task of each
  feature, never an afterthought.

  Phases are ordered by build dependency: Feature A (heading path) produces the `headingPath`
  data that Feature B's identity heuristic and Feature C's section resolver both consume.
-->

# Heading-Aware Anchors, Sticky Block Identity, Section Links

## User Story

As a knowledge worker, I want block anchors that stay meaningful and stable as I edit a note,
and a way to link to a *section* of a note distinct from linking to a single *thought*, so my
`((block))` references and `[[note]]` links don't silently rot as documents grow.

## Background — why, not what

`BlockDAL.syncBlocks` re-splits a document on every save and reconciles blocks by **exact
content match**. Two consequences a knowledge worker hits within a week:

1. **Anchors are unstable and collide.** `BlockDAL.anchor(for:)` slugs the first six words of a
   block's first line; `uniqueAnchor` disambiguates collisions with a positional `-2`/`-3`
   suffix. Edit the first line and the anchor changes; reorder two same-titled sections and
   `notes` vs `notes-2` swap. Any `((notes))` reference elsewhere now points at the wrong block
   or nothing.
2. **Identity churns on every edit.** Exact-content-match means fixing a typo in a referenced
   block mints a brand-new `blockId` and a brand-new `anchor`. Inbound `((anchor))` references
   and block backlinks break with no warning.

Separately, `[[Title]]` can only target a whole document. There is no `[[Title#Heading]]` — the
standard "link to a section" affordance every comparable tool has.

This plan fixes all three **without** changing the block model itself. Blocks stay blank-line
delimited and flat.

## Decisions Log

1. **Heading context is stored, not computed on read.** Add `Block.headingPath: String?` — the
   `>`-joined raw titles of the ATX headings enclosing the block (`"Q3 Planning > Financials"`;
   `nil` at document root). Stored because three call sites need it (anchor disambiguation,
   identity heuristic, section-link resolution) and recomputing a heading scan in each is
   wasteful and drift-prone. It is derived data — always rewritten by `syncBlocks`, never
   user-edited — so no migration risk beyond a one-time backfill (Phase A4).

2. **ATX headings only (`#`..`######`), fence-aware.** Setext headings (`===` / `---`
   underlines) are out of scope for v1 — rare in app-authored notes, and detecting them needs
   look-ahead the current line-at-a-time splitter doesn't do. A `#` inside a ``` or `~~~` fence
   is not a heading (the splitter already tracks fence state).

3. **Anchor stays a single slug in the common case.** `headingPath` is metadata, not the anchor
   format. A block whose own slug is unique in its document keeps exactly the anchor it has
   today — no churn for existing references. Only on collision does disambiguation change: walk
   up `headingPath` prepending slugified segments (`financials-budget`, then
   `q3-planning-financials-budget`) instead of appending `-2`. Numeric suffix remains the last
   resort for genuinely identical blocks (same text, same heading path).

4. **Identity: a second "reclaim" pass, exact-match unchanged.** Feature B does not touch the
   existing exact-content-match pass (it already handles pure reorder correctly — match is by
   content, not position). It adds a pass *after* it: pair each still-unmatched new chunk with a
   still-unmatched soft-deleted-this-save block when they are "clearly the same," reuse that
   `blockId` **and keep the old `anchor`**. "Clearly the same" =
   `(same flat index) AND (same headingPath)`, OR normalized Levenshtein similarity ≥ 0.7.
   Greedy best-score, deterministic index tie-break, strictly 1:1.

5. **Levenshtein is hand-rolled and bounded.** No Swift stdlib edit-distance; a two-row DP is
   ~20 lines (`StringSimilarity.swift`). Bounded: pairs where `max(len)/min(len) > 2` or
   `max(len) > 4000` skip the DP and fall back to the index+headingPath test only. Keeps
   `syncBlocks` within a few ms on note-sized input.

6. **Section links reuse the wikilink pipeline, not a new one.** `[[Title#Heading]]` — the
   `#Heading` is an optional suffix on the existing `[[ ]]` syntax. `WikilinkParser.extractTitles`
   keeps returning just `Title`, so document-level backlinks and rename propagation keep working
   unchanged; `[[A#B]]` is still a backlink to A. A new `parseTarget` exposes the split.

7. **Section-link navigation v1 = open the document, best-effort scroll.** The whole-document
   preview is one `Text(MDProcessor.process(...))` with no per-heading anchors
   (`DocumentPreviewView`). Restructuring it into addressable segments is out of proportion
   here. v1: resolve `[[Title#Heading]]` to `(Document, Block?)`, navigate to the document, and
   pass the target `headingPath` through so `DocumentView` scrolls to it *when the line-by-line
   render path is active*; otherwise open at top. The resolver and the passed-through target are
   the durable part — the scroll polish can land later without rework.

8. **`MarkdownG9` / `MDProcessor` change is additive and minimal.** `MDProcessor` rewrites
   `[[x]]` to a `wikilink://x` URL. It must emit `wikilink://Title#Heading` for the section case
   with the `#` left un-encoded so `URL.fragment` splits it. If `../MarkdownG9` already produces
   a usable fragment (verify first — Phase C1), no package change is needed and the app-side
   `OpenURLAction` just starts reading `url.fragment`.

## Assumptions

- The block model stays as-is: `MarkdownBlockSplitter` blank-line chunks, flat `sortOrder`,
  soft-delete via `isActive`. Nothing in this plan nests blocks or makes their text overlap.
- `Block` gains exactly one stored field (`headingPath`). Per `ARCHITECTURE.md` Model
  Conventions it is `String?`, placed with the domain fields (before audit fields), added to
  `CodingKeys` / `init(from:)` / `encode(to:)` and to `Block+Sync`'s `writeFields`/`readFields`.
  CloudKit schema change is additive (new optional field) — safe.
- `../MarkdownG9` is editable in this workspace (it is a local package per `ARCHITECTURE.md`).
- No UI redesign. New affordances reuse `WikilinkText` / `BlockReferenceText` styling.

---

## Feature A — Heading-aware anchors

Produces `Block.headingPath` and switches collision disambiguation from `-N` to section path.

- [x] **A1. Failing tests first.**
  - `MarkdownBlockSplitterTests`: `split(withHeadingContext:)` returns, for
    `"# A\n\npara1\n\n## B\n\npara2\n\n# C\n\npara3"`, chunk→path pairs
    `[("# A", []), ("para1", ["A"]), ("## B", ["A"]), ("para2", ["A","B"]), ("# C", []), ("para3", ["C"])]`.
  - Heading inside a fence is not a heading. Level jump (`#` → `###`) pushes without a phantom
    middle level. Content before any heading has `[]`.
  - `BlockDALTests`: two blocks with identical first-line text under different headings get
    anchors `b-budget` / `a-budget` (path-disambiguated), **not** `budget` / `budget-2`.
  - `BlockDALTests`: a single unique block's anchor is byte-identical to today's output
    (no-churn guard).
  - Verify: all four fail.

- [x] **A2. `MarkdownBlockSplitter.split(withHeadingContext:)`.** New method returning
  `[(content: String, headingPath: [String])]`. Keep the existing `split(_:)` untouched —
  `TaskDAL`, `NotebookDAL`, `MarkdownDiffMerge` callers don't need the context and shouldn't pay
  for it. Maintain a heading stack while scanning: on a line matching `^#{1,6}\s+` (and not
  inside a fence), pop the stack to `level-1`, the block *is* that heading line with the path
  as-of *before* the push, then push its title. → verify: A1 splitter tests pass.

- [x] **A3. `Block.headingPath` field + plumbing.** Add `var headingPath: String?` to `Block`
  (domain-field position), `CodingKeys`, `init(from:)`, `encode(to:)`, and
  `Block+Sync.writeFields` / `readFields` (`record["headingPath"]`). Register nothing new in
  `NoteBytezApp.swift` `Schema` (same `Block` type). → verify: `SyncMappingTests` still green;
  add one asserting `headingPath` round-trips through `writeFields`/`readFields`.

- [x] **A4. `syncBlocks` sets `headingPath`; path-based disambiguation.**
  - `syncBlocks` switches to `split(withHeadingContext:)`. Every result block (reused or new)
    gets `block.headingPath = path.joined(separator: " > ")` (nil if empty).
  - `uniqueAnchor(for:used:)` gains the block's `headingPath` segments. Collision resolution:
    try the bare slug; then `slug(lastPathSegment)-baseSlug`; then prepend successive
    higher segments; only then `-2`, `-3`.
  - A reused block whose text is unchanged but whose `headingPath` changed (heading above it
    was renamed) keeps its `anchor` (Decision 3 — no churn) but updates `headingPath`.
  - → verify: A1 `BlockDALTests` pass; existing `BlockDALTests` still green.

- [x] **A5. One-time backfill.** On app launch, if any active `Block` has `nil` `headingPath`,
  re-run `syncBlocks` for its owning documents once. Cheapest correct place: a guarded pass in
  the same startup path that the Phase-4 block work already uses (confirm where; if none,
  `NoteBytezApp` `.task`). → verify: integration test — seed a pre-migration block (nil path),
  launch, assert path populated and `blockId` **unchanged**.

- [x] **A6. Surface `headingPath` in pickers/backlinks.** `BlockReferenceText` and the
  `((`-autocomplete row (`DocumentView` ~L164, `TodayJournalView` ~L199) show `headingPath` as
  secondary caption text when present. `BlockReferenceDAL` backlink/autocomplete matching also
  matches against `headingPath` so "budget" finds "Financials > Budget". → verify:
  `BlockReferenceDALTests` case for a path-only query hit; manual check of the picker.

---

## Feature B — Sticky block identity

Depends on A (uses `headingPath`). Stops `blockId`/`anchor` churn on in-place edits.

- [x] **B1. Failing tests first (`BlockDALTests`).**
  - Edit one word in a referenced block → `blockId` **and** `anchor` unchanged; `content`
    updated.
  - Block moved *and* lightly edited → still reclaims its `blockId`.
  - Block deleted outright (text gone, nothing similar) → soft-deleted, no false reclaim.
  - Block split into two by an inserted blank line → the larger remnant keeps the `blockId`,
    the other is new.
  - Two near-identical blocks both edited → deterministic 1:1 mapping (document order).
  - Verify: all fail.

- [x] **B2. `StringSimilarity.swift`** (`NoteBytez/dal/` or a `Utilities/` group to match repo
  layout). `similarity(_:_:) -> Double` = `1 - levenshtein / max(len)`, two-row DP, `Character`
  arrays. Bounds per Decision 5. Unit tests: identical → 1.0; disjoint → ~0.0; one-word edit in
  a sentence → > 0.9; length-ratio bail returns a sentinel the caller treats as "not similar".

- [x] **B3. Reclaim pass in `syncBlocks`.** After the existing exact-match loop, before the
  soft-delete loop:
  - Collect unmatched new chunks (currently the `else` branch that inserts a new `Block`) and
    unmatched still-active existing blocks.
  - Candidate pair is eligible if `sameIndex && sameHeadingPath`, or
    `StringSimilarity.similarity(oldContent, newChunk) >= 0.7`.
  - Rank eligible pairs by `(similarity desc, |Δindex| asc, oldSortOrder asc)`; assign greedily,
    1:1.
  - On assignment: reuse `blockId`, **keep `anchor`**, set `content`, `sortOrder = newIndex`,
    `headingPath`, `updatedOn`; drop it from the to-be-soft-deleted set and from the new-inserts
    set.
  - → verify: B1 passes; full `BlockDALTests` + `BlockReferenceDALTests` + `TaskDALTests` green
    (TaskDAL keys reuse by `sortOrder`, which the reclaim pass sets correctly).

- [x] **B4. Guard `TaskDAL` / `NotebookDAL` splice assumptions.** Both locate a block by
  `sortOrder` index into `MarkdownBlockSplitter.split(...)` then verify `chunks[i] == blockContent`
  before splicing. The reclaim pass can now leave a reused block whose `content` was updated to
  match the chunk, so the existing equality guard still holds — add a `TaskDALTests` /
  `NotebookDALTests` case exercising "toggle a task in a block that was reclaimed (not
  exact-matched) on the previous save" to lock that in. → verify: those pass.

---

## Feature C — Section links `[[Title#Heading]]`

Depends on A (`headingPath` for resolution). Independent of B.

- [x] **C1. Verify `MDProcessor` behaviour + failing tests.**
  - Check `../MarkdownG9` `MDProcessor`: what does it emit for `[[A#B]]` today? Record whether
    `URL(string:)` of the output yields `host == "A"`, `fragment == "B"`.
  - `WikilinkParserTests`: `parseTarget("A#B")` → `(title: "A", heading: "B")`;
    `parseTarget("A")` → `(title: "A", heading: nil)`; `extractTitles("x [[A#B]] y")` → `["A"]`
    (unchanged); `renamingWikilinks(from:"A",to:"C")` on `"[[A#B]]"` → `"[[C#B]]"` (suffix
    preserved).
  - `DocumentViewModelTests`: `resolveSectionLink(title:"Note", heading:"Setup")` returns the
    block in "Note" whose `headingPath` last segment (or own heading line) slugifies to
    `setup`.
  - Verify: fail.

- [x] **C2. `WikilinkParser` — parse + rename.** Add
  `parseTarget(_ raw: String) -> (title: String, heading: String?)` splitting on the first `#`.
  Update `renamingWikilinks(from:to:)` regex to `\[\[<old>(#[^\]]*)?\]\]` with a template that
  re-emits the captured `#...` group. Leave `extractTitles` / `activeQuery` / `applying`
  behaviour for the plain case identical. → verify: C1 parser tests pass; existing
  `WikilinkParserTests` + `DocumentDALTests` (rename propagation) green.

- [x] **C3. Resolver.** `DocumentViewModel.resolveSectionLink(title:heading:) -> (Document, Block?)`:
  resolve the document via the existing `resolveWikilink` path, then among that document's
  `BlockDAL.fetchActive` pick the block whose own heading-line slug, else last `headingPath`
  segment slug, matches `slugify(heading)`. Nil block ⇒ heading not found, still navigate to the
  document. → verify: C1 view-model test passes.

- [x] **C4. Autocomplete for the `#` segment.** In `DocumentView` / `TodayJournalView` where
  `activeWikilinkQuery` drives the suggestion strip: if the in-progress query contains `#`,
  swap the source from titles to
  `DocumentViewModel.headingSuggestions(forDocumentTitled:matching:)` — parse that document's
  content with `split(withHeadingContext:)`, collect heading lines, fuzzy-filter by the
  post-`#` text. `insertWikilink` writes `[[Title#Heading]]`. → verify: `DocumentViewModelTests`
  for `headingSuggestions`; manual check the strip switches after typing `#`.

- [x] **C5. `MDProcessor` emit (only if C1 showed it's needed).** In `../MarkdownG9`, extend the
  `[[ ]]` rewrite to carry a `#heading` suffix into the URL as an un-encoded fragment
  (`wikilink://Title#Heading`, with `Title` percent-encoded but the `#` literal). Add a
  `MarkdownG9` test. If C1 showed the fragment already survives, skip this and note it. →
  verify: package tests green; `DocumentPreviewView` renders the link as tappable.

- [x] **C6. Navigation + best-effort scroll.** In the `OpenURLAction` `case "wikilink"` blocks
  (`DocumentView` ~L250, `TodayJournalView` ~L227): read `url.fragment`; if present call
  `resolveSectionLink` and set `wikilinkTarget` to the document, threading the target
  `headingPath` into the pushed `DocumentView` (new optional init param). On appear, if that
  param is set and the preview is on the line-by-line path, wrap `LineBasedPreview` rows in a
  `ScrollViewReader` keyed by heading and `scrollTo` it; else no-op (opens at top). → verify:
  UI test — tap a `[[Note#Heading]]` link, assert the target document view appears; scroll
  assertion only where the line-by-line path is active.

- [x] **C7. Docs.** Add `[[Note#Heading]]` to whatever user-facing syntax reference exists
  (`Docs/`), and a one-line note in `ARCHITECTURE.md` §Markdown parsing that section links
  reuse the wikilink URL scheme with a fragment. → verify: linkcheck / manual read.

---

## Out of scope (explicit)

- Nesting blocks or making block text overlap (the heading-scoped model discussed and rejected).
- Restructuring `DocumentPreviewView` into fully addressable per-heading anchors — C6 is
  best-effort only.
- Section-level *transclusion* (embedding a whole section inline). `((block))` embed semantics
  are unchanged.
- Setext (`===` / `---`) headings.
- A persisted link index — backlinks stay computed-on-demand per `BacklinkDAL`'s existing
  rationale.

## Verification gate (all features)

- [x] `MarkdownBlockSplitterTests`, `BlockDALTests`, `BlockReferenceParserTests`,
  `BlockReferenceDALTests`, `WikilinkParserTests`, `DocumentDALTests`, `DocumentViewModelTests`,
  `TaskDALTests`, `NotebookDALTests`, `SyncMappingTests`, `BackupDALTests` — all green.
- [x] New: `StringSimilarityTests`, splitter heading-context cases, sticky-identity cases,
  section-link parser/resolver/autocomplete cases.
- [ ] Manual: rename a heading above a referenced block → `((anchor))` still resolves; typo-fix
  a referenced block → reference still resolves; `[[Note#Heading]]` navigates.
- [x] `../MarkdownG9` test suite green if C5 was taken.
