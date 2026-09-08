<!-- NoteBytez20260823V2-MultiLanguage.md -->
<!--
  User story describing the features needed for NoteBytez to support users that are not using English.
-->
# Multi-Language Support

As a user (senior software engineer), I want to ensure that the NoteBytez app can be downloaded and used by end users that are not comfortable using the English language. This will allow a broader use of the application.

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

---

# Gaps Identified and Decisions

The original User Story ("app can be downloaded and used by end users not comfortable with
English") and the three Success Factors leave the scope, the language list, the translation
pipeline, and every localization-adjacent technical concern unspecified. Gaps below were
identified against the current codebase (state: `LOCALIZATION_PREFERS_STRING_CATALOGS = YES`
in the project, but **no String Catalog exists yet**; `knownRegions = (en, Base)`;
`developmentRegion = en`; ~227 user-facing string literals in `Kontinuum/views/`; English
pluralization hand-rolled in code; title sort is a raw `<` comparison; tag canonicalization
case-folds without locale awareness). Decisions were made in an interview on 2026-08-29.

## Scope

| # | Gap | Decision |
|---|---|---|
| G1 | "Downloaded" implies App Store listing/metadata/screenshot localization; SF1 only says "UI/UX text". | **In-app UI only.** App Store name, subtitle, description, keywords, screenshots, and per-territory availability are **out of scope** for this effort and handled separately. |
| G2 | Unclear whether NoteBytez-*generated* content is "UI text": starter `TemplateGroup`s (Fiction Writing, Character, Location…), `JournalDAL.template(for:)`, example seed data. | **Localize at creation time.** `LibraryDAL.create`'s seeding (`TemplateDAL.seedStarterContent`, journal template) emits content in the device's current language *at the moment the library is created*; it is never retranslated afterward — it is the user's editable data from that point. |
| G3 | No definition of done / acceptance bar / sign-off owner for SF1's "supports". | Acceptance = (a) no hardcoded user-facing string remains (lint, Phase 0); (b) pseudolocalization + double-length + RTL pseudolanguage passes show no truncation or layout break (Phase 0/6); (c) per-locale key-completeness is 100% at ship (missing keys fall back to en-US at runtime and are CI-warned, never blank); (d) a per-locale screenshot pass of the key-screen set is reviewed before that locale's tier ships. Owner: the release engineer for each tier. |
| G4 | How does a user actually get a non-English experience? | **Both.** iOS per-app language (Settings → NoteBytez → Language, automatic once localizations ship) **and** an in-app language override in `SettingsView` (see G4a). |
| G4a | In-app override mechanism (true no-relaunch switching is hard on iOS). | In-app picker sets the app's preferred localization (`AppleLanguages` in the app's `UserDefaults` suite) and applies on next launch, with a clear "changes take effect after restart" note. No attempt at live re-render of the whole tree. A "System default" option clears the override. |

## Language list

| # | Gap | Decision |
|---|---|---|
| G5 | 6 entries have little/no iOS display-language or App Store localization support: **Bavarian** (a German dialect, no locale), **Swahili**, **Hausa**, **Yoruba** ("Yorub", also a typo), **Igbo**, **Bosnian**. | **Dropped from scope.** Revisit only if Apple adds first-class support. |
| G6 | Script/region variants unresolved: Portuguese (pt-PT vs pt-BR), "Chinese – Mandarin" (zh-Hans vs zh-Hant), Serbian (Cyrl vs Latn), Norwegian (nb vs nn). | **Larger-market single variant each:** `pt-BR`, `zh-Hans`, `sr-Cyrl`, `nb`. |
| G7 | Two English variants (US + UK) — parallel maintenance for spelling. | **Keep both.** `en-US` is the development base; `en-GB` is an override layer carrying *only* the strings that actually differ (spelling, a few terms), inheriting en-US for the rest. |
| G8 | No canonical BCP-47 list. | **Final set — 24 locales:** `en-US` (base), `en-GB`, `es`, `fr`, `de`, `it`, `pt-BR`, `nl`, `sv`, `da`, `nb`, `fi`, `pl`, `cs`, `hu`, `ro`, `el`, `lt`, `sr-Cyrl`, `zh-Hans`, `ja`, `ko`, `ar`. |
| G9 | No phasing — 24 locales is a large QA matrix. | **Phased tiers** (see Implementation Plan Phases 6–9): T1 major European, T2 Nordic + Central/Eastern European, T3 CJK, T4 RTL (Arabic). A tier ships when it passes its screenshot/pseudoloc gate. |

## Translation pipeline (SF3 = "performed by AI", nothing else)

| # | Gap | Decision |
|---|---|---|
| G10 | No mechanism. | **Repo script over the String Catalog.** `Scripts/translate-strings.swift` (or a small SPM tool) extracts untranslated/stale keys from `Localizable.xcstrings`, sends each with its comment/context **and the terminology glossary** to an AI model, writes results back into the `.xcstrings`. Re-runnable and diffable; output committed to git so a re-run only touches what English changed (acts as translation memory). No third-party localization service. |
| G11 | No terminology control for product terms (Notebook, Backlink, Journal, Canvas, Wikilink, Promote, Block reference, Notebook, Library, Tag, Property, Template, Saved View). | **Maintained glossary** at `Docs/Localization/Glossary.md` (machine-readable table the script consumes). Each term carries a per-language directive: `translate` / `keep-as-loanword` / `transliterate`, so e.g. "Backlink" renders consistently and matches what Obsidian/Logseq migrants expect in that language. |
| G12 | No human/native review policy. | **AI-only, fix on report.** No review gate. Ship AI translations; provide an in-app "Report a translation issue" path (Phase 10) that captures the key, locale, screen, and current value. Corrections are applied to the `.xcstrings` and shipped in the next release. |
| G13 | No drift control when English strings change. | **CI warns, runtime falls back.** A CI step lists keys that are new / stale (English changed after translation) / missing per locale as a **non-blocking warning**. At runtime, any missing/empty value resolves to `en-US` so the UI is never blank. |
| G14 | Existing code hand-rolls English plurals (`"note\((n) == 1 ? "" : "s")"` in `SettingsView`, and similar). | **Adopt CLDR plural rules everywhere.** Every count-bearing string becomes a String Catalog plural variation; the hand-rolled ternaries are removed. Covers Polish/Romanian/Arabic multi-category plurals correctly. |
| G15 | Format specifiers / interpolation safety across languages (reordered args, `%@` vs positional `%1$@`). | The translate script validates that every translation preserves the placeholder set of its source (count, names, `%`-specifiers); a mismatch is a CI error, not a warning. |

## Technical concerns SF1 does not mention

| # | Gap | Decision |
|---|---|---|
| G16 | **RTL** (Arabic): layout mirroring, `.leading`/`.trailing` audit (views currently use some `.left`/`.right`), bidi in the Markdown editor/preview (e.g. an English `[[note title]]` inside Arabic prose), directional SF Symbols. | **Full RTL, gating the Arabic tier only** (Phase 9). Earlier tiers are unaffected. Arabic does not ship until layout mirrors correctly and the editor handles bidi. |
| G17 | **Unicode correctness** in DAL/parsers: title sort is `$0.title ?? "" < $1.title ?? ""` (not locale-aware); `TagParser.canonicalize` case-folds without handling Turkish dotless-ı / German ß; `WikilinkParser.fuzzyMatches` and search are not verified for NFC/NFD normalization or accent/diacritic handling. | **In scope, as an early phase** (Phase 1), *before* any locale rolls out. Sort → `localizedStandardCompare`; canonicalization → locale-aware case-folding + Unicode NFC normalization at every text-ingest boundary; fuzzy match / FTS reviewed for diacritic-insensitive behavior. These are correctness bugs that compound per language. |
| G18 | **Locale-dependent formatting**: `JournalDayHeader` date, `SyncStatusViewModel.lastSyncedText` ("Xm ago"), backup snapshot timestamps, first-day-of-week for journal navigation, number formatting. | **In scope** (Phase 1). All date/number/relative-time rendering routed through locale-aware `Date.FormatStyle` / `RelativeDateTimeFormatter` / `Calendar.current` with the active locale; no manually assembled date strings. |
| G19 | **Local Swift packages** (`../MarkdownG9`, `../SwiftRPT`) may expose user-facing strings. | **Audit both** (Phase 3). Any user-facing string gets its own String Catalog in that package, fed by the same translate script. If none exist, record that and move on. |
| G20 | **Do-not-translate set** is undefined — risk of localizing structural tokens. | Explicit non-localized register (Phase 0): `OSLog` messages; URL schemes (`wikilink://`, `tag://`, `blockref://`); frontmatter keys (`notebooks:`, `tags:`, property keys); the synthetic `#notebook/<name>` export tag; block anchors; JSON Canvas field names; the app name "NoteBytez"; the CloudKit container ID; accessibility *identifiers* (`sidebar.*`, `tabbar.*` — distinct from accessibility *labels*, which are localized). |
| G21 | **Font coverage** for the editor's `.body.monospaced()` across CJK/Arabic. | Check during Phases 8–9. If monospaced SF has gaps for a script, fall back that script's editor to proportional `.body` and accept system font substitution; documented, not worked around. |

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
| 0. i18n Infrastructure | 0 / 9 | Not started |
| 1. Unicode & Locale Correctness (pre-localization) | 0 / 8 | Not started |
| 2. String Externalization (app target) | 0 / 7 | Not started |
| 3. Package String Audit | 0 / 3 | Not started |
| 4. Seed-Content Localization at Creation Time | 0 / 5 | Not started |
| 5. In-App Language Override | 0 / 5 | Not started |
| 6. Tier 1 — Major European (es, fr, de, it, pt-BR, nl, en-GB) | 0 / 6 | Not started |
| 7. Tier 2 — Nordic + Central/Eastern European (sv, da, nb, fi, pl, cs, hu, ro, el, lt, sr-Cyrl) | 0 / 5 | Not started |
| 8. Tier 3 — CJK (zh-Hans, ja, ko) | 0 / 6 | Not started |
| 9. Tier 4 — RTL (ar) | 0 / 9 | Not started |
| 10. Drift Maintenance & Translation Feedback | 0 / 5 | Not started |
| 11. Verification Gate | 0 / 6 | Not started |
| **Total** | **0 / 74** | **0%** |

---

## Phase 0 — i18n Infrastructure

No user-visible change. Everything that must exist before strings are externalized or translated.

- [ ] **0.1** Create `Localizable.xcstrings` (String Catalog) in the app target; set the base
  as `en-US`. Add all 24 locales from G8 to the project's `knownRegions` and the target's
  localizations, so the catalog compiles every language slot from day one (values filled later).
- [ ] **0.2** Set `developmentRegion` decision: keep `en` in the pbxproj as the compile base;
  `en-US` / `en-GB` are catalog locales layered on top (R6).
- [ ] **0.3** Write `Docs/Localization/DoNotTranslate.md` — the G20 register — and reference it
  from `ARCHITECTURE.md` (§Naming / §Markdown parsing) and `docs/styleGuide.md`.
- [ ] **0.4** Write `Docs/Localization/Glossary.md` — machine-readable table (term, en
  definition, per-language directive `translate`/`loanword`/`transliterate`, notes). Seed with
  R5 defaults for the ~14 product terms.
- [ ] **0.5** Build `Scripts/translate-strings` (Swift, SPM executable): reads
  `Localizable.xcstrings` + `Glossary.md`, finds keys where a locale's state is
  `new`/`stale`/missing, calls the configured AI model with `{source, comment, glossary hits}`,
  writes translations + marks state `translated`. Idempotent. `--locale`, `--dry-run`,
  `--report` flags.
- [ ] **0.6** Placeholder-safety validator (G15) inside the script and as a standalone CI step:
  every translated value must carry the exact placeholder multiset of its source; mismatch =
  non-zero exit.
- [ ] **0.7** CI: drift report (G13) — a job printing new/stale/missing keys per locale as a
  **warning** (annotations, non-blocking). Runs on every PR touching `.xcstrings` or `views/`.
- [ ] **0.8** CI: hardcoded-string lint (R2) — flag `Text(verbatim:)`, `String(...)` /
  interpolation passed where a `LocalizedStringKey` is expected, and `.navigationTitle` /
  `.accessibilityLabel` given a non-literal. Baseline the current offenders; fail on new ones.
- [ ] **0.9** Add a **Pseudolocalization** run destination (R1): Double-Length + RTL
  pseudolanguage. Document running it in `docs/styleGuide.md` §Accessibility.

---

## Phase 1 — Unicode & Locale Correctness (pre-localization)

DAL / parser / formatter layer. Fixes latent correctness bugs (G17, G18) before any locale
exposes them. No new UI language yet.

- [ ] **1.1 Failing tests first.**
  - `DocumentDALTests`: a library with titles `["Äpfel","apfel","Apfel","Zebra"]` sorts by
    `localizedStandardCompare` under `de`, not ASCII order.
  - `TagParserTests`: `canonicalize("İSTANBUL")` under `tr` and under `en` — both fold to a
    single stable canonical form; `"straße"` / `"STRASSE"` do not silently split a tag.
  - `TagParserTests` / `WikilinkParserTests`: an NFD-composed input (`"é"`) and its NFC
    form (`"é"`) resolve to the same tag / wikilink target.
  - `SearchDALTests`: a diacritic-insensitive query (`"cafe"`) matches `"café"` in content.
  - Verify: all fail.
- [ ] **1.2** Route every user-facing collation through `localizedStandardCompare` (or a
  `String.localizedStandardCompare`-backed `SortComparator`): `DocumentDAL.fetchActive`,
  `TagDAL`, `NotebookDAL`, `BlockReferenceDAL` sort sites, `GraphDAL` ordering.
- [ ] **1.3** `TagParser.canonicalize` → locale-aware case-folding + `String`'s
  `precomposedStringWithCanonicalMapping` (NFC) normalization. Apply NFC at every text-ingest
  boundary: import, paste, `DocumentViewModel.content` setter, migration.
- [ ] **1.4** `WikilinkParser` / `BlockReferenceParser` matching: normalize both sides (NFC +
  case-fold) before comparison; add a diacritic-insensitive option for fuzzy/autocomplete.
- [ ] **1.5** `SearchDAL` (content / title / tag): diacritic- and case-insensitive matching
  via `String.range(of:options:)` with `[.caseInsensitive, .diacriticInsensitive]` or
  `folding(options:locale:)`.
- [ ] **1.6** Locale-aware formatting (G18): `JournalDayHeader`, `JournalViewModel` date nav,
  `SyncStatusViewModel.lastSyncedText`, `BackupSnapshotRow`, any `Date`/number rendering →
  `Date.FormatStyle` / `RelativeDateTimeFormatter` / `NumberFormatter` with `Locale.current`.
  First-day-of-week from `Calendar.current`.
- [ ] **1.7** Audit and register any Swift-side manually assembled date/number strings; none
  should survive.
- [ ] **1.8** Tests green; full `KontinuumTests` + `../MarkdownG9` suites pass; a quick manual
  pass under the `tr`, `de`, `sv` pseudo-run to confirm no regression in en behavior.

---

## Phase 2 — String Externalization (app target)

Every user-facing literal into `Localizable.xcstrings`, with context, plurals refactored.

- [ ] **2.1** Sweep `Kontinuum/views/` + `Kontinuum/*.swift`: confirm each `Text`, `Label`,
  `Button`, `.navigationTitle`, `Section`, `.accessibilityLabel`, `Toggle`, `TextField`
  placeholder, `Picker`, `.help`, `ContentUnavailableView`, `.alert`, menu-bar `.commands`
  string is a `LocalizedStringKey` literal (SwiftUI auto-extracts) or is explicitly
  `String(localized:)`. Convert the exceptions the Phase-0.8 baseline recorded.
- [ ] **2.2** Extract to catalog (Xcode "Migrate to String Catalog" + build); every key gets a
  `comment` (R4) — automated where an adjacent `//` comment exists, manual for the rest. Keys
  flagged `needs-context` block the translate script.
- [ ] **2.3** Plural refactor (G14): replace every hand-rolled count string (start with
  `SettingsView`'s export-count alert) with a String Catalog plural variation. Grep for
  `? "" : "s"`, `count == 1`, `"\(count) "` patterns; zero survivors.
- [ ] **2.4** Interpolation → positional specifiers where order may vary
  (`"%1$@ in %2$@"` style) so translators can reorder.
- [ ] **2.5** Verify `OSLog`/logging strings, URL schemes, frontmatter keys, and the
  `#notebook/` synthetic tag were **not** touched (G20 register; add a test asserting
  `ExportDAL` still emits literal `notebooks:` and `#notebook/<kebab>` regardless of locale).
- [ ] **2.6** Pseudolocalization pass (Double-Length + RTL) over every screen S1–S24; file
  bugs for truncation / clipping / layout breaks; fix.
- [ ] **2.7** `KontinuumUITests`: assert no screen shows a raw key (`%@`, `SOME_KEY`) under the
  pseudo-locale; full suite green.

---

## Phase 3 — Package String Audit

- [ ] **3.1** Grep `../MarkdownG9` and `../SwiftRPT` for user-facing strings (error messages
  surfaced to UI, any `LocalizedError`, formatter output). Record findings.
- [ ] **3.2** For any found: add a String Catalog to that package, wire it into the
  `translate-strings` script's target list, externalize with comments.
- [ ] **3.3** If none: note "packages are UI-string-free at the boundary" here and in
  `ARCHITECTURE.md` §Related Docs.

---

## Phase 4 — Seed-Content Localization at Creation Time

Decision G2. Seed content is emitted in the device language when the library is created, then
becomes plain user data.

- [ ] **4.1 Failing tests first (`TemplateDALTests`, `JournalDALTests`, `LibraryDALTests`).**
  - `LibraryDAL.create` under `es` seeds a `TemplateGroup` named the Spanish string, with
    Spanish template/field names; under `en` it is byte-identical to today.
  - Re-running seeding is still idempotent and does not retranslate an existing (possibly
    user-edited) group.
  - `JournalDAL.template(for:)` returns the localized template body for the active locale.
  - Verify: fail.
- [ ] **4.2** Move starter `TemplateGroup` / `NoteTemplate` names + field names + journal
  template body into `Localizable.xcstrings` (or a dedicated `SeedContent.xcstrings`), resolved
  via `String(localized:)` **at seed time only** inside `TemplateDAL.seedStarterContent` /
  `JournalDAL.template(for:)`.
- [ ] **4.3** Confirm the seeded rows persist the resolved literal string (not a key) — once
  written they are ordinary `Document`/`TemplateGroup` data and never move again.
- [ ] **4.4** Example/placeholder library names in `LibrarySelectionView` localized the same way.
- [ ] **4.5** Tests green; manual: create a library under `de`, confirm German starter groups,
  switch app to `en`, confirm the existing groups stay German (they're data now).

---

## Phase 5 — In-App Language Override

Decision G4 / G4a.

- [ ] **5.1 Failing tests first (`SettingsViewModel`/new `LocalePreferenceStore`).** Setting a
  preferred language writes `AppleLanguages` to the app's `UserDefaults`; "System default"
  clears it; reading back round-trips.
- [ ] **5.2** `LocalePreferenceStore` (UserDefaults, mirrors `ConflictStrategyStore`).
- [ ] **5.3** `SettingsView` → "Language" row: a `Picker` of the 24 locales (endonym labels —
  "Deutsch", "日本語", "العربية") + "System default", with a "takes effect after restart" caption.
- [ ] **5.4** Apply on launch in `KontinuumApp.init` (set `AppleLanguages` before the window
  builds); confirm interaction with iOS's own per-app language setting is documented (in-app
  override wins; clearing it returns control to iOS).
- [ ] **5.5** `KontinuumUITests`: set override to `fr`, relaunch, assert a known screen renders
  French.

---

## Phase 6 — Tier 1: Major European

Locales: `es`, `fr`, `de`, `it`, `pt-BR`, `nl`, plus `en-GB` (override layer). LTR, well
supported by system fonts, largest combined market.

- [ ] **6.1** Run `translate-strings --locale es,fr,de,it,pt-BR,nl,en-GB`; commit the
  `.xcstrings` diff.
- [ ] **6.2** Placeholder-safety + drift report clean for these locales.
- [ ] **6.3** Per-locale screenshot harness (R3) over the key-screen set; review each for
  layout break / obvious mistranslation / untranslated leakage; fix.
- [ ] **6.4** Glossary conformance spot-check: product terms render per `Glossary.md` directive
  in each locale.
- [ ] **6.5** `en-GB` diff review — only genuine US/UK divergences carry an override; everything
  else inherits en-US.
- [ ] **6.6** Ship Tier 1. Record the release; open the feedback path (Phase 10) even if the
  rest is pending.

---

## Phase 7 — Tier 2: Nordic + Central/Eastern European

Locales: `sv`, `da`, `nb`, `fi`, `pl`, `cs`, `hu`, `ro`, `el`, `lt`, `sr-Cyrl`. Adds
Cyrillic (`sr-Cyrl`) and Greek scripts; `pl`/`ro` exercise the CLDR plural refactor hardest.

- [ ] **7.1** Run the translate script for the tier; commit.
- [ ] **7.2** Placeholder + drift clean.
- [ ] **7.3** Screenshot pass; **specifically verify plural forms** in `pl`, `ro`, `lt` on
  count-bearing strings (export count, task counts, backlink counts).
- [ ] **7.4** Greek + Cyrillic render correctly in system font and in the `.monospaced` editor.
- [ ] **7.5** Ship Tier 2.

---

## Phase 8 — Tier 3: CJK

Locales: `zh-Hans`, `ja`, `ko`. No spaces between words (line-break / truncation behavior
differs), denser glyphs, IME interaction with the editor.

- [ ] **8.1** Run the translate script; commit.
- [ ] **8.2** Placeholder + drift clean.
- [ ] **8.3** Editor check: `.body.monospaced()` coverage for CJK (G21) — if substitution looks
  wrong, fall that locale's editor back to proportional `.body`; document.
- [ ] **8.4** Line-break / truncation pass on list rows, chips (`TagChip`), nav titles — CJK
  wraps differently; confirm no mid-glyph clip.
- [ ] **8.5** IME sanity: wikilink/tag/`((`/`!((` autocomplete triggers still fire correctly
  when composing via a CJK input method (`activeWikilinkQuery` etc. read composed text).
- [ ] **8.6** Ship Tier 3.

---

## Phase 9 — Tier 4: RTL (Arabic)

Locale: `ar`. Decision G16 — full RTL, gated. Does not ship until this phase's layout and
editor work is complete.

- [ ] **9.1 Failing tests / pseudo-run first.** Under the RTL pseudolanguage and `ar`: sidebar,
  tab bar, toolbars, chevrons (`chevron.left`/`right` day-nav), and row layouts mirror; the
  sync glyph and disclosure indicators sit on the correct edge.
- [ ] **9.2** Audit every explicit `.left` / `.right` / `.leading` / `.trailing` in
  `Kontinuum/views/`; replace directional-but-not-semantic uses with `.leading`/`.trailing`;
  keep semantic ones (e.g. a deliberately LTR code block) with `.environment(\.layoutDirection, .leftToRight)`.
- [ ] **9.3** Custom / directional glyphs get `.flipsForRightToLeftLayoutDirection(true)` where
  they indicate direction; verify SF Symbols that auto-mirror do so.
- [ ] **9.4** Markdown editor + `DocumentPreviewView`: base writing direction follows the
  paragraph; a bidi run (English `[[Title]]` or `#tag` inside Arabic text) renders without
  reordering the sigils incorrectly. Verify `TextEditor` caret/selection behavior.
- [ ] **9.5** `JournalDayHeader` and day navigation: "previous" / "next" follow reading order
  (previous = right in RTL).
- [ ] **9.6** Run `translate-strings --locale ar`; commit.
- [ ] **9.7** Placeholder + drift clean; screenshot pass in `ar` over every screen.
- [ ] **9.8** Confirm numerals policy (Western vs Eastern Arabic-Indic) — accept the system
  default from the locale; don't force.
- [ ] **9.9** Ship Tier 4.

---

## Phase 10 — Drift Maintenance & Translation Feedback

Steady state after tiers ship.

- [ ] **10.1** "Report a translation issue" affordance (Settings → About, or a long-press on
  any label in a debug build → captures key + locale + screen + current value). Decide the
  delivery channel (email compose sheet vs. a note appended to a shared doc) — no server.
- [ ] **10.2** Document the release-time loop in `ARCHITECTURE.md`: on any en string change,
  CI drift warning → run `translate-strings` for affected locales → commit → screenshot spot
  check of touched screens.
- [ ] **10.3** Make the drift report a **release-checklist gate** (must be run and reviewed,
  even though per-PR it's non-blocking).
- [ ] **10.4** Quarterly: re-run the full translate script with the latest model to pick up
  quality improvements on `stale`-marked or low-confidence keys; diff-review.
- [ ] **10.5** Glossary review each time a new product term ships (e.g. from
  `NoteBytez20260829v1/v2` features — "Insights", "Command Palette", "Send to Canvas") — add
  it to `Glossary.md` before its strings are translated.

---

## Phase 11 — Verification Gate

- [ ] **11.1** All 24 locales compile; `xcodebuild build` for iOS + macOS destinations green.
- [ ] **11.2** Hardcoded-string lint: zero new offenders; baseline list only shrinking.
- [ ] **11.3** Drift report: 0 missing keys across all shipped tiers; `stale` count reviewed.
- [ ] **11.4** Pseudolocalization (Double-Length + RTL): no truncation or layout break on
  S1–S24.
- [ ] **11.5** `KontinuumTests` + `KontinuumUITests` + `../MarkdownG9` suites green, including
  the Phase-1 Unicode tests and the Phase-2 "no raw key visible" UI test.
- [ ] **11.6** `ARCHITECTURE.md`, `docs/styleGuide.md`, and `Docs/Localization/*` reflect the
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

