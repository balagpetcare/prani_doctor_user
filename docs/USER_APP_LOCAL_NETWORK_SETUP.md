# USER_APP_LOCAL_NETWORK_SETUP

## 1. Current config (before)

| Item | Value |
|------|--------|
| API default (debug) | `http://10.0.2.2:3000` (emulator) / wrong port was 3001 |
| Env source | `--dart-define` only via `AppEnv` |
| Timeouts | Hardcoded 30s in Dio |
| Health check UI | None |
| Web port | Not documented in app |

## 2. Updated config

| Item | Value |
|------|--------|
| Backend port | **3000** (`API_PORT`, `pranidoctor-backend`) |
| Web port | **3001** (`WEB_PORT`, reference only) |
| API URL | `API_BASE_URL` → `http://<PC_WIFI_IP>:3000` |
| URL source | Tracked: `API_BASE_URL` / `API_HOST+PORT` / platform default |
| Timeouts | `API_CONNECT_TIMEOUT_SEC`, `API_RECEIVE_TIMEOUT_SEC` |
| Network service | Probes: `/live`, app-config, `/me`, refresh, storage/upload |
| Connection UI | Settings → App settings → **Connection check** |
| Reconnect | Sync coordinator + re-run probes |

## 3. Exact commands

### Detect PC IP
```powershell
cd D:\PraniDoctor\pranidoctor_user
.\scripts\detect_lan_ip.ps1
```

### Configure app
```powershell
copy .env.example .env
# Edit API_BASE_URL=http://<YOUR_IP>:3000
```

### Start backend
```powershell
cd D:\PraniDoctor\pranidoctor-backend
npm run dev
```

### Run on phone
```powershell
cd D:\PraniDoctor\pranidoctor_user
.\scripts\run_dev_device.ps1
```

### Manual flutter run
```powershell
flutter run `
  --dart-define=APP_ENV=dev `
  --dart-define=API_BASE_URL=http://192.168.0.42:3000 `
  --dart-define=LOG_NETWORK=true `
  --dart-define=ENABLE_PUSH=false
```

## 4. Test procedure

### A. Phone browser (pre-flight)
1. Open `http://<PC_IP>:3000/live` → `{"alive":true,...}`
2. Open `http://<PC_IP>:3000/api/mobile/app-config` → JSON with `ok` or `success`

### B. In-app Connection Check
1. Settings → App settings → **Connection check**
2. Tap **Run checks**
3. Expect green: API health, app-config
4. After login: Auth profile + Refresh token
5. Upload/storage: healthy or route reachable

### C. Verify flows
| Flow | How |
|------|-----|
| Phone → API | Connection check `/live` + app-config pass |
| Phone → Auth | Login OTP/password; `/me` probe green |
| Phone → Refresh | `/me` session then Refresh probe green |
| Phone → Upload | Storage probe or support upload in app |

### D. Reconnect
1. Toggle airplane mode off
2. Connection check → **Reconnect & sync**
3. Offline queue drains

## Troubleshooting

See `docs/LOCAL_DEV_INTEGRATION.md`.

**USER_APP_LOCAL_NETWORK_SETUP_COMPLETE**
