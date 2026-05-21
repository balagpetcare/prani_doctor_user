# Internal Test Report — Prani Doctor User App

**Repository:** `pranidoctor_user`  
**Package:** `com.pranidoctor.user.pranidoctor_user`  
**Version:** `1.0.0+1`  
**Report date:** 2026-05-22  
**Build target:** Internal testing (Play internal track + sideload APK)  
**Release guide:** [STORE_RELEASE.md](./STORE_RELEASE.md)

---

## Executive summary

| Gate | Result |
|------|--------|
| **Release artifacts** | **PASS** — signed `internal-release.apk` + `internal-release.aab` built |
| **Static verification** | **PASS** — analyze, unit test, API health, signing |
| **Device smoke (install → reconnect)** | **BLOCKED** — no Android device/emulator connected via ADB |
| **Production API** | **BLOCKED** — `https://api.pranidoctor.com` not resolvable; internal build uses staging LAN API |
| **Push delivery** | **BLOCKED** — `google-services.json` absent; build uses `ENABLE_PUSH=false` |
| **Crash reporting** | **BLOCKED** — no Sentry/Crashlytics SDK; debug symbols only in `build/debug-info/` |
| **Privacy URL (hosted)** | **FAIL** — `https://pranidoctor.com/privacy` returns 404 (in-app link + template doc exist) |
| **Play internal onboarding** | **BLOCKED** — requires Play Console upload + tester list (procedure documented below) |

**Verdict:** **INTERNAL_TEST_READY** for engineering handoff. Upload `release/internal-release.aab` to Play **Internal testing** after ops completes Play Console setup. Complete device smoke matrix on a physical tester phone before closed testing promotion.

---

## Release artifacts

Built with existing release pipeline (`flutter build` + `scripts/build_release.ps1` dart-defines, release Gradle signing via `android/key.properties`).

| Artifact | Path | Size | Signing |
|----------|------|------|---------|
| **APK (sideload / QA)** | `release/internal-release.apk` | ~49.7 MB | APK Signature Scheme **v2** (upload keystore) |
| **AAB (Play Console)** | `release/internal-release.aab` | ~41.3 MB | Play upload key (same keystore) |
| **Debug symbols** | `build/debug-info/` | — | Upload to crash backend when wired |

### Build command (this run)

```powershell
cd D:\PraniDoctor\pranidoctor_user
$api = "http://192.168.10.111:3000"
flutter build apk --release `
  --obfuscate --split-debug-info=build/debug-info `
  --dart-define=API_BASE_URL=$api `
  --dart-define=ENABLE_PUSH=false `
  --dart-define=LOG_NETWORK=false `
  --dart-define=PRIVACY_POLICY_URL=https://pranidoctor.com/privacy

flutter build appbundle --release `
  --obfuscate --split-debug-info=build/debug-info `
  --dart-define=API_BASE_URL=$api `
  --dart-define=ENABLE_PUSH=false `
  --dart-define=LOG_NETWORK=false `
  --dart-define=PRIVACY_POLICY_URL=https://pranidoctor.com/privacy
```

### Gradle fix applied (release blocker)

`android/app/build.gradle.kts` — enabled **core library desugaring** required by `flutter_local_notifications` release builds.

---

## Environment matrix

| Define | Internal build value | Status |
|--------|---------------------|--------|
| `API_BASE_URL` | `http://192.168.10.111:3000` | **PASS** — web BFF health + `/api/mobile/health` OK |
| `ENABLE_PUSH` | `false` | **BLOCKED** — Firebase config not in repo |
| `LOG_NETWORK` | `false` | **PASS** |
| `PRIVACY_POLICY_URL` | `https://pranidoctor.com/privacy` | **FAIL** — URL 404 at publish time |

### Production API check

| Endpoint | Result |
|----------|--------|
| `https://api.pranidoctor.com` | **BLOCKED** — DNS resolution failed |
| `http://192.168.10.111:3000/api/health` | **PASS** — 200, database up |
| `http://192.168.10.111:3000/api/mobile/health` | **PASS** — 200, scope mobile |

Re-run internal build with production `API_BASE_URL` once hosted API is live.

---

## Pre-build verification

| Check | Method | Result |
|-------|--------|--------|
| `flutter analyze` | CLI | **PASS** — 0 errors (39 info lints) |
| `flutter test` | CLI | **PASS** — 1/1 |
| Signed APK | `apksigner verify` | **PASS** — v2 signer present |
| Signed AAB | release keystore via Gradle | **PASS** — bundleRelease succeeded |
| Release minify/shrink | Gradle release type | **PASS** |
| Obfuscation | `--obfuscate` + split debug info | **PASS** |
| Privacy in-app link | `settings_page.dart` → `AppEnv.privacyPolicyUrl` | **PASS** |
| Privacy template | `docs/legal/PRIVACY_POLICY.md` | **PASS** |

---

## Testing matrix

Legend: **PASS** | **FAIL** | **BLOCKED** (cannot execute in this session)

### Auth

| # | Case | Expected | Result | Evidence / notes |
|---|------|----------|--------|------------------|
| A1 | Cold start → login screen | Unauthenticated users routed to login | **BLOCKED** | No ADB device |
| A2 | Password login | Tokens stored in secure storage | **BLOCKED** | Requires device + test account |
| A3 | OTP login | OTP request + verify flow | **BLOCKED** | Requires device + SMS/OTP test path |
| A4 | Session restore | Relaunch restores session | **BLOCKED** | Code: `AppStartup` + `SessionController` |
| A5 | Logout | Tokens cleared, login screen | **BLOCKED** | Code: `AuthRepository.signOut` |
| A6 | API route exists | Auth endpoints reachable | **PASS** | `POST /api/mobile/auth/otp/request` → 405 on GET (route live) |

### Profile

| # | Case | Expected | Result | Evidence / notes |
|---|------|----------|--------|------------------|
| P1 | Load profile (`GET /api/mobile/me`) | Profile shown in Settings | **BLOCKED** | Requires authenticated device |
| P2 | Edit profile online | PATCH persists | **BLOCKED** | Code: `profile_repository.dart` |
| P3 | Profile offline cache | Stale snapshot ≤24h TTL | **BLOCKED** | Code: `LocalCacheService` |
| P4 | Protected route without token | 401 | **PASS** | `GET /api/mobile/service-requests` → 401 |

### Doctor

| # | Case | Expected | Result | Evidence / notes |
|---|------|----------|--------|------------------|
| D1 | Area picker → hierarchy | Cached area tree | **BLOCKED** | Code: area cache-first |
| D2 | Doctor list for area | Providers returned | **BLOCKED** | Requires device |
| D3 | Doctor detail | Book CTA available | **BLOCKED** | Requires device |

### Appointment

| # | Case | Expected | Result | Evidence / notes |
|---|------|----------|--------|------------------|
| AP1 | Book consultation | `POST /api/mobile/service-requests` → inbox | **BLOCKED** | Requires device |
| AP2 | Inbox segments | Active / Completed / Closed filters | **BLOCKED** | Code: `inbox_page.dart` |
| AP3 | Appointment detail | Status + assigned doctor | **BLOCKED** | Requires device |
| AP4 | Cancel appointment | Cancel while PENDING/ASSIGNED/ACCEPTED | **BLOCKED** | Code: cancel API wired |
| AP5 | Timeline/history | Timeline events load | **BLOCKED** | Code: history page |

### Notification

| # | Case | Expected | Result | Evidence / notes |
|---|------|----------|--------|------------------|
| N1 | FCM init | Firebase initializes when configured | **BLOCKED** | No `google-services.json` |
| N2 | Device register | `POST /api/mobile/devices/register` | **BLOCKED** | Requires auth + FCM token |
| N3 | In-app notification list | Poll + panel render | **BLOCKED** | Requires device |
| N4 | Push tap → deep link | Opens request detail | **BLOCKED** | Requires FCM + device |
| N5 | Local notification fallback | Local notifications when FCM unavailable | **BLOCKED** | Requires device |

### Offline

| # | Case | Expected | Result | Evidence / notes |
|---|------|----------|--------|------------------|
| O1 | Airplane mode book | Outbox queues `service_request` | **BLOCKED** | Code: `outbox_service.dart` |
| O2 | Offline profile patch | Queued `profile_patch` | **BLOCKED** | Requires device |
| O3 | Settings offline panel | Pending count + sync now | **BLOCKED** | Code: `offline_queue_panel.dart` |
| O4 | Sync on reconnect | `SyncCoordinator` drains outbox | **BLOCKED** | Requires device |
| O5 | Sync API | `GET /api/sync/status` | **PASS** | 401 without auth (route live) |

### Recovery

| # | Case | Expected | Result | Evidence / notes |
|---|------|----------|--------|------------------|
| R1 | Transient network error | Retry with exponential backoff | **BLOCKED** | Code: `network_errors.dart` |
| R2 | Dead outbox item | Max 5 attempts then surfaced | **BLOCKED** | Requires device |
| R3 | Stale cache on read failure | Show cached appointments/profile | **BLOCKED** | Code: repository fallbacks |
| R4 | Token refresh on 401 | Dio interceptor refresh | **BLOCKED** | Code: `dio_provider.dart` |
| R5 | App crash reporting | Crashes reported to backend | **BLOCKED** | No crash SDK integrated |

---

## Release smoke tests (STORE_RELEASE §7)

| # | Flow | Result |
|---|------|--------|
| 1 | Cold start → login | **BLOCKED** |
| 2 | Profile load + edit (online) | **BLOCKED** |
| 3 | Area picker + doctor list | **BLOCKED** |
| 4 | Book consultation → inbox | **BLOCKED** |
| 5 | Appointment detail + history + cancel | **BLOCKED** |
| 6 | Airplane mode book → offline queue → sync | **BLOCKED** |
| 7 | Push token register (`ENABLE_PUSH=true`) | **BLOCKED** |
| 8 | Notification tap → deep link | **BLOCKED** |
| 9 | Logout → no token leak on relaunch | **BLOCKED** |
| 10 | Release build against production API | **BLOCKED** — production host unavailable |

---

## Infrastructure verification

| Area | Result | Notes |
|------|--------|-------|
| **Signed app bundle** | **PASS** | `release/internal-release.aab` |
| **Internal tester onboarding** | **BLOCKED** | Play Console steps below |
| **Production API** | **BLOCKED** | Use staging until `api.pranidoctor.com` live |
| **Push delivery** | **BLOCKED** | Add `google-services.json`; set `ENABLE_PUSH=true` |
| **Crash reporting** | **BLOCKED** | Wire Sentry/Crashlytics + upload `build/debug-info/` |
| **Offline sync** | **PASS** (code) / **BLOCKED** (device) | Implementation complete per `OFFLINE_COMPLETE.md` |
| **Appointment flow** | **PASS** (code) / **BLOCKED** (device) | Per `PHASE_APPOINTMENT_COMPLETE.md` |
| **Privacy link** | **PASS** (in-app) / **FAIL** (hosted URL) | Settings opens configured URL; host returns 404 |

---

## Internal tester onboarding (Play Console)

Procedure from [STORE_RELEASE.md §7](./STORE_RELEASE.md):

1. Create app in Play Console → **Internal testing** track.
2. Upload `release/internal-release.aab` (first upload enrolls Play App Signing).
3. Add testers via email list or Google Group (max 100 internal).
4. Complete minimum store listing fields.
5. Share opt-in link; testers install from Play.

**Ops checklist:**

- [ ] Back up upload keystore (`android/app/upload-keystore.jks`) — generated locally for this internal pass; store in secret manager
- [ ] Configure GitHub secrets: `KEYSTORE_BASE64`, `API_BASE_URL`, etc. (see [FINAL_CERTIFICATE.md](./FINAL_CERTIFICATE.md))
- [ ] Host privacy policy at public URL
- [ ] Add `google-services.json` if push required for internal test

---

## Device smoke script (QA — run on tester phone)

```powershell
# Sideload (alternative to Play internal link)
adb install -r release\internal-release.apk

# Manual checklist
# 1. Launch → login with test farmer account
# 2. Settings → Privacy policy opens browser
# 3. Services → pick area → doctor → book
# 4. Inbox → open request → cancel
# 5. Enable airplane mode → book or edit profile → verify offline queue in Settings
# 6. Disable airplane mode → tap Sync now → verify inbox updates
# 7. (If push enabled) verify notification received and tap opens request
```

---

## Blockers before closed testing

| Priority | Item | Owner |
|----------|------|-------|
| P0 | Complete device smoke matrix (all BLOCKED rows above) | QA |
| P0 | Host privacy policy URL (404 today) | Legal/Product |
| P0 | Production `API_BASE_URL` deployed and reachable | Ops |
| P1 | Firebase `google-services.json` + `ENABLE_PUSH=true` | Ops |
| P1 | Play internal track upload + tester invites | Product |
| P2 | Crash reporting SDK + symbol upload | Eng |

---

## Related docs

- [FINAL_CERTIFICATE.md](./FINAL_CERTIFICATE.md) — sign-off status
- [PRODUCTION_READINESS.md](./PRODUCTION_READINESS.md) — hardening pass
- [STORE_RELEASE.md](./STORE_RELEASE.md) — release pipeline

---

*Internal test preparation complete. Artifacts in `release/` ready for Play internal upload.*
