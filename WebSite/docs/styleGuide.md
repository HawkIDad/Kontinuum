<!-- styleGuide.md -->
<!--
  Derived web style guide for the NoteBytez website (WebSite20260919v1-WebSite.md D3).
  Parent: NoteBytez/Docs/styleGuide.md (visual-language parent; authoritative for anything not overridden here).
  Promoted from the "Derived Wiki Style Guide" table in wiki20260907v1-Phase1.md (Phase 1.0 / W1).
  These are the only intentional departures from the app guide: native SwiftUI -> accessible static web (WCAG 2.2 AA).
-->

# NoteBytez Website Style Guide

Parent: [`NoteBytez/Docs/styleGuide.md`](../../NoteBytez/Docs/styleGuide.md). Where this guide is silent, the app guide applies.

| App style guide element | Web adaptation (WCAG 2.2 AA) |
|---|---|
| **Foundation** — "unapologetically native", HIG defaults | Web equivalent: system font stack (`-apple-system, BlinkMacSystemFont, "Segoe UI", …`), minimal custom chrome, honour `prefers-color-scheme` and `prefers-reduced-motion`. The site should read as *documentation for a native app*, not a marketing microsite. |
| **Typography** — SwiftUI Dynamic Type roles (`.largeTitle` … `.caption`), no fixed sizes | Fluid `rem` type scale; body ≥ 1rem (16 px) at `line-height` ≥ 1.5; measure ≤ 70 ch; role mapping — Large Title → `h1`, Title → `h2`/`h3`, Body → `p`, Callout → `.callout`, Caption → `<small>`. Must survive 200% zoom and 400% reflow (1.4.10) and a user text‑spacing override (1.4.12). |
| **Colour** — semantic system colours only (`.primary`, `.secondary`, `.accentColor`) | CSS custom properties mirroring the roles, both schemes. Light: primary `#000`; **secondary must be a solid `#5C5C66` or darker** — do *not* port the app's `#3C3C43 @ 60%`, it fails 4.5:1 on white. Accent `#0F766E` on white ≈ 5.4:1 (AA for normal text, not AAA) → **all body links underlined** (1.4.1), never colour alone. Dark: primary `#FFF`, accent `#2DD4BF`. Verify every token pair with a contrast check in CI. |
| **Accent used for links + active nav** | Body links always underlined. Focus ring `2px solid` accent at `2px` offset, never removed, never obscured (2.4.7 / 2.4.11). Active nav item marked with `aria-current="page"` **and** a non‑colour indicator (weight + rule). |
| **Status colours** — Success `.green` / Warning/Conflict `.orange` / Destructive `.red` | Keep the hues; every use pairs colour with an icon **and** a text label (the app's own rule). Admonition components (`Note` / `Tip` / `Warning`) carry `role`, icon, and visible label — never colour‑coded alone. Check each on light and dark for ≥ 3:1 non‑text contrast. |
| **Spacing & targets** — 8 pt grid, 44×44 pt minimum | 8 px spacing scale. Interactive targets ≥ 24×24 CSS px (2.5.8); primary controls (search field, pager, nav toggles) ≥ 44 px. Content column ~72 ch max. |
| **Iconography** — SF Symbols exclusively | Web uses **Lucide** (DD2) chosen to echo the in‑app symbols; ship the mapping table. Non‑decorative icons get an accessible name; decorative icons `aria-hidden="true"`. |
| **App icon / logo / Logo Text** (Arial Rounded MT Bold, `#0f454a`) | Reuse the NoteBytez wordmark as an **SVG** in the site header with a text alternative; do **not** depend on the proprietary font in CSS. `#0f454a` on white ≈ 10.6:1 — fine. |
| **Accessibility section** (VoiceOver, Dynamic Type, colour never the only signal) | Superset it with the web specifics: HTML5 landmarks, skip link, ordered headings, `lang`, keyboard operability, labelled search input with keyboard‑navigable results, tables with `<th scope>`, forms with associated `<label>` and error identification. |
| **(new) Motion** | Screenshots are static; if any animated media is ever added, no autoplay under `prefers-reduced-motion: reduce`, provide a first‑frame poster and an explicit play control. |
| **(new) Screenshots** | Generated from a documented Simulator seed library; each `<figure>` has a descriptive `alt` and `<figcaption>`; ≤ 1600 px wide, `loading="lazy"`, 2× asset for retina; annotation callouts use shape + label, not colour alone, at ≥ 3:1 against the screenshot. |

## Screenshot naming and retina convention
- Path: `content/en/_assets/<category>/<name>-<device>-<appearance>.png`, with `<device>` = `iphone` | `mac` and `<appearance>` = `light` | `dark`.
- Every image ships two files: 1x (`….png`) and 2x (`…@2x.png`); iPhone is 400 / 800 px wide, Mac is 800 / 1600 px wide; the `screenshot` shortcode emits the `srcset`.
- Generated only by `tools/screenshots/capture.sh <category>` from the committed seed library (`tools/screenshots/seedLibrary/`) and `tools/screenshots/manifest.json`; never hand-edited.
- Captures use a dedicated portrait simulator, a fixed 9:41 status bar, and the app's DEBUG launch args `-SeedScreenshotLibrary` / `-ScreenshotDestination`.
- Mac captures are window-only (`screencapture -l`), light/dark set inside the app (`ScreenshotAppearance`), pointer parked off-window. Liquid Glass toolbar buttons sample whatever is behind the window, so Mac output can differ by a few dozen pixels between runs; iPhone output is byte-stable.
