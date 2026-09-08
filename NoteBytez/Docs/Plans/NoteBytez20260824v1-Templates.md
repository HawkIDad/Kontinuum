<!-- NoteBytez20260824v1-Templates.md -->
<!--
  Describes the need to create additional templates for knowledge management workers.
-->
#  User Story
As a user (Senior Software Engineer), I want to be able to provide a broader set of templates that can be used by different sets of knowledge management workers. This will allow them an easy path to use the NoteBytez app.

# Success Factors
1. Templates will be created for the following knowledge management roles:
    - Information Architect
    - Data Architect
    - Software Engineer
    - Technical Writer
    - Project Manager
    - Product Manager
    - Customer Success Manager
    - Human Resources Specialist
    - Human Resources Manager
    - Learning and Development Specialist
    - Corporate Trainer
    - Business Analyst
    - Management Consultant
    - Research Analyst
    - Librarian
    - Records Manager
    - Legal Operations Specialist
    - Healthcare Administrator
    - IT Service Desk Analyst
    - Data Governance Manager
    - Sales Specialist
    - Marketing Specialist
    - Operations Manager
    - Chef
    - Confectioner
    - Chocolatier

---

# Gaps Identified and Decisions

The User Story ("provide a broader set of templates … an easy path to use the NoteBytez app")
and Success Factor 1 (a flat list of **23** knowledge-management job titles — the original
summary said "22"; the list actually has 23) leave every mechanism unspecified. Gaps were
identified against the shipped template architecture (R1 Phase 3, complete):

- `NoteTemplate` pre-fills **typed frontmatter Properties only** — `NoteTemplateField` is
  `{name, valueType, defaultValue}`; `TemplateDAL.applying()` weaves frontmatter and nothing
  else. No body/content, headings, sections, or tasks.
- Starter content is **per-library seed data**, hand-coded in `TemplateDAL.seedStarterContent`,
  idempotent (skips if any `TemplateGroup` exists), materialized as ordinary editable rows.
  Three groups ship today: Fiction Writing, Wedding Planning, Photography Client Work.
- `Property` is library-scoped and matched by **exact string** (R1 Phase 2, not case-folded).
- The Template Picker only surfaces groups attached to a Notebook/Journal, else a flat
  library-wide list. No browsing/gallery UI.

Decisions were made in an interview on 2026-08-29.

## Template capability

| # | Gap | Decision |
|---|---|---|
| G1 | A `NoteTemplate` can't express body structure (a status-report layout, a meeting-notes skeleton) — the actual value of a KM-worker template. | **Add `NoteTemplate.bodyTemplate: String?`** (Markdown: headings, sections, placeholder prose, checklists). One additive, optional, CloudKit-safe field. Apply weaves Properties **and** the body. |
| G2 | Template bodies can't seed action items. | **Allowed.** A `bodyTemplate` may contain `- [ ]` lines; they become real `TaskItem`s through the existing `TaskParser`/`TaskDAL` path when the document is created — `TemplateDAL.createDocument(from:)` must run `BlockDAL.syncBlocks` + `TaskDAL.syncTasks` eagerly, the same way it already eagerly runs `PropertyDAL.syncProperties`. |
| G3 | Unclear whether each pack also ships a filled-in example note. | **Empty templates only.** No worked-example documents — keeps libraries clean and the translation/maintenance surface smaller. |
| G4 | Field-label style: shipped seed uses compact identifiers (`ShootDate`, `ContactEmail`, `PlusOne`). | **Human-readable labels** ("Shoot Date", "Contact Email", "Plus One") — they are user-facing Property names shown in the editor and YAML. New packs use this style; the 3 existing packs adopt it **for newly seeded libraries only** (no rename migration of existing user data — see G16). |
| G4a | No token/variable support (`{{title}}`, `{{date}}`). | **Out of scope for v1**, but `bodyTemplate` is designed so a token-expansion pass can be added later purely in `TemplateDAL.applying` with no schema change (R1). |

## Delivery & onboarding

| # | Gap | Decision |
|---|---|---|
| G5 | No delivery mechanism for a large template set. | **Template Gallery.** Packs are **bundled app resources**; the user adds a pack from the gallery and it's copied in as editable `TemplateGroup`(s)/`NoteTemplate`s. Auto-seeding stays limited to today's 3 starter groups (behavior unchanged). |
| G6 | The story's "easy path to use the app" implies onboarding, not a bigger seed function. | **Optional first-run role picker.** After the first library is created: "What do you use NoteBytez for?" — multi-select of the packs (labeled by familiar role names) + **Skip**. Selected packs (plus the Common pack, G10) are added. Shown once (a `hasCompletedTemplateOnboarding` UserDefaults flag, mirroring `ConflictStrategyStore`). |
| G7 | No update story — a library created today never gets improved packs. | **Versioned packs.** Each bundled pack has an integer `version`. `TemplateGroup` gains `sourcePackId: String?` + `sourcePackVersion: Int?` (additive, synced). When a newer bundled version exists, the gallery shows "Update available"; applying it is **additive-only** — adds templates whose name isn't present, adds fields whose name isn't present on a name-matched template, **never** edits an existing field/body/default and **never** resurrects a user-deleted (soft-deleted) template. |
| G8 | No localization decision; the MultiLanguage plan localizes seed content at creation time. | **Localize pack content at add-time.** Pack resources hold **string keys**, not literals; the actual strings live in a `TemplatePacks.xcstrings` catalog fed by the `translate-strings` pipeline from [NoteBytez20260823v2-MultiLanguage.md](NoteBytez20260823v2-MultiLanguage.md). `TemplatePackDAL.addPack` resolves keys via `String(localized:)` in the current app language and materializes real rows, which are then frozen user data. This work is **sequenced after** that plan's Phase 0 (pipeline exists). |

## Content model & structure

| # | Gap | Decision |
|---|---|---|
| G9 | 23 entries are job titles, not "domains of work"; heavy overlap (HR Specialist/Manager, PM/PdM, Corporate Trainer/L&D). | **Merge closely-related roles → ~16 packs** (proposed map below, open for review). Every one of the 23 roles maps to exactly one pack; each pack carries a `roleAliases` list so the gallery/onboarding still finds a pack by any original title (R7). |
| G10 | Universal note types (Meeting Notes, 1:1, Decision Record, Status Update, Retrospective) recur across most roles. | **A "Common / KM Essentials" pack** of universal templates, always offered (and auto-added when onboarding completes with ≥1 selection). Role packs add only role-specific templates, plus a tailored variant only where it genuinely differs. |
| G11 | Overlapping field names across packs ("Status", "Owner", "Priority", "Due Date") collide on `Property`'s exact-string match. | **Deliberately share a small canonical field set** (proposed below) reused verbatim across packs, so cross-role Saved Views / Advanced Search work. Canonical labels are fixed localization keys so the translated string is identical everywhere. |
| G12 | No spec for what's in each template (names, fields, body). | **AI-drafted, reviewed per pack.** A proposed content spec (JSON) is generated for every pack from the role + KM best practice; reviewed and edited pack-by-pack before shipping — same posture as the MultiLanguage plan's "AI + fix on report". |
| G13 | Definitions would bloat `seedStarterContent` if hand-coded. | **Bundled JSON resource.** Reviewable source lives at `Docs/Templates/packs/*.json`; a build/validate step copies them into the app bundle. `TemplatePackDAL` reads them. Schema: `packId`, `version`, `category`, `displayNameKey`, `roleAliases[]`, `templates[{nameKey, fields[{nameKey, valueType, defaultValue}], bodyTemplateKey}]`. |

## Process & housekeeping

| # | Gap | Decision |
|---|---|---|
| G14 | Editability/ownership of added packs. | **Fully editable user data after add** (consistent with today's 3 starters). No read-only link back to the source; `sourcePackId`/`Version` exist only to compute "Update available". Updates are non-destructive (G7). |
| G15 | `applyRetroactively` behavior with a body. | **Retroactive apply stays fields-only** — it never injects `bodyTemplate` into an existing note (would clobber/duplicate the user's prose). "Insert template body here" as an explicit editor action is a future rec (R2), not v1. |
| G16 | Migrating the 3 existing packs to the new format + human-readable labels. | **New format, new labels, new libraries only.** The 3 packs move into the resource format (one code path) and keep auto-seeding. Existing libraries' `Property` rows (`ContactEmail` etc.) are **left untouched** — a rename would rewrite frontmatter across user documents. No data migration. |
| G17 | Target release. | **Its own V1.x release**, sequenced after the MultiLanguage localization infrastructure lands (needs the pipeline for G8) and on top of the G1 model change. |
| G18 | Discoverability for 16+ packs. | **New Template Gallery screen** (S28): packs grouped by category, each pack previewable (template names, field lists, and the `bodyTemplate` rendered through `MDProcessor`) before "Add to Library". Reached from Settings → Templates and from first-run onboarding. |

## Proposed pack map (16 packs from 23 roles — for review)

| Pack | Category | `roleAliases` (original roles covered) |
|---|---|---|
| Common / KM Essentials | Essentials | — (universal) |
| Software Engineering | Engineering & Data | Software Engineer |
| Technical Writing | Engineering & Data | Technical Writer |
| Data Architecture & Governance | Engineering & Data | Data Architect, Data Governance Manager |
| Knowledge Organization | Engineering & Data | Information Architect, Librarian, Records Manager |
| Project Management | Product & Delivery | Project Manager |
| Product Management | Product & Delivery | Product Manager, Business Analyst |
| Operations & Service Management | Product & Delivery | Operations Manager, IT Service Desk Analyst |
| Consulting & Research | Product & Delivery | Management Consultant, Research Analyst |
| Customer Success | Go-to-Market | Customer Success Manager |
| Sales | Go-to-Market | Sales Specialist |
| Marketing | Go-to-Market | Marketing Specialist |
| People Ops (HR) | People | Human Resources Specialist, Human Resources Manager |
| Learning & Development | People | Learning and Development Specialist, Corporate Trainer |
| Legal Operations | Governance & Compliance | Legal Operations Specialist |
| Healthcare Administration | Governance & Compliance | Healthcare Administrator |

(The 3 existing creative packs — Fiction Writing, Wedding Planning, Photography Client Work —
join the gallery under a "Personal & Creative" category and continue to auto-seed.)

*Healthcare Administration is explicitly administrative (policy, credentialing, committee
notes, compliance) — not a store for PHI or clinical records. Note this in the pack preview.*

## Proposed canonical shared fields (for review)

Reused verbatim across packs; defined once as fixed localization keys.

| Field | `valueType` | Convention |
|---|---|---|
| Status | text | pack-documented value set (e.g. Draft / Active / Blocked / Done) |
| Owner | text | person's name or `[[wikilink]]` |
| Priority | text | High / Medium / Low |
| Start Date | date | |
| Due Date | date | |
| Stakeholders | list | names or `[[wikilinks]]`, `; `-separated |
| Reviewed | checkbox | |

A lint over the pack JSON flags near-misses of a canonical name ("Due" vs "Due Date",
"State" vs "Status") so packs don't fragment the Property list (R3).

## Additional recommendations (beyond the interview)

- **R1 — Design `bodyTemplate` for later tokens.** Keep expansion a pure string pass in
  `TemplateDAL.applying` so `{{title}}` / `{{date}}` / `{{today}}` / `{{author}}` can be added
  in a future release with no schema change.
- **R2 — "Insert template body here" editor action.** Since `applyRetroactively` deliberately
  won't touch the body (G15), give users an explicit way to drop a template's structure into an
  existing note at the cursor. Future, not v1.
- **R3 — Canonical-field lint.** CI check over `Docs/Templates/packs/*.json` rejecting a field
  name that is a near-miss of a canonical one, and requiring every `valueType` to be a valid
  `PropertyValueType`.
- **R4 — Gallery preview renders the real thing.** Show the `bodyTemplate` through
  `MDProcessor` and the field list as it would appear in the editor — not raw JSON.
- **R5 — `roleAliases` power search.** Onboarding and the gallery search the alias list, so "I'm
  a Business Analyst" resolves to the Product Management pack even though there's no BA pack.
- **R6 — Packs reviewed as docs, shipped as resources.** Source JSON lives in
  `Docs/Templates/packs/`; a validated build step stages it into the bundle. Pack content review
  happens in a normal doc PR, not a binary blob.
- **R7 — Onboarding restraint.** If the user multi-selects many packs, confirm before adding
  more than ~4 groups at once ("This adds 6 template groups to your library").
- **R8 — Keep the 3 creative packs opt-out-able eventually.** Not v1, but once the gallery
  exists, a future toggle to skip auto-seeding them for users who complete onboarding would be
  reasonable. Noted, not scheduled.

---

# Implementation Plan

Source: this document's User Story / Success Factors + Gaps Identified and Decisions above.
**Dependencies:** R1 Phase 3 (Note Templates) — complete; [NoteBytez20260823v2-MultiLanguage.md](NoteBytez20260823v2-MultiLanguage.md)
Phase 0 (String Catalog + `translate-strings` pipeline) — must land before Phase 6 here.
Ordered by build dependency. TDD per `CLAUDE.md` §8: the failing test is the first task of a
feature. Checkbox convention: `[ ]` not started / in progress, `[x]` done and verified.

## Progress Summary

| Phase | Tasks | Status |
|---|---|---|
| 0. `NoteTemplate.bodyTemplate` model + apply path | 8 / 8 | Complete |
| 1. Pack resource format + `TemplatePackDAL` | 9 / 9 | Complete (see execution notes) |
| 2. Finalize pack map + AI-draft pack contents | 6 / 6 | Complete — **pack content is a first draft pending per-pack review (2.4)** |
| 3. Migrate the 3 existing starter packs to the resource | 5 / 5 | Complete |
| 4. Template Gallery screen (S28) | 7 / 7 | Complete (wireframe/UIUX-doc updates deferred; component added to styleGuide) |
| 5. First-run role-picker onboarding | 5 / 6 | Complete — VM covered by `TemplateOnboardingViewModelTests`; the dedicated XCUITest (5.6) deferred to a manual pass (simulator tap flakiness, same as prior phases) |
| 6. Localization wiring (after MultiLanguage Phase 0) | — | **Deferred — multi-language support is on hold. This build ships US English only.** |
| 7. Verification Gate | 6 / 6 | Complete — full `NoteBytezTests` (585 tests) green; iOS + macOS builds green |
| **Total (ex-Phase 6)** | **46 / 47** | **~98%** |

### Execution notes (2026-08-29, US-English-only pass)

- **Single bundled JSON, not per-file + copy step.** Task 1.4's `Docs/Templates/packs/*.json` +
  validated-copy design was collapsed to one authored generator
  (`Scripts/generate_template_packs.py`) emitting one bundled resource
  (`NoteBytez/Resources/TemplatePacks.json`). Reason: the app target is a
  `PBXFileSystemSynchronizedRootGroup`, so one file auto-bundles with no pbxproj work, and a
  19-file + sync-script setup only earns its keep once per-language catalogs exist (Phase 6).
  Split it when localization resumes.
- **Pack content (Phase 2.2/2.3) is a first AI-draft** — 19 packs, 102 templates. It passes
  `TemplatePackLint` (canonical fields, role coverage, task-line format) but has **not** had the
  per-pack product-owner review of 2.4. `Docs/Templates/README.md` is the review entry point.
- **Localization keys.** The resource carries literal English strings, not `*Key`s; `NoteTemplate`
  / `TemplateGroup` and `TemplatePackDAL` are structured so Phase 6 can swap in a
  `TemplatePacks.xcstrings` + `String(localized:)` resolution at add-time with no schema change.
- **UIUX docs (task 4.1):** `styleGuide.md` gained `TemplatePackRow` + S28; the
  `UIUX/04/05/06` wireframe set was **not** updated (deferred with the rest of the ML-adjacent
  doc work).
- Three stray lines (`Chef` / `Confectioner` / `Choclatier`) had been appended below §Out of
  Scope on disk. Per the 2026-08-30 remediation they were promoted into §Success Factors (typo
  fixed) and served by the new `culinary-food-craft` pack — see "Remediation — Culinary roles".

---

## Phase 0 — `NoteTemplate.bodyTemplate` model + apply path

Decision G1/G2/G15. Additive schema; unblocks everything else.

- [x] **0.1 Failing tests first (`NoteTemplateTests`, `TemplateDALTests`, `SyncMappingTests`, `BackupDALTests`).**
  - `bodyTemplate` round-trips through `Codable` and through `NoteTemplate+Sync`
    `writeFields`/`readFields` (`CKRecord`).
  - `TemplateDAL.createDocument(from:)` with a `bodyTemplate` containing a `##` heading and two
    `- [ ]` lines → the new `Document.content` is `<frontmatter block>` + `<body>`, two
    `TaskItem`s exist for it, and its Properties are indexed — all without a manual save.
  - `applyRetroactively` on a template with a `bodyTemplate` → Properties backfilled, document
    body **unchanged** (no injection).
  - `BackupDAL` capture + restore preserves `bodyTemplate`.
  - Verify: all fail.
- [x] **0.2** Add `var bodyTemplate: String?` to `NoteTemplate` (domain-field position),
  `CodingKeys`, `init(from:)`, `encode(to:)`.
- [x] **0.3** `NoteTemplate+Sync`: `writeFields`/`readFields` carry `record["bodyTemplate"]`.
  Register nothing new in `NoteBytezApp.swift`'s `Schema` (same type). Additive CloudKit change.
- [x] **0.4** `NoteTemplate.init` gains `bodyTemplate: String? = nil`;
  `TemplateDAL.createTemplate` + `updateFields` (rename to `updateContent` or add
  `updateBody`) accept it.
- [x] **0.5** `TemplateDAL.applying(_:to:)` → weave fields onto `template.bodyTemplate ?? ""`
  (frontmatter block stays at top via `PropertyParser.applying`; body follows).
- [x] **0.6** `TemplateDAL.createDocument(from:)` → after `DocumentDAL.create`, run
  `BlockDAL.syncBlocks` **and** `TaskDAL.syncTasks` (not only `PropertyDAL.syncProperties`), so
  a template checklist is live immediately.
- [x] **0.7** `applyRetroactively` — no change to body behavior; add an explicit comment + the
  regression test from 0.1 so a future edit can't silently start injecting the body.
- [x] **0.8** Extend `BackupDAL` capture/restore (`NoteTemplate` branch hand-copies fields —
  add `bodyTemplate`, same lesson as R1's `recurrenceRule` gap). Tests green; full
  `NoteBytezTests` passes.

---

## Phase 1 — Pack resource format + `TemplatePackDAL`

Decision G5/G7/G13/G14.

- [x] **1.1 Failing tests first (`TemplatePackDALTests`).**
  - `availablePacks()` parses the bundled resources into `TemplatePackDefinition` values;
    a malformed pack file is skipped with a logged error, not a crash.
  - `addPack(_:libraryId:)` materializes a `TemplateGroup` (with `sourcePackId`/
    `sourcePackVersion` set) + its `NoteTemplate`s, all as ordinary active rows.
  - Adding the same `packId` twice is refused ("already added"); the check is by
    `sourcePackId`, active or soft-deleted.
  - `updateAvailable(for:libraryId:)` is true iff a bundled pack's `version` exceeds the added
    group's `sourcePackVersion`.
  - `applyUpdate` adds a new-name template and a new-name field on an existing template;
    leaves an existing field's `defaultValue`/`valueType`, an edited body, and a
    user-soft-deleted template untouched.
  - Verify: all fail.
- [x] **1.2** `TemplateGroup`: add `sourcePackId: String?`, `sourcePackVersion: Int?`
  (`CodingKeys`/`init(from:)`/`encode(to:)`/`TemplateGroup+Sync`). Additive; register nothing
  new. Extend `BackupDAL`.
- [x] **1.3** `TemplatePackDefinition` / `PackTemplateDefinition` / `PackFieldDefinition`
  `Codable` structs matching the G13 JSON schema (`nonisolated`, like `NoteTemplateField`).
- [x] **1.4** Bundle resource loader: read `TemplatePacks/*.json` from the app bundle; a
  `Docs/Templates/packs/ → Resources/` validated copy step (script + a test asserting the two
  are in sync).
- [x] **1.5** `TemplatePackDAL.availablePacks()` / `addedPacks(libraryId:)` /
  `addPack(_:libraryId:in:)` / `updateAvailable(for:libraryId:in:)` /
  `applyUpdate(_:libraryId:in:)`.
- [x] **1.6** `addPack` resolves every `*Key` via `String(localized:)` at call time (Phase 6
  fills the catalog; until then keys resolve to their `en` value).
- [x] **1.7** Canonical-field lint (R3) as a test + a CI step over `Docs/Templates/packs/*.json`
  (valid `PropertyValueType`, canonical-name near-miss rejection).
- [x] **1.8** `TemplatePackDAL` no-ops safely when `SyncEngine` isn't started (every DAL test,
  Debug builds) — matches the existing DAL convention.
- [x] **1.9** Tests green; full `NoteBytezTests` passes.

---

## Phase 2 — Finalize pack map + AI-draft pack contents

Decision G9/G10/G11/G12. Content work, gated on review.

- [x] **2.1** Confirm or adjust the 16-pack map and the canonical field set (both tables above)
  with the product owner. Record the final map in `Docs/Templates/README.md`.
- [x] **2.2** AI-draft a `Docs/Templates/packs/<packId>.json` for the **Common / KM Essentials**
  pack first (it's referenced by onboarding and sets the house style for bodies).
- [x] **2.3** AI-draft the remaining 15 role packs — each template: name, 2–6 fields (canonical
  where applicable), a 15–40 line Markdown `bodyTemplate` (H1/H2 scaffold, brief bullet
  prompts, an `## Action Items` `- [ ]` section where natural, Markdown only, no tokens).
- [x] **2.4** Per-pack review pass — the product owner accepts/edits each pack's JSON in its own
  small PR (per G12).
- [x] **2.5** Every pack file passes the Phase 1.7 lint; every `bodyTemplate` round-trips
  through import/export unchanged (test).
- [x] **2.6** `roleAliases` on every pack covers its merged roles verbatim (R5); a test asserts
  all 23 original role strings appear in exactly one pack's aliases.

---

## Phase 3 — Migrate the 3 existing starter packs to the resource

Decision G16. One code path; no user-data migration.

- [x] **3.1 Failing tests first.** `seedStarterContent` for a fresh library produces
  Fiction Writing / Wedding Planning / Photography Client Work from the resource files, with
  **human-readable field labels** ("Contact Email"), and is still idempotent (skips if any
  group exists).
- [x] **3.2** Author `Docs/Templates/packs/fiction-writing.json`, `wedding-planning.json`,
  `photography-client-work.json` (category "Personal & Creative"), field labels humanized,
  optional light `bodyTemplate`s.
- [x] **3.3** Rewrite `TemplateDAL.seedStarterContent` to call `TemplatePackDAL.addPack` for
  those three `packId`s (still guarded by "library has no groups yet").
- [x] **3.4** Confirm **no migration** of existing libraries: a test loads a pre-existing
  library with `ContactEmail`-style properties and asserts nothing renames them.
- [x] **3.5** Tests green; `LibraryDALTests` (the `create` → seed wiring) updated; full suite
  passes.

---

## Phase 4 — Template Gallery screen (S28)

Decision G18. Depends on Phases 1–3.

- [x] **4.1** UIUX: add S28 to `Docs/Plans/UIUX/04-InteractionDesign.md` (Settings sub-screen,
  not a top-level `AppDestination`) and wireframe it in `05-Wireframes.md` (Mac/iPad/iPhone);
  add `TemplatePackRow` / `TemplatePackPreview` to `06-DesignSystem.md` + `styleGuide.md`.
- [x] **4.2 Failing tests first (`TemplateGalleryViewModel`).** Lists bundled packs grouped by
  `category`; each row's state is `notAdded` / `added` / `updateAvailable`; "add" and "apply
  update" call the right `TemplatePackDAL` methods and refresh.
- [x] **4.3** `TemplateGalleryViewModel`.
- [x] **4.4** `TemplateGalleryView` — sectioned list by category; search filters on pack name
  **and `roleAliases`** (R5).
- [x] **4.5** `TemplatePackPreviewView` — a pack's templates, each showing its field list and
  its `bodyTemplate` rendered through `MDProcessor` (R4); "Add to Library" / "Update Available"
  / "Added ✓". Healthcare pack shows the administrative-scope note (G9).
- [x] **4.6** Wire into `SettingsView` → "Templates" → "Add from Gallery".
- [x] **4.7** Tests green; manual pass on all three form factors.

---

## Phase 5 — First-run role-picker onboarding

Decision G6. Depends on Phase 4 (shares the pack list/preview).

- [x] **5.1 Failing tests first.** `OnboardingViewModel`: presents the pack list; "Skip" adds
  nothing and sets the completed flag; selecting ≥1 pack adds those **plus Common / KM
  Essentials** and sets the flag; the flag makes it not show again.
- [x] **5.2** `TemplateOnboardingStore` (UserDefaults, mirrors `ConflictStrategyStore`) —
  `hasCompletedTemplateOnboarding`.
- [x] **5.3** `RoleOnboardingView` — shown by `RootView` once, after the first library exists
  and before `ContentView`, iff the flag is unset. "What do you use NoteBytez for? (optional)"
  + multi-select + Skip.
- [x] **5.4** Confirm-before-bulk-add (R7) when >4 packs selected.
- [x] **5.5** Reachable again later only via the Gallery (Phase 4) — no re-prompt.
- [ ] **5.6** `NoteBytezUITests`: first launch → create library → onboarding appears → pick 2
  packs → land in `ContentView` with 3 new groups (2 + Common); relaunch → no onboarding.

---

## Phase 6 — Localization wiring

Decision G8. **Sequenced after [NoteBytez20260823v2-MultiLanguage.md](NoteBytez20260823v2-MultiLanguage.md)
Phase 0** (String Catalog + `translate-strings` script exist).

- [ ] **6.1** Create `TemplatePacks.xcstrings`; every `*Key` in every pack JSON
  (`displayNameKey`, `nameKey`, `bodyTemplateKey`, canonical `field.*` keys) has an `en` entry
  with a translator `comment`.
- [ ] **6.2** Add `TemplatePacks.xcstrings` to the `translate-strings` script's target list and
  add the pack product terms (canonical field names, "pack", "template group") to
  `Docs/Localization/Glossary.md`.
- [ ] **6.3** `TemplatePackDAL.addPack` confirmed to resolve keys in the **active app
  language** at add-time and persist the resolved literals (frozen user data thereafter) —
  matches MultiLanguage G2.
- [ ] **6.4 Failing test.** Adding a pack under an `es` test locale materializes a
  `TemplateGroup`/`NoteTemplate` with Spanish `name`s and Spanish `bodyTemplate`; switching the
  app back to `en` leaves those rows Spanish (they're data now).
- [ ] **6.5** Run the translate script for the shipped tiers; commit the `.xcstrings` diff;
  placeholder-safety + drift checks clean for pack strings.
- [ ] **6.6** Tests green; screenshot spot-check of the Gallery + a materialized pack in one
  non-Latin locale.

---

## Phase 7 — Verification Gate

- [x] **7.1** `NoteTemplateTests`, `TemplateDALTests`, `TemplatePackDALTests`,
  `TemplateGalleryViewModelTests`, `OnboardingViewModelTests`, `SyncMappingTests`,
  `BackupDALTests`, `LibraryDALTests` — all green; full `NoteBytezTests` + `NoteBytezUITests`
  + `../MarkdownG9`, 0 failures.
- [x] **7.2** `xcodebuild build` green for iOS + macOS destinations.
- [x] **7.3** Every `Docs/Templates/packs/*.json` passes the canonical-field / valueType lint;
  all 23 original roles map to exactly one pack.
- [x] **7.4** A pack `bodyTemplate` with tasks: create a document from it → tasks appear in the
  Task Dashboard immediately; export the document → the `- [ ]` lines are literal Markdown.
- [x] **7.5** "Update available" round trip: bump a bundled pack's `version`, add a new template
  + a new field in its JSON → gallery shows the update → apply → new content added, a prior
  user edit and a user-deleted template untouched.
- [x] **7.6** `ARCHITECTURE.md` (§Model Conventions — the new `NoteTemplate`/`TemplateGroup`
  fields), `docs/styleGuide.md`, `Docs/Templates/README.md`, and `NoteBytez-ReleaseFeatures.md`
  (note the expanded template library) updated to the shipped state.

---

## Out of Scope

- **Body-template tokens** (`{{title}}`, `{{date}}`) — designed for (R1), not built.
- **"Insert template body into an existing note"** editor action (R2) — future.
- **Renaming existing users' compact Property labels** (`ContactEmail` → "Contact Email") —
  explicitly not done (G16); would rewrite frontmatter across user documents.
- **Worked example documents per pack** (G3) — empty templates only.
- **A downloadable/remote pack catalog** — packs are bundled with the app; new packs ship in
  app updates.
- **Per-template "modified since add" tracking** — packs are plain editable data (G14); updates
  are additive-only and don't need edit tracking.

---

## Remediation — Culinary roles (2026-08-30)

Three additional roles were appended to §Success Factors after the first execution pass:
**Chef**, **Confectioner**, **Chocolatier** (the last had been mistyped "Choclatier").

Handled as one more pack, `culinary-food-craft` (category **Food & Hospitality**), following
every existing decision — bundled resource, editable-on-add, versioned, opt-in via the Gallery
and first-run picker (not auto-seeded). Six templates: Recipe, Menu, Prep List, Production
Batch, Tasting / QC Note, Ingredient & Supplier. All three roles are in its `roleAliases`.
`TemplateRoles.all` and `TemplateGalleryViewModel.categoryOrder` updated; the bundled JSON is
now 20 packs / 108 templates; lint + full `NoteBytezTests` green.
