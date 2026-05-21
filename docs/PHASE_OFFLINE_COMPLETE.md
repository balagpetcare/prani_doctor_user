# Phase Offline — Complete

**Repository:** `pranidoctor_user`  
**Completed:** 2026-05-22

## Summary

| Capability | Implementation |
|------------|----------------|
| **Offline cache** | TTL cache for profile + appointment list (`LocalCacheService` on Hive) |
| **Retry** | Exponential backoff (30s → 1h, max 5 attempts) on local outbox |
| **Sync** | `SyncCoordinator` drains outbox + `POST /api/sync` for server queue / `OFFLINE_LEAD` |
| **Error recovery** | Transient network → queue locally; stale cache on read failure; Settings sync panel |

## Files

- `lib/core/offline/network_errors.dart` — transient detection + backoff
- `lib/features/offline/data/` — cache, outbox, connectivity, repository, sync coordinator
- `lib/features/offline/presentation/offline_queue_panel.dart`
- `lib/features/offline/offline_coordinator.dart`
- Updated: `profile_repository.dart`, `service_request_repository.dart`, `book_consultation_page.dart`, `settings_page.dart`, `app_startup.dart`, `offline_dto.dart`

## Local outbox kinds

| Kind | Retry target |
|------|----------------|
| `service_request` | `POST /api/mobile/service-requests` |
| `profile_patch` | `PATCH /api/mobile/me` |
| `offline_lead` | `POST /api/sync` (`OFFLINE_LEAD` entity) |

## Backend APIs

- `GET /api/sync/status`
- `POST /api/sync`
- `POST /api/sync/retry`
- `GET /api/offline/queue`

## UX

- Booking/profile save offline → “Saved offline — will sync when online”
- Settings → offline sync panel (pending count, sync now, retry failed)
- Reconnect + app startup → background sync (60s interval while running)

## Reuse

- Existing `CacheStore` / Hive bootstrap
- Existing offline contracts + extended DTOs
- Area picker cache unchanged (already cache-first)

*Offline phase complete.*
