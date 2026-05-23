# USER_APP_05 — Dashboard

**Project:** PraniDoctor User App (`pranidoctor_user`)  
**Module:** Home / Dashboard  
**Status:** COMPLETE  
**Date:** 2026-05-22

---

## Phase 1 — Audit summary

### Already implemented

| Capability | Location |
|------------|----------|
| Home route + shell tab | `HomePage`, `app_router.dart` |
| Dashboard context API + cache | `DashboardRepository` → `/api/mobile/profile/dashboard-context` |
| Summary cards (4 KPIs) | `HomeSummarySection` |
| Quick actions | `HomeQuickActions` |
| Pull-to-refresh + 60s poll | `dashboardProvider`, `dashboardPollProvider` |
| Skeleton + full-page error | `HomeSkeleton`, `_HomeErrorView` |
| Notification badge (shell) | `AppShellScaffold` → `unreadNotificationCountProvider` |
| Boot cache warm | `AppStartup` → `readCachedDashboard()` |

### Gaps fixed this pass

| Gap | Resolution |
|-----|------------|
| Summary blocks entire page while loading | Context paints first; per-section async |
| No activity feed | `HomeActivitySection` + `dashboardActivityProvider` |
| No upcoming appointments list | `HomeAppointmentsSection` + provider |
| No health alerts | `HomeHealthAlertsSection` + vaccine reminders |
| No support / AI tech blocks | `HomeSupportEntry`, `HomeAiTechnicianSection` |
| No greeting | `HomeGreetingHeader` with time-of-day |
| No tappable summary cards | Navigate to farms/animals/inbox |
| Cache not used for first paint | Cached context + silent refresh |
| Quick actions not role-aware | Filter by `DashboardType` |
| No section-level retry | `HomeSectionShell` widget |
| Deep-link refresh | `?refresh=true` on home route |

### Out of scope

| Item | Reason |
|------|--------|
| Wallet summary | No mobile wallet API |
| Promotions API | Use app-config support contacts only |
| Bengali ARB | English strings; l10n-ready keys |
| Standalone dashboard route | Home tab is the dashboard |

---

## API mapping

| Block | Production path | Method |
|-------|-----------------|--------|
| Dashboard context | `/api/mobile/profile/dashboard-context` | GET |
| User profile (boot) | `/api/mobile/me` | GET |
| App config | `/api/mobile/app-config` | GET |
| Farm summary (in context) | `farmSummary` field | — |
| Farms list | Composite via profile + dashboard | GET |
| Appointments | `/api/mobile/service-requests` | GET |
| Notifications | `/api/mobile/notifications` | GET |
| Unread count | `/api/mobile/notifications/unread-count` | GET |
| Health alerts | `/api/mobile/vaccines/reminders` | GET |

---

## State flow

```
Session authed → dashboardProvider
  ├─ cache hit → immediate paint → silent refresh
  └─ network → disk cache write

Independent sections (fail-safe, empty on error):
  dashboardMetricsProvider
  dashboardAppointmentsProvider
  dashboardActivityProvider
  dashboardHealthAlertsProvider

Pull-to-refresh / poll → invalidate sections + dashboard context
```

---

## Cache strategy

| Layer | Key | TTL |
|-------|-----|-----|
| Dashboard context | `dashboard_snapshot` | 7 days (`dashboardTtl`) |
| Service requests | `service_requests_list_snapshot` | profile TTL |
| Notifications | `notifications_list_snapshot` | profile TTL |
| Vaccine reminders | `vaccine_reminders_snapshot` | module TTL |

Cache-first dashboard context for fast first paint; sections reuse existing repository caches.

---

## Verification

```bash
flutter gen-l10n
dart analyze lib/features/home
flutter test test/home/
```
