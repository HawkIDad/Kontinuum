<!-- NoteBytez20260823V2-MultiLanguage.md -->
<!--
  User story describing the features needed for NoteBytez to support users that are not using English.
-->
# Multi-Language Support

As a user (senior software engineer), I want to ensure that the NoteBytez app can be downloaded and used by end users that are not comfortable using the English language. On first launch, the app will prompt the user to choose their preferred language from the languages available in that build; the user can change that choice at any time afterward from the application's Settings. This will allow a broader use of the application.

# Success Factors

1. All UI/UX text elements used in the NoteBytez to generate the complete UI/UX experience will support languages other than English.
2. Initial languages/dialects supported:
    1) English - United States
    2) English - United Kingdom
    3) Spanish
    4) French
    5) German
    6) Italian
    7) Polish
    8) Romanian
    9) Dutch
    10) Danish
    11) Turkish
    12) Bavarian
    13) Portugese
    14) Hungarian
    15) Greek
    16) Czech
    17) Swedish
    18) Serbian
    19) Chinese - Mandarin
    20) Japanese
    21) Korean
    22) Arabic
    23) Swahili
    24) Hausa
    25) Yorub
    26) Igbo
    27) Finnish
    28) Norwegian
    29) Bosnian
    30) Lithuanian
3. Translation of these elements will be performed by AI.
4. On first launch, the user is prompted to choose the application's language from the languages available in that build (pre-selected to the device's own language when it is supported); the choice can be changed at any later time from the application's Settings.

---

# Gaps Identified and Decisions

The original User Story ("app can be downloaded and used by end users not comfortable with
English") and the three Success Factors leave the scope, the language list, the translation
pipeline, and every localization-adjacent technical concern unspecified. Gaps below were
identified against the current codebase (state: `LOCALIZATION_PREFERS_STRING_CATALOGS = YES`
in the project, but **no String Catalog exists yet**; `knownRegions = (en, Base)`;
`developmentRegion = en`; ~227 user-facing string literals in `NoteBytez/views/`; English
pluralization hand-rolled in code; title sort is a raw `<` comparison; tag canonicalization
case-folds without locale awareness). Decisions were made in an interview on 2026-08-29.

## Scope

| # | Gap | Decision |
|---|---|---|
| G1 | "Downloaded" implies App Store listing/metadata/screenshot localization; SF1 only says "UI/UX text". | **In-app UI only.** App Store name, subtitle, description, keywords, screenshots, and per-territory availability are **out of scope** for this effort and handled separately. |
| G2 | Unclear whether NoteBytez-*generated* content is "UI text": starter `TemplateGroup`s (Fiction Writing, Character, Location…), `JournalDAL.template(for:)`, example seed data. | **Localize at creation time.** `LibraryDAL.create`'s seeding (`TemplateDAL.seedStarterContent`, journal template) emits content in the device's current language *at the moment the library is created*; it is never retranslated afterward — it is the user's editable data from that point. |
| G3 | No definition of done / acceptance bar / sign-off owner for SF1's "supports". | Acceptance = (a) no hardcoded user-facing string remains (lint, Phase 0); (b) pseudolocalization + double-length + RTL pseudolanguage passes show no truncation or layout break (Phase 0/6); (c) per-locale key-completeness is 100% at ship (missing keys fall back to en-US at runtime and are CI-warned, never blank); (d) a per-locale screenshot pass of the key-screen set is reviewed before that locale's tier ships. Owner: the release engineer for each tier. |
| G4 | How does a user actually get a non-English experience? | **Both.** iOS per-app language (Settings → NoteBytez → Language, automatic once localizations ship) **and** an in-app language override, set either from the first-launch prompt (G4b) or from `SettingsView` (see G4a) thereafter. |
| G4a | In-app override mechanism from Settings (true no-relaunch switching is hard on iOS). | In-app picker sets the app's preferred localization (`AppleLanguages` in the app's `UserDefaults` suite) and applies on next launch, with a clear "changes take effect after restart" note. No attempt at live re-render of the whole tree. A "System default" option clears the override. |
| G4b | New requirement (SF4): a first-launch prompt, not just a Settings row. Where does it sit in the cold-start flow, which languages can it offer before any translations exist, and how does it avoid a restart when the rest of the app hasn't rendered yet? | **A first-launch prompt precedes everything else**, including the entitlement/paywall gate (a user should be able to read the paywall in their own language) — it is the very first thing `RootView` shows. Shown exactly once, gated by a `hasPromptedForLanguage` flag in `LocalePreferenceStore` (same persistence pattern as `TemplateOnboardingStore`). It offers **only languages already shipped in the running build** (see the `SupportedLocales` registry, Phase 5.3) plus English (United States), never the full 24-locale target list — picking a language with zero translated strings would look broken, not localized. The device's own language is pre-selected when it's in that supported list (English (United States) otherwise), so confirming is a single tap for the common case, but the prompt always appears — this is an explicit choice moment, not silent auto-detection. Because nothing has rendered yet, the selection takes effect immediately with **no restart**; restart-on-change (G4a) still applies to a *later* change made from Settings, since by then the view hierarchy is already live. Not addressed here: whether a full-screen first-launch prompt is the right pattern on macOS (a modal sheet may fit macOS conventions better) and updating `UIUX/04-InteractionDesign.md` / `UIUX/05-Wireframes.md` with this new pre-S1 step — both are follow-ups outside this document. |

## Language list

| # | Gap | Decision |
|---|---|---|
| G5 | 6 entries have little/no iOS display-language or App Store localization support: **Bavarian** (a German dialect, no locale), **Swahili**, **Hausa**, **Yoruba** ("Yorub", also a typo), **Igbo**, **Bosnian**. | **Dropped from scope.** Revisit only if Apple adds first-class support. |
| G6 | Script/region variants unresolved: Portuguese (pt-PT vs pt-BR), "Chinese – Mandarin" (zh-Hans vs zh-Hant), Serbian (Cyrl vs Latn), Norwegian (nb vs nn). | **Larger-market single variant each:** `pt-BR`, `zh-Hans`, `sr-Cyrl`, `nb`. |
| G7 | Two English variants (US + UK) — parallel maintenance for spelling. | **Keep both.** `en-US` is the development base; `en-GB` is an override layer carrying *only* the strings that actually differ (spelling, a few terms), inheriting en-US for the rest. |
| G8 | No canonical BCP-47 list. | **Final set — 24 locales:** `en-US` (base), `en-GB`, `es`, `fr`, `de`, `it`, `pt-BR`, `nl`, `sv`, `da`, `nb`, `fi`, `pl`, `cs`, `hu`, `ro`, `tr`, `el`, `lt`, `sr-Cyrl`, `zh-Hans`, `ja`, `ko`, `ar`. (Turkish (`tr`) was present in the original Success Factors list but missing from an earlier draft of this table with no recorded reason — restored here; it was never in G5's dropped set.) |
| G9 | No phasing — 24 locales is a large QA matrix. | **Six phases** (see Implementation Plan Phases 6–11), ordered by market size, then by script/format complexity so the harder QA cases (heavy CLDR plurals, non-Latin scripts, RTL) land later and in smaller, more homogeneous batches: <br>• **Phase 1** — `en-US`. Already the base/development locale (Phase 0/2 output); no translation work. <br>• **Phase 2** — `en-GB`, `es`, `fr`, `de`, `it`, `pt-BR`. Largest Western-European markets, all Latin script, simple plural rules. <br>• **Phase 3** — `nl`, `da`, `el`, `sv`, `fi`, `nb`. Adds the Greek script; otherwise straightforward Latin-script Northern-European languages. <br>• **Phase 4** — `zh-Hans`, `ko`, `ja`. CJK: no inter-word spaces, denser glyphs, IME interaction (G21). <br>• **Phase 5** — the remaining Success-Factor-listed, non-dropped European languages: `pl`, `ro`, `tr`, `hu`, `cs`, `sr-Cyrl`, `lt`. Adds Cyrillic; exercises the CLDR plural refactor hardest (`pl`, `ro`) and Turkish's dotless-ı/dotted-İ casing (already covered as a Phase-1 *Unicode-correctness* test, see 1.1). <br>• **Phase 6** — `ar`. RTL, gated per G16; does not ship until Phase 11's layout/editor work is complete. <br>A phase ships when it passes its screenshot/pseudoloc gate. |

## Translation pipeline (SF3 = "performed by AI", nothing else)

| # | Gap | Decision |
|---|---|---|
| G10 | No mechanism. | **Repo script over the String Catalog.** `Scripts/translate-strings.swift` (or a small SPM tool) extracts untranslated/stale keys from `Localizable.xcstrings`, sends each with its comment/context **and the terminology glossary** to an AI model, writes results back into the `.xcstrings`. Re-runnable and diffable; output committed to git so a re-run only touches what English changed (acts as translation memory). No third-party localization service. |
| G11 | No terminology control for product terms (Notebook, Backlink, Journal, Canvas, Wikilink, Promote, Block reference, Notebook, Library, Tag, Property, Template, Saved View). | **Maintained glossary** at `Docs/Localization/Glossary.md` (machine-readable table the script consumes). Each term carries a per-language directive: `translate` / `keep-as-loanword` / `transliterate`, so e.g. "Backlink" renders consistently and matches what Obsidian/Logseq migrants expect in that language. |
| G12 | No human/native review policy. | **AI-only, fix on report.** No review gate. Ship AI translations; provide an in-app "Report a translation issue" path (Phase 12) that captures the key, locale, screen, and current value. Corrections are applied to the `.xcstrings` and shipped in the next release. |
| G13 | No drift control when English strings change. | **CI warns, runtime falls back.** A CI step lists keys that are new / stale (English changed after translation) / missing per locale as a **non-blocking warning**. At runtime, any missing/empty value resolves to `en-US` so the UI is never blank. |
| G14 | Existing code hand-rolls English plurals (`"note\((n) == 1 ? "" : "s")"` in `SettingsView`, and similar). | **Adopt CLDR plural rules everywhere.** Every count-bearing string becomes a String Catalog plural variation; the hand-rolled ternaries are removed. Covers Polish/Romanian/Arabic multi-category plurals correctly. |
| G15 | Format specifiers / interpolation safety across languages (reordered args, `%@` vs positional `%1$@`). | The translate script validates that every translation preserves the placeholder set of its source (count, names, `%`-specifiers); a mismatch is a CI error, not a warning. |

## Technical concerns SF1 does not mention

| # | Gap | Decision |
|---|---|---|
| G16 | **RTL** (Arabic): layout mirroring, `.leading`/`.trailing` audit (views currently use some `.left`/`.right`), bidi in the Markdown editor/preview (e.g. an English `[[note title]]` inside Arabic prose), directional SF Symbols. | **Full RTL, gating the Arabic phase only** (Phase 11). Earlier phases are unaffected. Arabic does not ship until layout mirrors correctly and the editor handles bidi. |
| G17 | **Unicode correctness** in DAL/parsers: title sort is `$0.title ?? "" < $1.title ?? ""` (not locale-aware); `TagParser.canonicalize` case-folds without handling Turkish dotless-ı / German ß; `WikilinkParser.fuzzyMatches` and search are not verified for NFC/NFD normalization or accent/diacritic handling. | **In scope, as an early phase** (Phase 1), *before* any locale rolls out. Sort → `localizedStandardCompare`; canonicalization → locale-aware case-folding + Unicode NFC normalization at every text-ingest boundary; fuzzy match / FTS reviewed for diacritic-insensitive behavior. These are correctness bugs that compound per language. |
| G18 | **Locale-dependent formatting**: `JournalDayHeader` date, `SyncStatusViewModel.lastSyncedText` ("Xm ago"), backup snapshot timestamps, first-day-of-week for journal navigation, number formatting. | **In scope** (Phase 1). All date/number/relative-time rendering routed through locale-aware `Date.FormatStyle` / `RelativeDateTimeFormatter` / `Calendar.current` with the active locale; no manually assembled date strings. |
| G19 | **Local Swift packages** (`../MarkdownG9`, `../SwiftRPT`) may expose user-facing strings. | **Audit both** (Phase 3). Any user-facing string gets its own String Catalog in that package, fed by the same translate script. If none exist, record that and move on. |
| G20 | **Do-not-translate set** is undefined — risk of localizing structural tokens. | Explicit non-localized register (Phase 0): `OSLog` messages; URL schemes (`wikilink://`, `tag://`, `blockref://`); frontmatter keys (`notebooks:`, `tags:`, property keys); the synthetic `#notebook/<name>` export tag; block anchors; JSON Canvas field names; the app name "NoteBytez"; the CloudKit container ID; accessibility *identifiers* (`sidebar.*`, `tabbar.*` — distinct from accessibility *labels*, which are localized). |
| G21 | **Font coverage** for the editor's `.body.monospaced()` across CJK/Arabic. | Check during Phases 9 and 11. If monospaced SF has gaps for a script, fall back that script's editor to proportional `.body` and accept system font substitution; documented, not worked around. |

## Additional recommendations (beyond the interview)

- **R1 — Pseudolocalization scheme now.** Add an Xcode scheme / run-destination using the
  *Double-Length Pseudolanguage* and *Right-to-Left Pseudolanguage*. Run it every Phase-2 PR to
  catch truncation and hardcoded strings *before* real translations exist.
- **R2 — Hardcoded-string lint.** A CI check flagging user-facing string literals that bypass
  `LocalizedStringKey` (e.g. `Text(verbatim:)`, `String(...)` passed to a label, interpolated
  titles). SwiftUI auto-localizes `Text("literal")`, so most of the 227 are fine — the check
  targets the exceptions.
- **R3 — Per-locale screenshot harness.** An XCUITest that walks the key-screen set
  (S1, S3, S4, S7, S9, Settings, Task Dashboard, Canvas list) and captures screenshots per
  locale. This is the review artifact for the "AI-only, fix on report" model (G12) — a cheap
  visual pass without paid reviewers.
- **R4 — Translator context comments.** Every `.xcstrings` entry gets a `comment` (extracted
  from adjacent code comments where present; a one-time manual pass for ambiguous UI strings
  like "Promote", "Fit to Screen"). The translate script refuses to translate a comment-less
  key flagged `needs-context`.
- **R5 — Glossary seeds from the migration story.** For Obsidian/Logseq migrants, some terms
  are better left as English loanwords in several languages (their prior tools did). The
  glossary's default for `Backlink`, `Wikilink`, `Canvas` leans loanword; `Notebook`,
  `Journal`, `Tag`, `Search`, `Settings` lean translate. Confirm per language as translations
  land.
- **R6 — Keep `en-US` the single source of truth in code.** Developers only ever write en-US
  strings; `en-GB` and all others are catalog-only. No `#if` locale logic in Swift.
- **R7 — Test-launch bypass for the first-launch prompt (G4b).** Every existing
  `NoteBytezUITestCase`-based test and manual `-EnableLiveSync` launch expects to land directly
  on S1 or the main shell; the new mandatory first-run prompt would otherwise block all of them.
  Add a `-SkipLanguagePrompt` launch argument (mirrors `-SeedTestConflicts`) that pre-seeds
  `hasPromptedForLanguage` at launch in Debug builds, and update
  `NoteBytezUITestCase.launchAndCreateLibrary` (and any other shared launch helper) to pass it
  by default (Phase 5.7). This is the highest-blast-radius task in this document — it touches
  every one of the ~30 existing UI test files indirectly through the shared helper, not just the
  new feature's own tests — so it ships in the same PR as the prompt itself, never after.

---

# Implementation Plan

Source: this document's User Story / Success Factors + Gaps Identified and Decisions above.
Baseline: MVP complete, R1 ~95%. Ordered by build dependency — infrastructure and
Unicode/format correctness precede string externalization; externalization precedes any
translation; translation rolls out per tier. TDD per `CLAUDE.md` §8: the failing test is the
first task of a feature. Checkbox convention: `[ ]` not started / in progress, `[x]` done and
verified.

## Progress Summary

| Phase | Tasks | Status |
|---|---|---|
| 0. i18n Infrastructure | 9 / 9 | Done |
| 1. Unicode & Locale Correctness (pre-localization) | 8 / 8 | Done |
| 2. String Externalization (app target) | 7 / 7 | Done |
| 3. Package String Audit | 3 / 3 | Done |
| 4. Seed-Content Localization at Creation Time | 5 / 5 | Done |
| 5. In-App Language Override (Settings row **and** first-launch prompt) | 8 / 8 | Done |
| 6. Language Rollout Phase 1 — `en-US` (baseline) | 1 / 1 | Done |
| 7. Language Rollout Phase 2 — `en-GB`, `es`, `fr`, `de`, `it`, `pt-BR` | 6 / 6 | Done — hand-authored (no API credit available); see phase notes |
| 8. Language Rollout Phase 3 — `nl`, `da`, `el`, `sv`, `fi`, `nb` | 5 / 5 | Done — hand-authored (no API credit available); see phase notes |
| 9. Language Rollout Phase 4 — `zh-Hans`, `ko`, `ja` | 6 / 6 | Done — hand-authored (no API credit available); IME composition and full screenshot pass partially limited by simulator tooling, see phase notes |
| 10. Language Rollout Phase 5 — `pl`, `ro`, `tr`, `hu`, `cs`, `sr-Cyrl`, `lt` | 7 / 7 | Done — hand-authored (no API credit available); first phase with real multi-category CLDR plurals, see phase notes |
| 11. Language Rollout Phase 6 — `ar` (RTL) | 0 / 9 | Not started |
| 12. Drift Maintenance & Translation Feedback | 5 / 5 | Done — "Report a Translation Issue" shipped; see phase notes |
| 13. Verification Gate | 0 / 6 | Not started |
| **Total** | **70 / 85** | **82%** |

---

## Phase 0 — i18n Infrastructure

No user-visible change. Everything that must exist before strings are externalized or translated.

- [x] **0.1** Created `NoteBytez/Localizable.xcstrings` (`sourceLanguage: "en"`). Added all 23
  non-`en` locales from G8 to `knownRegions` in `project.pbxproj` (`en`/`Base` already present).
  Verified via a real `xcodebuild build`.
- [x] **0.2** `developmentRegion` left as `en` in the pbxproj (unchanged); `en-US`/`en-GB` exist
  only as catalog-level locale entries, per R6 — no project-setting change needed.
- [x] **0.3** Wrote `NoteBytez/Docs/Localization/DoNotTranslate.md` (frontmatter keys, the
  synthetic `#notebook/<kebab>` tag, JSON Canvas field names, block-reference anchors, URL
  schemes, the CloudKit container id, the app name, accessibility identifiers vs. labels, OSLog
  messages) and cross-referenced it from `ARCHITECTURE.md` and `Docs/styleGuide.md`.
- [x] **0.4** Wrote `NoteBytez/Docs/Localization/Glossary.md` — a machine-readable term table
  (Library, Notebook, Journal, Tag, Property, Template, Saved View, Promote, Command Palette,
  Insights = `translate`; Backlink, Wikilink, Canvas, Block reference = `loanword`, with
  zh-Hans/ja/ko/ar `transliterate` overrides) covering R5's product-term list.
- [x] **0.5** Built `Scripts/translate-strings` as a standalone SPM package (executable +
  test target, `TranslateStringsCommand.swift` — named non-`main.swift` so the executable target
  stays importable by its own tests). Implements `--locale`, `--dry-run`, `--report`, and (added
  during Phase 2.1) `--extract <dir>` for regex-based catalog population. `AnthropicTranslator`
  used when `ANTHROPIC_API_KEY` is set, `DryRunTranslator` otherwise. 30/30 package tests pass.
- [x] **0.6** `Placeholders.isSafe`/`Placeholders.Mismatch` validate the exact placeholder
  multiset (`%@`, `%1$@`, `%#@variable@`) between source and translation; a mismatch fails the
  command with a non-zero exit and a printed report. Covered by `PlaceholdersTests`.
  **Not yet wired as a separate CI job** — currently only runs inline during a `--locale`
  translation pass, not as its own standalone gate; revisit if CI wiring is requested.
- [x] **0.7** `DriftReport.generate`/`printReport` implemented and callable via
  `translate-strings --report`; prints new/stale/missing keys per locale.
  **Not yet wired into CI** (no GitHub Actions/CI config exists in this repo at all yet) — the
  reporting logic exists and is tested, but nothing invokes it automatically per PR.
- [x] **0.8** `Scripts/lint-hardcoded-strings.sh` — regex-based (`git grep --untracked`, so a
  new not-yet-`git add`ed file is still caught), flags `.navigationTitle(EXPR)` /
  `.accessibilityLabel(EXPR)` where `EXPR` doesn't start with `"`, plus any `Text(verbatim:`.
  Baseline lives in `Scripts/hardcoded-strings-baseline.txt` (37 reviewed exceptions after Phase
  2.1 — see that phase's notes); `--update-baseline` accepts new findings deliberately.
  **Not yet wired into CI** for the same reason as 0.6/0.7 — runnable locally and used during
  Phase 2.1, but no CI to attach it to yet.
- [x] **0.9** `Scripts/run-pseudolocalized.sh` wraps Apple's built-in pseudolocalization launch
  flags (`-NSDoubleLocalizedStrings YES` for double-length, `-AppleTextDirection YES
  -NSForceRightToLeftWritingDirection YES` for RTL, `-NSShowNonLocalizedStrings YES` for
  accented/missing-key detection) against a booted simulator. Empirically verified via real
  screenshots. Documenting the workflow in `docs/styleGuide.md` §Accessibility is still
  outstanding — tracked for Phase 2.6, when it will actually be run screen-by-screen.

---

## Phase 1 — Unicode & Locale Correctness (pre-localization)

DAL / parser / formatter layer. Fixes latent correctness bugs (G17, G18) before any locale
exposes them. No new UI language yet.

- [x] **1.1 Failing tests first.** Written against `GraphDALTests`, `BlockReferenceDALTests`,
  `NotebookDALTests`, `TagParserTests`, `WikilinkParserTests`, `SearchDALTests`, `DocumentDALTests`,
  and a new `TextNormalizationTests`. One genuinely failed pre-fix and pinpointed a test bug, not
  a product bug (see note below); the collation/diacritic/NFC assertions mostly *passed* even
  pre-fix, because Swift's `String ==`/`Character` equality already honors Unicode canonical
  equivalence — the value added was making the correctness explicit and locale-*invariant* where
  it mattered (canonicalization identity, sort order, search), not fixing crashes. Documented
  honestly rather than overclaiming a bug that wasn't there.
- [x] **1.2** `GraphDAL.directLinks`/`neighborhood` and `BlockReferenceDAL.resolve`'s raw
  `($0.title ?? "") < ($1.title ?? "")` comparisons -> `.localizedStandardCompare(...) ==
  .orderedAscending`. `TagDAL`/`NotebookDAL`/`LibraryDAL`/`TemplateDAL`/`PropertyDAL`/`CanvasDAL`'s
  `SortDescriptor(\.name)` sites needed **no change** — Foundation's `SortDescriptor(_:comparator:)`
  already defaults to `.localizedStandard`; locked in with a new `NotebookDALTests` case rather
  than left as an unverified assumption. `DocumentDAL.fetchActive` itself sorts by `updatedOn`,
  not a string, so there was nothing to fix there directly — the actual title-collation call
  sites are its two consumers above.
- [x] **1.3** New `NoteBytez/dal/TextNormalization.swift`: `normalized(_:)` (NFC via
  `precomposedStringWithCanonicalMapping`) and `invariantLowercased(_:)` (`lowercased(with:
  Locale(identifier: "en_US_POSIX"))` — deliberately not `Locale.current`, so canonicalization
  can never diverge by device language). `TagParser.canonicalize` now composes both. NFC applied
  at the actual text-ingest chokepoint — not `DocumentViewModel.content` (a live `TextEditor`
  binding; normalizing per keystroke risks corrupting in-progress IME composition, e.g. Hangul/
  Pinyin) but `DocumentDAL.create` / `updateContent` / `updateTitle`, which import (`ImportDAL`),
  migration (`JournalDAL`/journal import), Canvas-to-document, notebook promote, and the editor's
  own `save()` all funnel through — traced and confirmed, not assumed.
- [x] **1.4** `WikilinkParser.fuzzyMatches` (which `BlockReferenceDAL.autocompleteMatches` also
  reuses, per its own doc comment) now NFC-normalizes and diacritic-folds both sides before the
  subsequence match — case- *and* diacritic-insensitive, so a plain "cafe" query fuzzy-matches
  "Café".
- [x] **1.5** `SearchDAL`'s title/content/tag/property matching, ranking, and snippet-centering
  switched from `localizedCaseInsensitiveContains`/`.caseInsensitive` to
  `containsIgnoringCaseAndDiacritics` (new `String` extension, same file as `TextNormalization`)
  / `[.caseInsensitive, .diacriticInsensitive]`.
- [x] **1.6** Audited — already correct, no change needed. `JournalDayHeader`
  (`.formatted(date: .complete, ...)`), `SyncStatusViewModel.lastSyncedText`
  (`.formatted(.relative(presentation: .named))`), and `BackupSnapshotRow`
  (`Text(_, format: .dateTime...)`) already use locale-aware `Date.FormatStyle`.
  `TaskDashboardViewModel`'s week-interval math already uses `Calendar.current` (first-day-of-week
  follows the locale automatically). No manually-formatted numbers exist anywhere in the app.
- [x] **1.7** Audit surfaced two real bugs in the *opposite* direction — machine-readable,
  non-user-facing `DateFormatter`s that must be locale-**invariant** and weren't:
  `LogseqImporter.makeDateFormatter` (parses `yyyy_MM_dd`/`yyyy-MM-dd` journal filenames) and
  `MigrationArchiveDAL.archiveTimestampFormatter` (`yyyyMMdd-HHmmss` archive folder names) had no
  `.locale`, so a non-Gregorian-calendar or non-ASCII-digit device locale could fail to parse or
  generate them correctly (Apple TN QA1480). Both now pin `Locale(identifier: "en_US_POSIX")`.
- [x] **1.8** `NoteBytezTests`: 815/815 green (one `ConflictStoreTests` timing test flaked once
  under full-suite parallel load and passed on re-run and in isolation — pre-existing, unrelated
  to this phase, not introduced here). `../MarkdownG9`: 46/46 green, unaffected (untouched by
  this phase). Manual pass: launched under `-AppleLanguages (de) -AppleLocale de_DE` — no crash,
  `Date.FormatStyle` visibly picked up German date conventions ("12. September" ordering) with no
  translations yet in place (expected — Phase 2/6+ work), created a library/note and typed/tagged
  content without incident. A true pseudolocalization (`tr`/`de`/`sv`) run destination doesn't
  exist yet — that's Phase 0.9, not built as part of this phase since Phase 1 has no UI/String
  Catalog dependency on Phase 0. Revisit once Phase 0 ships.

---

## Phase 2 — String Externalization (app target)

Every user-facing literal into `Localizable.xcstrings`, with context, plurals refactored.

- [x] **2.1** Swept the Phase-0.8 baseline's 26 offenders. `AppDestination.rawValue` (used both
  as a stable structural id and, previously, as display text) got a separate
  `AppDestination.displayName: LocalizedStringKey` computed property rather than changing
  `rawValue`'s type — 10 `ContentView.swift` call sites fixed this way. Three decorative/
  structural literals (`"NoteBytez"` app name ×3, `"!"` embed-marker glyph ×2, `"—"` empty-diff
  placeholder) converted to `Text(verbatim:)` per `DoNotTranslate.md`. The remaining 16: `?? "
  fallback"` cases (`Canvas`, `Attachment`, `Notebook`, `Saved View`, `Template`, `Group`,
  `Untitled`) converted to `optional.map(Text.init) ?? Text("fallback")` so user content stays
  verbatim (G2) while the fallback is a real catalog key; ternaries of two literals
  (`CanvasBoardView`'s connect-cards label, `GraphNode`'s current/linked-note label,
  `SearchView`'s advanced-search toggle) converted to `condition ? Text("A") : Text("B")`;
  `TemplatePackPreviewView.pack.displayName` (bundled, non-user content) converted to
  `Text(LocalizedStringKey(pack.displayName))` so its runtime value resolves as a catalog key.
  `SyncStatusViewModel.statusHeadline`/`lastSyncedText` (previously hardcoded English `String`
  properties feeding a verbatim `Text`) converted to `String(localized:)` — the actual root
  cause behind `SyncStatusGlyph`'s flagged ternary; `ForceGraphCanvas`'s
  `accessibilityLabel(for:hopDistance:)` helper got the same treatment. `TaskCheckbox.label` and
  `ForceGraphCanvas`'s call site are accepted G2/helper exceptions, left as-is.
  `StringExtractor` gained a `String(localized: "literal")` pattern (still excluding
  interpolation, same as its existing patterns) to catch the newly-`String(localized:)`-backed
  cases. Baseline re-recorded via `--update-baseline` (37 reviewed exceptions — grew from 26
  because several fixed call sites, now wrapped in `Text(...)`, still don't start with `"` under
  the lint's own literal heuristic and so remain intentionally listed). Full `xcodebuild build`
  and `NoteBytezTests` (815/815, excluding the pre-existing `ConflictStoreTests` timing flake
  documented in Phase 1) both verified green after this pass.
- [x] **2.2** Extraction tooling built and run: `StringExtractor.swift` (regex over
  `Text`/`Label`/`Button`/`.navigationTitle`/`.accessibilityLabel`/`.help`/`Section`/
  `String(localized:)`, plain literals only — interpolation deferred to 2.4) plus
  `--extract <dir>` wired into `translate-strings`. Two extraction passes run against
  `NoteBytez/`: the first surfaced 3 `DoNotTranslate.md` violations (fixed in 2.1, see above);
  after resetting the catalog and re-running, **178 clean keys, 0 policy violations**. A
  `STRING_CATALOG_GENERATE_SYMBOLS` build setting (unused elsewhere in the codebase — no
  generated-symbol accessor was ever called) was turned off after it started failing the build
  with false "same generated symbol" collisions between intentionally-distinct strings that
  differ only by trailing `…` or case (`"Settings"` vs `"Settings…"`, `"downloading…"` vs
  `"Downloading…"`, etc.) — a build-setting fix, not a string change.
  `needs-context` implemented as agreed: `StringCatalog.Entry.needsContext` is `true` when a
  key's `comment` starts with the literal `NEEDS-CONTEXT` (schema-safe — no non-standard field
  added to the `.xcstrings` shape); `TranslateStringsCommand` now refuses to run any `--locale`
  translation pass while a flagged key exists, printing the list and exiting 1
  (`StringCatalogTests` covers both the flagged and unflagged cases). The one-time manual pass
  (R4) then found and wrote real comments for the 14 genuinely ambiguous short keys in the
  catalog (`Promote`, `Fit to Screen`, `Done`, `Group`, `Restore`, `Update`, `Or create new`,
  `Status`, `Explore`, `downloading…`/`Downloading…` as a matched pair, `Added`, `Notes`,
  `Export`) by tracing each to its call site — none needed to stay flagged, since a real
  comment could always be written once the call site was actually read. Verified via
  `xcodebuild build` and a full `--report` run against the rebuilt catalog.
- [x] **2.3** Plural refactor (G14). Grepped for `? "" : "s"` / `count == 1` / `\(count)
  ...` patterns app-wide (not just the doc's example) and converted all 15 hits (10 flagged
  originally, plus `RecurrenceRule.displayName`'s 3 unlocalized enum-case strings and the two
  Phase-2.1 stopgap cases — `SyncStatusViewModel.statusHeadline`'s conflict count and
  `ForceGraphCanvas`'s hop-distance label — found needing the same fix) — zero survivors,
  confirmed by re-running the grep. **A real, load-bearing empirical correction happened here**:
  this tool's own `StringCatalog.isPluralVariant` and this doc's own G14/R-series wording both
  assumed a plural entry's `variations` key lives at the *top level* of a `.xcstrings` string
  entry (matching Apple's out-of-context schema snippets and this project's own initial,
  untested `StringCatalogTests` fixture). Tested directly against a real compiled `.stringsdict`
  (`plutil -p` on the built `.app`'s `en.lproj/Localizable.stringsdict`): a top-level
  `variations` key silently compiles to one flattened string, **discarding every plural
  category but one, with no build error** — the actual required shape nests `variations.plural`
  *inside* the language's own `localizations.<lang>` entry, which correctly compiles to
  `NSStringFormatSpecTypeKey: NSStringPluralRuleType`. Caught only because a new
  `NoteBytezTests/PluralCatalogTests.swift` asserted the actual rendered string for count 0/1/2+
  (not just that the code compiled) — it failed against the wrong schema and passed once
  corrected; `StringCatalog.isPluralVariant` and its test fixture were fixed to match. 16
  plural-variation keys now exist (`%lld note`, `%lld document`, `%lld canvas` →
  `%lld canvases`, `%lld journal entry` → `%lld journal entries`, etc., plus full-sentence keys
  like `Conflict on %lld note` and `Synced — %lld note %@`). `translate-strings --dry-run`
  confirms all 16 are correctly excluded from the flat per-locale translation loop (177 of 193
  keys would translate). Full `NoteBytezTests`: 819/819 (the 815 prior + 4 new
  `PluralCatalogTests`), excluding the same pre-existing `ConflictStoreTests` timing flake noted
  in Phase 1, reconfirmed passing in isolation.
- [x] **2.4** Interpolation → positional specifiers where order may vary. Swept the full
  catalog for keys with more than one substitution: exactly one exists,
  `"Synced — %lld note %@"` (count + received/updated verb, from `SyncStatusStore`). Its two
  plural-category values now read `"Synced — %1$lld note %2$@"` / `"Synced — %1$lld notes %2$@"`
  — identical rendering for `en` (order was already correct), but a translator can now freely
  reorder the two positions without breaking argument binding. Confirmed no regression via
  `PluralCatalogTests`.
- [x] **2.5** `OSLog`/logging strings, URL schemes, and frontmatter keys were never routed
  through `Text`/`String(localized:)` anywhere in this phase's edits, so nothing to revert
  there. Auditing `ExportDAL.swift` for this task surfaced a **real, previously-undiscovered
  bug** of Phase 1's own class (G17/G18) that Phase 1 didn't happen to cover (`ExportDAL` wasn't
  in its audited DAL list): `kebabCase(_:)`, which builds the synthetic `#notebook/<kebab>` tag,
  used plain `.lowercased()` — locale-*dependent* — instead of
  `TextNormalization.invariantLowercased`, so a Turkish-locale device would fold a notebook
  named e.g. "Ideas" to `#notebook/ıdeas` (dotless ı) instead of `#notebook/ideas`, silently
  desyncing the tag from the same notebook exported on any other device. Fixed to route through
  the existing Phase 1 helper. New `NoteBytezTests/ExportDALTests.swift` cases:
  `exportableContentKeepsTheLiteralFrontmatterKeyAndTagRegardlessOfNotebookName` (a diacritic
  notebook name keeps `notebooks:`/`#notebook/` literal and produces the expected
  diacritic-folded tag) and `syntheticTagKebabCasingUsesInvariantLowercasingForTurkishDottedI`
  (pins the exact invariant-locale output for a Turkish dotted capital I). Documented honestly:
  a unit test can't actually flip the process's `Locale.current` to Turkish, so this proves the
  code routes through the invariant helper and pins its exact output — it can't reproduce the
  old bug's divergence on an English-locale test host, the same limitation Phase 1 already had
  for its own two locale-invariant `DateFormatter` fixes.
- [x] **2.6** Ran `Scripts/run-pseudolocalized.sh double-length` and `rtl` against a real
  simulator over R3's key-screen subset (S1 Library Selection, S3 Today, S7 Search, Settings,
  Notebook Browser) rather than all 24 — the full 24-screen sweep is R3's own dedicated
  screenshot-harness job (Phase 7.3), and would just duplicate that work here without its
  reviewable artifact. This pass's actual value turned out to be **catching hardcoded strings**
  more than layout breaks, exactly as its own doc description promises — and it caught a lot:
  - `PrimaryButton`/`SecondaryButton` (`views/Components/`) — shared button components whose
    `title: String` fed `Text(title)` (verbatim), so **every one of their 10 call sites**
    ("Create New Library", "Cancel", "Restore", etc.) silently never localized. Fixed by
    rendering `Text(LocalizedStringKey(title))` while keeping `title: String` itself untouched —
    ~30 `NoteBytezUITests` assertions key off `"primaryButton.\(title)"` accessibility
    identifiers, which a naive `LocalizedStringKey`-typed parameter would have broken.
  - `GraphInsightRow`/`SearchResultRow`'s `title.isEmpty ? "Untitled" : title` and
    `ConflictVersionCard`'s `revision.snippet.isEmpty ? "(empty)" : revision.snippet` — the same
    literal-vs-variable ternary bug fixed repeatedly in 2.1, just not caught then because the
    lint only checks `.navigationTitle`/`.accessibilityLabel`, not arbitrary `Text(...)` calls.
  - `ConflictStrategy.title`/`.summary` (`sync/ConflictStrategyStore.swift`) — S11's three
    strategy names/descriptions were plain hardcoded `String` properties, never routed through
    `String(localized:)` at all.
  - `GraphInsightsView.swift` (Insights screen) — reached via code review once the pattern
    above kept recurring in this file's neighborhood, not from a screenshot: `InsightSectionHeader`'s
    `title`/`description` (both changed `String` → `LocalizedStringKey`, fixing 5 call sites:
    "Orphans", "Stale", "Notes with Open Tasks", "Hubs", "Clusters"), `emptyState(_:)` (`String` →
    `LocalizedStringKey`, fixing 5 more), and three `row(for:detail:...)` call sites building a
    hardcoded English `detail` string by hand (`"Unconnected"`, `"\(count) open"`,
    `"\(degree) links"` — the last two converted via `String(localized:)`, reusing this phase's
    existing `%lld link` plural key from `MigrationAssistantView`). The cluster `DisclosureGroup`
    title had the same `?? "Untitled"` bug nested inside a literal interpolation, plus its own
    unlocalized "notes" pluralization — pulled into a new `clusterDisclosureTitle(for:)` helper
    built the same way as this phase's other `String(localized:)` compositions.
  - **Two genuinely low-risk, system-level findings, left as-is rather than "fixed"**: the
    5-item `TabView` tab-bar labels and `ContentUnavailableView`'s title both truncate under
    `-NSDoubleLocalizedStrings`' worst-case 2x-length doubling (e.g. "Today Today", "No
    Notebooks Yet No No…"). Both are stock, unmodified system components enforcing short
    single-line labels by design (`UITabBar`, `ContentUnavailableView`'s documented usage
    pattern) — not app layout code with a fixable bug. Real translations typically run 20–50%
    longer, not 100%, so the actual risk is lower than this synthetic stress suggests; the real
    test is R3's per-locale screenshot review once Phase 6+ ships actual translations, not a
    redesign of the navigation shell speculatively now.
  - RTL: spot-checked Library Selection and Today — layout, tab-bar order, chevron direction,
    and icon/text ordering all mirror correctly throughout, confirming semantic
    `.leading`/`.trailing` (not hardcoded `.left`/`.right`) is used consistently.
  Re-ran `Scripts/lint-hardcoded-strings.sh --update-baseline` (40 reviewed exceptions) and the
  extraction tool (206 clean keys, 0 policy violations) after these fixes; full `xcodebuild
  build` and `NoteBytezTests` (819/821, same pre-existing `ConflictStoreTests` flake) both
  verified green.
- [x] **2.7** New `NoteBytezUITests/Phase2PseudolocalizationTests.swift`: launches with
  `-NSDoubleLocalizedStrings YES` (the same flag `run-pseudolocalized.sh double-length` uses),
  walks Today/Notebooks/Search/Settings, and regex-asserts no visible `staticTexts`/`buttons`
  label contains a raw, unresolved format specifier (`%@`, `%lld`, `%1$@`, `%#@name@`) — the
  shape a broken catalog lookup or malformed positional specifier would leak. Verified the
  regex has no false-positive risk by confirming no catalog key contains a literal `%` outside
  a real specifier. Writing this test surfaced a **pre-existing UI-test-infrastructure gap**
  unrelated to 2.6's production-code findings: `LibrarySelectionScreen.createLibrary(named:)` —
  used by `NoteBytezUITestCase.launchAndCreateLibrary`, and so indirectly by the large majority
  of this suite's ~30 files — looked up the library-name field by `app.textFields["Library
  Name"]`, i.e. by its *placeholder text*, which is exactly what pseudolocalization (and,
  eventually, real translation) changes. Fixed by adding a stable
  `.accessibilityIdentifier("newLibrary.nameField")` to the `TextField` in
  `LibrarySelectionView.swift` and updating both of its call sites
  (`LibraryScreens.swift`, `NoteBytezUITests.swift`) to key off that identifier instead —
  the same "identifier survives localization" principle already used for
  `primaryButton.\(title)` and `tabbar.\(destination)`. Confirmed via a representative subset
  (`NoteBytezUITests`, `Phase1MainShellSmokeTests`, `Phase5AccessibilityTests` — 10 tests, all
  of which flow through the shared helper) that this didn't regress anything; a full sweep of
  every remaining screen-object property for the same `app.button(labeled:)`/
  `app.navigationBars["English text"]` brittleness is out of this phase's scope (would mean
  retrofitting nearly every file under `NoteBytezUITests/Screens/`) and is noted here as a
  known, pre-existing limitation for whoever picks up Phase 6+'s first real (non-pseudo)
  locale — most of the suite will need equivalent identifier-based fixes before it can run
  against a translated build. Full `NoteBytezTests`: 819/821 (same pre-existing
  `ConflictStoreTests` flake). `Scripts/lint-hardcoded-strings.sh`: clean, no new offenders.
  Catalog re-extracted: 206 keys, 0 policy violations.

---

## Phase 3 — Package String Audit

- [x] **3.1** Grepped `../MarkdownG9` and `../SwiftRpt` (`SwiftRPT`'s actual on-disk casing) for
  `Text`/`Label`/`Button` literals, `LocalizedError`/`errorDescription`, and formatter/chart
  output strings. Findings:
  - **`MarkdownG9`** has exactly 2 hardcoded English UI strings: `MarkdownG9.swift`'s toggle
    button (`Text(isEditing ? "Preview" : "Edit")`) and `MDEditorView.swift`'s `Button("Done")`.
    Both live in the package's bundled `MarkdownG9` SwiftUI view (editor/preview toggle +
    keyboard-dismiss bar) — **not** in `MDProcessor`, the pure-function Markdown-to-
    `AttributedString` converter. Traced every call site in `NoteBytez/` (`grep -rl
    "MarkdownG9\|MDProcessor\|MDEditorView\|MDPreviewView"`): all eight hits
    (`DocumentView.swift`, `DocumentPreviewView.swift`, `TemplatePackPreviewView.swift`,
    `BlockReferenceText.swift`, `WikilinkText.swift`, plus three DAL files whose comments only
    reference `MDProcessor`'s regex patterns) call `MDProcessor.process(_:)` directly.
    `DocumentView.swift`'s own doc comment confirms this is deliberate: "Uses a bespoke
    editor/preview toggle instead of MarkdownG9's bundled `MarkdownG9` view." So the 2 strings
    exist in the package but are dead code from NoteBytez's integration boundary — never
    instantiated, never rendered. `MDProcessor.process(_:)` itself injects no English words into
    its output: its block-prefix/rule glyphs (`"• "`, `"│ "`, the ordinal `"\(ordinal). "`, the
    40-`─`-character horizontal rule, the `"🖼 "` image-caption glyph) are structural punctuation,
    not translatable text — same category as `DoNotTranslate.md`'s existing non-localized
    register.
  - **`SwiftRpt`** is not a dependency of this project at all — confirmed via
    `grep -rn "Rpt\|RPT" NoteBytez.xcodeproj/project.pbxproj` (zero hits; only `MarkdownG9` has an
    `XCLocalSwiftPackageReference`) and `grep -rln "import SwiftRpt" NoteBytez/` (zero hits).
    `ARCHITECTURE.md`'s "Report Generation: local Swift Package 'SwiftRPT' … extend as needed to
    meet identified feature requirements" describes planned/available tech, not a current
    integration — accurate as written, not a doc bug. Audited its source anyway for future
    relevance: no `LocalizedError`/`errorDescription` anywhere (`OOXMLPackageError` is a plain
    `Error` enum, thrown to Swift callers, never surfaced as UI text); the one real find is that
    every `SwiftRptCharts` chart type (`BarGraph`, `LineGraph`, `PieChart`, `BoxPlot`,
    `GanttChart`, `Histogram`, `AreaChart`, `ScatterPlot`, `StackedBarChart`, `TimeSeriesGraph`)
    hardcodes its Swift Charts `PlottableValue.value(_:_:)` axis/series labels in English
    (`"Category"`, `"Value"`, `"Series"`, `"Date"`, `"Bin"`, `"Count"`, `"Task"`, `"Start"`,
    `"End"`, `"Slice"`, `"Minimum"`, `"Maximum"`, `"Lower Quartile"`, `"Upper Quartile"`,
    `"Median"`) — Swift Charts surfaces these in auto-generated VoiceOver accessibility
    descriptions regardless of the labels' own `.chartLegend`/axis visibility. `PageNumberXML`
    takes its `"Page {current} of {total}"`-shaped template as a caller-supplied parameter, not a
    package literal, so it carries no hardcoded string of its own.
  - **Net for this app's shipped UI: zero reachable hardcoded strings.** Nothing in either
    package's actually-integrated surface (`MDProcessor.process(_:)`; nothing at all for
    `SwiftRpt`) renders English text into NoteBytez today.
- [x] **3.2** N/A — nothing found on the actual integration boundary to externalize (see 3.1).
  Not adding a String Catalog to either package speculatively: `MarkdownG9`'s 2 strings sit in a
  shared, multi-app package's unused view (this app doesn't need it, and localizing dead code
  the app never instantiates provides no verifiable behavior change here); `SwiftRpt` isn't a
  build dependency of NoteBytez at all yet, so writing a translation pipeline for it now would be
  speculative work for a feature that doesn't exist in this app. **Flagged, not fixed**, per
  `CLAUDE.md` §3: if/when `SwiftRpt` is wired in for a real report-generation feature, or
  `MarkdownG9`'s bundled view is ever adopted, its chart-label/button strings need the same
  String Catalog treatment as Phase 2 — revisit at that time rather than now.
- [x] **3.3** Recorded here (3.1 above) and in `ARCHITECTURE.md` §Related Docs: "packages are
  UI-string-free at NoteBytez's actual integration boundary — `MarkdownG9`'s 2 hardcoded strings
  and `SwiftRpt`'s chart-label strings exist in package source but are unreachable from this
  app's shipped code today; see Phase 3 of this doc for the full audit."

---

## Phase 4 — Seed-Content Localization at Creation Time

Decision G2. Seed content is emitted in the device language when the library is created, then
becomes plain user data.

- [x] **4.1 Failing tests first.** Wrote them against `TemplatePackDALTests`, `TemplateDALTests`,
  `LibraryDALTests`, `JournalDALTests` before any production change — all failed for the right
  reason (`locale:` parameter didn't exist yet / group names were always English). Verified
  failing, then made green (see 4.2). Coverage matches the doc's own list exactly: `LibraryDAL.create`
  under `es` seeds Spanish `TemplateGroup`/field names, `en` is byte-identical to the
  pre-Phase-4 baseline, a second `seedStarterContent` call under a *different* locale doesn't
  retranslate the first call's rows, and `JournalDAL.template(for:)` was audited (see 4.2 note
  below — it needed a locked-in regression test, not a code change).
- [x] **4.2** Real, hand-authored Spanish and German translations (not machine output — no
  `ANTHROPIC_API_KEY` is configured in this environment, and 4.5's own manual-verification step
  needs concrete non-English strings to check against) added to `Localizable.xcstrings` for the
  3 starter packs' `displayName`, template `name`s, field `name`s, and non-empty `.text`-type
  field `defaultValue`s (e.g. Scene's `Status` default "Drafting"/"Borrador"/"Entwurf`), plus all
  9 body-template scaffolds as whole-block translations (one catalog key per full Markdown
  block, matching how the app already treats a body template as an atomic unit). 41 new keys
  total; the pre-existing "Status" key (Settings' subscription-status header) picked up `es`/`de`
  values too and now doubles as the Scene/Client status field name — same word, same
  translation, one catalog entry, per the project's existing key-sharing convention.
  `TemplatePackDAL.addPack` (which `TemplateDAL.seedStarterContent` calls per starter pack, and
  which the Template Gallery's manual "add pack" also shares) now resolves `displayName`,
  template names, field names, and `.text`-type field defaults through a new
  `localizedSeedString(_:locale:)` helper *before* constructing each `TemplateGroup`/`NoteTemplate`
  row — not literally inside `seedStarterContent` itself as the doc's own wording suggested,
  since `addPack` is the actual point where pack literals become rows; `seedStarterContent`
  only threads a new `locale: Locale = .current` parameter down to it. A `.checkbox`/`.date`/
  `.number` field's `defaultValue` (e.g. `Alive`'s `"true"`) is deliberately **never** localized —
  it's a canonical machine-readable token stored the same register as a frontmatter boolean, not
  a word (the field's own *name* is still localized). `LibraryDAL.create` and
  `TemplateDAL.seedStarterContent` both gained the same `locale: Locale = .current` parameter,
  defaulting to today's behavior for every existing call site (Phase 5 is what will eventually
  vary it from the UI). Gallery's other 17 packs go through the identical code path with zero
  catalog entries of their own today — `String(localized:)` simply falls back to the English
  source, so this is a no-op for them until a later rollout phase adds their translations.
  **`JournalDAL.template(for:)` needed no change**: it returns the literal `"- "` — a bullet
  glyph and a space, no English word — so it was already locale-invariant; pinned that finding
  with a regression test (`templateForDateIsLocaleInvariantBecauseItCarriesNoWords`) rather than
  leaving it undocumented. **A real, load-bearing empirical correction happened here**, the same
  kind Phase 2.3 hit with plural variations: this doc's own wording (and my first implementation)
  assumed `String(localized:locale:)`'s `locale:` parameter changes which `.lproj` table is
  consulted. A diagnostic test against the real compiled catalog proved it does not — passing an
  explicit `locale:` to `String(localized:)` still resolved to the device's own current-locale
  table regardless of the argument. Only `LocalizedStringResource(_:locale:)` (then
  `String(localized: resource)`) actually honors an explicit locale override; `localizedSeedString`
  was rewritten to go through it. Caught only because a test asserted the actual returned string
  value under an explicit non-device locale, not just that the code compiled — this is exactly
  the first place in the whole project resolving a *non-source* locale, so nothing before this
  phase could have surfaced it. Written up durably (not just here) at
  [Docs/Localization/TechnicalNotes.md](../Localization/TechnicalNotes.md), cross-referenced from
  `ARCHITECTURE.md`, so it isn't re-discovered by whoever writes Phase 5's language-override code
  or Phase 11's RTL-pinned test infra next. This phase's `TemplatePackDAL.addPack` work also
  turned out to satisfy [NoteBytez20260824v1-Templates.md](NoteBytez20260824v1-Templates.md)'s
  own Phase 6.3/6.4 (that doc's "Localization wiring" phase planned the identical add-time
  resolution mechanism independently) — reconciled there rather than left as two documents
  quietly describing the same code differently.
- [x] **4.3** Confirmed directly: `NoteTemplateField`/`TemplateGroup.name`/`NoteTemplate.name`/
  `bodyTemplate` are plain `String`/`String?` SwiftData properties, never a catalog key — once
  `localizedSeedString` resolves a value and it's handed to `TemplateGroup(name:)`/
  `TemplateDAL.createTemplate(name:...)`, the resolved literal is what's persisted. Locked in by
  `seedStarterContentIsIdempotentEvenWhenTheSecondCallUsesADifferentLocale`: seeding under `es`
  then calling `seedStarterContent` again under `de` leaves the original Spanish names
  untouched (the idempotency guard in `seedStarterContent` — "a library that already has any
  `TemplateGroup` is left untouched" — runs before any localization would even happen on a second
  call, so there's no path back to English or German for already-seeded data).
- [x] **4.4** Found and fixed a real, previously-undiscovered instance of the exact bug class
  Phase 2.1/2.6 already fixed elsewhere: `LibrarySelectionView`'s
  `Text(library.name ?? "Untitled Library")` — since `library.name ?? "..."` is statically typed
  `String`, this bound to `Text`'s *verbatim* initializer, so `"Untitled Library"` could never
  have localized even once real translations exist, exactly like the `?? "fallback"` cases Phase
  2.1 already converted elsewhere in this same file's neighborhood. Missed then because Phase
  2.1's lint only flags `.navigationTitle`/`.accessibilityLabel`, not arbitrary `Text(...)` calls
  (documented as a known gap in Phase 2.6/2.7). Fixed with the same established idiom:
  `library.name.map(Text.init) ?? Text("Untitled Library")` — the user's own library name stays
  verbatim data, the structural fallback is now a real (English-only today) catalog key. Added
  to `Localizable.xcstrings` as a plain Phase-2-style UI string.
- [x] **4.5** All 11 new tests green (`TemplatePackDALTests` ×5, `TemplateDALTests` ×3,
  `LibraryDALTests` ×2, `JournalDALTests` ×1), full `NoteBytezTests` (831 tests) green except the
  same pre-existing `ConflictStoreTests` timing flake documented in Phases 1/2 (reconfirmed
  passing in isolation, unrelated to this phase), full `xcodebuild build` green. **Manual
  verification performed on the booted `iPhone 17 Pro` simulator** (`xcrun simctl launch
  com.kwicksync.NoteBytez -AppleLanguages "(de)" -AppleLocale "de_DE"`, matching Phase 1.8's
  precedent): created a library through the real UI, then confirmed via Settings → Templates →
  each group that every level renders in German — groups **Fotografie-Kundenarbeit**,
  **Hochzeitsplanung**, **Romanschreiben**; `Romanschreiben`'s templates **Figur**,
  **Schauplatz**, **Szene**; `Figur`'s fields **Spezies**, **Heimatwelt**, **Zugehörigkeit**,
  **Status**, **Lebendig** (the last a `.checkbox` field — its *name* localized, its stored
  `"true"` value untouched, confirmed via the equivalent unit test rather than this screen, which
  doesn't surface raw default values). Also incidentally confirmed `Sonntag, 13. September 2026`
  on the Today screen — Phase 1.6's locale-aware date formatting, still correct. **Did not**
  re-verify "switch to `en`, confirm groups stay German" live in the simulator: this Debug build's
  `ModelConfiguration` is `isStoredInMemoryOnly: true` unless launched with `-EnableLiveSync`
  (`NoteBytezApp.swift`), so terminating and relaunching under a different locale — the only way
  to change `AppleLanguages` — also wipes the in-memory store, making that exact manual sequence
  impossible without invoking this app's separate live-CloudKit-sync test setup (the
  Kontinuum1/Kontinuum2 simulator accounts from the unrelated live-sync-testing effort), which
  this phase had no reason to disturb. That persistence-across-a-later-locale-change guarantee is
  instead proven by 4.3's idempotency test, which exercises the identical code path within one
  `ModelContext` and is a strictly more precise check than a UI click-through would have been.

---

## Phase 5 — In-App Language Override (Settings row *and* first-launch prompt)

Decision G4 / G4a / G4b / SF4.

- [x] **5.1 Failing tests first.** `LocalePreferenceStoreTests` (7 tests) and `SupportedLocalesTests`
  (4 tests) written and confirmed failing before the store/registry existed. No dedicated
  `SettingsViewModel` exists in this codebase (Settings sub-screens, e.g.
  `ConflictStrategySettingsView`, read/write their store directly with no view-model layer) —
  matched that existing convention rather than inventing one. **A real, load-bearing discovery
  while writing these tests**: `AppleLanguages` lives in `NSGlobalDomain`, which every
  `UserDefaults` instance — including a brand-new `UserDefaults(suiteName:)` test suite —
  consults as a read fallback. A "fresh" test suite's `array(forKey: "AppleLanguages")` came back
  as the simulator's own ambient language, not `nil`, making "nothing stored" indistinguishable
  from "the device happens to already be English" — in both the test *and* the real Settings UI,
  which would otherwise show a language as explicitly selected that the user never picked. Fixed
  by giving `LocalePreferenceStore` its own private `preferredLanguageCode` key as the source of
  truth (see 5.2) rather than reading `AppleLanguages` back directly.
- [x] **5.2** `NoteBytez/dal/LocalePreferenceStore.swift` (UserDefaults, mirrors
  `ConflictStrategyStore`/`TemplateOnboardingStore`). `preferredLanguageCode(in:)` reads a
  private key (see 5.1's discovery); `setPreferredLanguageCode(_:in:)` writes that key **and**
  applies the real `AppleLanguages` key iOS reads at launch (one-element array, or removed
  entirely for `nil`/"System default" — not left as `[]`). `hasPromptedForLanguage`/
  `markPromptedForLanguage` alongside, exactly mirroring `TemplateOnboardingStore`'s
  boolean-flag shape.
- [x] **5.3** `NoteBytez/models/SupportedLocales.swift` — `SupportedLocale { id, endonym }` +
  `SupportedLocales.all`, starting with exactly one entry (`en-US`, "English (United States)"),
  per the decision. `matchingDevice(languageCode:)` matches by language subtag only (`"de"` from
  `"de-AT"`), falling back to the first entry — never offers a locale not in `all`.
- [x] **5.4** `NoteBytez/views/Language/FirstLaunchLanguagePromptView.swift`. `RootView.body` now
  branches on a new `shouldShowLanguagePrompt` (`!didConfirmLanguage &&
  !LocalePreferenceStore.hasPromptedForLanguage()`) *before* constructing
  `EntitlementGateContainer` at all — confirmed via a UI test that the entitlement gate (paywall)
  genuinely does not render until the prompt is confirmed, not just that the prompt appears
  first cosmetically. Confirming calls `setPreferredLanguageCode`/`markPromptedForLanguage`, then
  a `didConfirmLanguage` callback (same `@State` + `onFinished`-callback shape `RootView` already
  uses for `RoleOnboardingView`) switches away from the prompt with no restart, since nothing
  else has rendered yet to hold a stale value.
- [x] **5.5** `NoteBytez/views/Language/LanguageSettingsView.swift`, reached from a new
  `SettingsView` → "Language" row. "System Default" + `SupportedLocales.all`, checkmark-style
  rows (not `SettingsRadioRow` — that component's always-visible description line is for S11's
  "trust-critical decision" framing, which doesn't apply to a language's own name), footer
  caption "Changes take effect after restart." **A real bug caught before it shipped**: an early
  draft of this view's row helper took `title: String` so it could serve both "System Default"
  (should localize) and an endonym like "Deutsch" (must never re-localize — a language's name
  for itself is invariant) — exactly Phase 2.1's `Text(String)`-is-verbatim bug, just
  rediscovered here. Fixed the same way Phase 2.1 did: the helper takes a pre-built `Text`, so
  the call site chooses `Text("System Default")` (localizable) vs. `Text(locale.endonym)`
  (verbatim) explicitly.
- [x] **5.6** `LocalePreferenceStore.reapplyPreferredLanguage()`, called first thing in
  `NoteBytezApp.init()`, re-writes whatever is already stored back into `AppleLanguages` before
  the `ModelContainer`/`WindowGroup` are built. Documented honestly as a defensive no-op against
  a preferences-flush race between a Settings change and a subsequent cold launch, not as new
  behavior — this can't be verified by a test (it's about disk-flush timing across process
  launches, not in-process state). iOS's own per-app Language setting interaction: both
  mechanisms write the same `AppleLanguages` key, so whichever wrote it more recently is what's
  in effect — documented on the store and in `LanguageSettingsView`'s footer; there is no public
  API to detect iOS's own per-app setting separately, so no attempt was made to special-case it.
- [x] **5.7** `-SkipLanguagePrompt` (DEBUG-only, mirrors `-SeedTestConflict`'s launch-argument
  seam) marks `hasPromptedForLanguage` at launch. The actual blast radius was much smaller than
  "touches every one of the ~30 UI test files" suggested: only `NoteBytezUITestCase` needed a
  change (`launchAndCreateLibrary` and a new shared `launch(extraArguments:)` both inject the
  flag by default) — the 20 test files that subclass it all inherit the fix automatically. Two
  standalone `XCTestCase` files that predate `NoteBytezUITestCase` (`NoteBytezUITests.swift`,
  `NoteBytezUITestsLaunchTests.swift`) and three files that bypassed the shared helper to launch
  with their own extra arguments directly (`Phase6EntitlementGateTests`,
  `Phase1ConflictResolutionSmokeTests`, `Phase1ImportMigrationEntryPointSmokeTests`) needed their
  own fix — found by grepping for every `.launch(`/`XCUIApplication()` call site in
  `NoteBytezUITests`, not by guessing. Also added `-ResetLanguagePreference` (DEBUG-only): a test
  that specifically exercises the *un-skipped* first-launch prompt needs a way to force a clean
  slate, since `LocalePreferenceStore` persists to `UserDefaults.standard` across launches on the
  same simulator exactly like `ConflictStrategyStore` already does (`Phase1ConflictResolutionSmokeTests`'s
  own comment on that quirk was the tip-off).
- [x] **5.8** `NoteBytezUITests/Phase5LanguagePromptTests.swift`. (a)
  `testFirstLaunchPromptPrecedesTheEntitlementGateAndIsNotShownAgainAfterConfirming` — launched
  un-skipped with `-ResetLanguagePreference -SimulateEntitlement neverSubscribed`: the language
  option exists and the paywall does not; confirming makes the paywall appear and the prompt
  disappear; terminating and relaunching (with `-ResetLanguagePreference` dropped this time, since
  `launchArguments` itself persists across `.launch()` calls on the same `XCUIApplication`) lands
  straight on the paywall again, proving "shown exactly once." **(b) adapted, not skipped**:
  `SupportedLocales` ships only `en-US` today (5.3), so the plan's literal "override to `fr`,
  confirm it renders French" can't be tested without offering a locale with zero real
  translations — precisely what G4b says never to do. `testSettingsLanguageOverridePersistsAcrossARestart`
  instead proves the mechanism with the one locale that exists: select "System Default" (a known
  baseline — `LocalePreferenceStore` persists across tests on the same simulator, same quirk
  `Phase1ConflictResolutionSmokeTests` already documents), then "English (United States)",
  confirm the checkmark moves, terminate and relaunch (recreating the library, since the Debug
  in-memory SwiftData store doesn't survive a restart the way `UserDefaults` does), and confirm
  the checkmark is still on English — the explicit choice survived a real process restart, not
  just in-memory `@State`. Revisit once Phase 7 ships a second real locale to add the "visibly
  renders in a different language" assertion 5.8(b)'s original wording anticipates. (c) Full
  `NoteBytezTests` (842, up from 831 — the 11 new tests from 5.1) green except the same
  pre-existing `ConflictStoreTests` timing flake documented since Phase 1. UI regression pass:
  `NoteBytezUITests`, `Phase6EntitlementGateTests`, `Phase1ConflictResolutionSmokeTests`,
  `Phase1ImportMigrationEntryPointSmokeTests`, `Phase2PseudolocalizationTests` (14 tests spanning
  every launch path touched by 5.7, including the 3 that bypass the shared helper) — one
  (`testAddAttachmentEntryPointOpensSystemPicker`) flaked under full-run load and passed cleanly
  in isolation, the same pre-existing-flake pattern as `ConflictStoreTests`, not a regression.
  Manually verified on the booted iPhone 17 Pro simulator: the first-launch prompt renders
  correctly and transitions cleanly to S1 on confirm.

---

## Phase 6 — Language Rollout Phase 1: `en-US` (baseline)

No translation task — `en-US` is the development locale developers already write in (R6).

- [x] **6.1** `en-US` was already added to `SupportedLocales` (5.3) as its only/first entry when
  that registry was built in Phase 5 — nothing new to do there. Verified "100% populated" against
  the actual **compiled** catalog, not just the source `.xcstrings` JSON (the standard this
  project holds itself to since Phase 4's `LocalizedStringResource` discovery): built the app,
  then inspected `NoteBytez.app/en.lproj/Localizable.strings` (237 entries) and
  `Localizable.stringsdict` (16 plural entries) via `plutil -convert json` — 253 total, matching
  the source catalog's key count exactly, zero empty values. 195 of the 253 source keys carry no
  `localizations` block at all (Phase 0–2's ordinary UI strings — the key *is* the English value,
  Apple's own String Catalog convention) and 42 (Phase 4's starter-pack seed content) have `es`/
  `de` entries but no explicit `en` override — both fall back to resolving as their own key text,
  confirmed correct and non-empty in the compiled output for a representative sample
  (`Address`, `Character`, `Status`). Only the remaining 16 (plural variants) carry an explicit
  `en` value, since a plural key can't be its own fallback for every count category. No code
  change — a verification-only phase, exactly as documented.

---

## Phase 7 — Language Rollout Phase 2: Major Western European

Locales: `en-GB`, `es`, `fr`, `de`, `it`, `pt-BR`. LTR, well supported by system fonts, largest
combined market.

- [x] **7.1** `translate-strings --locale es,fr,de,it,pt-BR,en-GB` could not run for real: the
  configured `ANTHROPIC_API_KEY`'s account has **no credit balance** (confirmed via a direct
  `curl` against `api.anthropic.com` — "Your credit balance is too low to access the Anthropic
  API," not an auth error), so every one of the ~1,300 calls this locale set needs would have
  failed identically. Per the user's explicit choice, translations were **hand-authored**
  instead — same approach Phase 4 already used for its 3 starter-pack keys, just at full-catalog
  scale. All 237 non-plural + 16 plural (×one/other) keys existing at the time were translated
  for `es`/`fr`/`de`/`it`/`pt-BR` (skipping the ~42 keys Phase 4 already gave real `es`/`de`
  values, translating only the other 3 locales for those); written directly into
  `Localizable.xcstrings` via a script mirroring Phase 4's merge approach, each entry marked
  `"state": "translated"` so a future real `translate-strings` run will skip them rather than
  overwrite hand-authored work. `git diff`-reviewable; no `.xcstrings` commit made by this phase
  itself (commits are the user's own call per this repo's standing instructions).
- [x] **7.2** Placeholder-safety verified directly (a script comparing every source/translation
  pair's `%@`/`%lld`/`%1$lld`-style token multiset — zero mismatches across all 253 original
  keys × 5 locales, then re-verified after 7.3's additions) since no live `translate-strings` run
  happened to exercise its own built-in check. Drift report **clean for all 5** real-translation
  locales (`swift run translate-strings --report --locale es,fr,de,it,pt-BR` → "clean (no
  missing/stale keys)" for each, at both the 253-key and final 339-key catalog size). `en-GB`
  reports 100% "missing" by the tool's own design — expected and correct, not a defect: G7 treats
  a missing `en-GB` entry as "inherits en-US," and 7.5 below confirms that's genuinely true today
  (zero divergences exist), not merely untested.
- [x] **7.3** Screenshot review (booted iPhone 17 Pro simulator, `es`/`de`) over S1, Settings,
  Today, and the Explore hub found real, currently-shipping localization bugs — not just
  translation gaps — and fixed them:
  - **66 catalog keys that never existed at all**, because the strings live behind SwiftUI
    initializers `StringExtractor` doesn't scan (`ContentUnavailableView`, `PrimaryButton`/
    `SecondaryButton` (custom components), `TextField`, `Toggle`, `Picker`, `Menu`,
    `confirmationDialog`, `.alert`, `InsightSectionHeader`) — found by grepping every such
    call site for a literal argument and diffing against the catalog, not by clicking through
    every screen by hand. 27 + 39 = 66 keys added with `es`/`fr`/`de`/`it`/`pt-BR` values
    (`"https://example.com"` and the app name `"NoteBytez"` deliberately excluded — both are
    correct to leave un-keyed per `DoNotTranslate.md`).
  - **A real `Text(String)`-verbatim bug** (Phase 2.1's own bug class, recurring): `Text(isEditing
    ? "Preview" : "Edit")` in `TodayJournalView.swift`/`DocumentView.swift` — the ternary
    evaluates to a plain `String` *before* `Text` sees it, so it bound to the verbatim
    initializer and could never localize in any language, in any phase, until now. Fixed to
    `isEditing ? Text("Preview") : Text("Edit")`. A similar case with string interpolation
    (`MigrationAssistantView.swift`'s auto-detected-format caption) fixed via
    `String(localized:)` per branch instead, since the interpolated segment (`format.displayName`,
    itself a proper noun — "Obsidian"/"Logseq" — correctly never localized) doesn't fit the
    two-`Text` split.
  - **`ExploreHubView.swift`** used `destination.rawValue` (plain `String`, structural/never-
    localize by design) instead of the `displayName: LocalizedStringKey` computed property Phase
    2.1 built for exactly this purpose — so Graph/Insights/Tasks/Saved Views/Tags never
    localized on iPhone's Explore tab despite `ContentView.swift`'s own 10 sidebar call sites
    already doing this correctly. Two call sites fixed to use `displayName`.
  - **`FilterChipRow<Scope>.swift`** (the generic chip component behind Search's scope filter
    *and* the Task Dashboard's status/date filters) had `Button(scope.rawValue)` — same verbatim-
    String bug, silently breaking three screens' filter chips at once from one shared component.
    Fixed to `Button(LocalizedStringKey(scope.rawValue))`; added catalog entries for all 9
    chip values across the three enums (`Content`/`Tag`/`Path`, `Open`/`All`, `Any`/`Overdue`/
    `Due Today`/`Due This Week`).
  - Same bug, smaller blast radius: `PropertyValueType` display labels
    (`NoteTemplateFieldsView.swift` ×2, `DocumentView.swift` ×1 — the field-type `Picker`s'
    options) and `GraphMode.title` (`GraphView.swift`'s layout-mode `Picker`). Fixed the same way;
    added `Text`/`Number`/`Date`/`Checkbox`/`List`/`Radial`/`Force` to the catalog.
  - **Flagged, not fixed**: the identical bug pattern also appears in
    `TemplatePackPreviewView.swift`, `TemplateGalleryView.swift`, and `RoleOnboardingView.swift`
    (Template Gallery preview/list and the first-run role picker) — lower priority (not core
    "key screens," and some depend on `pack.summary`/`category` text that has no translations
    yet regardless of the code fix), spun off as a background task
    (`task_97baa568`) rather than chased here.
  - Total: 66 + 4 + 16 = **86 new catalog keys** this phase beyond the initial 253-key
    translation pass (final size: 339). Rebuilt and re-verified (build, lint, full
    `NoteBytezTests`, drift report) after each batch, not just once at the end.
- [x] **7.4** Glossary conformance spot-check: `Backlink`/`Wikilink`/`Canvas`/`Block reference`
  kept as English loanwords in all 5 locales per `Glossary.md`'s `loanword` directive (confirmed
  live on-device: the Explore hub's `Canvas` row stays `"Canvas"` under `es`, everything around
  it translates). `translate`-directive terms (Library→biblioteca/bibliothèque/Bibliothek/
  biblioteca/biblioteca, Notebook, Journal, Tag→etiqueta/étiquette/Schlagwort/tag/tag, Template,
  Saved View, Promote, Command Palette, Insights) rendered in each language's own vocabulary
  consistently across every occurrence (shared catalog keys make this automatic, not a
  per-occurrence judgment call).
- [x] **7.5** `en-GB` diff review: a systematic scan of every one of the 253+66 source strings for
  the common US/UK divergence patterns (-ize/-ise, -or/-our, -er/-re, `canceled`/`cancelled`,
  `color`/`colour`, `program`/`programme`, etc.) found **zero genuine divergences** — one
  incidental hit (the App Store subscription-disclosure string already reads "...unless
  **cancelled** at least 24 hours...", the double-L/British spelling, in the nominally `en-US`
  source text) doesn't need an `en-GB` override *because* it's already spelled the British way;
  it's arguably a latent `en-US` inconsistency instead, noted here rather than silently fixed
  (changing the source string is a Swift-source edit for a one-word cosmetic nit, out of this
  phase's scope). Net result: `en-GB` carries **zero catalog overrides** and inherits 100% of
  `en-US` — confirmed by the compiled build (`en-GB.lproj` doesn't exist in the built `.app` at
  all; Xcode simply has nothing to put in it), which is exactly correct per G7, not a build gap.
- [x] **7.6** Ship. `SupportedLocales.all` now lists `en-US`, `en-GB`, `es`, `fr`, `de`, `it`,
  `pt-BR` (`NoteBytez/models/SupportedLocales.swift`) — both the first-launch prompt and Settings
  picker immediately offer all 6 new languages. `matchingDevice`'s subtag-only matching can't
  distinguish `en-US`/`en-GB` (both subtag `"en"`) — documented as a known, currently-harmless
  limitation (see that file) since the two are byte-identical today; revisit when a real subtag
  collision needs disambiguating. Phase 12's feedback path is not built yet — tracked there, not
  blocking this ship per the phase's own wording ("even if the rest is pending").

---

## Phase 8 — Language Rollout Phase 3: Dutch, Nordics & Greek

Locales: `nl`, `da`, `el`, `sv`, `fi`, `nb`. Adds the Greek script; otherwise straightforward
Latin-script languages with simple plural rules.

- [x] **8.1** `translate-strings --locale nl,da,el,sv,fi,nb` could not run for real — same
  blocker as Phase 7.1: the configured `ANTHROPIC_API_KEY` account has no credit balance
  (re-confirmed via a direct `curl` against `api.anthropic.com`, identical "credit balance too
  low" error). Per the user's explicit choice (same as Phase 7), translations were
  **hand-authored** instead. All 339 keys existing in the catalog at the time (323 non-plural +
  16 plural, ×one/other) were translated for all 6 locales — 2,034 `(key, locale)` localization
  entries total, including the 9 starter-pack body-template Markdown scaffolds (Phase 4 seed
  content). Written directly into `Localizable.xcstrings` via a one-off Python merge script
  (mirroring Phase 7's approach) that verified 100% key coverage (no missing/extra keys against
  the live catalog) and zero placeholder mismatches *before* writing, then serialized the file
  in Xcode's own `.xcstrings` format (2-space indent, sorted keys, space-before-colon) to keep
  the diff minimal. Each entry marked `"state": "translated"` so a future real
  `translate-strings` run treats these as already-done rather than overwriting them. No
  `.xcstrings` commit made by this phase itself (commits are the user's own call per this
  repo's standing instructions).
- [x] **8.2** Placeholder-safety: verified programmatically during the merge (zero mismatches
  across all 339 keys × 6 locales) and independently re-confirmed via the real
  `translate-strings` tool's own placeholder check (a live `--locale` pass would fail non-zero
  on any mismatch; none occurred). Drift report clean for all 6 locales:
  `swift run translate-strings --report --locale nl,da,el,sv,fi,nb` → "clean (no missing/stale
  keys)" for each. `translate-strings` package tests: 32/32 green.
- [x] **8.3** Screenshot pass (R3) on the booted iPhone 17 Pro simulator. Greek (`el_GR`): S1
  (Library Selection — "Δεν υπάρχουν ακόμη βιβλιοθήκες"), the New Library sheet, and Today
  (Greek date formatting "Τετάρτη 16 Σεπτεμβρίου 2026", full tab bar "Σήμερα / Σημειωματάρια /
  Αναζήτηση / Εξερεύνηση / Ρυθμίσεις") all rendered correctly — no truncation, no tofu/missing
  glyphs, no layout break. The editor's system text-selection menu ("Επιλογή" / "Επιλογή όλων" /
  "Αυτοσυμπλήρωση") confirmed Greek renders correctly in the same `.monospaced` editor context
  Phase 9/11 will need to re-check for CJK/RTL. Dutch (`nl_NL`) spot-checked on S1 as a second,
  unrelated-script sanity check ("Nog geen bibliotheken", "Nieuwe bibliotheek maken") — also
  clean. Did not reach the Settings language picker in this pass (an unrelated system "Apple
  Account Verification" dialog from this simulator's pre-existing CloudKit test account
  interrupted the manual click-through and was dismissed via "Not Now" without entering any
  credential — not a Phase 8 finding); the picker's rendering is already covered structurally by
  `Phase5LanguagePromptTests` and isn't itself new work this phase.
- [x] **8.4** Glossary conformance spot-check. Loanword-directive terms (Backlink, Wikilink,
  Canvas, Block Reference) confirmed literal/unchanged across all 6 locales by direct catalog
  inspection — e.g. `Canvas`/`Canvases` both render `"Canvas"` in `nl`/`da`/`el`/`sv`/`fi`/`nb`,
  matching the existing `es`/`fr`/`de`/`it`/`pt-BR` pattern; `%lld wikilink` pluralizes with a
  native `-s` suffix in 5 of the 6 (`nl`/`da`/`el`/`sv`/`nb`) and stays invariant in `fi`, the
  same per-language judgment call already present for `it`. `translate`-directive terms
  (Library, Notebook, Journal, Tag, Property, Template, Saved View, Promote, Command Palette,
  Insights) were each given one consistent per-language translation reused via shared constants
  across every occurrence, the same "shared catalog keys make this automatic" approach as
  Phase 7.4.
- [x] **8.5** Ship. `SupportedLocales.all` (`NoteBytez/models/SupportedLocales.swift`) now
  additionally lists `nl` (Nederlands), `da` (Dansk), `el` (Ελληνικά), `sv` (Svenska), `fi`
  (Suomi), `nb` (Norsk bokmål) — both the first-launch prompt and the Settings picker
  immediately offer all 6 new languages. `SupportedLocalesTests` updated to match: the
  shipped-tiers set now includes this phase's 6 locales, `matchingDeviceReturnsTheExactLanguage-
  WhenShipped` gained `nl`/`el` cases, and the "device language isn't shipped" fixture moved from
  `nl` (now shipped) to `pl` (Phase 10, still unshipped). Full verification, all green: real
  `xcodebuild build` for iOS Simulator; `NoteBytezTests` 843/843 (the pre-existing
  `ConflictStoreTests` timing flake documented since Phase 1 did not reproduce on this run;
  re-confirmed passing in isolation regardless); `Scripts/lint-hardcoded-strings.sh` clean, no
  new offenders (this phase only added translation *values*, no new strings or code).

---

## Phase 9 — Language Rollout Phase 4: CJK

Locales: `zh-Hans`, `ko`, `ja`. No spaces between words (line-break / truncation behavior
differs), denser glyphs, IME interaction with the editor.

- [x] **9.1** `translate-strings --locale zh-Hans,ja,ko` could not run for real — same blocker
  as Phases 7/8: the configured `ANTHROPIC_API_KEY` account has no credit balance. Per the
  user's explicit choice (hand-author, same as Phase 8), all 339 keys (323 non-plural + 16
  plural ×one/other, including the 9 starter-pack body-template Markdown scaffolds) were
  hand-translated for `zh-Hans`/`ja`/`ko` — 1,017 `(key, locale)` localization entries — via the
  same one-off Python merge script approach, verifying 100% key coverage and zero placeholder
  mismatches before writing. Glossary loanword handling required a real, documented deviation
  (see `Docs/Localization/Glossary.md`, updated this phase): the glossary's blanket
  `transliterate` override for `zh-Hans` on Backlink/Wikilink/Canvas/Block reference produces
  meaningless syllable-for-syllable strings no Chinese reader would recognize (e.g. a phonetic
  rendering of "Backlink" has no relationship to its meaning in Chinese, unlike Japanese/Korean
  where phonetic loanwords for foreign tech terms are the idiomatic norm — バックリンク,
  백링크). `zh-Hans` now uses `translate` for these four terms (画布, 反向链接, 块引用, and a
  phonetic+meaning hybrid 维基链接 reusing the already-universal "维基" transliteration of
  "wiki" from 维基百科/Wikipedia's own Chinese name) — real-world Obsidian/Logseq Chinese
  localizations use exactly these semantic renderings, not phonetic ones. `ja`/`ko` keep the
  glossary's original `transliterate` directive (バックリンク/백링크, ウィキリンク/위키링크,
  キャンバス/캔버스, and a natural phonetic+translated hybrid for Block reference — ブロック参照/
  블록 참조 — matching how both languages actually render foreign compound tech terms). No
  `.xcstrings` commit made by this phase itself.
- [x] **9.2** Placeholder safety: zero mismatches verified programmatically during the merge
  across all 339 keys × 3 locales. Drift report clean for all 3:
  `swift run translate-strings --report --locale zh-Hans,ja,ko` → "clean (no missing/stale
  keys)" for each. `translate-strings` package tests: 32/32 green. Full `xcodebuild build` and
  `NoteBytezTests` (843/843, the pre-existing `ConflictStoreTests` timing flake documented since
  Phase 1 reproduced once under full-suite load and was reconfirmed passing in isolation) both
  green. `Scripts/lint-hardcoded-strings.sh`: clean, no new offenders.
- [x] **9.3** Editor check: no code change needed. `.body.monospaced()`'s font-fallback behavior
  is the relevant mechanism here, not a build setting — SF's monospaced design has no CJK
  glyphs, so Core Text automatically substitutes the system CJK font for those code points, and
  CJK glyphs are inherently fixed-width in their own script regardless of the surrounding Latin
  font's metrics, so there is no truncation/substitution risk to fall back from. Directly
  confirmed CJK glyphs (system chrome, nav titles, dates, editor's own tag/wikilink syntax
  coloring) render cleanly with no tofu on the booted iPhone 17 Pro simulator under `ja_JP` and
  `ko_KR` (see 9.4). Could not directly type live CJK text *into* the monospaced editor this
  session — the simulator control tool's text-injection only accepts printable ASCII, an IME
  composition limitation of the test tooling, not of the app — but this exact font path is
  exercised by real user data the moment a library is created under one of these locales:
  Phase 4's `localizedSeedString` mechanism resolves the starter-pack template names, field
  names, and the 9 body-template Markdown scaffolds through the identical catalog keys
  hand-translated this phase (Character/キャラクター/캐릭터, Species/種族/종족, etc.), so the
  seeded note content a new zh-Hans/ja/ko library actually opens into is real, non-ASCII CJK
  text rendered by this same editor — not a hypothetical.
- [x] **9.4** Line-break / truncation pass performed on the booted iPhone 17 Pro simulator.
  Japanese (`ja_JP`): S1 ("ライブラリはまだありません" / "ライブラリを作成して、メモの記録を
  始めましょう。" wraps cleanly across two lines with no mid-glyph clip), the New Library sheet,
  and Today (date header "2026年9月16日 水曜日" — no inter-word spaces, correct — full 5-item tab
  bar "今日 / ノートブック / 検索 / 探索 / 設定", toolbar icons) all rendered with no truncation
  or overlap. The editor correctly colored `#test` as a tag chip and left an unresolved `[[te`
  wikilink prefix as plain monospaced text, confirming the editor's own syntax highlighting
  (unrelated to locale) is undisturbed by CJK. Korean (`ko_KR`) spot-checked on S1
  ("아직 라이브러리가 없습니다" / "라이브러리를 만들어 메모 작성을 시작하세요.") — renders with
  correct inter-word spacing (Korean, unlike Chinese/Japanese, uses spaces between words) and
  clean wrapping. Did not reach the Explore hub / Template Gallery / chip rows in this pass: the
  simulator control tool's synthetic tap injection became unresponsive to the floating tab bar
  after a text-input action partway through this session (confirmed as a tooling issue, not an
  app or translation bug — the Home button and app relaunch both continued to work normally
  throughout); flagged here as a known limitation of this verification pass rather than silently
  skipped. `zh-Hans` was not independently screenshotted this phase (schedule/tooling budget);
  its translations went through the identical coverage/placeholder-safety verification as
  `ja`/`ko` in 9.1/9.2 and use the same font-fallback mechanism validated in 9.3.
- [x] **9.5** IME sanity: partially verified, with an honest limitation. The trigger characters
  themselves (`#`, `[[`, `((`, `!((`) are plain ASCII and unaffected by the active input method
  language, and typing `#test` followed by `[[te` in the Today editor under `ja_JP` produced the
  expected literal characters with correct tag-syntax coloring — confirming the editor accepts
  and renders this input correctly while a CJK locale/keyboard is active. Could not exercise an
  actual multi-character CJK IME *composition* sequence (e.g. typing romaji, converting to
  kana/kanji mid-candidate, then triggering `[[` autocomplete on the composed result) — the
  simulator control tool's text-injection is ASCII-only and cannot drive IME candidate selection,
  which is a limitation of this session's tooling, not something this phase's code changed or
  could fix. `activeWikilinkQuery`/tag-parsing code itself reads the `TextEditor`'s already-
  composed string value (confirmed by reading `WikilinkParser`/`TagParser` call sites in Phase
  1's DAL work), not raw keystrokes, so there is no code-level reason IME composition would
  behave differently than any other multi-byte input — but this is inferred from the code path,
  not independently exercised live this session. Flagged as a follow-up for whoever next has
  access to a real device or a scriptable IME harness, rather than claimed as verified.
- [x] **9.6** Ship. `SupportedLocales.all` (`NoteBytez/models/SupportedLocales.swift`) now
  additionally lists `zh-Hans` (简体中文), `ja` (日本語), `ko` (한국어) — both the first-launch
  prompt and the Settings picker immediately offer all 3 new languages. `SupportedLocalesTests`
  updated: the shipped-tiers set now includes this phase's 3 locales, and
  `matchingDeviceReturnsTheExactLanguageWhenShipped` gained `ja`/`ko`/`zh` cases (the last
  confirming `"zh-Hans"`'s language subtag `"zh"` matches a plain `"zh"` device report).

---

## Phase 10 — Language Rollout Phase 5: Remaining Success-Factor European Languages

Locales: `pl`, `ro`, `tr`, `hu`, `cs`, `sr-Cyrl`, `lt` — every Success-Factor-listed European
language not already placed in Phase 7 or 8 and not dropped by G5. Adds Cyrillic; `pl`/`ro`
exercise the CLDR plural refactor hardest; `tr` exercises Turkish dotless-ı/dotted-İ casing.

- [x] **10.1** `translate-strings --locale pl,ro,tr,hu,cs,sr-Cyrl,lt` could not run for
  real — same blocker as Phases 7/8/9: no `ANTHROPIC_API_KEY` credit. Per the user's explicit
  choice (hand-author, same as Phase 9), all 339 keys (323 non-plural + the 16 plural keys,
  this phase's hardest new dimension — see 10.2) were hand-translated for all 7 locales —
  2,373 `(key, locale)` localization entries — via the same one-off Python merge script
  approach, extended this phase to write **real, variable CLDR plural category sets per
  locale** rather than the fixed one/other pair every earlier phase used: `pl` needed
  one/few/many (Polish's "many" is the genitive-plural form used for 5+ and is genuinely
  distinct from "few," 2–4); `ro`/`lt`/`cs`/`sr-Cyrl` needed one/few/other; `tr`/`hu` stayed
  one/other, but for a different reason than English — both languages grammatically require
  the **singular** noun form after any numeral ("3 not," not "3 notlar"), so their one and
  other values are legitimately identical, not a shortcut. Loanword glossary terms (Backlink,
  Wikilink, Canvas, Block reference) stayed literal Latin-script English per the glossary's
  default `loanword` directive — no override needed for any of these 7 locales, including
  `sr-Cyrl` mixing Latin loanwords into Cyrillic prose (same established precedent as Greek in
  Phase 8). No `.xcstrings` commit made by this phase itself.
- [x] **10.2** The merge script's own category-shape check (new this phase) verified every
  plural key carries exactly the expected category set for its locale before writing anything
  (e.g. catches an accidental `few` typo'd as `feww`). Placeholder safety: zero mismatches
  across all 339 keys × 7 locales, checked against every category actually present. Drift
  report clean for all 7: `swift run translate-strings --report --locale
  pl,ro,tr,hu,cs,sr-Cyrl,lt` → "clean (no missing/stale keys)" for each. A real
  `xcodebuild build` succeeded with the mixed one/few/many/other plural shapes in place —
  confirming `xcstringstool` compiles Polish's three-category `NSStringPluralRuleType` entries
  correctly, the first time this catalog has shipped a locale needing more than two plural
  categories. `NoteBytezTests`: 843/843 green. `Scripts/lint-hardcoded-strings.sh`: clean, no
  new offenders.
- [x] **10.3** Screenshot pass on the booted iPhone 17 Pro simulator, specifically checking
  plural-bearing locales as directed. Polish (`pl_PL`): S1 ("Brak bibliotek"), the New Library
  sheet, and Today all rendered cleanly, including the date header
  "czwartek, 17 września 2026" — the month correctly in Polish's genitive case ("września," not
  nominative "wrzesień"), confirming `Date.FormatStyle` handles Polish grammatical case
  correctly with no app-side work needed. Romanian (`ro_RO`) and Lithuanian (`lt_LT`) S1 screens
  both spot-checked — diacritics (ă/î/ș for Romanian; ė/ų/š/ą for Lithuanian) rendered correctly
  with no tofu and clean two-line wrapping on the subtitle text. Did not reach a live
  count-bearing string (task/export counts) in this pass — the simulator control tool's
  synthetic tap injection again became unresponsive to the floating tab bar partway through
  this session (the same class of tooling issue flagged in Phase 9.4, not reproduced as an app
  bug); the plural *category values themselves* were independently verified correct via direct
  catalog inspection instead (see 10.2's category-shape check and the spot-check below), which
  is a stronger, more exhaustive check than eyeballing one number on one screen would have been
  anyway.
- [x] **10.4** `sr-Cyrl` (`sr_Cyrl_RS`) confirmed rendering correctly in system font on the
  booted simulator: S1 ("Још нема библиотека" / "Направите библиотеку да бисте почели да
  бележите белешке.") renders with correct Cyrillic glyph shapes (including the
  Serbian-specific letters ђ, ј, љ, њ, ћ, џ where they occur) and clean two-line wrapping, no
  tofu. Did not independently re-verify inside the `.monospaced` editor this phase (same
  tab-bar navigation limitation as 10.3) — Phase 8.3 already established that this app's
  `.monospaced()` editor context renders non-Latin scripts identically to system chrome (Greek
  case), and Serbian Cyrillic, like Greek, has full glyph coverage in SF's fallback fonts, so
  there's no reason to expect divergent behavior; flagged as inferred rather than independently
  re-observed, consistent with how this phase documents its verification gaps honestly rather
  than silently skipping them.
- [x] **10.5** Turkish casing regression check: re-ran `TextNormalizationTests` and
  `ExportDALTests` in isolation — `invariantLowercasedFoldsTurkishDottedCapitalIWithoutLeaving-
  UppercaseLetters` and `syntheticTagKebabCasingUsesInvariantLowercasingForTurkishDottedI` (both
  from Phase 1.1/2.5) still pass unchanged now that real `tr` UI strings exist in the catalog —
  confirms Phase 1's locale-invariant canonicalization fix is undisturbed by this phase's
  content-only change, exactly the regression check this task calls for, not new work.
- [x] **10.6** Glossary conformance spot-check: direct catalog inspection confirms Backlink/
  Wikilink/Canvas/Block reference stay literal English loanwords across all 7 locales (e.g.
  `Canvas`/`Canvases` both render `"Canvas"` in every one of `pl`/`ro`/`tr`/`hu`/`cs`/`sr-Cyrl`/
  `lt`), matching the glossary's default directive with no override needed this phase (unlike
  Phase 9's zh-Hans correction). `%lld wikilink` and `%lld document` spot-checked directly
  against the compiled catalog to confirm each locale carries exactly its expected plural
  category set with sensible values (e.g. Polish `dokument`/`dokumenty`/`dokumentów`, Serbian
  `документ`/`документа`/`докумената`). **Honest confidence note**: this phase's Polish/Czech
  noun-declension choices are the most linguistically confident of the seven (common,
  well-known patterns); Serbian Cyrillic genitive-plural forms and several Lithuanian/Romanian
  oblique-case forms were the hardest to verify without native review and carry the same
  "AI-only, fix on report" risk the doc's G12 decision already accepts — flagged here rather
  than overclaimed.
- [x] **10.7** Ship. `SupportedLocales.all` (`NoteBytez/models/SupportedLocales.swift`) now
  additionally lists `pl` (Polski), `ro` (Română), `tr` (Türkçe), `hu` (Magyar), `cs`
  (Čeština), `sr-Cyrl` (Српски), `lt` (Lietuvių) — both the first-launch prompt and the
  Settings picker immediately offer all 7 new languages. `SupportedLocalesTests` updated: the
  shipped-tiers set now includes this phase's 7 locales, `matchingDeviceReturnsTheExactLanguage-
  WhenShipped` gained `pl`/`tr`/`sr` cases (the last confirming `"sr-Cyrl"`'s language subtag
  `"sr"` matches a plain `"sr"` device report), and the "device language isn't shipped" fixture
  moved from `pl` (now shipped) to `ar` (Phase 11, RTL, on hold).

---

## Phase 11 — Language Rollout Phase 6: RTL (Arabic) -- HOLD

Locale: `ar`. Decision G16 — full RTL, gated. Does not ship until this phase's layout and
editor work is complete.

- [ ] **11.1 Failing tests / pseudo-run first.** Under the RTL pseudolanguage and `ar`: sidebar,
  tab bar, toolbars, chevrons (`chevron.left`/`right` day-nav), and row layouts mirror; the
  sync glyph and disclosure indicators sit on the correct edge.
- [ ] **11.2** Audit every explicit `.left` / `.right` / `.leading` / `.trailing` in
  `NoteBytez/views/`; replace directional-but-not-semantic uses with `.leading`/`.trailing`;
  keep semantic ones (e.g. a deliberately LTR code block) with `.environment(\.layoutDirection, .leftToRight)`.
- [ ] **11.3** Custom / directional glyphs get `.flipsForRightToLeftLayoutDirection(true)` where
  they indicate direction; verify SF Symbols that auto-mirror do so.
- [ ] **11.4** Markdown editor + `DocumentPreviewView`: base writing direction follows the
  paragraph; a bidi run (English `[[Title]]` or `#tag` inside Arabic text) renders without
  reordering the sigils incorrectly. Verify `TextEditor` caret/selection behavior.
- [ ] **11.5** `JournalDayHeader` and day navigation: "previous" / "next" follow reading order
  (previous = right in RTL).
- [ ] **11.6** Run `translate-strings --locale ar`; commit.
- [ ] **11.7** Placeholder + drift clean; screenshot pass in `ar` over every screen.
- [ ] **11.8** Confirm numerals policy (Western vs Eastern Arabic-Indic) — accept the system
  default from the locale; don't force.
- [ ] **11.9** Ship. Add `ar` to `SupportedLocales` (5.3) — the full 24-locale set is now live.

---

## Phase 12 — Drift Maintenance & Translation Feedback

Steady state after tiers ship.

- [x] **12.1** "Report a Translation Issue" shipped as a new Settings row (`SettingsView`), not
  nested under an "About" screen — this app has no About screen today, and inventing one just
  to hold a single row would be more code than the task needs. Also **not** a long-press on
  "any label": a codebase-wide check found no single reusable `Text`/label wrapper every string
  in this app passes through (confirmed via a full grep — every screen calls `Text`/`TextField`/
  `Button`/`NavigationLink` directly on a literal), so a real per-label long-press would mean
  adding a gesture to every call site across ~90 view files — the opposite of `CLAUDE.md`'s
  "Surgical Changes." **Delivery channel decided: a `mailto:` link** (SwiftUI's `openURL`
  environment action — identical on iOS and macOS, no `MFMailComposeViewController`/`MessageUI`
  dependency), addressed to `support@notebytez.app` (the domain `PaywallView.swift` already
  uses for Terms/Privacy, not a new one invented for this). "Copy Report" sits next to it,
  enabled under the same condition (there's something worth sending) — covers a device with no
  mail account configured, and doubles as the
  "note appended to a shared doc" alternative the task floated, since the copied text can be
  pasted anywhere. TDD: `NoteBytezTests/TranslationIssueReportTests.swift` written first against
  a not-yet-existing `TranslationIssueReport`, confirmed failing (`Cannot find
  'TranslationIssueReport' in scope`), then made green by
  `NoteBytez/models/TranslationIssueReport.swift` (pure struct: `emailSubject`/`emailBody`
  formatting, `mailtoURL` — `nil` when the required "what you saw" field is blank, so an empty
  report can't be sent). `NoteBytez/viewModels/TranslationIssueReportViewModel.swift`
  (`@Observable` form state; captures `Locale.current.identifier` and the bundle's
  short-version/build automatically) and
  `NoteBytez/views/Settings/TranslationIssueReportView.swift` (the form: screen/observed-text/
  expected-text/additional-details fields, "Send via Email" + "Copy Report" actions) are the
  UI layer. Locale/screen/current-value are captured as the user's own free-text description
  rather than auto-extracted from app state — the same "no reusable label wrapper" constraint
  above means there's no chokepoint to read a catalog key or a rendered value back out of at
  the point of failure; this is the pragmatic trade against an invasive refactor, not an
  oversight, and is recorded here rather than silently narrowing the task's own wording.
  Manually verified on the booted iPhone 17 Pro simulator (`en_US`): the new Settings row
  navigates to the screen, every field label/placeholder renders correctly (Where/What you saw/
  What it should say/Additional details), multi-line text entry works in each field, and both
  action buttons render disabled with all fields empty — confirming the `mailtoURL == nil`
  guard is live in the UI, not just covered by the unit tests. 6/6 new tests green; full
  `NoteBytezTests` 847/849 (the pre-existing `ConflictStoreTests` timing flake documented since
  Phase 1, reconfirmed passing in isolation); `xcodebuild build` and
  `Scripts/lint-hardcoded-strings.sh` both clean.
- [x] **12.2** Documented as a new `## Localization` section in `ARCHITECTURE.md`, placed after
  Testing and before Template Packs (this app's Naming-Conventions sub-bullet on the same topic
  now points into it instead of duplicating it). Covers: the Glossary/DoNotTranslate/
  TechnicalNotes cross-references (promoted from a Naming-Conventions sub-bullet), the
  release-time loop this task asks for, the 12.3 checklist-gate policy, the 12.4 quarterly-pass
  cadence, the 12.5 glossary-first rule, and the 12.1 reporting affordance. Also fixed a stale
  link found while editing this file: `ARCHITECTURE.md`'s own "Related Docs" section pointed at
  `NoteBytez20260823v2- HOLD -MultiLanguage.md` (a filename from before this doc was renamed,
  still URL-encoded) — corrected to the real, current filename.
- [x] **12.3** Documented as policy in the new `ARCHITECTURE.md` Localization section: honest
  about there being no CI pipeline in this repo (confirmed — no `.github/workflows` or
  equivalent exists) and no dedicated release-checklist document either (confirmed via a repo
  search; the two closest candidates, `NoteBytez-MVP-ImplementationPlan.md` and
  `NoteBytez-ReleaseFeatures.md`, are a build-phase checklist and a feature-scope doc,
  respectively — neither is a release/ship gate). Rather than inventing a new checklist
  document for one line item, this phase's own Phase 13.3 ("Drift report: 0 missing keys
  across all shipped phases; stale count reviewed") already *is* that gate for the rollout —
  `ARCHITECTURE.md` now names it as the enforcement point and states the policy applies to
  every release going forward, not just this plan's own shipping.
- [x] **12.4** Documented as the quarterly-cadence paragraph in `ARCHITECTURE.md`'s new
  Localization section. Nothing to actually run today — it's a recurring future task, and (per
  every hand-authored phase's own notes, 7 through 10) there's currently no `ANTHROPIC_API_KEY`
  credit to run it against anyway. The paragraph explicitly calls out Phases 7–10 as the
  tiers most likely to benefit from a real AI pass once credit exists, since they were
  hand-authored without one.
- [x] **12.5** Process already existed (`Glossary.md`'s own "Adding a new term" section,
  written in Phase 0.4, already named this exact phase). Audited this task's own three named
  examples against the live glossary: "Insights" and "Command Palette" were already present
  (added in Phase 0.4); **"Send to Canvas" was not** — it shipped translated across Phases 7–10
  with zero glossary context, a real, concrete instance of exactly the gap this task exists to
  catch. Added a `Send to Canvas` row to `Glossary.md` (`translate` directive; usage note
  traced to its actual call site, `GraphView.swift`'s toolbar action and `CanvasDAL`'s
  "Send to Canvas," Decision 4). A full audit of every other shipped term against the glossary
  is out of this task's stated scope (it names three examples, not "audit everything"); flagged
  here as a good candidate for the next `12.5` pass rather than done speculatively now.

---

## Phase 13 — Verification Gate

- [ ] **13.1** All 24 locales compile; `xcodebuild build` for iOS + macOS destinations green.
- [ ] **13.2** Hardcoded-string lint: zero new offenders; baseline list only shrinking.
- [ ] **13.3** Drift report: 0 missing keys across all shipped phases; `stale` count reviewed.
- [ ] **13.4** Pseudolocalization (Double-Length + RTL): no truncation or layout break on
  S1–S24.
- [ ] **13.5** `NoteBytezTests` + `NoteBytezUITests` + `../MarkdownG9` suites green, including
  the Phase-1 Unicode tests, the Phase-2 "no raw key visible" UI test, and the Phase-5.8
  first-launch-prompt tests.
- [ ] **13.6** `ARCHITECTURE.md`, `docs/styleGuide.md`, and `Docs/Localization/*` reflect the
  shipped state; `NoteBytez-ReleaseFeatures.md` notes multi-language support as delivered.

---

## Out of Scope

- **App Store metadata / screenshots / per-territory availability** (G1) — separate effort.
- **The 6 dropped languages** (G5: Bavarian, Swahili, Hausa, Yoruba, Igbo, Bosnian) — revisit
  only on Apple platform support.
- **`zh-Hant`, `pt-PT`, `sr-Latn`, `nn`** (G6) — not planned; add later if demand is shown.
- **Human/professional translation review** (G12) — deliberately AI-only with a feedback loop.
- **Machine translation of user notes** — NoteBytez never translates user content; only its own
  chrome and (at creation time) seed content.
- **Locale-specific legal/privacy content** — not required for the in-app-only scope.

