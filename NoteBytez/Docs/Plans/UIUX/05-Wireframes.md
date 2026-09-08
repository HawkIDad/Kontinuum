<!-- 05-Wireframes.md -->
<!--
  Part of the NoteBytez UIUX Research deliverable set. See ../../../NoteBytez20260813-UIUX-Research.md for scope/plan.
  Low-fidelity ASCII wireframes, layout/hierarchy only, no visual styling. One set per screen (S1-S15 from
  04-InteractionDesign.md), equal detail across iPhone / iPad / Mac per the interview decision.
  iPad shown in landscape (split view); portrait collapses to the iPhone layout with wider margins.
-->

# Interface Design / Wireframes

Screens correspond 1:1 to the sitemap in [04-InteractionDesign.md](04-InteractionDesign.md). Each screen shows three widths — Mac (~70 cols), iPad landscape (~50 cols), iPhone (~34 cols) — to reflect the container differences described there, not different content.

---

## S1 — Library Creation / Selection

**Mac**
```
┌────────────────────────────────────────────────────────────────┐
│                          NoteBytez                                │
│                                                                    │
│   ┌─────────────────────────┐    ┌─────────────────────────┐     │
│   │  + Create New Library      │    │  Import Existing Library   │     │
│   └─────────────────────────┘    └─────────────────────────┘     │
│                                                                    │
│   Recent Libraries                                                   │
│   • Personal Notes        ~/Documents/Notes                       │
│   • Work Library            ~/iCloud/Work                           │
└────────────────────────────────────────────────────────────────┘
```

**iPad (landscape)**
```
┌──────────────────────────────────────────┐
│               NoteBytez                    │
│                                              │
│  ┌───────────────────┐ ┌───────────────┐   │
│  │ + Create New Library │ │ Import Library  │   │
│  └───────────────────┘ └───────────────┘   │
│                                              │
│  Recent Libraries                              │
│  • Personal Notes                           │
│  • Work Library                               │
└──────────────────────────────────────────┘
```

**iPhone**
```
┌──────────────────────────┐
│        NoteBytez           │
│                             │
│ ┌───────────────────────┐ │
│ │ + Create New Library     │ │
│ └───────────────────────┘ │
│ ┌───────────────────────┐ │
│ │ Import Existing Library  │ │
│ └───────────────────────┘ │
│                             │
│ Recent Libraries               │
│ • Personal Notes             │
│ • Work Library                 │
└──────────────────────────┘
```

**Elements:** app title, primary CTA pair (create/import), recent-libraries list. iPhone stacks the CTAs instead of placing them side by side.

---

## S2 — Import Scan & Confirm

**Mac**
```
┌────────────────────────────────────────────────────────────────┐
│  Import Preview                                          [Cancel] │
│  ────────────────────────────────────────────────────────────── │
│  247 notes · 1,204 wikilinks · 389 tasks · 0 notebooks found      │
│                                                                    │
│  File                          Links   Tasks                      │
│  ─────────────────────────────────────────────                   │
│  Projects/NoteBytez.md            12      4                       │
│  Journal/2026-08-01.md             3      2                       │
│  Areas/Health.md                   8      0                       │
│  ...                                                               │
│                                                                    │
│                                        [ Confirm Import ]          │
└────────────────────────────────────────────────────────────────┘
```

**iPad (landscape)**
```
┌──────────────────────────────────────────┐
│ Import Preview                  [Cancel]   │
│ ─────────────────────────────────────────│
│ 247 notes · 1,204 links · 389 tasks · 0 notebooks │
│                                              │
│ Projects/NoteBytez.md         12L  4T       │
│ Journal/2026-08-01.md          3L  2T       │
│ Areas/Health.md                8L  0T       │
│ ...                                          │
│                                              │
│                        [ Confirm Import ]   │
└──────────────────────────────────────────┘
```

**iPhone**
```
┌──────────────────────────┐
│ Import Preview   [Cancel] │
│ ────────────────────────│
│ 247 notes                  │
│ 1,204 links · 389 tasks    │
│ 0 notebooks                 │
│                             │
│ Projects/NoteBytez.md       │
│   12 links · 4 tasks        │
│ Journal/2026-08-01.md       │
│   3 links · 2 tasks         │
│ ...                          │
│                             │
│ [    Confirm Import     ]  │
└──────────────────────────┘
```

**Elements:** summary counts (must be visible before any commitment — this is the trust-building moment from Journey 1), scrollable per-file preview, explicit Confirm action (never auto-commits). Notebook count reflects only files carrying a `notebooks:` frontmatter field (i.e. previously exported by NoteBytez) — a first-time Obsidian/Logseq migration like the one shown here correctly reads 0, since NoteBytez doesn't infer Notebooks from a foreign vault's own tag conventions (see [NoteBytez-ReleaseFeatures.md](../NoteBytez-ReleaseFeatures.md) Decisions Log). A re-import of a NoteBytez-exported library shows a populated count instead.

---

## S3 — Today (Journal)

**Mac**
```
┌───────────┬────────────────────────────────────────────────────┐
│ Today      │  ◀  Thursday, August 13, 2026  ▶          [sync ●] │
│ All Notes  │  ──────────────────────────────────────────────── │
│ Search     │                                                     │
│ Graph      │  - Stand-up notes: shipped [[Sync Log]] fixes       │
│ Settings   │  - [ ] Review PR from [[Dana]] #standup              │
│            │  - Idea: try [[Weekly Review]] template #followup    │
│            │                                                     │
│            │                                                     │
└───────────┴────────────────────────────────────────────────────┘
```

**iPad (landscape)**
```
┌───┬──────────────────────────────────────┐
│ ⌂ │ ◀  Aug 13, 2026  ▶            [sync ●]│
│ 🔍│ ────────────────────────────────────│
│ ◇ │                                        │
│ ⚙ │ - Stand-up: shipped [[Sync Log]]       │
│   │ - [ ] Review PR from [[Dana]] #standup  │
│   │ - Idea: try [[Weekly Review]] #followup │
└───┴──────────────────────────────────────┘
```

**iPhone**
```
┌──────────────────────────┐
│ ◀  Aug 13, 2026  ▶  [●]   │
│ ──────────────────────── │
│ - Stand-up: shipped        │
│   [[Sync Log]]              │
│ - [ ] Review PR from        │
│   [[Dana]] #standup         │
│ - Idea: try                │
│   [[Weekly Review]]         │
│   #followup                 │
│                             │
├──────────────────────────┤
│[Today][📓][Search][Graph][⚙]│
└──────────────────────────┘
```

**Elements:** date header with prev/next nav, persistent sync-status glyph (top right — always reachable, per Journey 3), free-text journal body with inline `[[links]]`, `#tags`, and `- [ ]` tasks. Mac/iPad use a sidebar; iPhone uses a bottom tab bar.

---

## S4 — Document (Note) View + S5 — Backlinks Pane

**Mac** (S4 + S5 shown together as two columns)
```
┌───────────┬───────────────────────────────┬────────────────────┐
│ Today      │ # NoteBytez Roadmap             │ Backlinks (5)       │
│ All Notes  │ ────────────────────────────  │ ──────────────────  │
│ Search     │ Native SwiftUI apps across      │ • Today — "shipped  │
│ Graph      │ iPhone, iPad, and Mac...        │   [[Sync Log]]..."  │
│ Settings   │                                  │ • Weekly Review     │
│            │ - [ ] Finalize conflict UI       │ • Dana — 1-on-1     │
│            │ - [x] Draft MVP feature list     │                     │
│            │ #roadmap #mvp                    │ Unlinked mentions   │
│            │ See [[Sync Log]] for status.     │ • Q3 Planning        │
└───────────┴───────────────────────────────┴────────────────────┘
```

**iPad (landscape, S4 + S5 as split view)**
```
┌───┬────────────────────────┬───────────────┐
│ ⌂ │ # NoteBytez Roadmap       │ Backlinks (5) │
│ 🔍│ ───────────────────────│ ─────────────│
│ ◇ │ Native SwiftUI apps...    │ • Today        │
│ ⚙ │ - [ ] Finalize conflict   │ • Weekly Review│
│   │ - [x] Draft feature list  │ • Dana         │
│   │ #roadmap #mvp             │ Unlinked (1)   │
│   │ See [[Sync Log]]          │                │
└───┴────────────────────────┴───────────────┘
```

**iPhone** (S4 full screen; S5 is a separate sheet, shown second)
```
┌──────────────────────────┐   ┌──────────────────────────┐
│ ← NoteBytez Roadmap  [🔗]  │   │  ▔▔▔  Backlinks (5)       │
│ ──────────────────────── │   │ ──────────────────────── │
│ Native SwiftUI apps...     │   │ • Today — "shipped         │
│ - [ ] Finalize conflict    │   │   [[Sync Log]]..."          │
│ - [x] Draft feature list   │   │ • Weekly Review             │
│ #roadmap #mvp               │   │ • Dana — 1-on-1             │
│ See [[Sync Log]]           │   │ Unlinked mentions           │
│                             │   │ • Q3 Planning                │
├──────────────────────────┤   └──────────────────────────┘
│[Today][📓][Search][Graph][⚙]│      (sheet, drag up from [🔗])
└──────────────────────────┘
```

**Elements:** document body with inline wikilinks, `#tags`, and task checkboxes, backlinks list split into linked vs. unlinked mentions (Journey 4's resurfacing moment). iPhone's backlinks pane is reached via a toolbar glyph rather than a persistent column.

---

## S6 — Quick Switcher

**Mac**
```
        ┌──────────────────────────────────────────┐
        │  🔍  Search notes...                        │
        ├──────────────────────────────────────────┤
        │  Weekly Review              Areas/          │
        │  Sync Log                   Projects/        │
        │  Dana — 1-on-1               People/          │
        └──────────────────────────────────────────┘
```

**iPad**
```
      ┌────────────────────────────────────┐
      │ 🔍  Search notes...                   │
      ├────────────────────────────────────┤
      │ Weekly Review          Areas/          │
      │ Sync Log               Projects/        │
      │ Dana — 1-on-1           People/          │
      └────────────────────────────────────┘
```

**iPhone**
```
┌──────────────────────────┐
│ 🔍  Search notes...         │
│ ──────────────────────── │
│ Weekly Review               │
│ Sync Log                    │
│ Dana — 1-on-1               │
└──────────────────────────┘
```

**Elements:** floating/overlay search field, fuzzy-matched results, secondary folder/context label. Full-screen modal on iPhone instead of a floating palette.

---

## S7 — Search Results

**Mac**
```
┌───────────┬────────────────────────────────────────────────────┐
│ Today      │  🔍 "conflict"          [Content][Tag][Path]        │
│ All Notes  │  ──────────────────────────────────────────────── │
│ Search ●   │  Sync Log — "...three conflict resolution           │
│ Graph      │   strategies, Keep All..."                          │
│ Settings   │  NoteBytez Roadmap — "Finalize conflict UI"          │
│            │  #conflict-handling (tag) — 3 notes                  │
└───────────┴────────────────────────────────────────────────────┘
```

**iPad (landscape)**
```
┌───┬──────────────────────────────────────┐
│ ⌂ │ 🔍 "conflict"     [Content][Tag][Path]│
│ 🔍●│ ────────────────────────────────────│
│ ◇ │ Sync Log — "...three conflict...       │
│ ⚙ │ NoteBytez Roadmap — "Finalize..."      │
│   │ #conflict-handling — 3 notes            │
└───┴──────────────────────────────────────┘
```

**iPhone**
```
┌──────────────────────────┐
│ 🔍 conflict                 │
│ [Content][Tag][Path]        │
│ ──────────────────────── │
│ Sync Log                    │
│  "...three conflict..."     │
│ NoteBytez Roadmap            │
│  "Finalize conflict UI"      │
│ #conflict-handling (3)       │
├──────────────────────────┤
│[Today][📓][Search][Graph][⚙]│
└──────────────────────────┘
```

**Elements:** persistent search field, scope filter chips (content/tag/path), result rows with matched-text snippet.

---

## S8 — Local Graph View

**Mac**
```
┌───────────┬────────────────────────────────────────────────────┐
│ Today      │                    ○ Weekly Review                  │
│ All Notes  │                   ╱                                 │
│ Search     │        ○ Dana — ●[NoteBytez Roadmap]                │
│ Graph ●    │                   ╲                                 │
│ Settings   │                    ○ Sync Log                       │
│            │                                          [+][-][⤢]  │
└───────────┴────────────────────────────────────────────────────┘
```

**iPad (landscape)**
```
┌───┬──────────────────────────────────────┐
│ ⌂ │              ○ Weekly Review            │
│ 🔍│            ╱                            │
│ ◇●│  ○ Dana — ●[Roadmap]                    │
│ ⚙ │            ╲                            │
│   │              ○ Sync Log        [+][-]   │
└───┴──────────────────────────────────────┘
```

**iPhone**
```
┌──────────────────────────┐
│                             │
│        ○ Weekly Review       │
│       ╱                     │
│  ●[Roadmap]                 │
│       ╲                     │
│        ○ Sync Log            │
│                    [+][-]    │
├──────────────────────────┤
│[Today][📓][Search][Graph][⚙]│
└──────────────────────────┘
```

**Elements:** current note as filled center node, direct links as surrounding nodes only (MVP has no depth/filters/forces), pinch/button zoom. No legend or filter controls — intentionally minimal per MVP scope.

---

## S9 — Sync Status / Log

**Mac** (popover from menu-bar/toolbar sync glyph)
```
        ┌──────────────────────────────────────┐
        │  Sync Status:  ⚠ Conflict on 1 note     │
        │  Last synced:  2 minutes ago             │
        │  ──────────────────────────────────── │
        │  08:14  Synced — 3 notes updated          │
        │  08:12  ⚠ Conflict — "NoteBytez Roadmap"  │
        │  08:02  Synced — 1 note updated           │
        │                                            │
        │  [ Sync Now ]                              │
        └──────────────────────────────────────┘
```

**iPad**
```
      ┌────────────────────────────────────┐
      │ Sync Status: ⚠ Conflict on 1 note      │
      │ Last synced: 2 minutes ago                │
      │ ────────────────────────────────────│
      │ 08:14  Synced — 3 notes                    │
      │ 08:12  ⚠ Conflict — Roadmap                │
      │ 08:02  Synced — 1 note                     │
      │                                              │
      │ [ Sync Now ]                                │
      └────────────────────────────────────┘
```

**iPhone** (pushed screen)
```
┌──────────────────────────┐
│ ← Sync Status               │
│ ──────────────────────── │
│ ⚠ Conflict on 1 note        │
│ Last synced: 2 min ago      │
│ ──────────────────────── │
│ 08:14  Synced (3 notes)     │
│ 08:12  ⚠ Conflict —         │
│         Roadmap             │
│ 08:02  Synced (1 note)      │
│                             │
│ [      Sync Now       ]    │
└──────────────────────────┘
```

**Elements:** current status headline, last-synced timestamp, chronological event log with errors called out, manual "Sync Now" always available.

---

## S10 — Conflict Resolution

Showing the **Keep All Versions** strategy (most structurally complex of the three). The other two strategies swap the content region only: **Last-Write-Wins + Banner** replaces the version list with a single dismissible banner atop the merged note; **Markdown Diff-Merge** replaces it with a two-column diff (old | new) with accept/reject per hunk. Container chrome (panel vs. sheet) is unchanged across strategies.

**Mac** (side panel)
```
┌───────────┬────────────────────────────────────────────────────┐
│ Today      │  Conflict: "NoteBytez Roadmap"            [Keep All]│
│ All Notes  │  ──────────────────────────────────────────────── │
│ Search     │  Version A — this Mac, 08:10                        │
│ Graph      │  "...Finalize conflict UI, ship by Friday."         │
│ Settings   │                                          [Keep A]   │
│            │  Version B — iPhone, 08:12                          │
│            │  "...Finalize conflict UI and sync log."            │
│            │                                          [Keep B]   │
│            │                              [ Keep Both Versions ] │
└───────────┴────────────────────────────────────────────────────┘
```

**iPad (modal sheet)**
```
┌──────────────────────────────────────────┐
│ Conflict: "NoteBytez Roadmap"     [Done]   │
│ ─────────────────────────────────────────│
│ Version A — this iPad, 08:10                │
│  "...Finalize conflict UI, ship..."  [Keep] │
│ Version B — Mac, 08:12                      │
│  "...Finalize conflict UI and..."    [Keep] │
│                        [ Keep Both ]        │
└──────────────────────────────────────────┘
```

**iPhone (modal sheet)**
```
┌──────────────────────────┐
│  Conflict: "Roadmap" [X]   │
│ ──────────────────────── │
│ Version A — 08:10           │
│ "...ship by Friday."        │
│              [ Keep A ]     │
│ Version B — 08:12           │
│ "...and sync log."          │
│              [ Keep B ]     │
│                             │
│ [    Keep Both Versions  ] │
└──────────────────────────┘
```

**Elements:** device + timestamp per version (never anonymous), per-version keep action, explicit "keep both" escape hatch — no silent discarding, matching Journey 3's design implication.

---

## S11 — Settings: Conflict Strategy

**Mac**
```
┌───────────┬────────────────────────────────────────────────────┐
│ General    │  Sync & Conflicts                                   │
│ Sync ●     │  ──────────────────────────────────────────────── │
│ Privacy    │  Conflict resolution strategy:                      │
│ About      │                                                     │
│            │  ○ Keep All Versions                                │
│            │     You resolve every conflict manually.            │
│            │  ● Last-Write-Wins + Banner                         │
│            │     Newest edit wins; a banner lets you revert.     │
│            │  ○ Markdown Diff-Merge                              │
│            │     Auto-merges text; you review the diff.          │
└───────────┴────────────────────────────────────────────────────┘
```

**iPad**
```
┌──────────────────────────────────────────┐
│ Sync & Conflicts                            │
│ ─────────────────────────────────────────│
│ ○ Keep All Versions                          │
│   You resolve every conflict manually.       │
│ ● Last-Write-Wins + Banner                   │
│   Newest edit wins; banner lets you revert.  │
│ ○ Markdown Diff-Merge                        │
│   Auto-merges text; you review the diff.     │
└──────────────────────────────────────────┘
```

**iPhone**
```
┌──────────────────────────┐
│ ← Sync & Conflicts          │
│ ──────────────────────── │
│ ○ Keep All Versions          │
│   Resolve manually.          │
│ ● Last-Write-Wins + Banner   │
│   Newest wins; can revert.   │
│ ○ Markdown Diff-Merge        │
│   Auto-merge, you review.    │
└──────────────────────────┘
```

**Elements:** three mutually-exclusive strategy options, one-line plain-language description per option — this is a trust-critical decision (Journey 3) and must not read as a technical/default-hidden setting.

---

## S12 — Backup & Restore

**Mac**
```
┌───────────┬────────────────────────────────────────────────────┐
│ General    │  Backups                                            │
│ Sync       │  ──────────────────────────────────────────────── │
│ Backups ●  │  Auto-snapshot before risky operations               │
│ About      │                                                     │
│            │  Aug 13, 2026 08:00  Pre-import snapshot   [Restore] │
│            │  Aug 12, 2026 22:14  Manual snapshot        [Restore] │
│            │  Aug 10, 2026 09:30  Pre-merge snapshot     [Restore] │
└───────────┴────────────────────────────────────────────────────┘
```

**iPad**
```
┌──────────────────────────────────────────┐
│ Backups                                     │
│ ─────────────────────────────────────────│
│ Aug 13, 08:00  Pre-import      [Restore]     │
│ Aug 12, 22:14  Manual          [Restore]     │
│ Aug 10, 09:30  Pre-merge       [Restore]     │
└──────────────────────────────────────────┘
```

**iPhone**
```
┌──────────────────────────┐
│ ← Backups                   │
│ ──────────────────────── │
│ Aug 13, 08:00                │
│  Pre-import      [Restore]   │
│ Aug 12, 22:14                │
│  Manual          [Restore]   │
│ Aug 10, 09:30                │
│  Pre-merge       [Restore]   │
└──────────────────────────┘
```

**Elements:** chronological snapshot list with cause label (auto vs. manual), per-row restore action — the safety net referenced in Journeys 1 and 3.

---

## S13 — Tag Browser

**Mac**
```
┌───────────┬────────────────────────────────────────────────────┐
│ Today      │  Tags                                               │
│ All Notes  │  ──────────────────────────────────────────────── │
│ Search     │  #roadmap        4 notes                            │
│ Tags ●     │  #mvp            3 notes                            │
│ Graph      │  #standup        6 notes                            │
│ Settings   │  #conflict-handling  3 notes                        │
│            │  #followup       2 notes                            │
└───────────┴────────────────────────────────────────────────────┘
```

**iPad (landscape)**
```
┌───┬──────────────────────────────────────┐
│ ⌂ │ Tags                                    │
│ 🔍│ ────────────────────────────────────│
│ #●│ #roadmap             4 notes           │
│ ◇ │ #mvp                 3 notes           │
│ ⚙ │ #standup             6 notes           │
│   │ #conflict-handling   3 notes           │
│   │ #followup            2 notes           │
└───┴──────────────────────────────────────┘
```

**iPhone** (pushed from Search tab's tag filter, or from a tag chip tap)
```
┌──────────────────────────┐
│ ← Tags                      │
│ ──────────────────────── │
│ #roadmap          4 notes    │
│ #mvp              3 notes    │
│ #standup          6 notes    │
│ #conflict-handling  3 notes  │
│ #followup         2 notes    │
├──────────────────────────┤
│[Today][📓][Search][Graph][⚙]│
└──────────────────────────┘
```

**Elements:** alphabetical tag list with per-tag note count, tap a tag to jump into S7 Search Results filtered to that tag. Empty state: "No tags yet — type `#` in any note to create one."

---

## S14 — Notebook Browser

**Mac**
```
┌───────────┬────────────────────────────────────────────────────┐
│ Today      │  Notebooks                                [+ New]  │
│ Notebooks ●│  ──────────────────────────────────────────────── │
│ All Notes  │  📓 App Onboarding Revamp        3 documents        │
│ Search     │  📓 NoteBytez Roadmap             1 document         │
│ Tags       │  📓 Home Renovation                7 documents      │
│ Graph      │                                                     │
│ Settings   │                                                     │
└───────────┴────────────────────────────────────────────────────┘
```

**iPad (landscape)**
```
┌───┬──────────────────────────────────────┐
│ ⌂ │ Notebooks                    [+ New]   │
│📓●│ ────────────────────────────────────│
│ 🔍│ 📓 App Onboarding Revamp    3 docs     │
│ # │ 📓 NoteBytez Roadmap        1 doc      │
│ ◇ │ 📓 Home Renovation          7 docs     │
│ ⚙ │                                         │
└───┴──────────────────────────────────────┘
```

**iPhone**
```
┌──────────────────────────┐
│ Notebooks         [+ New] │
│ ──────────────────────── │
│ 📓 App Onboarding Revamp   │
│    3 documents              │
│ 📓 NoteBytez Roadmap        │
│    1 document                │
│ 📓 Home Renovation           │
│    7 documents               │
├──────────────────────────┤
│[Today][📓][Search][Graph][⚙]│
└──────────────────────────┘
```

**Elements:** notebook list with per-notebook document count, tap a notebook to open a documents-in-this-notebook list (reuses the same filtered-document-list pattern as S13's tag drill-down, not a new bespoke screen), explicit "+ New" to create a Notebook directly (not only via Promote). Empty state: "No notebooks yet — promote a journal entry, or create one here."

---

## S15 — Promote to Notebook

Reached by long-press (iPhone/iPad) or right-click (Mac) on a journal block in S3, then "Promote to Notebook." A decision the user must complete or cancel before continuing, so it's a modal sheet on every platform — same rule S2/S10 follow.

**Mac**
```
        ┌──────────────────────────────────────────┐
        │  Promote to Notebook                [Cancel]│
        │  ──────────────────────────────────────  │
        │  "Idea: revamp the onboarding flow..."     │
        │                                            │
        │  Choose a notebook:                        │
        │  📓 App Onboarding Revamp                   │
        │  📓 NoteBytez Roadmap                       │
        │  📓 Home Renovation                          │
        │  ──────────────────────────────────────  │
        │  ○ Or create new:  [                    ] │
        │                                            │
        │                              [ Promote ]   │
        └──────────────────────────────────────────┘
```

**iPad (modal sheet)**
```
┌──────────────────────────────────────────┐
│ Promote to Notebook               [Cancel] │
│ ─────────────────────────────────────────│
│ "Idea: revamp the onboarding flow..."       │
│                                              │
│ 📓 App Onboarding Revamp                     │
│ 📓 NoteBytez Roadmap                         │
│ 📓 Home Renovation                            │
│ ─────────────────────────────────────────│
│ ○ Or create new:  [                     ]  │
│                              [ Promote ]    │
└──────────────────────────────────────────┘
```

**iPhone (modal sheet)**
```
┌──────────────────────────┐
│ Promote to Notebook  [X]   │
│ ──────────────────────── │
│ "Idea: revamp the          │
│  onboarding flow..."        │
│                             │
│ 📓 App Onboarding Revamp    │
│ 📓 NoteBytez Roadmap         │
│ 📓 Home Renovation            │
│ ──────────────────────── │
│ ○ Or create new:            │
│   [                    ]   │
│                             │
│ [       Promote        ]  │
└──────────────────────────┘
```

**Elements:** read-only preview of the block being promoted (confirms exactly what's moving before committing), existing-notebook list, single "or create new" text field as the alternate path, explicit Promote action — never auto-commits. Cancel leaves the journal entry completely untouched, reinforcing Journey 5's "copy-and-link, never move" design implication.

---

## S16 — Canvas

**Mac**
```
┌───────────┬────────────────────────────────────────────────────┐
│ Today      │  Mystery Board                            [+][-][⤢] │
│ Notebooks  │  ──────────────────────────────────────────────── │
│ Canvas ●   │   ┌──────────┐        ┌──────────────┐             │
│ Search     │   │ Suspect A │──reveals──▶│ Clue: Letter │        │
│ Graph      │   └──────────┘        └──────────────┘             │
│ Settings   │        │ alibi conflicts with                       │
│            │        ▼                                            │
│            │   ┌──────────┐   ┌───────────────────────┐          │
│            │   │ Suspect B │   │ 🌐 Reference article    │         │
│            │   └──────────┘   └───────────────────────┘          │
└───────────┴────────────────────────────────────────────────────┘
```

**iPad (landscape)**
```
┌───┬──────────────────────────────────────┐
│ ⌂ │ Mystery Board                [+][-]    │
│ 📓│ ────────────────────────────────────│
│◇●│  ┌────────┐      ┌────────┐            │
│ 🔍│  │Suspect A│─────▶│Clue: Ltr│           │
│ ⚙ │  └────────┘      └────────┘            │
│   │       │                                 │
│   │  ┌────────┐  ┌───────────────┐         │
│   │  │Suspect B│  │🌐 Reference    │         │
│   │  └────────┘  └───────────────┘         │
└───┴──────────────────────────────────────┘
```

**iPhone** (reached via toolbar button on S14)
```
┌──────────────────────────┐
│ ← Mystery Board    [+][-]  │
│ ──────────────────────── │
│  ┌────────┐                │
│  │Suspect A│                │
│  └───┬────┘                │
│      ▼                     │
│  ┌────────┐                │
│  │Clue: Ltr│                │
│  └────────┘                │
│  (pinch to zoom, drag to pan)│
├──────────────────────────┤
│[Today][📓][Search][Graph][⚙]│
└──────────────────────────┘
```

**Elements:** pan/zoom container, note/media/web cards (`CanvasCardView`), labeled connectors between cards (`CanvasConnector`), group boundary (visual grouping, not separately drawn at this fidelity), `[+][-][⤢]` zoom toolbar reused from S8's pattern. iPhone has no dedicated tab (per [04-InteractionDesign.md](04-InteractionDesign.md)'s V1 navigation-shell decision) — pushed from S14's toolbar instead.

---

## S17 — Properties Editor

Inline within S4 (Document View) — not a separate destination, a region atop the document body. Shown here as an augmented S4 to keep 1:1 parity with the screen inventory in [04-InteractionDesign.md](04-InteractionDesign.md).

**Mac**
```
┌───────────┬───────────────────────────────┬────────────────────┐
│ Today      │ # Elyra Voss                    │ Backlinks (2)       │
│ Notebooks  │ ────────────────────────────  │ ──────────────────  │
│ Canvas     │ Name      Elyra Voss             │ • Chapter 3         │
│ Search     │ Species   Kethran                │ • Weekly Review     │
│ Graph      │ Homeworld [[Kethra Prime]]       │                     │
│ Settings   │ Status    ☑ Alive                │                     │
│            │ ──────────────────────────────│                     │
│            │ Backstory: Elyra grew up on...   │                     │
│            │ #antagonist #act2                │                     │
└───────────┴───────────────────────────────┴────────────────────┘
```

**iPad (landscape)**
```
┌───┬────────────────────────┬───────────────┐
│ ⌂ │ # Elyra Voss              │ Backlinks (2) │
│ 🔍│ ───────────────────────│ ─────────────│
│ ◇ │ Name     Elyra Voss        │ • Chapter 3    │
│ ⚙ │ Species  Kethran            │ • Weekly Rvw   │
│   │ Homeworld [[Kethra Prime]] │                │
│   │ Status   ☑ Alive            │                │
│   │ ───────────────────────│                │
│   │ Backstory: Elyra grew...   │                │
└───┴────────────────────────┴───────────────┘
```

**iPhone**
```
┌──────────────────────────┐
│ ← Elyra Voss         [🔗]  │
│ ──────────────────────── │
│ Name      Elyra Voss        │
│ Species   Kethran            │
│ Homeworld [[Kethra Prime]]  │
│ Status    ☑ Alive            │
│ ──────────────────────── │
│ Backstory: Elyra grew up     │
│ on...                        │
│ #antagonist #act2             │
├──────────────────────────┤
│[Today][📓][Search][Graph][⚙]│
└──────────────────────────┘
```

**Elements:** `PropertyEditorRow` per typed field (text/number/date/checkbox/list — checkbox shown as ☑, a wikilink-valued text property renders as an ordinary `WikilinkText`), a divider between the Properties block and free-text body — same Document, one continuous scroll, per Journey 6's design implication that Properties must never feel like a separate form. Empty state: a Document created without a template shows no Properties block at all until a field is added manually.

---

## S18 — Template Picker / Manager

Two sub-flows: **Picker** (choosing a template at creation, shown below — the higher-frequency screen) and **Manager** (Settings, editing TemplateGroups — see Elements).

**Mac**
```
        ┌──────────────────────────────────────────┐
        │  New Document — Choose a Template   [Cancel]│
        │  ──────────────────────────────────────  │
        │  Fiction Writing                            │
        │   📄 Character   📄 Location   📄 Technology │
        │  ──────────────────────────────────────  │
        │  ○ Start blank (no template)               │
        │                              [ Create ]    │
        └──────────────────────────────────────────┘
```

**iPad (modal sheet)**
```
┌──────────────────────────────────────────┐
│ New Document — Choose a Template  [Cancel] │
│ ─────────────────────────────────────────│
│ Fiction Writing                              │
│  📄 Character   📄 Location   📄 Technology  │
│ ─────────────────────────────────────────│
│ ○ Start blank                               │
│                              [ Create ]     │
└──────────────────────────────────────────┘
```

**iPhone (modal sheet)**
```
┌──────────────────────────┐
│ Choose a Template   [X]    │
│ ──────────────────────── │
│ Fiction Writing              │
│  📄 Character                │
│  📄 Location                 │
│  📄 Technology                │
│ ──────────────────────── │
│ ○ Start blank                │
│                             │
│ [       Create         ]  │
└──────────────────────────┘
```

**Elements:** `TemplatePickerRow` per template, grouped by `TemplateGroup` name, explicit "start blank" opt-out (never forces a template) — matching S15's "explicit action, never auto-commits" rule. Scoped to the current Notebook or Journal context per the picker-scoping logic (a Notebook with no attached group falls back to every template in the library, ungrouped). Template *Manager* (create/edit/delete TemplateGroups and NoteTemplates) is a separate Settings-pushed list reusing this same `TemplatePickerRow` component in an editable `List` — not separately wireframed, since it's a standard edit-list pattern already covered by [06-DesignSystem.md](06-DesignSystem.md)'s State conventions.

---

## S19 — Task Dashboard

**Mac**
```
┌───────────┬────────────────────────────────────────────────────┐
│ Today      │  Tasks                        [Open][Done][All]    │
│ Notebooks  │  ──────────────────────────────────────────────── │
│ Tasks ●    │  ☐ Review PR from [[Dana]]      Due today   #standup│
│ Search     │  ☐ Finalize conflict UI          High · repeats wk │
│ Graph      │  ☑ Draft MVP feature list        Done               │
│ Settings   │  ☐ Outline Chapter 4              Due Fri  #act2    │
└───────────┴────────────────────────────────────────────────────┘
```

**iPad (landscape)**
```
┌───┬──────────────────────────────────────┐
│ ⌂ │ Tasks              [Open][Done][All]   │
│ 📓│ ────────────────────────────────────│
│✓●│ ☐ Review PR — Dana      Due today      │
│ 🔍│ ☐ Finalize conflict UI  High, weekly   │
│ ⚙ │ ☑ Draft feature list    Done            │
│   │ ☐ Outline Chapter 4     Due Fri         │
└───┴──────────────────────────────────────┘
```

**iPhone** (pushed from S3's toolbar)
```
┌──────────────────────────┐
│ ← Tasks                     │
│ [Open][Done][All]           │
│ ──────────────────────── │
│ ☐ Review PR — Dana           │
│   Due today · #standup       │
│ ☐ Finalize conflict UI       │
│   High · repeats weekly      │
│ ☑ Draft feature list          │
│ ☐ Outline Chapter 4           │
│   Due Fri · #act2             │
├──────────────────────────┤
│[Today][📓][Search][Graph][⚙]│
└──────────────────────────┘
```

**Elements:** `TaskDashboardRow` (checkbox + text + due-date/priority/recurrence indicators + source note), status filter chips reusing `FilterChipRow`, `RecurrenceControl` badge for repeating tasks. Toggling a task here uses the same `TaskCheckbox`/toggle path as S3/S4 (MVP's established consistency guarantee, extended rather than duplicated). Reached via a toolbar button on S3 (iPhone) or a dedicated sidebar item (Mac/iPad) — same platform-tiered pattern as S13 Tags.

---

## S20 — Attachment Preview

**Mac**
```
┌───────────┬───────────────────────────────┬────────────────────┐
│ Today      │ # Location Reference             │ Backlinks (1)       │
│ Notebooks  │ ────────────────────────────  │ ──────────────────  │
│ Search     │ [🖼 harbor.jpg] [📄 lease.pdf]   │ • Chapter 2          │
│ Graph      │                                  │                     │
│ Settings   │ Notes about the harbor district: │                     │
│            │ ...                              │                     │
└───────────┴───────────────────────────────┴────────────────────┘
```
Full preview (triggered by tapping a thumbnail):
```
┌────────────────────────────────────────────────────────────────┐
│  harbor.jpg                                          [Close]     │
│  ──────────────────────────────────────────────────────────── │
│                                                                    │
│                    [ full-size image render ]                    │
│                                                                    │
└────────────────────────────────────────────────────────────────┘
```

**iPad (landscape)**
```
┌───┬────────────────────────┬───────────────┐
│ ⌂ │ # Location Reference       │ Backlinks (1) │
│ 🔍│ ───────────────────────│ ─────────────│
│ ◇ │ [🖼 harbor.jpg][📄 lease] │ • Chapter 2    │
│ ⚙ │ Notes about the harbor...  │                │
└───┴────────────────────────┴───────────────┘
```

**iPhone**
```
┌──────────────────────────┐
│ ← Location Reference [📎]  │
│ ──────────────────────── │
│ [🖼 harbor.jpg]              │
│ [📄 lease.pdf]                │
│ ──────────────────────── │
│ Notes about the harbor       │
│ district: ...                │
├──────────────────────────┤
│[Today][📓][Search][Graph][⚙]│
└──────────────────────────┘
```

**Elements:** `AttachmentThumbnail` grid inline in the document body (image/PDF icon + filename), `AttachmentPreview` full-screen overlay on tap — same sheet-based full-screen pattern as S6 Quick Switcher on iPhone. Reached via a toolbar `[📎]` glyph on S4, mirroring S5's `[🔗]` backlinks-pane trigger.

---

## S21 — Saved Views

**Mac**
```
┌───────────┬────────────────────────────────────────────────────┐
│ Today      │  Saved Views                              [+ New]  │
│ Notebooks  │  ──────────────────────────────────────────────── │
│ Saved ●    │  📌 Act 2 Antagonists          (search)             │
│ Search     │  📌 Overdue Tasks                (task query)        │
│ Graph      │  📌 Unresolved Plot Threads     (search)             │
│ Settings   │                                                     │
└───────────┴────────────────────────────────────────────────────┘
```

**iPad (landscape)**
```
┌───┬──────────────────────────────────────┐
│ ⌂ │ Saved Views                 [+ New]    │
│📌●│ ────────────────────────────────────│
│ 🔍│ 📌 Act 2 Antagonists     search        │
│ ◇ │ 📌 Overdue Tasks         task query    │
│ ⚙ │ 📌 Unresolved Threads    search         │
└───┴──────────────────────────────────────┘
```

**iPhone** (a pinned section atop S7 and S19, not a separate tab)
```
┌──────────────────────────┐
│ 🔍 Search               [+] │
│ ──────────────────────── │
│ Saved Views                  │
│  📌 Act 2 Antagonists         │
│  📌 Unresolved Threads         │
│ ──────────────────────── │
│ [Content][Tag][Path]         │
│ ...search results below...   │
├──────────────────────────┤
│[Today][📓][Search][Graph][⚙]│
└──────────────────────────┘
```

**Elements:** `SavedViewChip`/list row, re-running a saved view always re-evaluates live — never a frozen snapshot from save time, per Journey 6's design implication. Dedicated sidebar item on Mac/iPad; folded into the top of S7/S19 on iPhone rather than a 6th tab.

---

## S22 — Sharing / Participants

**Mac**
```
        ┌──────────────────────────────────────────┐
        │  Share "Research Library"           [Done] │
        │  ──────────────────────────────────────  │
        │  Participants                               │
        │  • Dana Reyes        Read & Write   [▾]     │
        │  • Sam Okafor          Read Only      [▾]    │
        │  ──────────────────────────────────────  │
        │  [ + Invite Participant ]                   │
        └──────────────────────────────────────────┘
```

**iPad (modal sheet)**
```
┌──────────────────────────────────────────┐
│ Share "Research Library"           [Done]  │
│ ─────────────────────────────────────────│
│ • Dana Reyes       Read & Write    [▾]     │
│ • Sam Okafor         Read Only       [▾]    │
│ ─────────────────────────────────────────│
│ [ + Invite Participant ]                    │
└──────────────────────────────────────────┘
```

**iPhone (modal sheet)**
```
┌──────────────────────────┐
│ Share Library         [X]  │
│ ──────────────────────── │
│ • Dana Reyes                 │
│   Read & Write        [▾]    │
│ • Sam Okafor                  │
│   Read Only              [▾]  │
│ ──────────────────────── │
│ [  + Invite Participant  ] │
└──────────────────────────┘
```

**Elements:** `ParticipantAvatar` + name per row, `PermissionLevelPicker` (Read Only / Read & Write — text label always paired with the selection, never an icon-only toggle, per the color/icon/text accessibility rule in [06-DesignSystem.md](06-DesignSystem.md)), explicit invite action. A decision-bearing screen, so it's a sheet on every platform, same rule S2/S10/S15 already follow.

---

## S23 — Migration Assistant

**Mac**
```
┌────────────────────────────────────────────────────────────────┐
│  Migration Assistant                                    [Cancel] │
│  ────────────────────────────────────────────────────────────── │
│  Which tool is this vault from?                                   │
│   ○ Obsidian    ○ Logseq    ● Auto-detect                        │
│                                                                    │
│  Detected: Obsidian vault (YAML properties, .canvas files found)  │
│  247 notes · 1,204 wikilinks · 18 properties · 3 canvases          │
│  1 unsupported item flagged (see below)                            │
│                                                                    │
│                                        [ Confirm Migration ]       │
└────────────────────────────────────────────────────────────────┘
```

**iPad (modal sheet)**
```
┌──────────────────────────────────────────┐
│ Migration Assistant                [Cancel]│
│ ─────────────────────────────────────────│
│ ○ Obsidian  ○ Logseq  ● Auto-detect         │
│ Detected: Obsidian vault                    │
│ 247 notes · 1,204 links · 18 properties      │
│ 3 canvases · 1 unsupported item flagged      │
│                        [ Confirm Migration ] │
└──────────────────────────────────────────┘
```

**iPhone (modal sheet)**
```
┌──────────────────────────┐
│ Migration Assistant  [X]   │
│ ──────────────────────── │
│ ○ Obsidian ○ Logseq          │
│ ● Auto-detect                 │
│ ──────────────────────── │
│ Detected: Obsidian vault      │
│ 247 notes                     │
│ 1,204 links · 18 properties   │
│ 3 canvases                    │
│ 1 unsupported item flagged    │
│                             │
│ [   Confirm Migration    ] │
└──────────────────────────┘
```

**Elements:** `MigrationSourceRow` (format selector, auto-detect default), extends `ImportSummaryHeader` with property/canvas counts and an unsupported-item flag count — never silently drops content, per Journey 9's design implication. Reached from S1 as a sibling action to MVP's "Import existing Markdown folder."

---

## S24 — Plugin Management

**Mac**
```
┌───────────┬────────────────────────────────────────────────────┐
│ General    │  Plugins (Preview)                        [+ Add]  │
│ Sync       │  ──────────────────────────────────────────────── │
│ Templates  │  Word Count            ● Enabled                    │
│ Plugins ●  │   Permissions: Read library                          │
│ About      │  Daily Outline Builder   ○ Disabled                  │
│            │   Permissions: Read library, Write current note      │
└───────────┴────────────────────────────────────────────────────┘
```

**iPad**
```
┌──────────────────────────────────────────┐
│ Plugins (Preview)                  [+ Add] │
│ ─────────────────────────────────────────│
│ Word Count           ● Enabled              │
│  Permissions: Read library                   │
│ Daily Outline Builder  ○ Disabled            │
│  Permissions: Read library, Write note        │
└──────────────────────────────────────────┘
```

**iPhone**
```
┌──────────────────────────┐
│ ← Plugins (Preview)         │
│ ──────────────────────── │
│ Word Count                   │
│  ● Enabled                    │
│  Permissions: Read library    │
│ Daily Outline Builder         │
│  ○ Disabled                    │
│  Permissions: Read library,    │
│  Write current note            │
│                             │
│ [       + Add Plugin     ] │
└──────────────────────────┘
```

**Elements:** `PluginPermissionRow` listing each granted permission explicitly (never a bare "trust this plugin" toggle), enable/disable per plugin, install action. Every permission is user-visible before a plugin can run, per the sandboxed-`JavaScriptCore` design in [NoteBytez-R1-Implementation.md](../NoteBytez-R1-Implementation.md) Phase 13.

---

## S25 — Graph Insights

**Mac**
```
┌───────────┬────────────────────────────────────────────────────┐
│ Capture    │  Insights                                          │
│  Today     │  ──────────────────────────────────────────────── │
│ Library    │  Orphans (2)                                       │
│  Notebooks │   No incoming or outgoing links.                    │
│  All Notes │   • Loose Idea                                      │
│  Tags      │  Stale [30][60][90●][180] (1)                       │
│ Explore    │   Untouched a while, still has tasks/backlinks.      │
│  Search    │   • Old Project — edited Mar 2                      │
│  Graph     │  Notes with Open Tasks (3)                          │
│  Insights ●│   • Q3 Roadmap — 4 open, due Fri                     │
│  Tasks     │  Hubs (5)                                            │
│  Saved     │   • Worldbuilding — 14 links                         │
│  Canvas    │  Clusters (2)                                        │
│ Settings   │   ▸ Cluster: Worldbuilding — 14 notes                │
└───────────┴────────────────────────────────────────────────────┘
```

**iPad** — same sectioned sidebar + content region as Mac, collapsible.

**iPhone**
```
┌──────────────────────────┐
│ ← Insights                  │
│ ──────────────────────── │
│ Orphans (2)                  │
│  No orphans — every note      │
│  is connected.                 │
│ Stale [30][60][90●][180] (1)  │
│  • Old Project — Mar 2         │
│ Notes with Open Tasks (3)      │
│  • Q3 Roadmap — 4 open         │
│ Hubs (5)                        │
│  • Worldbuilding — 14 links     │
│ Clusters (2)                     │
│  ▸ Worldbuilding — 14 notes      │
└──────────────────────────┘
```

**Elements:** `InsightSectionHeader` (title + count + one-line meaning) atop each category, `GraphInsightRow` (title + icon + metric, never color-only), a segmented threshold picker for Stale, `DisclosureGroup` cluster rows headed by their highest-degree member. An empty category always renders a calm sentence ("No orphans — every note is connected."), never a blank section. Tapping any row pushes S4.

---

## S26 — Command Palette

**Mac / iPad** (⌘P, floating sheet from any screen)
```
┌────────────────────────────────────────┐
│ 🔍  Type a command or search…            │
│ ──────────────────────────────────────│
│ 🗒  New Note                             │
│ 📚  New Notebook                         │
│ 🔗  Graph                                │
│ 💡  Insights                             │
│ 🔄  Sync Now                             │
│                              [ Cancel ] │
└────────────────────────────────────────┘
```

**iPhone** — same layout, reached only via S27's "Command Palette" row (no hardware ⌘P).

**Elements:** `CommandPaletteRow` (icon + title), reuses `QuickSwitcherField`'s search-bar-in-surface + plain-list idiom. Return acts the top-ranked hit; a query fuzzy-filters and ranks shorter/more-exact titles above longer ones. Selecting a `.navigate` row jumps there; selecting an `.action` row runs it in place (no navigation for e.g. Sync Now).

---

## S27 — Explore Hub (iPhone only)

```
┌──────────────────────────┐
│ Explore                     │
│ ──────────────────────── │
│ 🔗  Graph                    │
│ 💡  Insights                  │
│ ✅  Tasks                     │
│ 📌  Saved Views                │
│ 🔲  Canvas                     │
│ 🏷️  Tags                       │
│ ⌘   Command Palette            │
└──────────────────────────┘
```

**Elements:** plain list of `SidebarNavItem`-style rows, each a `NavigationLink` to its destination except "Command Palette," which opens S26 as a sheet. This is the iPhone tab bar's 4th tab, replacing the bare Graph tab — Search keeps its own tab, so it isn't repeated here.

---

## Deltas to existing screens

**S8 (Local Graph View)** gains a toolbar "Send to Canvas" action (Mac/iPad/iPhone) that seeds a new `CanvasBoard` from the current note's neighborhood and pushes S16 — no new screen, an addition to S8's existing toolbar row.

**S4 (Document View)** gains live rendering for `!((anchor))` — a bordered `TransclusionBlockView` inline wherever that line appears, showing the target block's current content with a small "↗" jump-to-source button, top-right. No layout change to S4 otherwise.

**S4 (Document View), updated by [NoteBytez20260829v2-Enhancements.md](NoteBytez20260829v2-Enhancements.md) Workstream B:** the `TransclusionBlockView` embed above is no longer read-only. A pencil "Edit" button switches it to an inline `TextEditor`; "Done" splices the new text back into the *source* document and both notes reflect it immediately (optimistic, last-write-wins — no merge prompt). An "Undo Edit" button (shown only right after an edit) reverts via the same write path. A nested `!((anchor))` inside the edited text stays literal, never expands.

**S8 (Local Graph View), updated by the same v2 plan's Workstream A:** a Radial/Force segmented control in the toolbar switches the node layout; Force mode adds a filter bar (depth stepper, node-type chips, tag-scope field, "Save as View") and drag-to-pin on any node. A "graph too large" empty state caps Force mode at 500 nodes.

**S16 (Canvas), updated by the same v2 plan's Workstream C:** a board can bind to a note via a toolbar "Bind to Note…" action (also reachable from a board-list row's context menu, and from S26's new palette actions) — a bound board shows a small "↔ <Note title>" badge and its cards/connectors track the note's direct links automatically. Drawing a connector between two note cards on a bound board raises a confirm alert ("Add [[Target]] to Source?"); confirming writes the link, cancelling simply never creates the connector.

---

## Coverage check

All 15 MVP screens plus R1's 9 (S16-S24) and Flow Enhancements' 3 (S25-S27) — 27 total — are wireframed on Mac, iPad, and iPhone above (S10's two alternate strategies are specified as content-region deltas rather than fully redrawn, to avoid tripling near-identical container chrome; S25's Send-to-Canvas and S4's transclusion are likewise specified as deltas rather than new screens). Every component appearing in these wireframes is inventoried in [06-DesignSystem.md](06-DesignSystem.md).

**V2 Enhancements:** no new screens — Workstreams A/B/C are specified as deltas to S8/S4/S16 above, and the two new palette actions extend S26 (already wireframed) rather than requiring a redraw.

**Version 1:** S16–S24 are wireframed on Mac, iPad, and iPhone above, same equal-detail bar as the MVP set (S17 and S18's Manager sub-flow are specified as regions/deltas of S4 and S18's Picker respectively, following S10's own precedent for avoiding redundant near-identical chrome). Every V1 component is inventoried in [06-DesignSystem.md](06-DesignSystem.md).
