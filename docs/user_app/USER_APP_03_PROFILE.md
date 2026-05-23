# USER_APP_03 — Profile

**Project:** PraniDoctor User App (`pranidoctor_user`)  
**Module:** Profile  
**Status:** COMPLETE  
**Date:** 2026-05-22

---

## Phase 1 — Audit summary

### Implemented before this pass

| Screen | Route | Status |
|--------|-------|--------|
| Profile hub | `/settings/profile` | View + links |
| Edit profile | `/settings/profile/edit` | Name, email, avatar upload |
| Address | `/settings/profile/address` | Area picker + line/postal |
| Language | `/settings/profile/language` | `bn-BD` / `en-US` PATCH |

### Gaps identified

| Priority | Gap | Resolution |
|----------|-----|------------|
| P0 | Incomplete profile → edit only (village required by API) | Profile completion screen + redirect fix |
| P0 | Change password missing | Support/forgot-password page (no backend API) |
| P1 | Validation errors hardcoded English | l10n-aware `ProfileValidation` |
| P1 | No pull-to-refresh on profile hub | `RefreshIndicator` |
| P1 | Android gallery permissions missing | Manifest permissions |
| P1 | 401 on profile reload not handled | Sign-out on auth errors in `MobileMeNotifier` |
| P2 | Remove photo / cover upload / gender / DOB / verification | Backend not supported — documented |

---

## Phase 2 — Implementation plan

1. `ProfileCompletionPage` — checklist (name, location, optional photo) + continue to home
2. `ChangePasswordPage` — support + forgot-password link (blocked API)
3. `profile_navigation.dart` — setup route resolution + post-save navigation
4. Update boot/auth navigation → completion screen when `profileComplete == false`
5. l10n validation messages + profile strings
6. Session expiry handling in `mobileMeProvider`
7. Android media read permissions
8. Tests + manual QA checklist

### Out of scope (backend blocked)

- Change password API
- Gender, DOB, verification status fields
- Remove profile photo API
- Cover photo on profile screen
- Bengali ARB file (`app_bn.arb`)
- Structured address on GET `/me`

---

## API mapping

| Spec | Production path | Method |
|------|-----------------|--------|
| `auth/me`, `users/me` | `GET /api/mobile/me` | GET |
| `users/profile` | `PATCH /api/mobile/me` | PATCH |
| `upload/*` | `POST /api/mobile/uploads/profile-image` | POST multipart |

**PATCH fields:** `name`, `email`, `area`, `locale`, `address{…}`  
**Read-only on GET/PATCH:** `phone`, `profileComplete` (computed), photos (via upload)

---

## State / provider flow

```
mobileMeProvider (AsyncNotifier)
  ├── build() → ProfileRepository.getMe() + cache merge
  ├── save(PatchMobileMeInput) → patchMe + optimistic offline
  ├── uploadAvatar(path) → multipart upload
  ├── reload() → force refresh
  └── hydrate() → boot dedup

ProfileRepository
  ├── Hive: profile_snapshot, profile_address_snapshot
  └── Outbox: profilePatch on transient network failure
```

---

## Verification

```bash
flutter gen-l10n
dart analyze lib/features/profile
flutter test test/profile/profile_integration_test.dart
```
