<!-- NoteBytez-MacImplementation.md -->
<!--
  Detailed build checklist for adding a native macOS destination to NoteBytez, alongside the
  existing iPhone/iPad build. Derived from a codebase evaluation (grep/read audit of the actual
  project settings and source, not a guess): only one file imports UIKit
  (NoteBytez/AppDelegate.swift), no `#if os(` conditionals exist anywhere yet, and the project's
  build settings are hard-pinned to `SDKROOT = iphoneos` with no macOS destination at all.

  This is a living document: every task starts unchecked. Check a box only when the task is
  actually done and verified (builds, passes its test, or is confirmed working) — not when it's
  merely started.

  Checkbox convention: [ ] not started/in progress, [x] done and verified.
-->

# NoteBytez Mac Implementation Plan

Source: codebase evaluation (project.pbxproj build settings, `grep` audit of UIKit/iOS-only API usage across `NoteBytez/`). Ties into [NoteBytez-MVP-ImplementationPlan.md](NoteBytez-MVP-ImplementationPlan.md) Phase 15, which already flags Mac as unverified and documents a prior failed attempt (see Phase 0 below) — this plan is what unblocks that line.

## Scope / Non-Goals

- **In scope:** one native macOS destination, built from the same source tree and file list as iOS/iPadOS, sharing the same CloudKit container (`iCloud.com.g9Consulting.Kontinuum`) so a library syncs across all three platforms with no extra plumbing.
- **Not Mac Catalyst.** The one prior attempt at Mac support (per MVP Plan Phase 15) used the "My Mac (Designed for iPad)" Catalyst destination and failed outright on a provisioning/entitlement mismatch (`com.apple.developer.default-data-protection` — an iOS-only key — didn't match the Mac profile). Catalyst runs the iOS app's UIKit compatibility-shimmed on Mac; this plan instead targets the real `macosx` SDK directly with AppKit-backed SwiftUI, which is both the modern Apple-recommended path and the only one consistent with `CLAUDE.md`'s "unapologetically native" positioning.
- **Not a second target/codebase.** Xcode's multiplatform "Supported Destinations" model (one target, `SUPPORTED_PLATFORMS` covering both SDKs) is used instead of a duplicated Mac target — one file list, no drift risk between platforms.
- **No changes to the CloudKit schema, `SyncEngine`'s sync protocol, or any DAL/model logic.** The audit found zero UIKit dependency below the view layer — `dal/`, `sync/`, `models/`, and every `viewModel` are already pure Foundation/SwiftData and need no changes.

---

## Progress Summary

| Phase | Tasks complete | Status |
|---|---|---|
| 0. Approach Decision & Prerequisites | 3 / 3 | Complete |
| 1. Project & Target Configuration | 7 / 7 | Complete — verified with a real macOS build attempt |
| 2. Platform-Conditional App Lifecycle | 4 / 4 | Complete — verified with a real macOS build attempt |
| 3. Cross-Platform UI Compatibility Layer | 3 / 3 | Complete — **first BUILD SUCCEEDED for `platform=macOS`** |
| 4. Mac-Native Shell Polish | 3 / 4 | Code complete; screenshot now obtained (Screen Recording permission granted) but shows onboarding empty state, not populated sidebar — needs Accessibility permission or a manual click, see phase note |
| 5. Build, Test & Cross-Platform Verification | 2 / 4 | Build + full test suite (`NoteBytezTests` + `NoteBytezUITests`) verified green on macOS this session; manual GUI pass and live-CloudKit smoke test remain — both need a human, see phase notes |
| 6. Documentation & Housekeeping | 2 / 2 | Complete |
| **Total** | **24 / 27** | **~89%** |

Update this table's counts and status column as boxes below are checked.

---

## Phase 0 — Approach Decision & Prerequisites

Not code — the decisions and environment prerequisites everything below depends on.

- [x] Approach confirmed: native multiplatform single target (`macosx` + `iphoneos`/`iphonesimulator` SDKs sharing one source/file list), not Mac Catalyst — supersedes the failed "Designed for iPad" attempt logged in [NoteBytez-MVP-ImplementationPlan.md](NoteBytez-MVP-ImplementationPlan.md) Phase 15
- [x] A build environment with valid Mac code-signing is available — verified via `security find-identity -v -p codesigning`: three valid identities present, including two "Developer ID Application: David Collison (S4843K7ZH6)" certs matching the project's existing `DEVELOPMENT_TEAM = S4843K7ZH6` / `CODE_SIGN_STYLE = Automatic`. `defaults read com.apple.dt.Xcode IDEProvisioningTeams` confirms that team is a **paid** individual account (`isFreeProvisioningTeam = 0`) — required for the CloudKit/iCloud-container entitlement to provision for real, which is what the prior Catalyst attempt tripped on. No stale local provisioning profile conflicts (only one unrelated 2020 profile present; Automatic signing regenerates as needed)
- [x] Target macOS deployment version chosen: **`MACOSX_DEPLOYMENT_TARGET = 26.5`** — verified via `xcodebuild -showsdks`: this Xcode 26.6 install has `macOS 26.5` available locally, the exact same version number as the existing `IPHONEOS_DEPLOYMENT_TARGET = 26.5`, so no version-skew decision is actually needed

---

## Phase 1 — Project & Target Configuration

Xcode project settings only — no source changes yet. Everything here is mechanical but must land before Phase 2/3 code can even compile for macOS.

- [x] Add `macosx` to the app target's supported destinations — done at the **project level** (`SDKROOT = auto;`, `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx";` on both project-level Debug/Release configs), not duplicated per-target, so it cascades to `NoteBytez`, `NoteBytezTests`, and `NoteBytezUITests` automatically. Verified: `xcodebuild -showdestinations` now lists `{ platform:macOS, name:Any Mac }` / `My Mac` alongside the existing iOS destinations
- [x] Set `MACOSX_DEPLOYMENT_TARGET = 26.5` on both project-level configs, alongside the existing `IPHONEOS_DEPLOYMENT_TARGET = 26.5`
- [x] Mac device-family entry — **turned out to be unneeded**: `TARGETED_DEVICE_FAMILY` is an iOS/iPadOS/tvOS/watchOS-only build setting; it's simply not consulted when the active SDK resolves to `macosx`. Left the existing `TARGETED_DEVICE_FAMILY = "1,2"` untouched rather than adding a no-op Mac value
- [x] Created [NoteBytez-macOS.entitlements](../../NoteBytez-macOS.entitlements): same `iCloud.com.g9Consulting.Kontinuum` container + `CloudKit` service as [NoteBytez.entitlements](../../NoteBytez.entitlements), **without** `com.apple.developer.default-data-protection`. Wired in via `"CODE_SIGN_ENTITLEMENTS[sdk=macosx*]" = NoteBytez/NoteBytez-macOS.entitlements;` on the app target (base `CODE_SIGN_ENTITLEMENTS` still points at the iOS file) — confirmed via a real build log: the packaged entitlements for the macOS build contain the iCloud/CloudKit keys and *not* the data-protection key that broke the prior Catalyst attempt
- [x] Created [Info-macOS.plist](../../Info-macOS.plist) (empty dict, no `UIBackgroundModes`), wired in via `"INFOPLIST_FILE[sdk=macosx*]" = NoteBytez/Info-macOS.plist;`; added `Info-macOS.plist` to the same `PBXFileSystemSynchronizedBuildFileExceptionSet` membership-exceptions list as `Info.plist` so it's treated as an Info.plist source, not bundled as a stray resource
- [x] Mac signing — no new configuration needed. **Verified with a real build**, not just inspected: `xcodebuild ... -destination 'platform=macOS' -allowProvisioningUpdates build` succeeded in auto-generating a Mac provisioning profile for `com.g9Consulting.NoteBytez` under the existing `DEVELOPMENT_TEAM = S4843K7ZH6` / `CODE_SIGN_STYLE = Automatic` settings — the exact paid-team identity confirmed present in Phase 0
- [x] `NoteBytezTests`/`NoteBytezUITests` — covered for free by the project-level `SUPPORTED_PLATFORMS` change (first task above); no target-specific edits needed. Whether `NoteBytezUITests`' automation actually behaves well on Mac is a Phase 5 runtime question, not a Phase 1 config question

**Verification:** `xcodebuild -destination 'platform=macOS' -allowProvisioningUpdates build` now fails only at `AppDelegate.swift:8: Unable to resolve module dependency: 'UIKit'` — i.e. it gets past every project-configuration concern this phase owns (provisioning, entitlements, Info.plist, asset catalog compilation for `macosx`) and stops exactly at Phase 2's known scope. Re-ran the iOS Simulator build afterward to confirm the `SDKROOT = auto` change didn't regress iOS — still builds clean.

---

## Phase 2 — Platform-Conditional App Lifecycle

The one place in the codebase with genuine platform-specific logic: `AppDelegate.swift` bridges silent CloudKit push into `SyncEngine`, and does it entirely through `UIApplicationDelegate`.

- [x] `#if os(iOS)` branch in `AppDelegate.swift` keeps the existing `UIApplicationDelegate` implementation unchanged
- [x] `#elseif os(macOS)` branch adds an `NSApplicationDelegate` counterpart: `applicationDidFinishLaunching` calls `NSApplication.shared.registerForRemoteNotifications()`, failure logging matches the iOS path's signature (`NSApplicationDelegate`'s `didFailToRegisterForRemoteNotificationsWithError` takes the same shape), and remote-notification receipt routes into the same `SyncEngine.shared.handleRemoteNotification()` call — as expected, `NSApplicationDelegate.application(_:didReceiveRemoteNotification:)` has no `fetchCompletionHandler`/background-budget concept the way iOS's does (also its `userInfo` is `[String: Any]`, not `[AnyHashable: Any]`), so this is a fire-and-forget `Task`, not a like-for-like signature port
- [x] `NoteBytezApp.swift`'s `@UIApplicationDelegateAdaptor(AppDelegate.self)` property gated per-platform against `@NSApplicationDelegateAdaptor(AppDelegate.self)`
- [x] Confirmed `SyncEngine.handleRemoteNotification()` needs no changes — re-audited `sync/`, `dal/`, `models/`, `viewModels/` for `UIKit`/`UIApplication`/`UIBackgroundFetchResult` after this phase's edits: zero hits, as expected

**Verification:** `xcodebuild -destination 'platform=macOS' -allowProvisioningUpdates build` now compiles `AppDelegate.swift`, `NoteBytezApp.swift`, and the entire `dal`/`sync`/`models`/`viewModels` layers clean, and gets deep into the view layer before failing — confirming Phase 3's predicted blockers for real rather than by static analysis: `error: reference to member 'secondarySystemBackground' cannot be resolved without a contextual type` in `PromoteSourcePreview.swift:23` and `QuickSwitcherField.swift:25` (plus `ConflictVersionCard.swift`/`DiffMergeView.swift` failing in the same compile batch), exactly the `Color(.secondarySystemBackground)` call sites Phase 3 already lists. Re-ran the iOS Simulator build and full `NoteBytezTests` suite afterward — both still pass, no regression from the `AppDelegate`/`NoteBytezApp` split.

---

## Phase 3 — Cross-Platform UI Compatibility Layer

Two iOS/iPadOS-only APIs are used widely enough across the view layer that they're the actual compile blockers today. Both get a single shared fix rather than per-call-site `#if os()` sprinkled 24 times.

- [x] Added `View.noteBytezInlineNavigationTitle()` in new [PlatformCompatibility.swift](../../views/Components/PlatformCompatibility.swift) — stands in for `.navigationBarTitleDisplayMode(.inline)` (a no-op on macOS, where the type doesn't exist). Replaced across all 18 actual call sites (one more than this plan originally counted — `NotebookBrowserView` has it twice): `ConflictStrategySettingsView`, `DocumentView`, `SearchView`, `GraphView`, `LibrarySelectionView`, `ConflictResolutionView`, `BacklinksPaneView`, `TodayJournalView`, `QuickSwitcherView`, `NotebookDocumentsView`, `PromoteBlockPickerView`, `SyncStatusView`, `ImportScanView`, `PromoteToNotebookView`, `NotebookBrowserView` (×2), `TagBrowserView`, `TaggedDocumentsView`
- [x] Added `Color.noteBytezSecondarySurface` in the same file — backed by `UIColor.secondarySystemBackground` on iOS, `NSColor.controlBackgroundColor` on macOS. Replaced across the 7 actual call sites: `TodayJournalView`, `DocumentView`, `SearchView`, `QuickSwitcherField`, `ConflictVersionCard`, `PromoteSourcePreview`, `DiffMergeView`. **`Color.noteBytezSurface` (for `Color(.systemBackground)`) wasn't added** — this plan originally assumed both existed in the codebase, but the audit turned up zero real `Color(.systemBackground)` call sites, only `.secondarySystemBackground`; adding an unused twin would be speculative
- [x] Full project builds clean for both `iphonesimulator` and `macosx` destinations — **verified with real builds, not just inspection**: `xcodebuild -destination 'platform=macOS' -allowProvisioningUpdates build` now reports **BUILD SUCCEEDED**, code-signed and validated as `NoteBytez.app`. iOS Simulator build and the full `NoteBytezTests` suite re-verified clean afterward — no regression

**This is the first fully green native macOS build of NoteBytez.** Phases 0–3 (approach, target config, app lifecycle, UI compatibility) are done; everything from here is polish and verification, not compile blockers.

---

## Phase 4 — Mac-Native Shell Polish

Not compile blockers — the app builds and runs without these — but needed for the app to read as genuinely native on Mac rather than a stretched iPad layout, consistent with `CLAUDE.md`'s "unapologetically native" wedge.

- [x] Menu bar `.commands {}` for New Note (⌘N, replaces the default "New Window" item — a literal new window doesn't fit this app's single-shared-library model, matching how Notes.app/Bear repurpose ⌘N), Search (⌘O, replacing the default new-tab group), and Settings (⌘,, populates the normally-empty `.appSettings` group). Declared in [NoteBytezApp.swift](../../NoteBytezApp.swift); since `ContentView` owns the navigation `@State` and Commands live at the `App` level above it, they're bridged via `NotificationCenter` (new [AppCommands.swift](../../AppCommands.swift) declares the three `Notification.Name`s) rather than restructuring where selection state lives. `ContentView` listens and switches `selectedSidebarDestination`/`selectedTab`; `DocumentListView` separately listens for New Note to actually call its existing `createDocument()`. **Scope note:** Search routes to the existing `.search` sidebar destination (full `SearchView`), not a global Quick Switcher overlay — `QuickSwitcherView` is currently only sheet-presentable from `TodayJournalView`'s own local state, and wiring a from-anywhere quick switcher would need new cross-view navigation plumbing (`navigationDestination` at the `ContentView` level) beyond this phase's polish scope. `.commands {}` itself is a legitimate cross-platform SwiftUI API — a no-op on iPhone, real shortcuts on iPad with a hardware keyboard — so it wasn't platform-guarded
- [x] Window sizing: `.defaultSize(width: 1000, height: 700)` on the `WindowGroup` scene, `#if os(macOS)`-gated since `defaultSize` isn't available on iOS. Left resizability at its default (`.automatic`) rather than `.contentSize` — this is a text/list app, not a fixed-content one, so free resizing is correct
- [x] `.onHover` affordance added to `GraphNode` — nodes scale to 1.3× with a 0.12s ease-out on pointer hover (matches Obsidian's own graph-hover convention). `.onHover` is a no-op on touch-only platforms, so no platform guard needed
- [ ] Visual confirmation that the sidebar shell renders correctly on Mac — **partially achieved; still open**. Screen Recording permission is now granted in this environment, which unblocked `screencapture`: built the macOS app, launched it, activated it (`lsappinfo` confirmed it took foreground), and captured a real screenshot — confirmed a proper native AppKit window (traffic-light chrome, unified toolbar, correct `NoteBytez` app menu bar with File/Edit/View/Window/Help) with no crash. What it actually showed was the app's "No Libraries Yet" onboarding empty state, not a populated sidebar — this is a fresh Debug-build container with no library created yet, not a rendering bug. Could not get further: Accessibility/UI-scripting permission (`System Events`, needed to synthetically click "Create New Library") is still denied (`-25211 not allowed assistive access`) and is a separate TCC grant from Screen Recording, only settable by a human in System Settings; no `cliclick`-equivalent is installed either. Checked the codebase for a UI-test launch-argument seeding hook (common pattern for skipping onboarding in screenshots) — none exists, and adding one speculatively is out of scope. Quit the app cleanly afterward. **A human needs to either grant Accessibility permission or click through onboarding once** so the populated sidebar (not just the empty state) can be screenshotted before this box is checked

---

## Phase 5 — Build, Test & Cross-Platform Verification

- [x] `xcodebuild build` succeeds for a `macosx` destination — re-verified with a fresh build this session: `xcodebuild -project NoteBytez.xcodeproj -scheme NoteBytez -destination 'platform=macOS' -allowProvisioningUpdates build` → **BUILD SUCCEEDED**, signed with the `S4843K7ZH6` team's Mac provisioning profile
- [x] `NoteBytezTests` builds and passes running as a macOS test bundle — `xcodebuild ... -destination 'platform=macOS' test`: all `NoteBytezTests` suites (DAL, parsers, sync mapping, import/export, conflict resolution, etc.) ran and passed with 0 failures, exactly as predicted (pure SwiftData/Foundation, no platform-specific code). `NoteBytezUITests` ran too (as its own `NoteBytezUITests-Runner` process) and also passed, though its automation coverage on Mac is worth a second look in the manual pass below since UI test recorders are iOS-first
- [ ] Manual screen-by-screen pass on a real Mac (or a working "My Mac" destination) — this is what unblocks the Mac line in [NoteBytez-MVP-ImplementationPlan.md](NoteBytez-MVP-ImplementationPlan.md) Phase 15, which has been blocked since that phase was written. Same boundary as Phase 4's open item: Screen Recording is granted so screenshots work, but Accessibility/UI-scripting is not, so this environment can drive the app up to whatever its first unclicked screen is (currently the onboarding empty state) and no further
- [ ] Cross-platform CloudKit sync smoke test: a note created on iPhone/iPad appears on Mac through the shared `iCloud.com.g9Consulting.Kontinuum` private container (needs a live iCloud account — same caveat already logged against MVP Plan Phases 12–14)

---

## Phase 6 — Documentation & Housekeeping

- [x] Updated [NoteBytez-MVP-ImplementationPlan.md](NoteBytez-MVP-ImplementationPlan.md) Phase 15's Mac line to reference this plan — the original Catalyst provisioning blocker is resolved (real `macosx` build + `NoteBytezTests`/`NoteBytezUITests` pass); what's left there is the same GUI-pass/CloudKit gap this plan tracks in Phase 5
- [x] Updated [docs/styleGuide.md](../styleGuide.md)'s Surface color row (was still documenting the removed `Color(.secondarySystemBackground)` iOS-only call) to `Color.noteBytezSecondarySurface`, and added a line pointing at [PlatformCompatibility.swift](../../views/Components/PlatformCompatibility.swift) for both compatibility helpers

---

## Coverage check

Every concrete gap identified in the codebase evaluation (single UIKit import, missing macOS destination, `.navigationBarTitleDisplayMode` and `Color(.system...)` call sites, the prior Catalyst provisioning failure) maps to a task above; no finding from that evaluation is unaddressed.
