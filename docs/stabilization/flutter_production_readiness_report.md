# Flutter Production Readiness Report — Prani Doctor User App

> **Date:** 2026-05-29  
> **Repo:** `pranidoctor_user`  
> **Scope:** Final stabilization audit + safe hardening pass  
> **Analyzer:** `flutter analyze` — **0 errors** on changed modules; project-wide pre-existing warnings only

---

## Executive summary

The app has a **solid production foundation**: feature-first architecture, unified API/error layer, global error zones, Riverpod with targeted `autoDispose`, JSON localization (Bengali default), offline outbox, and structured logging with redaction. **Release to Play Store is blocked primarily by Firebase/push configuration** (`google-services.json`, FlutterFire options). Functional stability is **good for beta/internal testing** with HTTPS API; **not yet fully production-hardened** for push, crash analytics, or large-scale offline cache growth.

### Production readiness score: **74 / 100**

| Dimension | Score | Weight | Weighted |
|-----------|------:|-------:|---------:|
| Architecture & maintainability | 82 | 15% | 12.3 |
| State management (Riverpod) | 78 | 10% | 7.8 |
| API / offline / errors | 80 | 15% | 12.0 |
| UI/UX & localization | 76 | 10% | 7.6 |
| Performance & startup | 72 | 15% | 10.8 |
| Security | 70 | 15% | 10.5 |
| Observability (logging/crash) | 68 | 10% | 6.8 |
| Production build & release | 58 | 10% | 5.8 |
| **Total** | | **100%** | **73.8 → 74** |

---

## Audit findings (10 areas)

### 1. Remaining crash risks

| Severity | Finding | Location / notes |
|----------|---------|------------------|
| **HIGH** | ~244 force-unwraps (`!`) in `lib/features/**/presentation/` | Gradual migration to null-safe patterns |
| **HIGH** | DTO `as` casts on API payloads | Many `*_dto.dart` files — wrong schema → cast crash |
| **MEDIUM** | Providers `failure: (e) => throw e` on cache miss | `inventory_providers.dart`, farm/feed lists — hard `AsyncError` |
| **MEDIUM** | `vaccine_calendar_page.dart:157` — `day.records.first` | Guarded at grid level; edge case if data empty |
| **LOW** | Route `extra` unchecked cast | `app_router.dart` AI chat `extra as String?` |
| **FIXED** | Boot `jsonDecode` uncaught | `localization_loader.dart` — SafeParse + fallback to EN |
| **FIXED** | Feed catalog asset `jsonDecode` | `feed_catalog_repository.dart` — try/catch → `[]` |
| **FIXED** | `setState` after dispose on OTP verify | `otp_page.dart` — `mounted` guards |
| **FIXED** | State mutation during `build` | `fattening_log_feed_page.dart` — post-frame `setState` |

### 2. Performance bottlenecks

| Severity | Finding | Mitigation |
|----------|---------|------------|
| **HIGH** | 22 sequential cache warmups at startup (was blocking microtask) | **FIXED:** `StartupCacheWarmup` + post-frame + `SafeAsync` |
| **MEDIUM** | Raw `Image.network` in lists without decode caps | **FIXED:** `AppNetworkImage` on farm card/detail/profile |
| **MEDIUM** | Home dashboard watches multiple providers | Acceptable at page level; consider `.select` later |
| **MEDIUM** | Hive snapshots without TTL/eviction | Documented; prune in Phase 2 |
| **LOW** | `ApiMethodCache` unbounded | **FIXED:** cap at 128 entries |
| **FIXED** | Image cache unbounded | `ImageCacheConfig` — 200 images / 50 MB |
| **FIXED** | `initializeDateFormatting` sequential | Parallel with localization in `bootstrap.dart` |

### 3. Security issues

| Severity | Finding | Status |
|----------|---------|--------|
| **HIGH** | No `google-services.json` / FlutterFire options stub | **OPEN** — push/analytics blocked |
| **MEDIUM** | No TLS certificate pinning | **OPEN** — standard Dio trust store |
| **MEDIUM** | `assertProductionReady` does not validate Firebase | **PARTIAL** — release log when push enabled without Firebase |
| **LOW** | ~430 Bengali keys still English in `bn.json` | Content/i18n quality, not auth risk |
| **OK** | Tokens in `FlutterSecureStorage` | |
| **OK** | Network logs redact URIs; debug-only HTTP logs | `LoggingInterceptor` + `LogRedactor` |
| **OK** | Release requires HTTPS + explicit `API_BASE_URL` | `app_env.dart` |

### 4. Unstable providers

| Severity | Finding | Status |
|----------|---------|--------|
| **MEDIUM** | Long-lived `FutureProvider.family` without `autoDispose` | **FIXED:** service request detail/timeline, doctor detail, support ticket |
| **OK** | Fattening detail providers use `autoDispose.family` | |
| **OK** | Filter `StateProvider`s scoped with `autoDispose` | Prior Riverpod pass |
| **LOW** | `fatteningBatchListProvider` still permanent family | OK while list page mounted |

### 5. Unsafe async usage

| Severity | Finding | Status |
|----------|---------|--------|
| **MEDIUM** | ~56 `unawaited(` cache refreshes | Mostly OK; startup now uses `SafeAsync` |
| **MEDIUM** | `Future.microtask` in forms without `mounted` | **PARTIAL** — OTP fixed; others remain |
| **OK** | `SafeAsync` / global zone handler | This pass |

### 6. Missing disposals

| Severity | Finding | Status |
|----------|---------|--------|
| **LOW** | Most forms dispose controllers | Spot-check OK in audited files |
| **OK** | OTP / fattening log feed dispose `TextEditingController` | |

### 7. Memory leaks

| Severity | Finding | Status |
|----------|---------|--------|
| **MEDIUM** | Hive cache grows without TTL | **OPEN** |
| **MEDIUM** | Non-autoDispose family providers | **REDUCED** this pass |
| **FIXED** | `ApiMethodCache` static map | Capped at 128 |

### 8. Large widget rebuilds

| Severity | Finding | Status |
|----------|---------|--------|
| **MEDIUM** | `home_page` watches full dashboard state | Defer `.select` optimization |
| **OK** | `inventoryRecentFeedLogsProvider` uses `.select` | |
| **OK** | List `itemBuilder`s generally take DTO props | |

### 9. Navigation risks

| Severity | Finding | Status |
|----------|---------|--------|
| **OK** | `nav_guard.dart` avoids redirect loops | |
| **OK** | `GoRouter.errorBuilder` → `AppRouteErrorPage` | Prior UI pass |
| **OK** | `SafeNavigation` / `SafePop` | Prior passes |
| **MEDIUM** | Guest entry `null` redirect while onboarding loads | UX stall, not crash |

### 10. Production build blockers

| Blocker | Status |
|---------|--------|
| Missing `google-services.json` | **BLOCKER** for FCM release |
| FlutterFire `firebase_options.dart` stub | **BLOCKER** for Crashlytics/Analytics |
| `API_BASE_URL` + HTTPS enforced in release | **OK** |
| Android `minSdk` via Flutter default | **OK** |
| No `cached_network_image` package | **Non-blocker** — `AppNetworkImage` uses decode caps |
| Bengali translation coverage (~33% keys = English) | **Quality blocker** for BN-first UX |

---

## Completed stabilization items (cumulative)

### Architecture & core (Phase 1)
- Standardized `lib/core`, `lib/shared`, `lib/config`, `lib/services`, barrel exports
- Shared widgets: `AppLoadingView`, `AppErrorView`, `AppEmptyView`, `AppAsyncView`, `AppStatusChip`
- Removed dead `token_refresh.dart`

### API layer
- Dio interceptor stack (auth, refresh, logging, error, connectivity)
- `TokenStorage`, `CancelToken` support, safe multipart
- `NetworkErrorType`, `apiFailureMessage`

### Riverpod
- `OtpFlowNotifier` → `AutoDisposeNotifier`
- `autoDispose` on fattening detail, search, filters, upload progress
- `.select()` on area locale, inventory feed records
- Universal search debounce

### UI/UX
- Global `ThemeData` tokens (inputs, buttons, dialogs, sheets)
- `AppPrimaryButton`, `AppTextField`, `AppScaffold`, `AppConfirmDialog`
- Dark-mode `AppStatusColors`, overflow/keyboard fixes

### Localization
- Bengali default (`LocaleStorage`, `MaterialApp.locale`)
- Live language switch (no restart)
- 7 new keys for inventory/feed-catalog; `UserErrorMapper` path

### Error handling & logging (this pass)
- `GlobalErrorHandler` — zone + Flutter + platform + `ErrorWidget.builder`
- `AppLog` + `LogRedactor` + reporter interfaces (Crashlytics/Analytics stubs)
- `UserErrorMapper`, `SafeParse`, `SafeAsync`, `SafeNavigation`
- `AppGracefulErrorWidget`, `AppRouteErrorPage`, `AppErrorBoundary`

### Production hardening (this pass)
- **Startup:** parallel locale + intl init; `ImageCacheConfig`; post-frame cache warmup
- **Caching:** `StartupCacheWarmup` with logged `SafeAsync` warmups
- **Images:** `AppNetworkImage` on farm + profile media
- **Providers:** `autoDispose` on service request, doctor, support ticket detail
- **Crash fixes:** localization loader, feed catalog asset, OTP mounted, fattening log feed build side-effect

---

## Safe fixes applied (this session)

| File | Change |
|------|--------|
| `lib/app/bootstrap.dart` | Parallel init, image cache limits, Firebase push audit log |
| `lib/app/app_startup.dart` | Post-frame `StartupCacheWarmup` (non-blocking) |
| `lib/core/startup/image_cache_config.dart` | **NEW** — 200 / 50MB cache |
| `lib/core/startup/startup_cache_warmup.dart` | **NEW** — safe background warmups |
| `lib/core/localization/localization_loader.dart` | Safe JSON load + BN→EN fallback |
| `lib/features/feed_catalog/data/feed_catalog_repository.dart` | Safe asset catalog load |
| `lib/features/auth/presentation/otp_page.dart` | `mounted` after async verify |
| `lib/features/fattening/presentation/fattening_log_feed_page.dart` | Post-frame default animal; localized errors |
| `lib/core/network/flexible_http.dart` | `ApiMethodCache` max 128 |
| `lib/features/service_requests/.../service_request_repository.dart` | `autoDispose` detail providers |
| `lib/features/doctors/data/doctor_repository.dart` | `autoDispose` detail |
| `lib/features/support/presentation/support_providers.dart` | `autoDispose` ticket |
| `lib/shared/widgets/app_network_image.dart` | **NEW** — safe network images |
| `lib/features/farm/.../farm_card.dart`, `farm_detail_page.dart` | Use `AppNetworkImage` |
| `lib/features/profile/.../profile_media_image.dart` | Delegate to `AppNetworkImage` |

---

## Remaining risks (prioritized)

### P0 — Release blockers
1. Add **FlutterFire** + `google-services.json` for Android FCM.
2. Wire **`FirebaseCrashlyticsReporter`** in `bootstrap` (interface ready).
3. Confirm **`API_BASE_URL`** HTTPS in CI release builds.

### P1 — High (pre–public launch)
4. Reduce **force-unwraps** in presentation (top files: `area_picker`, `profile_address`, `home_card`).
5. Replace **`failure: (e) => throw e`** in list providers with cached-empty or offline fallbacks.
6. Expand **`bn_curated.json`** / translation pipeline (~430 English-fallback keys).
7. **Hive TTL** or snapshot pruning for largest keys (dashboard, animals, farms).

### P2 — Medium
8. Adopt **`AppNetworkImage`** on remaining `Image.network` sites (`support_attachment_viewer`, `home_card` internal).
9. **`AppPrimaryButton` / `AppTextField`** migration on top 10 form pages.
10. Certificate **pinning** for API if threat model requires.
11. Provider **`.select`** on home dashboard consumers.
12. Consolidate **ProfileLanguagePage** vs **SettingsLanguagePage** offline behavior.

### P3 — Polish
13. OTP / form `Future.microtask` → `mounted` guards (bulk pass).
14. DTO parsing via **`SafeParse.tryParse`** for new endpoints.
15. Golden tests + overflow fixes (pre-existing test failures).

---

## Recommended next phase

### Phase A — Release infrastructure (1–2 weeks)
- FlutterFire CLI: `google-services.json`, `firebase_options.dart`
- Enable `FirebaseCrashlyticsReporter` + symbol upload (`build/debug-info/`)
- `assertProductionReady` extension: fail release if `ENABLE_PUSH=true` and Firebase null
- Play Console internal testing track

### Phase B — Stability & i18n (2–3 weeks)
- Mechanical pass: top 50 crash-prone `!` sites
- Provider throw → graceful offline UI pattern
- `dart run tool/i18n/build_localization.dart` + expand `bn_curated.json`
- Hive cache policy document + TTL for 5 largest keys

### Phase C — Performance & UX polish (ongoing)
- `cached_network_image` evaluation vs current `AppNetworkImage`
- Home dashboard `.select` rebuild optimization
- Remaining form/widget standardization

---

## Verification checklist

| Check | Command / action | Expected |
|-------|------------------|----------|
| Analyzer | `flutter analyze` | 0 errors |
| Release build | `flutter build apk --release --dart-define=API_BASE_URL=https://...` | Succeeds |
| Cold start | Launch offline | BN UI, cached data, no crash |
| Language switch | Settings → বাংলা / English | Instant, no restart |
| OTP verify | Background app during verify | No `setState` exception |
| Farm list images | Scroll farm cards | Placeholder on bad URL, no OOM |
| Invalid route | Deep link typo | `AppRouteErrorPage` |

---

## Reference documents

- [flutter_stabilization_master_plan.md](./flutter_stabilization_master_plan.md) — full audit + phase log
- [FINAL_LANGUAGE_AUDIT.md](../localization/FINAL_LANGUAGE_AUDIT.md) — Bengali coverage metrics
- [STORE_RELEASE.md](../STORE_RELEASE.md) — release checklist (Crashlytics noted as blocked)

---

*Report generated after final stabilization audit. Re-run audit after Phase A Firebase wiring to target score **85+**.*
