<!-- 02-Journeys.md -->
<!--
  Part of the NoteBytez UIUX Research deliverable set. See ../../../NoteBytez20260813-UIUX-Research.md for scope/plan.
  Storyboards + Customer Journey Maps for the 5 selected flows. MVP scope only — every touchpoint below
  is a feature listed under "MVP" in NoteBytez-ReleaseFeatures.md. No V1/Advanced features appear.
-->

# Storyboards & Customer Journey Maps

Personas referenced: [Obsidian Archivist, Logseq Outliner, Dual-Tool Migrator](01-Personas.md).

---

## Journey 1 — Migrating a library from Obsidian/Logseq

**Primary persona:** Obsidian Archivist (also relevant to Dual-Tool Migrator) · **Platform:** Mac (bulk import is a desktop task)

### Storyboard

1. User has an existing Obsidian vault (or Logseq graph) of plain Markdown files on disk.
2. Opens NoteBytez for the first time on Mac. Chooses "Create a library" → "Import existing Markdown folder."
3. Selects the folder. NoteBytez scans files, reports what it found (note count, wikilinks, checkboxes) before touching anything.
4. User reviews the scan summary and confirms import.
5. NoteBytez imports files as Documents, parses `[[wikilinks]]` into Backlinks, parses `- [ ]` into Tasks, assigns each block a stable UUID.
6. A local snapshot (Backup) is taken automatically before import runs, in case anything looks wrong afterward.
7. User opens a few notes to spot-check that links, tasks, and formatting survived.
8. User exports one note back to Markdown to confirm round-trip fidelity before trusting the tool further.

**Circumstances:** Offline-capable — no CloudKit sync required for this to work, since it's local-first. Happens once, under high scrutiny; the user is actively looking for reasons to distrust the tool.

### Journey Map

| Stage | Action | Thought | Emotion | Touchpoint (MVP feature) |
|---|---|---|---|---|
| Discover | Learns import is folder-based, not proprietary | "At least I'm not re-typing anything" | Cautiously interested | Markdown import/export |
| Scan | Reviews pre-import summary | "Does it actually understand my wikilinks?" | Skeptical | Import scan/preview |
| Commit | Confirms import | "Here goes nothing" | Anxious | Local library, Backups (auto-snapshot before import) |
| Inspect | Opens imported notes, checks links/tasks | "My backlinks are still there" | Relieved | Documents + stable blocks, Backlinks |
| Verify | Exports a note back to `.md` | "I can leave whenever I want" | Trusting | Markdown import/export |

**Design implication:** the pre-import scan summary and the round-trip export are the two moments that make or break trust — both must be visible UI, not silent background steps.

---

## Journey 2 — Daily capture → journal → link → task

**Primary persona:** Logseq Outliner (also core loop for all personas) · **Platform:** iPhone (capture), Mac (review)

### Storyboard

1. User opens NoteBytez on iPhone during the day. Today's journal page is already created and open.
2. Types a quick line: a meeting note, an idea, a to-do.
3. Types `[[` and gets autocomplete to link the entry to an existing note (a project or person).
4. Types `#` and adds a tag to the line for later browsing/filtering.
5. Marks the line as a task with `- [ ]` syntax.
6. Later, on Mac, opens the same journal entry (synced via CloudKit), sees the backlink now appears on the linked note's Backlinks pane.
7. Toggles the task to done from either the journal or the linked note — state is the same object either place.
8. Next day, uses Previous/Next day navigation to glance back at yesterday's journal for anything left open.

**Circumstances:** Happens many times a day, in short bursts, often one-handed on a phone. Any friction here (extra taps, lost autocomplete, unclear task state) breaks the daily habit the product depends on.

### Journey Map

| Stage | Action | Thought | Emotion | Touchpoint (MVP feature) |
|---|---|---|---|---|
| Open | Launches app, journal is already there | "No 'where does this go' decision" | Frictionless | Daily journal (auto-created today page) |
| Capture | Types the note | "Just get it down" | Focused | Basic journal template |
| Link | Types `[[` , autocompletes | "Connected without leaving the flow" | Satisfied | Backlinks (wikilink parsing + autocomplete) |
| Tag | Types `#tag` inline | "Categorized without a separate step" | Efficient | Tagging (inline `#tag` parsing) |
| Mark | Adds `- [ ]` checkbox | "That's now a task, not just text" | Confident | Basic tasks (checkbox syntax) |
| Reconcile | Sees same note/task on Mac later | "It's actually the same object everywhere" | Trusting | CloudKit private sync |
| Review | Toggles task done, checks yesterday | "Nothing fell through" | In control | Basic tasks (toggle), journal prev/next nav |

**Design implication:** journal → link → task must be achievable without leaving the text-entry context (no modal detours) — this is the single highest-frequency flow in the product.

---

## Journey 3 — Sync status → conflict encountered → resolved

**Primary persona:** Logseq Outliner (data-loss anxious) · **Platform:** All three (conflict can surface anywhere)

### Storyboard

1. User edits the same note on iPhone (offline, on a flight) and on Mac (online) before the iPhone reconnects.
2. iPhone reconnects; CloudKit sync runs. NoteBytez detects the note was edited in both places since the last sync.
3. Sync status indicator changes from "Synced" to "Conflict" with a badge on the affected note.
4. User opens the sync log, sees which note conflicted and when each version was saved.
5. Per their chosen conflict strategy (set in Settings): either sees a merge banner (Last-Write-Wins + Banner), a diff-merge result (Markdown Diff-Merge), or both versions kept side by side (Keep All Versions).
6. User reviews and, if using Keep-All or Banner mode, manually picks/merges content.
7. Sync status returns to "Synced" once resolved.

**Circumstances:** Low-frequency but high-stakes — this is the moment that determines whether the persona trusts the product long-term. Must never happen silently.

### Journey Map

| Stage | Action | Thought | Emotion | Touchpoint (MVP feature) |
|---|---|---|---|---|
| Unaware | Edits offline on iPhone | (no awareness of conflict yet) | Neutral | Local library |
| Reconnect | iPhone comes online, sync runs | "Is this going to just overwrite something?" | Wary | CloudKit private sync, visible sync log |
| Notice | Sees conflict badge on note | "At least it told me" | Alert, not alarmed | Sync status indicator |
| Investigate | Opens sync log for detail | "I can see exactly what happened" | Reassured | Visible sync log (last-synced timestamp, error surfacing) |
| Resolve | Handles conflict per chosen strategy | "Nothing was thrown away" | Relieved | Conflict handling (Keep All / Banner / Diff-Merge) |
| Confirm | Status returns to Synced | "Back to normal" | Confident | Sync status indicator |

**Design implication:** the conflict badge and sync log must be reachable in ≤2 taps from anywhere, and the three conflict strategies need visually distinct resolution UI since they behave very differently (manual pick vs. banner-accept vs. diff review).

---

## Journey 4 — Exploring the graph to resurface a forgotten note

**Primary persona:** Obsidian Archivist (large library, half-remembered notes) · **Platform:** Mac (spatial exploration), iPad secondary

### Storyboard

1. User is writing a new note and has a vague memory of "something I wrote about this months ago" but doesn't remember the title.
2. Tries Exact Search first with a guessed keyword — gets partial results, not quite it.
3. Opens the current note's local graph view to see what it's directly linked to, hoping to spot a familiar neighbor.
4. Doesn't find it there either — the note isn't linked to the current one at all.
5. Falls back to Quick Switcher and searches by tag instead of title, then opens the Tag Browser to scan the full tag list since they only half-remember the tag name.
6. Finds the note. Opens it, sees its Backlinks pane, and realizes it connects to two other notes they'd also forgotten were related.
7. Adds a new `[[link]]` from today's note to the rediscovered one, closing the loop.

**Circumstances:** Unplanned, interrupt-driven — happens mid-task when the user's own memory is the bottleneck, not the tool. Failure here means the user gives up and re-writes something that already exists.

### Journey Map

| Stage | Action | Thought | Emotion | Touchpoint (MVP feature) |
|---|---|---|---|---|
| Search | Tries a keyword guess | "I know I wrote this somewhere" | Mildly frustrated | Exact search (FTS) |
| Explore | Opens local graph on current note | "Maybe it's a neighbor" | Hopeful | Simple graph (current note + direct links) |
| Miss | Graph doesn't show it | "Not linked, so not here" | Frustrated | Simple graph (limits acknowledged — no filters/forces in MVP) |
| Pivot | Switches to tag search, then Tag Browser | "Let me try how I organized it, not what I called it" | Determined | Search by tag and file/path, Quick Switcher, Tag browser |
| Find | Locates the note, reviews backlinks | "Oh — and it connects to two other things" | Delighted | Backlinks pane |
| Close loop | Links today's note to it | "Now it won't get lost again" | Satisfied | Backlinks (wikilink creation) |

**Design implication:** because MVP's Simple Graph is intentionally shallow (current note + direct links only, no clustering), Search and Quick Switcher — not the graph — are the real resurfacing tools in MVP. The graph should not overpromise what it can find; search/tag entry points need to be one tap away from the graph view, not buried.

---

## Journey 5 — Capturing a loose idea, promoting it into a project notebook

**Primary persona:** Dual-Tool Migrator (also core to Logseq Outliner's "capture without deciding" goal) · **Platform:** iPhone (capture), Mac (organizing into a notebook)

### Storyboard

1. User jots a rough idea into today's journal — no decision yet about whether it's a real project.
2. Over the following days, related thoughts land in other journal entries, loosely tied together by wikilinks/tags but not yet organized anywhere.
3. The idea firms up into something worth tracking as its own effort. On the journal entry, the user long-presses (iPhone/iPad) or right-clicks (Mac) the block and chooses "Promote to Notebook."
4. A sheet opens: pick an existing Notebook, or create a new one by name.
5. NoteBytez creates a new Document inside that Notebook, seeded with the promoted content, and inserts a `[[wikilink]]` on both the new Document and the original journal entry so the two stay connected.
6. User opens the Notebook Browser, sees the new (or updated) Notebook and its Document.
7. Over the following weeks, the user adds more Documents to the Notebook directly — no more promotion needed, this is now the project's home.
8. Returning to the original journal entry later, the backlink shows the promoted note still there — the idea was never re-typed and never got lost.

**Circumstances:** Low-frequency compared to daily capture (Journey 2), but the moment that determines whether Journal and Notebook feel like one coherent system or two disconnected buckets. Must never feel like a "move" that could lose the original entry — the journal entry stays exactly where it was.

### Journey Map

| Stage | Action | Thought | Emotion | Touchpoint (MVP feature) |
|---|---|---|---|---|
| Capture | Jots the idea in today's journal, undecided | "Not going to overthink where this goes" | Unburdened | Daily journal |
| Accumulate | More related thoughts land in later journal entries | "This keeps coming up" | Curious | Daily journal, Backlinks/tags |
| Decide | Selects the block, taps "Promote to Notebook" | "This is actually a real thing now" | Committed | Promote to Notebook |
| File | Picks an existing Notebook or names a new one | "Does this belong somewhere I already started, or is it new?" | Deliberate | Notebooks (create/select) |
| Confirm | New Document appears in the Notebook, backlink visible on the journal entry | "Nothing got retyped, nothing got lost" | Reassured | Promote to Notebook (auto-backlink), Notebooks |
| Build | Adds further Documents to the Notebook directly | "This is the project's home now" | Focused | Notebooks, Documents + stable blocks |
| Trace back | Revisits the original journal entry weeks later | "I can still see where this started" | Trusting | Backlinks pane |

**Design implication:** Promote to Notebook must read as *copy-and-link*, never *move* — the source journal entry is untouched and still shows the idea in its original context. The "pick existing vs. create new" choice needs to be the same single decision point every time, so it doesn't add a second flow to learn on top of daily capture.

---

## Cross-journey notes

- All five journeys stay within MVP scope: no Canvas, no properties, no AI, no sharing.
- Journeys 2 and 3 are the highest-frequency and highest-stakes flows respectively — they should get priority in wireframing (05) and drive the component inventory (06).
- Every journey terminates in a state the user can independently verify (exported file, synced badge, resolved conflict, closed link loop, promoted note with intact backlink) — consistent with the "never silently lose an edit" principle from [01-Personas.md](01-Personas.md).

---

## Journey 6 — Building a structured entity with Properties and a Note Template

**Primary persona:** Universe Architect ([01-Personas.md](01-Personas.md) §4) · **Platform:** Mac (drafting session)

### Storyboard

1. User is deep in worldbuilding for book two of a series and needs to add a new Character.
2. Opens the Template Picker inside the series' Notebook, selects the "Character" NoteTemplate from their "Fiction Writing" TemplateGroup (one of the starter groups, or one they've customized).
3. A new Document is created, pre-filled with the template's Property fields: Name, Species, Homeworld, Affiliation, Status (typed: text/text/text/text/checkbox).
4. User fills in the values, adds `#antagonist` and `#act2` tags, and writes free-text backstory below the properties.
5. Later, wants to see every Character tagged `#antagonist` who also appears in `#act2` — runs an Advanced Search boolean query across tags.
6. Saves that query as a Saved View named "Act 2 Antagonists" so it's one tap away next time, instead of re-typing the query.
7. Months later, applies the same "Character" template retroactively to an older, pre-template Character note that's missing some fields, backfilling Properties without re-creating the Document.

**Circumstances:** Low-frequency per entity (a handful of new Characters/Planets/etc. per week during active worldbuilding) but foundational — every other V1 capability for this persona (Saved Views, Advanced Search-by-property) depends on Properties actually being filled in consistently, so the creation moment has to be fast enough that the user doesn't skip it and fall back to free text.

### Journey Map

| Stage | Action | Thought | Emotion | Touchpoint (V1 feature) |
|---|---|---|---|---|
| Reach for structure | Opens Template Picker in the Notebook | "I don't want to rebuild the Character fields again" | Efficient | Note templates (picker scoping) |
| Create | Picks "Character" template | "This is my own system, not the app's" | In control | Note templates, Properties |
| Fill in | Enters typed field values | "Species and Homeworld are actually queryable now" | Satisfied | Properties (typed metadata) |
| Compose | Writes free-text backstory below the fields | "Structure and prose live in the same note" | Natural | Documents + stable blocks (MVP), Properties |
| Query | Boolean search across tags | "Now I can ask a real question" | Empowered | Advanced search |
| Pin | Saves the query as a Saved View | "One tap next time" | Relieved | Saved views |
| Retrofit | Applies the template after the fact to an old note | "I didn't have to start over" | Reassured | Note templates (apply-after-the-fact) |

**Design implication:** Property fields and free-text content must render in one continuous document, not a separate "metadata panel vs. body" split that feels like filling out a form before you're allowed to write — the Universe Architect's whole complaint (per [NoteBytez-PersonaAuthorValidation.md](../NoteBytez-PersonaAuthorValidation.md)) is not wanting to feel like she's "building a database."

---

## Journey 7 — Laying out a plot on Canvas

**Primary persona:** Obsidian Archivist (Canvas is already listed among her skills in [01-Personas.md](01-Personas.md) §1) · **Platform:** Mac (spatial layout), iPad secondary (touch-first canvas manipulation)

### Storyboard

1. User is untangling a multi-threaded mystery plot and text alone isn't cutting it — she needs to see the pieces spatially.
2. Creates a new Canvas board from the Notebook.
3. Drags existing Documents onto the canvas as note cards (a card per suspect, per clue, per timeline event).
4. Adds a web card linking to a real-world reference article she's using for research.
5. Draws labeled connectors between cards ("alibi conflicts with," "reveals"), groups the "Act 1" cluster visually apart from "Act 2."
6. Pans/zooms to review the whole board, then zooms into one cluster to add detail.
7. Exports the board as a `.canvas` file (JSON Canvas format) to hand to a co-writer who uses Obsidian.

**Circumstances:** Occasional, session-based (a planning sitting, not a daily habit) but high-value when it happens — this is the moment Canvas either proves it belongs inside NoteBytez or feels like a bolted-on extra.

### Journey Map

| Stage | Action | Thought | Emotion | Touchpoint (V1 feature) |
|---|---|---|---|---|
| Reach for space | Creates a new Canvas board | "Text isn't enough for this" | Determined | Canvas |
| Populate | Drags Documents on as note cards | "My existing notes, just spatial now" | Fluent | Canvas (note cards), Documents (MVP) |
| Reference | Adds a web card | "External research lives right next to my notes" | Convenient | Canvas (web cards) |
| Connect | Draws labeled connectors, groups clusters | "Now I can see the shape of the plot" | Clarity | Canvas (connectors, groups) |
| Review | Pans/zooms across the board | "Nothing feels cramped" | Comfortable | Canvas (pan/zoom) |
| Share | Exports as `.canvas` (JSON Canvas) | "My co-writer can open this without NoteBytez" | Trusting | Canvas (JSON Canvas export) |

**Design implication:** JSON Canvas export/import ([NoteBytez-R1-Implementation.md](../NoteBytez-R1-Implementation.md) Decisions Log #2) is what keeps this from being a proprietary dead end — the escape hatch matters here exactly as much as it did for Markdown export in Journey 1.

---

## Journey 8 — Sharing a research space with a collaborator

**Primary persona:** Obsidian Archivist · **Secondary:** Dual-Tool Migrator · **Platform:** Mac (invite/manage), all three for the invited collaborator

### Storyboard

1. User has been building a reference library for a joint project and wants a co-researcher to read and contribute.
2. Opens Sharing from the Library, invites the collaborator by email/Apple ID, sets their permission level to read-write.
3. Collaborator accepts the invite on their own device; the shared Library appears alongside their own libraries.
4. Both edit notes independently over the following days.
5. One evening, both edit the same note within minutes of each other. A conflict surfaces exactly like Journey 3's — except this time the sync log attributes each version to the collaborator by name, not just "this device"/"other device."
6. Owner reviews and resolves using their chosen conflict strategy, same UI as Journey 3.
7. Owner later changes the collaborator's permission to read-only for a section of the work that's now considered final.

**Circumstances:** Low-frequency setup, ongoing low-friction use afterward — the setup moment (invite, permission choice) needs to feel as safe and reversible as everything else in the product; the Outliner persona's "never silently lose an edit" promise now has to hold across two people, not one.

### Journey Map

| Stage | Action | Thought | Emotion | Touchpoint (V1 feature) |
|---|---|---|---|---|
| Decide to share | Opens Sharing from the Library | "Is this going to be safe?" | Cautious | CloudKit Sharing |
| Invite | Sets permission level, sends invite | "I control exactly what they can touch" | Confident | CloudKit Sharing (per-participant permission levels) |
| Accept | Collaborator accepts on their device | "It's just... there now" | Smooth | CloudKit Sharing |
| Collaborate | Both edit independently | (no friction, business as usual) | Productive | CloudKit private sync (MVP), extended |
| Conflict | Same note edited by both within minutes | "Whose version is this?" | Wary, but familiar (same UI as Journey 3) | Conflict handling, extended with named-collaborator attribution |
| Resolve | Reviews and picks/merges per strategy | "I know exactly who changed what" | Reassured | Conflict handling (collaborator-attributed) |
| Adjust | Downgrades permission on finished sections | "I can still lock things down later" | In control | CloudKit Sharing (permission levels, changeable) |

**Design implication:** extending Journey 3's conflict UI to name a collaborator, rather than building a separate multi-user conflict screen, is what makes sharing feel like an extension of a trusted system instead of a second, riskier one.

---

## Journey 9 — Migrating with the dedicated Migration Assistant

**Primary persona:** Dual-Tool Migrator · **Platform:** Mac

### Storyboard

1. User has decided to fully retire her Obsidian+Logseq combo and commit to NoteBytez.
2. Opens the Migration Assistant (distinct from MVP's generic "Import existing Markdown folder" — this one asks which tool the vault came from first).
3. Points it at her Obsidian vault. It auto-detects Obsidian's markers, scans and previews wikilinks, YAML properties, and `.canvas` files, in addition to everything MVP's importer already handled.
4. Confirms; Obsidian's typed properties become real NoteBytez Properties, `.canvas` boards import as Canvas boards, not flattened text.
5. Repeats the process pointing at her Logseq graph. It auto-detects Logseq's markers instead, previews block-outline structure, journals, and `TODO`/`DONE` tasks.
6. One Logseq page used a `{{query}}` block the Assistant can't faithfully translate — it's flagged in the scan summary as "not migrated, view original" rather than silently dropped or guessed at.
7. Both original vaults are preserved as read-only archives inside the new library, so nothing about the migration is a one-way door.

**Circumstances:** Once, at the point of full commitment — this is the highest-trust-required moment in the whole product for this persona, since it's the last time she'll touch her old tools at all.

### Journey Map

| Stage | Action | Thought | Emotion | Touchpoint (V1 feature) |
|---|---|---|---|---|
| Commit | Opens the Migration Assistant | "This time it's for real" | Resolved | Migration assistants |
| Detect | Points at Obsidian vault, format auto-detected | "It already knows what this is" | Reassured | Migration assistants (Obsidian importer) |
| Preview | Reviews scan: properties, canvas files included | "Nothing about my structure gets flattened" | Encouraged | Migration assistants, Properties, Canvas |
| Repeat | Points at Logseq graph, format auto-detected | "Same trust, second tool" | Confident | Migration assistants (Logseq importer) |
| Flag | Sees an unsupported `{{query}}` block called out | "It told me instead of guessing" | Trusting | Migration assistants (unsupported-pattern flagging) |
| Archive | Both originals kept as read-only archives | "I can still go back and check" | Secure | Migration assistants (archive preservation) |

**Design implication:** the "flag, don't guess" handling of an unsupported Logseq query pattern is what separates a trustworthy migration assistant from a lossy one — silently dropping or mis-translating content here would be worse than not attempting the migration at all, for a persona whose whole profile is built on "trust risk."

---

## Cross-journey notes (Version 1)

- Journeys 6-9 extend into V1 scope: Properties + Note templates, Canvas, CloudKit Sharing, and the dedicated Migration Assistant.
- Journey 6 is foundational for the Universe Architect persona ([01-Personas.md](01-Personas.md) §4) — Saved Views and Advanced Search-by-property both depend on Properties actually being populated, which is why its design implication focuses on making structured fields feel native rather than a database chore.
- Journey 8 deliberately reuses Journey 3's conflict-resolution UI rather than inventing a new one — sharing safety is judged by the same "never silently lose an edit" bar the MVP personas already hold the product to.
- Journey 9 supersedes Journey 1 for users who complete it — J1's generic Markdown import remains the right entry point for a first-run library with no prior tool, while J9's dedicated Assistant is for a deliberate, tool-aware migration.
- All four journeys terminate in an independently verifiable state (queryable Properties, an exported `.canvas` file, a resolved named-collaborator conflict, an archived original vault), consistent with the same principle [01-Personas.md](01-Personas.md) established for MVP.
