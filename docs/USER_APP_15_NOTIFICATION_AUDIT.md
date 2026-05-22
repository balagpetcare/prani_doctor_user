# USER_APP_15 — Notification Module Audit

**Project:** `pranidoctor_user`  
**Date:** 2026-05-22  
**Status before work:** Partial (inbox UI + list/mark-read + FCM register + 30s poll)

## Existing Flutter (`lib/features/notifications/`)

| File | Role |
|------|------|
| `data/notification_api_paths.dart` | List, mark read, read-all, device register |
| `data/notification_dto.dart` | `MobileNotificationDto`, list result |
| `data/notification_repository.dart` | HTTP client; unread via filtered list hack |
| `presentation/notifications_panel.dart` | Basic list in Inbox tab |
| `notification_service.dart` | FCM init, foreground → local tray, token refresh |
| `local_notification_service.dart` | `flutter_local_notifications` channel |
| `notification_coordinator.dart` | App wiring; tap → service request or inbox |
| `notification_realtime.dart` | 30s poll; local alert on unread increase |
| `push_registration.dart` | POST device + FCM token |
| `fcm_background.dart` | Firebase init only (no tray/sync) |

## Routes

| Route | Screen |
|-------|--------|
| `/inbox` | Appointments \| **Notifications** tabs |
| `/inbox/request/:id` | Deep link target (service request) |
| `/settings` | No notification settings screen |

## Backend (legacy, working)

| Endpoint | Status |
|----------|--------|
| `GET /api/mobile/notifications` | Exists |
| `PATCH /api/mobile/notifications/:id/read` | Exists |
| `PATCH /api/mobile/notifications/read-all` | Exists |
| `POST /api/mobile/devices/register` | Exists |
| `GET /api/mobile/notifications/unread-count` | **Missing** |
| `DELETE /api/mobile/notifications/:id` | **Missing** |
| `GET/PUT /api/mobile/notifications/settings` | **Missing** |

`GET /api/mobile/health` remains infrastructure probe (unchanged).

## Prisma

- `Notification`: id, userId, title, body, readAt, metadataJson, type, createdAt
- `UserDevice`: pushToken storage
- **No** `NotificationSettings` model (pre-work)

## Gaps identified

1. No dedicated unread-count endpoint (inefficient badge poll)
2. No delete notification API
3. No notification preferences API/UI
4. No offline cache for list/unread/settings
5. List UI lacks pagination, grouping, skeleton, delete, retry
6. Deep links only handle `serviceRequestId`
7. Background FCM handler minimal
8. No repository/provider unit tests

## Reference patterns to reuse

- Cache: `LocalCacheService` + `LocalCacheContract` (finance/health modules)
- List UX: finance `AsyncNotifier` pagination + feedback widgets
- Skeleton: `home_skeleton.dart` bone pattern
- Settings: `settings_page.dart` SwitchListTile pattern

## Implementation plan

1. Add `NotificationSettings` Prisma model + mobile API routes
2. Extend legacy `notification-service.ts` (unread, delete, settings)
3. Web BFF proxies for new routes
4. Upgrade Flutter repository (cache-first), providers, list + settings UI
5. Expand deep link resolver; wire coordinator + FCM background tray
6. Tests + report
