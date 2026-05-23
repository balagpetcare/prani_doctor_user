# USER_APP_18 — Settings

**Project:** `pranidoctor_user`  
**Phase:** 8 — Settings (Final)  
**Status:** Complete

## Audit (pre-implementation)

| Area | State |
|------|--------|
| Settings hub (profile, theme toggle, legal links) | Partial |
| Repository + cache + offline outbox | Done |
| Privacy / Terms pages | Done |
| Notification settings (separate API) | Done |
| Profile account (separate feature) | Done |
| **Sectioned hub + sub-screens** | Missing |
| **Theme / Language dedicated screens** | Missing |
| **Account / App / Preferences / About / Data & Sync** | Missing |
| **Apply server theme/locale on load** | Missing |
| **Duplicate update guard** | Missing |
| **SettingsNavigation + startup warm** | Missing |

Backend: `GET/POST /api/mobile/settings`, privacy, terms, sync. Notifications: `/api/mobile/notifications/settings`.

## Plan

1. Extend providers: apply bundle → theme/locale, sync guard, pending count.
2. Screens: account, preferences, app, language, theme, about, data-sync.
3. Refactor hub → sectioned navigation; move offline panel to data-sync.
4. Routes + l10n + startup cache warm.
5. Tests + validation.

## API mapping

| Flutter | Method | Path |
|---------|--------|------|
| `getSettings` | GET | `/api/mobile/settings` |
| `getPrivacy` | GET | `/api/mobile/settings/privacy` |
| `getTerms` | GET | `/api/mobile/settings/terms` |
| `sync` | POST | `/api/mobile/settings/sync` |
| Notification prefs | GET/PUT | `/api/mobile/notifications/settings` |
| Profile | GET/PATCH | `/api/mobile/auth/me` |
| App config | GET | `/api/mobile/app/config` |

**USER_APP_18_COMPLETE**
