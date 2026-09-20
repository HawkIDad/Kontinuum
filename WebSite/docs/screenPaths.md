<!-- screenPaths.md -->
<!-- Derived from the app source (ContentView.swift, SettingsView.swift, LibrarySelectionView.swift, RootView.swift and the view files they reach). Input to the screenshot manifest and Help how-tos. -->

# NoteBytez — screen path per feature

**Top level.** iPhone (compact width): tab bar **Today · Notebooks · Search · Explore · Settings**; *Explore* is a list of Graph, Insights, Tasks, Saved Views, Canvas, Tags and a Command Palette row. Mac / iPad (regular width): sidebar **Capture** (Today) · **Library** (Notebooks, All Notes, Tags) · **Explore** (Search, Graph, Insights, Tasks, Saved Views, Canvas) · **Settings**. There is no *All Notes* on iPhone. `⌘P` Command Palette and `⌘O` Quick Switcher are Mac/iPad shortcuts (menu **View**). A **sync glyph** sits in the toolbar of every screen.

`Capturable` = reachable with `-ScreenshotDestination <AppDestination>` today (top-level screens only). Everything else needs UI automation (see notes).

| Category | Feature | Path (iPhone → Mac/iPad differences in brackets) | Capturable |
|---|---|---|---|
| Getting Started | Create / select a library | Launch with no library → **Create New Library** (sheet) or pick from list | No (needs empty store) |
| | Onboarding role picker | Shown once by `RootView` after the first library exists → pick roles → **Add** / **Skip** | No |
| | Anatomy of the app | Any main screen | Yes (`Today`) |
| Capture & Journal | Today's journal / quick capture | **Today** tab [sidebar Capture › Today] | Yes |
| | Previous / next day | Today › date header chevrons | No |
| | Journal template | Today (template group applied to the Journal) — *no in-app attach UI found* | — |
| Documents & Blocks | Create a document | Notebooks › *notebook* › **+** [or All Notes › **+**; `⌘N`] → template picker → **Start Blank** | No |
| | Markdown, block anchors, external links | Open a note (edit mode) | No |
| | Export a note | Note › bottom bar **Export** (square.and.arrow.up) | No |
| Linking | Wikilinks, section links, block refs, transclusion | Typed in a note | No |
| | Backlinks pane, unlinked mentions | Note › bottom bar **Backlinks** (link) → sheet: Linked Mentions / Unlinked Mentions / Block References | No |
| Tags | Tag browser | Explore › **Tags** [Library › Tags] | Yes (`Tags`) |
| | Tagged notes | Tags › *tag*; or tap a `TagChip` in a note (sheet) | No |
| Tasks | Task Dashboard, filters, recurring | Explore › **Tasks** [Explore › Tasks]; Today toolbar **Tasks** (sheet) | Yes (`Tasks`) |
| | Save task filters | Tasks › toolbar **Save These Filters** | No |
| Notebooks | Browser, create | **Notebooks** tab [Library › Notebooks] › **+** New Notebook (sheet) | Yes (`Notebooks`) |
| | Add documents | Notebooks › *notebook* › **+** | No |
| | Promote a journal block | Today toolbar **Promote to Notebook** (sheet) [or Command Palette] | No |
| Search & Navigation | Full-text, scoped, advanced operators | **Search** tab [Explore › Search] › scope chips, Advanced toggle | Yes (`Search`) |
| | Save a search | Search › toolbar **Save This Search** | No |
| | Quick Switcher | Today toolbar **Quick Switcher** (sheet) [`⌘O`] | No |
| | Command Palette | Explore › **Command Palette** row [`⌘P`] | No |
| | Saved Views | Explore › **Saved Views** [Explore › Saved Views] | Yes (`Saved Views`) |
| Graph | Local graph, Radial / Force modes | Explore › **Graph** (mode picker in toolbar) [Explore › Graph]; note bottom bar **Graph** (sheet) | Yes (`Graph`) |
| | Filter bar, save as view, send to Canvas | Graph › toolbar **Filters** / **Send to Canvas** | No |
| | Graph Insights | Explore › **Insights** [Explore › Insights] | Yes (`Insights`) |
| Canvas | Boards list, new board, import | Explore › **Canvas** [Explore › Canvas] › **New Board** / **Import Canvas…** | Yes (`Canvas`) |
| | Cards, connectors, groups, zoom | Canvas › *board* › toolbar **Add Card** menu (Note / Media / Web Link / Group), connect toggle, zoom controls | No |
| | Bind to note, export | Canvas › board toolbar **Bind to Note…**, **Export Canvas…**; or long-press a board in the list | No |
| Properties & Templates | Typed Properties | Open a note › Properties section › **Add** | No |
| | Template Groups, Note Templates, fields | **Settings** › **Templates** › *group* › *template* | No |
| | Template Gallery, updates | **Settings** › **Template Gallery** › *pack* | No |
| | Apply a template | Note bottom bar **Apply Template**; or **+** template picker | No |
| | Attach a group to a Notebook / Journal | *DAL exists (`TemplateDAL`); no in-app UI found* | — |
| Attachments | Embed, preview | Note bottom bar **Add Attachment** (paperclip); tap thumbnail to preview | No |
| Sync & Conflicts | Status, last synced, Sync Now, log | Toolbar **sync glyph** (any screen) → Sync Status sheet | No |
| | Choose a conflict strategy | **Settings** › **Sync & Conflicts** | No |
| | Resolve a conflict | Sync Status › *Conflict* row → Conflict Resolution | No |
| Backup & Restore | Snapshots, restore | **Settings** › **Backups** › **Create Backup** / row › **Restore** | No |
| Sharing | Share, invite, permissions | **Settings** › **Sharing** (sheet) | No |
| Plugins | Enable, permissions | **Settings** › **Plugins** › **Add** | No |
| Migration | Obsidian / Logseq, verify, archive | No library open → library picker › **Migration Assistant (Obsidian/Logseq)** | No |
| Markdown Import/Export | Import `.md` folder | Library picker › **Import Existing Markdown Folder** → Import Preview › **Confirm Import** | No |
| | Export library | **Settings** › **Export Library** | No |
| Subscription & Account | Start, restore, manage | **Settings** › **Subscription** › **Change or Start Subscription** (Paywall) / **Restore Purchases** | No |
| | Lapsed banner, blocked states | Full-app gate (`EntitlementGateContainer`): banner above the app / full-screen Blocked view | No (`-SimulateEntitlement <scenario>` exists) |
| Settings extras | Language, translation report | **Settings** › **Language** / **Report a Translation Issue** | No |

## What this means for capture
- **Capturable today (top-level screens):** Today, Notebooks, Search, Graph, Insights, Tasks, Saved Views, Canvas, Tags, Settings, Explore (iPhone). Add these to `tools/screenshots/manifest.json` as needed. On iPhone `Tags`, `Tasks`, etc. are pushed from Explore, so `-ScreenshotDestination` alone lands on the wrong tab — the seam must select Explore then push (not built yet).
- **Everything else** (sheets, pushes, sub-screens) needs a driven UI. Recommended: an XCUITest capture target that uses the existing page objects in `NoteBytezUITests/Screens/` plus `XCUIScreen.main.screenshot()`, on both iPhone and "My Mac".
- **Gaps in the app worth a decision:** no All Notes on iPhone; no in-app UI to attach a Template Group to a Notebook or the Journal.
