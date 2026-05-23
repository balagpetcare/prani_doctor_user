# USER_APP_15 — Notifications

**Project:** `pranidoctor_user`  
**Phase:** 6 — Communication  
**Status:** Complete

## Audit (pre-implementation)

| Area | State |
|------|--------|
| List + mark read/all + delete | Done (inbox tab) |
| Repository cache read/write | Done |
| Settings GET/PUT | Done |
| Unread-count API | Done |
| FCM + local tray + device register | Done |
| 30s poll + badge on shell/home | Done |
| Deep link resolver (basic) | Done |
| **Cache-first providers** | Missing — list/settings/unread hit network in `build()` |
| **Notification center** | Missing dedicated dashboard |
| **Notification detail** | Missing — card jumped straight to target |
| **Permission flow screen** | Missing — silent `requestPermission()` only |
| **Deep link route handler** | Missing — coordinator only |
| **Unread filter + client search** | Missing |
| **Duplicate local alerts** | Missing dedup on poll |
| **Navigation invalidation helper** | Missing |

Backend list API supports `unreadOnly`; no server-side search.

## Plan

1. **Providers** — cache-first list/settings/unread; filter state; detail lookup from cache/list; `NotificationNavigation` invalidation helper.
2. **Screens** — `/notifications` center (summary + recent), `/notifications/:id` detail, `/notifications/permission`, `/notifications/open` deep-link handler.
3. **List UX** — search field (client), unread chip (API `unreadOnly`), tap → detail → action.
4. **Push** — permission status API on `NotificationService`; permission page with retry + open system settings.
5. **Realtime** — dedupe shown notification IDs; invalidate list only when unread count changes.
6. **Deep links** — expand resolver (vaccine, health); safe fallback via handler route.
7. **Validation** — tests, `dart analyze`, manual QA checklist in report.

## API mapping

| Flutter | Method | Backend |
|---------|--------|---------|
| `NotificationApiPaths.notifications` | GET | List (limit, offset, unreadOnly) |
| `unreadCount` | GET | `{ count }` |
| `markRead(id)` | PATCH | Mark one read |
| `readAll` | PATCH | Mark all read |
| `notification(id)` | DELETE | Delete |
| `settings` | GET/PUT | Notification preferences |
| `registerDevice` | POST | FCM token + device key |

## State / provider flow

```
AppStartup → readCachedList/Unread/Settings (disk warm)
notificationListProvider → cache → paint → silent refresh
unreadNotificationCountProvider → cache → silent refresh (badge independent)
notificationSettingsProvider → cache → silent refresh
notificationRealtimeProvider → poll unread-count → invalidate badge; list only if count changed
NotificationNavigation.after* → invalidate list + unread + dashboard metrics
```

## Push / deep-link flow

```
FCM foreground → NotificationService → local tray (metadata payload)
FCM background → fcm_background.dart → local tray
Tap (local/FCM) → NotificationCoordinator → NotificationDeepLink.resolve → go_router
Cold start → getInitialMessage → same resolver
In-app /notifications/open?target=… → NotificationDeepLinkPage → session check → resolve → go
```

## Cache strategy

- Keys: `notificationsListKey`, `notificationsUnreadCountKey`, `notificationSettingsKey` (profile TTL).
- List cache written on first page fetch (non-unreadOnly); optimistic updates on mark read/delete.
- Offline: repository returns cached page on network failure; UI shows offline hint.

## Files

**New:** `notification_center_page.dart`, `notification_detail_page.dart`, `notification_permission_page.dart`, `notification_deeplink_page.dart`, `notification_navigation.dart`, `widgets/notification_summary_section.dart`

**Updated:** `notification_providers.dart`, `notification_list_page.dart`, `notification_card.dart`, `notification_service.dart`, `notification_realtime.dart`, `notification_deeplink.dart`, `app_routes.dart`, `app_router.dart`, `app_en.arb`, tests

## Remaining blockers

- Backend FCM **send** not implemented (tokens stored only).
- Settings toggles not enforced in event dispatch.
- No GET single notification — detail resolves from list/cache.
- No server-side search.

## Manual QA

- [ ] Open `/notifications` — summary + recent items from cache then refresh
- [ ] Inbox notifications tab — pull refresh, pagination, grouped sections
- [ ] Unread filter chip — shows unread only
- [ ] Search — filters loaded items by title/body
- [ ] Tap notification → detail → Open action → correct screen
- [ ] Mark read / mark all / swipe delete — badge updates
- [ ] Settings save — persists after relaunch
- [ ] Permission page — request + open system settings when denied
- [ ] Push tap (or simulated local notification) — deep link routes correctly
- [ ] Offline — cached list + hint; retry works when online
- [ ] Logout — poll stops, badge clears

**USER_APP_15_COMPLETE**
