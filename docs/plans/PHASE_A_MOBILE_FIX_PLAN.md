# Phase A — Mobile Fix Plan

**Project:** pranidoctor_user (Prani Doctor User App)  
**Date:** 2026-05-30  
**Owner:** Mobile engineering  
**Goal:** `flutter analyze` = 0 errors, `flutter test` = pass, `flutter build apk` = pass

---

## Current project assessment

| Area | Status (baseline audit) |
|------|-------------------------|
| SDK | Dart ^3.11.5, Flutter stable |
| Architecture | Feature modules + Riverpod + go_router |
| Localization | Custom codegen (`tool/i18n/build_localization.dart`), 1300+ keys |
| Dependencies | 52 packages have newer majors (out of scope for Phase A) |
| Prior release pass | Analyze + APK already green; 11 test failures remain |

### Baseline command results

| Command | Result |
|---------|--------|
| `flutter pub get` | Pass |
| `flutter analyze` | **0 errors**, ~110 warnings/info |
| `flutter test` | **238 pass / 11 fail** |
| `flutter build apk --release` | Pass (prior run, 97.2 MB) |

---

## Root cause analysis

### RC-A1 — Widget tests assume English UI (P0)

**Symptoms:** Animal form tests cannot find `"Next"`, `"Add animal"`, `"Enter a name or tag"`. Home retry test cannot find `"Try again"`.

**Cause:** `MaterialApp` in tests omits `locale`; host OS locale resolves to `bn`, where strings differ (e.g. `animalFormNext` → `"পরের ধাপ"`, `dashboardRetry` → `"আবার চেষ্টা করুন"`).

**Fix:** Pin `locale: const Locale('en')` in widget tests via shared harness.

### RC-A2 — `HomeMetricCard` grid overflow (P0)

**Symptoms:** RenderFlex overflow ~8.3px in `summary_card.dart`; golden diffs ~4.5%; home widget tests throw layout exceptions.

**Cause:** `GridView` `childAspectRatio: 1.5` allocates ~78px inner height while card content (icon + headline + label) exceeds that. `minHeight: 96` conflicts with parent constraints.

**Fix:** Make metric card layout flex-aware (remove conflicting minHeight; use `Expanded` for label).

### RC-A3 — Settings provider gate in unit test (P1)

**Symptoms:** `settings_integration_test` expects `SettingsTheme.light`, gets `null`.

**Cause:** `SettingsNotifier.build()` returns `null` when `protectedApisEnabledProvider` is false (default in test `ProviderContainer`).

**Fix:** Override `protectedApisEnabledProvider` → `true` in provider test.

### RC-A4 — Home page test scroll target (P1)

**Symptoms:** `scrollUntilVisible` throws `Bad state: No element` for Summary section.

**Cause:** Default test viewport + lazy slivers; `find.byType(Scrollable).first` may not resolve primary vertical scrollable reliably after layout exceptions.

**Fix:** Taller test surface + direct visibility assertions for always-mounted sections.

### RC-A5 — Golden baseline drift (P1)

**Symptoms:** drawer/home goldens differ ~4.5–4.8%.

**Cause:** UI/layout changes (metric cards, closed-beta banner, i18n) since baselines captured.

**Fix:** Regenerate goldens after RC-A2 layout fix.

### RC-A6 — Android Kotlin compatibility (resolved)

**Symptoms:** `sentry_flutter` failed under Kotlin 2.x.

**Fix (already applied):** `android/build.gradle.kts` forces Kotlin language/api 1.8 for subprojects.

---

## Compile issues

None at baseline — release APK builds successfully.

---

## Analyzer issues

| Severity | Count | Blocker |
|----------|------:|---------|
| error | 0 | No |
| warning | ~15 | No |
| info | ~95 | No |

Categories: unused imports (AI widgets), deprecated Radio/FormField APIs, `constant_identifier_names` on generated `TranslationKeys`, `use_build_context_synchronously` info lints.

**Phase A policy:** Fix errors only; do not mass-refactor info/warning lints.

---

## Test issues

| Failing test | Root cause |
|--------------|------------|
| `add_animal_first_submit_test` (×2) | RC-A1 locale |
| `add_animal_rapid_tap_test` | RC-A1 locale |
| `home_refresh_test` (×2) | RC-A1 locale + RC-A2 overflow |
| `home_page_test` | RC-A2 overflow + RC-A4 scroll |
| `settings_integration_test` | RC-A3 provider gate |
| `drawer_golden_test` | RC-A5 golden drift |
| `home_golden_test` (×3) | RC-A2 + RC-A5 |

---

## Dependency issues

No resolution conflicts blocking build. Major-version upgrades deferred to Phase B.

---

## Platform issues

| Platform | Issue | Status |
|----------|-------|--------|
| Android | Kotlin 2.x vs sentry | Fixed (Kotlin 1.8 override) |
| Android | Gradle 8.14 | OK |
| iOS | Not in Phase A scope | N/A |

---

## Fix strategy

```
1. Document this plan
2. Fix HomeMetricCard overflow (RC-A2) — production layout
3. Add test/helpers/widget_test_harness.dart with en locale (RC-A1)
4. Update failing widget/provider tests
5. Override protectedApisEnabled in settings test (RC-A3)
6. Regenerate golden baselines (RC-A5)
7. flutter analyze → confirm 0 errors
8. flutter test → confirm all pass
9. flutter build apk --release → confirm pass
10. Write PHASE_A_MOBILE_FIX_REPORT.md
```

**Out of scope:** Package upgrades, deprecated Radio migration, unused-import cleanup, business-logic changes.

---

## Risk assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Golden updates mask real regressions | Medium | Medium | Review diff images in `test/golden/failures/` before commit |
| Locale harness hides bn-only bugs | Low | Low | Production uses user locale; bn strings covered by i18n audit |
| Metric card layout change affects tablet | Low | Low | Verify goldens include tablet size |
| Kotlin override breaks future plugin | Low | Medium | Track sentry_flutter Kotlin 2.x release |

---

## Verification checklist

- [x] `flutter pub get` succeeds
- [x] `flutter analyze` reports **0 errors**
- [x] `flutter test` — **all tests pass**
- [x] `flutter build apk --release` succeeds
- [x] `docs/plans/PHASE_A_MOBILE_FIX_PLAN.md` complete
- [x] `docs/reports/PHASE_A_MOBILE_FIX_REPORT.md` complete
- [x] No business functionality removed
- [x] No analyzer error suppressions added
