# Store Release — Prani Doctor User App

**Repository:** `pranidoctor_user`  
**Package:** `com.pranidoctor.user.pranidoctor_user`  
**Version:** `1.0.0+1` (`pubspec.yaml`)  
**Platform:** Android (no `ios/` project in repo)  
**Updated:** 2026-05-22

---

## Release readiness summary

| Area | Status | Notes |
|------|--------|-------|
| **Release build script** | Ready | `scripts/build_release.ps1` — obfuscate + dart-defines |
| **Release keystore** | **Blocked** | `build.gradle.kts` still signs with **debug** keys |
| **CI variables** | **Missing** | No `.github/workflows/` in repo |
| **API env** | Ready (code) | `AppEnv` enforces `API_BASE_URL` in release |
| **Push config** | **Partial** | FCM deps present; no `google-services.json`; no Gradle plugin |
| **Store assets** | **Gap** | Default label `pranidoctor_user`; `@mipmap/ic_launcher` not in repo res tree |
| **Privacy policy** | **Gap** | No in-app link or hosted policy URL in repo |
| **Internal testing** | **Not documented** | Play internal track steps below |
| **Release checklist** | This doc | See § Final checklist |

**Verdict:** Build pipeline is production-hardened; **Play Store upload blocked** until signing, Firebase (if push on), store listing assets, and privacy policy are complete.

---

## Reuse current build setup

### Script (preferred)

```powershell
cd D:\PraniDoctor\pranidoctor_user
.\scripts\build_release.ps1 -ApiBaseUrl "https://api.your-production-host.com"
```

### Manual (equivalent)

```powershell
flutter build appbundle --release `
  --obfuscate --split-debug-info=build/debug-info `
  --dart-define=API_BASE_URL=https://api.your-production-host.com `
  --dart-define=ENABLE_PUSH=true `
  --dart-define=LOG_NETWORK=false
```

Use **`appbundle`** for Play Console (not only APK). Extend `build_release.ps1` to accept `-AppBundle` if desired.

### Gradle release config (existing)

```29:39:D:/PraniDoctor/pranidoctor_user/android/app/build.gradle.kts
    buildTypes {
        release {
            // TODO: replace with release keystore before Play Store upload.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            ...
        }
    }
```

---

## 1. Release keystore

### Generate (once per org)

```powershell
keytool -genkey -v -keystore pranidoctor-user-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pranidoctor-user
```

Store `.jks` **outside** git (see `android/.gitignore`: `**/*.jks`, `key.properties`).

### `android/key.properties` (local / CI secret)

```properties
storePassword=<from-secret-manager>
keyPassword=<from-secret-manager>
keyAlias=pranidoctor-user
storeFile=<absolute-or-relative-path-to-jks>
```

### Wire signing in `android/app/build.gradle.kts`

- Load `key.properties` when present.
- Define `signingConfigs { create("release") { ... } }`.
- Set `release.signingConfig = signingConfigs.getByName("release")`.
- Keep debug signing for `debug` build type only.

### Play App Signing

- Enroll in **Google Play App Signing** on first upload.
- Upload key = your release keystore; Google holds app signing key.

---

## 2. CI variables

No workflow exists today. Recommended GitHub Actions secrets:

| Secret | Required | Example / purpose |
|--------|----------|-------------------|
| `API_BASE_URL` | Yes | `https://api.pranidoctor.com` |
| `ANDROID_KEYSTORE_BASE64` | Yes | Base64-encoded `.jks` for CI |
| `ANDROID_KEYSTORE_PASSWORD` | Yes | Keystore password |
| `ANDROID_KEY_ALIAS` | Yes | `pranidoctor-user` |
| `ANDROID_KEY_PASSWORD` | Yes | Key password |
| `GOOGLE_SERVICES_JSON_BASE64` | If push | Contents of `google-services.json` |
| `ENABLE_PUSH` | Optional | `true` / `false` |

### Example CI steps

```yaml
env:
  API_BASE_URL: ${{ secrets.API_BASE_URL }}
steps:
  - uses: subosito/flutter-action@v2
    with:
      flutter-version: "3.29.x"  # match team SDK
  - run: flutter pub get
  - run: flutter analyze
  - run: flutter test
  - name: Decode keystore
    run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/upload-keystore.jks
  - name: Build App Bundle
    run: |
      flutter build appbundle --release \
        --obfuscate --split-debug-info=build/debug-info \
        --dart-define=API_BASE_URL=${{ secrets.API_BASE_URL }} \
        --dart-define=ENABLE_PUSH=true \
        --dart-define=LOG_NETWORK=false
  - uses: actions/upload-artifact@v4
    with:
      name: app-release-aab
      path: build/app/outputs/bundle/release/app-release.aab
```

Gate merges on `flutter analyze` (zero errors).

---

## 3. API environment

### Compile-time defines (`lib/app/app_env.dart`)

| Define | Release | Purpose |
|--------|---------|---------|
| `API_BASE_URL` | **Required** | Dio base URL; must not be empty or `example.com` in release |
| `ENABLE_PUSH` | `true` / `false` | Skip FCM when Firebase not configured |
| `LOG_NETWORK` | `false` | Forced off outside debug |

Production should point at **pranidoctor-backend** (not web BFF unless deployment routes mobile there):

- `/api/mobile/*` — auth, profile, bookings, notifications
- `/api/sync/*`, `/api/offline/*` — offline sync
- `/api/area/*` — area hierarchy

`assertProductionReady()` runs in `bootstrap()` before `runApp`.

### Version reporting

`PushRegistrationService` sends hardcoded `appVersion: '1.0.0'` — align with `pubspec.yaml` or read from `package_info_plus` before store release.

---

## 4. Push configuration

### Client (implemented)

- `firebase_core`, `firebase_messaging` in `pubspec.yaml`
- `bootstrap.dart` — `Firebase.initializeApp()` (fails gracefully if no config)
- `notification_coordinator.dart` — FCM + local notifications
- `POST /api/mobile/devices/register` via `PushRegistrationService`

### Gaps

| Item | Status |
|------|--------|
| `android/app/google-services.json` | Not in repo (gitignored or never added) |
| `com.google.gms.google-services` Gradle plugin | Not in `settings.gradle.kts` / app `build.gradle.kts` |
| Firebase project + FCM enabled | Ops task |
| Backend FCM send | Tokens stored; server push send may be incomplete — verify backend |

### If push disabled for v1

```powershell
--dart-define=ENABLE_PUSH=false
```

App still runs; device register may omit token.

### Android permissions

Add when enabling push (if not merged by FlutterFire):

- `INTERNET`
- `POST_NOTIFICATIONS` (Android 13+)

Verify merged manifest after adding `google-services.json`.

---

## 5. Store assets

### In-repo today

| Asset | Status |
|-------|--------|
| App icon `@mipmap/ic_launcher` | Referenced in manifest; **mipmap resources not present** under `android/app/src/main/res/` — run `flutter create .` platform refresh or add launcher icons |
| App name | `android:label="pranidoctor_user"` — change to **Prani Doctor** (or product name) |
| Splash | Default `launch_background.xml` only |

### Play Console required (not in repo)

| Asset | Spec |
|-------|------|
| Hi-res icon | 512×512 PNG |
| Feature graphic | 1024×500 |
| Phone screenshots | ≥ 2, 16:9 or 9:16 |
| Short description | ≤ 80 chars |
| Full description | ≤ 4000 chars |
| Content rating | Questionnaire |
| Data safety | See § Privacy |

### Branding tasks

1. Add `flutter_launcher_icons` or manual mipmap sets for all densities.
2. Update `AndroidManifest` `android:label`.
3. Optional: branded splash (`flutter_native_splash`).

---

## 6. Privacy policy

### Data collected (declare accurately)

| Data | Purpose | Storage |
|------|---------|---------|
| Phone, name, email | Account | Server + secure token storage |
| Location (area/village) | Service area | Server + Hive cache |
| Animal profiles | Bookings | Server |
| FCM token | Push | Server device registry |
| Appointment cache | Offline read | Hive (24h TTL) |
| Outbox | Offline write | Hive until sync |

### Required deliverables

- [ ] Hosted privacy policy URL (e.g. `https://pranidoctor.com/privacy`)
- [ ] Terms of service URL (if required by market)
- [ ] In-app link on Settings or login footer
- [ ] Play **Data safety** form aligned with policy
- [ ] Bengali/English copy if primary market is Bangladesh

No `privacy_policy.md` or in-app WebView exists in repo today.

---

## 7. Internal testing (Play Console)

### Track flow

1. Create app in Play Console → **Internal testing** track.
2. Upload first **AAB** signed with upload key (after §1 keystore).
3. Add testers via email list or Google Group (max 100 internal).
4. Complete **store listing** minimum fields even for internal.
5. Distribute → testers install from Play link.

### Smoke test matrix (before promoting to closed/open)

| # | Flow | Pass |
|---|------|------|
| 1 | Cold start → login (OTP/password) | ☐ |
| 2 | Profile load + edit (online) | ☐ |
| 3 | Area picker + doctor list | ☐ |
| 4 | Book consultation → inbox | ☐ |
| 5 | Appointment detail + history + cancel | ☐ |
| 6 | Airplane mode book → offline queue → sync | ☐ |
| 7 | Push token register (if ENABLE_PUSH=true) | ☐ |
| 8 | Notification tap → deep link to request | ☐ |
| 9 | Logout → no token leak on relaunch | ☐ |
| 10 | Release build against **production** API only | ☐ |

### Pre-upload build checks

```powershell
flutter analyze
flutter test
flutter build appbundle --release ...  # must succeed
```

Upload `build/debug-info/` to crash backend when Sentry/Crashlytics wired.

---

## 8. Versioning for store

| Field | Location | Current |
|-------|----------|---------|
| `versionName` | `pubspec.yaml` → `version: 1.0.0+1` | `1.0.0` |
| `versionCode` | `+1` build number | `1` |

Increment `+N` for every Play upload. Use semantic version for `1.0.0` → `1.0.1` patches.

---

## Final release checklist

### P0 — Blockers for Play upload

- [ ] Release keystore + `key.properties` + Gradle signing (not debug)
- [ ] Production `API_BASE_URL` in CI and local release script
- [ ] App bundle builds: `flutter build appbundle --release`
- [ ] Launcher icons + display name **Prani Doctor**
- [ ] Privacy policy URL live + Data safety form
- [ ] `flutter analyze` clean

### P1 — Strongly recommended

- [ ] `google-services.json` + Gradle plugin (if push enabled)
- [ ] GitHub Actions workflow + secrets
- [ ] `package_info_plus` for `appVersion` on device register
- [ ] Play internal testing smoke (§7 matrix)
- [ ] Symbol upload (`build/debug-info/`) to crash reporting

### P2 — Post-launch

- [ ] Backend FCM send verified end-to-end
- [ ] iOS target if App Store required
- [ ] Closed testing → production rollout staged %

---

## Related docs

- [PRODUCTION_READINESS.md](./PRODUCTION_READINESS.md) — hardening pass
- [DEVELOPER_SETUP.md](./DEVELOPER_SETUP.md) — local dart-define
- [FINAL_CERTIFICATE.md](./FINAL_CERTIFICATE.md) — sign-off template
- [PHASE_NOTIFICATION_COMPLETE.md](./PHASE_NOTIFICATION_COMPLETE.md) — FCM wiring

---

*Complete P0 checklist and run Composer command in FINAL_CERTIFICATE.md to mark PRODUCTION_RELEASE_READY.*
