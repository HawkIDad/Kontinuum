<!-- WebSite20260923v1-MarkdownTutorial.md -->
<!--
  User story to incorporate a Markdown tutorial into the Web site.
  User Story + Success Factors reworked, and Implementation Plan added, from the 2026-09-23 interview.
-->

# User Story
As the product owner, I want to add a Markdown tutorial to the website so that End Users who have never used Markdown before can learn to create and maintain their notes — taught as two clearly separated layers, standard Markdown (portable to any tool) and NoteBytez's own syntax extensions (wikilinks, block references, embeds, tags, tasks) — without duplicating or disturbing the site's existing reference and how-to content.

## Scope

| In scope | Out of scope |
|---|---|
| A new `markdown-basics` Help category: one how-to per standard-Markdown construct | An interactive type-and-see-it-render sandbox (no client framework — D2 of the parent site plan) |
| A new "Learn Markdown" journey threading those how-tos in teaching order, then handing off to the existing NoteBytez-extension how-tos | Rewriting or restructuring the existing reference/how-to/concept Markdown pages |
| Cross-links from Getting Started and the existing Markdown pages into the new journey | A dedicated page for YAML front matter fields (`tags:`, `notebooks:`) — stays covered in the existing reference table for now |

## Decisions (from interview)

| # | Topic | Decision |
|---|---|---|
| MD1 | Relationship to existing content | **New pages only.** `reference/markdown-syntax.md`, `documents-and-blocks/markdown-formatting.md`, and `concepts/plain-markdown-data.md` keep their content unchanged; they gain reciprocal `Related` links to/from the new journey. |
| MD2 | Syntax scope | **Standard Markdown and NoteBytez extensions, taught separately.** The journey teaches standard Markdown via 9 new how-tos, then explicitly hands off to the existing extension how-tos (wikilinks, block references, embeds, tags, checkbox tasks) rather than duplicating them. |
| MD3 | Format | **Static** — prose, "you type / you get" examples, and code blocks, matching every other Help page. No interactive preview widget (consistent with the parent plan's D2, no client framework). |
| MD4 | Structure | **Both a journey and per-construct pages.** New category `markdown-basics` (9 how-tos) + one new journey `learn-markdown`. This is the site's 5th journey; unlike the existing four it isn't persona-exclusive, but it's listed with persona "New Arrival" (the primary beneficiary) since the `featureMap.json` journeys schema expects one. |
| MD5 | Standard-Markdown feature inventory | Nine constructs, one how-to each (below) — chosen as exactly the constructs in `reference/markdown-syntax.md`'s table that don't already have a dedicated how-to. |
| MD6 | IA mechanics | The Help hub's "Browse by topic" and "Start with a journey" lists, the category hub page, `sitemap.xml`, `llms.txt`, and the Pagefind index are **all generated automatically** from `featureMap.json` + `collections.helpPages` (verified in `_data/helpHubs.js` and `content/en/help/index.md`). No template or `nav.json` changes are needed — only content files and one `featureMap.json` edit. |
| MD7 | Cross-link placement | Add a `Related` link to the new journey from an existing Getting Started page, since New Arrivals are the primary audience. |

### MD5 — Standard Markdown feature inventory

| Title | Slug | Covers |
|---|---|---|
| Headings | `headings` | `# H1` … `###### H6` |
| Emphasis | `emphasis` | `**bold**`, `*italic*` |
| Lists | `lists` | Bulleted and numbered lists |
| Blockquotes | `blockquotes` | `> quote` |
| Code | `code-blocks` | Inline `` `code` `` and fenced code blocks |
| Links | `web-links` | `[text](https://example.com)` |
| Images | `images` | `![alt](path)` |
| Tables | `tables` | Pipe-delimited tables |
| Horizontal rules | `horizontal-rules` | `---` |

# Success Factors
Done when **all** pass. SF4 and SF5 are inherited site-wide gates (Wiki SF3/SF4 via the parent plan's D4) — no new tooling required, the existing scripts already cover them.

1. **Standard-Markdown coverage.** A published how-to exists for every construct in the MD5 inventory, each meeting the Article Standard (Purpose, Prerequisites, Steps, Expected result, Related).
2. **Guided path, no duplication.** The `learn-markdown` journey threads all 9 how-tos in a sensible teaching order, then links out to the 5 existing NoteBytez-extension how-tos (wikilinks, block references, embeds, tags, checkbox tasks) as explicit next steps — none of that content is duplicated in the new pages.
3. **Discoverability.** The tutorial is reachable within 2 clicks from the Help hub (new category tile under "Browse by topic", journey under "Start with a journey") and cross-linked from Getting Started; `npm run check:links` reports zero orphans.
4. **No regression to existing pages.** `reference/markdown-syntax.md`, `documents-and-blocks/markdown-formatting.md`, and `concepts/plain-markdown-data.md` are byte-identical except for one added `Related` link each.
5. **Quality parity (inherited).** The new pages pass the same site-wide bars as every other Help page: `npm run lint` (structure), `check:links` (no broken links/orphans), `check:seo` (HowTo/BreadcrumbList JSON-LD, canonical, meta description), and `npm run audit` (axe + Lighthouse ≥ 95) — verified with the existing scripts, nothing new to build.

# Implementation Plan
Reuses the parent site plan's tooling and conventions throughout (Article Standard, `featureMap.json`-driven IA, existing check scripts) — this is additive content, no new build tooling. Legend: **[x]** done and verified · **[ ]** open. Status as of 2026-09-23.

### Phase MT1 — IA & schema — DONE
- [x] Added the `markdown-basics` category to `WebSite/site/_data/featureMap.json` (9 features per MD5).
- [x] Added the `learn-markdown` journey entry (`persona: "New Arrival"`, `order: 0` on the content page so it lists first without renumbering the other four journeys).
- [x] → **verify:** `npm run lint` → `✔ IA lint clean`; all 10 new slugs confirmed unique against every existing `featureSlug` before writing content.

### Phase MT2 — Standard Markdown how-tos (9 pages) — DONE
- [x] Wrote the 9 how-to pages under `WebSite/content/en/help/markdown-basics/`, Article Standard, each with a short "you type / you get" example. Two also carry a short admonition disambiguating from NoteBytez's own syntax (`web-links` → wikilinks, `images` → attaching a file).
- [x] Each page's `Related` links back to `reference/markdown-syntax.md` and to `learn-markdown`; `order: 1`–`9` set to the actual teaching sequence used (see MT3).
- [x] → **verify:** `npm run lint` clean (Article Standard structure, numbered Steps); confirmed visually in the browser (headings, code samples, admonition all render correctly in dark mode).

### Phase MT3 — "Learn Markdown" journey + cross-links — DONE
- [x] Wrote `WebSite/content/en/help/journeys/learn-markdown.md`. Teaching order refined from the draft for pager consistency with MT2's `order` fields: **Headings → Emphasis → Lists → Blockquotes → Code → Links → Images → Tables → Horizontal rules**, then a "NoteBytez's own Markdown" section linking to the 5 existing extension how-tos (wikilinks, block references, transclusion, tags, checkbox tasks) — no content duplicated.
- [x] Added a `Related` cross-link from `getting-started/app-anatomy.md` to `learn-markdown` (MD7).
- [x] Added one reciprocal `Related` link on each of the 3 existing pages named in MD1 (`reference/markdown-syntax.md`, `documents-and-blocks/markdown-formatting.md`, `concepts/plain-markdown-data.md`) — no other change to those pages.
- [x] → **verify:** Help hub shows 5 journeys (Learn Markdown listed first) and 22 categories (Markdown Basics included), entirely from the `featureMap.json` edit — no template changes, confirming MD6; `check:links` clean.

### Phase MT4 — Site-wide gates and preview — DONE
- [x] Rebuilt (131 → **142 pages**); `npm run lint`, `check:links`, `check:seo`, `npm test` (26/26), and `npm run audit` (axe + Lighthouse) all pass on the new pages — same bars as every other phase, no new tooling.
- [x] Redeployed via `WebSite/tools/deploy/redeploy-pi.sh`.
- [x] → **verify:** all checks green; confirmed live and rendering correctly at `http://192.168.1.81:8080/en/help/journeys/learn-markdown/` and the `markdown-basics` pages.
