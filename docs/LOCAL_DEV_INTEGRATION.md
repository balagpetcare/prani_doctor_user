# Local Dev Integration — Android + PC Backend (WiFi)

Run the **PraniDoctor User** Flutter app on a **physical Android phone** against **pranidoctor-backend** on your PC over the same WiFi network.

---

## Architecture

| Component | Role | Default port |
|-----------|------|--------------|
| **pranidoctor-backend** | Mobile API (`/api/mobile/*`, `/api/ai/*`, uploads) | **3000** |
| **pranidoctor_user** (Flutter) | End-user app | — |
| **pranidoctor-web** | Admin/web BFF (optional for this flow) | 3001 |

The mobile app talks **directly to the backend** via `API_BASE_URL`. Do **not** point the app at `localhost` on a physical device — that refers to the phone itself.

---

## 1. Prerequisites

- Flutter SDK (see `pubspec.yaml` SDK constraint)
- Node 20+ for backend
- PostgreSQL (+ Redis if OTP enabled) for backend
- Android phone + USB debugging **or** wireless debugging
- PC and phone on the **same WiFi**

```powershell
cd D:\PraniDoctor\pranidoctor_user
flutter doctor
flutter pub get
```

---

## 2. Backend on PC

```powershell
cd D:\PraniDoctor\pranidoctor-backend
copy .env.example .env
# Edit DATABASE_URL, JWT secrets, etc.

npm install
npx prisma migrate deploy
npm run db:seed
npm run db:seed:demo   # optional demo data + customer 8801701022274

npm run dev
```

Confirm backend is listening:

```powershell
curl http://localhost:3000/api/mobile/app-config
```

Backend binds `0.0.0.0` by default (all interfaces) — required for LAN access.

---

## 3. Find your PC LAN IP

```powershell
cd D:\PraniDoctor\pranidoctor_user
.\scripts\detect_lan_ip.ps1
```

Or manually: `ipconfig` → **IPv4 Address** under Wi-Fi (e.g. `192.168.0.42`).

---

## 4. Configure the Flutter app

```powershell
cd D:\PraniDoctor\pranidoctor_user
copy .env.example .env
```

Edit `.env`:

```env
APP_ENV=dev
API_BASE_URL=http://192.168.0.42:3000
LOG_NETWORK=true
ENABLE_PUSH=false
```

| Target | API_BASE_URL |
|--------|----------------|
| Physical phone (WiFi) | `http://<PC_LAN_IP>:3000` |
| Android emulator | `http://10.0.2.2:3000` |
| iOS simulator | `http://localhost:3000` |

---

## 5. Windows Firewall

Allow inbound **TCP 3000** on **Private** network profile (one-time):

- Windows Security → Firewall → Advanced → Inbound Rules → New Rule → Port → TCP 3000

Quick test from phone browser: `http://<PC_IP>:3000/api/mobile/app-config` (should return JSON).

---

## 6. Run on Android device

Enable **Developer options** + **USB debugging** on the phone. Connect via USB (or wireless adb).

```powershell
cd D:\PraniDoctor\pranidoctor_user
flutter devices
.\scripts\run_dev_device.ps1
# or specify device id:
.\scripts\run_dev_device.ps1 -Device <device_id>
```

Manual equivalent:

```powershell
flutter run `
  --dart-define=APP_ENV=dev `
  --dart-define=API_BASE_URL=http://192.168.0.42:3000 `
  --dart-define=LOG_NETWORK=true `
  --dart-define=ENABLE_PUSH=false
```

Watch logcat / console for:

```
[AppEnv] env=dev api=http://192.168.0.42:3000 ...
→ GET http://192.168.0.42:3000/api/mobile/app-config
```

---

## 7. Staging / production

| APP_ENV | API_BASE_URL |
|---------|----------------|
| `staging` | `https://staging-api.your-domain.com` |
| `production` | `https://api.your-domain.com` (HTTPS required) |

Release build:

```powershell
.\scripts\build_release.ps1 -ApiBaseUrl "https://api.your-domain.com"
```

---

## 8. Validation checklist

### Build & tests
- [ ] `flutter pub get`
- [ ] `dart analyze` — 0 errors
- [ ] `flutter test` — all pass
- [ ] `flutter build apk --debug` succeeds

### Network
- [ ] Phone browser opens `http://<PC_IP>:3000/api/mobile/app-config`
- [ ] App boot loads config (not stuck on maintenance)
- [ ] `LOG_NETWORK=true` shows API calls in console

### Auth
- [ ] OTP login or password login works
- [ ] Session persists after app restart
- [ ] Logout clears session

### Navigation
- [ ] Bottom nav: Home, Farms, Inbox, Settings
- [ ] Deep routes open (notifications, support, AI, etc.)

### Features (smoke)
- [ ] Dashboard loads
- [ ] Profile `/settings/profile`
- [ ] Offline queue visible when airplane mode + create action
- [ ] Support attachment upload (if storage enabled on backend)
- [ ] AI chat (if AI module enabled on backend)

### Permissions
- [ ] Notifications (Android 13+)
- [ ] Microphone for AI voice input
- [ ] Photos for support attachments

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Connection refused / timeout | Wrong IP, firewall blocking 3000, backend not running, different WiFi/VLAN |
| `localhost` fails on phone | Use PC LAN IP in `API_BASE_URL` |
| Cleartext HTTP blocked | Debug build uses cleartext config; release needs HTTPS |
| Boot stuck / config error | Check backend logs; verify `/api/mobile/app-config` |
| 401 after login | Check `MOBILE_JWT_SECRET` stable across backend restarts |
| OTP not received | Set `REDIS_ENABLED=true` or use password login with seeded demo user |
| Upload fails | Backend `STORAGE_DRIVER=local`; check upload size env vars |
| Firebase errors on boot | Set `ENABLE_PUSH=false` until `google-services.json` is added |
| Emulator can't reach API | Use `10.0.2.2` not `localhost` |

### Demo login (after `db:seed:demo`)

- Phone: `8801701022274`
- Use OTP flow or password per your backend auth setup

---

## Files reference

| File | Purpose |
|------|---------|
| `.env.example` | Template for local/staging/prod defines |
| `scripts/load_env.ps1` | Parses `.env` → `--dart-define` |
| `scripts/run_dev_device.ps1` | Run on connected Android |
| `scripts/detect_lan_ip.ps1` | Suggest PC WiFi IP |
| `lib/app/app_env.dart` | Compile-time env resolution |
| `android/app/src/debug/` | Cleartext HTTP for dev LAN |

---

## Final launch steps

1. Start Postgres + backend (`npm run dev`)
2. Set `.env` with PC WiFi IP
3. Open firewall port 3000
4. Verify URL in phone browser
5. `flutter devices` → `.\scripts\run_dev_device.ps1`
6. Log in → smoke-test Home + Settings + one CRUD module

**USER_APP_FINAL_INTEGRATION_COMPLETE**
