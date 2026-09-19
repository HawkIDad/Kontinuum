<!-- DoNotTranslate.md -->
<!--
  The explicit non-localized register (G20) for NoteBytez20260823v2-MultiLanguage.md Phase 0.3.
  If a string in this list ever shows up as a candidate key in `Localizable.xcstrings`, that is
  a bug in the extraction sweep (Phase 2.1/2.5), not a translation task — fix the call site to
  use `Text(verbatim:)`/a raw `String` instead of a `LocalizedStringKey` literal.
-->

# Do Not Translate

Structural tokens the app parses, matches, or persists as data — never shown to a user as prose,
and never subject to translation. Grouped by why each one is off-limits.

## Interoperability formats — changing these breaks parsing of existing user content

- **Markdown frontmatter keys** — `tags:` (`TagParser`), `notebooks:` (`NotebookParser`,
  `ExportDAL`), and every YAML property key a document's frontmatter block carries
  (`PropertyParser`). These round-trip through plain-text export/import and must match
  byte-for-byte across every locale, or a document exported under one language setting fails to
  re-import under another.
- **The synthetic `#notebook/<kebab-name>` export tag** (`ExportDAL.kebabCase`) — the ASCII
  kebab-case transform of a notebook's name, appended on export so a plain-Markdown reader
  (Obsidian, Logseq) can reconstruct notebook membership from tags alone. The literal `notebook/`
  prefix is a structural marker, not English prose.
- **JSON Canvas field names** (`JSONCanvasFormat`'s `CodingKeys` — `nodes`, `edges`, `type`, and
  siblings) — the [JSON Canvas](https://jsoncanvas.org) interchange format's own schema keys.
- **Block reference anchors** (`BlockDAL.anchor(for:)` and friends) — algorithmically derived
  from heading text, not free text a translator would touch; a translated *heading* still
  produces a new anchor via the same algorithm, which is correct — the anchor *algorithm* itself
  has no English string embedded in it to translate.

## URL schemes — routing tokens, not link text

- `wikilink://`, `tag://`, `blockref://` (matched in `DocumentView`/`TodayJournalView`'s
  `onOpenURL` handling) — the scheme name is compared with `==`, not displayed.

## Identifiers — compared by code, not read by a person

- The CloudKit container identifier `iCloud.com.kwicksync.NoteBytez` (`SyncEngine.containerIdentifier`).
- The app's own name, "NoteBytez" — a proper noun/trademark, never translated, same as any
  other product name.
- **Accessibility *identifiers*** (`sidebar.<destination>`, `tabbar.<destination>`, and the
  handful of others `ElementQuerying.swift`'s UI tests key off) — these are `.accessibilityIdentifier`
  values read by UI test automation, not `.accessibilityLabel` values read by VoiceOver. **Do
  not confuse the two**: an accessibility *label* (what VoiceOver speaks) is user-facing and
  **is** localized; an accessibility *identifier* (what a test targets) is not.

## Diagnostics — developer-facing only

- Every `OSLog`/`Logger` message (`Log.logger(...)` call sites across `sync/`, `dal/`) — these
  never reach a user; keep them in English so anyone triaging a log (support, the developer, a
  future contributor) can read them regardless of the device's language.

## How this list is used

- Phase 2.5's extraction sweep adds a regression test asserting `ExportDAL` still emits the
  literal `notebooks:` frontmatter key and `#notebook/<kebab>` tag regardless of the active
  locale.
- The Phase 0.5 `translate-strings` script never sees these — they are never wrapped in
  `LocalizedStringKey`/`String(localized:)` in the first place, so they never enter
  `Localizable.xcstrings` to begin with. This document exists so a future contributor (or an AI
  translation pass) recognizes *why* a given string was deliberately left as a plain, hardcoded
  literal instead of assuming it was simply missed.
