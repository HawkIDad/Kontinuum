<!-- Glossary.md -->
<!--
  Machine-readable product-term glossary for NoteBytez20260823v2-MultiLanguage.md Phase 0.4
  (G11) / R5. `Scripts/translate-strings` parses the table below (pipe-delimited, one term per
  row, column order fixed) and passes each string's glossary hits to the translation model as
  extra context — it does NOT pre-supply the translated word per language. Per-language
  overrides start empty and are filled in during that language's own phase (6.4/7.4/8.x/9.6/10.6/
  11.7's "glossary conformance spot-check" tasks), not invented ahead of time.
-->

# Product Term Glossary

## Directives

| Directive | Meaning |
|---|---|
| `translate` | Render the term in the target language's own vocabulary. |
| `loanword` | Keep the English word as-is (in Latin script), the way Obsidian/Logseq migrants already know it — R5. |
| `transliterate` | Render the English word's *sound* in the target script (used only where a loanword in Latin script would be unreadable — e.g. Arabic, Chinese, Japanese, Korean, Greek, Serbian's Cyrillic). |

A language-specific override in the last column takes precedence over `Default Directive` for
that term in that language; an empty override means "use the default."

## Terms

| Term | Usage note (for the translator/model) | Default Directive | Per-language overrides |
|---|---|---|---|
| Library | The top-level container for a user's notes (S1) — not a physical/lending library. | translate | |
| Notebook | A user-created grouping of notes (S14), distinct from a physical paper notebook only in that it's digital — the everyday word applies. | translate | |
| Journal | The daily-entry note (S3/Today) — a diary/log, not a ledger. | translate | |
| Tag | A `#hashtag`-style label (S13). | translate | |
| Property | A YAML-frontmatter key/value pair on a note (S17), same sense as a spreadsheet "field" or a database "property." | translate | |
| Template | A reusable note starting-point (S15/S16). | translate | |
| Saved View | A stored search/filter configuration a user can reopen (S21). | translate | |
| Backlink | A link *to* the current note from elsewhere (S5) — the Obsidian/Logseq/Roam term of art; migrants from those tools already know this exact English word. | loanword | zh-Hans: translate (反向链接 — see Phase 9.1 note below); ja: transliterate (バックリンク); ko: transliterate (백링크); ar: transliterate |
| Wikilink | The `[[Title]]` linking syntax itself (not the rendered link) — same migration rationale as Backlink. | loanword | zh-Hans: translate — phonetic+meaning hybrid (维基链接, reusing the universal "维基" transliteration of "wiki" from 维基百科/Wikipedia); ja: transliterate (ウィキリンク); ko: transliterate (위키링크); ar: transliterate |
| Canvas | The freeform card/board view (S18/S19) — Obsidian Canvas and JSON Canvas both use this exact English word as their format/feature name. | loanword | zh-Hans: translate (画布 — see Phase 9.1 note below); ja: transliterate (キャンバス); ko: transliterate (캔버스); ar: transliterate |
| Block reference | The `((anchor))` syntax referencing a specific paragraph/line (S20), Logseq's term of art. | loanword | zh-Hans: translate (块引用 — see Phase 9.1 note below); ja: transliterate — phonetic+meaning hybrid (ブロック参照); ko: transliterate — phonetic+meaning hybrid (블록 참조); ar: transliterate |
| Promote | Turning a block or a daily-journal entry into its own standalone document (Decision 9). A verb of elevation/upgrade, not "advertise" or "publicize" — pick the target language's "move up a level" sense, not a marketing sense. | translate | |
| Command Palette | The `Cmd+P`-style fuzzy-command launcher. | translate | |
| Insights | The Graph Insights dashboard (orphan notes, hub notes, etc.) — plain "analysis/overview" sense, not "psychological insight." | translate | |
| Send to Canvas | Graph view toolbar action (`GraphView.swift`) that sends the current graph selection to a Canvas board (`CanvasDAL`'s "Send to Canvas," Decision 4) — "Send" in the plain transfer/move sense, "Canvas" per its own `loanword`/override row above. | translate | |

## Phase 9 zh-Hans override (Backlink, Wikilink, Canvas, Block reference)

The default `transliterate` directive assumes a phonetic rendering stays recognizable once
dropped into the target script — true for Japanese/Korean, whose phonetic loanword systems
(katakana, Hangeul phonetic borrowings) are the idiomatic way those languages absorb foreign tech
terms. It does not hold for Chinese: a syllable-for-syllable phonetic rendering of a multi-syllable
English compound (e.g. "Backlink") produces a string with no relationship to its meaning that no
Chinese reader would recognize. Real-world Obsidian/Logseq Simplified Chinese localizations use
semantic translations for exactly these four terms (反向链接, 画布, 块引用), not phonetic ones, and
Wikilink's translation reuses "维基" — already the universal Chinese transliteration of "wiki" via
维基百科 (Wikipedia's own Chinese name) — paired with the translated "链接" (link). This is a
per-language override, not a change to the default: `ja`/`ko`/`ar` are unaffected.

## Adding a new term

Add a row here **before** its first string reaches `Localizable.xcstrings` (Phase 12.5 makes
this an explicit release-checklist step for every future feature). A term with no row here still
gets translated — it just gets no glossary context, which is the thing this file exists to avoid.
