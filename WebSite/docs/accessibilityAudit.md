<!-- accessibilityAudit.md -->
<!-- Phase W8 verify: signed checklist, zero WCAG 2.2 AA violations, CI gate green (= Wiki SF3 / Phase 1.6). -->

# Accessibility audit — W8

## 1. Automated (CI budget)

`npm run audit` (axe-core wcag2a/aa, wcag21a/aa, wcag22aa, best-practice + Lighthouse accessibility/SEO/best-practices ≥ 0.95) run against **all 131 built pages**, 2026-09-21: **zero violations, zero pages below threshold.**

| Batch | Pages | Result |
|---|---|---|
| Marketing/legal + attachments, backup-and-restore, tags, plugins | 21 | ✔ |
| getting-started, capture-and-journal, documents-and-blocks, notebooks, concepts | 26 | ✔ |
| linking, markdown-import-export, migration, sharing | 25 | ✔ |
| search-and-navigation, sync-and-conflicts, tasks, reference | 24 | ✔ |
| properties-and-templates, subscription-and-account, journeys | 21 | ✔ |
| canvas, graph, Help hub | 14 | ✔ |

Re-run any time with `AUDIT_FILTER="prefix1,prefix2"` (comma list; a bare `/` matches only the home page, `=path` forces an exact match — see `scripts/audit.js`).

## 2. WCAG 2.2-specific checks (code review, `assets/site.css` + `_includes/`)

| SC | Check | Result |
|---|---|---|
| 2.4.11 Focus not obscured | No sticky/fixed header or other overlapping chrome anywhere in the layout; `:focus-visible` outline is never suppressed. | ✔ pass |
| 2.5.8 Target size (min.) | Nav, buttons, pager: `min-height: 44px`. Breadcrumb: `24px`. Inline prose links fall under the WCAG exemption (text-constrained). | ✔ pass |
| 1.4.1 Use of color | Body/article links always underlined. Nav follows the documented nav-bar exception; the active item adds weight + underline + border, not color alone. Admonitions pair an icon with a text label (Note/Tip/Warning), never color alone. | ✔ pass |
| `prefers-reduced-motion` | No animations/transitions/video exist anywhere in `site.css` or content today; the defensive `* { animation: none !important; transition: none !important }` rule also overrides the one micro-transition in Pagefind's own CSS. | ✔ pass (nothing to reduce; verify again if motion is ever added) |
| `forced-colors: active` | `.button, .badge, .admonition, .feature-card` get an explicit `1px solid CanvasText` border so surfaces stay legible when backgrounds are flattened. | ✔ pass by code review — recommend a human spot-check with Chrome DevTools' forced-colors emulation or Windows High Contrast |

## 3. Keyboard-only pass (done this session, `localhost:8080`)

- Tab order on Home follows DOM/visual order: skip-link → brand → primary nav → search → hero CTA → feature-card links. Focus ring visible at every stop.
- **Found and fixed:** the skip-link (`href="#main"`) scrolled to `<main>` but never moved keyboard focus there — `<main>` had no `tabindex`, so the next Tab resumed at the top of the document instead of inside the content. axe-core's own `skip-link` rule doesn't catch this (it only checks the target exists and is visible to screen readers, not that it's focusable). Fixed by adding `tabindex="-1"` to `<main id="main">` in [`_includes/base.njk`](../site/_includes/base.njk:43); verified live (`document.activeElement` now lands on `<main>`, next Tab reaches the hero CTA). Regression-tested in [`scripts/checkPages.js`](../site/scripts/checkPages.js) (`skipLinkTargetIsFocusable`) and wired into `npm run check:pages`, which now runs on every page.
- Pagefind search: reachable by Tab, typing filters results live, Tab reaches "Clear" then each result link, Enter follows a result — full keyboard operability confirmed on the Help hub.
- No keyboard traps found on any page exercised (Home, Help hub + search, a How-to page, a table-heavy reference page).

## 4. Zoom / reflow (WCAG 1.4.10)

Tested at 320px width (400% zoom equivalent) and 640px (200% zoom equivalent) on the home page and the table-heavy `reference/keyboard-shortcuts/` page: no horizontal scroll, no content or functionality loss, table reflows without a scroll container.

## 5. Not done — needs a human with real assistive tech

No VoiceOver, NVDA, or a Windows machine is available in this environment, so these are still open:

- [ ] VoiceOver + Safari full pass (macOS, real device)
- [ ] NVDA + Firefox full pass (Windows, real device)
- [ ] Forced-colors mode, live confirmation (Windows High Contrast, or Chrome DevTools → Rendering → Emulate CSS media feature `forced-colors`)

**Suggested pages to cover:** Home (landmarks, FAQ), a How-to page (steps list, screenshot figures, Applies-to badge), the Help hub (search, category list), a page with a table (`reference/keyboard-shortcuts`), Pricing (FAQ). For each: landmarks/headings announce correctly, images have sensible alt text, the search field and its results are usable, no content is announced as unlabelled or duplicated.

## Sign-off

| Item | Status |
|---|---|
| CI green (axe + Lighthouse ≥ 95, zero violations) | ✔ done, this session |
| 2.4.11 / 2.5.8 / 1.4.1 | ✔ done, this session |
| Keyboard-only | ✔ done, this session (one defect found and fixed) |
| Zoom / reflow | ✔ done, this session |
| `prefers-reduced-motion` / `forced-colors` | ✔ code review done; forced-colors recommended for live human confirmation |
| VoiceOver + Safari | ⬜ pending — needs a person with a Mac + VoiceOver |
| NVDA + Firefox | ⬜ pending — needs a person with Windows + NVDA |
| **Signed off by** | _pending — fill in name/date once the two items above are run_ |
