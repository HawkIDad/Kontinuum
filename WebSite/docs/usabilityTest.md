<!-- usabilityTest.md -->
<!-- Phase W9 verify: ≥ 80% task completion (N=5, real participants); failures fixed and re-tested (= Wiki SF2 / Phase 1.7, plus ≥ 2 prospect tasks per D5). -->

# Usability test — W9

## Status

The fixed task list below is ready to run. **The N=5 completion-rate test itself has not been run** — it needs five real people unfamiliar with the site, which this environment can't produce (no participants, no session-recording/moderation tooling here). What's in this doc instead: the task list, a solo dry-run against the live site that already found and fixed two real defects, and everything a moderator needs to run the actual test.

## The fixed task list

Recruit 5 participants spread across the four personas (New Arrival, Switcher, Power User, Collaborator — see `wiki20260907v1-Phase1.md`). Each attempts every task below, site-only, no other help, starting from the Home page each time. Record: completed / completed with difficulty / failed, and the path taken.

| # | Task (as read to the participant) | Persona anchor | Expected area |
|---|---|---|---|
| P1 | "You're considering NoteBytez. Find out what it costs and whether there's a free trial." | Prospect | Pricing |
| P2 | "Find out what happens if two devices edit the same note while it's syncing." | Prospect | Home feature card → Help concept |
| H1 | "Find out how to connect two notes together so you can jump between them." | New Arrival | Help › Linking |
| H2 | "You're moving from Obsidian. Find out what happens to your original files after import." | Switcher | Help › Migration |
| H3 | "Find out how to see which of your notes aren't linked to anything else." | Power User | Help › Graph |
| H4 | "Find out how to control whether someone you've invited can edit or only read your notes." | Collaborator | Help › Sharing |
| H5 | "Find out how to search your whole library for a word." | General | Help › Search & Navigation |

7 tasks: the 2 prospect tasks named in the plan (D5/SF2 — cost, sync) plus one anchor task per persona journey, plus one general-search task for broader IA coverage. Keep it to 7 — a longer list risks fatigue for a formative N=5 session.

## Dry run (this session, solo, not a substitute for SF2)

Walked every task against the live built site (`npm start`, `localhost:8080`) as a first-time reader would, using only nav/search/breadcrumbs. Purpose: catch obvious blockers before spending real participants' time, not to produce the ≥80% figure — that number is only meaningful from independent participants who don't already know the answer.

| # | Path taken | Clicks | Result |
|---|---|---|---|
| P1 | Home → Pricing | 1 | ✔ clear (trial confirmed; exact price still `TODO-PRICE`, expected — D6) |
| P2 | Home → feature card "Sync without losing an edit" → Related "How NoteBytez syncs your notes" → "What if two devices disagree?" | 2 | ✔ clear, answers the question directly |
| H1 | Searching "connect two notes" surfaces **Canvas** results first (connector/connect terms), not the wikilinks article. Browsing Help → **Linking** instead finds "Link two notes with wikilinks" immediately. | 2 (browse) / fails via that search phrasing | ⚠ found via browse; **flagged, not fixed** — see below |
| H2 | Help → Migration → "Keep your originals as an archive" | 2 | ✔ clear |
| H3 | Help → Graph → "Review Graph Insights" (names orphans explicitly) | 2 | ✔ clear |
| H4 | Help → Sharing → "Change what a participant can do" | 2 | ✔ clear |
| H5 | Help → Search & Navigation → "Search your library" | 2 | ✔ clear |

### Found and fixed during the dry run

**Double-escaped `&` on every category hub page.** `content/en/help/hub.njk` interpolated `{{ hub.title }}` inside a front-matter string that Eleventy itself renders as a template (autoescaping once), and `base.njk` escaped it again on output — so "Search & Navigation" rendered as literally **"Search &amp; Navigation"** in the page `<title>`, meta description, OG tags, and the on-page H1, on all 7 hub pages whose name contains "&" (Capture & Journal, Documents & Blocks, Search & Navigation, Properties & Templates, Sync & Conflicts, Backup & Restore, Subscription & Account). Fixed with `| safe` on both interpolations in [`hub.njk`](../content/en/help/hub.njk); added a site-wide regression guard (`checkSeo.js` now fails on any `&amp;amp;`/`&amp;lt;`/etc., tested in `checkSeo.test.js`) so this class of bug can't silently return. Rebuilt; `check:seo`, `check:links`, `check:pages`, `lint`, `test` (26/26) and a targeted `audit` re-run all pass.

### Found, not fixed — needs a product call, not a blind fix

**Search ranking for natural-language queries.** Pagefind ranks "connect two notes" toward Canvas ("connector") ahead of Linking ("wikilinks"), because it scores on literal term frequency, not intent. A New Arrival who types that exact phrase may not find wikilinks without also trying Browse. This is worth watching for in the real test — if multiple participants hit the same wall on H1, it's a case for adding a search synonym/alias (Pagefind supports per-page weighting and custom metadata) rather than renaming content. Left as-is rather than tuning search ranking blind.

## Running the real test

1. Recruit 5 people matching the four personas (a New Arrival and Switcher are easiest to find cold; Power User and Collaborator may need someone who's used a linked-notes tool before).
2. One task at a time, site-only, think-aloud if the participant is comfortable with it. Record completion (✔ / difficulty / ✘) and time.
3. Any task below 80% completion across the 5 → specific content or IA fix → re-test just that task with a fresh participant.
4. File results in this doc (replace the dry-run table above with the real one) and update Phase W9 in `WebSite20260919v1-WebSite.md`.
