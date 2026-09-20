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

### Phase W0 — Reconcile plans
- Note in `wiki20260907v1-Phase1.md` that `Wiki/` paths map to `WebSite/` (D1) and Phase 1.8 is deferred (D7).
- Create `WebSite/site/_data/site.json` (site name, base URL, App Store URL, price, trial length — placeholders).
- → **verify:** no remaining `Wiki/` path references in active plan steps without the remap note.

### Phase W1 — Foundations (= Wiki 1.0)
- Eleventy project at `WebSite/site/`; Pagefind post-build; layout `WebSite/content/en/`, `WebSite/docs/`.
- Promote the derived style guide to `WebSite/docs/styleGuide.md`.
- → **verify:** empty build succeeds; Pagefind runs; style guide reviewed against app guide.

### Phase W2 — Information architecture
- Top nav: Home · Features · Pricing · Help · Support; footer: Privacy · Terms · Support.
- URL scheme: `/`, `/features/`, `/pricing/`, `/support/`, `/privacy/`, `/terms/`, `/en/help/<category>/<slug>/` (Wiki 1.1 front-matter schema for Help; lighter schema for marketing pages).
- → **verify:** every Feature Inventory row maps to ≥ 1 slug; every page is in nav or linked; taxonomy sign-off.

### Phase W3 — Templates & components (= Wiki 1.2, plus marketing)
- Help layouts and components as in Wiki 1.2.
- Add `marketing` layout (hero, feature grid, CTA block sourcing App Store URL from `site.json`), `legal` layout, and a Features-overview → Help deep-link component.
- → **verify:** axe + Lighthouse ≥ 95 (a11y, SEO, Best Practices) on sample pages of every layout; JSON-LD validates.

### Phase W4 — Screenshot pipeline (= Wiki 1.3)
- Seed library, capture script, naming/retina convention; output to `WebSite/content/en/_assets/`.
- → **verify:** one category regenerates byte-stable on a clean machine.

### Phase W5 — Marketing & support content
- Write Home (value proposition, audiences, CTA), Features overview (capability tour linking into Help), Pricing (trial, subscription, lapse and read-only export; values from `site.json`).
- Write Privacy Policy, Terms of Use / EULA, Support / Contact. **Legal text is drafted for your review; have counsel confirm before publish.**
- → **verify:** SF2 walkthrough (*what / who / cost / how to get it* in ≤ 2 clicks); footer links present on every page.

### Phase W6 — Help content authoring (= Wiki 1.4)
- All how-tos, four journeys, concept and reference pages; internal-link pass.
- → **verify:** Wiki SF1 — coverage 100%, structure lint, link-check clean, no orphans.

### Phase W7 — SEO / AI-retrieval wiring (= Wiki 1.5, site-wide)
- Sitemap, robots, canonicals, meta, OG/Twitter, `llms.txt` covering marketing + Help; question-shaped headings in Help.
- → **verify:** schema validates; Lighthouse SEO / Best Practices ≥ 95 everywhere; no page needs JS to read.

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
