# Phase Profile & Location — Complete

**Repository:** `pranidoctor_user`  
**Completed:** 2026-05-22

## Summary

| Feature | API | UI |
|---------|-----|-----|
| User profile (GET/PATCH) | `/api/mobile/me` | Home, Settings, Profile edit |
| Division | `GET /api/area/divisions` | AreaPicker |
| District | `GET /api/area/divisions/:id/districts` | AreaPicker |
| Upazila | `GET /api/area/districts/:id/upazilas` | AreaPicker |
| Union | `GET /api/area/upazilas/:id/unions` | AreaPicker |
| Village | `GET /api/area/unions/:id/villages` | AreaPicker |

## Files

- `lib/features/profile/data/` — `mobile_me_dto.dart`, `profile_repository.dart`
- `lib/features/profile/presentation/` — `profile_providers.dart`, `profile_edit_page.dart`
- `lib/features/area/data/` — `area_repository.dart`, `area_cache_store.dart`
- `lib/features/area/presentation/area_picker.dart`
- Updated: `HomePage`, `SettingsPage`, `AppStartup`, `api_envelope.dart`, routing, l10n

## Config

Point `API_BASE_URL` at **backend** (foundation `/api/area/*` is not proxied by Next.js web):

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:3001
```

## UI reuse

- **HomePage** — same centered layout; shows name, phone, area + edit link
- **SettingsPage** — same `ListView`; profile block + edit tile
- **Profile edit** — nested route `/settings/profile`; cascading dropdowns

*Profile phase complete.*
