# USER_APP_07 — Animal Module Report

**Project:** PraniDoctor User App (`pranidoctor_user`)  
**Module:** USER_APP_07_ANIMAL  
**Status:** COMPLETE  
**Date:** 2026-05-22

---

## Summary

Implemented a dedicated `features/animals/` module with full CRUD against `/api/mobile/animals`, offline cache, outbox sync for create/update, list/detail/form screens, image upload, draft save, and care history derived from service requests.

---

## Screens completed

| Screen | Route | File |
|--------|-------|------|
| Animal List | `/animals` | `animal_list_page.dart` |
| Animal Details | `/animals/:id` | `animal_detail_page.dart` |
| Add / Edit Animal | `/animals/create`, `/animals/:id/edit` | `animal_form_page.dart` |

Home **Add animal** quick action → `/animals/create`. Farm detail animal rows → animal detail.

---

## APIs connected

| Method | Path | Use |
|--------|------|-----|
| GET | `/api/mobile/animals` | List (optional `includeInactive=true`) |
| POST | `/api/mobile/animals` | Create |
| GET | `/api/mobile/animals/:id` | Detail |
| PATCH | `/api/mobile/animals/:id` | Update |
| PATCH | `/api/mobile/animals/:id/deactivate` | Deactivate |
| POST | `/api/mobile/uploads/profile-image` | Photo upload (URL stored in `photoUrl`) |

---

## Upload flow

1. `image_picker` with compression (1920×1080, quality 70).
2. Multipart upload via profile-image endpoint (customer-accessible storage).
3. Progress via `animalUploadProgressProvider` + Dio `onSendProgress`.
4. Returned URL saved on animal create/update.

---

## Repository & cache

| Key | Purpose |
|-----|---------|
| `animalsListKey` | Cached animal list |
| `animalDetailKey(id)` | Cached detail + timeline/history |
| `animalDraftKey` / `animalEditDraftKey(id)` | Form drafts |

Outbox kinds: `animal_create`, `animal_patch` — drained in `SyncCoordinator`.

---

## Detail timeline & history

- **Timeline:** registered + profile updated events from `createdAt` / `updatedAt`.
- **History:** service requests filtered by `animal.id` (links to inbox detail).

No dedicated animal medical-records API on mobile yet.

---

## Files changed

| Area | Files |
|------|-------|
| Data | `lib/features/animals/data/*` |
| UI | `lib/features/animals/presentation/*` |
| Routing | `app_routes.dart`, `app_router.dart` |
| Offline | `outbox_item.dart`, `sync_coordinator.dart`, `local_cache_contract.dart` |
| Integration | `book_consultation_page.dart`, `home_quick_actions.dart`, `farm_detail_page.dart` |
| Cleanup | Removed duplicate `listAnimals` / `animalsProvider` from `service_request_repository.dart` |
| Tests | `test/animals/animal_integration_test.dart` |

---

## Pending items

| Item | Notes |
|------|-------|
| Dedicated animal photo upload endpoint | Uses profile-image URL hosting |
| Server-side animal timeline API | Client-built from timestamps + appointments |
| Medical records API | Backend module exists but not exposed on mobile routes |
| Bangla l10n | Only `app_en.arb` |

---

## Manual QA checklist

- [ ] List animals with search/filter/pagination  
- [ ] Pull to refresh  
- [ ] Create animal (name or tag required)  
- [ ] Save draft and restore  
- [ ] Upload photo with progress  
- [ ] View detail timeline + appointment history  
- [ ] Edit animal  
- [ ] Offline list from cache  
- [ ] Book consultation animal dropdown still works  

Run: `flutter test test/animals/`
