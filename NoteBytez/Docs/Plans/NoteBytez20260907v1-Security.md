<!-- NoteBytez20260907v1-Security.md -->
<!--
    Identify the payment and security restrictions for the application and explore how to enforce.

    Scope note: this doc owns App Store *provenance + subscription entitlement* enforcement only.
    The whole-app security audit lives in NoteBytez20260627v2-Security.md (see its WS9.5 for the
    RESILIENCE stance this plan inherits). Decisions captured in the Resolutions section below.
-->

# User Story
As the product owner of the NoteBytez application, I want to ensure that users of the application are only able to use the application if procured from a valid app store - Apples App Store for iOS/iPadOS applications and the Apple App Store for MacOS applications.

# Success Factors

> Success Factors 3 and 4 as originally written assumed a one-time paid app. The product is an
> auto-renewable **subscription** — the wording below is amended accordingly and the reasoning is
> in *Gaps / Open Questions / Resolutions* (G2–G4, G13–G14). "Procured from a valid app store" is
> now read as: the install is App Store / TestFlight provenanced **and** the Apple Account has an
> active subscription entitlement (trial, paid, family-shared, or Apple billing-grace all count).

1. The user will be able to locate the NoteBytez app on the appropriate Apple App Store for their device.
2. The user will be able to download the app for free and start an introductory free trial, then subscribe (Monthly or Annual), from the appropriate Apple App Store for their device.
3. Once a subscription (or trial) is active on the Apple Account, the user will be able to use NoteBytez across all of their devices signed into that Apple Account.
    - There is one App Store shared by iPhone and iPad; there is no separate iPadOS App Store. A single app record with Universal Purchase covers iPhone, iPad, and Mac.
    - The subscription entitlement is per Apple Account, not per device or per platform. Subscribing on any one device (iPhone, iPad, or Mac) unlocks all of them; StoreKit propagates the entitlement automatically.
4. One subscription entitles every device signed into the purchasing Apple Account, **and** — because Family Sharing is enabled on the subscription — every member of that Apple Family, each using their own Apple Account. Enforcement accepts `Transaction.ownershipType == .familyShared`.
5. When installed via TestFlight (or run from Xcode), the build is inherently store-provenanced; the subscription requirement is waived and the tester has full access on every device signed into the TestFlight/developer Apple Account. TestFlight's own 90-day build expiry still applies.

# Gaps / Open Questions / Resolutions

The Success Factors describe only the legitimate purchase and cross-device happy path. The User
Story asks for **enforcement**. Every gap below is a thing the Success Factors left unspecified
that the implementation needs a decision on. All are now resolved.

| ID | Gap / Open question | Resolution | Rationale |
|---|---|---|---|
| **G1** | No Success Factor defines what the app does when it is **not** legitimately procured (sideloaded, patched binary, no subscription, revoked). | A launch-time and foreground **entitlement gate** with three access levels — `full`, `warning`, `blocked`. Provenance failure → immediate `blocked` (no grace). Loss of subscription → `warning` for 3 days, then `blocked`. | The User Story is an enforcement requirement; it needs an explicit negative path, not just a happy path. |
| **G2** | Business model was undefined ("purchase", "one payment"). | **Auto-renewable subscription.** Monthly + Annual products in one subscription group, with a StoreKit introductory **free trial**. | Product-owner decision. Drives the entire check: entitlement = active subscription, not a persistent receipt. |
| **G3** | SF4's "one payment … Apple Account used to purchase" contradicts a subscription and excludes Family Sharing. | SF4 amended: entitlement is an active subscription on the Apple Account; **Family Sharing is enabled**; enforcement accepts `Transaction.ownershipType == .familyShared`. | Product-owner decision (allow family members). |
| **G4** | SF3 hedged on "if the iPadOS has its own app store". | Resolved as fact: **no separate iPadOS App Store.** One shared iPhone/iPad App Store; a single app record with **Universal Purchase** covers iPhone, iPad, and Mac; the subscription entitlement syncs across all three via the Apple Account. | Removes a false conditional; sets Universal Purchase as the cross-platform mechanism. |
| **G5** | Validation mechanism unspecified (on-device vs server, receipt vs StoreKit). | **On-device StoreKit 2 only.** `AppTransaction` proves App Store provenance of the install; `Transaction.currentEntitlements` proves an active subscription. No backend, no App Store Server API, no jailbreak heuristics. | Product-owner decision (rigor = "on-device StoreKit 2 only"). The app has no backend and adding one is out of proportion for a notes app. See G6 residual risk. |
| **G6** | Residual risk of the on-device-only choice. | **Accepted, documented, not mitigated.** A jailbroken or patched binary can bypass the gate. Matches v2 WS9.5 (no aggressive anti-tamper for a notes app). No sensitive server-side logic depends on the client check. | Explicit risk acceptance is the v2 plan's own standard for RESILIENCE items. |
| **G7** | macOS distribution channel. | **Mac App Store only.** No Developer ID / direct-download build exists. Any macOS copy whose `AppTransaction` fails verification in `.production` is invalid. | Product-owner decision. Keeps "valid app store" unambiguous on macOS. |
| **G8** | How TestFlight (SF5) interacts with the subscription requirement. | When `AppTransaction.environment` is `.sandbox` or `.xcode`, provenance passes **and the subscription requirement is waived** → `full` access. TestFlight cannot take real payment; testers should not need a sandbox subscription. | Lets SF5 hold without special-casing tester accounts. |
| **G9** | Failure-path UX was undefined. | **Grace period, then hard block**, with a permanent read-only export escape hatch (G12). States and screens specified in the Implementation Plan, Phase 4. | Product-owner decision (grace-then-block over immediate block or read-only mode). |
| **G10** | Offline behaviour for an already-verified subscriber. | **Cache the last successful verification** (Keychain). Within **7 days** of the last good check → full offline use. Past 7 days with no re-verification → enter the post-lapse grace, then block. | Product-owner decision (7-day offline cache). Supports travel/airplane use without indefinitely trusting a cancelled account. |
| **G11** | Re-lock behaviour on expiry / refund / revocation. | On `Transaction.currentEntitlements` no longer listing the product, or a non-nil `revocationDate`: record the lapse date, show `warning` for **3 days**, then `blocked`. | Product-owner decision (3-day post-lapse grace). |
| **G12** | Grace/offline durations. | **7-day** offline cache window; **3-day** post-lapse grace window. | Product-owner decision. |
| **G13** | Apple billing-retry / billing grace period. | **Enable "Billing Grace Period" in App Store Connect.** Users in billing retry are treated as fully entitled (StoreKit keeps them in `currentEntitlements` while in Apple's grace). No separate in-app warning. | Product-owner decision; Apple-recommended, reduces involuntary churn. |
| **G14** | Is there any usable experience without a subscription? | **Introductory free trial only** (one per subscription group, Apple-managed). No perpetual free tier. When the trial lapses without conversion, the G11 grace/block path applies. | Product-owner decision (trial, then gated). |
| **G15** | CloudKit share participants without a subscription. | **Every user needs their own subscription.** The gate is identical for owned and shared-in libraries. An unsubscribed participant who accepts a share still hits the block screen. | Product-owner decision. Keeps enforcement uniform; no per-content entitlement logic. |
| **G16** | What exactly is gated ("use")? | Everything except: (a) the paywall / subscribe / **Restore Purchases** UI, (b) **read-only browsing + export** of existing local libraries while blocked, (c) Settings → subscription management + support/legal links. `SyncEngine` is suspended while blocked. | Needed so "blocked" is precise and App-Review-safe (users can always reach their data). |
| **G17** | Data safety when blocked. | Local SwiftData store and attachment files are **left intact and encrypted at rest**; nothing is deleted. Resubscribing restores full function with no data loss. While blocked, `SyncEngine` is suspended — no pushes, pulls queued without destructive apply. | Product-owner decision (always allow read-only export); protects against data loss from a lapsed payment. |
| **G18** | Where the check runs in the app lifecycle. | An `EntitlementGate` evaluated at launch (in `RootView`), on `scenePhase == .active`, on every `Transaction.updates` event, and on a 6-hour foreground timer. `RootView` renders app UI vs. warning banner vs. block/paywall from the resulting `AccessLevel`. | Implementation detail, fixed here so the plan is buildable. |
| **G19** | Telemetry on validation failures. | **Local `OSLog` only**, privacy-redacted (`%{private}` for dates/ids). No phone-home. | Consistent with the app's no-analytics posture (v2 WS10.4). |
| **G20** | Cached-entitlement storage & tamper. | Stored in the **Keychain**, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, not synced: last-verified timestamp, entitlement expiry, product id, environment. No signed payload (on-device threat model accepts local tamper — G6). | Avoids `UserDefaults`/plist for a security-relevant value (v2 WS2.4). |
| **G21** | "Restore Purchases" is an App Review requirement (Guideline 3.1.1 / 3.1.2). | Explicit **Restore Purchases** button on the paywall **and** in Settings, calling `AppStore.sync()`. Plus "Manage Subscription" (`showManageSubscriptions`) and "Redeem Code". | Required for approval; also the recovery path for a new device or reinstall. |
| **G22** | Minimum OS / StoreKit availability. | Deployment target is iOS/macOS **26.5**; StoreKit 2 `AppTransaction` (iOS 16+/macOS 13+) is fully available. No legacy `SKReceiptRefreshRequest` / `exit(173)` fallback needed. | Removes a whole class of macOS receipt-refresh complexity. |
| **G23** | Universal Purchase / single app record. | One app record; identical bundle id `com.g9Consulting.Kontinuum` is already shared by the iOS and macOS targets. Confirm **Universal Purchase** is enabled on the app record and both platforms are attached to it. | Precondition for SF3/SF4 cross-platform entitlement. |
| **G24** | Export-compliance key. | Unchanged. StoreKit uses only Apple TLS; keep `ITSAppUsesNonExemptEncryption` as set in v2 WS9.4. | No new crypto is introduced. |

**Deferred to the product owner (do not block the build):** exact trial length (placeholder 7 days),
prices, localized store copy, final product IDs if different from the placeholders in Phase 0, and
the Terms of Use (EULA) + Privacy Policy URLs the paywall must link.

# Implementation Plan

MVVM per `Kontinuum/CLAUDE.md`: models in `models/`, data-access in `dal/`, view models in
`viewModels/`, views in `views/Entitlement/`. Every new `.swift` file carries the copyright
header. `OSLog.Logger` for events. TDD — write the failing test first; 100% coverage on new
types. Phases are dependency-ordered: 0 → 1 → 2 → 3 → (4, 5, 6 in parallel) → 7 → 8.

## Phase 0 — App Store Connect & StoreKit configuration (no app code)

1. Confirm the single app record has **Universal Purchase** enabled and both iOS and macOS builds attached (G23).
2. Create subscription group **`NoteBytez`**. Add two auto-renewable products:
   - `com.g9Consulting.Kontinuum.sub.monthly`
   - `com.g9Consulting.Kontinuum.sub.annual` (priced at a discount vs. 12× monthly)
3. Add one **Introductory Offer** (free trial, 7-day placeholder) at group level.
4. **Enable Family Sharing** on the subscription group (G3).
5. **Enable Billing Grace Period** for the group (G13).
6. Add `Kontinuum.storekit` StoreKit configuration file to the repo; attach it to the Debug scheme and to a new `KontinuumStoreKit.xctestplan` for `StoreKitTest`.
7. **Verify:** a unit test loads both `Product`s from the config file and asserts ids, type, and group.

## Phase 1 — Entitlement domain model + cache DAL

- `models/Entitlement.swift` — value types, never a `@Model`, never synced:
  - `EntitlementEnvironment { production, sandbox, xcode }`
  - `SubscriptionSnapshot { productId: String, expiration: Date?, isFamilyShared: Bool, isInAppleGracePeriod: Bool, revocationDate: Date? }`
  - `AccessLevel { case full; case warning(daysRemaining: Int); case blocked(reason: BlockReason) }`
  - `BlockReason { provenanceFailed, neverSubscribed, subscriptionLapsed, offlineTooLong }`
- `dal/EntitlementCache.swift` — protocol `EntitlementCaching` + Keychain implementation (G20). Stores `lastVerified: Date`, `expiration: Date?`, `productId: String`, `environment`. Accessibility `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, not synced. Reads that fail decode → treated as "no cache".
- **Tests** `EntitlementCacheTests`: round-trip, missing item, corrupt item → nil, overwrite, delete. 100%.

## Phase 2 — StoreKit verification service

- `dal/StoreKitEntitlementProvider.swift` — protocol `EntitlementProviding`:
  - `func verifyProvenance() async -> EntitlementEnvironment?` — `AppTransaction.shared`; `nil` when unverified or (in `.production`) the check throws. `.sandbox` / `.xcode` returned as-is.
  - `func currentSubscription() async -> SubscriptionSnapshot?` — iterate `Transaction.currentEntitlements`, keep verified transactions in the `NoteBytez` group, pick the unexpired one with the latest `expirationDate`; capture `ownershipType` (accept `.purchased` **and** `.familyShared`), `revocationDate`, and cross-reference `Product.SubscriptionInfo.Status` for `.inGracePeriod` / `.inBillingRetryPeriod`.
  - `var transactionUpdates: AsyncStream<Void>` — wraps `Transaction.updates`, calls `finish()` on each, emits a tick.
- **Tests** `StoreKitEntitlementProviderTests` with `SKTestSession`: active monthly, active annual, expired, in trial, family-shared, revoked (`revocationDate` set), none, `.sandbox` environment. Each branch a named test.

## Phase 3 — EntitlementGateViewModel (the state machine)

- `viewModels/EntitlementGateViewModel.swift` — `@MainActor @Observable`:
  - Init deps: `EntitlementProviding`, `EntitlementCaching`, `now: () -> Date` (injectable clock), a `SyncEngineControlling` handle (Phase 5).
  - `private(set) var accessLevel: AccessLevel`
  - `func evaluate() async` implements, in order:
    1. `verifyProvenance()` is `nil` → `.blocked(.provenanceFailed)`. Return.
    2. environment `.sandbox` or `.xcode` → `.full`. Return.
    3. `currentSubscription()` non-nil and (`expiration == nil` or `expiration > now` or `isInAppleGracePeriod`) and `revocationDate == nil` → `.full`; write cache (`lastVerified = now`, `expiration`, `productId`, env). Return.
    4. Cache exists and `now - cache.lastVerified <= 7 days` → `.full` (offline window). Return.
    5. Compute `lapseDate = max(subscription.expiration ?? .distantPast, cache.expiration ?? cache.lastVerified)`. If `now - lapseDate <= 3 days` → `.warning(daysRemaining: ceil(3d - elapsed))`. Else → `.blocked(.subscriptionLapsed)` — or `.blocked(.offlineTooLong)` when there is a cache but no live subscription and step 4 failed purely on age.
    6. No subscription ever and no cache → `.blocked(.neverSubscribed)` (renders the paywall, not the "get your data out" screen).
  - Transition side effect: entering `.blocked` → `syncEngine.suspend()`; leaving `.blocked` → `syncEngine.resume()`.
  - `func startObserving()` — call `evaluate()` now, on each `transactionUpdates` tick, and (owner: the view) on `scenePhase == .active` and a 6-hour `Timer`.
- **Tests** `EntitlementGateViewModelTests` — table-driven with fake provider + injected clock. One named test per state-table row, plus boundaries: exactly 7d / 7d+1s offline, exactly 3d / 3d+1s post-lapse, family-shared → full, Apple grace → full, revoked → blocked, sandbox → full, provenance nil → blocked. Assert `suspend()`/`resume()` fire on the right transitions. 100%.

## Phase 4 — Views

- `views/Entitlement/EntitlementGateContainer.swift` — generic wrapper `EntitlementGateContainer<Content: View>`; switches on `accessLevel`:
  - `.full` → `content`.
  - `.warning(daysRemaining:)` → `content` + a non-dismissable top banner ("Subscription lapsed — N days of access left") with a **Resubscribe** button.
  - `.blocked(.neverSubscribed)` → `PaywallView` (primary), with Restore + Export still reachable.
  - `.blocked(other)` → `BlockedView`.
- `views/Entitlement/PaywallView.swift` — loads Monthly + Annual `Product`s, trial-eligibility badge, `product.purchase()` → on `.success(verification)` verify, `transaction.finish()`, `await viewModel.evaluate()`. **Restore Purchases** (`AppStore.sync()`), Terms & Privacy links. Styled per `Docs/styleGuide.md`.
- `views/Entitlement/BlockedView.swift` — explains the state (lapsed / offline-too-long / provenance), and offers: **Resubscribe** (→ paywall), **Restore Purchases**, **Manage Subscription** (`showManageSubscriptions` / `AppStore.showManageSubscriptions(in:)`), and **Export my notes** → read-only export of every local `Library` via existing `ExportDAL` (`NSSavePanel` on macOS, share sheet on iOS).
- `RootView.swift` — wrap existing content: `EntitlementGateContainer(viewModel: gate) { <existing RootView body> }`; hold `gate` as `@State`; drive `evaluate()` from `.onChange(of: scenePhase)` and a timer.
- **DEBUG seam** (mirrors `-SeedTestConflict` in `KontinuumApp.swift`): launch arg `-SimulateEntitlement full|warning|trial|lapsed|provenanceFailed` injects a fake provider so UI tests and manual QA can drive every screen without StoreKit.
- **Tests**: `EntitlementGateUITests` (iOS + macOS) — one test per simulated state; assert the block screen shows Export + Restore, warning shows the banner over a usable app, full shows the app. Snapshot/ViewInspector tests for each subview's copy across `BlockReason`s.

## Phase 5 — SyncEngine suspension

- `sync/SyncEngine.swift` — add `protocol SyncEngineControlling { func suspend(); func resume() }` and conform:
  - `suspend()` — stop scheduling syncs, stop pushing local changes; incoming pushes/pulls are held (queued) and **not** applied destructively.
  - `resume()` — idempotent; flush the queue, resume normal scheduling.
  - `start(modelContainer:)` callers: a launch that resolves to `.blocked` starts the engine **suspended**.
- **Tests** `SyncEngineSuspensionTests`: suspend → no outbound record ops, no data mutated; resume → queue flushes once; double-suspend / double-resume are no-ops; blocked launch → engine suspended and `SyncStatusStore` shows idle.

## Phase 6 — Settings integration

- Add a **Subscription** section to the existing Settings surface: current plan + renewal/expiry date (from `EntitlementGateViewModel`), **Manage Subscription**, **Restore Purchases**, **Redeem Code** (`presentCodeRedemptionSheet` / `AppStore.presentOfferCodeRedeemSheet`).
- No new verification path — reuses the gate view model.
- **Tests**: settings VM test for the displayed strings across `full` / `warning` / `blocked` / trial.

## Phase 7 — Logging, privacy, docs

- `OSLog.Logger` category `entitlement`: log every `AccessLevel` transition; dates/product ids as `%{private}`; never log transaction JWS.
- `PrivacyInfo.xcprivacy` (created in v2 WS10.1): add StoreKit required-reason declarations if the audit finds any; `NSPrivacyTracking` stays `false`; no collected-data types added.
- Cross-link: add a one-line pointer in `NoteBytez20260627v2-Security.md` that entitlement enforcement is owned by this doc.
- `Docs/styleGuide.md`: add the lapsed-subscription banner component spec only if it is a new pattern.

## Phase 8 — Verification matrix & release gate

| State | iPhone | iPad | Mac (MAS) | TestFlight | Xcode |
|---|---|---|---|---|---|
| Active subscription | full | full | full | full | full |
| Trial active | full | full | full | full | full |
| Trial lapsed, no convert | warning→blocked | ″ | ″ | full (waived) | full |
| Subscription expired | warning 3d → blocked | ″ | ″ | full | full |
| Apple billing-retry | full | full | full | full | full |
| Family member (2nd Apple ID) | full | full | full | n/a | n/a |
| Offline 6 days (was verified) | full | full | full | full | full |
| Offline 8 days (was verified) | blocked | blocked | blocked | full | full |
| Refunded / revoked | warning 3d → blocked | ″ | ″ | full | full |
| Patched / sideloaded binary | blocked (no grace) | ″ | ″ | n/a | n/a |

- Automated: every row that a fake provider can express is an `EntitlementGateViewModelTests` case; the screens are `EntitlementGateUITests` cases.
- Manual (two sandbox Apple Accounts, Family set up): buy monthly → confirm full on all devices; cancel → warning after expiry → blocked +3d; 2nd family Apple ID → full; set device clock +8 days offline → blocked; TestFlight build with no subscription → full; confirm **Export my notes** works from every blocked screen.
- **Exit criteria:** all state-table unit/UI tests green on iOS + macOS; manual matrix signed off by the app owner; paywall self-reviewed against App Review Guideline 3.1.1 / 3.1.2 (plan, price, trial terms, Restore, Terms & Privacy links all present).

# Implementation Results

Status as built. Verified with Xcode 26.6 (iOS/macOS 26.5 SDK) on 2026-09-07.

## Summary

| | |
|---|---|
| **iOS build** | ✅ `BUILD SUCCEEDED` |
| **macOS build** | ✅ `BUILD SUCCEEDED` |
| **Unit tests** | ✅ **782 pass** (baseline 776 + ~45 new entitlement tests), 0 failures — via `KontinuumEntitlement.xctestplan` |
| **Gate UI tests** | ✅ `Phase6EntitlementGateTests` 5/5, stable across 3 consecutive runs |
| **Outstanding** | App Store Connect record setup (account work); real `SKTestSession` + two-account manual matrix (needs sandbox accounts / devices); product-owner inputs (trial length, prices, final product IDs, EULA/Privacy URLs) |

> Note: the wider `Phase1*/Phase2*/Phase5*` XCUITest suite shows ~27 failures **on this machine** — confirmed pre-existing by reproducing them with the entitlement changes reverted (this simulator launches tests in landscape with `TemplateOnboardingStore` unset, so tests that assume a direct-to-Today landing fail). Not caused by this work.

## Phase-by-phase

### Phase 0 — StoreKit configuration — ⚠️ partial (code done; ASC account work outstanding)

- [x] `Kontinuum/StoreKit/Kontinuum.storekit` — subscription group `NoteBytez`, products `com.g9Consulting.Kontinuum.sub.monthly` / `…annual`, `familyShareable = true`, 7-day free `introductoryOffer` on each.
- [x] `KontinuumEntitlement.xctestplan` created; runs the full `KontinuumTests` target + `Phase6EntitlementGateTests`, with `storeKitConfigurationFileReference` → the `.storekit` file.
- [x] Scheme (`Kontinuum.xcscheme`) — added the test-plan reference and a `StoreKitConfigurationFileReference`. *(Xcode may re-normalise the relative path on first open.)*
- [ ] App Store Connect: create the app record with **Universal Purchase**, the subscription group, the two products, the introductory offer, **enable Family Sharing**, **enable Billing Grace Period** — account/console work, not code.

### Phase 1 — Entitlement model + cache DAL — ✅ complete

- [x] `Kontinuum/models/Entitlement.swift` — `Entitlement.Products` (ids + `offlineCacheWindow` 7d / `postLapseGrace` 3d), `EntitlementEnvironment` (`.production/.sandbox/.xcode` + `isSubscriptionWaived`), `SubscriptionSnapshot` (with `isActive(asOf:)`), `BlockReason`, `AccessLevel` (`.full` / `.warning(daysRemaining:)` / `.blocked(reason:)`).
- [x] `Kontinuum/dal/EntitlementCache.swift` — `EntitlementCaching` protocol; `CachedEntitlement` (Codable); `KeychainEntitlementCache` (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, not synced, overridable `service` for test isolation, corrupt value → discard); `InMemoryEntitlementCache` (tests/previews).
- [x] Tests — `EntitlementModelTests` (17), `EntitlementCacheTests` (7: Codable round-trip, in-memory, Keychain round-trip / overwrite / clear).

### Phase 2 — StoreKit verification service — ✅ complete (test approach adjusted)

- [x] `Kontinuum/dal/StoreKitEntitlementProvider.swift` — `EntitlementProviding` protocol; `verifyProvenance()` via `AppTransaction.shared` (unverified/throws → `nil`); `currentSubscription()` iterates `Transaction.currentEntitlements`, filters to the group, `.autoRenewable` only, accepts `ownershipType ∈ {.purchased, .familyShared}`, reads `revocationDate`, cross-references `Product.SubscriptionInfo.Status.state == .inGracePeriod`; `transactionUpdates: AsyncStream<Void>` wrapping `Transaction.updates` (calls `finish()` per event).
- [x] `Kontinuum/EntitlementSimulation.swift` — DEBUG `SimulatedEntitlementProvider` (scenarios `full / warning / trial / lapsed / provenanceFailed / neverSubscribed`), parsed from `-SimulateEntitlement`.
- **Deviation:** the planned `SKTestSession`-based `StoreKitEntitlementProviderTests` are replaced by `SimulatedEntitlementProviderTests` (8, hermetic + deterministic) plus full behavioural coverage through the gate's fake provider. A live `SKTestSession` pass remains a Phase 8 manual/Xcode task. `transaction.subscriptionStatus` is non-optional / non-throwing on the 26.5 SDK — handled accordingly.

### Phase 3 — EntitlementGateViewModel state machine — ✅ complete

- [x] `Kontinuum/viewModels/EntitlementGateViewModel.swift` — `@MainActor @Observable`; deps `EntitlementProviding` / `EntitlementCaching` / `SyncEngineControlling` / injectable `now: () -> Date` / `offlineWindow` / `postLapseGrace`.
- [x] `evaluate()` — the ordered decision table exactly as specified (provenance → waived env → active sub + cache write → 7-day offline cache → 3-day grace `.warning` / `.blocked(.subscriptionLapsed|.offlineTooLong)` → `.blocked(.neverSubscribed)`). `effectiveEnd(of:)` clamps a revoked sub's anchor to its `revocationDate` (refund → 3-day grace → block).
- [x] `apply(_:)` — drives `syncEngine.suspend()/resume()` across blocked⇄unblocked; first evaluation forces the side-effect to match the resolved state (engine may already have started).
- [x] `startObserving()` — first `evaluate()` then re-evaluates on every `transactionUpdates` tick; the view adds `scenePhase == .active` and a 6-hour timer.
- [x] `provisionalAccessLevel(...)` + `hasEvaluated` — cache-only synchronous best-guess so a returning subscriber never flashes the paywall; `launchShouldSuspendSync()` for Phase 5.
- [x] Tests — `EntitlementGateViewModelTests` (22): every state-table row, boundaries (exactly 7d / 7d+1s offline, exactly 3d / 3d+1s grace), family-shared → full, Apple grace → full, revoke within/after grace, sandbox/xcode → full, provenance nil → blocked, and suspend/resume transition counting (with an advanceable `MutableClock`).
- **Deviation:** `deinit { observationTask?.cancel() }` dropped — `deinit` can't touch `@MainActor` state; the observation task is app-lifetime and self-terminates (the simulated provider's stream finishes immediately; the real one lives for the process).

### Phase 4 — Views — ✅ complete (two real UI bugs fixed in the process)

- [x] `views/Entitlement/EntitlementGateContainer.swift` — `ProgressView` until `hasEvaluated`, then `.full` → `content()`; `.warning` → `content()` + `LapsedBanner` via `.safeAreaInset(edge: .top)`; `.blocked(.neverSubscribed)` → `PaywallView`; other `.blocked` → `BlockedView`. Re-evaluates on `.task` / `scenePhase` / 6-hour timer.
- [x] `views/Entitlement/PaywallView.swift` — `ScrollView`+`VStack`; loads Monthly + Annual `Product`s, `purchase()` → verify → `finish()` → `onEntitled`; **Restore Purchases** (`AppStore.sync()`), Manage / Redeem, **Export My Notes**, Terms & Privacy links, auto-renew disclosure.
- [x] `views/Entitlement/BlockedView.swift` — per-`BlockReason` copy ("nothing has been deleted"); **Resubscribe** (paywall sheet), **Restore Purchases**, **Manage Subscription**, **Export My Notes** (`ExportDAL.exportAllActiveLibraries`); no Resubscribe for `provenanceFailed`.
- [x] `views/Entitlement/LapsedBanner.swift`, `views/Entitlement/SubscriptionActions.swift` (iOS `manageSubscriptionsSheet` / `offerCodeRedemption`; macOS → App Store account URLs).
- [x] `RootView.swift` — wrapped in `EntitlementGateContainer(viewModel: .makeDefault()) { … }`.
- [x] DEBUG seam — `-SimulateEntitlement <scenario>`; `EntitlementGateViewModel.makeDefault()` resolves DEBUG builds to `.full` unless the arg is present, so the existing UI suite is untouched.
- [x] Tests — `KontinuumUITests/Phase6EntitlementGateTests` (5): provenance-failed / lapsed / never-subscribed / warning-over-usable-app / full-no-gate-UI. *(ViewInspector snapshot tests not added — the 5 XCUITests cover the states end-to-end.)*
- **Bugs found & fixed while testing:** (1) action buttons inside a SwiftUI `List` don't expose `.accessibilityIdentifier` to XCUITest → paywall rebuilt as `ScrollView`+`VStack`; (2) the banner in a plain `VStack` occluded the S1 "Create" button in landscape → `.safeAreaInset`; (3) a container-level `.accessibilityIdentifier` on the banner shadowed the child button's id → removed.

### Phase 5 — SyncEngine suspension — ✅ complete

- [x] `sync/SyncEngine.swift` — `SyncEngineControlling` protocol; `suspend()` / `resume()` (idempotent, lock-guarded). While suspended: `recordChanged` returns before enqueue, `nextRecordZoneChangeBatch` returns `nil`, `handleRemoteNotification` / `syncNow` no-op, fetched batches buffer into `bufferedFetchedChanges` (no destructive apply). `resume()` replays the buffer then `syncNow()`.
- [x] `KontinuumApp.swift` — Release launch calls `EntitlementGateViewModel.launchShouldSuspendSync()` and `SyncEngine.shared.suspend()` before the gate's first async check.
- [x] Tests — added to `SyncEngineTests` (the existing `@Suite(.serialized)`, since they mutate the shared `SyncEngine.shared`): suspended `recordChanged` is suppressed before even the read-only check; `resume()` restores normal handling; suspend/resume idempotent.
- **Deviation:** tests live in `SyncEngineTests.swift`, not a separate `SyncEngineSuspensionTests` file — cross-suite serialization isn't guaranteed and these share singleton state with the attribution tests.

### Phase 6 — Settings integration — ✅ complete

- [x] `viewModels/SubscriptionSettingsViewModel.swift` — read-only status (`"Not verified"` / `"TestFlight / development build"` / `"No active subscription"` / `"Monthly|Annual subscription[ · shared … Family Sharing]"` + `"Renews|Expired <date>"`).
- [x] `views/Settings/SubscriptionSettingsView.swift` — status + **Change or Start Subscription** (paywall sheet), **Restore Purchases**, **Manage Subscription**, **Redeem Code**; linked from `SettingsView` as the first row.
- [x] Tests — `SubscriptionSettingsViewModelTests` (7) across the states.
- **Deviation:** a dedicated read-only VM instead of reusing `EntitlementGateViewModel` (which would drive sync suspend/resume as a side effect of a Settings screen).

### Phase 7 — Logging, privacy, docs — ✅ complete

- [x] `Logging.swift` — `LogCategory.entitlement`; the gate logs each `AccessLevel` transition with `%{public}` only on the case name, dates/ids kept private.
- [x] `Kontinuum/PrivacyInfo.xcprivacy` — **created** (did not exist from v2). `NSPrivacyTracking = false`, no collected data types, required-reason entries for `UserDefaults` (CA92.1) and `FileTimestamp` (C617.1). Full data-type audit still tracked in v2 WS10.1/10.2. StoreKit is not a required-reason API → no entries added for it.
- [x] `NoteBytez20260627v2-Security.md` — cross-link note added under Objective.
- [x] `Docs/styleGuide.md` — "Entitlement gate additions" component table (`LapsedBanner`, `PaywallView`, `BlockedView`, `SubscriptionActionButtons`).

### Phase 8 — Verification matrix & release gate — ⚠️ partial

- [x] **Automated state table** — every row expressible by the fake provider is an `EntitlementGateViewModelTests` case; the screens are `Phase6EntitlementGateTests` cases. All green (see Summary).
- [x] iOS + macOS **build** green; **782** unit tests green.
- [ ] **Live `SKTestSession`** run of `StoreKitEntitlementProvider` against `Kontinuum.storekit` — needs Xcode StoreKit testing.
- [ ] **Two-account manual matrix** (buy → all devices; cancel → warning → +3d block; family Apple ID → full; clock +8d offline → block; TestFlight no-sub → full; export from every blocked screen) — needs sandbox accounts + devices.
- [ ] **App Review self-check** of the finished paywall against Guideline 3.1.1 / 3.1.2.

## Files delivered

**New**
- `Kontinuum/StoreKit/Kontinuum.storekit`
- `Kontinuum/models/Entitlement.swift`
- `Kontinuum/dal/EntitlementCache.swift`, `Kontinuum/dal/StoreKitEntitlementProvider.swift`
- `Kontinuum/viewModels/EntitlementGateViewModel.swift`, `PaywallViewModel.swift`, `BlockedViewModel.swift`, `SubscriptionSettingsViewModel.swift`
- `Kontinuum/views/Entitlement/{EntitlementGateContainer,PaywallView,BlockedView,LapsedBanner,SubscriptionActions}.swift`
- `Kontinuum/views/Settings/SubscriptionSettingsView.swift`
- `Kontinuum/EntitlementSimulation.swift` (DEBUG)
- `Kontinuum/PrivacyInfo.xcprivacy`
- `KontinuumEntitlement.xctestplan`
- `KontinuumTests/{EntitlementModelTests,EntitlementCacheTests,EntitlementGateViewModelTests,SimulatedEntitlementProviderTests,SubscriptionSettingsViewModelTests}.swift`
- `KontinuumUITests/Phase6EntitlementGateTests.swift`

**Modified**
- `Kontinuum/RootView.swift` (gate wrap), `Kontinuum/KontinuumApp.swift` (suspend-at-launch), `Kontinuum/sync/SyncEngine.swift` (`SyncEngineControlling` + suspension), `Kontinuum/Logging.swift` (category), `Kontinuum/dal/ExportDAL.swift` (`exportAllActiveLibraries`), `Kontinuum/views/SettingsView.swift` (Subscription row)
- `KontinuumTests/SyncEngineTests.swift` (suspension tests)
- `Kontinuum.xcodeproj/xcshareddata/xcschemes/Kontinuum.xcscheme`
- `Kontinuum/Docs/Plans/NoteBytez20260627v2-Security.md`, `Kontinuum/Docs/styleGuide.md`

## Still needs a decision (product owner)

Exact trial length (placeholder 7 days), prices (placeholders $4.99 / $39.99), final product IDs, and the Terms of Use (EULA) + Privacy Policy URLs the paywall links (`PaywallView` currently points at `https://notebytez.app/terms` / `/privacy` with a `TODO(product-owner)`).
