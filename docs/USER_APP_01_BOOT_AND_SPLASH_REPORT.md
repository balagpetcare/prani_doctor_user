# USER_APP_01 — Boot & Splash Report

**Project:** PraniDoctor User App (`pranidoctor_user`)  
**Phase:** 1 — Splash + App Init + Session Foundation  
**Status:** COMPLETE  
**Date:** 2026-05-22

---

## 1. Pre-implementation analysis

### What existed (PARTIAL)

| Area | State |
|------|-------|
| Native Android splash | Present (`launch_background.xml`) — no Flutter boot route |
| Session restore | Logic in `AppStartup` microtask — no UI gate |
| Token refresh | Duplicated in `AuthRepository` and `dio_provider` |
| `/api/mobile/me` | Complete via `ProfileRepository` + `mobileMeProvider` |
| `/api/mobile/app-config` | **Missing** — only compile-time `AppEnv` |
| Force update | **Missing** |
| Router guards | Auth-only — caused login flash before session restore |
| Boot optimization | Sequential; no parallel config + session |

### API reference (web/backend)

| Endpoint | Method | Auth | Response `data` |
|----------|--------|------|-----------------|
| `/api/mobile/app-config` | GET | None | `{ emergencyPhone, supportPhone, supportWhatsapp }` |
| `/api/mobile/me` | GET/PATCH | Bearer | Profile object (used as session “me”) |
| `/api/mobile/auth/refresh` | POST | None (body token) | Rotated access + refresh tokens |

**Note:** Task spec referenced `auth/me` and `app/config`. Actual compat paths are `/api/mobile/me` and `/api/mobile/app-config`.

---

## 2. Implementation summary

### New files

```
lib/core/auth/token_refresh.dart          — shared refresh-token rotation
lib/core/utils/version_utils.dart         — semver compare for force-update
lib/features/app_config/data/             — api paths, DTO, repository
lib/features/app_config/presentation/     — appConfigProvider
lib/features/boot/boot_state.dart         — boot phases + force-update info
lib/features/boot/boot_controller.dart    — orchestrates cold start
lib/features/boot/presentation/boot_page.dart — Splash / Init / Update / Restore UI
```

### Modified files

| File | Change |
|------|--------|
| `lib/routing/app_routes.dart` | Added `/boot` |
| `lib/routing/app_router.dart` | `initialLocation: /boot`; boot + auth redirect guards; `RouterNotifier` listens to boot state |
| `lib/app/app_startup.dart` | Preloads cached app config only (session moved to boot) |
| `lib/app/app_env.dart` | `MINIMUM_APP_VERSION`, `UPDATE_URL` dart-defines |
| `lib/core/network/dio_provider.dart` | Uses shared `refreshAccessToken` |
| `lib/features/auth/data/auth_repository.dart` | Delegates refresh to shared helper |
| `lib/features/auth/data/auth_api_paths.dart` | `/api/mobile/app-config` marked unauthenticated |
| `lib/core/offline/local_cache_contract.dart` | `appConfigKey` + 12h TTL |
| `lib/l10n/app_en.arb` | Boot flow strings |
| `pubspec.yaml` | `package_info_plus` |

### Boot sequence

```mermaid
flowchart TD
  A[/boot route] --> B[Splash ~400ms]
  B --> C[Parallel: loadConfig + restoreFromStorage]
  C --> D{Config OK?}
  D -->|No cache + offline| E[Error + Retry]
  D -->|Yes| F[Force update check]
  F -->|Blocked| G[Force update UI]
  F -->|OK| H[Token refresh if expired]
  H --> I[GET /api/mobile/me + background sync]
  I --> J[Boot ready → /home or /login]
```

### Requirements checklist

| # | Requirement | Status |
|---|-------------|--------|
| 1 | Analyze current implementation | Done — see §1 |
| 2 | No architecture redesign | Kept Riverpod + go_router + feature folders |
| 3 | Flutter + Riverpod structure | Followed |
| 4 | Reuse existing widgets/providers/services | `SessionController`, `ProfileRepository`, `SyncCoordinator`, `LocalCacheService` |
| 5 | Real API endpoints only | `GET /api/mobile/app-config`, `GET /api/mobile/me`, `POST /api/mobile/auth/refresh` |
| 6 | Loading / error / empty states | Per-phase loading text; error + retry; empty config hint |
| 7 | Offline-ready repository | `AppConfigRepository` cache-first with retry |
| 8 | Boot optimization, token refresh, force update | Parallel fetch; shared refresh; client-side force update |
| 9 | Navigation guards | Boot gate prevents login flash |
| 10 | No duplicate providers | Single `bootControllerProvider`, `appConfigProvider` |

---

## 3. State & UI mapping

| Boot phase | Screen label | User sees |
|------------|--------------|-----------|
| `splash` | Splash | Logo + “Starting…” |
| `initializing` | App Init | “Loading app settings…” |
| `checkingUpdate` | Update Check | “Checking for updates…” |
| `restoringSession` | Session Restore | “Restoring your session…” |
| `forceUpdate` | Force update | Blocked with store link |
| `error` | Error | Network message + Try again |
| `ready` | — | Auto-navigate |

---

## 4. Migration notes

### Dependencies

Run after pull:

```bash
flutter pub get
flutter gen-l10n
```

New dependency: `package_info_plus` (app version for update check).

### Optional dart-defines (release)

```bash
flutter run \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=MINIMUM_APP_VERSION=1.0.0 \
  --dart-define=UPDATE_URL=https://play.google.com/store/apps/details?id=...
```

- `MINIMUM_APP_VERSION` — client-side force update until backend exposes version fields.
- `UPDATE_URL` — opened from force-update screen.

### Router behavior change

- **Before:** `initialLocation: /home` → brief redirect to `/login` on cold start.
- **After:** `initialLocation: /boot` → session restored before auth redirect.

### Cache

App config cached under Hive key `local_cache:app_config_snapshot` (12h TTL). First offline launch after a successful online boot will use cached config.

### Backend follow-up (recommended)

Extend `GET /api/mobile/app-config` to return:

```json
{
  "minimumVersion": "2.0.0",
  "updateUrl": "https://play.google.com/...",
  "updateRequired": false,
  "updateMessage": "..."
}
```

Client DTO already parses these fields. Seeded `mobile.app.config` feature flags (`demoBanner`, etc.) are still not exposed by the API.

---

## 5. Unresolved blockers

| Blocker | Impact | Workaround |
|---------|--------|------------|
| Backend does not return version fields on app-config | Force update only via dart-define or future API | Use `MINIMUM_APP_VERSION` at build time |
| No live `FORCE_UPDATE_REQUIRED` error from API | Server-driven block not testable end-to-end | Client semver check implemented; API hook ready |
| Firebase / push config missing | Unrelated to boot; push registration may fail silently | Documented in `STORE_RELEASE.md` |
| `platform: 'android'` hardcoded in auth | iOS builds send wrong platform | Out of scope for USER_APP_01 |
| Feature flags in DB not in app-config response | Home cannot toggle features from remote config | Requires backend change |

---

## 6. Verification

```bash
cd pranidoctor_user
dart analyze lib   # exit 0
```

Manual test plan:

1. **Fresh install + online** — boot phases → login or home if tokens valid.
2. **Returning user** — no login flash; lands on home after restore.
3. **Offline, cached config** — boot completes with “Using saved settings (offline)”.
4. **Offline, no cache** — error screen with retry.
5. **Force update** — build with `--dart-define=MINIMUM_APP_VERSION=99.0.0` → blocked on update screen.
6. **Expired token** — refresh via `/api/mobile/auth/refresh`; 401 retry uses shared helper.

---

## 7. Files touched (quick reference)

**Added:** 9 Dart files + this report  
**Modified:** 10 files  
**Removed:** 0  

No duplicate session or auth providers introduced.
