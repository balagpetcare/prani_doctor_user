# Home black screen fix

**Date:** 2026-05-31  
**Scope:** `pranidoctor_user` — GoRouter shell, Home dashboard, bottom navigation

---

## 1. Root cause

The Home tab showed a **blank/black body** while the bottom navigation remained visible. Three compounding issues:

| # | Root cause | Symptom |
|---|------------|---------|
| 1 | **Shell stack corruption** — bottom nav always called `goBranch(index, initialLocation: true)` and drawer used **`goBranch` + `context.go` in the same frame** | Indexed stack desynced; Home branch navigator rendered an empty route |
| 2 | **Unsafe shell jumps from Home header** — `context.go('/inbox')` / `context.go('/settings/profile')` without coordinating shell branch index | Router location and active branch diverged; returning to Home left an empty branch frame |
| 3 | **No Home error boundary** — a thrown build error in a dashboard section (header, lazy sliver, provider) produced an empty/black subtree in release | Bottom nav visible, Home body empty |

Secondary factors:

- `Scaffold.of(context).openDrawer()` threw when the widget tree was disrupted after navigation
- No structured navigation logging to diagnose route enter/exit

---

## 2. Navigation flow (fixed)

```
Bottom nav tap
  → ShellNavigation.selectTab()
       same tab  → goBranch(index, initialLocation: true)   // reset branch root
       other tab → goBranch(index)                           // preserve branch stack
  → post-frame recoverShellIfNeeded() if location desynced

Drawer tab change
  → ShellNavigation.selectTab() first
  → router.go(route) only if matchedLocation != target

Home header inbox
  → ShellNavigation.goShellRoot('/inbox')

System back from feature hub
  → ShellNavigation.goShellRoot('/home')
```

### Diagnostic logs (debug builds)

| Tag | Meaning |
|-----|---------|
| `NAVIGATION_START` | `go` / `push` / `replace` / `shell-tab` / `system-back` began |
| `NAVIGATION_END` | Action completed (or `success=false`) |
| `ROUTE_ENTER` | Navigator pushed a route |
| `ROUTE_EXIT` | Navigator popped/replaced/removed a route |
| `HOME_REBUILD` | HomePage build generation |

---

## 3. Provider flow

```
HomePage.build
  → watch dashboardProvider (persisted, cache-first)
  → loading + cache  → show dashboard body (stale-while-revalidate)
  → loading, no cache → HomePageSkeleton
  → error            → _HomeErrorView with Retry
  → data null        → HomeLoadFailureView ("ডেটা লোড করা যায়নি")
  → data ok          → _HomeDashboardBody

_HomeDashboardBody
  → wrapped in AppErrorBoundary → HomeLoadFailureView on section crash
```

Providers that can throw during Home render are guarded at section level (`homeAnimalSummaryProvider`, etc. return empty on catch). Top-level `AppErrorBoundary` catches synchronous build failures.

---

## 4. Crash source

Most likely crash sources before fix:

1. `Scaffold.of(context)` in `HomeAppHeader` when drawer ancestor missing after stack corruption
2. Uncaught exception in lazy-mounted sliver during rebuild after pop
3. Empty `StatefulNavigationShell` branch after double `goBranch` + `go`

---

## 5. Files changed

| File | Change |
|------|--------|
| `lib/core/navigation/navigation_diagnostics.dart` | **New** — NAVIGATION_* / HOME_REBUILD logs |
| `lib/core/navigation/navigation_route_observer.dart` | **New** — ROUTE_ENTER / ROUTE_EXIT |
| `lib/core/navigation/shell_navigation.dart` | **New** — safe tab switch + stack recovery |
| `lib/core/navigation/safe_navigation.dart` | Diagnostic logging on go/push/replace |
| `lib/core/navigation/navigation_service.dart` | Logged system back; shell-safe home return |
| `lib/features/home/presentation/widgets/home_load_failure_view.dart` | **New** — Bengali fallback + Retry |
| `lib/features/home/presentation/home_page.dart` | Error boundary, HOME_REBUILD logs, failure UI |
| `lib/features/home/presentation/widgets/bottom_nav.dart` | `ShellNavigation.selectTab` |
| `lib/features/home/presentation/widgets/drawer_menu.dart` | Remove double goBranch+go |
| `lib/features/home/presentation/widgets/app_header.dart` | Safe drawer + shell inbox navigation |
| `lib/routing/app_router.dart` | `NavigationRouteObserver` on GoRouter |
| `test/navigation/shell_navigation_test.dart` | **New** regression tests |

---

## 6. Regression tests

```bash
cd pranidoctor_user
flutter test test/navigation/shell_navigation_test.dart
flutter test test/profile/ test/integration/location/
```

### Manual QA

1. Home → Search → back → Home shows content (not black)
2. Home → Settings → Profile → Home tab → dashboard visible
3. Drawer → Services → Home tab → dashboard visible
4. Rapid bottom-nav switching (Home ↔ Inbox ↔ Settings) — no blank Home
5. Airplane mode on Home → skeleton or error with Retry, never empty black
6. Filter logcat: `[HOME_REBUILD]`, `[NAVIGATION_START]`, `[ROUTE_EXIT]`

---

## 7. Rollback

Revert commits touching `shell_navigation.dart`, `bottom_nav.dart`, `drawer_menu.dart`, `home_page.dart`, and `app_router.dart` observers. Restore previous `goBranch(index, initialLocation: true)` in bottom nav (not recommended — reintroduces bug).

---

## 8. Requirements checklist

- [x] Home must always render (skeleton, content, or failure UI)
- [x] Failed API cannot create blank screen
- [x] Provider/build crash cannot create blank screen (`AppErrorBoundary`)
- [x] Navigation stack corruption auto-recover (`recoverShellIfNeeded`)
- [x] Safe fallback widget with Bengali message + Retry
