<!-- NoteBytez20260627v2-Security.md -->
<!--
  Whole-app security assessment & test plan (v2). Supersedes the Phase 11 (Local File
  Encryption) slice in NoteBytez-R1-Implementation.md, which covered at-rest file protection
  only. This plan is an audit/verification plan, not a feature build: every item produces
  evidence (a passing test, a documented config check, or a written finding), never new
  product behaviour except where a finding forces a fix.

  Living document. Checkbox convention: [ ] not started / in progress, [x] done and evidence
  recorded. Each workstream item names its method, the standard clause it maps to, and a
  pass criterion. Workstreams are ordered by dependency: the threat model (WS0) frames every
  later stream; static/config review precedes dynamic testing.

  Severity: CVSS v3.1 base score + qualitative band (Critical/High/Medium/Low/Info).
  Findings tracked in Docs/Security/findings/ (one file per finding, template in WS-REPORT).
-->

# NoteBytez Security Assessment & Test Plan (v2)

## Objective

As the owner of a local-first, CloudKit-synced, multi-user knowledge app that also runs
user-authored plugin code, I want a repeatable security assessment covering storage, transport,
authorization, the plugin sandbox, untrusted-input parsing, platform hardening, and the release
pipeline — measured against Apple guidance and recognised industry standards — so that a release
can be signed off against explicit criteria rather than assumption.

> App Store provenance + auto-renewable-subscription enforcement (blocking side-loaded/patched
> copies and gating use on an active subscription) is **owned by `NoteBytez20260907v1-Security.md`**,
> not this plan. This assessment still covers the entitlement cache's at-rest posture (WS2) and
> the RESILIENCE stance it inherits (WS9.5).

## Standards & Frameworks (authoritative references)

| Ref | Source | Used for |
|---|---|---|
| **OWASP MASVS 2.1** | OWASP Mobile Application Security Verification Standard | Primary control catalogue — STORAGE, CRYPTO, AUTH, NETWORK, PLATFORM, CODE, RESILIENCE |
| **OWASP MASTG** | Mobile Application Security Testing Guide (iOS) | Concrete test procedures per MASVS control |
| **OWASP Mobile Top 10 (2024)** | OWASP | Risk framing / exec summary categorisation |
| **OWASP ASVS 4.0.3** | OWASP | Server-side-style logic that CloudKit share permissions and conflict resolution represent (access control, V4/V8) |
| **Apple Secure Coding Guide** | developer.apple.com | Language/API misuse, injection, race conditions, buffer/format issues |
| **Apple Data Protection** | File protection classes, Keychain, Secure Enclave | At-rest crypto posture (WS2) |
| **Apple App Sandbox + Hardened Runtime** | macOS | Entitlement minimisation, notarisation (WS9) |
| **Apple Privacy Manifests / ATT / ATS** | Required-reason APIs, `PrivacyInfo.xcprivacy` | Privacy compliance (WS10) |
| **Apple CloudKit security model** | Private DB, `CKShare`, zone encryption | Sharing authz (WS4) |
| **NIST SP 800-163r1** | Vetting the Security of Mobile Applications | Assessment methodology / checklist backbone |
| **NIST SP 800-218 (SSDF)** | Secure Software Development Framework | Build/CI/release stream (WS14) |
| **NIST SP 800-53r5** | Control families (AC, SC, SI, CM, RA) | Cross-reference for enterprise buyers |
| **CIS Apple iOS/iPadOS & macOS Benchmarks** | CIS | Device-posture assumptions the app depends on |
| **CWE Top 25 (2024)** | MITRE | Finding classification |
| **STRIDE / LINDDUN** | Microsoft / KU Leuven | Threat- and privacy-threat modelling (WS0) |

## Scope

**In scope**
- The `NoteBytez` app target (iPhone, iPad, native macOS), all `dal/`, `sync/`, `viewModels/`,
  `views/`, `models/` code.
- Local packages `MarkdownG9` and `SwiftRPT` (`../MarkdownG9`, `../SwiftRPT`) as bundled
  dependencies.
- CloudKit container `iCloud.com.g9Consulting.Kontinuum`: schema, share permissions, zone
  layout — the client's *use* of it.
- Local persisted artefacts: SwiftData store, `Backups/`, `SyncState/`, `AttachmentStore/`,
  `MigrationArchives/`.
- Plugin execution path (`PluginBridge`, `PluginDAL`, `Plugin` sync).
- All untrusted-input entry points: Markdown import, Obsidian/Logseq migration, `.canvas`
  import, attachment ingestion, backup restore, inbound `CKShare` acceptance.
- Build settings, entitlements, `Info.plist`(s), signing, CI test plan.

**Out of scope**
- Apple's CloudKit server infrastructure, APNs, iCloud account security, Secure Enclave
  internals (assumed trustworthy; documented as assumptions in WS0).
- Physical/forensic device attacks beyond what Data Protection classes address.
- Social engineering of end users outside the app.
- Formal cryptographic primitive review (no custom crypto exists — see WS12).
- Penetration test of third-party infrastructure.

## WS0 — Threat model & architecture review

- [ ] **0.1 Asset inventory.** Enumerate assets and sensitivity: note content (Confidential),
  attachments (Confidential), tags/metadata (Confidential), plugin scripts (Integrity-critical —
  they execute), CloudKit share participant identities (PII), sync-engine state, backup
  snapshots. Method: doc review + code walk. Output: `Docs/Security/threat-model.md` asset table.
- [ ] **0.2 Trust boundaries & data-flow diagram.** Draw DFDs for: local edit → SwiftData →
  CloudKit; import/migration file → parser → model; plugin script → `PluginBridge` → host
  writes; inbound `CKShare` → participant with `readWrite` → synced records (incl. `Plugin`).
  Map each boundary crossing. Standard: NIST 800-163r1 §3, STRIDE per-element.
- [ ] **0.3 STRIDE pass per boundary.** Spoofing (participant identity, plugin provenance),
  Tampering (CloudKit record fields in transit to a co-owner's device, backup JSON), Repudiation
  (`createdBy`/`updatedBy` currently unpopulated — attribution gap), Information disclosure
  (macOS at-rest, logs, pasteboard, QuickLook), DoS (ReDoS, huge-file reads, runaway plugin
  thread), Elevation of privilege (plugin permission escalation via synced `permissionsJSON`,
  `canWrite` fail-open). Output: ranked threat register with CVSS-estimated severity.
- [ ] **0.4 LINDDUN privacy pass.** Linkability/identifiability of participants; data
  minimisation in the plugin `PluginLibrarySnapshot` (currently full document `content` of every
  note is handed to every enabled plugin). Standard: LINDDUN, Apple privacy guidance.
- [ ] **0.5 Documented trust assumptions.** Explicit written list (Apple platform crypto, APNs
  delivery integrity, device passcode set, user vets plugins before enabling). Everything not on
  the list is in test scope.

## WS1 — Static analysis & secure-coding review

- [ ] **1.1 Compiler/analyser clean.** Build with `-Wall`, treat-warnings-as-errors audit,
  Xcode Static Analyzer (`analyze`), and Swift concurrency checking `complete`. Address or
  ticket every diagnostic. Standard: Apple Secure Coding Guide; MASVS-CODE-1.
- [ ] **1.2 Lint for dangerous patterns.** SwiftLint custom rules + `grep` audit for: forced
  unwrap (`CLAUDE.md` already bans; verify), forced `try!`, `NSRegularExpression(pattern:)` with
  `try!`, `String(contentsOf:)` without size guard, `FileManager` path building by string
  concatenation, `evaluateScript`, `URL(string:)` on external input, unbounded recursion in
  parsers. Output: annotated list, each item → finding or justified accept.
- [ ] **1.3 Secret scan.** `gitleaks` / `trufflehog` over full history + current tree. Confirm
  no API keys, tokens, container credentials, signing material, `.p12`, provisioning profiles
  committed. Standard: SSDF PW.4; CWE-798.
- [ ] **1.4 Injection surface review.** `#Predicate` usage (compiled — confirm no string-built
  predicates), regex construction, Markdown → `AttributedString` link generation in `MarkdownG9`
  (`wikilink://` / `tag://` / `blockref://` emission), `OpenURLAction` scheme handling in
  `DocumentView` / `TodayJournalView`. Verify the `default: .systemAction` branch cannot be
  driven by document content to open `http(s)://`, `file://`, `shortcuts://`, `tel://` etc. from
  a crafted `[[...]]`. Standard: MASTG-TEST deep links; CWE-939/CWE-79 (link-context).

## WS2 — Data at rest (MASVS-STORAGE)

- [ ] **2.1 SwiftData store protection.** Confirm the on-disk SwiftData/SQLite store inherits
  `NSFileProtectionComplete` from the iOS entitlement (`com.apple.developer.default-data-protection`).
  Test on a **physical device** (simulator cannot report protection class — see
  `LocalFileProtectionTests` header). Verify store is unreadable while device locked. MASTG:
  data storage tests.
- [ ] **2.2 Local-file protection regression.** Extend `LocalFileProtectionTests` to assert
  `.complete` for every writer: `BackupDAL`, `SyncStateStore`, `AttachmentStorage`,
  `MigrationArchiveDAL`. Add a test that fails if a new local-file writer appears without a
  protection attribute (enumerate Application Support tree post-exercise). Standard:
  Apple Data Protection; MASVS-STORAGE-1.
- [ ] **2.3 macOS at-rest gap.** macOS has no per-file Data Protection API; `Kontinuum-macOS.entitlements`
  sets no protection key. Document the resulting posture (rest security == FileVault only).
  Decide + record: is FileVault a stated requirement? Evaluate `NSFileProtectionComplete`
  no-op on macOS and whether Keychain-wrapped or `CryptoKit` envelope encryption is warranted
  for `Backups/` and `MigrationArchives/` on macOS. Finding if unmitigated. Standard: CIS macOS
  Benchmark 2.6 (FileVault); MASVS-STORAGE-1.
- [ ] **2.4 No secrets in plaintext stores.** Confirm nothing sensitive lands in
  `UserDefaults`, plist, or unprotected caches: `SharingPermissionStore` (in-memory only —
  verify not persisted), sync tokens (`SyncState/` — protected, verify), no note content cached
  by `TextEditor` outside the protected store. MASTG: sensitive data in local storage.
- [ ] **2.5 Keyboard cache / autocorrect.** Ensure the Markdown editor `TextEditor` does not
  leak note content to the keyboard learning cache (evaluate `.autocorrectionDisabled` /
  secure-entry trade-off; document decision — full secure entry is likely too costly UX).
- [ ] **2.6 Backgrounding snapshot.** Verify the app obscures its window in the app switcher
  snapshot (iOS) so note content is not captured to `Library/SplashBoard`. MASTG-TEST.
- [ ] **2.7 Pasteboard hygiene.** Copy actions on note/block content — confirm no
  `UIPasteboard` general-pasteboard persistence beyond user intent, no `.expirationDate`-less
  sensitive writes, and nothing auto-copied. Standard: Apple pasteboard privacy.

## WS3 — Data in transit (MASVS-NETWORK)

- [ ] **3.1 Traffic inventory.** Confirm the only egress is CloudKit (`CKSyncEngine`,
  `CloudKit` framework) and APNs silent push (`remote-notification` background mode). No
  bespoke `URLSession`, no analytics, no crash SDK. Method: symbol search + mitmproxy/Charles
  run of a full session. MASVS-NETWORK-1.
- [ ] **3.2 ATS posture.** No `NSAppTransportSecurity` dictionary present → default (TLS 1.2+,
  no arbitrary loads). Confirm no target or package adds an ATS exception. Standard: Apple ATS.
- [ ] **3.3 CloudKit TLS trust.** CloudKit manages pinning/trust internally; verify the app adds
  no `URLSessionDelegate` that weakens trust evaluation and no `serverTrust` overrides anywhere
  (incl. packages). MASTG: TLS verification tests.
- [ ] **3.4 Push payload trust.** `AppDelegate` remote-notification path must treat the APNs
  payload as a trigger only (fetch from CloudKit), never as authoritative data. Verify
  `handleRemoteNotification` does not act on push-supplied content. CWE-345.

## WS4 — CloudKit & multi-user authorization (MASVS-AUTH / ASVS V4)

- [ ] **4.1 Share permission enforcement — client.** `SharingPermissionStore.canWrite` returns
  `readWrite` by default (`?? .readWrite`) for any library with no cached share. Test: a
  `readOnly` participant whose cache is cold/cleared — does `SyncEngine.recordChanged` wrongly
  allow a local write to a shared library? Assess fail-open severity and whether the server
  rejects the push regardless. Standard: ASVS V4.1 (deny by default); CWE-276.
- [ ] **4.2 Share permission enforcement — server.** Confirm CloudKit itself rejects writes
  from a `readOnly` participant (the real backstop). Live test with two iCloud accounts: accept
  a read-only share, force a local edit, observe the sync error. Evidence: captured CKError.
- [ ] **4.3 Zone / record isolation.** Verify one `CKRecordZone` per library, records parent to
  the library zone, and a participant of library A cannot enumerate or fetch library B's zone.
  Test cross-library reference resolution (`BlockReferenceDAL`, wikilinks) does not leak titles
  or content across a share boundary.
- [ ] **4.4 Malicious co-participant record injection.** A `readWrite` participant is trusted to
  edit notes — but can they inject a **`Plugin`** record (arbitrary JS + `permissionsJSON`) into
  the shared library that then syncs to and is offered for execution on the owner's device?
  Trace `Plugin.libraryId` scoping, `PluginViewModel` enable/run gate, and whether a synced
  plugin can be `isEnabled == true` on arrival. **Treat as High/Critical until disproven.**
  Standard: STRIDE-Elevation; CWE-829 (inclusion of untrusted functionality).
- [ ] **4.5 `permissionsJSON` tamper.** `Plugin.grantedPermissions` derives from a synced JSON
  string. Test: a tampered CloudKit record (or a malicious co-participant) sets
  `permissionsJSON` to all permissions on a plugin the user installed with none. Does
  `PluginBridge` honour the synced value without re-consent? CWE-565 (reliance on untrusted
  input).
- [ ] **4.6 Participant identity display.** `SharingPermissionStore.displayName` shows
  name/email from `CKUserIdentity`. Confirm no spoofable free-text field is rendered as identity
  and conflict-resolution UI attributes revisions correctly.
- [ ] **4.7 Share link handling.** Accepting a `CKShare.Metadata` via URL — confirm the app
  surfaces what library/permission is being joined and requires explicit user action
  (no silent auto-accept). MASVS-PLATFORM (deep link).

## WS5 — Plugin sandbox (MASVS-CODE / RESILIENCE)

- [ ] **5.1 Bridge surface enumeration.** Confirm the JS context exposes only `kontinuum.*`
  (7 functions + `invokedCommand`) and standard ECMAScript — no `JSContext` globals leaking
  host objects, no `ObjC`/`JSExport` bridged classes, no `setTimeout`/network/`XMLHttpRequest`,
  no `require`/module loader. Method: from a test plugin, reflect `Object.getOwnPropertyNames`
  on the global and every reachable object; assert the allow-list. Standard: MASVS-CODE-2;
  CWE-749 (exposed dangerous method).
- [ ] **5.2 Permission gate coverage.** Each of `listDocuments`, `searchDocuments`, `listTags`,
  `listNotebooks`, `appendToCurrentNote`, `insertAtCursor`, `addCommand` denies when its
  permission is absent (`PluginBridgeTests` partly covers — complete the matrix, incl. calling a
  denied API repeatedly and after a granted one).
- [ ] **5.3 Data minimisation.** `PluginLibrarySnapshot.capture` copies **full content of every
  note** into the snapshot regardless of which notes a plugin needs. Assess: should `readLibrary`
  expose titles/ids only until a per-note grant? Finding + recommendation. LINDDUN; MASVS-PLATFORM.
- [ ] **5.4 Resource exhaustion.** `PluginBridge` has a 2s wall-clock timeout but cannot
  interrupt JS (documented) → thread leak on `while(true)`. Test: (a) infinite loop, (b)
  unbounded allocation `while(true) a.push(x)` — does the abandoned thread OOM the app? (c) deep
  recursion. Evaluate `JSContextGroup` memory/stack limits (private API caveats noted in code).
  Standard: CWE-400; MASVS-RESILIENCE.
- [ ] **5.5 Output injection.** Text a plugin returns via `appendToCurrentNote` /
  `insertAtCursor` is written into the user's note verbatim. Test injection of `[[...]]`,
  `((...))`, `#tag`, task syntax, fenced blocks, and a `wikilink://`/`file://` payload — confirm
  it is treated as content, cannot forge a block anchor collision to hijack an existing
  reference (ties to WS-Anchors identity work), and cannot drive `OpenURLAction` to a dangerous
  scheme when later rendered. CWE-74.
- [ ] **5.6 Concurrency safety.** `PluginWriteCollector` / `PluginRunResultLatch` are
  `@unchecked Sendable` with manual locking. Review for races: double-resume of the
  continuation, collector read on `.timedOut` (must be ignored — verify), snapshot captured on
  `MainActor` then read off-thread. TSan run of `PluginBridgeTests`. Apple Secure Coding
  (race conditions).
- [ ] **5.7 Persistence of effect.** Confirm a plugin cannot establish persistence: no
  background execution, no scheduled re-run, `addCommand` names are re-collected each run and
  not executed automatically. Verify `invokedCommand` cannot be set by the script to self-invoke.

## WS6 — Untrusted input: import, migration, parsers (MASVS-CODE / SI)

- [ ] **6.1 Path traversal — import scan.** `ImportScanner.relativePath` / `AttachmentStorage`
  containment use `hasPrefix(rootPath)` (string prefix, not path-component) and
  `AttachmentStorage.sanitize` strips only `/ \ :` — **not `..`**. Test import/migration of a
  vault containing `../`, symlinks, absolute-path names, Unicode look-alike separators, and
  overlong names. Assert no write escapes the container. CWE-22; CWE-59 (symlink).
- [ ] **6.2 Decompression / archive.** `MigrationArchiveDAL` uses `FileManager.copyItem` on a
  folder (no zip extraction path today — confirm still true for `.canvas`/Obsidian). If any zip
  handling is added, test zip-slip, zip-bomb, nested archives. CWE-409.
- [ ] **6.3 Resource limits on file reads.** `String(contentsOf:)` in `ImportScanner` and
  importers reads whole files unbounded. Test a multi-GB `.md`, a file that is one 500MB line,
  and 100k tiny files — assert graceful limit/skip, not OOM/hang. CWE-400; NIST SI-10.
- [ ] **6.4 ReDoS across parsers.** `AdvancedSearchParser` has a reject heuristic (Phase 5).
  Fuzz `WikilinkParser`, `BlockReferenceParser`, `TagParser`, `TaskParser`, `AttachmentParser`,
  `PropertyParser`, `NotebookParser`, `EmbeddedSearchBlockParser`, `MigrationFormatDetector`
  with pathological inputs (nested brackets, unbalanced fences, huge repetition). Measure
  worst-case time. CWE-1333.
- [ ] **6.5 Parser fuzzing harness.** Stand up `swift-fuzz` / libFuzzer targets (or
  property-based tests with `SwiftCheck`) for every parser and `MarkdownG9.MDProcessor`.
  Corpus: real Obsidian/Logseq exports + mutated. Run in CI nightly. SSDF PW.8.
- [ ] **6.6 Malformed model input on restore/import.** Feed importers and `BackupDAL.restore`
  malformed/oversized/duplicate-id/cyclic-reference data; assert validation rejects with a
  user-facing error and no partial corrupt commit (transactional). CWE-20; CWE-502 (untrusted
  deserialization — Codable, so scope is logic bombs / resource abuse, not RCE).
- [ ] **6.7 Canvas/JSON import.** `.canvas` (JSON Canvas 1.0) — schema-validate before use;
  test hostile JSON (deep nesting, huge arrays, duplicate keys, `__proto__` keys). CWE-1321.
- [ ] **6.8 Content-driven deep links.** Round-trip: import a note containing
  `[[x]]`/`((y))`/`#z` and a raw `[markdown](javascript:...)` / `[x](file:///...)` link; render
  it; confirm `MDProcessor` neutralises non-allow-listed URL schemes and `OpenURLAction` refuses
  them. MASTG deep-link tests.

## WS7 — Attachments & external file handling (MASVS-PLATFORM)

- [ ] **7.1 Ingestion.** Security-scoped resource lifecycle in `AttachmentStorage.copyIntoContainer`
  (start/stop balanced — verify on error paths), filename sanitisation (see 6.1), collision
  handling, and that copied bytes get `.completeFileProtection` even when the source had none
  (code claims best-effort `try?` — test the failure branch).
- [ ] **7.2 Type handling / QuickLook.** `AttachmentPreview` renders arbitrary user files via
  QuickLook. Confirm previews run in the OS-provided out-of-process previewer (no in-app
  `WKWebView` rendering of untrusted HTML/SVG/PDF). Test a malformed PDF/image, an HTML file,
  an `.svg` with script, a file with a spoofed extension. CWE-434 context / CWE-79.
- [ ] **7.3 Storage location.** Attachments live outside the container `Documents/` folder
  (not Files.app-visible) — confirm, and confirm they are not inadvertently included in iTunes/
  Finder file sharing or unencrypted device backups (`.isExcludedFromBackup` where appropriate,
  or rely on Data Protection). Apple: Backup & data protection.
- [ ] **7.4 Sync of attachment bytes.** Bytes go to the ubiquity container, not CloudKit
  records. Verify transfer is Apple-encrypted in transit and that a shared-library participant
  only receives attachments for libraries they are in.

## WS8 — Backup / restore integrity (MASVS-STORAGE / SI)

- [ ] **8.1 Snapshot confidentiality.** `Backups/*.json` contain full library content in
  plaintext JSON at `.completeFileProtection` (iOS) — acceptable on iOS, gap on macOS (WS2.3).
  Decide whether backups warrant `CryptoKit` encryption with a Keychain-held key on all
  platforms. Finding + decision record.
- [ ] **8.2 Restore validation.** Restoring a hand-edited/hostile snapshot: assert schema
  validation, id sanity, size caps, and that restore is all-or-nothing. Confirm restore cannot
  be pointed at an arbitrary file path (only app-managed `Backups/`).
- [ ] **8.3 Snapshot never syncs.** Confirm `BackupSnapshot` is not a `@Model` and never enters
  `ModelContext` / CloudKit (ARCHITECTURE.md states this — add a test that would fail if a
  future change made it syncable).
- [ ] **8.4 Detached-copy guarantee.** `BackupDAL.createSnapshot` encodes-then-decodes to
  detach from live objects — test that a post-snapshot soft-delete does not mutate the snapshot.

## WS9 — Platform hardening, entitlements, signing (MASVS-RESILIENCE / CM)

- [ ] **9.1 macOS App Sandbox.** `Kontinuum-macOS.entitlements` has **no
  `com.apple.security.app-sandbox`**. Required for Mac App Store and strongly recommended
  otherwise. Add sandbox + minimal entitlements (`files.user-selected.read-write` for import/
  attachments, iCloud, network client for CloudKit) and retest all file flows. **Finding: High.**
  Standard: Apple App Sandbox; CIS macOS.
- [ ] **9.2 Hardened Runtime + notarisation (macOS).** Verify Hardened Runtime is enabled,
  no `com.apple.security.cs.allow-unsigned-executable-memory` / `disable-library-validation` /
  `allow-jit` unless justified (note: JavaScriptCore may need `allow-jit` — confirm and scope
  it tightly). Confirm release builds notarise clean. Apple: Hardened Runtime.
- [ ] **9.3 Entitlement minimisation (all platforms).** Diff requested vs used entitlements.
  `aps-environment` is `development` in both entitlement files — confirm the release pipeline
  flips to `production`. No `get-task-allow` in release. No debug entitlements shipped.
- [ ] **9.4 `Info.plist` review.** iOS `Info.plist` declares only `UIBackgroundModes:
  remote-notification`. Confirm: no custom `CFBundleURLTypes` unless a share/deep-link handler
  is intended (the `wikilink://` etc. are in-process `AttributedString` links, not registered
  schemes — verify none is registered); no `NSAllowsArbitraryLoads`; appropriate
  `LSApplicationQueriesSchemes` (should be empty). Add `ITSAppUsesNonExemptEncryption` = false
  (or correct value) to avoid export-compliance prompts.
- [ ] **9.5 Anti-tamper / jailbreak posture.** Decide the RESILIENCE stance for a notes app
  (likely: no aggressive jailbreak detection, but document the decision per MASVS-RESILIENCE-1).
  Confirm no sensitive logic depends on client-side checks an attacker controls.
- [ ] **9.6 Binary protections.** Confirm PIE, stack canaries, ARC, and that Swift/Clang
  hardening flags are on; strip symbols in release; no `#if DEBUG` secrets compiled into release.
- [ ] **9.7 Third-party target audit.** `MarkdownG9` / `SwiftRPT` build settings inherit the
  same hardening; neither adds entitlements, ATS exceptions, or network calls.

## WS10 — Privacy & telemetry (Apple privacy program)

- [ ] **10.1 Privacy manifest.** No `PrivacyInfo.xcprivacy` in the project. Required by Apple.
  Author one: declare data types collected (none leave the device except via user-initiated
  iCloud sync — assess whether that counts), required-reason API usage (`NSFileManager`
  timestamp/space APIs, `UserDefaults` if used), and tracking = false. **Finding: Medium
  (submission blocker).** Standard: Apple Privacy Manifests.
- [ ] **10.2 Required-reason APIs.** Audit for APIs on Apple's required-reason list
  (`fileTimestamp`, `systemBootTime`, `diskSpace`, `activeKeyboards`, `UserDefaults`) and record
  the approved reason code for each actually used.
- [ ] **10.3 Logging hygiene.** Audit every `OSLog.Logger` call site: note content, titles,
  attachment names, participant emails, share URLs, plugin scripts must be `%{private}` (or
  omitted), never `%{public}`. Test with `log stream` on a device that private redaction holds
  in release. CWE-532.
- [ ] **10.4 No third-party analytics/crash/ads SDKs.** Confirm by dependency graph + binary
  string scan. If a crash reporter is added later, it re-enters this plan.
- [ ] **10.5 Diagnostics/export.** Any "export logs"/"contact support" path must scrub content
  and PII before sharing.

## WS11 — Authentication & local access control (MASVS-AUTH)

- [ ] **11.1 App-level lock.** There is no passcode/Face ID lock on the app itself; at-rest
  security relies wholly on the device passcode via Data Protection. Decide whether an optional
  `LocalAuthentication` (Face ID/Touch ID) app lock is in scope for a knowledge app holding
  Confidential notes. Document decision; if yes, spec it (with secure fallback, no bypass on
  backgrounding). Standard: MASVS-AUTH-1; Apple LocalAuthentication.
- [ ] **11.2 iCloud account dependency.** App identity == signed-in iCloud account. Test
  behaviour on account switch, sign-out, and "iCloud unavailable": no data from account A must
  be readable/writable under account B on the same device; `AttachmentStorage` already surfaces
  `iCloudUnavailable` — verify no unprotected fallback path (code claims none — test it).
- [ ] **11.3 Attribution.** `createdBy`/`updatedBy` are unpopulated (MVP single-user). For
  shared libraries this is a repudiation gap — confirm V1 multi-user populates them from the
  `CKShare` participant and that a participant cannot forge another's attribution.

## WS12 — Cryptography review (MASVS-CRYPTO)

- [ ] **12.1 Confirm "no custom crypto".** ARCHITECTURE.md asserts platform-native only. Verify
  by symbol scan: no bespoke XOR/AES/base64-as-encryption, no `CommonCrypto` misuse, no
  hardcoded keys/IVs, no `Math.random`-grade RNG for anything security-relevant (`UUID()` for
  ids is fine; flag any use as a secret/token). CWE-327/330.
- [ ] **12.2 Keychain (if introduced).** If WS2.3/WS8.1/WS11.1 add encryption, review:
  `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (or stricter), no `...Always`, access-control
  flags, no key in `UserDefaults`/file, key not synced. Apple Keychain Services.
- [ ] **12.3 Transport crypto** — covered in WS3 (delegated to CloudKit/ATS).

## WS13 — Dependency & supply chain (SSDF PS/PW)

- [ ] **13.1 Inventory / SBOM.** Generate an SBOM (CycloneDX) for the app + `MarkdownG9` +
  `SwiftRPT` + any SPM transitive deps. Record versions, licences (CLAUDE.md requires
  unencumbered — verify), source URLs, pinned revisions.
- [ ] **13.2 Vulnerability scan.** Run `osv-scanner` / GitHub Dependabot over `Package.resolved`.
  Triage any advisories.
- [ ] **13.3 Local package integrity.** `../MarkdownG9` / `../SwiftRPT` are path deps — confirm
  they are version-controlled, reviewed, and pinned for release builds (not a floating local
  checkout). Establish an update review process.
- [ ] **13.4 Build-tool trust.** CI image, Xcode version, and any Homebrew/SPM plugins pinned
  and sourced from trusted origins. SSDF PW.3.

## WS14 — Secure build, CI & release pipeline (NIST SSDF)

- [ ] **14.1 Security gates in CI.** Add to the pipeline (alongside `KontinuumCIGate.xctestplan`):
  static analyzer, SwiftLint security rules, `gitleaks`, `osv-scanner`, the parser-fuzz
  nightly. Fail the build on new High/Critical. SSDF PW.7/PW.8/RV.1.
- [ ] **14.2 Reproducible, signed builds.** Release built only by CI from a tagged commit;
  signing identities in a sece enclave/keychain not on disk; provenance recorded (SLSA-style
  attestation aspiration). SSDF PS.2/PS.3.
- [ ] **14.3 Test-plan coverage.** Ensure this plan's automated items are in a dedicated
  `KontinuumSecurity.xctestplan` run on every PR; manual items tracked as release-checklist
  gates.
- [ ] **14.4 Vulnerability disclosure & response.** Publish a `SECURITY.md` (contact, scope,
  SLA). Define severity → fix-SLA (Critical 7d, High 30d…) and a regression test requirement for
  every fixed finding (matches `CLAUDE.md` §8 TDD). SSDF RV.1/RV.2/RV.3.
- [ ] **14.5 Data-deletion path.** Given the app's no-physical-delete rule, define and test a
  genuine "delete my data" flow (local store + CloudKit zone + ubiquity container + backups) for
  privacy-law compliance. NIST 800-53 SI-12 / privacy.

## WS15 — Dynamic testing & penetration pass

- [ ] **15.1 Instrumented device test.** Jailbroken/again device or Xcode-instrumented: inspect
  the app container while locked/unlocked, dump `UserDefaults`/plists/caches, inspect the
  SwiftData store, attempt to read `Backups/`/`SyncState/`/`AttachmentStore/`. MASTG methodology.
- [ ] **15.2 Network interception.** mitmproxy with a trusted root: confirm CloudKit traffic
  cannot be MITM'd by the app's own (mis)configuration; confirm nothing else talks to the
  network.
- [ ] **15.3 Two-account sharing pentest.** Full adversarial run of WS4 with two real iCloud
  accounts: read-only write attempts, `Plugin` injection, `permissionsJSON` tamper (via
  CloudKit Dashboard record edit), cross-zone fetch attempts, stopped-share access-revocation
  timing.
- [ ] **15.4 Malicious-import corpus.** Run the WS6 hostile corpus end-to-end through the real
  import/migration UI on device.
- [ ] **15.5 Malicious-plugin corpus.** A suite of hostile plugin scripts (sandbox-escape
  probes, resource bombs, output-injection, reflection) run through `PluginManagementView`.
- [ ] **15.6 Retest.** Re-run every failed check after fixes; attach before/after evidence to
  each finding.

## Deliverables

- [ ] `Docs/Security/threat-model.md` — assets, DFDs, STRIDE/LINDDUN registers (WS0).
- [ ] `Docs/Security/findings/NNNN-slug.md` per finding — description, CVSS v3.1 vector + score,
  affected code (`file:line`), reproduction, evidence, recommended fix, MASVS/CWE refs, status.
- [ ] `KontinuumSecurity.xctestplan` — automated regression suite for every codified check.
- [ ] `SECURITY.md` (repo root) + `PrivacyInfo.xcprivacy` (app target).
- [ ] Assessment report: executive summary, methodology, standards-coverage matrix
  (MASVS control → result), findings table, residual-risk acceptance sign-off.
- [ ] Release go/no-go checklist derived from the manual-only items.

## Exit criteria (release sign-off)

1. Zero open Critical or High findings; Mediums have an owner and a dated remediation plan.
2. Every MASVS 2.1 control in scope marked Pass / Not-Applicable (with rationale) / accepted-risk
   (with written owner sign-off).
3. `PrivacyInfo.xcprivacy` present and accurate; App Store export-compliance keys set.
4. macOS build sandboxed + hardened + notarised (WS9.1–9.2) or a documented, signed risk
   acceptance for not shipping to the Mac App Store.
5. Every fixed finding has a regression test in `KontinuumSecurity.xctestplan`.
6. Threat model reviewed and signed off; residual-risk register accepted by the app owner.

## Assumptions

- Apple platform crypto (Data Protection keybag, Secure Enclave, CloudKit zone encryption,
  APNs transport) is trustworthy and correctly implemented — not re-tested here.
- The end user vets a plugin's source before enabling it; the app's job is to bound what an
  enabled plugin can do, not to prove a script benign.
- Test devices have a passcode set (Data Protection is inert without one) — stated as a
  deployment requirement, not something the app can enforce.
- CloudKit share-permission enforcement is ultimately server-side; WS4 tests both the client
  posture and the server backstop.

## Out of scope (explicit)

- Attacks on Apple-operated infrastructure (CloudKit servers, iCloud auth, APNs).
- Formal verification / cryptanalysis of platform primitives.
- Hardware/side-channel attacks on the Secure Enclave.
- Denial-of-service against Apple's sync backend.
- Non-security functional bugs (tracked in the normal backlog unless they have a security
  consequence).
