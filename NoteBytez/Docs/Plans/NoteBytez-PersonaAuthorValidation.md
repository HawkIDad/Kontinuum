<!-- NoteBytez-PersonaAuthorValidation.md -->
<!--
    This document will describe a user scenario and then use that information to confirm
    the UI/UX information is will support the given scenario - Personas, Journeys, Feature Marriage,
    Interactive Desgin, Wireframes and Design System.
-->
#  Persona Author Validation

An an Author of Science Fiction Space Novels, I want to be able to use NoteBytez to record, track, and validate the research needed for me to author various books.

I need to be able to define and create universes that will contain a book or series of books. This universe will track all information that I need, allowing me to cross reference notes and material.

    - Specific features/conditions of the universe that the series and books live within.
    - Specific information about individual series or books.
    - Specific information about stellar systems, planets, and moons.
    - Specific information characters.
    - Specific information about the overall character arcs.
    - Specific information about the books plot lines and sub-plots.
    - Specific inforamtion about individual chapters.
    - Specific information about chapter scenes/locations.
    - Specific information about artifacts.
    - Specific information about technology.
    
They system should allow me to associate information together in different combinations to allow me to have various views into relationships that are needed when analyzing how to progress the story, characters, plot lines, etc.

    - Tags to create ways to associate various pieces of data.
    - Links to internally generated data within NoteBytez.
    - Links to external information via URLs.

---

## Validation Against Current Plan (2026-08-15)

| Need | Supported by | Status |
|---|---|---|
| Tags to associate data | Tagging (MVP) | Supported |
| Links to internal NoteBytez data | Backlinks/wikilinks (MVP); Block references (V1) for citing a specific scene/paragraph rather than a whole chapter note | Supported |
| Links to external URLs | External links, `[text](url)` (MVP — added as a result of this review; was previously unstated) | Supported |
| Universe/series/book containment | No first-class "Universe" container. Maps to either (a) a Universe document with wikilinks out to its books/series, or (b) one library per universe (MVP Library creation/selection) if hard separation is wanted. Choice affects search/graph scope, since both are library-scoped — not yet decided | Workable via convention, not a named feature |
| Stellar systems, planets, moons, characters, character arcs, plot lines/sub-plots, chapters, scenes/locations, artifacts, technology | No built-in entity schema (deliberate — see Decisions Log in [NoteBytez-ReleaseFeatures.md](NoteBytez-ReleaseFeatures.md)). Built by the user from Documents + typed Properties + **Note templates** (new V1 feature added as a result of this review) | **Gap until V1** — MVP alone (Documents + Tags + Backlinks + Search + simple Graph) gives only unstructured, convention-based organization; no typed fields, no filter-by-field |
| Various views into relationships, for story/plot analysis | Tag Browser + Backlinks pane (MVP) for single-hop relationship browsing (open a Chapter/Character/Act, see everything linking to it); Advanced Search boolean tag operators (V1, e.g. `#character AND #act2 NOT #resolved`) for compound combinations; Saved Views (V1) to pin a combination as a persistent view | **Resolved** — no new query engine needed. Tags + Links are the base mechanism; V1's boolean search closes the "different combinations" requirement. |

### Findings

1. **This persona is not servable in MVP.** Its core need — structured, filterable, cross-referenced entity types — depends on Properties and Note templates, both V1. MVP gives partial value (generic notes + tags + links + search), not the "various views into relationships" the story requires.
2. **Entity modeling is deliberately generic, not built-in.** An earlier version of NoteBytez's `CLAUDE.md` carried leftover UI-renaming rules for `Actor`→Character and `Backdrop`→Scene models, plus a `StellarType` model example — copy-paste residue from a sibling project, not evidence of intended scope. That's been removed. NoteBytez will not ship built-in Character/Location/Item schemas; users build their own via Note templates on top of Properties.
3. **Resolved:** "various views into relationships" doesn't need a new generalized query engine. Tags + Links (MVP) already provide it — Tag Browser plus each note's Backlinks pane is the view. Advanced Search's boolean operators (V1) were clarified to explicitly apply across tags, not just content, so compound questions ("characters who are `#antagonist` AND appear in `#act2`") are covered without new scope.
4. **Open decision, not yet made:** whether a "universe" should be one library or one document-with-links. This has real consequences — library boundaries are also CloudKit zone boundaries (see sync/zone strategy in [NoteBytez-ReleaseFeatures.md](NoteBytez-ReleaseFeatures.md)), so it affects whether search/graph can ever cross universes.
5. **Not yet added as a formal persona** in the UIUX deliverables (01–06) — by decision, deferred until the entity-modeling and universe-container questions above are settled.
