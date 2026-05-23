# Offline-First Refresh Fix Report

**Project:** `pranidoctor_user`  
**Date:** 2026-05-23  
**Goal:** Stop automatic refresh loops when backend/DB is unavailable

---

## Root causes found

| Source | Behavior when API down | Loop? |
|--------|------------------------|-------|
| `scheduleCacheRevalidate` | Always `invalidateSelf()` after revalidate, even on failure | **Yes (~2s)** |
| `.then((_) => ref.invalidateSelf())` on cache hit | Treatment, milk, health, feed providers | **Yes (per timeout)** |
| `unawaited(refresh(silent: true))` on cache | Dashboard, profile, settings, notifications, animals, etc. | Retries on every invalidation |
| `dashboardPollProvider` | 60s timer | Steady polling |
| `notificationRealtimeProvider` | 30s timer + invalidates unread provider | Steady polling + cascade |
| `DashboardRepository` | 2 network attempts per fetch | Amplified failures |

---

## Fixes applied

### Phase 1–2 — Disable auto refresh

- **Dashboard poll:** timer disabled (offline-first)
- **Notification realtime poll:** timer disabled
- **`AutoRefreshGuard`:** silent/background network refresh allowed **only** during manual refresh (pull-to-refresh, retry button) or resume refresh (60s+ away)
- **`scheduleCacheRevalidate`:** skips when auto refresh disabled; **never** `invalidateSelf()` on failure
- **Removed** `invalidateSelf()` background fetches from treatment, milk, health, feed providers on cache hit
- **Dashboard / notifications / settings / profile:** cache-hit background refresh gated via `scheduleSilentRefresh`

### Phase 3 — Cache TTL

- `LocalCacheContract.dashboardTtl` → **30 minutes**
- `LocalCacheContract.profileTtl` → **30 minutes**
- Added `LocalCacheContract.dataTtl` → **30 minutes**

Existing Hive/disk cache paths unchanged — still serve last known state on failure.

### Phase 4 — Network layer

- Default timeouts: **connect 5s**, **receive 10s** (`network_constants.dart`)
- Dashboard fetch: **max 1 attempt** (was 2)
- Dio interceptor: records `serverReachable` false on timeout/connection/5xx; true on successful responses
- 401 retry remains **single** retry (unchanged)

### Phase 5 — Provider rules

- `AsyncRefreshGuard.guardRefresh(silent: true)` blocks silent refresh unless manual/resume scope active
- Finance/vaccine revalidate callbacks return `bool` (success only invalidates)
- No `invalidateSelf()` inside failed revalidate paths

### Phase 6 — UI

- Global **`OfflineStatusBanner`** in shell: Bengali `অফলাইন মোড — সর্বশেষ সংরক্ষিত তথ্য দেখানো হচ্ছে`
- **Retry** button runs manual refresh (shows cached data underneath, no fullscreen loader storm)
- Home offline hint unchanged for `fromCache` dashboard state

### Phase 7 — App resume

- **`AppLifecycleCoordinator`:** refresh only if app was backgrounded **≥ 60 seconds**

---

## Files changed

### New

- `lib/core/network/auto_refresh_guard.dart`
- `lib/core/network/app_lifecycle_coordinator.dart`
- `lib/core/offline/offline_status_banner.dart`

### Modified (core)

- `lib/core/providers/provider_stability.dart`
- `lib/core/network/dio_provider.dart`
- `lib/core/network/network_constants.dart`
- `lib/core/offline/local_cache_contract.dart`
- `lib/app/app.dart`
- `lib/routing/shell/app_shell_scaffold.dart`
- `lib/l10n/app_en.arb`

### Modified (features)

- `lib/features/home/presentation/home_providers.dart`
- `lib/features/home/presentation/home_navigation.dart`
- `lib/features/home/data/dashboard_repository.dart`
- `lib/features/notifications/notification_realtime.dart`
- `lib/features/notifications/presentation/notification_providers.dart`
- `lib/features/vaccine/presentation/vaccine_providers.dart`
- `lib/features/finance/presentation/finance_providers.dart`
- `lib/features/treatment/presentation/treatment_providers.dart`
- `lib/features/milk/presentation/milk_providers.dart`
- `lib/features/health/presentation/health_providers.dart`
- `lib/features/feed/presentation/feed_providers.dart`
- `lib/features/profile/presentation/profile_providers.dart`
- `lib/features/settings/presentation/settings_providers.dart`

---

## Verification

| Test | Expected |
|------|----------|
| Backend ON → open app | Normal load + cache write |
| Backend OFF | Home/profile stay on cached data |
| Wait 30+ seconds | **No** repeated loading flicker |
| Pull-to-refresh | One refresh attempt; failure keeps cache |
| Retry on banner | Manual refresh only |
| Resume after 60s | Optional single refresh |

Commands:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test test/home/
flutter run -d 192.168.10.107:5555
```

---

## Remaining risks

1. **Other notifiers** (animals, farm, batch, ai, support) still have `unawaited(refresh(silent: true))` on cache — gated by `AutoRefreshGuard` but not all use `scheduleSilentRefresh` yet.
2. **Prod background sync timer** (60s) still runs outside dev — only drains outbox; does not invalidate on failure.
3. **Connectivity flap** can still trigger one sync on reconnect (by design).
4. **Manual test** with backend stopped required to confirm no loop on device.

---

## Retry removed / reduced

- Dashboard repository: 2 → **1** attempt
- Cache revalidate: infinite invalidate loop → **none on failure**
- Treatment/milk/health/feed: immediate invalidateSelf loops → **removed**
- Dashboard poll: 60s → **disabled**
- Notification poll: 30s → **disabled**
