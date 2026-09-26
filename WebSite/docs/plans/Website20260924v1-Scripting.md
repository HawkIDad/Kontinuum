<!-- WebSite20260924v1-Scripting.md -->
<!--
  User story to add scripting (Plugin SDK, Preview) tutorials and documentation to the Web Site.
  User Story + Success Factors reworked, and Implementation Plan added, from the 2026-09-24 interview.
-->

# User Story

As a Power End User, I want to take advantage of NoteBytez's built-in scripting engine (the Plugin SDK, Preview). To do so, I need tutorials and documentation on the Web Site that show me exactly what features, functions and data a script can access, what it cannot, and how to write, install, run and troubleshoot my own scripts to process information within NoteBytez.

## Scope

| In scope | Out of scope |
|---|---|
| Extending the existing `plugins` Help category with reference, concept, tutorial and troubleshooting pages | A new `scripting` category, or renaming/moving the existing plugin pages (URLs unchanged) |
| One reference page per `noteBytez.*` API (7), plus an overview table, "what scripts can see", and "limits & gotchas" | A JavaScript primer — readers are assumed to know basic JavaScript |
| Three worked tutorials: first plugin, library report, search-driven digest | A multi-command tutorial; a plugin marketplace/sharing guide |
| Two journeys, persona "Power User" | A new persona (would touch schema, onboarding wording and nav) |
| Build-time syntax highlighting; every code sample executed against the real engine in tests | Interactive in-browser script sandbox (no client framework — D2 of the parent site plan) |
| An app change so plugin commands can actually be run from the UI, with visible errors (Phase 0 — prerequisite to publishing) | Editing `NoteBytez/Docs/PluginSDK.md` (developer doc, kept as-is) |

## Decisions (from interview)

| # | Topic | Decision |
|---|---|---|
| SC1 | Relationship to existing content | **Extend `plugins`.** Keep the category and the 3 existing pages' URLs; add 15 pages; lightly revise the 3 existing pages for accuracy and cross-links. Matches the in-app term "Plugins (Preview)". |
| SC2 | Reference depth | **One page per API** (`type: reference`): signature, return value, required permission, example, errors, Preview limits. Plus one overview page (`scripting-api`) tabulating all 7 APIs, the 3 permissions and `noteBytez.invokedCommand`. |
| SC3 | Audience | **Basic JavaScript assumed.** Pages teach the `noteBytez.*` API and the run model only. |
| SC4 | Limits | **Dedicated "Limits & gotchas" page plus inline admonitions** where each limit bites (2 s timeout, no state between runs, `insertAtCursor` behaves as append, no file/network access, permissions fixed at install, Preview status). |
| SC5 | Tutorials | **Three:** *Your first plugin*, *Library report*, *Search-driven digest*. Each is a complete, copy-paste script. |
| SC6 | Journeys | **Two,** both persona "Power User": **Write your first plugin** and **Build a useful plugin** (composition below). |
| SC7 | Data exposure | **Documented exactly:** scripts see document `id` + `title`, tag names and notebook names only — never note bodies, and never the current note's text. `searchDocuments` matches titles *and* content, but returns only `{id, title}`. |
| SC8 | Troubleshooting | **A "Troubleshoot a plugin" how-to** (permission denied, no commands appear, 2 s timeout, syntax errors). Must describe the app as shipped after Phase 0. |
| SC9 | App gap | **Wire it in the app first.** Today `PluginViewModel.invokeCommand` / `registeredCommands` are unit-tested but nothing in the UI calls them, the Command Palette is explicitly "a static registry, no plugin surface" (`AppCommand.swift`, Decision 6), and script errors/timeouts are silent. Docs describe working behaviour; nothing in Phases 3–6 is published until Phase 0 ships. Note this reverses Decision 6. |
| SC10 | Code samples | **Copy-paste blocks, build-time highlighted** (`@11ty/eleventy-plugin-syntaxhighlight`, MIT, zero client JS). **Every sample lives once** as a `.js` file, is included in pages via a shortcode, and is **executed against `PluginBridge` in the app's test target** so docs cannot drift from the engine. |
| SC11 | Source of truth | `NoteBytez/Docs/PluginSDK.md` is left as-is; site content is derived from it once, then verified against the engine by SC10's tests and SF1's drift check. |
| SC12 | IA mechanics | As in the Markdown tutorial plan (MD6): Help hub, category page, `sitemap.xml`, `llms.txt` and Pagefind are generated from `featureMap.json`. Edits are content files, one `featureMap.json` change, one shortcode and one config change. |

### Journey composition (SC6)

| Journey | Slug | Path |
|---|---|---|
| Write your first plugin | `write-your-first-plugin` | How scripts run → Understand plugin permissions → Your first plugin → Add and enable a plugin → Troubleshoot a plugin |
| Build a useful plugin | `build-a-useful-plugin` | Scripting API overview → What scripts can see → Library report → Search-driven digest → Limits & gotchas → Troubleshoot a plugin (API pages linked from the overview and tutorials) |

### Page inventory (SC1–SC8)

| Type | Title | Slug |
|---|---|---|
| concept | How scripts run | `how-scripts-run` |
| concept | What scripts can see | `what-scripts-can-see` |
| reference | Scripting API overview | `scripting-api` |
| reference | `listDocuments` | `list-documents` |
| reference | `searchDocuments` | `search-documents` |
| reference | `listTags` | `list-tags` |
| reference | `listNotebooks` | `list-notebooks` |
| reference | `appendToCurrentNote` | `append-to-current-note` |
| reference | `insertAtCursor` | `insert-at-cursor` |
| reference | `addCommand` | `add-command` |
| reference | Limits & gotchas | `plugin-limits` |
| howto | Troubleshoot a plugin | `troubleshoot-plugin` |
| howto | Your first plugin | `first-plugin` |
| howto | Library report plugin | `library-report-plugin` |
| howto | Search-driven digest plugin | `search-digest-plugin` |

Existing, revised only for accuracy and `Related` links: `enable-plugin`, `plugin-permissions`, `plugin-sdk-overview`.

# Success Factors
Done when **all** pass. SF7 is an inherited site-wide gate (Wiki SF3/SF4 via the parent plan's D4).

1. **Complete API coverage.** Every function on the `noteBytez` global (7) and the `invokedCommand` property, all 3 permissions, and the two-pass execution model each have a published page, and a check fails the build if a bridge function has no reference page (drift check).
2. **Honest about data and limits.** "What scripts can see" and "Limits & gotchas" state every exposure and constraint in SC4/SC7, and each is repeated as an admonition on the page where it applies. Nothing is documented that the engine doesn't do.
3. **Guided paths.** `write-your-first-plugin` and `build-a-useful-plugin` exist, thread the pages in the order in the journey table, and are reachable within 2 clicks of the Help hub.
4. **Tutorials work.** The three tutorials are complete copy-paste scripts, and every sample is executed against `PluginBridge` in the app test suite (finishes, expected output, correct permissions declared on the page).
5. **Documented behaviour is real.** A reader following *Your first plugin* on a current build can install the script, run its command from the Command Palette and see the note change; a failing script shows an error (Phase 0). Publish is blocked until Phase 0 is verified.
6. **Troubleshooting.** `troubleshoot-plugin` covers permission denied, no commands appearing, the 2 s timeout and syntax errors, matching the error states the app actually shows.
7. **Quality parity (inherited) and no regression.** All new pages meet the Article Standard (howto) or reference layout, and pass `npm run lint`, `check:links` (zero orphans), `check:seo`, `npm test` and `npm run audit` (axe + Lighthouse ≥ 95, including syntax-highlight colour contrast in light and dark). The 3 existing plugin pages keep their URLs and change only in accuracy fixes and added `Related` links.

# Implementation Plan
Reuses the parent site plan's tooling and conventions (Article Standard, `featureMap.json`-driven IA, existing check scripts). Legend: **[ ]** open · **[x]** done and verified. Status as of 2026-09-26: P0–P6 complete; no open items.

Assumptions: (a) the App Phase 0 is scoped here but tracked in its own plan file (`NoteBytez/Docs/Plans/`), since it changes app behaviour and reverses Decision 6; (b) reference pages use `type: reference` and the `reference.njk` layout — confirm `checkIA.js` accepts them in a non-`reference` category in P2.

### Phase P0 — App prerequisite: run plugin commands, show errors (blocks publish)
- [x] Wrote the app plan file (`NoteBytez/Docs/Plans/NoteBytez20260924v1-PluginCommands.md`); Decision 6 reversal proceeded on the go-ahead to execute P0.
- [x] Tests first (TDD): palette lists enabled plugins' registered commands; selecting one calls `invokeCommand` with the open `DocumentViewModel`; disabled plugins contribute nothing.
- [x] Surface `PluginRunResult.scriptError` and `.timedOut` (and registration failure) to the user instead of returning silently; unit tests for each state; verified in the iPhone UI flow.
- [x] Extend `WebsiteScreenshotTests` / `WebsiteScreenshotMacTests` to capture the palette showing a plugin command and the error state (iPhone + Mac, light + dark, 1x/2x). iPhone done on the "NoteBytez Screenshots" simulator (12 images exported); the Mac flow now passes too (light and dark; 12 Mac image files exported).
- [x] → **verify:** app test suite green; manually install the P4 *Your first plugin* script, run it from the palette, see the note change; break the script and see the error. Done on the simulator by seeded launch and by `testPluginCommandFlow`; note the iPhone needed a new Command Palette toolbar button (PC6).

### Phase P1 — Site tooling
- [x] Add `@11ty/eleventy-plugin-syntaxhighlight` (build-time; no client JS); pick light/dark themes meeting ≥ 4.5:1 text contrast against the site's code-block background.
- [x] Add `pluginSample` shortcode in `scripts/shortcodes.js` that includes `WebSite/content/en/_plugin-samples/<name>.js` as a highlighted block; add a check (in `checkContent.js`) that every referenced sample exists.
- [x] Add the app-side test, e.g. `PluginDocsSamplesTests` in `NoteBytezTests`, that loads every file in `_plugin-samples/` and runs it through `PluginBridge` with all permissions, asserting `.finished` and expected `collector` output; also asserts every function on the `noteBytez` global has a matching reference page slug (SF1 drift check).
- [x] → **verify:** `npm test`, `npm run lint`; app tests green; a deliberately broken sample fails the Swift test.
- Notes: the Swift drift check (`everyBridgeFunctionHasAReferencePage`) was wrapped in `withKnownIssue` in P1; the wrapper was removed in P3 once the pages existed. Samples declare permissions on line 1 (`// permissions: addCommand, writeCurrentNote`), which the shortcode renders as "Permissions to grant" and the Swift test grants. `first-plugin.js` is the P4 tutorial script, created in P1 to prove the harness. Site code blocks previously had no styling; `pre`/`code` and token colours (≥ 5.5:1 in light and dark) were added to `assets/site.css`. Audit coverage: `_samples/en/help/reference/sample-code.md` (built only with `SAMPLES=1`).

### Phase P2 — IA & schema
- [x] Add the 15 new features to the `plugins` category in `WebSite/site/_data/featureMap.json` (slugs per the inventory) and the two journeys (`persona: "Power User"`).
- [x] Confirm all 17 new slugs are unique against existing `featureSlug` values; confirm the schema/lint accept `type: reference` and `type: concept` pages in `plugins`.
- [x] → **verify:** `npm run lint` → IA lint clean.
- Notes: hub pages and the pager are built from the pages themselves, so the new map entries produce no links until P3/P4 write the pages (no broken links or orphans meanwhile). Layouts and the front-matter schema are category-agnostic, so `type: reference`/`concept` pages in `plugins` need no changes — checked with a throwaway reference page (linted, built, listed on the hub, got a pager), then removed. Map now: `plugins` 18 features, 7 journeys; 0 duplicate slugs.

### Phase P3 — Concepts and reference (11 pages)
- [x] Write `how-scripts-run` (registration vs invocation, `invokedCommand`, no state between runs) and `what-scripts-can-see` (SC7).
- [x] Write `scripting-api` overview, then the 7 API pages; each with signature, return value, permission, a `pluginSample` example, error ("Permission denied: …") and Preview limits. `insert-at-cursor` states it currently behaves as append.
- [x] Write `plugin-limits`: 2 s timeout (host stops waiting; script abandoned), no persisted state, no filesystem/network, permissions fixed at install, Preview status.
- [x] → **verify:** `npm run lint`; every sample passes the P1 Swift test; every claim traced to `PluginBridge.swift` / `PluginSDK.md`.
- Notes: 11 pages written (2 concepts, 9 reference); 7 new samples added under `_plugin-samples/` (one per API page, each registers a command and writes to the note, all passing `PluginDocsSamplesTests`). The drift check's `withKnownIssue` wrapper was removed and the check now passes for real. Claims were traced to `PluginBridge.swift`, `PluginViewModel.swift` and `DocumentViewModel.applyPluginWrites`; the JavaScript-features sentence was checked by running probes in JavaScriptCore (arrow functions, let/const, template literals, JSON, Date, Promise work; no setTimeout/fetch/require). `console` exists in the engine but has no visible output, so the pages say output is not shown. Pages link only to existing pages — links to the P4 tutorials and troubleshooting page are added in P4/P5. Gates: lint clean; build 142 → 153 pages; `check:links` and `check:seo` clean; axe + Lighthouse pass on all 15 plugin pages.

### Phase P4 — Tutorials and troubleshooting (4 pages)
- [x] Write `first-plugin` (register a command, append text; Article Standard), `library-report-plugin` (`listDocuments`/`listTags`/`listNotebooks` → summary), `search-digest-plugin` (`searchDocuments` → wikilink list). Store each script in `_plugin-samples/`.
- [x] Write `troubleshoot-plugin` against the P0 error states.
- [x] → **verify:** `npm run lint` (numbered Steps); each tutorial script installed and run in the app; screenshots present (light/dark, 1x/2x).
- Notes: 4 pages (3 how-tos meeting the Article Standard, plus troubleshooting) and 2 new samples (`library-report.js`, `search-digest.js`); `first-plugin.js` was created in P1. The three scripts were installed verbatim from the sample files on the simulator (seeded launch) and run from the Command Palette: Say Hello, Library Report and Topic Digest each wrote the expected text to Today. Troubleshooting messages were checked against the app (alert and registration caption seen on the simulator, screenshots reused from P0) and against JavaScriptCore probes for the SyntaxError/ReferenceError/TypeError wording. Since a plugin's script can't be edited after install, the pages tell readers to remove and re-add. Gates: lint, check:links and check:seo clean on 157 pages; 31 JS tests; axe + Lighthouse pass on the four pages; Swift samples test passes on the simulator. The Mac and iPad wording for opening the palette (Command-P) is from the app's menu commands and was not exercised here.

### Phase P5 — Journeys, cross-links, existing pages
- [x] Write `journeys/write-your-first-plugin.md` and `journeys/build-a-useful-plugin.md` per the composition table.
- [x] Revise `enable-plugin` (accurate "runs from the Command Palette" wording), `plugin-permissions` and `plugin-sdk-overview` (link to new pages); add a `Related` link to the journeys from `journeys/model-your-world.md`.
- [x] → **verify:** Help hub shows 7 journeys and the Plugins category tile with 18 pages, with no template changes (SC12); `check:links` clean.
- Notes: journey `order` 5 and 6 (after the existing five). Existing pages changed only by accuracy fixes and links: `enable-plugin` (expected result now says commands appear in the Command Palette as *Plugin name: Command name*; two Related links), `plugin-permissions` (new step 4: permissions are fixed at install; two Related links), `plugin-sdk-overview` (step 2 corrected — scripts read note *titles* and tag/notebook *names*, not the whole library; three Related links). URLs unchanged. `features.md` still links only to `enable-plugin` and was not touched. Hub check from the built site: 7 journeys, Plugins category lists 18 pages; 159 pages, `check:links` (no orphans), `check:seo`, lint clean; axe + Lighthouse pass on the journeys, the three revised pages and the Help, Journeys and Plugins hubs.

### Phase P6 — Site-wide gates and deploy
- [x] Rebuild; run `npm run lint`, `check:links`, `check:seo`, `npm test`, `npm run audit`; fix contrast issues in highlighted code, if any.
- [x] Confirm SF5 end to end on a current build, then redeploy via `WebSite/tools/deploy/redeploy-pi.sh`.
- [x] → **verify:** all checks green; new pages render correctly, in light and dark, at `http://192.168.1.81:8080/en/help/plugins/first-plugin/` and both journeys.
- Notes: whole-site audit (axe + Lighthouse) run in four chunks on a `SAMPLES=1` build — every page passes, no contrast fixes needed. `check:links` and `check:seo` were run on the normal build (159 pages, clean); on a `SAMPLES=1` build they flag the audit-only sample pages by design. SF5 re-confirmed on the simulator (`testPluginCommandFlow` passes; 60 plugin/palette unit tests pass). Deployed with `redeploy-pi.sh` (`baseUrl` restored afterwards); the journeys, the plugin hub, the new pages, the canonical URL, syntax highlighting and the palette screenshot all serve 200 on the Pi. **Still open, outside P6:** the Mac `testPluginCommandFlow` has not been run (macOS UI-test authentication prompt), so the Mac screenshots for these docs don't exist yet; `WebSite/tools/screenshots/capture-ui.sh mac testPluginCommandFlow` when unlocked.

## Open items
- **Resolved (2026-09-26):** `NoteBytez/Docs/PluginSDK.md`'s "breaking change" note said the global was renamed from `noteBytez` to `noteBytez`. History (`git show 2e32c07`) shows the original said `kontinuum`; the rename sweep rewrote it to nonsense, and `Scripts/verify-rename.sh` forbids the old name in shipping docs. The note now says the global was renamed in the pre-release rename and is `noteBytez`, without repeating the retired name. (`verify-rename.sh` itself already fails on unrelated `Docs/Bugs/` hits and its `git` resolves to a broken x86 binary here — not touched.)
- **Resolved (2026-09-26):** the Mac `testPluginCommandFlow` passes in light and dark; the six Mac plugin screenshots are exported. No open items remain.
