# USER_APP_12 — Health Timeline

**Project:** PraniDoctor User App (`pranidoctor_user`)  
**Module:** Animal health tracking & timeline  
**Status:** COMPLETE  
**Date:** 2026-05-22

---

## Phase 1 — Audit summary

### Already implemented (~75%)

| Capability | Location |
|------------|----------|
| History list + CRUD | `HealthRepository`, `HealthHistoryPage`, `HealthFormPage` |
| Timeline (date-grouped) | `HealthTimelinePage` |
| Detail view | `HealthDetailPage` |
| Search + event-type filter | History page |
| Offline cache + outbox | Repository + `SyncCoordinator` |
| Backend API | `/api/mobile/health/history`, `/timeline` |

### Gaps fixed this pass

| Gap | Resolution |
|-----|------------|
| No health hub / summary | `HealthDashboardPage` at `/health` |
| Lists not cache-first | Cached records → silent refresh |
| No date range / animal filter in UI | From/to pickers + animal dropdown |
| No summary cards | `HealthSummarySection` on dashboard + history |
| No analytics screen | `HealthAnalyticsPage` (derived from real list data) |
| No navigation helper | `HealthNavigation` |
| Timeline missing filters | Shared filter providers |
| Detail lacks delete / treatment link | Delete action + treatment deep link |
| Home quick action → history only | Points to `/health` dashboard |

### Out of scope (schema)

| Field | Reason |
|-------|--------|
| health_score, status, severity | Not in backend DTO |
| temperature, weight, attachments | Not in API |
| disease_id (FK) | Free-text `diseaseName` only |
| prescription_id, doctor | Not in API |
| Dedicated analytics API | Client-side aggregation from list records |

---

## API mapping

| UI action | HTTP |
|-----------|------|
| List / medical records | `GET /api/mobile/health/history` |
| Timeline | `GET /api/mobile/health/timeline` |
| Detail | `GET /api/mobile/health/history/:id` |
| Create | `POST /api/mobile/health/history` |
| Update | `PATCH /api/mobile/health/history/:id` |
| Delete | `DELETE /api/mobile/health/history/:id` |
| Animals (form picker) | Existing animals API |
| Treatment link (read-only) | Existing treatments module route |

## Routes

| Route | Screen |
|-------|--------|
| `/health` | Dashboard (summary + recent events) |
| `/health/history` | Health history |
| `/health/records` | Medical records (alias → history) |
| `/health/timeline` | Timeline |
| `/health/analytics` | Analytics |
| `/health/create` | Create form |
| `/health/:id` | Detail |
| `/health/:id/edit` | Edit/delete form |

## Verification

```bash
flutter gen-l10n
dart analyze lib/features/health lib/routing/app_router.dart
flutter test test/health/
```
