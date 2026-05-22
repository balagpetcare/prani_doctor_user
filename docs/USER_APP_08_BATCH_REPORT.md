# USER_APP_08 — Groups & Batches Module Report

**Project:** `pranidoctor_user`  
**Module:** `USER_APP_08_BATCH`  
**Status:** Complete  
**Date:** 2026-05-22

## Summary

Implemented the Groups / Batches module for the customer Flutter app with offline-first storage, future-ready `/api/mobile/batches` integration, list/filter/pagination, CRUD, animal movement, batch merge, sync outbox, UI states, tests, and documentation.

## Backend API status

| Endpoint | Status |
|----------|--------|
| `GET /api/mobile/batches` | **Not implemented** on backend |
| `POST /api/mobile/batches` | **Not implemented** |
| `GET/PATCH /api/mobile/batches/:id` | **Not implemented** |
| `POST /api/mobile/batches/:id/move` | **Not implemented** |
| `POST /api/mobile/batches/merge` | **Not implemented** |

The repository attempts the API first. When unavailable (404 / network), it falls back to **local Hive cache** and optionally **seeds auto-groups** from cached animals grouped by `animalType`.

## Architecture

```
lib/features/batches/
├── data/
│   ├── batch_api_paths.dart
│   ├── batch_dto.dart
│   ├── batch_validation.dart
│   ├── batch_repository_contract.dart
│   └── batch_repository.dart
└── presentation/
    ├── batch_providers.dart
    ├── batch_list_page.dart
    ├── batch_detail_page.dart
    ├── batch_form_page.dart
    └── widgets/
        ├── batch_card.dart
        ├── batch_feedback.dart
        ├── batch_move_dialog.dart
        └── batch_merge_dialog.dart
```

Patterns reused from Animals/Farm modules: `ApiResult`, `LocalCacheService`, Riverpod `AsyncNotifier`, go_router nested routes, outbox sync, loading/error/empty/retry widgets.

## Routes

| Route | Screen |
|-------|--------|
| `/batches` | Group list |
| `/batches/create` | Create batch |
| `/batches/:id` | Batch detail |
| `/batches/:id/edit` | Edit batch |

Entry point: **Animals list** app bar → groups icon.

## Repository behaviour

### A. Cache & offline

- Keys: `batches_list_snapshot`, `batch_detail:{id}`, draft keys for create/edit
- Startup warm: `AppStartup` preloads cached batch list
- TTL: `LocalCacheContract.profileTtl` (24h)

### B. Group list

- Search by name, type, location
- Filters: All / With animals / Empty
- Client-side pagination (page size 20, infinite scroll)

### C. Batch management

- Create / edit with name, type, location, notes, animal assignment
- Detail view with animals (resolved from animal cache) and movement log
- Draft save to cache

### D. Operations

- **Move:** select target batch + animals; updates both batches locally; queues `batch_move`
- **Merge:** combine source into target; removes source; queues `batch_merge`

### E. UI states

- Loading, error + retry, empty + CTA, offline hint, pending-sync banner

### F. Sync

Outbox kinds added:

- `batch_create`, `batch_patch`, `batch_move`, `batch_merge`

`SyncCoordinator` drains to batch API paths. Failures increment attempt count (existing outbox dead-letter behaviour). Conflict messages surface via `lastSyncError` on batch entity when sync fails.

## Tests

`test/batches/batch_integration_test.dart` — DTO parsing, validation, move payload (7 tests).

Run:

```bash
flutter test test/batches/
dart analyze lib/features/batches
```

## Follow-up (backend)

When `/api/mobile/batches` ships:

1. Align response shape with `AnimalBatch.fromJson` (`batches[]`, `batch` wrapper)
2. Repository `_localOnly` flag will auto-disable on successful GET
3. Outbox items will sync without client changes

## Files touched (integration)

- `lib/core/offline/local_cache_contract.dart` — batch cache keys
- `lib/features/offline/data/outbox_item.dart` — batch outbox kinds
- `lib/features/offline/data/sync_coordinator.dart` — batch sync + invalidate
- `lib/features/offline/presentation/offline_queue_panel.dart` — batch labels
- `lib/routing/app_routes.dart`, `app_router.dart`
- `lib/app/app_startup.dart`
- `lib/l10n/app_en.arb`
- `lib/features/animals/presentation/animal_list_page.dart` — nav link

---

**Module token:** `USER_APP_08_BATCH_COMPLETE`
