# Home ANR / freeze investigation

**Date:** 2026-05-31  
**Scope:** `pranidoctor_user` — Home tab, dashboard providers, profile/farm/notification cascade  
**Symptom:** Android ANR dialog (“Prani Doctor isn't responding”), skeleton loaders never resolving

---

## 1. Root cause

Multiple compounding issues produced **indefinite loading** and **main-thread pressure**, not a single crash:

| # | Root cause | Symptom |
|---|------------|---------|
| 1 | **`dashboardProvider` could stay in `AsyncLoading` forever** when `build()` awaited a hung network/deduped request with no cache | Full-screen skeleton never replaced |
| 2 | **No UI-level skeleton escalation** — `HomePage` showed `HomePageSkeleton` with no max duration | Users stuck on shimmer past Dio timeouts if provider never settled |
| 3 | **Heavy synchronous JSON hydration on UI thread** — cached animal list parsed with `.map(AnimalProfile.fromJson)` on main isolate | Frame drops / ANR on large farms |
| 4 | **Dashboard metrics fan-out** — `_loadMetrics` fired 3 sequential API calls without per-call timeout guards | Long blocking load phase before sections render |
| 5 | **Section providers rethrew errors** (`homeHealthTasksProvider`, `homeDoctorsPreviewProvider`) | Section rebuild errors; combined with lazy slivers increased rebuild churn |
| 6 | **Profile auth recovery loop risk** — `mobileMeProvider` called `ref.invalidateSelf()` on every 401 without a cap | Potential recursive provider refresh during home pull-to-refresh |

Secondary (already mitigated in [home-black-screen-fix.md](./home-black-screen-fix.md)): shell navigation desync causing blank home body.

---

## 2. Audit summary

### HomePage / DashboardScreen

- `HomePage` watches `dashboardProvider`, `homeStateProvider`, `dashboardPollProvider`.
- Loading branch now uses `HomeSkeletonTimeoutGuard` (12s max) → Bengali retry UI.
- `_HomeDashboardBody` wrapped in `AppErrorBoundary` → `HomeLoadFailureView`.

### Providers (Riverpod, not ChangeNotifier)

| Provider | Risk found | Mitigation |
|----------|------------|------------|
| `dashboardProvider` | Hung load, no degraded fallback | `_loadWithFallback`, `DashboardContext.degraded()`, timeouts |
| `dashboardMetricsProvider` | 3 sequential calls, no timeout | Per-call `runWithTimeout` + partial metrics |
| `mobileMeProvider` | `invalidateSelf` loop on auth | Max 2 auth recovery attempts |
| `farmListProvider` | Invalidates dashboard on save (expected) | Unchanged; guarded by `AsyncRefreshGuard` |
| `notificationListProvider` | Silent refresh only when manual refresh active | Unchanged (by design) |

### Project-wide pattern search

| Pattern | Home impact |
|---------|-------------|
| `setState(` | Only drawer expand in `drawer_menu.dart` — not a rebuild loop |
| `invalidate(` / `refresh(` | Debounced via `scheduleInvalidateDashboardSections` (800ms) |
| `FutureBuilder` / `StreamBuilder` | **None** in codebase |
| `Timer.periodic` | Dashboard poll **disabled**; sync coordinator unrelated to home mount |
| `while(` | No home-path infinite loops |

---

## 3. Diagnostics added

Debug log tags (filter logcat: `HOME_`):

| Tag | When |
|-----|------|
| `HOME_INIT` | `HomePage.initState` |
| `HOME_BUILD` | Every `HomePage.build` |
| `HOME_REBUILD` | Build generation / error boundary |
| `HOME_API_START` | Dashboard/metrics/repository request start |
| `HOME_API_SUCCESS` | Request completed |
| `HOME_API_FAILURE` | Timeout or error |
| `HOME_PROVIDER_REFRESH` | Dashboard reload/refresh/section invalidate |
| `HOME_SKELETON_TIMEOUT` | Skeleton guard fired |

Files: `home_performance_diagnostics.dart`, `api_timeout.dart`, `navigation_diagnostics.dart` (existing `HOME_REBUILD` kept).

---

## 4. Protections implemented

### API layer

- `HomeApiGuard`: 15s dashboard timeout, 2 retries, 400ms backoff.
- `DashboardRepository`: timeout wrapper, retry, isolate cache parse.
- `runWithTimeout` helper with structured logging.

### UI layer

- **`HomeSkeletonTimeoutGuard`**: never endless skeleton; shows **“ডেটা লোড করতে সমস্যা হয়েছে”** + **“পুনরায় চেষ্টা করুন”** (via `dashboardRetry` l10n on button).
- **`DashboardContext.degraded()`**: home shell renders when network + cache both fail (non-auth).
- **`AppErrorBoundary`**: dashboard body crash → same Bengali fallback.

### Performance

- **`parseAnimalProfilesOffMain`**: animal cache lists ≥24 items parsed via `compute`.
- **`parseDashboardContextOffMain`**: dashboard cache hydration off UI thread.

---

## 5. Files changed

| File | Change |
|------|--------|
| `lib/features/home/presentation/home_performance_diagnostics.dart` | **New** — HOME_* logs |
| `lib/features/home/data/home_api_guard.dart` | **New** — timeout/retry constants |
| `lib/core/util/api_timeout.dart` | **New** — timeout + logging wrapper |
| `lib/core/util/json_isolate.dart` | **New** — isolate parsers |
| `lib/features/home/data/dashboard_repository.dart` | Timeout, retry, isolate cache read |
| `lib/features/home/data/dashboard_context_dto.dart` | `DashboardContext.degraded()` |
| `lib/features/home/presentation/home_providers.dart` | Fallback load, metrics timeouts, refresh logs |
| `lib/features/home/presentation/home_page.dart` | Skeleton guard, diagnostics, crash boundary copy |
| `lib/features/home/presentation/widgets/home_skeleton_timeout_guard.dart` | **New** |
| `lib/features/home/presentation/widgets/home_load_failure_view.dart` | Updated Bengali message |
| `lib/features/home/presentation/providers/home_section_providers.dart` | Empty fallback on section errors |
| `lib/features/home/presentation/home_navigation.dart` | Provider refresh logging |
| `lib/features/profile/presentation/profile_providers.dart` | Auth recovery attempt cap |
| `lib/features/animals/data/animal_repository.dart` | Isolate cache parse |
| `test/home/home_anr_guard_test.dart` | **New** regression tests |

---

## 6. Profiling notes

Expected ANR sources addressed:

| Source | Mitigation |
|--------|------------|
| Blocked UI thread (JSON) | Isolate parsing for large animal cache |
| Long async load without UI fallback | 12s skeleton guard + 15s provider timeout |
| Provider refresh storm | Debounced section invalidation; profile auth cap |
| Memory spikes from eager sections | Existing lazy slivers (`HomePageController.lazyTier`) retained |

**Recommended manual profiling** (Android Studio):

```bash
cd pranidoctor_user
flutter run --profile
# DevTools → Performance: verify Home first frame < 16ms after cache hit
# DevTools → CPU: confirm no long `AnimalProfile.fromJson` on UI thread for large lists
```

Logcat during repro:

```text
adb logcat | findstr /I "HOME_ NAVIGATION_"
```

---

## 7. Regression tests

```bash
cd pranidoctor_user
flutter test test/home/home_anr_guard_test.dart
flutter test test/home/home_page_test.dart
flutter test test/navigation/shell_navigation_test.dart
```

### Manual QA

1. Airplane mode, clear app data → Home shows skeleton ≤12s then Bengali retry (not ANR).
2. Slow backend (throttle 20s) → skeleton timeout OR degraded dashboard shell.
3. Large animal cache (25+ animals) → no ANR on cold home open.
4. Pull-to-refresh ×5 rapidly → no freeze; `[HOME_PROVIDER_REFRESH]` debounced.
5. Kill backend mid-load → cached or degraded home, not infinite shimmer.

---

## 8. Requirements checklist

- [x] No screen waits forever (skeleton guard + provider timeout)
- [x] API calls: timeout, retry limit, fallback state
- [x] Home renders on API/internet/backend failure
- [x] Never endless skeleton
- [x] Heavy JSON off UI thread where needed
- [x] Crash boundary with Bengali message + retry
- [x] Structured HOME_* diagnostics
- [x] Investigation report + regression tests

---

## 9. Rollback

Revert commits touching `home_providers.dart`, `home_page.dart`, `home_skeleton_timeout_guard.dart`, and `dashboard_repository.dart`. Restores prior behavior but reintroduces skeleton hang risk on slow/hung dashboard loads.
