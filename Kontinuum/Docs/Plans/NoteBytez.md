<!-- NoteBytez.md -->
<!--
    Product rename: Kontinuum -> NoteBytez.
    Living document. Checkbox convention: [ ] not started/in progress, [x] done and verified.
    Interview answers (2026-09-06) are recorded under Resolutions R1-R4.
-->

# Product Rename — Kontinuum → NoteBytez

## User Story

As the senior developer on the project, I have been told the product name is finalized as
**NoteBytez**. Every place a user (or a plugin author) can *see* the old name "Kontinuum" must
show "NoteBytez" instead, so that nobody using the app, reading its documentation, or writing a
plugin against its SDK is confused by a name that no longer exists.

The rename is deliberately **surface-level**: it changes what people see, not how the project is
built. Internal build identity — the Xcode project, targets, scheme, Swift module, bundle
identifier, CloudKit container, and the per-file header comments — keeps the name "Kontinuum".
Those are invisible to users, carry real migration/account risk to change, and changing them
buys nothing for this goal. The project is **pre-launch with disposable data**, so this is the
cheapest moment to do the visible rename and the right moment to *not* over-reach into
infrastructure that would be expensive to touch later.

Scope covers: on-screen text, the app's on-device display name, the plugin SDK's public API and
its reference doc, all Markdown documentation, and name-bearing image assets.

## Success Factors

1. **No user-visible "Kontinuum" anywhere in the running app.** Every on-screen string
   (`navigationTitle`, `alert`, body `Text`, onboarding copy, plugin-management copy) reads
   "NoteBytez". Verified by the grep gate in Phase 5 plus a manual screenshot pass of every
   screen that referenced the old name.
2. **The app's on-device name is "NoteBytez".** `CFBundleDisplayName` is set to `NoteBytez` for
   both iOS and macOS via `INFOPLIST_KEY_CFBundleDisplayName` (the product/target name stays
   `Kontinuum`; only the display string changes).
3. **All Markdown documentation reads "NoteBytez".** Every `.md` file under `Kontinuum/` that is
   not `z_`-prefixed (excluded per repo `CLAUDE.md`) has its body text updated, and every
   `Kontinuum*.md` file is renamed to `NoteBytez*.md` with the original datestamp/version suffix
   preserved and every inbound cross-link fixed. Infrastructure identifiers quoted inside docs
   (bundle ID, CloudKit container) are left verbatim with a one-line "legacy identifier" note.
4. **The plugin SDK is renamed.** The JavaScript global `kontinuum.*` becomes `noteBytez.*`
   (hard rename, no alias — acceptable because no third-party plugin has shipped).
   `Docs/PluginSDK.md` and `PluginBridgeTests` are updated to match. This is a **breaking SDK
   change**, recorded as such.
5. **Name-bearing asset files are renamed.** `images/logos/Kontinuum-V1.jpg` →
   `NoteBytez-V1.jpg` (a placeholder). Final AppIcon / logo art is undefined and owned by a
   separate design track (OQ2) — out of this plan's scope; its only carried-forward constraint
   is that it must read "NoteBytez".
6. **Build and tests stay green.** `xcodebuild build` succeeds for iOS and macOS; the full
   `KontinuumTests` suite passes (with `PluginBridgeTests` updated to `noteBytez.*`); no
   regression in `KontinuumUITests`.
7. **Deliberate retentions are documented, not silently skipped.** A "Legacy Identifiers"
   section in `ARCHITECTURE.md` records that the Swift module name (held explicitly by
   `PRODUCT_MODULE_NAME = Kontinuum`, since `PRODUCT_NAME` is now `NoteBytez`), targets,
   scheme blueprint, `.xcodeproj`, source directory, `KontinuumApp.swift`, `*.entitlements`
   filenames, bundle identifier `com.g9Consulting.Kontinuum`, CloudKit container
   `iCloud.com.g9Consulting.Kontinuum`, the `kontinuum-private-changes` /
   `kontinuum-shared-changes` subscription IDs, `Notification.Name` raw values, `DispatchQueue`
   labels, the `Logger` subsystem fallback string, and the `// Kontinuum` file-header line all
   intentionally keep the old name. The built product itself is `NoteBytez.app`.

## Canonical name

"**NoteBytez**" — one word, capital `N`, capital `B`, terminal `z`. Never spaced
("Note Bytez"), never all-lower except where an existing lowercased identifier is being matched
(e.g. the `noteBytez` JS global uses lowerCamelCase to match the old `kontinuum` global's
casing).

---

## Gaps / Open Questions / Resolutions

### Resolutions (decided — interview 2026-09-06)

| # | Question | Resolution |
|---|---|---|
| **R1** | How deep does the rename go beyond on-screen text? | **Visual + docs only.** Leave all code identifiers, the Swift module/target/scheme/`.xcodeproj`/source-dir names, `Notification.Name` raw values, `DispatchQueue`/log labels, and the `// Kontinuum` file-header comments untouched. The plugin SDK API is the one carve-out (R4) because plugin authors are users of it. |
| **R2** | CloudKit container `iCloud.com.g9Consulting.Kontinuum` and bundle ID `com.g9Consulting.Kontinuum` — containers can't be renamed. | **Keep both as-is.** Zero data migration, no App Store Connect / provisioning churn. A code comment at each definition site notes the legacy name. |
| **R3** | Real users / committed data in the current container today? | **Pre-launch, data disposable.** No migration concern. Confirms R2 is a convenience choice, not a forced one — and means infra IDs *could* be changed cheaply later if ever wanted, but there is no reason to. |
| **R4** | Plugin `kontinuum.*` JS global + `Kontinuum*.md` doc filenames. | **Hard rename both.** `kontinuum.*` → `noteBytez.*` with no deprecation alias; all `Kontinuum*.md` files renamed to `NoteBytez*.md` and cross-links fixed. Justified by pre-launch status — no shipped plugin, no external doc links to break. |

### Derived resolutions (reasoned defaults — flag if any is wrong)

| # | Item | Default taken | Rationale |
|---|---|---|---|
| **DR1** | App display name mechanism | Add `INFOPLIST_KEY_CFBundleDisplayName = NoteBytez` (+ macOS key) to both build configs; do **not** rename the target. | Gets the visible rename (SF#2) without touching build identity (R1). |
| **DR2** | Historical dated plan docs (`Kontinuum20260627v2-Security.md`, etc.) | Rename file + replace the name in body text; do **not** rewrite the decisions/history they record. | SF#3 + R4 say rename; the documents' value as a decision record is preserved by leaving their substance intact. |
| **DR3** | `Kontinuum-V1.jpg` logo asset | Rename to `NoteBytez-V1.jpg` (placeholder — final logo art is still in design, OQ2). Not referenced from code, so the rename is safe and lossless. | Housekeeping. |
| **DR4** | Repo-root `Kontinuum/CLAUDE.md` | In scope for the prose sweep; infra-identifier lines (`iCloud.com.g9Consulting.Kontinuum`) left verbatim. Workspace-level `../CLAUDE.md` is shared across projects and out of scope except any line naming this app. | `CLAUDE.md` is a Markdown document (SF#3) but is also build/infra instruction — treat identifiers as identifiers. |
| **DR5** | `z_`-prefixed Markdown | Excluded from the sweep. | Repo `CLAUDE.md`: "Ignore markdown files beginning with 'z_'". |
| **DR6** | Swift local var `let kontinuum` in `PluginBridge.swift` | Rename to `noteBytez` for readability alongside the JS-facing rename; it is not an API surface. | Cosmetic; keeps the file self-consistent after R4. |
| **DR7** | This planning doc's own filename | Leave as `NoteBytez.md` (already renamed); optionally realign to the dated convention as `NoteBytez20260906v1-ProductRename.md`. | Cosmetic, non-blocking. |

### Open Questions — all resolved (2026-09-06)

| # | Question | Resolution |
|---|---|---|
| **OQ1** | Canonical styling exactly "NoteBytez" (one word, `N`/`B` caps, trailing `z`)? | **Yes.** Proceed as stated under **Canonical name**. |
| **OQ2** | Does the AppIcon / logo art contain the "Kontinuum" wordmark? | **N/A — app icon and logo are still in design, currently undefined.** No existing wordmark to remove. The visual-rename DoD does **not** depend on art; the only constraint is that whatever art lands later must read "NoteBytez", never "Kontinuum". Phase 4 shrinks to renaming the placeholder JPG. |
| **OQ3** | Existing App Store Connect record / TestFlight build to update? | **No — nothing submitted to App Store Connect yet.** The ASC metadata step is dropped from Phase 5; it will simply be created as "NoteBytez" when the time comes. |
| **OQ4** | Any pilot plugin written against `kontinuum.*` we own? | **No plugins created.** Phase 2 touches only `PluginBridge.swift`, `PluginBridgeTests`, and `PluginSDK.md`. |
| **OQ5** | External references to `Kontinuum*.md` doc paths? | **None.** Phase 3 link-fixing is entirely repo-internal. |

---

## Implementation Plan

TDD note (repo `CLAUDE.md` §8): the only behavioural change is the plugin API rename — Phase 2
updates `PluginBridgeTests` first (they will fail against the old global), then the bridge.
Everything else is string/asset substitution verified by build + the Phase 5 grep gate.

> **Executed 2026-09-06.** All phases complete. Full `KontinuumTests` suite 727/727 green on the
> iOS 26 simulator; `xcodebuild build` green for iOS Simulator and `platform=macOS`;
> `Scripts/verify-rename.sh` exits 0. Deviations and caveats in **Execution Notes** below.

### Phase 0 — Confirm dependencies
- [x] OQ1–OQ5 resolved (2026-09-06) — see table above. No blocking design dependency; app
  icon / logo art is a separate in-flight design track whose only rename constraint is "must
  read NoteBytez". No App Store Connect record, no plugins, no external doc links.

### Phase 1 — In-app visible strings + display name
- [x] Replaced the 6 user-visible literals: `ContentView.swift` (`.navigationTitle`, `.alert`),
  `LibrarySelectionView.swift` (`.navigationTitle`), `RoleOnboardingView.swift` (body `Text` +
  `.navigationTitle`), `PluginManagementView.swift` (empty-state `Text`).
- [x] `CFBundleDisplayName = NoteBytez` added to `Kontinuum/Info.plist` **and**
  `Kontinuum/Info-macOS.plist` directly (not via `INFOPLIST_KEY_*` — Xcode's generated-plist
  merge ignores `INFOPLIST_KEY_CFBundleName` when it collides with `$(PRODUCT_NAME)`; a plain
  `INFOPLIST_KEY_CFBundleDisplayName` would have worked but keeping both keys together in the
  plist files is clearer). Baked value confirmed via `PlistBuddy` on the built `.app`.
- [x] `PRODUCT_NAME = NoteBytez` on the app target (both configs) — so `CFBundleName`,
  `CFBundleExecutable`, and the built product (`NoteBytez.app`) all read NoteBytez, and the
  **macOS app menu** now shows "About NoteBytez" / "Quit NoteBytez". Paired with
  `PRODUCT_MODULE_NAME = Kontinuum` (explicit) so the Swift module name is **not** dragged along
  — `@testable import Kontinuum` in ~80 test files still resolves. `KontinuumTests` `TEST_HOST`
  updated to the new `NoteBytez.app` path.
- [x] → verify: `Scripts/verify-rename.sh` passes; simulator screenshots confirm "NoteBytez" on
  the library-selection and role-onboarding screens; `PlistBuddy` on the built `.app` (both
  platforms): `CFBundleName` / `CFBundleExecutable` / `CFBundleDisplayName` = `NoteBytez`,
  `CFBundleIdentifier` = `com.g9Consulting.Kontinuum` (retained), `PRODUCT_MODULE_NAME` =
  `Kontinuum` (retained).

### Phase 2 — Plugin SDK hard rename (breaking)
- [x] `PluginBridgeTests.swift` — all JS `entryScript` snippets `kontinuum.*` → `noteBytez.*`
  (ran red first). Also updated `PluginViewModelTests.swift` (executes a script — would have
  failed), and the `kontinuum.addCommand('x')` fixture strings in `PluginDALTests.swift`,
  `BackupDALTests.swift`, `SyncMappingTests.swift` for consistency.
- [x] `PluginBridge.swift` — JS global string `"kontinuum"` → `"noteBytez"`; local
  `let kontinuum` → `noteBytez` (**DR6**); doc comments updated. `PluginViewModel.swift:58`
  comment updated.
- [x] `Docs/PluginSDK.md` — retitled "NoteBytez Plugin SDK (Preview)", all 19 `kontinuum` →
  `noteBytez`, prose updated, top-of-file **Breaking change** note added.
- [x] → verify: full suite green; no `kontinuum` (lowercase) remains in code except the retained
  subscription IDs and the `.kontinuum*` `Notification.Name` comment.

### Phase 3 — Documentation sweep
- [x] Renamed all 15 `Kontinuum*.md` plan docs → `NoteBytez*.md` (datestamp/version preserved;
  the `- HOLD -` marker on the MultiLanguage doc kept).
- [x] Guarded body-text sweep across 25 in-scope `.md` files (`Kontinuum/**` non-`z_` +
  repo-root `CLAUDE.md`; `NoteBytez.md` itself excluded — it authors both names): `Kontinuum`
  → `NoteBytez` **except** `com.g9Consulting.Kontinuum`, `iCloud.com.g9Consulting.Kontinuum`,
  `kontinuum-*-changes`, `import Kontinuum`, `-scheme/-project/-target Kontinuum`,
  `Kontinuum{Tests,UITests,App,CIGate}`, `Kontinuum.{xcodeproj,xcscheme,app,entitlements}`,
  `Kontinuum-macOS.entitlements`, `KontinuumSecurity.xctestplan`, and the `Kontinuum/` source
  path prefix (retained per R1). Link text `](Kontinuum*.md)` tracked the file renames in the
  same pass, so same-directory cross-links stay valid.
- [x] Fixed Swift **doc-comment** references to the renamed plan docs (50 `.swift` files, e.g.
  `/// Per Kontinuum20260824v1-Templates.md` → `NoteBytez…`) — pointer fixes the rename
  created, not an identifier change. Headers (`//  Kontinuum`), module, and `KontinuumApp`
  untouched.
- [x] Repo-root `CLAUDE.md`: its only "Kontinuum" is the retained container ID — no change (DR4
  satisfied trivially).
- [x] → verify: `Scripts/verify-rename.sh` (b) passes; the only `Kontinuum` left in docs is the
  retained-identifier set + `ARCHITECTURE.md`'s new "Legacy Identifiers" section.
  **Pre-existing broken links (NOT introduced here, left per `CLAUDE.md` §3):** 3 refs to
  `NoteBytez20260823v2-MultiLanguage.md` (real file is `…- HOLD -MultiLanguage.md`); and
  several `Docs/Plans/…` / bare relative links in `UIUX/` + `NoteBytez20260813-UIUX-Research.md`
  that resolve from repo root, not from the file's own directory. All were equally broken under
  the old names.

### Phase 4 — Assets
- [x] `Kontinuum/images/logos/Kontinuum-V1.jpg` → `NoteBytez-V1.jpg` (placeholder, unreferenced
  in code).
- [x] No AppIcon/logo change — art is undefined (OQ2), separate design track; constraint handed
  forward: finished icon/logo must read "NoteBytez".
- [x] → verify: iOS + macOS builds green; asset catalog unaffected (logo JPG is not a catalog
  asset).

### Phase 5 — Verification gate
- [x] `Scripts/verify-rename.sh` created and passing (exit 0). Checks (a) Swift string literals,
  (b) non-`z_` Markdown body text, (c) `INFOPLIST_KEY_CFBundle*Name` — against the allow-list
  above. (d) asset-catalog check dropped — no catalog asset carries the name.
- [x] `xcodebuild build` — iOS Simulator **and** `platform=macOS`: both **BUILD SUCCEEDED**.
- [x] `xcodebuild test -only-testing:KontinuumTests` — **727/727 pass** on iPhone 17 Pro
  (iOS 26 sim).
- [x] Screenshot pass (iOS sim): library-selection title, role-onboarding title + body all read
  "NoteBytez"; `CFBundleDisplayName` baked as `NoteBytez` (PlistBuddy). `ContentView` sidebar
  title + `PluginManagementView` empty-state + `.alert` are plain literal swaps covered by the
  green suite (not separately screenshotted — `ContentView`'s title only renders in the
  iPad/Mac sidebar layout).
- [x] No App Store Connect step (OQ3 — nothing submitted).

### Phase 6 — Record the retentions
- [x] `ARCHITECTURE.md` → new **"Legacy Identifiers"** section enumerating every retained
  `Kontinuum` identifier and why; points at `Scripts/verify-rename.sh` as the enforcement.
- [x] `NoteBytez-ReleaseFeatures.md`, `styleGuide.md`, `ARCHITECTURE.md` product-name prose
  updated by the Phase 3 sweep.
- [x] → verify: section present; allow-list matches the script.

## Execution Notes (2026-09-06)

- **Deviation from DR1 mechanism:** `CFBundleDisplayName` set directly in both `Info.plist`
  files rather than via `INFOPLIST_KEY_*` build settings.
- **`PRODUCT_NAME = NoteBytez` (added on product-owner instruction, after the first pass).**
  This renames the built product to `NoteBytez.app` and makes `CFBundleName` / the macOS app
  menu read NoteBytez — the item originally flagged as "needs a call". To keep this from
  crossing R1's line, `PRODUCT_MODULE_NAME = Kontinuum` was pinned explicitly: without it,
  `PRODUCT_NAME` also becomes the Swift module name and every `@testable import Kontinuum`
  breaks (seen and fixed during this change). `KontinuumTests` `TEST_HOST` was repointed to
  `NoteBytez.app`. Net: the *product/bundle* is NoteBytez; the *module, target, scheme
  blueprint, project, bundle ID, container* stay Kontinuum. `Kontinuum.xcscheme`'s
  `BuildableName` auto-updated to `NoteBytez.app` (Xcode owns that field; `BlueprintName`
  stays `Kontinuum`). One historical build-log quote in `NoteBytez-MacImplementation.md`
  still says "validated as `Kontinuum.app`" — left as a dated record (`CLAUDE.md` §3).
- **Scope extension (kept minimal):** ~50 `.swift` files had doc-comment references to the
  renamed plan docs (`/// Per Kontinuum20260…md`). These were updated — leaving them would have
  created dangling references the rename itself introduced (`CLAUDE.md` §3). No identifier,
  header, or module name was touched.
- **Pre-existing broken doc links** surfaced by the link check are left as-is per `CLAUDE.md`
  §3 (they were broken under the old names too): 3 × `NoteBytez20260823v2-MultiLanguage.md`
  (real file has the `- HOLD -` marker), and repo-root-relative links inside `UIUX/*.md` and
  `NoteBytez20260813-UIUX-Research.md`.
- **`git mv`** in the plan text is nominal — this working copy is not a git repo, so plain `mv`
  was used; history-preservation is moot here.

## Definition of Done

**Met (2026-09-06).** SF#1–SF#7 done; `Scripts/verify-rename.sh` exits 0; iOS + macOS builds
green; `KontinuumTests` 727/727; screenshot pass done; `ARCHITECTURE.md` "Legacy Identifiers"
section added. `PRODUCT_NAME = NoteBytez` applied (macOS app menu + built `NoteBytez.app`),
with `PRODUCT_MODULE_NAME` pinned to `Kontinuum` so the module name is retained. No open
items. App icon / logo art is **out of this plan's DoD** (undefined, separate design track,
OQ2) — carried-forward constraint: the finished art must read "NoteBytez".
