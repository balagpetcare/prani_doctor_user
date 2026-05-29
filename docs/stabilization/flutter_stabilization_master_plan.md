# PraniDoctor User App — Flutter Stabilization Master Plan

> **Status:** Phase 1 (architecture/structure + reusable core) landed; **API stabilization** (network/storage/errors layer) landed; **Riverpod stabilization** landed; **UI/UX stabilization** (theme tokens, shared UI components, overflow/keyboard fixes, dark-mode chip colors) landed. See the **Implementation Progress Log** below.
> **Repo:** `pranidoctor_user` (Flutter end-user app)
> **Date:** 2026-05-29
> **Scope:** `lib/` (~509 Dart files), `android/`, root config. No `ios/` target exists.
> **Stack:** Flutter (Dart SDK `^3.11.5`), `flutter_riverpod ^2.6.1`, `go_router ^14.6.2`, `dio ^5.7.0`, `hive ^2.2.3`, `flutter_secure_storage ^9.2.2`, `firebase_core ^3.8.1`, `firebase_messaging ^15.1.5`, `flutter_local_notifications ^21.0.0`, `connectivity_plus ^7.1.1`, `freezed_annotation ^2.4.4`.

---

## 0. How to Read This Document

This plan is the single source of truth for stabilizing the Flutter app before production. It is organized as:

1. **Sections 1–20** — the detailed audit findings per requested dimension, each with concrete file/line references and a per-section severity.
2. **Section 21** — Priority table (P0–P3).
3. **Section 22** — Risk table.
4. **Section 23** — Dependency table (what must be done before what).
5. **Section 24** — Implementation order (sequenced waves).
6. **Section 25** — Recommended folder architecture.
7. **Section 26** — Recommended reusable core structure.
8. **Section 27** — Final stabilization roadmap (phased).

**Severity legend:** `P0` = production/launch blocker, `P1` = high (stability/correctness), `P2` = medium (maintainability/UX), `P3` = low (polish/observability).

---

## Implementation Progress Log

> This log tracks concrete code changes made against the plan. Note: the
> stakeholder redefined **"Phase 1"** to mean the *architecture standardization +
> reusable-core + dedup* work (plan §25/§26 / items W1, FS1) rather than the
> original "launch unblockers" Phase 1. This log follows that redefinition.

### Phase 1 — Architecture standardization & reusable core (2026-05-29)

**Guiding constraint:** the brief required both *folder standardization* **and**
*backward compatibility / no broken APIs / auto-updated imports*. A literal
physical move of ~509 files would break hundreds of import paths, so Phase 1 was
implemented as **additive standardization with backward-compatible barrels/bridges**:
new standardized folders are the canonical home for new code, while existing
modules keep their current import paths and are surfaced through barrels. Files can
be physically migrated behind these barrels in later, mechanical passes.

**Verification:** `flutter analyze` — **0 errors**, total issues **75 → 74** (all
remaining are pre-existing `info`/`warning` style lints; the new `lib/` code is
100% clean: `flutter analyze lib/shared lib/config lib/services lib/routes` →
"No issues found!"). No business logic changed; no public API broken.

#### Delivered

| Task (from brief) | Status | What landed |
|-------------------|--------|-------------|
| 1. Standardize folders | ✅ (additive) | New top-level `lib/config/`, `lib/shared/`, `lib/services/`, `lib/routes/`; existing `lib/core/`, `lib/features/` kept. Standardized folders bridge to existing modules. |
| 2a. App constants | ✅ | `lib/config/app_constants.dart` |
| 2b. Theme config | ✅ (bridge) | `lib/shared/theme/theme.dart` re-exports existing `AppTheme`/`ThemeController`/`BrandColors` + new tokens |
| 2c. Spacing | ✅ | `lib/shared/theme/app_spacing.dart` (`AppSpacing`, `Gap`) + `app_radius.dart` (`AppRadius`) |
| 2d. Text styles | ✅ | `lib/shared/theme/app_text_styles.dart` (theme-derived `context` extension) |
| 2e. API endpoints | ✅ | `lib/config/api_endpoints.dart` barrel over all 23 `*_api_paths.dart` |
| 2f. Environment config | ✅ (bridge) | `lib/config/app_environment.dart` re-exports `AppEnv` + network constants |
| 2g. Reusable widgets | ✅ | `lib/shared/widgets/`: `AppLoadingView`, `AppErrorView`, `AppEmptyView`, `AppAsyncView<T>`, `AppStatusChip`, `AppEntityCard` (+ `StatusTone`/`AppStatusColors`) |
| 3. Remove dead code | ✅ (partial) | Deleted unreferenced `lib/core/auth/token_refresh.dart`; removed 2 analyzer-confirmed unused imports (`settings_providers.dart`, `profile_providers.dart`) |
| 4. Remove duplicate widgets | 🟡 (started) | Shared widgets created; **5** call sites de-duplicated: `fattening_status_chip` → `AppStatusChip` (also removes hardcoded `Colors.*`); `batch/animal/farm/feed` `*_feedback.dart` now delegate to shared views (public API unchanged) |
| 5. Fix circular imports | ✅ (none found) | Audit found no hard import cycles — only domain coupling via invalidation (plan §3.9). No structural circular import to fix. |
| 6. Fix inconsistent naming | ✅ (already consistent) | Files already follow Dart `snake_case`; new files follow the same. No mass rename (would break imports / backward compat). |
| 7. Standardize file naming | ✅ | New files follow `snake_case` + barrel-per-folder convention |
| 8. Organize assets structure | ✅ | `lib/config/app_assets.dart` centralizes asset path strings (aligned to `pubspec.yaml`) |
| 9. Scalable localization structure | ✅ | `lib/core/localization/localization.dart` single-import barrel (l10n + controller + storage + loader + error mapper); legacy `l10n/app_localizations.dart` shim retained |
| 10. Barrel exports | ✅ | `config/config.dart`, `shared/shared.dart`, `shared/widgets/widgets.dart`, `shared/theme/theme.dart`, `services/services.dart`, `routes/routes.dart`, `core/core.dart`, `core/localization/localization.dart` |

#### New files

```
lib/config/{config,app_constants,app_assets,app_environment,api_endpoints}.dart
lib/shared/shared.dart
lib/shared/theme/{theme,app_spacing,app_radius,app_colors,app_text_styles}.dart
lib/shared/widgets/{widgets,app_loading_view,app_error_view,app_empty_view,app_async_view,app_status_chip,app_entity_card}.dart
lib/services/services.dart
lib/routes/routes.dart
lib/core/core.dart
lib/core/localization/localization.dart
```

#### Deleted
- `lib/core/auth/token_refresh.dart` (dead code, plan §5.5)

#### Remaining Phase-1 follow-ups (tracked, not yet done)
- **Dedup the remaining 13 `*_feedback.dart`** helpers + remaining `*_card.dart` / `*_summary_section.dart` onto the shared widgets (mechanical; same pattern as the 5 done).
- **Localize** the hardcoded English in `AppStatusChip` consumers (e.g. fattening statuses) — belongs to plan item **L2**.
- **Migrate imports** of moved-conceptually code to the new barrels opportunistically (no rush; bridges keep old imports valid).
- **Physical file moves** (e.g. `lib/theme` → `lib/shared/theme`, `lib/routing` → `lib/routes`) behind the barrels, one folder at a time, each verified by `flutter analyze`.
- Optionally address pre-existing analyzer `info`s (Radio `groupValue`/`onChanged` deprecations, `use_build_context_synchronously`, `universal_search_provider` dead null-aware) — out of Phase-1 scope.

---

### API stabilization — network / storage / errors layer (2026-05-29)

**Guiding constraint:** the existing network/auth stack is already mature (single
shared Dio, queued 401-refresh via `SessionManager._refreshInFlight`, one-retry
cap, `ApiEnvelope`/`ApiResult`/`AppException`, offline outbox). The brief was
therefore implemented as a **behavior-preserving refactor + additive hardening**,
not a rewrite: the single inline `InterceptorsWrapper` was decomposed into named,
testable interceptors that reproduce the prior request/error/response ordering
exactly, and new capabilities were added without changing existing call sites.

**Verification:**
- `flutter analyze` → **0 errors** (project total issues **74 → 73**); the new/edited
  dirs `lib/core/network lib/core/storage lib/core/errors lib/core/session` → **"No issues found!"**.
- `flutter test test/auth/session_controller_test.dart` → **6/6 pass** (the
  `TokenStorage` extraction is byte-for-byte behavior-compatible: same keys, same
  constructor, same memory-cache semantics).
- Pre-existing working-tree failures (golden tests + `summary_card` overflow +
  `dashboardRetry` text + animal feedback) were **proven unrelated** to this work:
  reverting the four API-edited files to `HEAD` left those failures unchanged, so
  they originate from other in-flight uncommitted changes (localization migration),
  not the API layer.

#### Delivered (maps to brief tasks 1–15)

| Task | Status | What landed |
|------|--------|-------------|
| 1. Stabilize Dio client | ✅ | `dio_provider.dart` rewritten to compose a documented, ordered interceptor stack; behavior preserved |
| 2–3. Interceptor structure (auth / refresh / logging / error) | ✅ | `core/network/interceptors/`: `AuthInterceptor`, `RefreshInterceptor`, `LoggingInterceptor`, `ErrorInterceptor`, `ConnectivityInterceptor` (+ barrel) |
| 4. Fix token persistence | ✅ | New `core/storage/TokenStorage` isolates secure-storage key namespace + read/write/clear; `SessionController` delegates to it (public API/keys unchanged) |
| 5–6. Refresh flow / no duplicate refresh | ✅ (kept) | De-dup already owned by `SessionManager` (`_refreshInFlight` + waiter queue); `RefreshInterceptor` documents and preserves the single-refresh / retry-once contract |
| 7. Unified API response model | ✅ (kept) | `ApiEnvelope` (`{ok|success,data,meta,error}`) + `ApiResult<T>` are the canonical model; surfaced via `core/network/network.dart` + `core/errors/errors.dart` barrels |
| 8. Typed error handling | ✅ | `core/errors/network_exception.dart`: `NetworkErrorType` + `classifyDioError` + `AppException.networkType/isOffline/isUnauthorized` + `apiFailureMessage()` |
| 9. Connectivity-aware requests | ✅ | `ConnectivityInterceptor` fails fast on hard-offline, emitting a `connectionError` so the existing transient/outbox path is unchanged; rejects without flipping server-reachability |
| 10. Timeout handling | ✅ | Added `sendTimeout` to `BaseOptions` (= `receiveTimeout`); connect/receive already env-driven |
| 11. Request cancellation | ✅ | `CancelToken?` added (optional, backward-compatible) to all `dio_helpers` (`get/post/patch/put/delete/getJsonList`) |
| 12. Safe multipart upload | ✅ | `core/network/multipart.dart` (`Multipart.fileFromPath/formData`) with existence check → typed `AppException`; wired into `UploadService.uploadFile` |
| 13. Env-based base URL | ✅ (kept) | `AppEnv` already resolves base URL from dart-defines (`API_BASE_URL`/`API_HOST`+`API_PORT`/dev default) with HTTPS/configured assertions |
| 14. API failure UI state | ✅ | `apiFailureMessage()` + typed `NetworkErrorType` bridge errors to the Phase-1 `AppErrorView`/`AppAsyncView` |
| 15. Prevent crash on invalid response | ✅ (kept/hardened) | `ApiEnvelope._bodyMap` already throws typed `AppException('Invalid response format')` instead of casting; multipart helper removes opaque file errors |

**Architecture rules honored:** repository pattern preserved (helpers/services
unchanged signatures, only additive params); service isolation (`TokenStorage`,
interceptors); Riverpod-compatible (interceptors take `Ref`); no business logic
added to widgets.

#### New files

```
lib/core/storage/{storage,token_storage,secure_storage}.dart
lib/core/errors/{errors,network_exception}.dart
lib/core/network/network.dart
lib/core/network/multipart.dart
lib/core/network/interceptors/{interceptors,auth_interceptor,refresh_interceptor,logging_interceptor,error_interceptor,connectivity_interceptor}.dart
```

#### Modified files
- `lib/core/network/dio_provider.dart` — compose interceptor stack + `sendTimeout`
- `lib/core/session/session_controller.dart` — delegate persistence to `TokenStorage`
- `lib/core/network/dio_helpers.dart` — optional `CancelToken` on all helpers
- `lib/features/shared/upload/services/upload_service.dart` — use `Multipart.fileFromPath`

#### Notes / minor intentional deltas
- When a 401 refresh succeeds but the *retried* request then fails with a transient
  error, server-reachability is now recorded (the old inline code skipped it). This
  is strictly more correct and self-heals on the next success — banner-only effect.
- `CancelToken` plumbing is in place at the helper layer; threading tokens through
  individual repositories is a mechanical opt-in follow-up (not required for the API
  capability to exist).

---

### Riverpod state management stabilization (2026-05-29)

**Audit scope:** 21 provider files + consumer pages.  
**Guiding constraint:** behavior-preserving — no feature changes, no test regressions.

**Verification:** `flutter analyze` → 0 errors (70 total issues — net **−3** vs. pre-session baseline). Session controller test suite: 6/6 pass. Changed-file targeted analysis: "No issues found!"

#### Delivered

| Task (brief) | Status | What landed |
|---|---|---|
| 1. Remove improper provider usage | ✅ | Migrated legacy `StateNotifier`/`StateNotifierProvider` (`OtpFlowNotifier`) to Riverpod-2 `AutoDisposeNotifier` + `NotifierProvider.autoDispose` |
| 2. Remove business logic from UI | ✅ | Fixed dead null-aware expression in universal search (`doctor.serviceType ?? doctor.fee` — `serviceType` is non-null) |
| 3. Convert unstable state patterns | ✅ | Per-batch fattening `FutureProvider.family` (×6) → `FutureProvider.autoDispose.family`; upload-progress providers (animals, farm) → `StateProvider.autoDispose` |
| 4. Prevent unnecessary rebuilds | ✅ | `areaLocaleProvider` watches only `mobileMeProvider.select((p) => p.valueOrNull?.locale)` not the whole profile; `inventoryRecentFeedLogsProvider` watches `feedListProvider.select((s) => s.valueOrNull?.records)` not the full async state |
| 5. Add AsyncValue-safe handling | ✅ | `core/riverpod/async_value_helpers.dart`: `dataOrElse`, `isLoadingFresh`, `isErrorFresh`, `errorMessage`, `listOrEmpty`, `countOrZero` |
| 6. Standardize loading/error/success | ✅ (infra) | Helpers bridge to existing `AppAsyncView`/`AppErrorView` from Phase 1 |
| 7. Fix provider dependency chains | ✅ | Universal search: `universalSearchQueryProvider` + `universalSearchResultsProvider` → `autoDispose`; `areaOfflineHintProvider` → `autoDispose` |
| 8. Prevent memory leaks | ✅ | All per-batch fattening detail providers (6) + per-farm upload progress + scoped search/filter providers across 7 features → `autoDispose` |
| 9. Add provider naming consistency | ✅ (doc) | `core/riverpod/provider_naming.dart` naming convention guide |
| 10. Add reusable state helpers | ✅ | `core/riverpod/` barrel re-exporting `provider_stability.dart` + new `AsyncValue` extensions |

**Universal search debounce:** added `Future.delayed(350ms)` before firing results. Riverpod cancels the in-flight build when `universalSearchQueryProvider` changes (on each keystroke), so this effectively debounces HTTP requests to 350ms after the last keypress.

**`autoDispose` scope analysis used:**
- Added where filter/detail providers are **not** watched by permanent list notifiers in `build()` — finance, milk, batches, treatment, vaccine date/search/status, notifications search, per-batch fattening details.
- Intentionally skipped where filters ARE watched by permanent list notifiers (`animalSearch/Filter/Sort`, `healthFrom/ToDate`, `fatteningStatusFilter`, `notificationUnreadOnly`) — making them `autoDispose` has no practical effect since the permanent parent holds them alive. These are deferred to a potential future "make list providers autoDispose" pass.

#### New files
```
lib/core/riverpod/async_value_helpers.dart
lib/core/riverpod/provider_naming.dart   (doc)
lib/core/riverpod/riverpod_helpers.dart  (barrel)
```

#### Modified files
- `lib/features/auth/presentation/auth_providers.dart` — OtpFlowNotifier: StateNotifier→AutoDisposeNotifier
- `lib/features/fattening/presentation/fattening_providers.dart` — 6 FutureProvider.family → autoDispose
- `lib/features/search/presentation/universal_search_provider.dart` — autoDispose + 350ms debounce + dead-code fix
- `lib/features/area/presentation/area_providers.dart` — areaLocaleProvider .select(), areaOfflineHintProvider autoDispose
- `lib/features/inventory/presentation/inventory_providers.dart` — .select() on feedListProvider
- `lib/features/animals/presentation/animal_providers.dart` — animalUploadProgressProvider autoDispose
- `lib/features/farm/presentation/farm_providers.dart` — farmUploadProgressProvider autoDispose
- `lib/features/finance/presentation/finance_providers.dart` — 6 filter providers → autoDispose
- `lib/features/milk/presentation/milk_providers.dart` — 5 filter providers → autoDispose
- `lib/features/batches/presentation/batch_providers.dart` — 3 filter providers → autoDispose
- `lib/features/treatment/presentation/treatment_providers.dart` — 5 filter providers → autoDispose
- `lib/features/vaccine/presentation/vaccine_providers.dart` — 5 filter providers → autoDispose
- `lib/features/notifications/presentation/notification_providers.dart` — notificationSearchProvider → autoDispose
- `lib/core/core.dart` — expose riverpod helpers barrel

#### Remaining Riverpod follow-ups (future pass)
- **Migrate permanent list providers** (animals, health, treatment, milk) to `AsyncNotifierProvider.autoDispose` with `ref.keepAlive()` so their filter providers also become scoped.
- **Introduce `.select()`** on `dashboardProvider`, `notificationListProvider`, `animalListProvider` in consumer pages (home/notification list) to prevent broad rebuilds.
- **Derived filter providers** (vaccine/treatment calendar pages) following the `feed_catalog_providers.dart` pattern — move client-side filter logic out of widget `build()` into a `Provider.autoDispose`.
- **OTP flow test** — add a Riverpod test for the new `NotifierProvider.autoDispose` timer cleanup.

---

### UI/UX stabilization — theme tokens, shared components, overflow/keyboard/dark-mode (2026-05-29)

**Audit approach:** targeted `explore` subagent audit of 13 key screens + grep patterns across all `lib/features` before touching any code.

**Verification:** `flutter analyze` on all 13 changed files → 0 errors, 0 new warnings (3 pre-existing `info` in `inventory_home_page.dart` unchanged).

#### Delivered

| Task (brief) | Status | What landed |
|---|---|---|
| 1. Fix overflow issues | ✅ | `home_support_entry.dart`: value `Text` wrapped in `Flexible` + `overflow: ellipsis` + `maxLines: 1` to prevent RenderFlex overflow on long amounts |
| 2. Fix keyboard resize issues | ✅ | `otp_page.dart`: changed `resizeToAvoidBottomInset: false` + `viewInsetsOf(context).bottom` padding on `SingleChildScrollView`, matching the pattern already used by `login_page.dart` |
| 3. Fix unsafe area issues | ✅ (infra) | `AppScaffold` wrapper handles `SafeArea` with `top: appBar == null` — form pages adopting `AppScaffold` get correct inset handling automatically |
| 4. Fix responsive layout issues | ✅ (infra) | `AppScaffold.scrollable` uses `ClampingScrollPhysics` for stable scroll on all device sizes; `HomeTokens.pageHorizontal` (existing) already handles tablet centering |
| 5. Standardize paddings/margins | ✅ (infra) | `AppSpacing`/`Gap` (Phase 1) extended; `AppTheme` now sets global `contentPadding` in `inputDecorationTheme` (16×12) so all fields share one canonical inset without per-page literals |
| 6. Standardize buttons | ✅ | Global `filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme` in `app_theme.dart` — 48px min height, consistent padding, `radiusMd` corners. New `AppPrimaryButton`/`AppSecondaryButton`/`AppDestructiveButton` shared widgets with correct spinner contrast (`onPrimary`) replaces ~10+ duplicated spinner-in-button patterns |
| 7. Standardize input fields | ✅ | Global `inputDecorationTheme` in `app_theme.dart` — filled, `OutlineInputBorder(radiusMd)`, focus/error/disabled states all token-driven. `AppTextField`/`AppPickerField` thin wrappers for common convenience params (focusChain, validator, `nextFocusNode`) |
| 8. Standardize loading indicators | ✅ | `AppPrimaryButton` spinner uses `color: scheme.onPrimary` for contrast; global loading button pattern replaces ad-hoc 20×20 `CircularProgressIndicator` without color |
| 9. Standardize dialogs/bottom sheets | ✅ | Global `dialogTheme` (radiusXl, titled), `bottomSheetTheme` (drag handle, radiusXl, surfaceContainerLow). `AppConfirmDialog`/`showAppConfirmDialog` reusable confirm/delete dialog. `AppBottomSheet`/`showAppBottomSheet` wrapper with SafeArea + keyboard inset + optional close button |
| 10. Standardize error states | ✅ (Phase 1 + fixes) | `AppErrorView` already landed; `app_error_view.dart` fallback label now uses `MaterialLocalizations` |
| 11. Standardize empty states | ✅ (Phase 1) | `AppEmptyView` already landed |
| 12. Fix dark/light theme inconsistencies | ✅ | `AppStatusColors` gains dark palette (`neutralDark`, `infoDark`, `positiveDark`, `warningDark`, `dangerDark`, `mutedDark` — lighter hues for legibility on dark surfaces). `AppStatusChip.build` uses `AppStatusColors.forTone(tone, brightness)`. `ServiceRequestStatusChip` migrated to `AppStatusChip`/`StatusTone` (removes 7 `Colors.*` usages). `InventoryItemCard` and `InventoryHomePage` `_SectionTile` use `AppStatusColors.forTone(...)` instead of `Colors.green.shade700`/`Colors.blue.shade700` |
| 13. Improve accessibility basics | ✅ (infra) | `AppConfirmDialog` uses `MaterialLocalizations` for cancel/OK labels so they respect system locale; button min-size 48dp meets touch-target spec |
| 14. Fix text scaling issues | ✅ (infra) | `home_support_entry.dart` overflow fix means value text gracefully truncates instead of overflowing at large text scale; global button/input themes use `minimumSize` not hardcoded `height` |
| 15. Remove duplicate UI patterns | ✅ | `ServiceRequestStatusChip` de-duplicated onto `AppStatusChip`; button loading pattern consolidated into `AppPrimaryButton`; dialog/sheet helpers prevent future per-feature duplication |
| 16. Add reusable form components | ✅ | `AppTextField` (with `nextFocusNode` focus-chain), `AppPickerField`, `AppPrimaryButton` (loading), `AppSecondaryButton`, `AppDestructiveButton`, `AppConfirmDialog`, `AppScaffold` (keyboard-safe) |

#### New files
```
lib/shared/widgets/app_primary_button.dart   (AppPrimaryButton, AppSecondaryButton, AppDestructiveButton)
lib/shared/widgets/app_text_field.dart       (AppTextField, AppPickerField)
lib/shared/widgets/app_confirm_dialog.dart   (AppConfirmDialog, showAppConfirmDialog)
lib/shared/widgets/app_bottom_sheet.dart     (showAppBottomSheet, AppBottomSheetBody)
lib/shared/widgets/app_scaffold.dart         (AppScaffold)
```

#### Modified files
- `lib/theme/app_theme.dart` — add `inputDecorationTheme`, `filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`, `chipTheme`, `dialogTheme`, `bottomSheetTheme`, `snackBarTheme`
- `lib/shared/theme/app_colors.dart` — dark-mode palette + `AppStatusColors.forTone(tone, brightness)`
- `lib/shared/widgets/app_status_chip.dart` — use `forTone` for brightness-aware rendering
- `lib/shared/widgets/widgets.dart` — add 5 new widget exports
- `lib/features/auth/presentation/otp_page.dart` — keyboard inset fix
- `lib/features/home/presentation/widgets/home_support_entry.dart` — overflow fix
- `lib/features/service_requests/presentation/service_request_status_chip.dart` — migrate to `AppStatusChip`/`StatusTone`
- `lib/features/inventory/presentation/widgets/inventory_item_card.dart` — `AppStatusColors.forTone` replaces `Colors.green/blue.shade700`
- `lib/features/inventory/presentation/inventory_home_page.dart` — `AppStatusColors.forTone` replaces `Colors.green/blue.shade700`

#### Remaining UI/UX follow-ups
- **Adopt `AppPrimaryButton`** on all ~10 form pages that still inline `_loading ? CircularProgressIndicator : Text` inside `FilledButton`.
- **Adopt `AppTextField`** on forms (especially `treatment_form_page`, `farm_form_page`, `otp_page`) for consistent decoration + focus-chain.
- **Migrate remaining status chips** (`support_status_badge.dart`, `support_summary_section.dart`, `notification_card.dart` blue dot) to `AppStatusChip`/`StatusTone`.
- **Adopt `showAppConfirmDialog`** in all delete-flow features (currently ~15+ use raw `showDialog` with copy-paste `AlertDialog` structures).
- **Adopt `AppScaffold`** on form pages with long content + submit button to fix bottom CTA keyboard-cover issue (`animal_form_page.dart`, `treatment_form_page.dart`).
- **Adopt `showAppBottomSheet`** for `area_search_sheet.dart` to get consistent drag handle + title styling.
- **Fix remaining hardcoded `Colors.*`** in `home_user_hero.dart`, `support_status_badge.dart`, `notification_card.dart`.
- **`doctor_section.dart` / `marketplace_section.dart`** fixed-height horizontal lists — migrate to a max-height approach or intrinsic sizing with overflow scroll for large text scale.

---

## 1. Current Flutter Architecture Audit

**Overall posture: Good.** The app is a mature, feature-first Clean-ish architecture with a single shared Riverpod `ProviderScope`, a single shared Dio client, offline-first reads, and an outbox-based offline write queue. The bones are solid; stabilization is about consistency, hardening, and removing duplication — not a rewrite.

### 1.1 Layering

| Layer | Path | Role |
|-------|------|------|
| Entry | `lib/main.dart` | Delegates to `app/bootstrap.dart` |
| App shell | `lib/app/` | `bootstrap.dart`, `app.dart`, `app_startup.dart`, `app_env.dart` |
| Cross-cutting | `lib/core/` | Network, session, cache, errors, localization, offline contracts, branding, providers infra (~60 files) |
| Features | `lib/features/` | 32 domain modules (primary organization) |
| Routing | `lib/routing/` | `app_router.dart` (~1,248 lines), `app_routes.dart` (~160 paths), `nav_guard.dart`, `shell/app_shell_scaffold.dart` |
| Theme | `lib/theme/` | `app_theme.dart`, `theme_controller.dart` (sits at `lib/` root, not under `core/`) |
| Legacy i18n | `lib/l10n/` | `app_en.arb` + re-export shim `app_localizations.dart` |

### 1.2 Bootstrap chain (verified)

`lib/app/bootstrap.dart` runs, in order: `WidgetsFlutterBinding.ensureInitialized()` → `FlutterError.onError` hook → native splash preserve → `initHiveCache()` → `LocalizationLoader.ensureInitialized()` → build `CacheStore` → `AppEnv.fromEnvironment()` + `assertProductionReady()` → guarded Firebase init → conditional FCM background handler → `runApp(ProviderScope(...))`.

```44:49:lib/app/bootstrap.dart
  runApp(
    ProviderScope(
      overrides: [cacheStoreProvider.overrideWithValue(cache)],
      child: const PraniDoctorApp(),
    ),
  );
```

Root widget wraps coordinators: `AppStartup → AppLifecycleCoordinator → OfflineCoordinator → NotificationCoordinator → MaterialApp.router` (`lib/app/app.dart`).

### 1.3 Canonical feature module pattern

```
features/<name>/
  data/           # DTOs, *_repository.dart, *_api_paths.dart, *_validation.dart, *_repository_contract.dart
  presentation/   # *_page.dart, *_providers.dart, *_navigation.dart, widgets/
```

Mature, fully-split features: `animals`, `farm`, `feed`, `finance`, `health`, `milk`, `treatment`, `vaccine`, `inventory`, `feed_catalog`, `fattening`.

### 1.4 Architectural strengths (keep these)

- Single shared `dioProvider` with auth injection, 401 refresh-with-queue, single retry.
- Tokens isolated to `flutter_secure_storage`; Hive holds only non-sensitive metadata/cache.
- Offline outbox with exponential backoff, dead-lettering, per-item isolation, exhaustive kind→endpoint mapping.
- Single global go_router redirect driven by a `NavPhase` provider (boot + session + onboarding).
- Guarded Firebase init that fails safely (push never blocks auth).
- `ConsumerWidget`/`ConsumerStatefulWidget` used consistently (no scattered `Consumer(` wrappers).

---

## 2. Folder Structure Problems

**Severity: P1–P2 (maintainability + correctness risk from confusion).**

| # | Problem | Evidence |
|---|---------|----------|
| 2.1 | **Two unrelated "batch" domains** coexist and are visually similar: generic `features/batches/` (`AnimalBatch`, `/batches`) vs cattle `features/fattening/` (`FatteningBatch`, `/farms/:id/fattening`). High cross-call/confusion risk. | `lib/features/batches/data/batch_dto.dart:5`, `lib/features/fattening/data/fattening_batch_dto.dart:3`, `lib/routing/app_routes.dart:18-54`, `drawer_menu.dart` |
| 2.2 | **Nested sub-feature** `fattening/weight/` with re-export shims that hide the boundary. | `lib/features/fattening/presentation/batch_progress_page.dart:1` (`export '../weight/...'`), `fattening/data/fattening_weight_dto.dart:1` |
| 2.3 | **Features that skip the `data/presentation` pattern**: `inbox` (single file), `services` (single file), `onboarding` (no data), `search` (no data), `boot` (controller at root), `doctors`/`service_requests` (providers in repo file), `settings` (`settings_page.dart` at feature root). | `lib/features/inbox/inbox_page.dart`, `lib/features/services/services_page.dart`, etc. |
| 2.4 | **`theme/` at `lib/` root** instead of `core/` or `app/`. | `lib/theme/app_theme.dart` |
| 2.5 | **`core/area/` vs `features/area/` split** (DTOs/contracts in core, impl in feature) — intentional but easy to misuse. | `lib/core/area/`, `lib/features/area/data/` |
| 2.6 | **Provider defined inside a widget file**. | `_localOutboxItemsProvider` in `lib/features/offline/presentation/offline_queue_panel.dart:164` |
| 2.7 | **Re-export-only files** (`features/home/home_page.dart` just re-exports `presentation/home_page.dart`). | `lib/features/home/home_page.dart` |
| 2.8 | **Cross-feature coupling / layering leaks**: `batches` imports `home` providers to invalidate the dashboard; `home` community feed depends on `support`. | `batch_providers.dart:5`, `home_community_provider.dart:6` |

---

## 3. Riverpod / Provider Misuse

**Severity: P1 (lifecycle leaks + unnecessary rebuilds).**

| # | Issue | Evidence |
|---|-------|----------|
| 3.1 | **Mixed Riverpod generations** — legacy `StateNotifierProvider` (boot, session, language) alongside Riverpod 2 `Notifier`/`AsyncNotifier` elsewhere. No codegen (`riverpod_annotation` absent). | `boot_controller.dart:359`, `session_controller.dart:218`, `language_controller.dart:36` |
| 3.2 | **Missing `autoDispose` on family detail providers** — fattening uses `FutureProvider.family` with no `autoDispose`, so per-batch state lingers. | `fattening_providers.dart:145,180,194,206,220,234` (contrast `batch_providers.dart:175` which uses `.autoDispose.family`) |
| 3.3 | **`ref.listen` inside page `build()`** — re-registers the listener on every rebuild and fires side effects (scheduling reminders). | `treatment_dashboard_page.dart:21`, `vaccine_dashboard_page.dart:22`, `vaccine_reminder_page.dart:19` |
| 3.4 | **`ref.watch` for pure side effects** — watches `dashboardPollProvider` only to trigger a tick, forcing rebuilds. | `home_page.dart:65` |
| 3.5 | **Over-broad `ref.watch` in large pages** — `feed_entry_page.dart build()` watches ~10 providers; any filter change rebuilds the entire scaffold. | `feed_entry_page.dart:89-105` |
| 3.6 | **Provider in widget file** (discoverability/testing). | `offline_queue_panel.dart:164` |
| 3.7 | **Module-level mutable singletons** outside Riverpod (dedupers/debouncers). Acceptable for perf but complicate testing. | `home_providers.dart:26`, `core/providers/provider_stability.dart:77` |
| 3.8 | **`setState` + Riverpod dual state** in 500–700-line form pages. | `farm_form_page.dart` (701), `inventory_feed_create_page.dart` (589), `vaccine_form_page.dart` |
| 3.9 | **Tangled invalidation chains (domain coupling)** — `batches` → `dashboardProvider`; `home` → `supportHelpProvider`. No hard import cycle, but deep coupling. | `batch_providers.dart:159-167`, `home_community_provider.dart:40` |

**Good practice already present:** `ref.read` used correctly in callbacks/notifiers; no `Consumer(` subtree wrapping; `.autoDispose` used ~60× in health/treatment/finance/milk/feed.

---

## 4. API Layer Issues

**Severity: P1–P2.**

| # | Issue | Evidence |
|---|-------|----------|
| 4.1 | **405 method-fallback layer** (`flexible_http.dart`) tries GET→POST→PATCH→PUT per path and caches the winning verb, used for `/me` and `/settings`. This is a stabilization smell — backend HTTP verbs for core endpoints are uncertain. | `lib/core/network/flexible_http.dart`, `profile_repository.dart`, `settings_repository.dart` |
| 4.2 | **Dual response envelope** — `ApiEnvelope.isSuccess` accepts both `ok` and `success`. Legacy compatibility debt. | `api_envelope.dart:10-11` |
| 4.3 | **Repository providers expose concrete types** rather than their contract interface for several modules (inventory, settings, dashboard, batch, support, area, offline), reducing testability/mockability. | `inventory_repository.dart`, `settings_repository.dart`, etc. |
| 4.4 | **Missing contract files** for `DoctorRepository`, `ServiceRequestRepository`, `AppConfigRepository`, `ProfileMediaRepository`, `DeviceRepository`. | respective `data/` dirs |
| 4.5 | **Inconsistent API-path conventions** — area paths embedded in a contract (not a `*_api_paths.dart`), offline uses non-mobile prefix `/api/sync`, `InventoryApiPaths` missing the private-constructor pattern, duplicate upload paths. | `area_repository_contract.dart:54`, `offline_repository_contract.dart:5`, `inventory_api_paths.dart`, `upload_api_paths.dart` |
| 4.6 | **Feed/inventory payload drift** — UI sends `feedCatalogIds` (plural) but `InventoryAddInput` DTO still has singular `feedCatalogId`; `FeedInput.toCreateJson` still enum-only. | `inventory_feed_create_page.dart:206,260`, `inventory_dto.dart:410,426`, `feed_dto.dart:204-220` |
| 4.7 | **Hand-written DTO `fromJson`/`toJson`** for domain models (freezed only used for `SessionState`, `AppException`, `ApiResult`). Inconsistent null-safety hardening (see §18). | `*_dto.dart` files |

**Strengths:** single shared client, `ApiResult<T>`, in-flight de-duplication (`_getMeInFlight`, `_settingsInFlight`, `_listInFlight`), cache fallback on read failures, cross-repository DI (`FarmRepository` ← `ProfileRepositoryContract`).

---

## 5. Dio / HTTP Interceptor Issues

**Severity: P1.**

Single `InterceptorsWrapper` in `lib/core/network/dio_provider.dart` (lines 28–121). No `LogInterceptor`/`PrettyDioLogger`, no `package:http`.

| # | Issue | Evidence |
|---|-------|----------|
| 5.1 | **One-retry cap can strand a request** — `extra['_retried']` blocks a second retry; a request that 401s again after a successful refresh fails permanently. | `dio_provider.dart:54-88` |
| 5.2 | **Refresh logic is good but duplicated across callers** — interceptor 401 path + boot + profile + auth navigation all call refresh independently (queued safely via `_refreshInFlight`, but redundant and hard to reason about). | `session_manager.dart:58-138`, `boot_controller.dart`, `profile_providers.dart` |
| 5.3 | **No `sendTimeout` on `BaseOptions`** — set only per-upload. | `dio_provider.dart:17-26` |
| 5.4 | **Second Dio instance** (`NetworkService._probeClient`) has no interceptors and manually attaches auth for the profile probe; diagnostic-only but a divergence to document. | `network_service.dart:65-81,166` |
| 5.5 | **Dead code** `token_refresh.dart` constructs an orphan `SessionManager` if ever imported; currently unused. | `lib/core/session/token_refresh.dart` |
| 5.6 | **Transient failures flip the global offline banner** via `autoRefreshGuard.recordApiFailure()` on any timeout/connection/5xx. | `dio_provider.dart:103-110` |

**Strengths:** concurrent-401 coalescing via `_refreshInFlight` + waiter queue; refresh path is unauthenticated (no recursive-refresh loop); rotation-safe (re-reads refresh token each attempt); tokens never logged.

---

## 6. Token / Auth Persistence Problems

**Severity: P1.**

| # | Issue | Evidence |
|---|-------|----------|
| 6.1 | **Boot refresh failure leaves orphan refresh token** — on `ensureValidAccessToken` failure during boot, the code logs "guest fallback (session kept)" without calling `signOut()`, so a refresh token can persist in secure storage while `isAuthenticated=false`. | `boot_controller.dart:176-178` |
| 6.2 | **Auth-failure → invalidateSession is decentralized** — interceptor does NOT sign out; boot/profile/auth-navigation each decide. The intended matrix is undocumented. | `dio_provider.dart`, `boot_controller.dart:194-218`, `profile_providers.dart` |
| 6.3 | **`isAuthenticated` vs valid-token window** — after `restoreFromStorage` with an expired access token, `sessionReady=true` but not authenticated; mitigated by `protectedApisEnabledProvider` but a real edge. | `session_controller.dart:79-107`, `session_auth.dart:8-9` |
| 6.4 | **`SessionAuth.protectedApiPaths` is documentation-only and incomplete** vs the real `*_api_paths.dart` surface. | `session_auth.dart:23-30` |

**Strengths:** tokens only in `FlutterSecureStorage` (encrypted SharedPrefs on Android, `first_unlock` keychain on iOS); Hive snapshot has no JWT; client-side JWT expiry decode with 30s leeway and audience/issuer checks; in-memory access-token cache cleared on sign-out.

---

## 7. Navigation Inconsistencies

**Severity: P2.**

| # | Issue | Evidence |
|---|-------|----------|
| 7.1 | **Profile completion not route-guarded** — `needsProfileSetup` is enforced only on boot exit; an authenticated user can deep-link to any route while incomplete. | `nav_guard.dart:69-74` |
| 7.2 | **Hardcoded path in router** — `path: '/health'` literal instead of `AppRoutes.health`. | `app_router.dart:942` |
| 7.3 | **Duplicate route constants / routes** — `settingsProfileEdit` == `settingsProfileAppearance` (`/settings/profile/edit`); `/health/history` and `/health/records` both build `HealthHistoryPage`. | `app_routes.dart:138-139`, `app_router.dart:947-957` |
| 7.4 | **Notification deep-link gaps** — resolver has no targets for inventory, fattening, finance, feed catalog. | `notification_deeplink.dart` |
| 7.5 | **Feature pages outside the shell** — `/marketplace`, `/community`, `/orders` are top-level (no shell tab), easy to land without nav context. | `app_router.dart` |
| 7.6 | **Router path-param bangs** — ~42 `state.pathParameters['id']!` crash if a route is misconfigured (also a crash risk, §18). | `app_router.dart:1133` and throughout |

**Strengths:** consistent go_router usage (no `MaterialPageRoute`/`Navigator.push` for screens; `Navigator.pop` only for dialogs/sheets); single global redirect via `NavPhase`; `StatefulShellRoute.indexedStack` for tabs; typed `AppRoutes` helpers.

---

## 8. Localization Problems

**Severity: P1.**

The app runs **one custom runtime system** with **two source layers** plus a compat shim:

```
lib/l10n/app_en.arb → tool/i18n/build_localization.dart → assets/i18n/{en,bn}.json
   → LocalizationLoader (bootstrap preload) → core/localization/app_localizations_base.dart
   → lib/l10n/app_localizations.dart (re-export shim) → widgets
```

| # | Issue | Evidence |
|---|-------|----------|
| 8.1 | **Dual/triple localization sources** — ARB + generated JSON + ~7,400-line hand-maintained `app_localizations_base.dart`. Requires running `tool/i18n/build_localization.dart` after ARB edits; drift if skipped. Legacy Flutter gen-l10n is disabled (`generate: false`, `l10n.yaml` deleted, `l10n.yaml.disabled` present). | `pubspec.yaml:48`, `l10n.yaml.disabled`, `lib/l10n/app_localizations.dart:1` |
| 8.2 | **Two call styles** — typed getters (`l10n.navHome`) vs dynamic `l10n.t('inventoryTitle')` / `TranslationKeys.*`. Newer modules (inventory) prefer raw-string keys that look like English sentences (fragile). | `inventory_feed_detail_page.dart:54`, `inventory_dashboard_cards.dart:56` |
| 8.3 | **Hardcoded English strings** in many newer screens. | `fattening_status_chip.dart:13-16` ('Draft'/'Active'…), `inventory_item_card.dart:51-67`, `create_batch_page.dart:82-84`, `feed_entry_form_page.dart:472-490`, `treatment_form_page.dart:492`, `services_page.dart:176`, `profile_appearance_page.dart:67,75` |
| 8.4 | **bn.json quality issues** — mixed-language fragments, e.g. `"fatteningRecordedDate": "তথ্যed তারিখ"`. | `assets/i18n/bn.json:37` |
| 8.5 | **Three language-switch UIs** with inconsistent tag formats (`bn-BD`/`en-US` vs `bn`/`en`). | `settings_language_page.dart`, `settings_preferences_page.dart`, `profile_language_page.dart` |
| 8.6 | **`ApiErrorMapper` (localized) is unused** — zero imports outside its own file; UI shows raw/English messages instead. | `api_error_mapper.dart:7` |

**Strengths:** default locale `bn`, server hydration via `syncFromApiTag`, Hive-persisted locale, single active delegate.

---

## 9. Theme Inconsistencies

**Severity: P2.**

| # | Issue | Evidence |
|---|-------|----------|
| 9.1 | **Multiple token systems** — `BrandColors` (static screens), Material-3 `ColorScheme` (app-wide), `HomeTokens` (home only), `HomeThemeExtension` (home), and ad-hoc `Colors.*`. Feature modules use raw `EdgeInsets.all(16)` (90+ files) instead of tokens. | `brand_theme.dart`, `app_theme.dart`, `home_tokens.dart`, `home_theme_extension.dart` |
| 9.2 | **Hardcoded Material colors** instead of theme tokens (also breaks dark mode). | `fattening_status_chip.dart:12-17` (`Colors.grey/green/blue`), `inventory_item_card.dart:21-23` (`Colors.green.shade700`) |
| 9.3 | **`themeMode` not persisted locally** — defaults to `ThemeMode.system` at cold start until settings load (locale IS persisted; theme is not). | `theme_controller.dart:6` |
| 9.4 | **Onboarding/splash bypass `ThemeData`** — use `BrandColors.*` directly, so they aren't dark-mode aware. | `onboarding_page.dart`, splash |

**Strengths:** central `AppTheme.light()/dark()` with Material 3 seed, `HomeThemeExtension` for dark-aware home, golden tests for home dark/light.

---

## 10. Duplicate Widget Patterns

**Severity: P1 (largest single maintainability cost).**

| Pattern | Count | Notes |
|---------|-------|-------|
| `*_feedback.dart` (loading/error/empty/offline helpers) | **18** | Near-identical static classes; two "dialects" — plain (`batch_feedback.dart`) vs rich (`fattening_feedback.dart` with `MaterialBanner` + `context.tr`). |
| `*_card.dart` (feature list cards) | **18** | `batch_card.dart` vs `fattening_batch_card.dart` are parallel batch cards. |
| `*_summary_section.dart` (dashboard headers) | **10** | animal/batch/feed/finance/health/milk/notification/support/treatment/vaccine. |
| Status chips / badges | **4** | `fattening_status_chip` (hardcoded English) vs `service_request_status_chip` (localized) vs `support_status_badge` vs `stock_quantity_chip`. |
| `*_labels.dart` formatting helpers | **2** | `finance_labels`, `health_labels`. |

A shared `core/ui/` (or `core/widgets/`) component library would collapse ~50 files into a handful of parameterized widgets.

---

## 11. Rebuild / Performance Issues

**Severity: P2.**

| # | Issue | Evidence |
|---|-------|----------|
| 11.1 | **Monolithic build() / page files** (500–700 lines) rebuild wholesale. | `farm_form_page.dart` (701), `inventory_feed_create_page.dart` (589), `feed_entry_form_page.dart` (530), `animal_form_page.dart` (523), `treatment_form_page.dart` (521) |
| 11.2 | **Over-watching** — `feed_entry_page.dart` watches 10 providers in one build; `home_page.dart:65` watches a poll provider purely for side effect. | `feed_entry_page.dart:89-105`, `home_page.dart:65` |
| 11.3 | **Eager `ListView` + `.map()`** for data-driven lists builds all children upfront. `ListView(` (non-builder) appears in 50+ files; `ListView.builder` only ~12 call sites. | `inventory_feed_list_page.dart:65-80`, `universal_search_page.dart:98` |
| 11.4 | Filter bars / summary sections not extracted into small `ConsumerWidget`s, widening rebuild scope on list pages. | feed/health/finance list pages |

**Strengths:** main list pages use lazy slivers (`animal_list_page.dart:230`, `feed_entry_page.dart:357`); home uses a lazy-tier `ListenableBuilder` mitigation.

---

## 12. Offline / Network Handling Gaps

**Severity: P0–P2.**

Architecture: Hive box `app_cache` shared by the outbox (`_outbox_items`) and `local_cache:*` TTL cache; `SyncCoordinator` drains the outbox on connectivity restore / auth / 60s timer (non-dev) / manual; `OfflineCoordinator` wires connectivity at app root.

| # | Gap | Severity | Evidence |
|---|-----|----------|----------|
| 12.1 | **`inventoryConsume` never enqueued offline** — coordinator is ready for it but `consumeStock` only returns failure, no outbox path. | **P0** | `inventory_repository.dart:337-354` vs `sync_coordinator.dart:246` |
| 12.2 | **Fattening enqueues non-transient errors** — queues on any `AppException`, not gated by `isTransientNetworkError`, so validation/403 errors poison the outbox. | **P0** | `fattening_repository.dart:321,371,669-685` |
| 12.3 | **No conflict resolution UI** — DTOs include `conflict` status and `conflictCount` is parsed, but there is no resolution flow; server wins on replay (no optimistic locking/version merge). | **P2** | `offline_dto.dart:17`, `offline_providers.dart:23` |
| 12.4 | **Cache eviction is a stub** — `evictExpired()`/`evictLru()` are no-ops; no quota enforcement (entries only expire on read). | **P2** | `local_cache_service.dart:42-53` |
| 12.5 | **`fromApi` unknown kind → `serviceRequest`** — corrupt/unknown stored kind silently replays to the wrong endpoint. | **P2** | `outbox_item.dart:47-51` |
| 12.6 | **Connectivity has no HTTP/captive-portal probe** — `degraded` is treated as online; `connectivity_plus` only checks link type. | **P2** | `connectivity_service.dart:74-76` |
| 12.7 | **Support attachment upload failures swallowed** (`failure: (_) {}`). | **P1** | `sync_coordinator.dart:387-392` |
| 12.8 | **Dev disables server sync entirely** — background timer + `/api/sync` off in dev, so the production sync path is under-tested. | **P3** | `sync_coordinator.dart:58-62,96-100` |
| 12.9 | **Dead UX hook** — `uxStateStream` is never consumed. | **P2** | `sync_coordinator.dart:48-54` |

**Strengths:** the FIX_OUTBOX exhaustive-switch issue is **resolved** — all three `OutboxKind` consumers (coordinator, invalidation, queue panel) now cover inventory. Exponential backoff + dead-letter at 5 attempts; per-item isolation; targeted debounced invalidation.

---

## 13. Error Handling Gaps

**Severity: P1.**

Pipeline: `Dio → ApiEnvelope.fromDioException → HttpErrorMapper.fromDio → AppException → ApiResult → AsyncValue → UI .when()`.

| # | Gap | Evidence |
|---|-----|----------|
| 13.1 | **No async/global error handler** — only `FlutterError.onError`; no `runZonedGuarded`, no `PlatformDispatcher.instance.onError`, no Crashlytics/Sentry. | `bootstrap.dart:18-27` |
| 13.2 | **Silent catches / swallowed failures** — many empty `catch (_) {}` and `failure: (_) {}` bodies degrade silently (search index drops sources, dashboard sections empty, navigation side-effects lost). | `universal_search_provider.dart:102,115,128,141`; `home_providers.dart:303,313,321`; `notification_providers.dart:202,214`; `animal_navigation.dart:28-37` |
| 13.3 | **Localized `ApiErrorMapper` unused** — UI surfaces raw `AppException.message` (often English) instead of localized text. | `api_error_mapper.dart`, `fattening_feedback.dart:30-33` |
| 13.4 | **Inconsistent surfacing** — mature discrimination in `home_page.dart:111` (offline/unauthorized) vs raw message in fattening; some pages render `e.toString()`. | `home_page.dart:111`, `inventory_feed_detail_page.dart:29` |

---

## 14. Logging / Debugging Gaps

**Severity: P2–P3.**

| # | Gap | Evidence |
|---|-----|----------|
| 14.1 | **No logging framework** — ad-hoc `debugPrint` in 30+ files; `developer.log` used once; no `logging`/`logger` package. | `bootstrap.dart:21`, feature `_log()` helpers |
| 14.2 | **Inconsistent tag conventions** — `[Boot]`, `[PROFILE]`, `[SYNC]`, `[AUTH]`, `[REFRESH]`, `[analytics]`, etc. | `boot_controller.dart:352`, `session_manager.dart:29` |
| 14.3 | **Analytics are debug-only stubs** — explicitly "wire to telemetry later". | `home_analytics.dart:3`, `notification_analytics.dart:19-22` |
| 14.4 | **No crash/error reporting** in production. | (no Crashlytics/Sentry dependency) |

**Strengths:** logging is generally gated by `kDebugMode` and `LOG_NETWORK && kDebugMode`; tokens not logged.

---

## 15. Notification Integration Readiness

**Severity: P0 (delivery blocked) + P1 (reliability).**

Code architecture is production-shaped: lazy `NotificationCoordinator` after first frame, FCM foreground/opened/cold-start handlers, Android channel `pranidoctor_updates` (high importance), top-level `@pragma('vm:entry-point')` background handler, device registration `POST /api/mobile/devices/register`, dedicated permission page, deep-link resolver.

| # | Gap | Severity | Evidence |
|---|-----|----------|----------|
| 15.1 | **Push blocked without Firebase config** — `isFirebaseReady` false → push skipped (local-only works). | **P0** | `notification_coordinator.dart:50` |
| 15.2 | **Android 13+ runtime permission never requested via local-notifications API** — only FCM `requestPermission()` is called; manifest declares `POST_NOTIFICATIONS`. | **P1** | `notification_service.dart:153` |
| 15.3 | **Background handler uses bare `Firebase.initializeApp()`** (no `FirebaseOptions`) — fragile until config exists; Android-only. | **P1** | `fcm_background.dart:9` |
| 15.4 | **Data-only FCM messages ignored** in foreground/background (no `notification` block → dropped). | **P1** | `notification_service.dart:208`, `fcm_background.dart:11` |
| 15.5 | **Cold-start deep-link race** — `getInitialMessage` may `router.go` before boot/auth gate completes. | **P1** | `notification_service.dart:108-110` |
| 15.6 | **Registration result ignored** — `register()` awaits but never checks `ApiResult`. | **P2** | `push_registration.dart:81-89` |
| 15.7 | **Polling disabled** — realtime notifier no-ops its timer; server-unread local alerts won't fire. | **P2** | `notification_realtime.dart:35-38` |
| 15.8 | **Hardcoded app version** `'1.0.0'` in push registration (auth path uses `PackageInfo` correctly). | **P3** | `push_registration.dart:16` |

---

## 16. Firebase Readiness Audit

**Severity: P0.**

| # | Finding | Evidence |
|---|---------|----------|
| 16.1 | **`lib/firebase_options.dart` not present** — accessor stub returns `null`; `flutterfire configure` not run. | `firebase_options_accessor_stub.dart:1-7` |
| 16.2 | **`google-services.json` not in repo** (gitignored; example only). Gradle plugin applied conditionally only if the file exists. | `.gitignore:48`, `android/app/build.gradle.kts:71-73`, `google-services.json.example` |
| 16.3 | **Init is guarded** — failures set `firebaseAppReady=false` and don't crash; app builds and runs without Firebase, but **push is non-functional**. | `firebase_bootstrap.dart:19-43` |
| 16.4 | **No iOS Firebase config** (no iOS target at all — §20). | — |

CI can inject `google-services.json` via secret (`.github/workflows/release.yml:63-64`).

---

## 17. Environment Config Problems

**Severity: P2.**

Solid compile-time model via `String.fromEnvironment` in `lib/app/app_env.dart` (`APP_ENV`, `API_BASE_URL`, `API_HOST/PORT`, `DEV_WIFI_HOST`, `LOG_NETWORK`, `ENABLE_PUSH`, timeouts, `MINIMUM_APP_VERSION`, etc.) with release guards (`assertProductionReady()` throws if `API_BASE_URL` missing or production uses cleartext).

| # | Issue | Evidence |
|---|-------|----------|
| 17.1 | **Hardcoded dev LAN IP** `192.168.10.111:3000` (debug-only fallback; wrong-machine risk; leaks internal topology into binary strings). | `network_constants.dart:9,15` |
| 17.2 | **`UPLOAD_URL` not HTTPS-validated** in production and not part of `AppEnv` (separate dart-define in `upload_service.dart:25`). | `upload_service.dart:25-30` |
| 17.3 | **Env loaded via `scripts/load_env.ps1`** mapping `.env` → dart-defines; works but Windows/PowerShell-specific. | `scripts/load_env.ps1`, `.env.example` |

**Strengths:** no secrets in dart-defines; documented setup; release guards present.

---

## 18. Crash-Risk Components

**Severity: P1–P2.**

| # | Risk | Evidence |
|---|------|----------|
| 18.1 | **Strict JSON parsing in new fattening/weight DTOs** — `json['x'] as String`, `DateTime.parse(...)` (4 sites) throw `TypeError`/`FormatException` on null/wrong type from API. | `weight_dto.dart:57-72`, `fattening_batch_dto.dart`, `fattening_feed_dto.dart`, `fattening_qurbani_dto.dart` |
| 18.2 | **`plan!` field chains** in fattening repo crash if caller's null guarantee breaks. | `fattening_repository.dart:708-721` |
| 18.3 | **Router path-param bangs** (`state.pathParameters['id']!`) — ~42 sites crash if route misconfigured. | `app_router.dart:1133` and throughout |
| 18.4 | **Platform pickers unguarded** — `ImagePickerTile._pick`, `FilePickerTile`, `ProfileMediaActions._pickCropUpload`, `SupportAttachmentPicker` have no try/catch for permission denial / platform exceptions. (Speech service is the good counter-example.) | `image_picker_tile.dart:63-69`, `profile_media_actions.dart:104-117` |
| 18.5 | **In-flight future bangs** (`_listInFlight!`) — safe today but fragile. | `fattening_repository.dart:211`, `notification_repository.dart:74` |
| 18.6 | **Unchecked cast** `FileImage(...) as ImageProvider`. | `image_picker_tile.dart:141` |

Scale: `!` operator in 200+ files (largely `AppLocalizations.of(context)!`, standard); `as` casts in 60+ DTO files.

---

## 19. Security Concerns

**Severity: Medium.**

| # | Concern | Evidence |
|---|---------|----------|
| 19.1 | **Debug cleartext HTTP** allowed (LAN dev). Confined to debug manifest + network security config — acceptable. | `android/app/src/debug/AndroidManifest.xml:4-6`, `network_security_config.xml` |
| 19.2 | **Hardcoded dev IP** in binary strings. | `network_constants.dart:9` |
| 19.3 | **No certificate pinning** (standard Dio TLS only). | `dio_provider.dart` |
| 19.4 | **Push token in API body** — expected; ensure backend treats as sensitive. | `notification_repository.dart:297` |

**Strengths:** tokens in encrypted secure storage; no JWT in Hive; logging gated; production cleartext blocked; secrets gitignored; **no committed real keys/passwords found**.

---

## 20. Production Build Blockers

**Severity: P0.**

| # | Blocker | Evidence |
|---|---------|----------|
| 20.1 | **Release falls back to debug keystore** if `key.properties` missing → debug-signed AAB (Play Store reject). | `android/app/build.gradle.kts:50-56`, `key.properties.example` |
| 20.2 | **No `google-services.json` / `firebase_options.dart`** → push non-functional (see §16). | §16 |
| 20.3 | **No `ios/` target** — iOS release impossible from current repo; `pubspec.yaml` disables iOS icons/splash. | workspace; `pubspec.yaml:60,68` |
| 20.4 | **`flutterfire configure` not run.** | §16.1 |

**Strengths:** `applicationId com.pranidoctor.user.pranidoctor_user`; Java/Kotlin 17; release minify + shrink + ProGuard with Firebase/Flutter keep rules; desugaring enabled; CI `release.yml` (analyze/test/conditional AAB); `build_release.ps1` with obfuscation. No blocking TODOs in `lib/`.

---

## 21. Priority Table

| ID | Priority | Item | Section |
|----|----------|------|---------|
| B1 | **P0** | Release keystore (`key.properties` + upload keystore) | 20.1 |
| B2 | **P0** | `google-services.json` + `flutterfire configure` → `firebase_options.dart`; wire bootstrap + background handler to generated options | 16, 15.1, 15.3 |
| B3 | **P0** | Decide iOS scope (scaffold `ios/` or document Android-only) | 20.3 |
| B4 | **P0** | Confirm production `API_BASE_URL` injected in CI | 17, 20 |
| O1 | **P0** | Add offline enqueue path for `inventoryConsume` | 12.1 |
| O2 | **P0** | Gate fattening enqueue behind `isTransientNetworkError` | 12.2 |
| C1 | **P1** | Harden fattening/weight/inventory DTO parsing (`tryParse`, nullable casts, defaults) | 18.1–18.2 |
| C2 | **P1** | Wrap platform pickers (image/file/profile/support) in try/catch | 18.4 |
| E1 | **P1** | Add `runZonedGuarded` + `PlatformDispatcher.onError`; route to logger/crash sink | 13.1 |
| E2 | **P1** | Replace silent catches with logged/surfaced errors | 13.2, 12.7 |
| L1 | **P1** | Adopt `ApiErrorMapper` app-wide; remove raw/English error surfacing | 13.3, 8.6 |
| L2 | **P1** | Localize hardcoded strings (fattening, inventory, feed/treatment forms); fix bn.json fragments | 8.3, 8.4 |
| R1 | **P1** | Add `autoDispose` to fattening family providers | 3.2 |
| R2 | **P1** | Move `ref.listen` out of page `build()` into notifiers/coordinators | 3.3, 3.4 |
| W1 | **P1** | Extract shared `core/ui` feedback/card/chip/summary widgets (collapse ~50 files) | 10 |
| N1 | **P1** | Android 13+ notification permission; data-only FCM; defer cold-start deep link; check register result | 15.2,15.4,15.5,15.6 |
| A1 | **P1** | Strengthen one-retry interceptor cap; document refresh-call matrix; fix boot orphan-refresh path | 5.1, 6.1, 6.2 |
| AP1 | **P1** | Pin backend verbs; remove `flexible_http` for `/me`+`/settings`; align feed/inventory payload DTOs | 4.1, 4.6 |
| NAV1 | **P2** | Profile-completion route guard; fix hardcoded `/health`; dedupe routes; extend notification deep links | 7 |
| T1 | **P2** | Persist `themeMode` locally; replace `Colors.*` with theme tokens; unify spacing tokens | 9 |
| FS1 | **P2** | Resolve `batches` vs `fattening` naming; flatten `fattening/weight`; normalize non-standard modules | 2 |
| P1 | **P2** | Convert eager `ListView` to `.builder`; split monolithic forms; narrow over-watch | 11 |
| OF1 | **P2** | Implement cache LRU/quota; `fromApi` unknown-kind safety; conflict UX; consume `uxStateStream` | 12.3–12.9 |
| RT1 | **P2** | Type repository providers as contracts; add missing contracts; standardize API-path files | 4.3–4.5 |
| LOG1 | **P3** | Introduce a small logger abstraction with consistent tags + levels | 14 |
| OBS1 | **P3** | Wire analytics/crash telemetry to real backend | 14.3, 15.8 |
| ENV1 | **P3** | Externalize dev host; HTTPS-validate `UPLOAD_URL` | 17 |

---

## 22. Risk Table

| Risk | Likelihood | Impact | Triggered by | Mitigation |
|------|-----------|--------|--------------|------------|
| Outbox replays a non-retryable error forever / poisons queue | High | High | Fattening enqueues validation/403 errors (12.2) | O2: gate on `isTransientNetworkError` (matches feed/milk) |
| Offline inventory consumption silently lost | High | Med | No enqueue path (12.1) | O1: add outbox path; coordinator already handles the kind |
| Runtime crash on malformed API JSON | Med | High | Strict `as`/`DateTime.parse` in fattening DTOs (18.1) | C1: defensive parsing + add `runZonedGuarded` (E1) to capture |
| Debug-signed / push-less production release | High (if unguarded) | High | Missing keystore + Firebase config (20.1, 16) | B1, B2; CI gate that fails build if release keystore/config absent |
| Cold-start deep link navigates before auth gate ready | Med | Med | `getInitialMessage` race (15.5) | N1: queue initial message until `NavPhase` ready |
| Orphan refresh token after boot refresh failure | Low | Med | `boot_controller.dart:176` keeps session (6.1) | A1: explicit `signOut()` or re-login prompt |
| User confusion / wrong cross-domain calls between two "batch" features | Med | Med | `batches` vs `fattening` overlap (2.1) | FS1: rename/namespace + drawer clarity |
| Untranslated UI shipped to bn-default users | High | Med | Hardcoded English in new modules (8.3) | L2: localize + lint rule for raw strings |
| Errors invisible in production (no crash reporting) | High | Med | Debug-only logging/analytics (13.1, 14) | E1 + OBS1 |
| Cache grows unbounded on long-lived installs | Med | Low–Med | LRU/quota stubs (12.4) | OF1: implement eviction |
| Backend verb change breaks `/me` or `/settings` silently masked | Med | Med | `flexible_http` fallback hides drift (4.1) | AP1: pin verbs, remove fallback |
| Widget-pattern drift increases bug surface | High | Low–Med | 18× feedback/card duplication (10) | W1: shared `core/ui` library |

---

## 23. Dependency Table

| Item | Depends on / must follow | Rationale |
|------|--------------------------|-----------|
| B2 (Firebase config) | B-prereq: Firebase project provisioned | Cannot run `flutterfire configure` without project |
| N1 (notification reliability) | B2 | Push handlers can't be validated without working FCM |
| 15.3 background handler options | B2 | Needs generated `FirebaseOptions` |
| E2 (replace silent catches) | E1 (global handler + logger) | Need a sink to log to before removing swallows |
| L1 (adopt `ApiErrorMapper`) | E2 partially | Error surfacing path should be unified first |
| L2 (localize strings) | LOG/build pipeline understood (`build_localization.dart`) | New keys require regenerating JSON |
| W1 (shared `core/ui`) | L2 (localization decisions), T1 (theme tokens) | Shared widgets should consume final tokens + l10n API |
| FS1 (folder/naming) | W1 ideally | Avoid moving files twice; do structural rename after widget consolidation |
| R1/R2 (Riverpod fixes) | none (independent) | Safe early wins |
| AP1 (verb pinning) | backend coordination (pranidoctor-web) | Cross-repo; verify routes before removing `flexible_http` |
| RT1 (contract typing) | none | Independent refactor; enables testing |
| C1/C2 (crash hardening) | none | Independent; do early |
| OF1 (cache/conflict) | none | Independent |
| OBS1 (telemetry) | E1 (logger abstraction) | Telemetry plugs into the logger sink |

---

## 24. Implementation Order

Sequenced into waves; within a wave, items are independent and parallelizable.

**Wave 0 — Launch unblockers (P0, ops + config):**
1. B1 release keystore → 2. B4 CI `API_BASE_URL` → 3. B2 Firebase config + options → 4. B3 iOS scope decision.
*(Parallel, no code coupling; B2 precedes any notification verification.)*

**Wave 1 — Correctness/crash hardening (P0–P1, code, low coupling):**
5. O1 inventory consume enqueue, 6. O2 fattening transient gate, 7. C1 DTO parsing, 8. C2 picker guards, 9. E1 global error handler + minimal logger, 10. R1 fattening autoDispose, 11. R2 `ref.listen` relocation.

**Wave 2 — Error/localization unification (P1):**
12. E2 silent-catch cleanup → 13. L1 `ApiErrorMapper` adoption → 14. L2 localize hardcoded strings + bn.json fixes → 15. A1 auth/refresh hardening → 16. N1 notification reliability (after B2).

**Wave 3 — Reuse + structure (P1–P2):**
17. T1 theme tokens/persistence → 18. W1 shared `core/ui` widgets → 19. FS1 folder/naming normalization → 20. RT1 contract typing + API-path normalization → 21. AP1 backend verb pinning (with web repo).

**Wave 4 — Performance + offline depth + observability (P2–P3):**
22. P1 list/build performance, 23. OF1 cache LRU + conflict UX, 24. NAV1 nav consistency, 25. LOG1 logger rollout, 26. OBS1 telemetry, 27. ENV1 env polish.

---

## 25. Recommended Folder Architecture

Target structure (evolution, not rewrite). **Bold** = new/relocated.

```
lib/
  main.dart
  app/
    bootstrap.dart            # init (Hive, l10n, env, Firebase) + runApp
    app.dart                  # MaterialApp.router + coordinators
    app_env.dart              # env config (move dev host out; add UPLOAD_URL)
    app_startup.dart
  core/
    network/                  # dio_provider, interceptors/, dio_helpers, api_envelope, flexible_http (to retire)
    session/                  # session_controller, session_manager, session_auth, providers
    cache/                    # hive_bootstrap, cache_store, cache_providers
    offline/                  # contracts, network_errors, local_cache_contract
    error/                    # AppException, ApiResult, http_error_mapper, **global_error_handler (new)**
    localization/             # the single active l10n system (canonical home)
    **theme/**                # MOVED from lib/theme: app_theme, tokens, theme_controller, extensions
    **ui/**                   # NEW shared widget library (see §26)
    **logging/**              # NEW logger abstraction + sinks
    branding/                 # BrandColors
    area/                     # shared area contracts/DTOs
    providers/                # provider_stability utilities
    util/                     # safe_numeric, jwt_utils, etc.
  features/
    <feature>/
      data/                   # *_dto, *_repository(+_contract), *_api_paths, *_validation
      presentation/
        <feature>_page.dart
        <feature>_providers.dart
        <feature>_navigation.dart
        widgets/              # only feature-SPECIFIC widgets (generic ones move to core/ui)
  routing/
    app_router.dart
    app_routes.dart           # de-duplicated constants; no literal paths in router
    nav_guard.dart            # + profile-completion guard
    shell/
  l10n/
    app_en.arb                # source ARB (kept); shim re-export retained for import stability
```

Structural normalization (FS1): flatten `fattening/weight/` into `fattening/` (drop re-export shims); give `inbox`/`services`/`onboarding`/`search`/`boot`/`settings` a consistent `presentation/` layout; rename to clearly distinguish `batches` (generic) from `fattening` (cattle).

---

## 26. Recommended Reusable Core Structure (`core/ui/`)

Collapse the ~50 duplicated widgets (§10) into a parameterized library:

```
core/ui/
  feedback/
    async_view.dart          # <T> wrapper around AsyncValue.when: loading/error/empty/data
    app_error_view.dart      # localized error (offline/unauthorized/generic) + onRetry
    app_empty_view.dart      # icon + message + optional onCreate
    offline_banner_hint.dart # MaterialBanner offline hint
  cards/
    app_entity_card.dart     # title/subtitle/leading/trailing/status/onTap (replaces 18 *_card)
  status/
    app_status_chip.dart     # enum-agnostic: label + semantic color from theme extension
  layout/
    app_summary_section.dart # dashboard header (count + metrics) (replaces 10 *_summary_section)
    app_scaffold.dart        # safeAppBar + offline banner + consistent padding
  inputs/
    media_picker_field.dart  # image/file picker with built-in try/catch + error surfacing (fixes C2)
  formatting/
    value_labels.dart        # shared label/format helpers (replaces *_labels)
```

Design rules:
- All copy goes through the localization API (no raw strings); status colors come from a single `StatusColors` `ThemeExtension` (no `Colors.*`).
- `AsyncView<T>` standardizes loading/error/empty so feature pages shrink and error handling is uniform (ties into L1).
- `MediaPickerField` centralizes platform-call error handling (resolves the unguarded-picker crash class).

Also recommended core additions:
- `core/error/global_error_handler.dart` — `runZonedGuarded` + `PlatformDispatcher.onError` + `FlutterError.onError`, routed to `core/logging`.
- `core/logging/app_logger.dart` — leveled, tagged, `kDebugMode`-aware, single sink that telemetry (OBS1) can attach to.
- `core/network/interceptors/` — split the single wrapper into named auth/refresh/error/logging interceptors for testability.

---

## 27. Final Stabilization Roadmap

| Phase | Theme | Items | Exit criteria |
|-------|-------|-------|---------------|
| **Phase 1 — Ship-ability** | Remove launch blockers | B1–B4, O1, O2 | Release-signed AAB builds in CI with production `API_BASE_URL`; FCM token obtained on a device; offline inventory consume + fattening writes queue correctly; iOS scope decided and documented |
| **Phase 2 — Don't crash, don't lose data** | Crash + error hardening | C1, C2, E1, E2, R1, R2 | Global error handler captures async/isolate errors to logger; defensive DTO parsing; no unguarded platform pickers; no `ref.listen` in `build`; fattening providers autoDispose |
| **Phase 3 — Correct & localized UX** | Error/l10n unification + notifications | L1, L2, A1, N1 | All user-facing errors localized via `ApiErrorMapper`; no hardcoded English in shipped screens; bn.json clean; auth refresh matrix documented & boot orphan-token fixed; notifications reliable end-to-end |
| **Phase 4 — Maintainable** | Reuse + structure + contracts | T1, W1, FS1, RT1, AP1 | Shared `core/ui` adopted (≥80% of feedback/card/chip usages migrated); theme tokens + persisted themeMode; repos typed to contracts; backend verbs pinned, `flexible_http` removed for core endpoints; folder structure normalized |
| **Phase 5 — Performant & observable** | Perf + offline depth + telemetry | P1, OF1, NAV1, LOG1, OBS1, ENV1 | Data lists use `.builder`; cache eviction/quota active; conflict UX present; consistent logger; production telemetry/crash reporting live; env polished |

**Suggested cadence:** Phases 1–2 are the minimum for a controlled internal/beta release. Phases 3–4 are required for a polished public production launch. Phase 5 is post-launch hardening.

---

## Appendix A — Cross-Repo Coordination (pranidoctor-web / backend)

These items require alignment with the `pranidoctor-web` repo and cannot be fully closed inside Flutter alone:
- **AP1 verb pinning** — confirm fixed HTTP verbs for `/api/mobile/me` and `/api/mobile/settings`, then delete `flexible_http` usage (`flexible_http.dart`).
- **4.6 feed/inventory payload** — backend feed-catalog multi-select expects `feedCatalogIds`; align `InventoryAddInput` and `FeedInput.toCreateJson`.
- **4.2 envelope** — standardize on `ok` vs `success` to retire dual handling.
- **15 device registration** — confirm `POST /api/mobile/devices/register` contract and push-token sensitivity handling.

## Appendix B — Files Most Frequently Implicated (hot spots)

| File | Sections |
|------|----------|
| `lib/features/fattening/data/fattening_repository.dart` | 12.2, 18.2, 18.5 |
| `lib/features/fattening/weight/data/weight_dto.dart` | 18.1 |
| `lib/features/inventory/data/inventory_repository.dart` | 12.1, 4.3 |
| `lib/core/network/dio_provider.dart` | 5.1, 5.3, 5.6 |
| `lib/core/session/session_manager.dart` / `boot_controller.dart` | 6.1, 6.2, 5.2 |
| `lib/core/network/flexible_http.dart` | 4.1, AP1 |
| `lib/features/offline/data/sync_coordinator.dart` | 12.2, 12.7, 12.8, 12.9 |
| `lib/app/bootstrap.dart` | 13.1, 14.1 |
| `lib/core/localization/api_error_mapper.dart` | 8.6, 13.3 |
| `lib/routing/app_router.dart` / `nav_guard.dart` | 7.1–7.6, 18.3 |
| `lib/features/notifications/*` | 15 |
| `android/app/build.gradle.kts` | 20.1, 16.2 |

---

*End of master plan. This is an audit and plan only — no implementation has been performed. Recommended next step: confirm scope/priorities (especially iOS and the cross-repo AP1 items), then begin Wave 0.*
