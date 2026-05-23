# Profile & Settings 405 / Load Failure Fix

## Symptoms

- Profile screen: **"Could not load profile"**
- Account Settings: raw **`DioException`** with **HTTP 405**
- `GET /api/mobile/me` failed after login
- `POST /api/sync` could also return 401 (separate JWT `aud` fix)

## Root cause

`src/modules/profile/customer-address.service.ts` mixed nullish coalescing (`??`) and logical OR (`||`) **without parentheses**:

```ts
// BROKEN — SyntaxError at module load
const x = a ?? b.join(', ') || undefined;
```

That prevented:

1. `customer-address.service.ts` from loading
2. `mobile-me.adapter.ts` from importing
3. `/api/mobile/me` compat route from registering a working `GET` handler

**Server behavior:**

- First request after failed import → **500** (module load throw)
- Subsequent requests → **405** (handler missing in route registry)

Flutter paths were already correct:

- `GET /api/mobile/me`
- `PATCH /api/mobile/me`
- `GET /api/mobile/settings`

## Solution

### Backend

1. Fixed `hierarchyAreaLabel` to avoid mixed `??` / `||`.
2. Added `no-mixed-operators` ESLint rule + `npm run ci:validate`.
3. Added `validateMobileProfileModules()` at startup (server exits if import fails).
4. Added `GET /health/mobile` with `{ mobileMe, profile, settings, auth }`.

### Flutter

1. Friendly error mapping (`HttpErrorMapper`) — no raw Dio in UI.
2. Cache → API → recovery in `MobileMeNotifier`.
3. JWT validation before profile fetch; invalid session cleared.
4. Optional 405 method fallback in `flexible_http.dart`.

## Tests

| Layer | Command |
|-------|---------|
| Backend lint + modules | `npm run ci:validate` |
| Backend unit/contract | `npm test` (mobile-me.contract, mobile-profile-startup, mobile-health) |
| Flutter | `flutter test test/core/http_error_mapper_test.dart` |

## Manual verification

```bash
# Backend
curl http://localhost:3000/health/mobile
curl -H "Authorization: Bearer <token>" http://localhost:3000/api/mobile/me

# Flutter
flutter run -d <device>
# Login → Profile → Settings → Account
```

## Future prevention

1. **Never merge** `??` and `||` in one expression without explicit parentheses.
2. Run **`npm run ci:validate`** in CI before deploy.
3. Watch **`GET /health/mobile`** — any `false` field blocks release.
4. On profile regressions, check backend logs for **"Mobile profile module import failed"** at startup.

## Related files

- `src/modules/profile/customer-address.service.ts`
- `src/shared/config/mobile-profile-startup.ts`
- `src/api/health/mobile-health.service.ts`
- `lib/core/error/http_error_mapper.dart`
- `lib/features/profile/presentation/profile_providers.dart`
