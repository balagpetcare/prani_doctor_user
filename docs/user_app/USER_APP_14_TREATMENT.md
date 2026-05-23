# USER_APP_14 — Treatment

**Project:** PraniDoctor User App (`pranidoctor_user`)  
**Module:** Treatment & care management  
**Status:** COMPLETE  
**Date:** 2026-05-22

---

## Phase 1 — Audit summary

### Already implemented (~70%)

| Capability | Location |
|------------|----------|
| Treatment list + CRUD | `TreatmentRepository`, `TreatmentListPage`, `TreatmentFormPage` |
| Detail + prescription embed | `TreatmentDetailPage`, `prescriptionProvider` |
| Medicine items in DTO/forms | `MedicineItem`, form add/remove |
| Search (API) | List page |
| Offline cache + outbox | Repository + `SyncCoordinator` |

### Gaps fixed this pass

| Gap | Resolution |
|-----|------------|
| No treatment dashboard | `TreatmentDashboardPage` at `/treatments` |
| Lists not cache-first | Cached records → silent refresh |
| No timeline | `TreatmentTimelinePage` |
| No dedicated prescription route | `TreatmentPrescriptionPage` |
| No medicine plan view | `TreatmentMedicinePlanPage` |
| No follow-up flow | `TreatmentFollowUpPage` + local reminder fallback |
| No summary cards | `TreatmentSummarySection` |
| No status/animal/date filters on list | Filters on list page |
| No navigation helper | `TreatmentNavigation` |
| Detail lacks delete/retry | Enhanced detail page |

### Out of scope (schema)

| Field | Reason |
|-------|--------|
| health_id, prescription_id FK | Not in API |
| doctor, symptoms, attachments | Not in DTO |
| Dedicated follow-up/reminder API | Derived from `endDate` |
| Separate medicines knowledge API | Embedded `medicines` array only |

---

## API mapping

| UI action | HTTP |
|-----------|------|
| List | `GET /api/mobile/treatments` |
| Detail / prescription | `GET /api/mobile/treatments/:id` |
| Create / update / delete | POST / PATCH / DELETE |

## Routes

| Route | Screen |
|-------|--------|
| `/treatments` | Dashboard |
| `/treatments/list` | Treatment list |
| `/treatments/timeline` | Timeline |
| `/treatments/medicine-plan` | Medicine plan |
| `/treatments/follow-up` | Follow-up |
| `/treatments/create` | Create form |
| `/treatments/:id` | Detail |
| `/treatments/:id/edit` | Edit |
| `/treatments/:id/prescription` | Prescription view |

## Verification

```bash
flutter gen-l10n
dart analyze lib/features/treatment lib/routing/app_router.dart
flutter test test/treatment/
```
