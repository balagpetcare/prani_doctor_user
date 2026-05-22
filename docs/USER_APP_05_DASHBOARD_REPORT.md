# USER_APP_05 — Dashboard Report

**Project:** PraniDoctor User App (`pranidoctor_user`)  
**Module:** USER_APP_05_DASHBOARD  
**Status:** COMPLETE  
**Date:** 2026-05-22

---

## Summary

Replaced the Home tab profile stub with a full dashboard fed by `GET /api/mobile/profile/dashboard-context`. Added repository caching, Riverpod state (loading / refresh / error / retry), summary KPI cards, quick actions, safe 60s polling, and offline fallback.

---

## Screens completed

| Screen | Status | Location |
|--------|--------|----------|
| Home | COMPLETE | `lib/features/home/home_page.dart` |
| Summary (KPI grid) | COMPLETE | `widgets/home_summary_section.dart` |
| Quick Actions | COMPLETE | `widgets/home_quick_actions.dart` |

---

## API connected

| Endpoint | Purpose |
|----------|---------|
| `GET /api/mobile/profile/dashboard-context` | Dashboard user + farm summary |
| `GET /api/mobile/service-requests` | Active appointment count (existing repo) |
| `GET /api/mobile/notifications` | Unread notification count (existing repo) |

---

## Providers updated

| Provider | Role |
|----------|------|
| `dashboardProvider` | AsyncNotifier — dashboard context load / reload / refresh |
| `dashboardSummaryProvider` | Composed KPIs (farms, animals, appointments, notifications) |
| `dashboardPollProvider` | Safe 60s background refresh (deduped, session-gated) |
| `dashboardRepositoryProvider` | API-first + Hive disk cache |

---

## Cache strategy

1. **Remote API** — primary source with 1 retry on transient errors  
2. **Disk cache** — `LocalCacheContract.dashboardKey`, TTL 12h  
3. **Cold boot** — non-blocking `readCachedDashboard()` in `AppStartup`  
4. **Offline UI** — banner when serving cached dashboard context

---

## Offline readiness

- Dashboard context cached after successful fetch  
- Network failure falls back to cached snapshot  
- Unauthorized (401/403) does not use stale cache — prompts sign out  
- Appointment/notification counts degrade to 0 on secondary API failure (dashboard still visible)

---

## Files changed

| File | Change |
|------|--------|
| `lib/core/offline/local_cache_contract.dart` | `dashboardKey`, `dashboardTtl` |
| `lib/features/home/data/dashboard_api_paths.dart` | **NEW** |
| `lib/features/home/data/dashboard_context_dto.dart` | **NEW** — DTO/entity mapping |
| `lib/features/home/data/dashboard_repository_contract.dart` | **NEW** |
| `lib/features/home/data/dashboard_repository.dart` | **NEW** |
| `lib/features/home/presentation/home_providers.dart` | **NEW** |
| `lib/features/home/home_page.dart` | Dashboard UI + pull-to-refresh |
| `lib/features/home/presentation/widgets/home_skeleton.dart` | **NEW** |
| `lib/features/home/presentation/widgets/home_summary_section.dart` | **NEW** |
| `lib/features/home/presentation/widgets/home_quick_actions.dart` | **NEW** |
| `lib/app/app_startup.dart` | Warm dashboard cache on boot |
| `lib/l10n/app_en.arb` | Dashboard strings |
| `test/home/dashboard_integration_test.dart` | **NEW** |
| `test/home/home_page_test.dart` | **NEW** |

---

## Pending items

| Item | Notes |
|------|-------|
| Dedicated farm CRUD screens | Quick action routes to profile address setup |
| Dedicated add-animal screen | Routes to Services tab (animals via booking API) |
| Backend `farmCount` field | `totalFarms` derived from `primaryVillageId` (0 or 1) |
| Bangla l10n file | Only `app_en.arb` exists in repo today |
| `/home/ai-chat` nested route | Planned in FLUTTER_REUSE_PLAN, out of scope |

---

## Risks

| Risk | Mitigation |
|------|------------|
| Farm count approximation | Documented; update when backend exposes `farmCount` |
| Secondary KPI APIs slow | Dashboard header loads first; counts may lag briefly |
| Polling while backgrounded | 60s interval + in-flight guard limits duplicate calls |
| AI technician / doctor dashboards | Payload parsed; UI shows general customer layout for v1 |

---

## Manual QA checklist

- [ ] Sign in → Home shows greeting + summary cards  
- [ ] Pull to refresh updates counts  
- [ ] Airplane mode → cached dashboard + offline banner  
- [ ] Restore network → refresh succeeds  
- [ ] Quick action: Create farm → profile address  
- [ ] Quick action: Add animal → services tab  
- [ ] Quick action: View records → inbox tab  
- [ ] Session expiry → unauthorized message + sign out  
- [ ] Background 60s → no duplicate loading spinners  

---

## Tests

| File | Coverage |
|------|----------|
| `test/home/dashboard_integration_test.dart` | DTO parsing, farm summary, auth helpers |
| `test/home/home_page_test.dart` | Summary/quick actions render, skeleton loading |

Run: `flutter test test/home/`
