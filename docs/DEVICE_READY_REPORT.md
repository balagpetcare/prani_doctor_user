# Device Ready Report — Prani Doctor User App

**Date:** 2026-05-22  
**Scope:** Branding integration + physical Android device readiness  
**Repo:** `pranidoctor_user`

---

## Completed

### Phase 1 — Asset validation
- Scanned all `Image.asset` / `BrandAssets` references (8 UI call sites + pubspec tooling).
- Centralized paths in `lib/core/branding/brand_assets.dart` with `allReferencedPaths` for CI/tests.
- Verified `pubspec.yaml` directory registrations (no duplicate per-file entries).
- Added `BrandImage` widget with graceful icon fallbacks on every branded surface.
- Added `test/branding/brand_assets_test.dart` — fails if any referenced file is missing on disk.
- Mapped UI to **real bundled illustrations** (replacing 4.8 KB placeholder PNGs):
  - Splash illustration → `onboarding_farmer_livestock.png`
  - Onboarding slides → brand illustration pack (4 unique images)
  - Home hero → `farm_service_banner.png`
  - Home emergency → `doctor_visit_cow_farm.png`
  - In-app logo → `prani_doctor_alt_logo_earth_tone.png` (native splash/launcher still use primary logo path)

### Phase 2 — Splash + boot
- Native splash: `flutter_native_splash` white `#FFFFFF` + primary logo (Android generated drawables verified).
- `SplashPage`: logo → illustration → title animation; removes native splash in `initState` (no white flash).
- Boot pipeline verified: config → maintenance/update gates → session restore → token refresh → `/me` → route.
- Navigation gated on **both** splash animation complete **and** `BootPhase.ready` (prevents early route flicker).
- Error/update overlays reuse logo + `BrandImage` fallback.

### Phase 3 — Onboarding
- Persistence: Hive key `onboarding.completed` via `AuthPreferences`.
- Completion sets flag + invalidates `onboardingCompletedProvider` → routes to `/login`.
- Router fix: while onboarding provider is **loading**, redirect is suppressed (`null`) — prevents onboarding loop on relaunch.
- First launch: unauthenticated + not completed → `/onboarding`; subsequent → `/login`.

### Phase 4 — Home branding
- Hero banner, emergency card, promo card wired with `BrandImage` + fallbacks.
- Services empty state uses `empty_nearby_doctors.png` with fallback icon.
- Dashboard text-only empty hint unchanged (by design).

### Phase 5 — Mobile device readiness
- `.env` → `scripts/load_env.ps1` → `--dart-define` flags (not runtime `.env` read).
- `scripts/run_dev_device.ps1` auto-creates `.env` from example.
- `scripts/detect_lan_ip.ps1` documented for PC WiFi IP.
- **New:** `scripts/wireless_debug.ps1` for ADB wireless pairing/connect.
- Android debug: `INTERNET` permission + `usesCleartextTraffic` + `network_security_config.xml` for LAN HTTP.
- Connection Check screen: Settings → App settings → Connection check.

### Phase 6 — Quality gates

| Command | Result |
|---------|--------|
| `flutter clean` | Pass |
| `flutter pub get` | Pass |
| `dart analyze` | Pass (pre-existing warnings only; no new errors) |
| `flutter test` | **148/148 pass** (includes new branding test) |
| `flutter build apk --debug` | Pass → `build/app/outputs/flutter-apk/app-debug.apk` |

---

## Fixed

| Issue | Fix |
|-------|-----|
| Placeholder PNGs on splash/onboarding/home hero/emergency | Pointed `BrandAssets` to full-size brand illustrations |
| Missing `errorBuilder` on onboarding/home/services images | `BrandImage` used everywhere |
| Onboarding loop on relaunch (provider loading → false) | Router returns `null` while `onboardingCompletedProvider` loads |
| Unused `welcomeSeenAsync` watch in router | Removed unused import/watch |
| `flutter_native_splash: ios: true` with no iOS project | Set `ios: false` |
| No wireless debug helper | Added `scripts/wireless_debug.ps1` |
| No automated asset existence check | Added `test/branding/brand_assets_test.dart` |

---

## Remaining (non-blocking)

| Item | Notes |
|------|-------|
| `prani_doctor_primary_logo.png` | Still placeholder (4.8 KB) — used by **native splash + launcher only** |
| `prani_doctor_app_icon.png` | Placeholder — regenerate launcher after final icon export |
| `assets/images/onboarding/onboarding_0*.png` | Legacy placeholders; no longer referenced in code |
| `assets/images/home/hero_farm_vet.png`, `emergency_vet.png` | Legacy placeholders; superseded by brand illustrations |
| `WelcomePage` route | Exists but boot flow skips it (onboarding → login); intentional, not removed |
| `assets/brand/guidelines/` | Design reference only — correctly excluded from pubspec |
| `assets.zip` | Archive duplicate of `assets/` — optional cleanup |

---

## Manual action required

1. **Replace final logo + app icon** (same filenames):
   - `assets/brand/logos/prani_doctor_primary_logo.png`
   - `assets/brand/app_icons/prani_doctor_app_icon.png`
   Then regenerate:
   ```powershell
   cd D:\PraniDoctor\pranidoctor_user
   dart run flutter_native_splash:create
   dart run flutter_launcher_icons
   ```

2. **Set PC LAN IP in `.env`:**
   ```powershell
   .\scripts\detect_lan_ip.ps1
   # Edit .env: API_BASE_URL=http://<YOUR_IP>:3000
   ```

3. **Start backend** on same machine:
   ```powershell
   cd D:\PraniDoctor\pranidoctor-backend
   npm run dev
   ```

4. **Windows Firewall:** allow inbound TCP **3000** on Private network.

5. **Phone pre-flight:** browser → `http://<PC_IP>:3000/live` must return JSON.

6. **Wireless debugging (optional):**
   ```powershell
   .\scripts\wireless_debug.ps1
   adb pair <ip>:<pair-port>   # enter pairing code on phone
   .\scripts\wireless_debug.ps1 -DeviceIp <debug-ip> -Port 5555
   ```

---

## Screenshots required (capture on physical device)

Save under `docs/screenshots/device-ready/` (create folder):

| # | Screen | Filename suggestion |
|---|--------|---------------------|
| 1 | Native splash (cold start) | `01_native_splash.png` |
| 2 | Flutter `SplashPage` mid-animation | `02_flutter_splash.png` |
| 3 | Onboarding slide 1 | `03_onboarding_01.png` |
| 4 | Onboarding slide 4 + CTA | `04_onboarding_04.png` |
| 5 | Login after onboarding | `05_login.png` |
| 6 | Home hero banner | `06_home_hero.png` |
| 7 | Home emergency card | `07_home_emergency.png` |
| 8 | Home promo card | `08_home_promo.png` |
| 9 | Services empty doctors | `09_services_empty.png` |
| 10 | Settings → Connection check (all green) | `10_connection_check.png` |

---

## Device run command

```powershell
cd D:\PraniDoctor\pranidoctor_user
.\scripts\run_dev_device.ps1
```

List devices / pick specific device:

```powershell
.\scripts\run_dev_device.ps1 -ListDevices
.\scripts\run_dev_device.ps1 -Device <device-id>
```

Install debug APK only (no hot reload):

```powershell
flutter install --debug
# or
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

---

## Changed files (this pass)

```
lib/core/branding/brand_assets.dart
lib/core/branding/brand_image.dart          (new)
lib/features/boot/presentation/boot_page.dart
lib/features/boot/presentation/pages/splash_page.dart
lib/features/onboarding/presentation/onboarding_page.dart
lib/features/auth/presentation/welcome_page.dart
lib/features/home/presentation/widgets/home_hero_banner.dart
lib/features/home/presentation/widgets/home_emergency_card.dart
lib/features/home/presentation/widgets/home_promo_card.dart
lib/features/services/services_page.dart
lib/routing/app_router.dart
pubspec.yaml
scripts/wireless_debug.ps1                  (new)
test/branding/brand_assets_test.dart        (new)
docs/DEVICE_READY_REPORT.md                 (new)
```
