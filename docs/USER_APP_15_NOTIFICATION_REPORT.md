# USER_APP_15 — Notification Module Report

**Project:** `pranidoctor_user`  
**Module:** `USER_APP_15_NOTIFICATION`  
**Date:** 2026-05-22  
**Status:** Complete

## Existing findings (audit)

- Inbox tab had basic notification list with mark read / mark all / pull refresh
- FCM token registration and 30s polling existed
- No dedicated unread-count, delete, or settings APIs
- No offline cache; deep links only handled `serviceRequestId`
- Background FCM handler only initialized Firebase

## Completed work

### Backend (`pranidoctor-backend`)

| Addition | Path |
|----------|------|
| `NotificationSettings` model | `prisma/schema.prisma` |
| Migration | `prisma/migrations/20260522180000_phase6_notification_settings/` |
| Unread count, delete, settings | `lib/notifications/notification-service.ts` |
| Routes | `routes/mobile/notifications/unread-count`, `settings`, `[id]` DELETE |

### Web BFF (`pranidoctor-web`)

Proxies for unread-count, settings (GET/PUT), notification DELETE.

### Flutter (`pranidoctor_user`)

| Area | Changes |
|------|---------|
| Repository | Cache-first list/unread/settings; delete; dedicated unread API |
| Providers | `notificationListProvider` (pagination, grouping), `notificationSettingsProvider` |
| UI | Grouped list (Today/Yesterday/Earlier), skeleton, swipe delete, settings page |
| Deep links | `NotificationDeepLink` — appointment, animal, treatment, support, dashboard |
| Push | Background tray display; coordinator uses deep link resolver |
| Analytics | `NotificationAnalytics` debug hooks |
| Integration | Cache keys, app startup warm, settings route + link from Settings |

## API connected

| Method | Path | Status |
|--------|------|--------|
| GET | `/api/mobile/notifications` | Connected |
| GET | `/api/mobile/notifications/unread-count` | **New** |
| PATCH | `/api/mobile/notifications/:id/read` | Connected |
| PATCH | `/api/mobile/notifications/read-all` | Connected |
| DELETE | `/api/mobile/notifications/:id` | **New** |
| GET/PUT | `/api/mobile/notifications/settings` | **New** |
| POST | `/api/mobile/devices/register` | Connected |

## Files changed

**Backend:** schema, migration, notification-service, 3 route files  
**Web:** 3 proxy route files  
**Flutter:** `notification_repository*.dart`, `notification_dto.dart`, `notification_api_paths.dart`, `notification_grouping.dart`, `notification_deeplink.dart`, `notification_analytics.dart`, `notification_providers.dart`, `notification_list_page.dart`, `notification_settings_page.dart`, widgets, coordinator, realtime, fcm_background, push_registration, local_cache_contract, app_routes, app_router, settings_page, app_startup, app_en.arb, dio_helpers (putJson)

## Pending limitations

- Backend FCM **send** not implemented (tokens stored; delivery future work)
- Settings toggles persisted server-side; not yet enforced in event dispatch/SMS
- 30s polling remains (no WebSocket/SSE)
- Widget/provider tests minimal (DTO/deeplink/grouping covered)

## Testing evidence

```bash
cd pranidoctor_user
flutter gen-l10n
flutter test test/notifications/
dart analyze lib/features/notifications
```

## Rollback notes

- Revert migration `20260522180000_phase6_notification_settings` if settings table causes issues
- Flutter falls back to cached list when network fails; safe to deploy independently of push send
- `/api/mobile/health` probe unchanged

**USER_APP_15_COMPLETE**
