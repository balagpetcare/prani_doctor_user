# USER_APP_18 — Settings Module Report

**Date:** 2026-05-22  
**Status:** ✅ Complete

## Existing state (before)

Thin settings hub with profile summary, local dark mode, notification link, external privacy URL. No settings repository, no terms, no server sync.

## Changes

### Backend
- Prisma `MobileUserSettings` + `MobileThemePreference` enum
- Migration `20260522200000_phase8_mobile_user_settings`
- Service `mobile-settings-service.ts` — legal config from `Setting.mobile.legal.config`
- Routes: `GET settings`, `GET settings/privacy`, `GET settings/terms`, `POST settings/sync`
- Seed `mobile.legal.config` in demo

### Web BFF
- Proxies under `src/app/api/mobile/settings/**`

### Flutter
- `lib/features/settings/data/` — paths, DTOs, repository
- `lib/features/settings/presentation/` — providers, privacy/terms pages, feedback widget
- Updated `settings_page.dart` — cache-first load, refresh, theme sync, privacy/terms navigation
- Offline: cache keys + `OutboxKind.settingsSync`

## APIs

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/mobile/settings` | User prefs + legal summary |
| GET | `/api/mobile/settings/privacy` | Privacy document + acceptance |
| GET | `/api/mobile/settings/terms` | Terms document + acceptance |
| POST | `/api/mobile/settings/sync` | Theme, locale, accept privacy/terms |

## Files modified

- `lib/features/settings/settings_page.dart`
- `lib/routing/app_routes.dart`, `app_router.dart`
- `lib/core/offline/local_cache_contract.dart`
- `lib/features/offline/data/outbox_item.dart`
- `lib/features/offline/data/sync_coordinator.dart`
- `lib/features/offline/presentation/offline_queue_panel.dart`
- `lib/l10n/app_en.arb`
- `prisma/schema.prisma`, `prisma/seed-demo.ts`

## Risks

- Legal URLs may 404 until marketing pages are hosted — in-app content fallback provided
- Theme sync is best-effort; local toggle remains primary UX
- Notification prefs remain on separate API (backward compatible)

## Testing

- `test/settings/settings_integration_test.dart` — DTO, theme mapping, sync payload
- Run: `flutter test test/settings/`

## Completion status

Phase 8 Settings module complete: Settings hub, Privacy, Terms, API connection, offline cache/sync.
