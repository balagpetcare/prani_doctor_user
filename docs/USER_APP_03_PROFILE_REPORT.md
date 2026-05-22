# USER_APP_03 — Profile Report

**Project:** PraniDoctor User App (`pranidoctor_user`)  
**Phase:** Profile (view, edit, address, language)  
**Status:** COMPLETE  
**Date:** 2026-05-22

---

## 1. Pre-implementation analysis

### Existing (PARTIAL)

| Area | Before |
|------|--------|
| Profile view | Embedded in Home/Settings only |
| Edit profile | Single page mixing name + area picker |
| Address | No dedicated screen; picker not rehydrated (GET omits `address`) |
| Language | No UI; `locale` never PATCHed |
| Avatar | DTO fields only; no upload |
| Repository | Concrete class; no contract; duplicate GET possible |
| Validation | Name required only; no email format check |
| Offline PATCH | Outbox worked but no optimistic UI update |
| State sync | Edit page bypassed `mobileMeProvider` |

---

## 2. API mapping

Task spec uses shorthand. **Production paths:**

| Task API | Production path | Method | Repository |
|----------|-----------------|--------|------------|
| `me` | `/api/mobile/me` | GET | `getMe()` |
| `update-profile` | `/api/mobile/me` | PATCH | `patchMe()` |
| Avatar upload | `/api/mobile/uploads/profile-image` | POST multipart | `uploadProfilePhoto()` |

### GET `/api/mobile/me` response (`data`)

```json
{
  "id": "…",
  "name": "…",
  "phone": "…",
  "email": "…",
  "area": "…",
  "locale": "bn-BD",
  "role": "customer",
  "profilePhotoUrl": "…",
  "coverPhotoUrl": null,
  "profileComplete": true
}
```

**Note:** GET does **not** return structured `address` — app merges cached address IDs from local Hive after PATCH.

### PATCH `/api/mobile/me` body

```json
{
  "name": "…",
  "email": "…",
  "area": "…",
  "locale": "bn-BD",
  "address": {
    "divisionId": "…",
    "districtId": "…",
    "upazilaId": "…",
    "unionId": "…",
    "villageId": "…",
    "line1": "…",
    "postalCode": "…"
  }
}
```

### POST `/api/mobile/uploads/profile-image`

- `multipart/form-data`, field `file`
- Returns `data.profilePhotoUrl`

---

## 3. Implementation summary

### New files

```
lib/features/profile/data/profile_repository_contract.dart
lib/features/profile/data/profile_validation.dart
lib/features/profile/presentation/profile_page.dart
lib/features/profile/presentation/profile_address_page.dart
lib/features/profile/presentation/profile_language_page.dart
lib/features/profile/presentation/profile_locale_controller.dart
lib/features/profile/presentation/widgets/profile_feedback.dart
test/profile/profile_integration_test.dart
```

### Modified files

| File | Change |
|------|--------|
| `profile_repository.dart` | Contract, deduped GET/PATCH, address cache, upload, optimistic offline |
| `profile_providers.dart` | `uploadAvatar`, deduped reload, locale sync |
| `profile_edit_page.dart` | Avatar picker, validation, uses `mobileMeProvider.save` |
| `mobile_me_dto.dart` | `copyWith`, `mergeAddress`, `toJson` |
| `profile_api_paths.dart` | Upload paths |
| `local_cache_contract.dart` | `profile_address_snapshot` key |
| `app_routes.dart` | Profile hub + edit/address/language |
| `app_router.dart` | Nested profile routes |
| `app.dart` | `locale` from profile |
| `auth_navigation.dart` | Incomplete profile → edit |
| `settings_page.dart` | Link to profile hub |
| `pubspec.yaml` | `image_picker` |
| `app_en.arb` | Profile strings |

### Screen map

| Screen | Route |
|--------|-------|
| Profile | `/settings/profile` |
| Edit Profile | `/settings/profile/edit` |
| Address | `/settings/profile/address` |
| Language | `/settings/profile/language` |

### Requirements checklist

| # | Requirement | Status |
|---|-------------|--------|
| 1 | Keep architecture | Feature folders + Riverpod unchanged |
| 2 | Flutter + Riverpod | Followed |
| 3 | Reuse components | `AreaPicker`, auth feedback patterns |
| 4 | Real API | GET/PATCH me + upload endpoint |
| 5 | Loading / error / empty | All profile screens |
| 6 | Offline repository | Contract + cache + outbox + optimistic update |
| 7 | Avatar, validation, language | Implemented |
| 8 | Cache consistency | Profile + address snapshots updated together |
| 9 | Prevent duplicate requests | In-flight guards on GET/PATCH/reload |
| 10 | Navigation + state sync | Hub routes; `mobileMeProvider` single source |

---

## 4. Key design decisions

### Address rehydration workaround

Backend GET omits `address` object. After PATCH, address IDs are stored in `local_cache:profile_address_snapshot` and merged into `MobileMeDto` on every read.

### Language persistence

- PATCH `locale` to backend (`bn-BD` / `en-US`)
- `ProfileLocaleController` drives `MaterialApp.locale`
- Synced on profile load and after language save

### Avatar upload

- `image_picker` → `POST /api/mobile/uploads/profile-image`
- Cache snapshot updated with new `profilePhotoUrl`
- `mobileMeProvider` state updated immediately

### Duplicate request prevention

- `ProfileRepository`: `_getMeInFlight`, `_patchInFlight`
- `MobileMeNotifier`: `_reloadInFlight`

---

## 5. Migration notes

```bash
flutter pub get
flutter gen-l10n
dart analyze lib
flutter test test/profile/profile_integration_test.dart
```

### Route changes

- `/settings/profile` is now the **profile hub** (was edit-only)
- Edit moved to `/settings/profile/edit`
- Update deep links / docs referencing old behavior

### New dependency

- `image_picker` — requires platform permissions for gallery access (Android/iOS manifest updates may be needed for production)

---

## 6. Unresolved blockers

| Blocker | Impact | Workaround |
|---------|--------|------------|
| GET `/api/mobile/me` lacks `address` object | Address picker cannot rehydrate from server alone | Client-side address cache after PATCH |
| No `app_bn.arb` | Language UI saves `bn-BD` but UI strings stay English | Add Bengali ARB in future l10n pass |
| S3/storage may be disabled in dev | Avatar upload returns 503 | Error banner; retry when storage configured |
| Cover photo upload | Backend has endpoint; UI not built | `uploadCoverImage` path reserved |
| Area picker locale hardcoded `bn` | Area labels not tied to profile locale | Pass profile locale to `AreaRepository` in follow-up |

---

## 7. Verification

```bash
cd pranidoctor_user
dart analyze lib
flutter test test/profile/profile_integration_test.dart
flutter test test/auth/auth_integration_test.dart
```

Manual test plan:

1. Open Profile hub from Settings — loading → data or error retry.
2. Edit name/email — validation errors for invalid email.
3. Upload avatar — photo appears on hub and edit screen.
4. Save address with village — area label shown; re-open address picker (cached IDs).
5. Change language — app locale updates; persists after restart.
6. Offline PATCH — optimistic update + outbox snackbar.
7. Incomplete profile after register — lands on edit screen.

---

## 8. Navigation flow

```mermaid
flowchart TD
  Settings --> ProfileHub[/settings/profile]
  ProfileHub --> Edit[/settings/profile/edit]
  ProfileHub --> Address[/settings/profile/address]
  ProfileHub --> Language[/settings/profile/language]
  Auth -->|profileComplete false| Edit
  Auth -->|profileComplete true| Home
```

Single provider: `mobileMeProvider` — no duplicate profile state.
