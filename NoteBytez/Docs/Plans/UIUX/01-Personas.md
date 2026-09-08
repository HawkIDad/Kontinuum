<!-- 01-Personas.md -->
<!--
  Part of the NoteBytez UIUX Research deliverable set. See ../../../NoteBytez20260813-UIUX-Research.md for scope/plan.
  Persona segment: PKM power users migrating from Obsidian/Logseq (MVP scope only).
-->

# Personas

Three personas cover the Obsidian/Logseq power-user segment. Each frustration is traced to a documented pain point in [NoteBytez20260813-Research.md](../NoteBytez20260813-Research.md) §4 so the mapping is verifiable, not invented.

---

## 1. The Obsidian Archivist

**Archetype:** File-first knowledge hoarder. Treats the library as a permanent research archive.

- **Goals:** Own every note as a plain file forever; never be locked into a proprietary format; build a large, densely cross-linked reference library over years.
- **Motivations:** Data portability and longevity. Has already lost data once to a closed tool and won't repeat it.
- **Skills:** High. Comfortable with YAML frontmatter, regex search, a curated plugin stack (Tasks, Dataview-adjacent views), Canvas.
- **Platforms:** Mac primary (multi-window, large library), iPad for reading/annotating, iPhone rarely (quick capture only).

**Frustrations → Research pain point (§4):**
| Frustration | Source |
|---|---|
| Advanced task management, dashboards, and AI only work after installing/configuring plugins | "Obsidian's key UX challenge is configuration complexity... advanced task management, AI, dashboards, database-like views... rely on choosing, configuring, and maintaining plugins." |
| Mobile app feels like a degraded desktop port — slow loads, full reloads after app-switching, missing desktop plugins | "slow iOS/iPadOS loading, full reloads after app switching, desktop plugin gaps on mobile, weaker mobile clipping, limited quick capture" |
| Doesn't fully trust automatic sync merges on Canvas/non-Markdown files | "canvases and other non-Markdown files use last-modified-wins... conflict-resolution preferences are device-specific" |

**What NoteBytez must earn from this persona:** proof that Markdown export/import is real and lossless (§ Documents + stable blocks, Markdown import/export), and that mobile isn't an afterthought.

---

## 2. The Logseq Outliner

**Archetype:** Block-first daily thinker. Journal is the entry point for everything; structure emerges later.

- **Goals:** Capture fast without deciding where something belongs; query across journals for tasks and recurring topics; keep blocks addressable and remixable.
- **Motivations:** Low-friction capture; distrust of rigid folder/schema systems decided in advance.
- **Skills:** Medium-high. Comfortable with block references and basic queries, but not a developer; never wrote a plugin.
- **Platforms:** iPhone primary (capture on the go), Mac for review/writing sessions, iPad occasional.

**Frustrations → Research pain point (§4):**
| Frustration | Source |
|---|---|
| Worried about outright data loss, not just inconvenience | Logseq README: "DB version is beta... mobile app and RTC are alpha... data loss is possible," recommending backups and test graphs |
| Has personally hit sync problems moving between devices | "GitHub issue reported major data loss while using Logseq Sync with smart merge enabled... Reddit thread contains multiple anecdotal reports of missing blocks/attributes" |
| Uneasy about the app's own stability under normal use | "recent issues around DB persist, graph loading, query rendering, search, import, and mobile/app packaging" |

**What NoteBytez must earn from this persona:** a visible, trustworthy sync log and a conflict strategy that never silently discards an edit (§ Visible sync log, § Conflict handling). Also: a way to capture without deciding where something belongs, then organize it later without retyping — this is what Notebooks + Promote to Notebook are for (§ Notebooks, § Promote to Notebook).

---

## 3. The Dual-Tool Migrator

**Archetype:** Runs Obsidian and Logseq side by side today — Obsidian as the durable reference vault, Logseq for daily journaling — because neither product does both well.

- **Goals:** Collapse two tools into one without losing what each was good at (Obsidian's durability, Logseq's capture speed); stop manually reconciling notes that exist in both places.
- **Motivations:** Tool fatigue. Every context switch between apps costs time and breaks the linking model (Obsidian wikilinks vs. Logseq block refs don't map onto each other).
- **Skills:** High — this is the most technically confident persona; understands both products' data models well enough to feel their seams.
- **Platforms:** All three equally — Mac for deep work, iPad for reading/reviewing, iPhone for capture, switching mid-task between devices.

**Frustrations → Research pain point (§4):**
| Frustration | Source |
|---|---|
| Configuration burden on the Obsidian side | "much of the advanced experience depends on user configuration and third-party plugins" |
| Trust/stability risk on the Logseq side | "DB version is beta... data loss is possible" |
| No single tool combines file durability with block-level thinking | Executive thesis: "the opportunity is not to clone either product; it is to combine Obsidian's file durability... with Logseq's block-level thinking" |

**What NoteBytez must earn from this persona:** that documents + addressable blocks (§ Documents + stable blocks) genuinely replace *both* tools, not just one — including the split this persona already lives by: Obsidian as the durable reference vault, Logseq for daily journaling. NoteBytez's Journal/Notebook split (§ Notebooks) is that same distinction inside one app, one library, one sync engine.

---

## 4. The Universe Architect

**Archetype:** World-builder and long-form fiction author. Treats the library as the single source of truth for an entire fictional universe spanning multiple books. Formally admitted here per [NoteBytez-PersonaAuthorValidation.md](../NoteBytez-PersonaAuthorValidation.md) — that document found this persona **not servable in MVP** and deferred it until Properties and Note templates (Version 1) existed to make it real.

- **Goals:** Track structured, cross-referenceable detail — stellar systems, characters, character arcs, plot lines, chapters, artifacts, technology — without hand-rolling a schema in prose; view the same material through different combinations (by character, by act, by unresolved plot thread) without a separate query tool.
- **Motivations:** Story consistency across a long series. A contradiction discovered in book three of a trilogy is expensive to fix; catching it while drafting book one is free.
- **Skills:** Medium. Comfortable with tags and links from other writing tools, but not a developer — expects a form-like editor for structured fields, not YAML hand-editing.
- **Platforms:** Mac primary (long drafting sessions, multi-window reference lookup), iPad for research reading, iPhone for capturing a scene idea on the go.

**Frustrations → Source:**
| Frustration | Source |
|---|---|
| No first-class way to give a note typed, filterable fields (a Character's species, a Planet's star system) — everything is either free text or a tag | [NoteBytez-PersonaAuthorValidation.md](../NoteBytez-PersonaAuthorValidation.md) §Validation Against Current Plan: "No built-in entity schema... **Gap until V1**" |
| Wants reusable structure across many similar entities (every Character note needs the same fields) without rebuilding it by hand each time | [NoteBytez-PersonaAuthorValidation.md](../NoteBytez-PersonaAuthorValidation.md) §Findings #1: "core need — structured, filterable, cross-referenced entity types — depends on Properties and Note templates" |
| Compound questions ("characters who are `#antagonist` AND appear in `#act2`") aren't answerable with tag browsing alone | [NoteBytez-PersonaAuthorValidation.md](../NoteBytez-PersonaAuthorValidation.md) §Findings #3 |

**What NoteBytez must earn from this persona:** proof that structured entity modeling doesn't mean a proprietary Character/Location schema imposed by the app — Properties (typed fields) and Note Templates (reusable, user-authored field sets) must feel like the user built their own system, not that they're filling in NoteBytez's forms (§ Properties, § Note templates). Unlike the other three personas, this one has no MVP entry point at all — every touchpoint she needs is Version 1 scope.

---

## Cross-persona summary

| | Archivist | Outliner | Dual-Tool Migrator | Universe Architect |
|---|---|---|---|---|
| Primary need | Portability, no lock-in | Trustworthy sync, no data loss | One tool instead of two | Structured, filterable entity modeling |
| Skill level | High | Medium-high | High | Medium |
| Primary platform | Mac | iPhone | All three, equally | Mac |
| Biggest risk to NoteBytez adoption | "This is just another walled garden" | "This will eat my notes like Logseq almost did" | "This is worse than my current two-tool setup" | "This makes me build a database, not write a book" |

All four personas share one non-negotiable: **never silently lose an edit** — this is the throughline for the journey maps and interaction design that follow. The Universe Architect adds a second, Version-1-specific one: **structure must never feel like the app's schema, only the user's own.**
