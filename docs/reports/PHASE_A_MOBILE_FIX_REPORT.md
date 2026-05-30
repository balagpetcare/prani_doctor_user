# Phase A — Mobile Fix Report

**Project:** pranidoctor_user  
**Date:** 2026-05-30  
**Plan:** [PHASE_A_MOBILE_FIX_PLAN.md](../plans/PHASE_A_MOBILE_FIX_PLAN.md)

---

## Executive summary

| Gate | Target | Result |
|------|--------|--------|
| `flutter analyze` errors | 0 | **PASS (0 errors)** |
| `flutter test` | All pass | **PASS (249/249)** |
| `flutter build apk --release` | Success | **PASS (`app-release.apk`, 97.2 MB)** |

Phase A success criteria are met.

---

## Issues found

### P0 — Test infrastructure

| ID | Issue | Root cause |
|----|-------|------------|
| T-1 | Animal/home widget tests could not find English UI strings | `LocalizationLoader` not initialized in tests; `tr()` returned raw keys |
| T-2 | Tests flaky on Bengali host locale | `MaterialApp` omitted explicit `locale: en` |
| T-3 | Settings provider test returned `null` theme | `protectedApisEnabledProvider` false in bare `ProviderContainer` |

### P0 — Home dashboard layout

| ID | Issue | Root cause |
|----|-------|------------|
| L-1 | `HomeMetricCard` RenderFlex overflow on phone grids | Grid `childAspectRatio` too aggressive for icon + value + label |
| L-2 | `HomeQuickActionGrid` tile overflow | Fixed icon/text column taller than grid cell at 4-column phone layout |

### P1 — Golden baselines

| ID | Issue | Root cause |
|----|-------|------------|
| G-1 | drawer/home goldens ~4.5% pixel drift | UI layout + i18n loading changes since baseline capture |

### Already resolved (prior pass)

- Localization codegen drift (1300+ keys)
- Kotlin 2.x / `sentry_flutter` compile failure (Kotlin 1.8 subproject override)

---

## Files modified

### Production code

| File | Change |
|------|--------|
| `lib/features/home/presentation/widgets/summary_card.dart` | Taller grid cells (`childAspectRatio` 1.2); flex-safe metric card layout |
| `lib/features/home/presentation/widgets/quick_action_grid.dart` | Taller tiles (`childAspectRatio` 0.72); compact icon + `Expanded` label |

### Test infrastructure

| File | Change |
|------|--------|
| `test/flutter_test_config.dart` | **New** — preloads `LocalizationLoader` for all tests |
| `test/helpers/widget_test_harness.dart` | **New** — `testMaterialApp()` with pinned English locale + viewport |

### Tests updated

| File | Change |
|------|--------|
| `test/animals/add_animal_first_submit_test.dart` | `locale: testLocale` |
| `test/animals/add_animal_rapid_tap_test.dart` | `locale: testLocale` |
| `test/home/home_refresh_test.dart` | `testMaterialApp()` harness |
| `test/home/home_page_test.dart` | Harness + 390×1600 viewport; focused assertions |
| `test/settings/settings_integration_test.dart` | `protectedApisEnabledProvider` override |
| `test/golden/drawer_golden_test.dart` | Harness + en locale |
| `test/golden/home_golden_test.dart` | Harness + en locale |

### Golden assets (regenerated)

| File |
|------|
| `test/golden/goldens/drawer_light.png` |
| `test/golden/goldens/home_light.png` |
| `test/golden/goldens/home_dark.png` |
| `test/golden/goldens/home_tablet.png` |

### Documentation

| File |
|------|
| `docs/plans/PHASE_A_MOBILE_FIX_PLAN.md` |
| `docs/reports/PHASE_A_MOBILE_FIX_REPORT.md` |

---

## Fixes applied

1. **Global l10n test bootstrap** — `test/flutter_test_config.dart` calls `LocalizationLoader.ensureInitialized()` so widget tests resolve real strings from `assets/i18n/en.json`.
2. **English locale harness** — `test/helpers/widget_test_harness.dart` pins `Locale('en')` to eliminate OS-locale drift on Bengali developer machines.
3. **Settings provider test gate** — Override `protectedApisEnabledProvider → true` so `SettingsNotifier` reads cached settings as in authenticated sessions.
4. **Home grid overflow** — Adjusted aspect ratios and used `Expanded` for multi-line labels in quick-action tiles and metric cards (production-safe, no feature removal).
5. **Golden realignment** — Regenerated four baselines after layout/i18n fixes.

---

## Verification results

### flutter analyze

```
0 errors
111 issues (warnings + info)
```

Non-blocking categories: unused imports (AI widgets), deprecated Radio/FormField APIs, `constant_identifier_names` on generated `TranslationKeys`, style infos.

### flutter test

```
00:26 +249: All tests passed!
```

Previously failing (now green):

- `add_animal_first_submit_test` (×2)
- `add_animal_rapid_tap_test`
- `home_refresh_test` (×2)
- `home_page_test`
- `settings_integration_test`
- `drawer_golden_test`
- `home_golden_test` (×3)

### flutter build apk --release

```
√ Built build\app\outputs\flutter-apk\app-release.apk (97.2MB)
```

---

## Remaining warnings

- ~15 analyzer **warnings** (mostly unused imports in AI compliance widgets)
- ~96 analyzer **info** lints (deprecated Radio APIs, `use_build_context_synchronously`, style hints)
- 52 packages have newer major versions (deferred to Phase B dependency upgrade)

No analyzer **errors**. No test failures. No build blockers.

---

## Risk notes

| Risk | Mitigation |
|------|------------|
| Golden updates may hide unintended visual regressions | Diff reviewed via `test/golden/failures/` during regeneration; layout changes are intentional overflow fixes |
| Home grid aspect ratio changes affect all phone users | Cards gain ~15% vertical space — improves readability on narrow devices (target market) |
| Test locale pinned to English | Production still uses user locale; bn strings covered by i18n assets and existing integration tests |
| Kotlin 1.8 Gradle override for sentry | Track upstream `sentry_flutter` Kotlin 2.x compatibility |

---

## Sign-off checklist

- [x] `flutter pub get` succeeds
- [x] `flutter analyze` — **0 errors**
- [x] `flutter test` — **249/249 pass**
- [x] `flutter build apk --release` succeeds
- [x] Plan and report documented
- [x] No business functionality removed
- [x] No analyzer suppressions added
