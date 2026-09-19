<!-- NoteBytez/Docs/Localization/TechnicalNotes.md -->
<!--
  Platform/Foundation gotchas discovered while implementing localization, kept here so they
  aren't re-discovered (or re-broken) by whoever touches this code next. Not a design doc —
  see NoteBytez20260823v2-MultiLanguage.md for the actual plan and decisions.
-->
# Localization — Technical Notes

## `String(localized:locale:)` does not honor an explicit `locale:` for table selection

**Symptom:** calling `String(localized: String.LocalizationValue("Fiction Writing"), locale:
Locale(identifier: "es"))` returns `"Fiction Writing"` (the English source), not the Spanish
catalog value — even though `es.lproj/Localizable.strings` in the running bundle demonstrably
contains the correct translation (verified with `plutil -p` against the compiled `.app`).

**Root cause (empirical, not from documentation):** `String(localized:)`'s `locale:` parameter
does not change which `.lproj` table Foundation consults for the base string lookup — that
selection still follows the process's *actual* current locale (driven by `AppleLanguages` /
`Bundle.main.preferredLocalizations`), not the argument you pass. In practice this means
`locale:` only affects things layered on top of the resolved value (plural-category math,
`String.LocalizationValue` interpolation formatting) — never which language's string gets picked
in the first place. This is easy to miss because Apple's own documentation and most sample code
never resolve a *non-ambient* locale explicitly (they change the OS/simulator language and read
the process's own current locale instead).

**Fix:** go through `LocalizedStringResource`, which *does* respect an explicit locale override:

```swift
// Wrong — always resolves in the process's current locale, ignoring `locale:`:
String(localized: String.LocalizationValue(raw), locale: someOtherLocale)

// Right:
let resource = LocalizedStringResource(String.LocalizationValue(raw), locale: someOtherLocale)
String(localized: resource)
```

**Where this actually matters:** only when code needs to resolve a locale *other than* the
process's own current one — e.g. `TemplatePackDAL.localizedSeedString(_:locale:)`
(`NoteBytez/dal/TemplatePackDAL.swift`), which must be testable under an explicit `es`/`de`
locale without relaunching the process or wiring up a fake `Bundle`. Ordinary UI code
(`Text("...")`, plain `String(localized: "...")` with no `locale:` argument) is unaffected — it
already resolves correctly against whatever locale the process is actually running under, which
is the only thing G4a's Settings-driven language override changes anyway (via a restart, which
changes the *ambient* current locale, not an explicit per-call one). Do not "fix" ordinary UI
string sites to route through `LocalizedStringResource` — they don't have this problem to begin
with.

**How it was caught:** a diagnostic `@Test` asserted the actual returned string value against a
real compiled catalog under an explicit non-English `locale:` argument, rather than only checking
that the code compiled or that the *current-locale* (English) case returned the right value.
Every catalog-dependent test in this project before `TemplatePackDALTests`'s Phase 4 additions
(e.g. `PluralCatalogTests`) only ever exercised the ambient/default locale, so none of them could
have surfaced this — worth remembering when writing the next locale-sensitive test: assert
against a locale the process isn't actually running under, not just the happy path.

_Added: Phase 4 of [NoteBytez20260823v2-MultiLanguage.md](../Plans/NoteBytez20260823v2-%20HOLD%20-MultiLanguage.md)._
