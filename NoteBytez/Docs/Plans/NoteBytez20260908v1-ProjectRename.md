<!-- NoteBytez20260908v1-ProjectRename.md -->
<!--
    Rename the Xcode project and every remaining internal reference Kontinuum -> NoteBytez.
    Supersedes the deliberate "keep internal identity as Kontinuum" decision in
    NoteBytez20260906v1-NameChange.md / ARCHITECTURE.md "Legacy Identifiers".
    Interview: 2026-09-08 (2 rounds). Resolutions in "Gaps and Resolution".
-->

# Project Rename — Kontinuum → NoteBytez (internal)

## User Story

**As** the Senior Developer on NoteBytez, **I want** the Xcode project, its targets, folders,
scheme, Swift module, bundle identifiers, embedded identifier strings, file headers, and
documentation renamed from **Kontinuum** to **NoteBytez**, **so that** the codebase carries one
name end to end and a developer opening the project never has to reconcile a build-identity
name that no longer means anything.

This **reverses the deliberate scope limit** set in
[NoteBytez20260906v1-NameChange.md](NoteBytez20260906v1-NameChange.md), which renamed only what
users and plugin authors could see and explicitly retained the internal `Kontinuum` identity
(module, targets, scheme, `.xcodeproj`, bundle ID, `Notification.Name` raw values, file
headers, …) to avoid churn. The project is still **pre-launch with disposable data** and
nothing is in App Store Connect, so the cost of going the rest of the way is a one-time
mechanical sweep with no migration risk — and this is the cheapest moment it will ever be.

The rename is **in-place** (rename the existing project, preserve git history), not a
rebuild. The **CloudKit container** `iCloud.com.g9Consulting.Kontinuum` is the single
identifier that keeps the old name — containers cannot be renamed and there is no user benefit
to a new one — and it becomes the only `Kontinuum` string allowed to remain anywhere in the
repository.

## Prerequisites

1. The app has **not been distributed** beyond local Simulators — no TestFlight, no App Store
   Connect record, no shipped plugin.
2. The **CloudKit container stays** `iCloud.com.g9Consulting.Kontinuum` (both entitlement files,
   both `icloud-container` / `ubiquity-container` keys, and any code constant). It is the sole
   retained legacy identifier.
3. **Bundle identifiers change.** `com.g9Consulting.Kontinuum` → `com.g9Consulting.NoteBytez`
   (and the `…Tests` / `…UITests` variants). Automatic signing (team `S4843K7ZH6`) mints the new
   App IDs on first build; the existing CloudKit container is associated with the new primary
   App ID (Xcode's automatic iCloud management, or a one-time association in the Developer
   portal if the build reports a missing entitlement).
4. **In-place rename**, not a new project. `git mv` for every renamed path so history and blame
   survive; the `.xcodeproj` is edited, not regenerated.
5. **Xcode 26.x**, matching `CreatedOnToolsVersion = 26.6` / `objectVersion = 77`. The three
   source groups are `PBXFileSystemSynchronizedRootGroup`s, so renaming a folder + its `path =`
   entry is sufficient — there is no per-file list to edit.
6. The **GitHub repo rename** (`HawkIDad/Kontinuum` → `HawkIDad/NoteBytez`) is an account/settings
   action performed by the maintainer; this plan provides the exact commands and the follow-up
   `git remote set-url`.
7. Work happens on a **feature branch** off `main` with phased commits, landing as one PR.

## Success Factors

Each is objectively checkable; the check is named. All must pass for Definition of Done.

### SF1 — Project identity is NoteBytez
`NoteBytez.xcodeproj`; scheme `NoteBytez.xcscheme` (`BlueprintName = NoteBytez`); targets
`NoteBytez` / `NoteBytezTests` / `NoteBytezUITests`; source folders `NoteBytez/` /
`NoteBytezTests/` / `NoteBytezUITests/`; `NoteBytez.entitlements`,
`NoteBytez-macOS.entitlements`; `NoteBytezCIGate.xctestplan`, `NoteBytezEntitlement.xctestplan`;
`NoteBytez/StoreKit/NoteBytez.storekit`. `PRODUCT_NAME` **and** `PRODUCT_MODULE_NAME` =
`NoteBytez`. **Check:** `xcodebuild -list -project NoteBytez.xcodeproj` + `git ls-files | grep -i kontinuum`.

### SF2 — Test/app types are NoteBytez
`NoteBytezTests` / `NoteBytezUITests` targets, folders, and base class `NoteBytezUITestCase`;
the `@main` entry type is `NoteBytezApp` in `NoteBytezApp.swift`; every `@testable import
NoteBytez` resolves. **Check:** full `NoteBytezTests` suite compiles and passes at the
pre-rename baseline count (727/727 per `NoteBytez.md`).

### SF3 — Zero `Kontinuum` outside the container
No case-insensitive `kontinuum` in any git-tracked file **except** the literal
`iCloud.com.g9Consulting.Kontinuum`. **Check:** the inverted `Scripts/verify-rename.sh` exits 0;
`git grep -i kontinuum` returns only container-string lines.

### SF4 — Embedded identifiers renamed, container retained
Bundle IDs `com.g9Consulting.NoteBytez{,Tests,UITests}`; StoreKit product IDs
`com.g9Consulting.NoteBytez.sub.monthly` / `.sub.annual` / `.entitlement`; CloudKit zone
subscription IDs `notebytez-private-changes` / `notebytez-shared-changes`; `Notification.Name`
raw values `noteBytez*`; `DispatchQueue` labels and `Logger` subsystem (+ fallback string)
`com.g9Consulting.NoteBytez.*`. CloudKit **container** unchanged. **Check:** `verify-rename.sh`
allow-list contains exactly the container string; targeted `git grep` for each old identifier
returns nothing.

### SF5 — Builds, tests, and runs green
`xcodebuild build` succeeds for **iOS Simulator** and **`platform=macOS`**; `NoteBytezTests`
passes at baseline; `NoteBytezUITests` passes per `NoteBytezCIGate.xctestplan`; the app launches
in the iOS 26 Simulator, a library can be created, and sync status reaches "synced" against the
retained container. **Check:** CI + a manual Simulator smoke pass.

### SF6 — Repository renamed
Working copy directory is `NoteBytez/`; `origin` is
`https://github.com/HawkIDad/NoteBytez.git`; the `../MarkdownG9` local Swift package resolves
from the new path. **Check:** `git remote -v`, `git fetch`, clean build from the renamed path.

### SF7 — Docs and enforcement updated
Every non-`z_` `.md` reads `NoteBytez` (container line excepted); `ARCHITECTURE.md`'s "Legacy
Identifiers" section is replaced by a one-paragraph "Retained name" note; `verify-rename.sh` is
inverted and wired into CI. **Check:** doc link-check passes; `verify-rename.sh` in CI is green.

---

## Gaps and Resolution

Gaps in the original draft (User Story + Prerequisites + Success Factors only), and their
resolution. **R** = answered directly in the 2026‑09‑08 interview. **DD** = derived default
taken to proceed — flag if wrong.

### Resolved by interview

| # | Gap | Resolution |
|---|---|---|
| **R1** | Strategy contradiction — Prereq 4 said "a new Xcode project will be created", but the Success Factors describe an in-place rename. | **In-place rename.** Rename the existing `.xcodeproj`, targets, scheme, folders, and module; `git mv` every path; edit `project.pbxproj`, don't regenerate it. Preserves history/blame; keeps build settings, test-plan wiring, package refs, and entitlements intact. Prereq 4 is rewritten accordingly. |
| **R2** | Depth undefined — does "all references" include the Swift module, runtime strings, and 346 file headers? | **Everything.** Module name (`import NoteBytez`), `KontinuumApp` → `NoteBytezApp`, `KontinuumUITestCase` → `NoteBytezUITestCase`, all `Notification.Name` raw values, `DispatchQueue` labels, `Logger` subsystem + fallback, and the `//  Kontinuum` header line in every `.swift`. Only the CloudKit container survives. |
| **R3** | Bundle identifier — allowed to change (Prereq 3) but not stated as a requirement; signing implications unnoted. | **Change to `com.g9Consulting.NoteBytez{,Tests,UITests}`.** Automatic signing mints the new App IDs; the existing container is associated with the new primary App ID (Prereq 3). |
| **R4** | Other embedded identifier strings — StoreKit product IDs, `.storekit` filename, CloudKit zone subscription IDs. | **Rename all to NoteBytez.** Product IDs → `com.g9Consulting.NoteBytez.sub.*` / `.entitlement`; `Kontinuum.storekit` → `NoteBytez.storekit`; subscription IDs → `notebytez-*-changes`. Safe pre-launch — nothing server-side is authoritative and data is disposable. |
| **R5** | CloudKit container — keep, or create a fresh NoteBytez container since data is disposable? | **Keep `iCloud.com.g9Consulting.Kontinuum`.** It is the *sole* documented exception; the verify gate allow-lists exactly this string. No new container, no migration. |
| **R6** | Git repo + GitHub — in scope, or project-internal only? | **In scope.** Rename the local working-copy folder `Kontinuum/` → `NoteBytez/` and the GitHub repo `HawkIDad/Kontinuum` → `NoteBytez` (GitHub keeps redirects), then `git remote set-url origin …/NoteBytez.git`. |
| **R7** | Historical documentation — rewrite the dated decision records, or preserve them? | **Full sweep, all docs.** Every non-`z_` `.md` including the dated historical plans; `Docs/Plans/Projects/Kontinuum.md` → `…/NoteBytez.md`; `ARCHITECTURE.md` "Legacy Identifiers" replaced with a short "Retained name" note. Historical plans get a one-line "superseded by NoteBytez20260908v1-ProjectRename.md" banner but their decisions are not rewritten. |
| **R8** | No verification method / success gate. | **Inverted `verify-rename.sh` + build/test gates:** `xcodebuild` iOS + macOS green; full `NoteBytezTests` at baseline; `NoteBytezUITests` per the CI Gate plan; Simulator smoke + CloudKit connect; `verify-rename.sh` exit 0; `git grep -i kontinuum` shows only the container. Encoded as SF1–SF7 and Phase 8. |
| **R9** | `verify-rename.sh` currently enforces the *opposite* (allow-lists all retentions). | **Invert it**, keeping the filename. New rule: exit 1 on any case-insensitive `kontinuum` in `git ls-files` output except the container string (and the script's own allow-list line). Header comment updated. |
| **R10** | Execution shape — branch? commit granularity? | **Feature branch `rename/notebytez-project`, phased commits** (project/build settings → files+module → code identifiers → headers → docs → repo → gate), one PR to `main`. |

### Derived defaults (flag if wrong)

| # | Item | Default taken | Rationale |
|---|---|---|---|
| **DD1** | `PRODUCT_MODULE_NAME` | Set **explicitly** to `NoteBytez` (not deleted to fall through to `PRODUCT_NAME`). | Matches the current file's explicit style; unambiguous. |
| **DD2** | `Notification.Name` raw values | `kontinuum*` → `noteBytez*` (lowerCamelCase). | `CLAUDE.md` §5 naming; matches the existing casing of these constants. |
| **DD3** | CloudKit zone subscription IDs | `kontinuum-private-changes` / `kontinuum-shared-changes` → `notebytez-private-changes` / `notebytez-shared-changes` (kebab-case). | Preserves the existing token shape; only the name changes. |
| **DD4** | Verify script | Keep the filename `Scripts/verify-rename.sh`; invert the logic; allow-list = exactly `iCloud\.com\.g9Consulting\.Kontinuum`. | Interview chose "invert", not "new name". One allow-list entry keeps the gate honest. |
| **DD5** | Dated historical plans | Swept in place (body text) with a "superseded" banner; **not** renamed again — they already carry `NoteBytez…` date-prefixed filenames from the 2026‑09‑06 rename. Only `Docs/Plans/Projects/Kontinuum.md` is `git mv`d. | Their filenames are already correct; only `Projects/Kontinuum.md` is stale. |
| **DD6** | GitHub repo rename | Performed by the maintainer in repo settings; this plan supplies the commands. Old URL keeps redirecting, so a missed local checkout still works until updated. | Renaming a GitHub repo is an account action, not a code change. |
| **DD7** | Pre-existing drift | **Noted, not fixed** (`CLAUDE.md` §3): `ARCHITECTURE.md` "Legacy Identifiers" cites `KontinuumSecurity.xctestplan` but the file is `KontinuumEntitlement.xctestplan`; app `MARKETING_VERSION` `0.1.0` vs test targets `1.0`. The "Legacy Identifiers" rewrite fixes the first as a side effect. |
| **DD8** | `xcuserdata` / `*.xcuserstate` | Left to regenerate; never hand-edited. Already dirty in `git status`. | Machine-generated UI state. |
| **DD9** | `.storekit` internals | Update only name / product-ID fields; leave `_developerTeamID` and structural keys. | Minimal, surgical. |
| **DD10** | Baseline capture | Record `xcodebuild` result + `NoteBytezTests` count on the branch point **before** any edit, as the regression reference. | "Green before and after" needs a known before. |

---

## Implementation Plan

TDD note (`CLAUDE.md` §8): the rename is non-behavioural. The safety net is the **existing test
suite** (baseline captured in Phase 0) plus the **inverted grep gate** (Phase 7). Any test that
asserts on a literal `Kontinuum` string is updated in the same phase that changes the string
and must be red→green across that edit.

Each phase ends with a commit and a verify step; a phase is not done until its verify passes.
Success criteria per phase map to the SF they satisfy.

### Phase 0 — Branch & baseline
- `git checkout -b rename/notebytez-project` off `main`.
- Capture baseline: `xcodebuild build` (iOS Sim + macOS) and `xcodebuild test
  -only-testing:KontinuumTests` — record pass/fail and the test count.
- Commit the current full `kontinuum` inventory (`git grep -in kontinuum`) as
  `Docs/Plans/rename-inventory.txt` — the checklist Phases 1–5 burn down (deleted in Phase 8).
- → **verify:** branch exists; baseline recorded; build + suite green at baseline.

### Phase 1 — Xcode project & build settings (SF1, SF4)
- `git mv`: `Kontinuum` → `NoteBytez`, `KontinuumTests` → `NoteBytezTests`, `KontinuumUITests`
  → `NoteBytezUITests`, `Kontinuum.xcodeproj` → `NoteBytez.xcodeproj`,
  `Kontinuum{,-macOS}.entitlements` → `NoteBytez{,-macOS}.entitlements`,
  `KontinuumCIGate.xctestplan` → `NoteBytezCIGate.xctestplan`,
  `KontinuumEntitlement.xctestplan` → `NoteBytezEntitlement.xctestplan`,
  `Kontinuum/StoreKit/Kontinuum.storekit` → `NoteBytez/StoreKit/NoteBytez.storekit`,
  `xcshareddata/xcschemes/Kontinuum.xcscheme` → `NoteBytez.xcscheme`.
- Edit `project.pbxproj`: target `name` / `productName` (×3), `remoteInfo` (×2),
  `.xctest` product refs + comments, `path = Kontinuum*` on the 3 synchronized groups,
  config-list comments, `PRODUCT_BUNDLE_IDENTIFIER` (app + both test targets → `…NoteBytez*`),
  `PRODUCT_MODULE_NAME = NoteBytez` (DD1), `INFOPLIST_FILE` + `CODE_SIGN_ENTITLEMENTS`
  (+ `[sdk=macosx*]`) paths, `TEST_TARGET_NAME = NoteBytez`.
- Edit `NoteBytez.xcscheme`: `BlueprintName`, `BuildableName` (`NoteBytezTests.xctest` /
  `NoteBytezUITests.xctest`), `ReferencedContainer = container:NoteBytez.xcodeproj`, the two
  `*.xctestplan` refs, and `identifier = "NoteBytez/StoreKit/NoteBytez.storekit"`.
- Edit both `.xctestplan`: `containerPath`, target `name`s, `storeKitConfigurationFileReference`.
- Entitlement file **contents unchanged** — the container string stays (Prereq 2).
- Identify and handle the 1 `.plist` with a `kontinuum` match (`git grep -il kontinuum
  '*.plist'`) — expected to be a path/name reference, not the container.
- → **verify:** `xcodebuild -scheme NoteBytez build` green iOS + macOS; scheme + both test
  plans load in Xcode; `xcodebuild -list` shows only `NoteBytez*` targets.

### Phase 2 — Module, entry point, named files & types (SF2)
- `KontinuumApp.swift` → `NoteBytezApp.swift`; `struct KontinuumApp` → `NoteBytezApp` (+ the
  `@main` attribute site and any `KontinuumApp.init` / preview refs).
- `KontinuumTests/KontinuumTests.swift`, `KontinuumUITests/KontinuumUITests.swift`,
  `KontinuumUITestsLaunchTests.swift`, `Support/KontinuumUITestCase.swift` → `NoteBytez…`;
  `class KontinuumUITestCase` → `NoteBytezUITestCase` (+ every subclass reference).
- `@testable import Kontinuum` → `@testable import NoteBytez` across all ~80 test files;
  any plain `import Kontinuum`.
- → **verify:** full `NoteBytezTests` suite green at the Phase 0 baseline count;
  `NoteBytezUITests` green per `NoteBytezCIGate.xctestplan`.

### Phase 3 — Code identifiers & embedded strings (SF4)
- `Notification.Name` raw values `kontinuum*` → `noteBytez*` (definitions in the extension +
  every `.kontinuum…` call site) (DD2).
- `DispatchQueue` labels, `Logger(subsystem:)` values, and the subsystem **fallback** literal
  → `com.g9Consulting.NoteBytez.*`.
- StoreKit product-ID constants → `com.g9Consulting.NoteBytez.sub.monthly` / `.sub.annual` /
  `.entitlement`; mirror inside `NoteBytez.storekit` (product IDs + any `Kontinuum` name field)
  (DD9).
- CloudKit zone subscription IDs → `notebytez-private-changes` / `notebytez-shared-changes` (DD3).
- Remaining strays: `kontinuum2` and any helper `kontinuum*` func/var names → investigate,
  rename.
- → **verify:** suite green; `git grep -i kontinuum -- '*.swift'` returns **only** a container
  constant line if one exists (else nothing).

### Phase 4 — File headers (SF3)
- Scripted replace of the header line `//  Kontinuum` → `//  NoteBytez` across
  `git ls-files '*.swift'` (~346 files). Leave the
  `// © Copyright, 2026 David L. Collison, All Rights Reserved.` line untouched.
- → **verify:** build green iOS + macOS; `git grep -n '^//  Kontinuum'` empty.

### Phase 5 — Documentation full sweep (SF7)
- Every non-`z_` `.md` under the repo (incl. `Kontinuum/CLAUDE.md`, `ARCHITECTURE.md`, all
  `Docs/Plans/**`, `Wiki/**`): `Kontinuum` → `NoteBytez` **except**
  `iCloud.com.g9Consulting.Kontinuum`.
- `git mv Docs/Plans/Projects/Kontinuum.md Docs/Plans/Projects/NoteBytez.md`; fix inbound links.
- `ARCHITECTURE.md`: replace the "## Legacy Identifiers" section with a short **"Retained
  name"** paragraph — the CloudKit container is the only `Kontinuum` string left, and
  `Scripts/verify-rename.sh` enforces it.
- Dated historical plans (`NoteBytez.md`, `NoteBytez20260906v1-NameChange.md`, …): body swept;
  add a one-line `> Superseded by NoteBytez20260908v1-ProjectRename.md` banner (DD5). Decisions
  not rewritten.
- Workspace-level `../CLAUDE.md` is shared across projects and out of scope (it names no app).
- → **verify:** markdown link-check clean; `git grep -i kontinuum -- '*.md'` returns only
  container lines.

### Phase 6 — Repository (SF6)
- **Maintainer, in GitHub settings:** rename `HawkIDad/Kontinuum` → `HawkIDad/NoteBytez` (DD6).
- `git remote set-url origin https://github.com/HawkIDad/NoteBytez.git`; `git fetch` to confirm.
- Quit Xcode; `mv ~/DevProjects/xCodeWorkspace/Kontinuum ~/DevProjects/xCodeWorkspace/NoteBytez`;
  reopen `NoteBytez.xcodeproj`.
- Confirm the `../MarkdownG9` package still resolves from the new path (sibling of the repo
  root — unchanged).
- → **verify:** `git remote -v` shows the new URL; `git fetch` works; clean build from the
  renamed directory; `MarkdownG9` resolves; no absolute-path breakage (regenerate `xcuserdata`
  if needed, DD8).

### Phase 7 — Enforcement gate (SF3)
- Rewrite `Scripts/verify-rename.sh`: `set -euo pipefail`; iterate `git ls-files` (skip
  binaries — `*.xcuserstate`, images, `*.storekit` is text so keep it); **fail (exit 1)** on
  any case-insensitive `kontinuum` match except lines matching
  `iCloud\.com\.g9Consulting\.Kontinuum` or the script's own `ALLOW=` definition (DD4). Update
  the header comment to describe the inverted intent.
- Add a canary (`// kontinuum` in a scratch file), confirm the script exits 1, remove it.
- Wire the script into the CI step that runs `NoteBytezCIGate` (or a dedicated CI job).
- → **verify:** `Scripts/verify-rename.sh` exits 0 on the renamed tree; exits 1 on the canary.

### Phase 8 — Definition of Done (SF1–SF7)
- `xcodebuild build` — iOS Simulator **and** `platform=macOS`: both **BUILD SUCCEEDED**.
- `xcodebuild test -only-testing:NoteBytezTests` — passes at the Phase 0 baseline count.
- `NoteBytezUITests` per `NoteBytezCIGate.xctestplan` — passes.
- Simulator smoke (iOS 26): app launches, a library can be created, sync status reaches
  "synced" against `iCloud.com.g9Consulting.Kontinuum`.
- `Scripts/verify-rename.sh` exits 0; `git grep -i kontinuum` shows only the container string.
- Delete `Docs/Plans/rename-inventory.txt`.
- Open one PR `rename/notebytez-project` → `main` with the phased commits intact.

## Definition of Done

SF1–SF7 all pass; build green iOS + macOS; `NoteBytezTests` + `NoteBytezUITests` green at
baseline; `Scripts/verify-rename.sh` (inverted) green in CI; the only `Kontinuum` string
anywhere in the repo is `iCloud.com.g9Consulting.Kontinuum`; the working copy is `NoteBytez/`
and `origin` points at `github.com/HawkIDad/NoteBytez.git`.
