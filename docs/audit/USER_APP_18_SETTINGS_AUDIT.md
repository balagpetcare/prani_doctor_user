# USER_APP_18 — Settings Module Audit

**Date:** 2026-05-22  
**Status before work:** Partial

## Existing Flutter

| Component | Status |
|-----------|--------|
| `lib/features/settings/settings_page.dart` | Hub only — profile, theme, notifications link, static privacy URL |
| Settings data layer | **Missing** |
| Privacy / Terms screens | **Missing** |
| Settings repository | **Missing** |
| Notification settings | Separate feature (`/settings/notifications`) — kept |
| Profile | Separate feature under `/settings/profile` — kept |
| Theme | Local `themeModeProvider` only — not synced |
| Privacy URL | `AppEnv.privacyPolicyUrl` dart-define — not server-driven |

## Routes (before)

- `/settings` — hub
- `/settings/profile/*`, `/settings/notifications`
- **No** `/settings/privacy`, `/settings/terms`

## Backend (before)

| Endpoint | Status |
|----------|--------|
| `GET /api/mobile/settings` | Missing |
| `GET /api/mobile/settings/privacy` | Missing |
| `GET /api/mobile/settings/terms` | Missing |
| `POST /api/mobile/settings/sync` | Missing |
| `GET /api/mobile/notifications/settings` | Exists (unchanged) |

## Prisma (before)

- `NotificationSettings` — per user
- **No** `MobileUserSettings` or legal acceptance fields

## Cache / offline (before)

- `notificationSettingsKey`, `appConfigKey`, `profileKey`
- **No** user settings / legal document cache keys
- **No** settings outbox kind

## Gaps

1. No aggregate settings API
2. No legal document API with version + acceptance
3. No offline sync for theme/locale/acceptance
4. Privacy opens external URL only — no in-app screen
5. Terms not implemented

## Implementation plan

1. Add `MobileUserSettings` + `GET/POST` mobile settings routes
2. Flutter `settings/data` repository (cache-first)
3. Privacy + Terms pages with accept + offline cache
4. Outbox `settingsSync` + sync coordinator drain
5. Upgrade settings hub with provider-driven legal status
