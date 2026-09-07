<!-- Docs/Templates/README.md -->

# Template Packs

Curated `TemplateGroup` + `NoteTemplate` sets for knowledge-management roles. Delivered as a
bundled app resource; the user adds a pack from the **Template Gallery** (Settings → Template
Gallery, and the first-run role picker) and it is copied into the library as ordinary
editable/deletable rows. Per
[NoteBytez20260824v1-Templates.md](../Plans/NoteBytez20260824v1-Templates.md).

## Where the content lives

| File | Role |
|---|---|
| `Scripts/generate_template_packs.py` | **Authoring source of truth.** Edit here. |
| `Kontinuum/Resources/TemplatePacks.json` | Generated bundle resource. Do not hand-edit. |
| `Kontinuum/models/TemplatePackDefinition.swift` | Decodable shapes + `CanonicalField` + `TemplatePackLint`. |
| `Kontinuum/dal/TemplatePackDAL.swift` | Read / add / update packs. |

Regenerate after editing the script:

```bash
python3 Scripts/generate_template_packs.py
```

`TemplatePackDALTests.bundledTemplatePacksDecodeAndPassLint` fails the build if the committed
JSON is malformed, uses a non-canonical field name, has a mis-typed canonical field, contains a
non-`- [ ]` checkbox, or doesn't cover every documented role exactly once.

## The 16 knowledge-management packs (+ 1 culinary pack + 3 creative starters)

The 23 knowledge-management roles from the spec are merged into 16 packs; the three culinary
roles added by the 2026-08-30 remediation form one more pack. Every role appears in exactly one
pack's `roleAliases`, so the gallery still finds a pack by any original job title.

| Pack | Category | Roles covered |
|---|---|---|
| Common / KM Essentials | Essentials | — (universal: meetings, decisions, 1:1s, reviews) |
| Software Engineering | Engineering & Data | Software Engineer |
| Technical Writing | Engineering & Data | Technical Writer |
| Data Architecture & Governance | Engineering & Data | Data Architect, Data Governance Manager |
| Knowledge Organization | Engineering & Data | Information Architect, Librarian, Records Manager |
| Project Management | Product & Delivery | Project Manager |
| Product Management | Product & Delivery | Product Manager, Business Analyst |
| Operations & Service Management | Product & Delivery | Operations Manager, IT Service Desk Analyst |
| Consulting & Research | Product & Delivery | Management Consultant, Research Analyst |
| Customer Success | Go-to-Market | Customer Success Manager |
| Sales | Go-to-Market | Sales Specialist |
| Marketing | Go-to-Market | Marketing Specialist |
| People Ops (HR) | People | Human Resources Specialist, Human Resources Manager |
| Learning & Development | People | Learning and Development Specialist, Corporate Trainer |
| Legal Operations | Governance & Compliance | Legal Operations Specialist |
| Healthcare Administration | Governance & Compliance | Healthcare Administrator |
| Culinary & Food Craft | Food & Hospitality | Chef, Confectioner, Chocolatier |
| Fiction Writing / Wedding Planning / Photography Client Work | Personal & Creative | — (auto-seeded starters) |

Only the three creative starters are auto-seeded into a new library. The 16 KM packs and the
culinary pack are opt-in via the gallery or the first-run picker.

## Canonical shared fields

Use these exact spellings and value types wherever the concept applies, so cross-role Saved
Views and Advanced Search work:

| Field | Type |
|---|---|
| Status | text |
| Owner | text |
| Priority | text |
| Start Date | date |
| Due Date | date |
| Stakeholders | list |
| Reviewed | checkbox |

## Body templates

`bodyTemplate` is plain Markdown (no `{{tokens}}` yet). `- [ ]` lines become real `TaskItem`s
when a document is created from the template. Keep bodies ~12–25 lines: an H1 title, a few H2
sections with bullet prompts, and an `## Action Items` checklist where natural.

## Updating a shipped pack

Bump the pack's `version` in the script and add/extend templates. `TemplatePackDAL.applyUpdate`
is **additive only**: it adds new-named templates and new-named fields, fills an empty body, and
never touches a user's edits or resurrects a template they deleted.

## Localization

English-only for now. When
[NoteBytez20260823v2-MultiLanguage.md](../Plans/NoteBytez20260823v2-MultiLanguage.md) resumes,
the literal strings here move into a `TemplatePacks.xcstrings` catalog and `TemplatePackDAL`
resolves them in the active app language at add-time.
