# USER_APP_04 — Location System Report

**Project:** PraniDoctor User App (`pranidoctor_user`)  
**Module:** PHASE 2 — Location System  
**Status:** COMPLETE  
**Date:** 2026-05-22

---

## Summary

Extended the existing `features/area/` stack (no new routes, no architecture redesign). Production API is `/api/area/*` (mapped from task `locations/*`). Cascading location UI remains in `AreaPicker`, now backed by Riverpod providers with API-first fetch, memory + disk fallback, and loading/error/empty/retry states.

---

## Screens completed

| Screen | Status | Location |
|--------|--------|----------|
| Select Division | COMPLETE | `AreaPicker` level 1 |
| Select District | COMPLETE | `AreaPicker` level 2 |
| Select Upazila | COMPLETE | `AreaPicker` level 3 |
| Select Union | COMPLETE | `AreaPicker` level 4 |
| Select Village | COMPLETE | `AreaPicker` level 5 |

Used in: `ProfileAddressPage`, `BookConsultationPage`

---

## API connected

| Task path | Production path | Status |
|-----------|-----------------|--------|
| `locations/divisions` | `GET /api/area/divisions` | Connected |
| `locations/districts` | `GET /api/area/divisions/:id/districts` | Connected |
| `locations/upazilas` | `GET /api/area/districts/:id/upazilas` | Connected |
| `locations/unions` | `GET /api/area/upazilas/:id/unions` | Connected |
| `locations/villages` | `GET /api/area/unions/:id/villages` | Connected |
| Search | `GET /api/area/search` | Repository only (no UI — not previously used) |

Uses existing Dio client, interceptors, and token refresh (public endpoints — no auth required).

---

## Providers updated

| Provider | Type | Behavior |
|----------|------|----------|
| `areaLocaleProvider` | `Provider<String>` | Profile locale → `bn` / `en` |
| `divisionProvider` | `FutureProvider.autoDispose` | All divisions |
| `districtProvider` | `Family FutureProvider` | Districts by division |
| `upazilaProvider` | `Family FutureProvider` | Upazilas by district |
| `unionProvider` | `Family FutureProvider` | Unions by upazila |
| `villageProvider` | `Family FutureProvider` | Villages by union |

Parent change clears child selections in widget state; family providers auto-dispose when parent ID changes.

Aliases: `locationRepositoryProvider` → `areaRepositoryProvider`

---

## Repositories updated

`AreaRepository` / `LocationRepository`:

- **API first** with up to 2 attempts on transient errors
- **Memory cache** (session) via `AreaMemoryCache`
- **Disk cache** fallback (Hive, 7-day TTL)
- **In-flight dedup** prevents duplicate parallel requests
- **`warmFromDisk()`** for cold-boot memory warm (non-blocking)

Entity aliases: `Division`, `District`, `Upazila`, `Union`, `Village` → `AreaNodeDto`

---

## Cache strategy

```
Request
  ↓
In-flight dedup (same key)
  ↓
Remote API (retry ×1 on transient failure)
  ↓ success → memory + disk write
  ↓ failure → memory → disk → error
```

**Keys:** `divisions:{locale}`, `districts:{divisionId}:{locale}`, etc.

**Cold boot:** `AppStartup` calls `warmFromDisk()` for `bn` and `en` without blocking UI.

---

## Offline readiness

| Capability | Status |
|------------|--------|
| Disk cache on successful fetch | Yes |
| API failure → cached lists | Yes |
| Memory warm on boot | Yes |
| Offline hint string | Added (`areaOfflineHint`) |
| Empty hierarchy levels | Per-level empty messages |

---

## Files changed

### Added

- `docs/USER_APP_04_LOCATION_ANALYSIS.md`
- `docs/USER_APP_04_LOCATION_REPORT.md`
- `lib/core/area/area_entities.dart`
- `lib/core/area/area_locale.dart`
- `lib/features/area/data/area_memory_cache.dart`
- `lib/features/area/presentation/area_providers.dart`
- `lib/features/area/presentation/widgets/area_feedback.dart`
- `test/area/area_integration_test.dart`

### Modified

- `lib/features/area/data/area_repository.dart`
- `lib/features/area/presentation/area_picker.dart`
- `lib/app/app_startup.dart`
- `lib/l10n/app_en.arb`

---

## Remaining risks

| Risk | Mitigation |
|------|------------|
| Backend area seed empty in dev | Empty-state UI + retry |
| `GET /api/area/*` not proxied via Next.js web | Point `API_BASE_URL` at backend (existing convention) |
| Search API unused in UI | Repository retained; UI deferred |
| Seed version invalidation | `clearHierarchy()` still no-op — TTL handles staleness |
| Bengali UI strings only in EN ARB | l10n keys added; `app_bn.arb` future work |

---

## Manual QA checklist

- [ ] First online load: all 5 dropdowns populate
- [ ] Select division → districts load; lower levels reset
- [ ] Select through to village → `selectedLabel` emitted
- [ ] Airplane mode after cache warm → cached lists shown
- [ ] Airplane mode cold (no cache) → error + retry
- [ ] Profile language EN → area labels request `locale=en`
- [ ] Profile address save with village selected
- [ ] Book consultation location picker works
- [ ] Back navigation preserves valid prior selections when IDs still valid
- [ ] No duplicate network calls when rapidly opening address screen

---

## Verification

```bash
flutter pub get
flutter gen-l10n
dart analyze lib
flutter test test/area/area_integration_test.dart
```

---

## Status

**COMPLETE**
