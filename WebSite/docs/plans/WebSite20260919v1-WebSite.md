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
- [x] **Logo/favicon**, 2026-09-23 (raised by the product owner viewing the Pi preview — the header and browser tab had never had an icon, only the styled `NoteBytez` wordmark). Sourced from the app's own `AppIcon.appiconset` (light/dark/tinted variants already exist there, no new art needed): `favicon-32.png` + `apple-touch-icon.png` for the browser tab, and a light/dark `brand-mark` pair in the header next to the wordmark (`<picture>` + `prefers-color-scheme`, same technique as the screenshot shortcode) so it blends with the site's own theme switching, not just the OS favicon chrome. Decorative `alt=""` since the adjacent text already names the site. Header mark sized up 2× same day (56px display, 112px @2x source) per product owner feedback. Regenerate the PNGs from `NoteBytez/Assets.xcassets/AppIcon.appiconset/AppIcon-1024[-dark].png` with `sips -Z <size>` if the app icon or its display size ever changes.
- [x] → **verify:** axe + Lighthouse ≥ 95 (a11y, SEO, Best Practices) on sample pages of every layout; JSON-LD structurally valid; logo verified in both color schemes locally and confirmed live on the Pi preview after redeploy.
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

### Phase W6.5 — UI-automation screenshots — DONE except embedding Mac figures
Closes the screenshot gap left by W4/W6: the launch-arg seam only reaches top-level screens, so every sheet and sub-screen (see `WebSite/docs/screenPaths.md`) needs a driven UI.
- [x] **Approach:** `WebsiteScreenshotTests` in `NoteBytezUITests` (six flows), built on `NoteBytezUITestCase` and the page objects; each shot is an `XCTAttachment` named `<category>__<name>__<device>-<appearance>`.
- [x] **Isolation:** skips unless `WEBSITE_SCREENSHOTS=1`; settings go in as launch environment.
- [x] **Export:** `capture-ui.sh` runs `xcodebuild test`, exports attachments from the `.xcresult` (`exportShots.mjs`), resizes to the W4 convention.
- [x] **iPhone:** 39 screens × light/dark, zero failed steps.
- [x] **Embed:** 37 `{% screenshot %}` figures in Help pages (`embeds.json`, `embedShots.mjs`); light/dark `<picture>` sources; lint fails on a missing image.
- [x] **Mac (sidebar screens):** 10 screens × light/dark.
- [x] Guarded the one iOS-only call (`XCUIDevice.orientation`) in `Phase2TemplatesAndPropertiesFeatureTests` so the UI-test target builds for macOS.
- [x] **Mac deep flows** (`WebsiteScreenshotMacTests`, Mac-only class on a shared `WebsiteScreenshotCase` base): driven by sidebar rows, menu-bar shortcuts (Command-P), toolbar buttons by label and list rows as buttons; every step asserts its target and stops the flow with a hierarchy dump attached.
  - [x] Activate the app and confirm the sidebar before each flow (`app.activate()`) — this was the root cause of the earlier navigation failures.
  - [x] Mac helpers: `click()`, editor focus by click, list rows found as buttons (`BEGINSWITH`/`CONTAINS`), Escape to close sheets, wait-until-hittable.
  - [x] Toolbar overflow (`more toolbar items` pop-up) handled; the board's Add Card menu is clicked by its position.
  - [x] Faster loop: `capture-ui.sh` now uses `build-for-testing` once and `test-without-building` per run (`SKIP_BUILD=1`, `APPEARANCES=light`, per-flow test name).
  - [x] All six flows fixed from their dumps (notes/linking, journal, explore/canvas, search, settings, getting started) plus a sidebar-screens test.
  - [x] Exclusions recorded (iPhone-only): `notebooks/promote-block-picker`, `notebooks/promote-to-notebook` (the Mac Promote a Block sheet lays its list out at zero size: rows exist but are not hittable — possible app layout bug worth a look), `graph/graph-force-mode` (Radial/Force picker not exposed to XCUITest on Mac), `sync-and-conflicts/sync-status` (sync glyph not exposed in the Mac toolbar).
  - [x] → **verify (Mac):** every iPhone shot name exists for Mac in both appearances at 1x and 2x, except the four exclusions above; the normal UI-test run still skips the capture class (`WEBSITE_SCREENSHOTS=1` gate).
  - [ ] Decide whether Help pages show Mac figures beside the iPhone ones (extend the `screenshot` shortcode and `embeds.json` with a device). Mac images are captured but not embedded yet.
- **Known limits:** screens that show today's date (journal, graph) are not byte-stable across days; Mac liquid-glass controls vary by a few pixels.

### Phase W7 — SEO / AI-retrieval wiring (= Wiki 1.5, site-wide) — DONE except `baseUrl`
- [x] `sitemap.xml` (every page, incl. generated hubs; `lastmod` from `lastReviewed`), `robots.txt` with the sitemap line.
- [x] Per-page canonical, meta description (help pages get a category suffix so all are 50–300 chars), Open Graph + Twitter tags, `hreflang` (`en`, `x-default`).
- [x] `llms.txt` at the root (marketing + Help hubs) and a per-section index at `/en/help/<category>/llms.txt`.
- [x] JSON-LD: `FAQPage` now also generated from concept pages' question headings; `HowTo`, `TechArticle`, `BreadcrumbList`, `WebSite` + `SearchAction` from W3.
- [x] `npm run check:seo` (tests first): tags, one h1, sitemap coverage, robots, llms.txt links resolve, readable content without JavaScript, JSON-LD structure.
- Deviation: how-to pages keep the fixed Article Standard headings (Purpose, Prerequisites, Steps, Expected result, Related); question-shaped headings are used on concept pages, marketing FAQs and the page titles. Say if you want how-to headings rewritten as questions.
- [x] → **verify:** `check:seo` passes on all 131 pages; Lighthouse SEO / Best Practices ≥ 95 everywhere (`npm run audit`).
- [x] Re-verified 2026-09-21 after the W6.5 Mac screenshot batch landed (new/updated PNGs under `content/en/_assets/`, still unembedded per W6.5): rebuilt (131 pages, unchanged), `check:seo`, `check:links`, `lint`, `test`, `check:pages` all pass; `audit` spot-checked on `/`, `/pricing/`, `/privacy/`, `/terms/`, and the `getting-started` Help pages (axe + Lighthouse ≥ 0.95, no regressions). The new assets don't touch any page HTML, so they're inert for SEO until W6.5's embedding decision ships.
- [x] Rich Results Test / Schema.org validator on a sample of pages (external). Google's Rich Results Test now requires sign-in for the code-paste path, so used `validator.schema.org`'s code-snippet mode instead against the rendered JSON-LD from the home page (BreadcrumbList, WebSite+SearchAction, FAQPage), a HowTo page (`getting-started/create-select-library`), and a concept page (`concepts/blocks-and-anchors`, TechArticle+FAQPage): 0 errors, 0 warnings on every block, across every JSON-LD type the site emits.
- [ ] Set `baseUrl` in `site.json` (sitemap, canonicals and llms.txt still point at `TODO-DOMAIN`) — blocked on the host/domain decision (D6); not something to fill with a placeholder.

### Phase W8 — Accessibility audit (= Wiki 1.6, site-wide) — DONE except VoiceOver/NVDA
- [x] CI budgets: `npm run audit` (axe-core + Lighthouse ≥ 0.95) run on all 131 pages — zero violations.
- [x] 2.4.11, 2.5.8, 1.4.1, `prefers-reduced-motion`, `forced-colors` — verified by code review of `assets/site.css` and the shared layout.
- [x] Keyboard-only pass: tab order, focus visibility, Pagefind search, no traps. **Found and fixed a real defect the automated budget missed:** the skip-link's target (`<main>`) had no `tabindex`, so activating "Skip to content" scrolled the page but never moved keyboard focus off the link — the next Tab restarted at the top of the document instead of landing in the content. Fixed with `tabindex="-1"` in `_includes/base.njk`; regression-tested (`checkPages.js` → `skipLinkTargetIsFocusable`, wired into `npm run check:pages`).
- [x] 200%/400% zoom reflow (320px / 640px) — no horizontal scroll or content loss, including a table-heavy reference page.
- Full detail and the sign-off table: `WebSite/docs/accessibilityAudit.md`.
- [ ] VoiceOver + Safari and NVDA + Firefox — genuinely need a human with real assistive tech (no Mac VoiceOver driver or Windows/NVDA available in this environment); checklist and suggested pages are in the audit doc.
- → **verify:** signed checklist (pending the two AT passes above), zero AA violations ✔, CI green ✔.

### Phase W9 — Usability test (= Wiki 1.7 plus prospect tasks) — task list ready; N=5 run pending
- [x] Fixed task list drafted: 2 prospect tasks (cost/trial, sync-conflict — D5/SF2) + one anchor task per persona journey + one general-search task. `WebSite/docs/usabilityTest.md`.
- [x] Solo dry run against the live site (not a substitute for the real test — see below): found and fixed a double-escaped `&` on all 7 "X & Y" category hub pages (title, meta description, OG tags, on-page H1); added a site-wide regression guard (`check:seo` now fails on any double-escaped entity). Also found, and left for a product call rather than a blind fix: Pagefind ranks "connect two notes" toward Canvas ahead of Linking/wikilinks.
- [ ] **Run the actual N=5 test.** This needs five real people unfamiliar with the product — nothing in this environment can substitute for that. Instructions, recruiting notes, and the results table to fill in are in `usabilityTest.md`.
- → **verify:** ≥ 80% completion; failures fixed and re-tested; report filed in `WebSite/docs/` — blocked on running the test with real participants.

### Phase W10 — Build, CI, release gate (= Wiki 1.9) — preview deploy done; CI pipeline + release gate not started
- [x] **Dry-run deploy to a preview host**, 2026-09-22: the household Raspberry Pi (`g9Wiki`, `192.168.1.81`, Debian 12/Docker, already running Wiki.js + Postgres in containers). Steps taken:
  1. **Access.** SSH to the Pi was password-only; generated a dedicated local key (`~/.ssh/notebytez_pi`, alias `notebytez-pi` in `~/.ssh/config`, user `dlcollison`) and authorized it (`ssh-copy-id`) so later steps don't need a password each time.
  2. **Surveyed first, changed nothing yet.** Confirmed `/media/data1` and `/media/data2` are the two NVMe mounts; Wiki.js (`requarks/wiki`, port 3000) and Postgres (port 5432) run as Docker Compose services under `<drive>/docker/<service>/docker-compose.yml`, with their data under `<drive>/<service>/`. No web server (nginx/Apache/Caddy) on the host; no port conflict with 8080.
  3. **Built a preview copy.** Temporarily set `baseUrl` in `site/_data/site.json` to `http://192.168.1.81:8080` so canonical/sitemap/OG tags resolve on the preview host, ran `npm run build`, then reverted `baseUrl` back to `https://TODO-DOMAIN` and rebuilt again once the preview copy was shipped — the repo's working tree still reflects the deferred production-domain decision (D6, W7).
  4. **Shipped it**, following the host's own convention: `rsync -az --delete` the built `_site/` to `/media/data1/notebytez-website/site/` (43 MB); a new `docker-compose.yml` (nginx:alpine, read-only bind mount of that directory, `restart: unless-stopped`, same logging config as the existing services) to `/media/data1/docker/notebytez-website/docker-compose.yml` — kept in the repo too, at `WebSite/docs/deploy/notebytez-website.docker-compose.yml`. `docker compose up -d` on the Pi started it as container `notebytez-website` on port **8080**, isolated from `wikinetwork` (no need for it to talk to Wiki.js or Postgres).
  5. **Verified**: HTTP 200 for `/`, `/en/help/`, and a Pagefind asset, both from the Pi itself and from the Mac; loaded it in a browser from the Mac and confirmed navigation and live search work.
  - **Access from your Mac:** **http://192.168.1.81:8080/** — works from any device on the same LAN, no VPN or port-forwarding involved.
  - **To redeploy after content changes:** rebuild (`cd WebSite/site && npm run build`) and `rsync -az --delete WebSite/site/_site/ notebytez-pi:/media/data1/notebytez-website/site/` — the running container serves the directory live, no restart needed. Say the word if you'd like this wrapped in a one-line script.
  - **To stop/remove:** `ssh notebytez-pi 'cd /media/data1/docker/notebytez-website && docker compose down'` (site files under `/media/data1/notebytez-website/` are untouched by this).
  - [ ] **CI pipeline** (build → axe/Lighthouse budgets → HTML validate → link-check → JSON-LD validate → Pagefind → publish) — not started. All the underlying checks exist and pass as `npm` scripts (`build`, `audit`, `check:seo` (includes JSON-LD), `check:links`, `lint`); what's missing is wiring them into an actual CI workflow (e.g. `.github/workflows/`) that gates on them.
  - [ ] **Release gate for `appliesTo`** (Wiki R5, paths remapped) — not started, no script exists yet.
  - → **verify:** CI green on a sample content PR (blocked on the pipeline above); preview renders correctly ✔ (this Pi deploy).

### Phase W10.5 — Redeploy automation — DONE
- [x] `WebSite/tools/deploy/redeploy-pi.sh`: rebuild the site with the Pi's `baseUrl`, rsync `_site/` to `/media/data1/notebytez-website/site/`, then always restore the repo's real (deferred) `baseUrl` — via `trap ... EXIT`, so it restores even if the rsync fails partway. One command, no arguments; the running container serves the directory live, so no container restart is needed.
- [x] Run 2026-09-23: rebuilt (131 pages) and pushed. `git status` shows no diff on `site.json` afterward; verified `http://192.168.1.81:8080/` returns 200 with the current build.
- → **verify:** `tools/deploy/redeploy-pi.sh` run clean; site reachable at `http://192.168.1.81:8080/` afterward; `site.json` unchanged in the repo ✔.

### Phase W10.5 - Logo
1. Incorporate the NoteBytez Logo NoteBytex/images/logo/NoteByterz-Artwork-1024x1024.png into the header of the web page.

### Phase W11 — Definition of Done
- Success Factors 1–8 pass; style guide promoted; release-gate check active.
- Open items only: host/domain, App Store URL, final price/trial values (fill `site.json`), and the deferred in-app Help links.
