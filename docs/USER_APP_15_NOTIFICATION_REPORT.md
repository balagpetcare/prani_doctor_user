# USER_APP_15 — Notification Module Report

**Project:** `pranidoctor_user`  
**Module:** `USER_APP_15_NOTIFICATION`  
**Date:** 2026-05-22  
**Status:** Complete

## 1. Current audit (at start)

- Inbox tab had list, mark read/all, delete, pagination, grouping
- Repository had cache read/write but providers hit network on every `build()`
- No notification center, detail, or permission screens
- Deep links via coordinator only; no safe handler route
- No client search/unread filter UI
- Poll invalidated list every 30s; duplicate local alerts possible

## 2. Plan

See `docs/user_app/USER_APP_15_NOTIFICATION.md`.

## 3. Implementation

| Feature | Status |
|---------|--------|
| Cache-first list/settings/unread providers | Done |
| Notification center (`/notifications`) | Done |
| Notification detail (`/notifications/:id`) | Done |
| Permission flow (`/notifications/permission`) | Done |
| Deep-link handler (`/notifications/open`) | Done |
| Client search + unread filter | Done |
| Duplicate alert dedup + conditional list invalidation | Done |
| `NotificationNavigation` invalidation helper | Done |
| Deep links: health, vaccine, treatment, support, appointment | Done |

## 4. Changed files

**New**
- `docs/user_app/USER_APP_15_NOTIFICATION.md`
- `lib/features/notifications/presentation/notification_center_page.dart`
- `lib/features/notifications/presentation/notification_detail_page.dart`
- `lib/features/notifications/presentation/notification_permission_page.dart`
- `lib/features/notifications/presentation/notification_deeplink_page.dart`
- `lib/features/notifications/presentation/notification_navigation.dart`
- `lib/features/notifications/presentation/widgets/notification_summary_section.dart`

**Updated**
- `notification_providers.dart`, `notification_list_page.dart`, `notification_card.dart`
- `notification_settings_page.dart`, `notification_service.dart`, `notification_realtime.dart`
- `notification_deeplink.dart`, `notification_repository.dart`
- `app_routes.dart`, `app_router.dart`, `app_en.arb`
- `home_summary_section.dart`, `home_greeting_header.dart`, `app_shell_scaffold.dart`
- `test/notifications/notification_integration_test.dart`

## 5. API mapping

| Method | Path | Flutter |
|--------|------|---------|
| GET | `/api/mobile/notifications` | `listNotifications` |
| GET | `/api/mobile/notifications/unread-count` | `getUnreadCount` |
| PATCH | `/api/mobile/notifications/:id/read` | `markRead` |
| PATCH | `/api/mobile/notifications/read-all` | `markAllRead` |
| DELETE | `/api/mobile/notifications/:id` | `deleteNotification` |
| GET/PUT | `/api/mobile/notifications/settings` | `getSettings` / `saveSettings` |
| POST | `/api/mobile/devices/register` | `registerDevice` |

## 6. State / provider flow

- `notificationListProvider` — cache → paint → silent refresh; filters via `notificationUnreadOnlyProvider`, search client-side
- `unreadNotificationCountProvider` — independent badge (cache-first)
- `notificationSettingsProvider` — cache-first AsyncNotifier
- `notificationDetailProvider` — resolves from list/cache, fallback refresh
- `notificationRealtimeProvider` — poll unread; invalidate list only when count changes; dedupe local alerts by ID

## 7. Push / deep-link flow

- FCM foreground/background → local tray with metadata payload
- Tap → `NotificationCoordinator` → `NotificationDeepLink.resolve` → `go_router`
- `/notifications/open?target=…` → session check → resolve → navigate
- Permission page → `requestPermission` → `pushRegistrationProvider.register`

## 8. Cache strategy

- Disk keys: list, unread count, settings (profile TTL)
- Optimistic cache on mark read / delete
- Offline fallback in repository; offline hint in UI

## 9. Validation

```bash
flutter gen-l10n
flutter test test/notifications/   # 9/9 passed
dart analyze lib/features/notifications lib/routing/app_router.dart  # 0 errors
```

## 10. Remaining blockers / risks

| Item | Risk |
|------|------|
| No backend FCM send | Push delivery not end-to-end until server send exists |
| No GET notification by id | Detail depends on list/cache |
| No server search | Search only filters loaded items |
| Settings not enforced in dispatch | Toggles saved but may not affect all channels |
| 30s polling | Battery/network vs real-time tradeoff |

## 11. Manual QA checklist

- [ ] `/notifications` — summary cards, recent list, pull refresh
- [ ] Inbox → Notifications tab — search, unread filter, pagination, grouping
- [ ] Tap card → detail → Mark read / Open action
- [ ] Mark all read — badge clears
- [ ] Swipe delete — item removed, badge updates
- [ ] Settings save + permission page flow
- [ ] Offline — cached data + hint
- [ ] Deep link `/notifications/open?target=animal&animalId=…`
- [ ] Logout — polling stops

**USER_APP_15_COMPLETE**
