<!-- WebSite20260919v1-WebSite.md -->
<!--
  Base instructions to create a public facing website that can be used by potential users of the NoteBytez app to investigate and understand the capabilities of the application, and by actual users of the application to learn how to use the features within the application.
  User Story + Success Factors + Implementation Plan rebuilt from the 2026-09-19 interview (3 rounds).
  The how-to subsection is defined by wiki20260907v1-Phase1.md (Article Standard, Personas, Feature Inventory, Derived Style Guide deltas); this plan does not duplicate it.
-->
# User Story
As the Product Manager of the NoteBytez application, I want to generate a website that I can then load to my hosting provider that will provide a public facing location for potential users and actual users.

    - Potential Users: Will use the website to learn about NoteBytez — what it is, who it is for, what it costs, and how to get it — and understand how the application will allow them to structure and organize their notes.
    - Actual NoteBytez Users: Will use the website to learn how to use the features of the NoteBytez application. The website will describe the various features along with instructions on how the user can execute those functions within the application (the "Help" subsection, defined by wiki20260907v1-Phase1.md).

## Scope

| In scope | Out of scope |
|---|---|
| One static site under `WebSite/`, built with Eleventy + Pagefind | Choice of host and domain (build is host-agnostic) |
| Marketing pages: Home / value proposition, Features overview, Pricing / Subscription | Compare / switch-from landing pages, About, Changelog |
| Support pages: Privacy Policy, Terms of Use / EULA, Support / Contact | Analytics of any kind |
| Help subsection: every how-to, journey, concept, and reference page from wiki20260907v1-Phase1.md | In-app contextual Help links (`helpURL(for:)`, Wiki Phase 1.8) — separate follow-up work |
| Site-wide search (Pagefind), `llms.txt`, sitemap, schema.org | Video, iPad screenshots, translated locales |
| Screenshots from the Wiki Simulator seed-library pipeline | Device-framed marketing shots |

## Decisions (from interview)

| # | Topic | Decision |
|---|---|---|
| D1 | Wiki vs Site | **One site in `WebSite/`.** The Wiki plan's `Wiki/` paths are remapped: `Wiki/site/` → `WebSite/site/`, `Wiki/content/en/` → `WebSite/content/en/`, `Wiki/docs/` → `WebSite/docs/`. Help lives at `/en/help/<category>/<slug>/`. |
| D2 | Stack | **Eleventy (MIT) + Pagefind (MIT)**, plain semantic HTML, no client framework (Wiki DD1). |
| D3 | Style guide | **Derived web guide** at `WebSite/docs/styleGuide.md`, built from the Wiki plan's WCAG 2.2 AA delta table; `NoteBytez/Docs/styleGuide.md` is the parent. |
| D4 | Quality gates | Wiki SF3 + SF4 apply to **every page** (marketing included); SF1 + SF2 apply to the Help subsection. |
| D5 | Marketing measure | No analytics. Every marketing page carries a clear App Store CTA; a prospect can answer *what is it / who is it for / what does it cost / how do I get it* within 2 clicks. |
| D6 | Host, domain, App Store URL, price, trial length | **Deferred.** Placeholders in a single `WebSite/site/_data/site.json`; pages read from it. Pricing page describes trial, lapse behaviour, and read-only export without hard numbers until finalised. |
| D7 | In-app Help links | Out of scope; the site guarantees stable permalinks + unique `featureSlug` so the follow-up can consume them. |
| D8 | Media | Reuse the Wiki screenshot pipeline (Simulator seed library; iPhone 17 Pro + "My Mac"; light + dark); marketing images come from the same set. |
| D9 | Search / SEO scope | Pagefind index and `llms.txt` cover the **whole site**. |
| D10 | Content ownership | User-facing only; `NoteBytez/Docs/Plans/**` is never published. Release-gate (`appliesTo` bump) from Wiki R5 applies to Help articles. |

# Success Factors
Done when **all** pass. Each maps to a verification gate in the Implementation Plan.

1. **Structure.** The website is constructed under the `WebSite/` folder (`site/`, `content/en/`, `docs/`) and builds host-agnostically to `WebSite/site/_site/`; loading that folder to a hosting provider requires no code changes beyond `site.json` values.
2. **Prospect clarity.** Home, Features, and Pricing exist; each carries the App Store CTA; a prospect can answer *what / who / cost / how to get it* within 2 clicks (checked by a written walkthrough, no analytics).
3. **Help content coverage (Wiki SF1).** 100% of the Wiki Feature Inventory has published how-to articles meeting the Article Standard; four persona journeys complete; concept/reference pages published; zero orphan pages; structure lint and link-check clean.
4. **Task completion (Wiki SF2).** 5 participants, Help-only, ≥ 80% task completion; failures fixed and re-tested. The fixed task list includes at least two prospect tasks (find cost; find what sync does).
5. **Accessibility (Wiki SF3), whole site.** WCAG 2.2 AA, zero violations; `axe-core` + Lighthouse Accessibility ≥ 95 on every page in CI; manual keyboard / VoiceOver / NVDA / zoom / reduced-motion / forced-colors pass signed off.
6. **SEO / AI retrieval (Wiki SF4), whole site.** Valid schema.org (`HowTo`, `TechArticle`, `BreadcrumbList`, `WebSite`+`SearchAction`, `FAQPage` where Q&A-shaped), `sitemap.xml`, `robots.txt`, canonicals, OG/Twitter, site-wide `llms.txt`, no-JS readable, Lighthouse SEO and Best Practices ≥ 95 on every page.
7. **Style guide.** The site uses the derived `WebSite/docs/styleGuide.md`, reviewed line-by-line against `NoteBytez/Docs/styleGuide.md` with every WCAG 2.2 AA mapping present.
8. **Legal / support readiness.** Privacy Policy, Terms of Use / EULA, and Support / Contact are published and linked from every page footer; the Privacy Policy states the local-first + CloudKit data model and that the site uses no analytics or cookies.

# Implementation Plan
Reuse the Wiki plan's phases for Help content; this plan adds the marketing/legal layer and remaps paths. No behavioural app code changes, so TDD applies to build tooling only (lint, schema checks, link check written first and run red against seed content). Each phase must pass its verify step.

Legend: **[x]** done and verified · **[ ]** open. Status as of 2026-09-19.

### Phase W0 — Reconcile plans — DONE
- [x] Note in `wiki20260907v1-Phase1.md` that `Wiki/` paths map to `WebSite/` (D1) and Phase 1.8 is deferred (D7). One remap note at the top of the file covers every `Wiki/` reference.
- [x] Create `WebSite/site/_data/site.json` (site name, base URL, App Store URL, price, trial length; later also tagline, publisher, support email).
- [x] → **verify:** no remaining `Wiki/` path references in active plan steps without the remap note.

### Phase W1 — Foundations (= Wiki 1.0) — DONE
- [x] Eleventy project at `WebSite/site/`; Pagefind post-build; layout `WebSite/content/en/`, `WebSite/docs/`.
- [x] Promote the derived style guide to `WebSite/docs/styleGuide.md`.
- [x] → **verify:** empty build succeeds; Pagefind runs; style guide reviewed against app guide (all 11 WCAG 2.2 AA rows present).

### Phase W2 — Information architecture — DONE except sign-off
- [x] Top nav: Home · Features · Pricing · Help · Support; footer: Privacy · Terms · Support (`_data/nav.json`).
- [x] URL scheme and front-matter schemas (`featureMap.json`, help + marketing JSON Schemas, `npm run lint`).
- [x] → **verify:** every Feature Inventory row maps to ≥ 1 slug (98 slugs, 21 categories); every marketing page is in nav or footer; lint enforced.
- [ ] Taxonomy sign-off by the product owner.

### Phase W3 — Templates & components (= Wiki 1.2, plus marketing) — DONE except external validator
- [x] Help layouts (howto, concept, reference, journey) and components (admonition, screenshot figure, Applies-to badge, persona chip, pager, breadcrumb, skip link, Pagefind search).
- [x] `marketing` layout (hero, feature grid, CTA from `site.json`, FAQ), `legal` layout, Features → Help deep-link component.
- [x] → **verify:** axe + Lighthouse ≥ 95 (a11y, SEO, Best Practices) on sample pages of every layout; JSON-LD structurally valid.
- [ ] Run Google's Rich Results Test on a sample of pages (external tool; our check is structural only).

### Phase W4 — Screenshot pipeline (= Wiki 1.3) — DONE for iPhone; Mac window capture built
- [x] Seed library (`tools/screenshots/seedLibrary/`), capture script (`capture.sh`), naming/retina convention (styleGuide.md), output to `WebSite/content/en/_assets/`.
- [x] DEBUG launch seams in the app: `SeedScreenshotLibrary` / `SeedScreenshotNotes`, `ScreenshotDestination`, `ScreenshotAppearance`, `ResetTemplateOnboarding` (unit-tested).
- [x] Mac window capture (`screencapture -l`, environment-based launch, appearance set in-app).
- [x] → **verify:** iPhone `notebooks` category byte-identical over 3 runs (light + dark). Mac: visually stable, not byte-stable (liquid-glass controls).
- [ ] Re-verify byte stability on a clean machine.

### Phase W5 — Marketing & support content — DONE except counsel review
- [x] Home, Features overview, Pricing (values from `site.json`, no numbers while placeholders), Support.
- [x] Privacy Policy and Terms of Use / EULA rendered from the in-app v1.0 legal text (single source of truth), plus a website addendum (no analytics, no cookies).
- [x] → **verify:** walkthrough (`docs/prospectWalkthrough.md`); footer links + App Store CTA checked on every page (`npm run check:pages`).
- [ ] Counsel confirms the legal text before publish.
- [ ] Fill `site.json`: App Store URL, price, trial length, support email, base URL.

### Phase W6 — Help content authoring (= Wiki 1.4) — DONE
- [x] 98 how-tos, 4 journeys, 5 concept pages, 4 reference pages; generated category and Help hubs; internal-link pass.
- [x] → **verify:** coverage 100% of the feature map; structure lint (Purpose, Prerequisites, Steps, Expected result, Related) passes; 131 pages with no broken internal links and no orphans (`npm run check:links`).
- Notes: five features have no in-app control (due dates/priority, recurrence, attaching a template group to a notebook or the journal, property filter, removing a note from a notebook); their pages say so.
- [ ] Verify page details against the running app (steps were written from source); covered by the W9 usability test.

### Phase W6.5 — UI-automation screenshots — iPhone DONE; Mac deep flows open
Closes the screenshot gap left by W4/W6: the launch-arg seam only reaches top-level screens, so every sheet and sub-screen (see `WebSite/docs/screenPaths.md`) needs a driven UI.
- [x] **Approach:** `WebsiteScreenshotTests` in `NoteBytezUITests` (six flows), built on `NoteBytezUITestCase` and the page objects; each shot is an `XCTAttachment` named `<category>__<name>__<device>-<appearance>`.
- [x] **Isolation:** skips unless `WEBSITE_SCREENSHOTS=1`; settings go in as launch environment.
- [x] **Export:** `capture-ui.sh` runs `xcodebuild test`, exports attachments from the `.xcresult` (`exportShots.mjs`), resizes to the W4 convention.
- [x] **iPhone:** 39 screens × light/dark, zero failed steps.
- [x] **Embed:** 37 `{% screenshot %}` figures in Help pages (`embeds.json`, `embedShots.mjs`); light/dark `<picture>` sources; lint fails on a missing image.
- [x] **Mac (sidebar screens):** 10 screens × light/dark.
- [x] Guarded the one iOS-only call (`XCUIDevice.orientation`) in `Phase2TemplatesAndPropertiesFeatureTests` so the UI-test target builds for macOS.
- **Mac deep flows — open items** (root causes found in the first Mac probe: sidebar rows report *Disabled*, so the app window may not be key; Settings rows are table cells, not buttons; a coordinate tap does not focus the editor; some toolbar items sit in the overflow menu):
  - [ ] Activate the app and confirm a key window before each flow (`app.activate()`); confirm sidebar navigation then registers.
  - [ ] Mac interaction helpers: `click()` for taps, focus the editor by clicking it, find rows by any element type (cells), close sheets with Escape.
  - [ ] Toolbar overflow: enlarge the window or use menu-bar commands (New Note, Command Palette, Quick Switcher, View menu) where a toolbar item is hidden.
  - [ ] Fix each flow from its exported window dump: notes/linking, journal/promote, explore (incl. canvas), search (advanced toggle label), settings (rows, backups, plugins, sharing, sync status), getting started.
  - [ ] Decide which iPhone-only screens are excluded on Mac and record them (file pickers, share and StoreKit system UI).
  - [ ] Decide whether Help pages show Mac figures beside iPhone ones (extend the `screenshot` shortcode and `embeds.json` with a device).
  - [ ] → **verify (Mac):** every iPhone shot name exists for Mac in both appearances at 1x and 2x, except a documented exclusion list; the normal UI-test run still skips the capture class.
- **Known limits:** screens that show today's date (journal, graph) are not byte-stable across days; Mac liquid-glass controls vary by a few pixels.

### Phase W7 — SEO / AI-retrieval wiring (= Wiki 1.5, site-wide) — DONE except final audit sign-off
- [x] `sitemap.xml` (every page, incl. generated hubs; `lastmod` from `lastReviewed`), `robots.txt` with the sitemap line.
- [x] Per-page canonical, meta description (help pages get a category suffix so all are 50–300 chars), Open Graph + Twitter tags, `hreflang` (`en`, `x-default`).
- [x] `llms.txt` at the root (marketing + Help hubs) and a per-section index at `/en/help/<category>/llms.txt`.
- [x] JSON-LD: `FAQPage` now also generated from concept pages' question headings; `HowTo`, `TechArticle`, `BreadcrumbList`, `WebSite` + `SearchAction` from W3.
- [x] `npm run check:seo` (tests first): tags, one h1, sitemap coverage, robots, llms.txt links resolve, readable content without JavaScript, JSON-LD structure.
- Deviation: how-to pages keep the fixed Article Standard headings (Purpose, Prerequisites, Steps, Expected result, Related); question-shaped headings are used on concept pages, marketing FAQs and the page titles. Say if you want how-to headings rewritten as questions.
- [x] → **verify:** `check:seo` passes on all 131 pages; Lighthouse SEO / Best Practices ≥ 95 everywhere (`npm run audit`).
- [ ] Set `baseUrl` in `site.json` (sitemap, canonicals and llms.txt still point at `TODO-DOMAIN`).
- [ ] Rich Results Test / Schema.org validator on a sample of pages (external).

### Phase W8 — Accessibility audit (= Wiki 1.6, site-wide)
- CI budgets on every page; manual keyboard, VoiceOver + Safari, NVDA + Firefox, 200%/400% zoom, reduced-motion, forced-colors; 2.4.11, 2.5.8, 1.4.1 checks.
- → **verify:** signed checklist, zero AA violations, CI green.

### Phase W9 — Usability test (= Wiki 1.7 plus prospect tasks)
- 5 participants, fixed task list (Help tasks + ≥ 2 prospect tasks), site-only.
- → **verify:** ≥ 80% completion; failures fixed and re-tested; report filed in `WebSite/docs/`.

### Phase W10 — Build, CI, release gate (= Wiki 1.9)
- CI: build → axe/Lighthouse budgets → HTML validate → link-check → JSON-LD validate → Pagefind → publish `WebSite/site/_site/`.
- Release gate for `appliesTo` per Wiki R5 (paths remapped).
- Dry-run deploy to a preview URL on any candidate host.
- → **verify:** CI green on a sample content PR; preview renders correctly.

### Phase W11 — Definition of Done
- Success Factors 1–8 pass; style guide promoted; release-gate check active.
- Open items only: host/domain, App Store URL, final price/trial values (fill `site.json`), and the deferred in-app Help links.
