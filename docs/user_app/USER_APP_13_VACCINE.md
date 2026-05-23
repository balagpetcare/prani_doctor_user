# USER_APP_13 — Vaccine

**Project:** PraniDoctor User App (`pranidoctor_user`)  
**Module:** Vaccination management & reminders  
**Status:** COMPLETE  
**Date:** 2026-05-22

---

## Phase 1 — Audit summary

### Already implemented (~70%)

| Capability | Location |
|------------|----------|
| Schedule list + CRUD | `VaccineRepository`, `VaccineSchedulePage`, `VaccineFormPage` |
| Reminders (overdue/upcoming) | `VaccineReminderPage`, `/api/mobile/vaccines/reminders` |
| Status filters | Schedule page |
| Offline cache + outbox | Repository + `SyncCoordinator` |
| Local notification fallback | `VaccineReminderService` |

### Gaps fixed this pass

| Gap | Resolution |
|-----|------------|
| No vaccine dashboard | `VaccineDashboardPage` at `/vaccines` |
| Lists not cache-first | Cached records → silent refresh |
| No detail screen | `VaccineDetailPage` |
| No history screen | `VaccineHistoryPage` (completed records) |
| No calendar view | `VaccineCalendarPage` (month grid from real records) |
| No summary cards | `VaccineSummarySection` |
| No search / animal filter / date range | Filters on schedule + client-side search/date |
| No navigation helper | `VaccineNavigation` |
| Reminders not cache-first | Cache-first `vaccineReminderProvider` |
| Card navigates to edit | Navigates to detail |

### Out of scope (schema)

| Field | Reason |
|-------|--------|
| dose_no, manufacturer, route, reaction | Not in backend DTO |
| reminder_enabled, notification_id | Local fallback only |
| attachments | Not in API |
| Server-side date/search on list | Client-side filter on loaded records |

---

## API mapping

| UI action | HTTP |
|-----------|------|
| List / schedule | `GET /api/mobile/vaccines` |
| History (completed) | `GET /api/mobile/vaccines?status=COMPLETED` |
| Reminders | `GET /api/mobile/vaccines/reminders` |
| Detail | `GET /api/mobile/vaccines/:id` |
| Create / update / delete | POST / PATCH / DELETE |

## Routes

| Route | Screen |
|-------|--------|
| `/vaccines` | Dashboard |
| `/vaccines/schedule` | Schedule |
| `/vaccines/history` | History |
| `/vaccines/calendar` | Calendar |
| `/vaccines/reminders` | Reminders |
| `/vaccines/create` | Create form |
| `/vaccines/:id` | Detail |
| `/vaccines/:id/edit` | Edit form |

## Verification

```bash
flutter gen-l10n
dart analyze lib/features/vaccine lib/routing/app_router.dart
flutter test test/vaccine/
```
