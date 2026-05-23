# Auth / Session Hardening — Test Report

**Date:** 2026-05-22  
**Scope:** `pranidoctor_user` OTP login, session restore, protected API gating, offline sync

## Summary

| Area | Status | Notes |
|------|--------|-------|
| Debug auth logs removed | PASS | `OTP_VERIFY_RESPONSE`, `AUTH_HEADER`, `TOKEN_*` removed from release paths |
| Login success (token persist) | PASS | `session_controller_test.dart` |
| Session restore (restart) | PASS | In-memory store simulates cold start |
| Logout | PASS | Clears storage + `sessionReady` guest state |
| Expired token restore | PASS | Clears invalid session |
| Invalid token (`dev-token`) | PASS | No pseudo-auth |
| Provider gate `sessionReady && isAuthenticated` | PASS | Central `SessionAuth.canCallProtectedApis` |
| Protected APIs documented | PASS | me, settings, vaccines, notifications, dashboard |
| Offline queue unauthenticated | PASS | `SyncCoordinator` + `OfflineCoordinator` gated |

## Automated tests

Run:

```powershell
cd D:\PraniDoctor\pranidoctor_user
flutter test test/auth/
```

| File | Tests |
|------|-------|
| `session_controller_test.dart` | login, restore, logout, expired, invalid, memory cache |
| `session_auth_test.dart` | gate matrix, JWT validation, protected paths |
| `auth_integration_test.dart` | DTO, validators, gate helpers |

## Manual verification (device)

1. **OTP login** — request + verify → Home; logcat has no `401` on `/api/mobile/me` immediately after login.
2. **App restart** — kill app → reopen → still authenticated; `/me` succeeds.
3. **Logout** — Settings → sign out → login screen; no background sync logs.
4. **Fresh install / clear data** — OTP only path; no `dev-token` Home bypass.
5. **Protected sections** — Home dashboard, vaccine reminders, notifications, settings load without 401 when authed.

## Provider gate coverage

Uses `SessionAuth.canCallProtectedApis`:

- `dashboardProvider` + section providers (metrics, appointments, activity, health alerts)
- `vaccineProvider`, `vaccineReminderProvider`, `vaccineSummaryProvider`, `vaccineCalendarProvider`
- `mobileMeProvider` (`/api/mobile/me`)
- `settingsProvider` (`/api/mobile/settings`)
- `NotificationListNotifier`, `NotificationRealtimeNotifier`
- `SyncCoordinator.syncNow`
- `OfflineCoordinator`, `NotificationCoordinator`, `PushRegistrationService`
- `BootController._restoreSession`
- `navigateAfterAuth`

## Remaining risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Router redirect uses `isAuthenticated` only (not `sessionReady`) | Low | Boot keeps user on splash until restore; brief window unlikely to mount Home |
| `sync_coordinator` background timer still ticks when guest | Low | `syncNow` returns immediately when gate false |
| No live HTTP integration tests in CI | Medium | Manual device checklist above |
| Refresh token rotation failure → signOut | Low | Existing Dio 401 + `refreshAccessToken` behavior |
| Secure storage platform quirks on some OEMs | Low | Memory cache + JWT validation on restore |

## Changed files (this pass)

See git diff; primary:

- `lib/core/session/session_auth.dart` (new)
- `lib/core/session/session_controller.dart`
- `lib/core/network/dio_provider.dart`
- `lib/features/auth/data/auth_repository.dart`
- Provider gates: home, vaccine, profile, settings, notifications, offline, boot, auth_navigation
- `test/auth/session_controller_test.dart`
- `test/auth/session_auth_test.dart`
- `test/auth/auth_integration_test.dart`
- `test/helpers/test_jwt.dart`
