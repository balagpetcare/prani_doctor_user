# Mobile Release Fix Plan — pranidoctor_user

**Date:** 2026-05-30  
**Goal:** Clear `flutter analyze` errors and produce a release APK without feature or business-logic changes.

## Analyze summary (baseline)

| Severity | Count | Release blocker |
|----------|------:|-----------------|
| error    | ~120  | Yes             |
| warning  | ~25   | No (non-blocking)|
| info     | ~115  | No              |

## Root-cause categories

### RC-1 — Localization codegen drift (P0)

**Symptoms:** `AppLocalizations` abstract base out of sync with generated impl; missing `consentWithdraw*` impl; missing `registerTerms*` on base; stale overrides in `app_localizations_impl.dart`.

**Cause:** `tool/i18n/build_localization.dart` reads `lib/l10n/app_localizations.dart` for base generation, but that file is now a re-export shim (no `_AppLocalizationsDelegate`). Base is not regenerated; impl/json/keys are.

**Fix:** Regenerate base directly from `app_en.arb` entries in the build script; run `dart run tool/i18n/build_localization.dart`.

### RC-2 — Missing i18n keys (P0)

**Symptoms:** `TranslationKeys.ecosystem*`, `phase4Feed*`, `analytics*`, `recommendation*` undefined; `consentWithdraw*` missing from JSON/ARB.

**Cause:** Phase 4 / ecosystem UI added keys in Dart only; never added to `lib/l10n/app_en.arb`.

**Fix:** Add English strings to `app_en.arb`; regenerate assets + Dart.

### RC-3 — TranslationKeys naming mismatch (P0)

**Symptoms:** Livestock feature uses `TranslationKeys.livestock*`; codegen exposes `animal*` (canonical keys in ARB).

**Cause:** Feature renamed in UI layer without updating key constants.

**Fix:** Map `livestock*` references to existing `animal*` / `farmEmpty` / `savedOffline` keys (no duplicate strings).

### RC-4 — Broken import path (P0)

**Symptoms:** `closed_beta_banner.dart` imports `../../../app_config/...` (wrong path).

**Fix:** Import `app_config_provider.dart` from the same directory.

### RC-5 — Missing provider import (P0)

**Symptoms:** `settingsProvider` undefined in `app_router.dart`, `auth_navigation.dart`.

**Fix:** Import `settings_providers.dart`.

## Fix order (dependency graph)

```
1. Document plan (this file)
2. Fix build_localization base writer (RC-1)
3. Add missing ARB keys (RC-2)
4. Rename livestock → animal TranslationKeys in feature code (RC-3)
5. Fix closed_beta_banner import (RC-4)
6. Fix settingsProvider imports (RC-5)
7. dart run tool/i18n/build_localization.dart
8. flutter analyze
9. flutter test
10. flutter build apk --release
11. Verification report
```

## Out of scope (non-blockers)

- Unused imports / deprecated Radio APIs / `use_build_context_synchronously` info lints
- Package version upgrades
- New features or business-logic changes

## Verification criteria

- [x] `flutter analyze` — zero errors
- [ ] `flutter test` — all pass (238/249; 11 pre-existing failures documented in verification report)
- [x] `flutter build apk --release` — succeeds (`app-release.apk`, 97.2 MB)
- [x] Verification report committed under `docs/releases/`
