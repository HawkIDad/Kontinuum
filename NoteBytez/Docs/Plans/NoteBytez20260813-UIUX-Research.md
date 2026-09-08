<!-- NoteBytez20260813-UIUX-Research.md -->
<!--
  Creating the baseline UI/UX documentation.
-->

# User Story
As a UI/UX expert - review the Research and Release Features markdown documents. I need you to evaluate what is being proposed in this document and create: 

- User Personas
  - Identify the various users, their goals, motivations, frustrations, and skills.
  
- Storyboards
  - Outline of the user's actions.
  - Circumstances under which these actions are performed.
  
- Customer Journey Maps
  - Lay the process out along a timeline.
  
- Feature/Function to User Marriage
  - Lay out how each feature or function solves a need of the user.
  
- Interaction Design
  - Flowcharts to visualize user interactions - sitemaps and userflows.
  
- Interface Design / Mockups
  - Wireframes - the proposed ideas/solutions of the visual design.
  
- Design System
  - Reusable components and guidelines that people can use to combine into interfaces and interactions.
     - Style Guide.
     - User Interface Standards.
     - Common User Interface Components/Widgets.

# Success Factors

1. As a UI/UX Expert, the AI will interview me and produce the deliverables identified in the User Story.
2. All documents will be stored in the following folder: NoteBytez/Docs/Plans

---

# Gaps Identified (pre-interview)

The original User Story is a request, not a scoped research plan. Gaps that would have blocked execution:

1. Target audience in [NoteBytez20260813-Research.md](Docs/Plans/NoteBytez20260813-Research.md) §6 is broad (executives, researchers, engineers, writers, students, PKM power users) — no primary persona set.
2. No roadmap phase specified — [NoteBytez-ReleaseFeatures.md](Docs/Plans/NoteBytez-ReleaseFeatures.md) splits scope into MVP/V1/Advanced; UI/UX for all three is a different-sized effort than MVP alone.
3. No deliverable format specified for wireframes — this is a markdown-only repo (no Figma/Sketch file, no existing mockup tooling).
4. CLAUDE.md references `{application}/docs/styleGuide.md` as the base design reference — file does not exist. No existing brand assets (colors, typography, logo) found anywhere in the repo.
5. No platform priority — MVP targets iPhone, iPad, and Mac; wireframe depth per platform was unspecified.
6. No named user journeys/tasks to storyboard — "outline of the user's actions" needed concrete scenarios to be tractable.

# Clarifications (from interview, 2026-08-13)

- **Persona focus:** PKM power users migrating from Obsidian/Logseq (the research doc's primary target). Executives/students/generalist knowledge workers are out of scope for this pass.
- **Phase scope:** MVP only — local library, markdown import/export, documents + stable blocks, backlinks, tagging, daily journal, basic tasks, exact search, simple graph, CloudKit private sync, visible sync log, backups, conflict handling. V1/Advanced features (Canvas, AI, sharing, plugins, block references) are explicitly excluded from personas/journeys/wireframes.
- **Wireframe format:** Low-fidelity SVG/ASCII wireframes embedded directly in markdown — layout/hierarchy only, no visual styling.
- **Design system base:** No existing brand direction. Propose an Apple HIG-aligned starting point (system fonts, SF Symbols, standard iOS/iPadOS/macOS spacing and color roles) as the default for a native SwiftUI app.
- **Platform coverage:** Equal detail for iPhone, iPad, and Mac — full wireframe set per platform, not a primary-platform-plus-adaptations approach.
- **Journeys to storyboard (all four):**
  1. Migrating a library from Obsidian/Logseq (first-run import, trust in translated wikilinks/blocks/journals)
  2. Daily capture → journal → link → task (the core day-to-day loop)
  3. Sync status → conflict encountered → resolved (visible sync log, resolution-strategy picker)
  4. Exploring the graph to resurface a forgotten note (local graph, backlinks pane, search)
  5. Capturing a loose idea in the journal, promoting it into a project notebook (added after Notebooks/Promote to Notebook joined MVP scope — see [NoteBytez-ReleaseFeatures.md](NoteBytez-ReleaseFeatures.md))

# Scope Note

Equal-fidelity wireframes across 3 platforms × 5 journeys × MVP's full feature list is a large document. To keep each file reviewable, the research will be split into linked files under `Docs/Plans/UIUX/` rather than one monolithic markdown file, per NoteBytez's `CLAUDE.md` "Simplicity First" guidance. This document remains the index/entry point.

# Execution Plan

1. **Personas** ([Docs/Plans/UIUX/01-Personas.md](Docs/Plans/UIUX/01-Personas.md)) — 2–3 personas within the Obsidian/Logseq power-user segment (e.g., Obsidian-native, Logseq-native, hybrid/dual-tool user), each with goals, motivations, frustrations, skill level.
   → Verify: every persona's stated frustration maps to a specific pain point already documented in [NoteBytez20260813-Research.md](Docs/Plans/NoteBytez20260813-Research.md) §4.

2. **Storyboards + Customer Journey Maps** ([Docs/Plans/UIUX/02-Journeys.md](Docs/Plans/UIUX/02-Journeys.md)) — the 5 selected journeys, each as an action outline (storyboard) plus a timeline (journey map: stages, actions, thoughts, emotions, touchpoints).
   → Verify: every step in each journey references only MVP-scope features (no V1/Advanced).

3. **Feature/Function to User Marriage** ([Docs/Plans/UIUX/03-FeatureMarriage.md](Docs/Plans/UIUX/03-FeatureMarriage.md)) — table mapping each MVP feature bullet from [NoteBytez-ReleaseFeatures.md](Docs/Plans/NoteBytez-ReleaseFeatures.md) to the persona need(s) it solves.
   → Verify: every MVP feature bullet appears at least once; no orphaned features or unsupported persona needs.

4. **Interaction Design** ([Docs/Plans/UIUX/04-InteractionDesign.md](Docs/Plans/UIUX/04-InteractionDesign.md)) — sitemap (screen inventory per platform) and userflow flowcharts for the 5 journeys.
   → Verify: every screen referenced in a flowchart has a corresponding wireframe in step 5.

5. **Interface Design / Wireframes** ([Docs/Plans/UIUX/05-Wireframes.md](Docs/Plans/UIUX/05-Wireframes.md)) — low-fidelity SVG/ASCII wireframes, one set per platform (iPhone/iPad/Mac), for each screen in the sitemap.
   → Verify: every flowchart screen from step 4 has a wireframe on all 3 platforms.

6. **Design System** ([Docs/Plans/UIUX/06-DesignSystem.md](Docs/Plans/UIUX/06-DesignSystem.md)) — Apple HIG-aligned style guide (type, color roles, spacing), UI standards (navigation patterns, state conventions), and a component inventory.
   → Verify: every component/widget used across the step-5 wireframes appears in the inventory.

This document (`NoteBytez20260813-UIUX-Research.md`) will be updated with links to each file as it's completed.

# Deliverables

1. [Personas](Docs/Plans/UIUX/01-Personas.md) — Obsidian Archivist, Logseq Outliner, Dual-Tool Migrator
2. [Storyboards & Customer Journey Maps](Docs/Plans/UIUX/02-Journeys.md) — migration, daily capture loop, sync conflict, graph resurfacing, journal-to-notebook promotion
3. [Feature/Function to User Marriage](Docs/Plans/UIUX/03-FeatureMarriage.md) — every MVP feature mapped to persona needs
4. [Interaction Design](Docs/Plans/UIUX/04-InteractionDesign.md) — sitemap + Mermaid userflow flowcharts
5. [Interface Design / Wireframes](Docs/Plans/UIUX/05-Wireframes.md) — ASCII wireframes, 15 screens × iPhone/iPad/Mac
6. [Design System](Docs/Plans/UIUX/06-DesignSystem.md) — Apple HIG-aligned style guide, UI standards, component inventory

All six coverage checks pass: every persona frustration traces to a documented pain point, every MVP feature bullet is mapped, every journey stays MVP-scope, every flowchart screen has a wireframe on all three platforms, and every wireframe component is inventoried in the design system.
