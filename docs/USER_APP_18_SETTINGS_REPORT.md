# USER_APP_18 — Settings Module Report

**Project:** `pranidoctor_user`  
**Module:** `USER_APP_18_SETTINGS`  
**Date:** 2026-05-22  
**Status:** Complete

## 1. Current audit

| Area | Pre-work |
|------|----------|
| Settings hub (inline theme, legal links) | Partial |
| Repository + cache + offline outbox | Done |
| Privacy / Terms pages | Done |
| Notification settings (separate API) | Done |
| Profile account routes | Done |
| **Sectioned hub + sub-screens** | Missing |
| **Theme / Language pages** | Missing |
| **Account / App / Preferences / About / Data & Sync** | Missing |
| **Apply server theme/locale on load** | Missing |
| **Duplicate update guard** | Missing |

## 2. Plan

See `docs/user_app/USER_APP_18_SETTINGS.md`.

## 3. Implementation

- Sectioned settings hub with navigation to all sub-screens
- Account, Preferences, App, Language, Theme, About, Data & Sync pages
- Providers: cache-first load, apply theme/locale from server, sync guard
- `SettingsNavigation`; startup cache warm for settings
- Language sync: settings API + profile patch (cross-device + auth/me)
- Data & Sync: last sync, pending settings count, offline queue panel

## 4. Changed files

**New:** `settings_account_page.dart`, `settings_preferences_page.dart`, `settings_app_page.dart`, `settings_language_page.dart`, `settings_theme_page.dart`, `settings_about_page.dart`, `settings_data_sync_page.dart`, `settings_navigation.dart`, `settings_section_header.dart`, plan doc

**Updated:** `settings_page.dart`, `settings_providers.dart`, `privacy_page.dart`, `terms_page.dart`, routes, l10n, `app_startup.dart`, tests, report

## 5. API mapping

| Flutter | Method | Path |
|---------|--------|------|
| `getSettings` | GET | `/api/mobile/settings` |
| `getPrivacy` | GET | `/api/mobile/settings/privacy` |
| `getTerms` | GET | `/api/mobile/settings/terms` |
| `sync` | POST | `/api/mobile/settings/sync` |
| Notification prefs | GET/PUT | `/api/mobile/notifications/settings` |
| Profile locale | PATCH | `/api/mobile/auth/me` |
| App config | GET | `/api/mobile/app/config` |

## 6. State / provider flow

```
AppStartup → warm user_settings_snapshot cache
settingsProvider → cache → apply theme/locale → silent refresh
settingsUpdateInFlightProvider → blocks duplicate sync
syncInput / syncTheme / syncLocale → repository.sync → cache update
settingsPendingSyncCountProvider → outbox settingsSync items
settingsLastSyncProvider → settings.updatedAt
```

## 7. Sync flow

1. User changes theme/locale/legal acceptance → `POST /settings/sync`
2. Offline → outbox `settingsSync` → SyncCoordinator drains on reconnect
3. Data & Sync page → manual sync + full offline queue panel
4. Language also patches profile for auth/me consistency

## 8. Cache strategy

| Key | Content | TTL |
|-----|---------|-----|
| `user_settings_snapshot` | Settings bundle | profile TTL |
| `privacy_document_snapshot` | Privacy doc | app config TTL |
| `terms_document_snapshot` | Terms doc | app config TTL |

## 9. Validation

```
flutter test test/settings/  → 10/10 passed
dart analyze lib/features/settings  → 0 errors
```

## 10. Remaining blockers

- Bangla UI strings not in arb (English only in generated l10n)
- Session/device management not exposed in mobile API
- Notification prefs remain on separate endpoint (by design)
- `RadioListTile` deprecation infos (Flutter 3.32+)

## 11. Manual QA checklist

- [ ] `/settings` hub sections and pull-to-refresh
- [ ] Account → profile sub-routes
- [ ] Preferences → language, theme, notifications
- [ ] Theme system/light/dark syncs cross-device
- [ ] Language bn-BD / en-US syncs settings + profile
- [ ] Privacy/Terms accept + offline queue
- [ ] Data & Sync shows last sync + sync now
- [ ] About shows version + legal links
- [ ] Sign out from hub

**USER_APP_18_COMPLETE**
