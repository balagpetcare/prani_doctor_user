# USER_APP_04 — Location System Analysis

**Project:** PraniDoctor User App (`pranidoctor_user`)  
**Module:** PHASE 2 — Location System  
**Date:** 2026-05-22  
**Status:** Pre-implementation audit (STEP 0)

---

## 1. Scope note

Task spec references `locations/*` endpoints. The **existing app and backend** use the **Area Engine** at `/api/area/*` (foundation module). There is **no** separate `/api/mobile/locations/*` client in the Flutter app. This module extends the existing `features/area/` stack — no architecture redesign.

---

## 2. Current file map

| Path | Role |
|------|------|
| `lib/core/area/area_dto.dart` | `AreaNodeDto`, `AreaSearchHitDto`, `AreaPage`, `AreaPageMeta` |
| `lib/core/area/area_repository_contract.dart` | `AreaRepositoryContract`, `AreaApiPaths` |
| `lib/core/area/area_cache_contract.dart` | Hive key scheme, 7-day TTL |
| `lib/features/area/data/area_repository.dart` | API + disk cache |
| `lib/features/area/data/area_cache_store.dart` | Hive read/write |
| `lib/features/area/presentation/area_picker.dart` | Cascading dropdown UI |

**Consumers:** `profile_address_page.dart`, `book_consultation_page.dart`

---

## 3. Current screens

| Screen (task name) | Status | Implementation |
|--------------------|--------|----------------|
| Select Division | **Embedded** | `AreaPicker` dropdown #1 |
| Select District | **Embedded** | `AreaPicker` dropdown #2 |
| Select Upazila | **Embedded** | `AreaPicker` dropdown #3 |
| Select Union | **Embedded** | `AreaPicker` dropdown #4 |
| Select Village | **Embedded** | `AreaPicker` dropdown #5 |

No standalone location routes (by design — navigation unchanged).

---

## 4. API coverage

### Task name → production path

| Task endpoint | Production path | Method | Auth |
|---------------|-----------------|--------|------|
| `locations/divisions` | `/api/area/divisions` | GET | Public |
| `locations/districts` | `/api/area/divisions/:id/districts` | GET | Public |
| `locations/upazilas` | `/api/area/districts/:id/upazilas` | GET | Public |
| `locations/unions` | `/api/area/upazilas/:id/unions` | GET | Public |
| `locations/villages` | `/api/area/unions/:id/villages` | GET | Public |
| (search) | `/api/area/search` | GET | Public |

**Query params:** `page`, `pageSize` (max 100), `locale` (`bn` \| `en`)

**Response:** Foundation paginated `{ success, data: [...], meta: { total, page, pageSize, hasMore } }` — unwrapped by `getJsonList` / Dio compat layer.

**Node shape:** `id`, `slug`, `code`, `nameBn`, `nameEn`, `label`, `level`, `parentId`, `latitude`, `longitude`, `isVerified`

---

## 5. Current API coverage vs gaps

| Capability | Status |
|------------|--------|
| All 5 hierarchy levels | **Implemented** in repository |
| Search API | **Repository only** — no UI |
| Locale from profile | **Missing** — hardcoded `bn` |
| Auth headers on area calls | **N/A** — public endpoints |

---

## 6. Repository gaps (pre-fix)

| Gap | Detail |
|-----|--------|
| Cache-first on page 1 | Returns disk cache **before** API — violates API-first requirement |
| No memory cache | Repeated calls re-read disk or re-fetch |
| No in-flight dedup | Parallel loads possible |
| No API failure fallback | Uncaught Dio errors propagate to UI |
| No empty-state signal | Empty list indistinguishable from error |
| No retry | Transient failures not retried |
| `LocationRepository` name | Only `AreaRepository` exists (naming alias needed) |

---

## 7. Offline / caching gaps

| Gap | Detail |
|-----|--------|
| Disk cache write | Only on successful API page 1 |
| Disk cache read TTL | 7 days — OK |
| Cold boot warm | Divisions not preloaded into memory |
| Seed version invalidation | `clearHierarchy()` is no-op |
| Offline indicator in UI | Not shown |

---

## 8. Riverpod gaps

| Provider (task) | Status |
|-----------------|--------|
| `divisionProvider` | **Missing** — widget calls repository directly |
| `districtProvider` | **Missing** |
| `upazilaProvider` | **Missing** |
| `unionProvider` | **Missing** |
| `villageProvider` | **Missing** |

No `AsyncValue` handling at provider layer. Parent-change cascade handled in widget `setState` only.

---

## 9. UI / UX gaps

| Gap | Detail |
|-----|--------|
| Error state | No retry UI — loading spinner only |
| Empty state | Dropdown shows empty list silently |
| Offline state | No message when serving cached data |
| Search | Not exposed |
| Rebuild risk | Direct async in widget without provider dedup |

---

## 10. Broken flows

| Flow | Issue |
|------|-------|
| First load offline, no cache | Unhandled exception |
| Profile address rehydrate | Address IDs from profile cache; area lists must load for dropdown labels |
| Locale switch | Area labels stay Bengali after switching profile to English |

---

## 11. What is already complete

- DTO parsing for all hierarchy levels
- Repository contract with all required methods
- Hive-backed disk cache with versioned keys
- Cascading dropdown with parent-disable logic
- Parent change clears children (widget state)
- Integration in profile address + booking flows

---

## 12. Implementation plan (steps 1–9)

1. Add entity type aliases (`Division`, `District`, …)
2. Enhance `AreaRepository`: memory cache, API-first, fallback, dedup, retry
3. Add `area_providers.dart` with hierarchy providers + locale
4. Refactor `AreaPicker` to use providers + loading/error/empty/retry
5. Warm division cache on app startup (non-blocking)
6. Add l10n strings + integration tests
7. Generate `USER_APP_04_LOCATION_REPORT.md`

**Out of scope:** New routes, mock removal (none exist), `/api/mobile/locations/*` migration.
