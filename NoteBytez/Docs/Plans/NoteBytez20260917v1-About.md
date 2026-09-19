<!-- NoteBytez20260917v1-About.md -->
<!--
  User story to create the standard About screen for the NoteBytez app.
-->
# User Story
As the Senior Developer of the NoteBytez app, I want a standard, read-only About screen, reachable from the macOS application menu, Settings, and the Command Palette, that identifies the app and its version and opens the End User License Agreement and Privacy Policy, so that NoteBytez meets Apple and Swift Community conventions for app identity and legal disclosure on iOS and macOS.

# Success Factors
1. **Entry points** - the About screen is reachable, read-only, from all three:
    1. macOS application menu: "About NoteBytez" (replaces the standard `.appInfo` command).
    2. Settings: an "About" row in `SettingsView` (iOS and macOS).
    3. Command Palette: an "About NoteBytez" `AppAction`.
2. **Identity content** - the About screen shows the app icon, display name, and "Version {marketing} ({build})", read from the bundle (`CFBundleDisplayName`, `CFBundleShortVersionString`, `CFBundleVersion`), never hard-coded.
3. **Copyright** - the About screen shows "© Copyright, 2026 David L. Collison, All Rights Reserved."
4. **End User License Agreement** - the About screen has a "Terms of Use" row that opens the bundled EULA (`Resources/Legal/NoteBytez-EULA-v1.0.md`), read-only.
5. **Privacy Policy** - the About screen has a "Privacy Policy" row that opens the bundled Data Use Policy (`Resources/Legal/NoteBytez-Data-Use-Policy-v1.0.md`), read-only. The UI label is "Privacy Policy" (matches `PaywallView` and App Store terminology); the document's own title remains "Data Use Policy (Privacy Policy)".
6. **Consistent presentation** - both documents open in the existing `LegalDocumentView` sheet, the same one `PaywallView` uses.
7. **Quality** - About logic is testable and holds no view state: `AboutViewModel` unit tests reach 100% coverage; a UI smoke test opens About from Settings and opens both documents. Logging uses OSLog; UI strings are localizable literals (no new hardcoded-string lint violations).

# Decisions
| # | Decision |
|---|----------|
| 1 | Entry points: macOS app menu, Settings row, Command Palette action. |
| 2 | Content: icon, name, version (build), copyright. No acknowledgements or support links in this story. |
| 3 | Legal documents reuse the `LegalDocumentView` sheet. |
| 4 | UI label "Privacy Policy" for the Data Use Policy. |
| 5 | Tests: `AboutViewModel` unit tests plus a UI smoke test. |

# Out of Scope
- Third-party acknowledgements (MarkdownG9, etc.) and support/website links.
- First-launch EULA acceptance and re-prompt on version change.
- Localizing the legal documents themselves.

# Implementation Plan
Each step follows TDD: write the failing test first, then the code. Every new `.swift` file carries the copyright header.

1. **AboutViewModel** (`viewModels/AboutViewModel.swift`) → verify: unit tests.
    - `@Observable` final class, `init(bundle: Bundle = .main)` for testability.
    - Properties: `displayName`, `versionText` ("Version 1.0 (1)"), `copyrightText`. Missing keys fall back with nil coalescing (no force unwraps).
    - Tests (`NoteBytezTests/AboutViewModelTests.swift`): a stub bundle with all keys, missing keys, and the copyright string.
2. **AboutView** (`views/About/AboutView.swift`) → verify: SwiftUI preview and UI test.
    - Icon, name, version and copyright at the top, per `docs/styleGuide.md`.
    - A `List` section with "Terms of Use" and "Privacy Policy" buttons that set `@State presentedLegalDocument: LegalDocumentView.LegalDocument?`.
    - `.sheet(item:)` presents `LegalDocumentView(document:)`, mirroring `PaywallView`.
    - Accessibility labels on the icon and rows; works with Dynamic Type.
3. **Settings entry** (`views/SettingsView.swift`) → verify: UI smoke test.
    - Add `NavigationLink("About") { AboutView() }` to the list.
4. **macOS menu entry** (`NoteBytezApp.swift`, `AppCommands.swift`, `ContentView.swift`) → verify: manual run on macOS.
    - Add `Notification.Name.noteBytezOpenAbout`.
    - Add `CommandGroup(replacing: .appInfo) { Button("About NoteBytez") { post } }`.
    - `ContentView` observes the notification with `.onReceive` and presents `AboutView` in a sheet, matching how `.noteBytezOpenSettings` is handled.
5. **Command Palette entry** (`AppCommand.swift`, `ContentView.swift`) → verify: extend `AppCommandTests`.
    - Add `AppAction.openAbout` with title "About NoteBytez" and symbol `info.circle`.
    - Handle the case in `ContentView`'s action switch by presenting the same sheet as step 4.
6. **Tests** → verify: the CI gate test plan passes.
    - `AboutViewModelTests` (step 1) and `AppCommandTests` additions (step 5).
    - `NoteBytezUITests/AboutScreenTests.swift`: Settings → About → opens Terms of Use → Done → opens Privacy Policy → Done. Add the screen object to `Screens/SettingsScreens.swift`.
7. **Strings and docs** → verify: `Scripts/lint-hardcoded-strings.sh` passes.
    - Add new literals to `Localizable.xcstrings`.
    - Add `AboutView` and `AboutViewModel` to `ARCHITECTURE.md`.

**Assumptions to confirm:**
- `Resources/Legal/*.md` is bundled, so `LegalDocumentView` loads it (verify on first run).
- The macOS About sheet is acceptable in place of the system About panel, since the panel cannot host legal links.
