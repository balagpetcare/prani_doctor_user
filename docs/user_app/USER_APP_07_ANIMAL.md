# USER_APP_07 — Animal Management

**Project:** PraniDoctor User App (`pranidoctor_user`)  
**Module:** Animal  
**Status:** COMPLETE  
**Date:** 2026-05-22

---

## Phase 1 — Audit summary

### Already implemented (~75%)

| Capability | Location |
|------------|----------|
| List + search + filters | `AnimalListPage` |
| CRUD via mobile API | `AnimalRepository` |
| Deactivate API | `deactivateAnimal` |
| Detail + timeline + care history | `AnimalDetailPage` |
| Add/Edit + draft | `AnimalFormPage` |
| Photo upload | `AnimalImageUpload` |
| Offline cache + outbox | Repository |
| Validation | `AnimalValidation` |

### Backend reality

| Operation | Path |
|-----------|------|
| List | `GET /api/mobile/animals?includeInactive=` |
| Create | `POST /api/mobile/animals` |
| Detail | `GET /api/mobile/animals/:id` |
| Update | `PATCH /api/mobile/animals/:id` |
| Deactivate (delete) | `PATCH /api/mobile/animals/:id/deactivate` |
| Photo | `POST /api/mobile/uploads/profile-image` |

No server pagination (client-side), no `farm_id`, no breeds API, no gallery API.

### Gaps fixed this pass

| Gap | Resolution |
|-----|------------|
| No cache-first list | Cached list → silent refresh |
| No sort | `AnimalSort` + dropdown |
| Missing filters | Inactive + pets chips |
| No summary cards | Stats row on list |
| No deactivate UI | Detail deactivate with confirm |
| No pull-to-refresh detail | `RefreshIndicator` |
| No navigation helper | `AnimalNavigation` |
| Dashboard not invalidated | After create/update/deactivate |

### Out of scope

| Item | Reason |
|------|--------|
| Farm-wise listing | Animals tied to customer, not farm |
| Breeds API | Not exposed on mobile |
| Multi-image gallery | Single `photoUrl` only |
| Hard delete | Mobile uses deactivate only |
| Purchase/sale fields | Not in API schema |

---

## Verification

```bash
flutter gen-l10n
dart analyze lib/features/animals
flutter test test/animals/
```
