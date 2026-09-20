<!-- informationArchitecture.md -->
<!-- Phase W2 output (WebSite20260919v1-WebSite.md). Machine-readable sources live in site/_data/. -->

# NoteBytez Website — Information Architecture

## Navigation
- **Primary:** Home · Features · Pricing · Help · Support
- **Footer (every page):** Privacy · Terms · Support
- Source: `site/_data/nav.json`

## URL scheme
| Page | URL |
|---|---|
| Home / Features / Pricing / Support / Privacy / Terms | `/`, `/features/`, `/pricing/`, `/support/`, `/privacy/`, `/terms/` |
| Help hub | `/en/help/` |
| Category hub | `/en/help/<category>/` |
| How-to / concept / reference | `/en/help/<category>/<featureSlug>/` |
| Persona journey | `/en/help/journeys/<slug>/` |

Permalinks are stable and dateless; `featureSlug` is globally unique (consumed later by in-app Help links, D7).

## Taxonomy (21 categories, 98 planned feature slugs)
Source of truth: `site/_data/featureMap.json` — each Feature Inventory row → `featureSlug`. Categories are the Feature Inventory's left column; `concepts` and `reference` are supporting categories. Four journeys: `your-first-week`, `bring-your-vault-across`, `model-your-world`, `share-a-space`.

## Front-matter schemas
- Help pages (Wiki 1.1): `site/_data/helpFrontMatter.schema.json` — `title, description, category, order, appliesTo[], personas[], featureSlug, lastReviewed, type (howto|concept|reference|journey)`.
- Marketing/legal: `site/_data/marketingFrontMatter.schema.json` — `title, layout` (+ optional `description`).
- Enforced by `npm run lint` (`site/scripts/checkIA.js`, Ajv); tests in `site/test/` (`npm test`).

## Verification
- Every Feature Inventory row maps to ≥ 1 unique `featureSlug` — lint-enforced.
- Every marketing page is in nav or footer; Help pages are reached via the Help hub → category hub — lint-enforced for marketing; Help orphan check runs in W6 when pages exist.
- **Taxonomy sign-off:** pending owner review.
