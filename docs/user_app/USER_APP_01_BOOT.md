# USER_APP_01 — Boot / Splash / App Initialization

**Project:** PraniDoctor User App (`pranidoctor_user`)  
**Module:** Boot / Splash / App Initialization  
**Status:** COMPLETE  
**Date:** 2026-05-22

---

## Overview

Cold start is gated behind `/boot`. A single `BootPage` drives splash, config load, maintenance/update checks, session restore, and navigation — no login flash before tokens are validated.

Compat API paths (not literal `auth/me` / `app/config`):

| Spec | Actual path | Auth |
|------|-------------|------|
| `app/config` | `GET /api/mobile/app-config` | None |
| `auth/me` | `GET /api/mobile/me` | Bearer |
| Token refresh | `POST /api/mobile/auth/refresh` | Body: `refreshToken` |

---

## Architecture

```
lib/
├── app/
│   ├── bootstrap.dart          # Hive, Firebase, ProviderScope
│   ├── app_startup.dart        # Pre-hydrate cached config + warm caches
│   └── app_env.dart            # MINIMUM_APP_VERSION, UPDATE_URL dart-defines
├── core/
│   ├── auth/token_refresh.dart # Shared refresh + retry (boot + Dio 401)
│   └── session/                # Secure token storage
└── features/
    ├── app_config/             # DTO, repository, provider
    └── boot/
        ├── boot_controller.dart
        ├── boot_state.dart
        ├── boot_navigation.dart
        └── presentation/boot_page.dart
```

### Boot sequence

```mermaid
flowchart TD
  A[/boot] --> B[Parallel: splash 400ms + config + session restore]
  B --> C{Config OK?}
  C -->|No cache + offline| D[Error + Retry]
  C -->|Yes| E{Maintenance?}
  E -->|Yes| F[Maintenance UI + Retry]
  E -->|No| G{Force update?}
  G -->|Yes| H[Blocked update UI]
  G -->|No| I{Optional update?}
  I -->|Yes| J[Update / Not now]
  J --> K[Session restore]
  I -->|No| K
  K --> L[Refresh token if expired]
  L --> M[GET /api/mobile/me]
  M --> N[Boot ready]
  N --> O{Navigation engine}
  O -->|Guest| P[/welcome or /login]
  O -->|Authed + incomplete profile| Q[/settings/profile/edit]
  O -->|Authed| R[/home]
```

---

## Requirements checklist

| # | Requirement | Implementation |
|---|-------------|----------------|
| 1 | Splash flow | Logo + phased loading text; 400ms minimum splash overlapped with init |
| 2 | App initialization | `AppConfigRepository.loadConfig()` + `AppStartup` cache warm |
| 3 | Session restore | Secure storage → refresh if expired → `/me` validation |
| 4 | Token refresh | `refreshAccessToken()` with 2-attempt retry on transient errors; sign-out on auth failure |
| 5 | Force update | Semver vs `minimumVersion` or `updateRequired`; dart-define fallback |
| 6 | Optional update | Semver vs `recommendedVersion`; skippable |
| 7 | Maintenance mode | `maintenanceMode` from app-config or `SYS_MAINTENANCE` API error |
| 8 | Navigation engine | `resolveBootDestination()` — welcome/login/home/profile-edit |
| 9 | Performance | Parallel config + session + splash; no duplicate `/me` (hydrate profile) |
| 10 | UX | Loading, error retry, offline config banner, force/optional/maintenance screens |

---

## API integration

### `GET /api/mobile/app-config`

**Response `data` (current):**

```json
{
  "emergencyPhone": "+880…",
  "supportPhone": "+880…",
  "supportWhatsapp": "+880…",
  "minimumVersion": "2.0.0",
  "recommendedVersion": "2.1.0",
  "updateUrl": "https://play.google.com/…",
  "updateRequired": false,
  "updateMessage": "Please update for the latest fixes.",
  "maintenanceMode": false,
  "maintenanceMessage": "Scheduled maintenance until 10:00 UTC."
}
```

Version/maintenance fields are read from DB `Setting` key `mobile.app.config` (backend route updated in this module).

**Offline:** Cached 12h under Hive key `local_cache:app_config_snapshot`.

**Error codes handled:**

| Code | Boot behavior |
|------|---------------|
| `FORCE_UPDATE_REQUIRED` | Force-update screen (API hook ready) |
| `SYS_MAINTENANCE` | Maintenance screen |

### `POST /api/mobile/auth/refresh`

Used when access JWT is expired at boot. Invalid refresh token → secure cleanup + guest fallback.

### `GET /api/mobile/me`

Validates restored session. `401`/`TOKEN_INVALID` → sign out. Network failure without cache → continue unauthenticated (guest).

---

## Navigation decision engine

`lib/features/boot/boot_navigation.dart`:

| Condition | Destination |
|-----------|-------------|
| Not authenticated + welcome not seen | `/welcome` |
| Not authenticated + welcome seen | `/login` |
| Authenticated + `profileComplete == false` | `/settings/profile/edit` |
| Authenticated + profile complete | `/home` |

Router guards (`app_router.dart`) pin `/boot` while boot is blocked (error, maintenance, force update, optional update pending).

---

## Migration notes

### After pull

```bash
cd pranidoctor_user
flutter pub get
flutter gen-l10n
```

### Release dart-defines (until API version fields are seeded)

```bash
flutter build apk \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=MINIMUM_APP_VERSION=1.0.0 \
  --dart-define=UPDATE_URL=https://play.google.com/store/apps/details?id=…
```

### Backend / DB

Add optional fields to `mobile.app.config` setting JSON:

```json
{
  "supportPhone": "+8809612345678",
  "minimumVersion": "1.0.0",
  "recommendedVersion": "1.1.0",
  "updateUrl": "https://play.google.com/…",
  "maintenanceMode": false
}
```

### Router change (existing installs)

- **Before:** `initialLocation: /home` → login flash on cold start.
- **After:** `initialLocation: /boot` → session restored before auth redirect.

---

## Files changed (this completion pass)

### Created

- `lib/features/boot/boot_navigation.dart`
- `test/boot/boot_integration_test.dart`
- `docs/user_app/USER_APP_01_BOOT.md`

### Modified

- `lib/features/boot/boot_controller.dart` — parallel init, maintenance/optional update, session validation
- `lib/features/boot/boot_state.dart` — new phases + info types
- `lib/features/boot/presentation/boot_page.dart` — maintenance + optional update UI
- `lib/features/app_config/data/app_config_dto.dart` — version + maintenance fields
- `lib/features/app_config/data/app_config_repository.dart` — `SYS_MAINTENANCE` handling
- `lib/core/auth/token_refresh.dart` — retry on transient failures
- `lib/features/profile/presentation/profile_providers.dart` — `hydrate()` for boot
- `lib/routing/app_router.dart` — guards for blocked boot phases
- `lib/l10n/app_en.arb` — maintenance + optional update strings
- `pranidoctor-backend/.../mobile/app-config/route.ts` — expose version/maintenance from settings

---

## Remaining blockers

| Blocker | Impact | Workaround |
|---------|--------|------------|
| `FORCE_UPDATE_REQUIRED` not emitted by API yet | Server-driven force block untestable E2E | Client semver + dart-define |
| Feature flags in DB not in app-config | Remote feature toggles unavailable | Future backend change |
| Native splash not synced to Flutter phases | Brief white frame possible | `flutter_native_splash` (see `STORE_RELEASE.md`) |
| Push/Firebase config | Unrelated to boot | Documented separately |

---

## Verification

```bash
cd pranidoctor_user
dart analyze lib
flutter test test/boot/boot_integration_test.dart
```

### Manual test plan

1. **Fresh install + online** — boot phases → welcome/login or home.
2. **Returning user** — no login flash; lands on home.
3. **Offline + cached config** — completes with offline banner.
4. **Offline + no cache** — error + retry.
5. **Force update** — `MINIMUM_APP_VERSION=99.0.0` dart-define or API field.
6. **Optional update** — set `recommendedVersion` above installed; tap “Not now”.
7. **Maintenance** — set `maintenanceMode: true` in settings; retry when cleared.
8. **Expired token** — refresh at boot; invalid refresh → guest/login.
9. **Incomplete profile** — authed user with `profileComplete: false` → profile edit.
