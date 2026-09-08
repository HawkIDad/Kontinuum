<!-- 06-DesignSystem.md -->
<!--
  Part of the NoteBytez UIUX Research deliverable set. See ../../../NoteBytez20260813-UIUX-Research.md for scope/plan.
  Apple HIG-aligned starting point — no prior brand assets existed in the repo (see Gaps Identified in the
  index doc). This is a proposal, not a locked-in identity; intended to become docs/styleGuide.md.
-->

# Design System

## Style Guide

**Foundation:** SwiftUI + Apple Human Interface Guidelines defaults, not a custom brand system. Rationale: NoteBytez's wedge is "unapologetically native" (research doc §9) — fighting the platform's own conventions works against that.

### Typography

| Role | Style | Use |
|---|---|---|
| Large Title | `.largeTitle` | Library name, onboarding headlines (S1) |
| Title | `.title2` / `.title3` | Note titles, section headers |
| Body | `.body` | Journal/document text — supports Dynamic Type |
| Callout | `.callout` | Backlink snippets, search result previews |
| Caption | `.caption` | Timestamps, sync log entries, snapshot metadata |
| Monospace | `.body.monospaced()` | Raw Markdown source view (if/when exposed) |

All text uses Dynamic Type — no fixed point sizes. This is a hard requirement, not a nice-to-have, given the Archivist persona's long reading sessions.

### Color roles (semantic, not literal hex)

| Role | System color | Use |
|---|---|---|
| Primary text | `.primary` / `Color(.label)` | Body content |
| Secondary text | `.secondary` | Timestamps, metadata, unlinked-mention labels |
| Accent | `.accentColor` (app sets one tint) | Links, active tab/sidebar item, primary buttons |
| Success | `.green` | "Synced" status |
| Warning/Conflict | `.orange` | Conflict badges, sync warnings — deliberately not red (conflict is recoverable, not catastrophic) |
| Destructive | `.red` | Restore-overwrite confirmation, delete actions only |
| Surface | `Color(.systemBackground)` / `Color(.secondarySystemBackground)` | Panel backgrounds, respects light/dark automatically |

No custom palette is introduced in MVP. Every color is a semantic system color so light/dark mode and increased-contrast accessibility settings work for free.

**Primary / Secondary / Accent** (kept in sync with `Docs/styleGuide.md`): **Primary** = `.primary` / `Color(.label)` (system label — `#000000` light / `#FFFFFF` dark, no brand hex by design). **Secondary** = `.secondary` (system secondary label — `#3C3C43` @ 60% light / `#EBEBF5` @ 60% dark). **Accent** = the one custom tint in `Assets.xcassets/AccentColor.colorset`, applied via `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME`: **`#0F766E`** (deep teal) in Light, **`#2DD4BF`** (bright teal) in Dark — links, active tab/sidebar item, `PrimaryButton`.

### Spacing & layout

- 8pt base grid (4pt for tight inline elements like checkbox-to-text).
- Standard SwiftUI `NavigationSplitView` insets on Mac/iPad; standard `List`/`Form` insets on iPhone. No custom margins.
- Minimum tap target 44×44pt on all interactive elements (checkbox toggles, restore buttons, graph node targets).

### Iconography

SF Symbols exclusively — no custom icon set. Confirmed symbols used across the wireframes in [05-Wireframes.md](05-Wireframes.md):

`magnifyingglass` (search), `point.topleft.down.curvedto.point.bottomright.up` or `circle.grid.cross` (graph), `gearshape` (settings), `link` (backlinks toggle), `tag` (tags nav item / tag chips), `books.vertical` (notebooks nav item / notebook rows), `arrow.triangle.2.circlepath` (sync), `exclamationmark.triangle` (conflict warning), `chevron.left` / `chevron.right` (journal day nav), `plus.square` (create), `square.and.arrow.down` (import), `clock.arrow.circlepath` (backup/restore), `checkmark.square` / `square` (task states).

**Version 1 additions:** `rectangle.3.group` (canvas nav item), `paperclip` (attachments), `person.2` (sharing/participants), `puzzlepiece.extension` (plugins), `arrow.triangle.swap` (migration assistant), `pin` (saved views), `checklist` (task dashboard nav item), `doc.badge.plus` (note templates).

**V2 Enhancements additions:** `link.badge.plus` (bind canvas to a note), `link.badge.minus` (unbind), `link.circle` (open note as bound canvas).

---

## User Interface Standards

### Navigation patterns

| Pattern | When to use | Screens |
|---|---|---|
| Sidebar (`NavigationSplitView`) | Mac always; iPad landscape/expanded | S3, S4/S5, S7, S8, S13, S14 |
| Tab bar | iPhone always; iPad compact/portrait | Same screens, collapsed |
| Push (stack) | Drilling into a specific note or settings sub-page | S4, S9 (iPhone), S11, S12, S13 (iPhone) |
| Modal sheet | Focused, interruptive tasks the user must resolve or dismiss | S2 (iPad/iPhone), S6 (iPhone), S10, S15 |
| Popover | Quick-glance status that doesn't warrant leaving context | S9 (Mac/iPad) |
| Floating overlay | Global, keyboard-triggerable utilities | S6 (Mac/iPad Quick Switcher) |

Rule: a screen that **requires a decision before the user can continue** (conflict resolution, import confirmation) is always a sheet/modal, never a passive panel — this reinforces "never silently lose an edit" from the personas.

### State conventions

Every list-bearing screen (S7 results, S9 log, S12 backups, S13 tags, S14 notebooks) supports four states, styled consistently:

1. **Loading** — system `ProgressView`, no custom spinner.
2. **Empty** — short, calm message + relevant icon (e.g., "No conflicts — you're all synced" with a checkmark, not a generic "no data" state).
3. **Populated** — as wireframed.
4. **Error** — inline, dismissible, with a retry action (e.g., sync error banner in S9); never a blocking alert unless the action is destructive (restore-overwrite).

### Sync & conflict visual language

- **Synced:** green dot, `arrow.triangle.2.circlepath`.
- **Syncing:** same glyph, animated/spinning.
- **Conflict:** orange `exclamationmark.triangle` badge, always paired with a count ("1 note") — never a bare icon.
- **Offline:** gray dot, "Last synced Xm ago" label persists so the user always has a timestamp, not just a status word.

### Accessibility

- VoiceOver labels required on every icon-only control (sync glyph, graph zoom buttons, backlink toggle).
- Dynamic Type up to accessibility sizes must not truncate journal/document text (reflow, don't clip).
- Color is never the only signal — conflict/warning states always pair color with an icon and text label (see above), so the design remains legible for color-blind users without any extra work.

---

## Common UI Components / Widgets

Inventory of every component used across [05-Wireframes.md](05-Wireframes.md), for reuse rather than one-off screens:

| Component | Description | Used in |
|---|---|---|
| `PrimaryButton` | Filled, accent-colored, one per screen max | S1, S2, S3 |
| `SecondaryButton` | Bordered/plain, for cancel or lower-emphasis actions | S1, S2, S10 |
| `SidebarNavItem` | Icon + label, selectable, shows active state | S3, S4, S7, S8 |
| `TabBarItem` | iPhone/compact equivalent of `SidebarNavItem` | S3, S4, S7, S8 |
| `JournalDayHeader` | Date label + prev/next chevrons | S3 |
| `WikilinkText` | Inline styled text run for `[[links]]`, tappable | S3, S4 |
| `TagChip` | Inline styled text run for `#tags`, tappable — jumps to S7 filtered by that tag | S3, S4, S7, S13 |
| `TaskCheckbox` | Two-state checkbox bound to `- [ ]`/`- [x]` | S3, S4 |
| `BacklinkRow` | Source note title + matched snippet | S4/S5 |
| `UnlinkedMentionRow` | Same as `BacklinkRow`, visually de-emphasized (secondary text) to distinguish from confirmed links | S4/S5 |
| `QuickSwitcherField` | Search input with fuzzy result list, keyboard-navigable | S6 |
| `SearchResultRow` | Title + snippet + source scope (content/tag/path) | S7 |
| `FilterChipRow` | Horizontal scoped-filter toggles | S7 |
| `GraphNode` | Circle, filled when current note, outlined otherwise | S8 |
| `GraphCanvas` | Pan/zoom container for nodes + edges | S8 |
| `SyncStatusGlyph` | Persistent, tappable status indicator (see visual language above) | S3, S4, S9 |
| `SyncLogRow` | Timestamp + event description, orange when error/conflict | S9 |
| `ConflictVersionCard` | Device + timestamp + snippet + keep action | S10 (Keep All) |
| `ConflictBanner` | Dismissible top-of-note strip | S10 (Last-Write-Wins) |
| `DiffMergeView` | Two-column old/new with per-hunk accept | S10 (Diff-Merge) |
| `SettingsRadioRow` | Radio selector + title + one-line description | S11 |
| `BackupSnapshotRow` | Timestamp + cause label + restore action | S12 |
| `ImportSummaryHeader` | Aggregate counts (notes/links/tasks/notebooks) | S2 |
| `ImportFileRow` | Filename + per-file link/task counts | S2 |
| `TagListRow` | Tag name + note count, tappable | S13 |
| `NotebookListRow` | Notebook name + document count, tappable — opens a filtered document list (reuses S13's drill-down pattern) | S14, S15 |
| `PromoteSourcePreview` | Read-only snippet of the journal block being promoted, so the user confirms what's moving before committing | S15 |

Every component maps to a native SwiftUI primitive (`Button`, `List`/`Form` row, `NavigationSplitView`, `TabView`, system `ProgressView`) — none require custom rendering to hit this design system, consistent with NoteBytez's own `CLAUDE.md` guidance to leverage the Swift Standard Library/Apple frameworks before reaching for anything custom.

### Version 1 additions

| Component | Description | Used in |
|---|---|---|
| `CanvasCardView` | Note/media/web card on the Canvas, draggable/resizable | S16 |
| `CanvasConnector` | Labeled line between two Canvas cards | S16 |
| `PropertyEditorRow` | Typed field row (text/number/date/checkbox/list) inline in a Document | S17 |
| `TemplatePickerRow` | Template name + icon, grouped by TemplateGroup, tappable; reused editable for the Template Manager | S18 |
| `TaskDashboardRow` | Checkbox + task text + due-date/priority/recurrence indicators + source note | S19 |
| `RecurrenceControl` | Badge/picker for a task's repeat interval | S19 |
| `AttachmentThumbnail` | Image/PDF thumbnail inline in a document body | S20 |
| `AttachmentPreview` | Full-screen image/PDF preview overlay | S20 |
| `SavedViewChip` | Pinned query name + type (search/task), tappable, always re-evaluates live | S21 |
| `ParticipantAvatar` | Collaborator initials/photo + name | S22 |
| `PermissionLevelPicker` | Read Only / Read & Write selector, text label always paired with the choice | S22 |
| `MigrationSourceRow` | Format selector (Obsidian/Logseq/auto-detect) + detected-format summary | S23 |
| `PluginPermissionRow` | Plugin name + enable toggle + explicit list of granted permissions | S24 |

Sharing's permission levels (`PermissionLevelPicker`) follow the same color-blind-safe rule established above for sync/conflict states: the level is always a text label, never a color or icon alone.

### Flow Enhancements additions (`NoteBytez20260829v1-FlowEnhancements.md`)

| Component | Description | Used in |
|---|---|---|
| `CommandPaletteRow` | Icon + command title, reuses `QuickSwitcherField`'s search-bar-in-surface + plain-list layout idiom | S26 |
| `GraphInsightRow` | Document title + the category-relevant metric (last-edited, open-task count + due date, link degree), metric always icon + text, never color alone | S25 |
| `InsightSectionHeader` | Category title + count + a one-line "what this means" explanation | S25 |
| `TransclusionBlockView` | Bordered container rendering a `!((anchor))` embed's live target-block content, with a small "jump to source" button | S4 (not a new screen — an addition to its rendered body) |

Insight severity (Stale vs. fresh, open vs. done) is never color-only, matching the same
color-blind-safe rule `PermissionLevelPicker` already establishes: `GraphInsightRow` always
pairs its metric with an icon and a text label.

### V2 Enhancements additions (`NoteBytez20260829v2-Enhancements.md`)

| Component | Description | Used in |
|---|---|---|
| `ForceGraphCanvas` | `TimelineView`-driven force-directed layout render of `GraphNode`s — drag to pin a node in place, hop-distance-based opacity, highlight ring for tag-scope matches | S8 (Force mode) |
| `GraphFilterBar` | Depth stepper, node-type filter chips, tag scope field, "Save as View" — scoped to Force mode | S8 (Force mode) |
| Bound-canvas chrome badge | Small "↔ <Note title>" capsule — a board-list row subtitle, and a top-leading overlay on the board itself | S16 |
| `BindBoardSheet` | Note picker for binding a board (reuses the wikilink fuzzy-picker layout) | S16 |
| Connector-creates-link confirm | Alert raised when a connector is drawn between two note cards on a bound board — confirm writes the underlying `[[link]]`, cancel simply never creates the connector | S16 |

`TransclusionBlockView` (above) is also updated by this plan: it is now editable in place rather
than read-only — tap to open an inline `TextEditor`, Done writes back to the source, an "Undo
Edit" affordance reverts the last edit.

## Coverage check

Every component named or implied in [05-Wireframes.md](05-Wireframes.md)'s 15 screens appears in the inventory above.

**Version 1:** every component named or implied in [05-Wireframes.md](05-Wireframes.md)'s S16–S24 appears in the Version 1 additions table above.
