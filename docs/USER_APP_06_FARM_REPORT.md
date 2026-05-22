# USER_APP_06 — Farm Module Report

**Project:** PraniDoctor User App (`pranidoctor_user`)  
**Module:** USER_APP_06_FARM  
**Status:** COMPLETE  
**Date:** 2026-05-22

---

## Summary

Implemented the Farm module as a **composite farms layer** over existing mobile APIs (no dedicated `/api/mobile/farms` backend yet). A customer farm maps to profile location (`PATCH /api/mobile/me`) plus dashboard `farmSummary` and related animals. UI includes list, detail, and create/edit flows with offline cache, search/filter, pagination scaffold, and cover image upload.

---

## Screens completed

| Screen | Route | File |
|--------|-------|------|
| Farm List | `/farms` | `farm_list_page.dart` |
| Farm Details | `/farms/:id` | `farm_detail_page.dart` |
| Create Farm | `/farms/create` | `farm_form_page.dart` |
| Edit Farm | `/farms/:id/edit` | `farm_form_page.dart` |

Home quick action **Create farm** now routes to `/farms`.

---

## APIs connected (composite “farms”)

| Logical operation | HTTP | Path |
|-------------------|------|------|
| List / detail context | GET | `/api/mobile/profile/dashboard-context` |
| Profile + address | GET | `/api/mobile/me` |
| Create / update farm | PATCH | `/api/mobile/me` (`area` + `address`) |
| Cover image upload | POST | `/api/mobile/uploads/cover-image` |
| Related animals | GET | `/api/mobile/animals` |

---

## Upload flow

1. User picks image via `image_picker` (max 1920×1080, quality 70 — client compression).
2. `FarmRepository.uploadCoverImage` posts multipart `file` to cover-image endpoint.
3. Dio `onSendProgress` drives `farmUploadProgressProvider` linear indicator.
4. Success returns `coverPhotoUrl` / `downloadUrl`; failure shows snackbar + retry via pick again.

---

## Repository & cache

| Component | Role |
|-----------|------|
| `FarmRepository` | API-first, retry, disk fallback |
| `LocalCacheContract.farmsListKey` | Cached farm list |
| `LocalCacheContract.farmDetailKey(id)` | Cached farm detail + animals |
| `AppStartup` | Non-blocking `readCachedFarmList()` |

---

## Providers

| Provider | Role |
|----------|------|
| `farmListProvider` | AsyncNotifier — list, refresh, pagination, optimistic save |
| `farmDetailProvider` | Family FutureProvider — detail + animals |
| `farmSearchProvider` / `farmFilterProvider` | Query state |
| `farmUploadProgressProvider` | Upload progress 0–1 |

---

## Files changed

| File | Change |
|------|--------|
| `lib/core/offline/local_cache_contract.dart` | Farm cache keys |
| `lib/features/farm/data/*` | DTO, repo, validation, API paths |
| `lib/features/farm/presentation/*` | Pages, providers, widgets |
| `lib/routing/app_routes.dart` | Farm routes |
| `lib/routing/app_router.dart` | Farm GoRoutes |
| `lib/features/home/.../home_quick_actions.dart` | Link to `/farms` |
| `lib/app/app_startup.dart` | Warm farm cache |
| `lib/l10n/app_en.arb` | Farm strings |
| `test/farm/farm_integration_test.dart` | Unit tests |

---

## Pending items

| Item | Notes |
|------|-------|
| Dedicated `/api/mobile/farms` CRUD | Backend `FarmProfile` table deferred (PHASE2 plan) |
| Multi-farm per customer | Current model: 0–1 farm from profile location |
| Animal photo upload endpoint | Animals use `photoUrl` string only |
| Bangla l10n file | Only `app_en.arb` in repo |
| Full animal CRUD screens | Detail lists animals; add/edit animal out of scope |

---

## Risks

| Risk | Mitigation |
|------|------------|
| Single-farm limitation | Documented; pagination ready for future multi-farm API |
| Farm name = profile `area` field | Shared with profile display label |
| Cover upload without farm save | Upload updates customer cover immediately (backend behavior) |

---

## Manual QA checklist

- [ ] Open `/farms` — empty state or existing farm card  
- [ ] Create farm — name + village + save → detail screen  
- [ ] Pull to refresh list  
- [ ] Search / filter chips  
- [ ] Farm detail — summary + animals list  
- [ ] Upload cover — progress bar + image preview  
- [ ] Offline — cached list/detail with banner  
- [ ] Edit farm — update location/name  

Run tests: `flutter test test/farm/`
