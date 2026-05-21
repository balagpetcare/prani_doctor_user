# Phase Auth — Complete

**Repository:** `pranidoctor_user`  
**Completed:** 2026-05-22  
**API surface:** `/api/mobile/auth/*` (legacy compat via `API_BASE_URL`)  
**Approach:** Extended existing `SessionController`, `AuthRepository`, `dioProvider`, `LoginPage`, `AppStartup` — no parallel auth stack.

---

## Summary

End-user mobile authentication is implemented end-to-end:

| Capability | Status | Implementation |
|------------|--------|----------------|
| **Login (password)** | ✅ | `AuthRepository.loginWithPassword` → `POST /api/mobile/auth/login` |
| **Login (OTP)** | ✅ | Two-step: `requestOtp` + `verifyOtp` |
| **Register** | ✅ | `RegisterPage` → `POST /api/mobile/auth/register` |
| **Session restore** | ✅ | `AppStartup` + `SessionController.restoreFromStorage` |
| **Logout** | ✅ | `AuthRepository.signOut` → clears secure storage |
| **Token refresh** | ✅ | `AppStartup` on expired access token; Dio 401 interceptor retry |

---

## Files Changed / Added

### Core

| File | Role |
|------|------|
| `lib/core/network/api_envelope.dart` | Parses `{ ok, data }` / `{ ok, error }` backend envelope |
| `lib/core/network/dio_helpers.dart` | Shared `postJson` / `getJson` |
| `lib/core/network/dio_provider.dart` | Bearer interceptor + 401 refresh retry |
| `lib/core/auth/jwt_utils.dart` | JWT `sub` / expiry decode for session restore |
| `lib/core/session/session_state.dart` | Added `phone` field |
| `lib/core/session/session_controller.dart` | Access + refresh token persistence, device key, `applyAuthTokens` |

### Auth feature

| File | Role |
|------|------|
| `lib/features/auth/data/auth_api_paths.dart` | Mobile auth path constants |
| `lib/features/auth/data/auth_dto.dart` | `OtpRequestResultDto`, `AuthTokensDto`, `AuthUserDto` |
| `lib/features/auth/data/auth_repository.dart` | OTP, login, register, refresh, signOut |
| `lib/features/auth/presentation/login_page.dart` | OTP + password tabs, register link |
| `lib/features/auth/presentation/register_page.dart` | Registration form |

### App / routing

| File | Role |
|------|------|
| `lib/app/app_startup.dart` | Restore session; refresh if access token expired |
| `lib/routing/app_routes.dart` | Added `/register` |
| `lib/routing/app_router.dart` | Register route; auth redirect allows login + register |
| `lib/features/settings/settings_page.dart` | Profile snippet + `auth.signOut()` |
| `lib/l10n/app_en.arb` | Auth strings |

---

## API Endpoints Used

| Method | Path | Used by |
|--------|------|---------|
| POST | `/api/mobile/auth/otp/request` | `AuthRepository.requestOtp` |
| POST | `/api/mobile/auth/otp/verify` | `AuthRepository.verifyOtp` |
| POST | `/api/mobile/auth/login` | `AuthRepository.loginWithPassword` |
| POST | `/api/mobile/auth/register` | `AuthRepository.register` |
| POST | `/api/mobile/auth/refresh` | `AuthRepository.refreshSession`, Dio interceptor |

**Request/response envelope:** `{ "ok": true, "data": { ... } }` on success; `{ "ok": false, "error": { "code", "message" } }` on failure.

---

## Auth Flows

### OTP login

```
LoginPage (OTP tab)
  → POST /api/mobile/auth/otp/request { phone }
  → POST /api/mobile/auth/otp/verify { phone, code, deviceKey, platform }
  → SessionController.applyAuthTokens
  → go_router → /home
```

### Password login

```
LoginPage (Password tab)
  → POST /api/mobile/auth/login { identifier, password, deviceKey, platform }
  → SessionController.applyAuthTokens
  → /home
```

### Register

```
RegisterPage
  → POST /api/mobile/auth/register { name, mobile, password, email? }
  → SessionController.applyAuthTokens (includes user object)
  → /home
```

### Session restore (cold start)

```
AppStartup
  → SessionController.restoreFromStorage()
  → if access token expired && refresh token exists
       → AuthRepository.refreshSession()
     else if expired && no refresh
       → signOut()
  → go_router redirect based on isAuthenticated
```

### Logout

```
SettingsPage
  → AuthRepository.signOut()
  → clears access + refresh + profile keys in secure storage
  → context.go(/login)
```

### Token refresh (401)

```
Any authenticated Dio request → 401
  → dio interceptor → POST /api/mobile/auth/refresh { refreshToken }
  → retry original request with new Bearer token
  → on failure: signOut()
```

---

## Secure Storage Keys

| Key | Content |
|-----|---------|
| `auth.accessToken` | JWT access token |
| `auth.refreshToken` | Refresh token (when issued) |
| `auth.userId` | User id |
| `auth.displayName` | Display name |
| `auth.phone` | Mobile number |
| `auth.deviceKey` | Stable device id for OTP verify |

---

## Configuration

Run with web BFF or backend URL:

```powershell
flutter run --dart-define=API_BASE_URL=https://your-web-or-backend-origin
```

Optional:

```powershell
--dart-define=LOG_NETWORK=true
```

**Debug only:** Dev sign-in button on `LoginPage` (`kDebugMode`) writes placeholder session without API.

---

## Reuse Compliance

| Reuse plan rule | Followed |
|-----------------|----------|
| Extend `AuthRepository` (not new auth service) | ✅ |
| Extend `SessionController` (not second token store) | ✅ |
| Single `dioProvider` with interceptor | ✅ |
| Evolve `LoginPage` layout (tabs, same scaffold) | ✅ |
| `/api/mobile/auth/*` only (no duplicate `/api/auth/*`) | ✅ |
| Keep go_router auth redirect pattern | ✅ |

---

## Not in Scope (deferred)

- Google / Facebook server token exchange (SDK hooks remain; returns clear message)
- `POST /api/mobile/devices/register` after login (FCM token registration — next phase)
- Backend logout endpoint (local sign-out only; no server revoke call)
- Bengali l10n strings for auth UI

---

## Verification Checklist

- [ ] `flutter analyze` — no errors
- [ ] `dart run build_runner build` — `session_state.freezed.dart` regenerated
- [ ] `flutter gen-l10n` — new auth strings generated
- [ ] OTP: request code → verify → lands on Home tab
- [ ] Password: login with mobile/email + password → Home
- [ ] Register: create account → auto signed in → Home
- [ ] Kill app → relaunch → session restored (or refreshed)
- [ ] Settings → Sign out → Login screen
- [ ] Expired access token → refresh on startup or 401 retry

---

## Next Steps

1. Wire `POST /api/mobile/devices/register` in `AppStartup` after auth (FCM)
2. Implement `GET /api/mobile/me` on Home / Settings
3. Persist theme mode via existing `CacheStore`

---

*Phase auth complete.*
