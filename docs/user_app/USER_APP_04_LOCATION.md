# USER_APP_04 — Location System

**Project:** PraniDoctor User App (`pranidoctor_user`)  
**Module:** Bangladesh hierarchical location  
**Status:** COMPLETE  
**Date:** 2026-05-22

---

## Phase 1 — Audit summary

### Already implemented

| Capability | Status |
|------------|--------|
| 5-level cascade (Division → Village) | `AreaPicker` |
| API `/api/area/*` | `AreaRepository` |
| Memory + disk cache (7-day TTL) | `AreaMemoryCache`, `AreaCacheStore` |
| In-flight dedup + retry | Repository |
| Profile locale → `locale` param | `areaLocaleProvider` |
| Consumers | Profile address, farm, booking, services filter |

### Gaps fixed this pass

| Gap | Resolution |
|-----|------------|
| Search UI | Searchable bottom sheet per level + scoped API village search |
| Pagination | Auto-fetch pages when `hasMore` (up to 500 items) |
| Offline hint | `fromCache` propagation + UI banner |
| Location confirmation | Selected breadcrumb card |
| Validation | `AreaValidation.validateVillageSelected`, `isValidParentChain` |
| Dead code | Removed unused `fetchLevel` |

### Out of scope

| Item | Reason |
|------|--------|
| Standalone `/location/*` routes | Embedded picker by design |
| Bengali ARB | English strings ready; locale param uses `bn`/`en` |
| Seed-version cache invalidation | Backend hook exists; client stub deferred |
| Global search full hierarchy rebuild | Search sets village + label; user confirms via cascade when needed |

---

## API mapping

| Task spec | Production path | Method |
|-----------|-----------------|--------|
| `locations/divisions` | `/api/area/divisions` | GET |
| `locations/districts` | `/api/area/divisions/:id/districts` | GET |
| `locations/upazilas` | `/api/area/districts/:id/upazilas` | GET |
| `locations/unions` | `/api/area/upazilas/:id/unions` | GET |
| `locations/villages` | `/api/area/unions/:id/villages` | GET |
| Search | `/api/area/search` | GET |

**Query params:** `page`, `pageSize` (max 100), `locale` (`bn`/`en`)  
**Search params:** `q`, `level`, parent scope IDs

**Envelope:** `{ success: true, data: [...], meta: { total, page, pageSize, hasMore } }`

---

## State flow

```
areaLocaleProvider ← mobileMeProvider.locale
divisionProvider → districtProvider(divisionId) → … → villageProvider(unionId)

Parent change → clear child IDs (AreaPicker state)
API fail → memory/disk fallback → fromCache=true → offline hint

Search (union selected) → areaSearchProvider → pick village → emit label
```

---

## Cache strategy

| Layer | Key pattern | TTL |
|-------|-------------|-----|
| Memory | `divisions:bn`, `districts:{id}:bn`, … | Session |
| Disk (Hive) | Same via `AreaCacheStore` | 7 days |
| Boot warm | `AppStartup.warmFromDisk(bn/en)` | — |

Page 1 responses cached; auto-pagination merges into single list before cache write.

---

## Verification

```bash
flutter gen-l10n
dart analyze lib/features/area lib/core/area
flutter test test/area/area_integration_test.dart
```
