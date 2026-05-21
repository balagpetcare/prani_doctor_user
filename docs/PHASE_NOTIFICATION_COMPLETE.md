# Phase Notifications — Complete

**Repository:** `pranidoctor_user`  
**Completed:** 2026-05-22

## Summary

| Capability | Implementation | API / mechanism |
|------------|----------------|-----------------|
| **Push** | FCM token fetch + `POST /api/mobile/devices/register` on login, session restore, token refresh | `firebase_messaging` |
| **Local** | Heads-up tray for foreground FCM + poll-detected unread | `flutter_local_notifications` |
| **Realtime** | 30s polling when authenticated; invalidates inbox + unread badge; local alert on new unread | `GET /api/mobile/notifications` |

## Files

- `lib/features/notifications/data/` — `notification_api_paths.dart`, `notification_dto.dart`, `notification_repository.dart`
- `lib/features/notifications/presentation/notifications_panel.dart`
- `lib/features/notifications/` — `notification_service.dart`, `local_notification_service.dart`, `notification_coordinator.dart`, `notification_realtime.dart`, `push_registration.dart`, `fcm_background.dart`
- Updated: `inbox_page.dart` (Appointments | Notifications tabs), `app_shell_scaffold.dart` (unread badge), `login_page.dart`, `bootstrap.dart`, `app.dart`, l10n

## Mobile APIs

- `GET /api/mobile/notifications` — list (`unreadOnly`, pagination)
- `PATCH /api/mobile/notifications/:id/read`
- `PATCH /api/mobile/notifications/read-all`
- `POST /api/mobile/devices/register` — `{ deviceKey, platform, pushToken?, appVersion? }`

## UX

- Inbox tab: **Appointments** | **Notifications**
- Unread badge on bottom nav + drawer Inbox
- Tap notification → mark read → deep link to service request when `metadata.serviceRequestId` present
- Pull-to-refresh on notifications list

## Notes

- Backend FCM **send** is not implemented yet; push registration stores tokens for future delivery.
- No WebSocket/SSE on backend — realtime uses polling (same pattern as admin web).
- Requires Firebase config (`google-services.json` / `GoogleService-Info.plist`) for device push tokens.

*Notification phase complete.*
