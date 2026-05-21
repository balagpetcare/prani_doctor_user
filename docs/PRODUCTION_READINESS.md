# Production Readiness — PraniDoctor User App

**Repository:** `pranidoctor_user`  
**Updated:** 2026-05-22  
**Status:** Production-hardened (Android); store release requires signing + Firebase config

---

## Executive summary

The Flutter customer app implements auth, profile, area hierarchy, doctor discovery, appointments, notifications, and offline sync. This pass removed dead code, tightened security defaults, enabled release shrinking, and documented the release pipeline.

| Area | Status | Notes |
|------|--------|-------|
| Code cleanup | Done | Removed 20+ stub/unused files |
| Dead files | Done | Stubs, unused contracts, stale audit doc |
| Performance | Improved | Theme caching, lighter notification polling |
| Security | Hardened | Release API URL guard, OAuth SDKs removed, LOG_NETWORK debug-only |
| Build optimization | Done | R8 minify/shrink, obfuscation script, ProGuard rules |

---

## Completed in this pass

### Code cleanup
- Removed unused OAuth methods and dependencies (`google_sign_in`, `flutter_facebook_auth`)
- Removed example `UserProfileDto` and generated code
- Removed stub modules: `video_call_gateway`, `media_upload_coordinator`
- Removed unimplemented contract-only folders: `core/voice`, `core/ai`, `core/treatment`
- Removed unused `storage_contract.dart`, `sync_coordinator_contract.dart`
- Deleted stale `docs/FLUTTER_CURRENT_STATE.md`
- Enabled stricter lints in `analysis_options.yaml`

### Performance
- **Themes:** cached as top-level finals (no rebuild on every frame)
- **Notifications:** poll no longer invalidates full list every 30s (unread badge only)
- **Notification coordinator:** uses `ref.read` for side-effect init (not `ref.watch`)
- **Offline sync:** coordinator + provider dispose timers on app teardown

### Security
- **`AppEnv`:** release builds require `API_BASE_URL` dart-define (throws if missing)
- **`LOG_NETWORK`:** forced off outside debug mode
- **Auth tokens:** remain in `flutter_secure_storage` (unchanged)
- **Dev login bypass:** gated by `kDebugMode` only (unchanged)
- **Removed OAuth SDKs** until backend exchange is implemented (reduced attack surface)

### Build optimization
- Android release: `isMinifyEnabled`, `isShrinkResources`, ProGuard rules
- Release script: `scripts/build_release.ps1` with `--obfuscate --split-debug-info`
- Pinned `intl` version (removed `any`)

---

## Release build

### Required dart-defines

| Define | Release value | Purpose |
|--------|---------------|---------|
| `API_BASE_URL` | `https://your-backend-host` | Backend origin (includes `/api/mobile/*`, `/api/sync/*`, `/api/area/*`) |
| `ENABLE_PUSH` | `true` or `false` | FCM; set `false` if Firebase not configured |
| `LOG_NETWORK` | `false` | Never enable in production |

### Command

```powershell
cd D:\PraniDoctor\pranidoctor_user
.\scripts\build_release.ps1 -ApiBaseUrl "https://api.your-domain.com"
```

Or manually:

```powershell
flutter build apk --release `
  --obfuscate --split-debug-info=build/debug-info `
  --dart-define=API_BASE_URL=https://api.your-domain.com `
  --dart-define=ENABLE_PUSH=true `
  --dart-define=LOG_NETWORK=false
```

### Backend routing note

Point `API_BASE_URL` at **pranidoctor-backend** directly for:
- `/api/area/*` (foundation)
- `/api/sync/*`, `/api/offline/*` (offline architecture)

Mobile compat routes (`/api/mobile/*`) are served by backend or web BFF depending on deployment.

---

## Pre-store checklist (P0)

- [ ] Configure **release signing** in `android/app/build.gradle.kts` (replace debug signing)
- [ ] Add `google-services.json` + Gradle plugin if push enabled
- [ ] Set production `API_BASE_URL` in CI/CD dart-defines
- [ ] Run `flutter analyze` clean in CI
- [ ] Smoke test: login → book → inbox → offline queue → sync
- [ ] Upload debug symbols from `build/debug-info/` to crash reporting

---

## Pre-store checklist (P1)

- [ ] Add iOS target if App Store required
- [ ] Certificate pinning (optional, high-threat environments)
- [ ] Firebase Cloud Messaging sender on backend (push tokens stored; send not implemented)
- [ ] Privacy policy for cached profile/appointment data in Hive
- [ ] Play Store data safety form (PII: phone, location hierarchy, animals)

---

## Architecture (production modules)

```
lib/
├── app/           bootstrap, env, startup
├── core/          auth, cache, network, offline DTOs, session
├── features/
│   ├── auth/      OTP + password
│   ├── profile/   GET/PATCH /api/mobile/me + cache
│   ├── area/      hierarchy cache-first
│   ├── doctors/   discovery + booking
│   ├── service_requests/  appointments CRUD + outbox
│   ├── notifications/     FCM + local + poll
│   ├── offline/   outbox, sync, connectivity
│   ├── inbox/     appointments + notifications tabs
│   └── settings/  profile, theme, offline panel
└── routing/       go_router shell
```

---

## Removed files (dead code)

| Path | Reason |
|------|--------|
| `lib/features/calls/video_call_gateway.dart` | Stub, never wired |
| `lib/features/media/media_upload_coordinator.dart` | Stub, never wired |
| `lib/core/models/user_profile_dto.*` | Superseded by `mobile_me_dto.dart` |
| `lib/core/voice/*` | Contract-only, no implementation |
| `lib/core/ai/*` | Contract-only, no implementation |
| `lib/core/treatment/*` | Doctor persona, not customer app |
| `lib/core/offline/storage_contract.dart` | Unused |
| `lib/core/offline/sync_coordinator_contract.dart` | Unused |
| `docs/FLUTTER_CURRENT_STATE.md` | Stale audit |

Phase completion docs (`docs/PHASE_*.md`) retained as implementation record.

---

## Security model

| Data | Storage | TTL / notes |
|------|---------|-------------|
| Access / refresh tokens | `flutter_secure_storage` | Until logout |
| Profile snapshot | Hive (`local_cache:profile_snapshot`) | 24h |
| Appointment list cache | Hive | 24h |
| Area hierarchy | Hive (`area_cache_store`) | 7 days |
| Offline outbox | Hive (`_outbox_items`) | Until synced or dead |

JWT decode is client-side for expiry only; authorization is server-side.

---

## CI recommendations

```yaml
# Example steps
- run: flutter pub get
- run: flutter analyze
- run: flutter test
- run: flutter build apk --release --dart-define=API_BASE_URL=${{ secrets.API_BASE_URL }} ...
```

Gate merges on `flutter analyze` with zero errors.

---

## Known limitations

1. **Release signing** still uses debug keys in Gradle (documented TODO) — required before Play Store.
2. **Firebase** not committed; push gracefully skips if init fails.
3. **Android only** — no `ios/` project in repo.
4. **Backend FCM send** not implemented — device tokens registered but not pushed from server.
5. **OAuth** removed from client until server endpoints exist.

---

## Related docs

- `docs/DEVELOPER_SETUP.md` — local dev + dart-define
- `docs/FLUTTER_REUSE_PLAN.md` — integration architecture
- `docs/PHASE_*.md` — feature completion records
- `docs/MASTER_APP_ARCHITECTURE_PLAN.md` — long-term architecture

---

*Production readiness pass complete.*
