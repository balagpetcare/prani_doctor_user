# USER_APP_06 — Farm Management

**Project:** PraniDoctor User App (`pranidoctor_user`)  
**Module:** Farm  
**Status:** COMPLETE  
**Date:** 2026-05-22

---

## Phase 1 — Audit summary

### Already implemented (~70%)

| Capability | Location |
|------------|----------|
| Farm list + search + filters | `FarmListPage`, `FarmListNotifier` |
| Farm detail + animals | `FarmDetailPage` |
| Create / edit form | `FarmFormPage` + `AreaPicker` |
| Cover upload | `FarmImageUpload` → `/api/mobile/uploads/cover-image` |
| Validation | `FarmValidation` |
| Offline cache | `LocalCacheService` list + detail keys |
| Optimistic save | `saveOptimistic` in `FarmListNotifier` |
| Routes | `/farms`, `/farms/create`, `/farms/:id`, `/farms/:id/edit` |

### Backend reality (not spec paths)

There is **no** `/api/mobile/farms/*` CRUD API. Farm data is composite:

| Operation | Actual API |
|-----------|------------|
| List / detail | `GET /api/mobile/me` + `GET /api/mobile/profile/dashboard-context` + `GET /api/mobile/animals` |
| Create / update | `PATCH /api/mobile/me` (`area` + `address`) |
| Cover media | `POST /api/mobile/uploads/cover-image` (persists `coverPhotoUrl`) |
| Location | `/api/area/*` via `AreaPicker` |

**Single farm per customer** — derived from profile `villageId`. Multiple farms / delete farm are **not supported** by backend.

### Gaps fixed this pass

| Gap | Resolution |
|-----|------------|
| No cache-first list paint | Cached list → silent refresh |
| No draft recovery | Local draft save/restore on form |
| No sort / needsLocation filter UI | Sort chips + filter chip |
| No settings / profile screen | `FarmSettingsPage` |
| Detail missing refresh / actions | Pull-to-refresh + quick actions |
| Cover not reflected after save | Invalidate profile + farm providers post-save |
| No active farm state | `activeFarmIdProvider` (session persist) |
| Hardcoded card strings | l10n |

### Out of scope (blockers)

| Item | Reason |
|------|--------|
| Multiple farms CRUD | No backend farms table/API |
| Delete farm | Cannot clear `villageId` via PATCH |
| Geo coordinates / farm code | Not in mobile me schema |
| Bengali ARB | English keys ready |

---

## API mapping

See audit table above.

---

## State flow

```
farmListProvider: cache → paint → silent refresh
farmDetailProvider(id): network → detail cache fallback
saveOptimistic → PATCH /me → refresh list + dashboard
activeFarmIdProvider: persisted selected farm (auto-set when one farm)
FarmFormPage: draft read on open → save draft → clear on success
```

---

## Verification

```bash
flutter gen-l10n
dart analyze lib/features/farm
flutter test test/farm/
```
