# User App: Animal Media + Home List Fix

**Date:** 2026-05-23  
**Scope:** `pranidoctor_user` (Flutter), `pranidoctor-backend` (upload purpose)

## Phase 1 — Root cause analysis

### A. Animal image overwrites user profile image

| Layer | Finding |
|-------|---------|
| **Flutter pick/upload** | `AnimalImageUpload` and `AnimalRepository.uploadPhoto()` call `UploadService.uploadProfileImage()` → `POST /api/mobile/uploads/profile-image` |
| **Backend side effect** | Profile-image route runs `ingestProfileMedia(kind: 'avatar')`, which writes `customerProfile.profilePhotoUrl` / `profilePhotoThumbUrl` |
| **Animal save** | Create/update only sets `AnimalProfile.photoUrl` — profile is already overwritten at upload time |
| **State/cache** | Not caused by `refreshProfile`, `copyWith`, or cache key collision (`profileKey` vs `animalsListKey` are separate) |

**Root cause:** Wrong upload endpoint — animal photos reuse the **customer avatar** pipeline.

### B. Home / farm animal list unreliable

| Layer | Finding |
|-------|---------|
| **Auth gate** | `AnimalListNotifier.build()` did not watch `protectedApisEnabledProvider` (unlike profile/notifications). Early build could 401 and stick in error/empty until manual reopen |
| **Post-save refresh** | `AnimalNavigation.afterSave()` called `refresh(silent: true)`, which is blocked unless manual refresh is active (`AutoRefreshGuard`) |
| **Optimistic UI** | No local upsert after create/edit — home waited on a silent refresh that often never ran |

**Root cause:** Missing auth gate + silent refresh gating + no optimistic list update after save.

---

## Phase 2 — Media domain separation

### Backend

- Add `ANIMAL_PHOTO` to `MobileUploadPurpose` enum (Prisma migration).
- Generic upload `POST /api/mobile/upload` with `purpose=ANIMAL_PHOTO` stores file only — **does not** touch `CustomerProfile`.
- Public download allowed for `ANIMAL_PHOTO` (same as profile/cover — `Image.network` has no Bearer).

### Flutter

| Domain | Field | Upload |
|--------|-------|--------|
| User | `profilePhotoUrl` / `avatarUrl` | `POST /api/mobile/me/avatar` or legacy profile-image |
| Animal | `photoUrl` / `primaryImageUrl` | `POST /api/mobile/upload` + `purpose=ANIMAL_PHOTO` |

New types:

- `UploadPurpose.animalPhoto`
- `MediaOwnerType` / `MediaPurpose` in `media_owner.dart` (client contract)
- `UploadService.uploadAnimalPhoto()`

**Disallowed:** animal upload → profile-image / me/avatar endpoints.

---

## Phase 3 — State management

- `AnimalListNotifier` watches `protectedApisEnabledProvider`.
- Uses `AsyncRefreshGuard` (same pattern as notifications).
- `afterSave()` → `upsertLocal(animal)` + `reload(forceRefresh: true)` — **never** `mobileMeProvider` refresh.
- Scoped invalidation: `animalListProvider`, `animalsProvider`, `farmListProvider`, `dashboardProvider` only.

---

## Phase 4 — Home animal list

- First open: load when `sessionReady && isAuthenticated`.
- Pull-to-refresh: `HomeNavigation.refreshDashboard()` → `animalListProvider.reload/refresh`.
- Return from add/edit: optimistic upsert + forced reload.
- Delete/deactivate: existing `reload(forceRefresh: true)` retained.

---

## Phase 5 — Cache keys

Widget/image identity keys (Flutter `Image.network` caches by URL):

- Profile: `profile_image_{userId}`
- Animal: `animal_image_{animalId}`

Disk list cache unchanged: `animals_list_snapshot`, `profile_snapshot`.

---

## Phase 6 — UI

- Animal cards: `animal.primaryImageUrl` → placeholder — never profile avatar.
- Profile header: `profile.profileImageUrl` / `user.avatarUrl` only.

---

## Phase 7 — Tests

See `test/animals/animal_media_and_home_fix_test.dart`:

1. Animal upload purpose ≠ profile
2. Upload URL resolver prefers generic `url` for animals
3. `upsertLocal` prepends/updates list
4. `UploadResult` generic response does not expose profile fields as animal URL

---

## Migration needed?

**Yes (backend):** Prisma migration adding `ANIMAL_PHOTO` to `MobileUploadPurpose`.

Run:

```bash
cd pranidoctor-backend
npx prisma migrate deploy
npx prisma generate
```

---

## API impact

| Change | Breaking? |
|--------|-----------|
| New enum value `ANIMAL_PHOTO` | No — additive |
| Flutter stops calling profile-image for animals | No — clients should migrate |
| Animal list behavior | No contract change |

---

## Remaining risks

1. **Existing users** who already have wrong profile avatars need manual re-upload of profile photo (data not auto-reverted).
2. **Old app versions** still using profile-image for animals will keep overwriting profile until upgraded.
3. **Storage env** must allow image MIME for `ANIMAL_PHOTO` (uses default image limits).

---

## Files changed

### Flutter (`pranidoctor_user`)

- `lib/features/shared/upload/models/upload_purpose.dart`
- `lib/features/shared/upload/models/media_owner.dart` (new)
- `lib/features/shared/upload/services/upload_service.dart`
- `lib/features/shared/upload/widgets/image_picker_tile.dart`
- `lib/features/animals/presentation/widgets/animal_image_upload.dart`
- `lib/features/animals/data/animal_repository.dart`
- `lib/features/animals/data/animal_api_paths.dart`
- `lib/features/animals/data/animal_dto.dart`
- `lib/features/animals/presentation/animal_providers.dart`
- `lib/features/animals/presentation/animal_navigation.dart`
- `lib/features/animals/presentation/animal_form_page.dart`
- `lib/features/profile/data/profile_media_models.dart`
- `lib/core/offline/local_cache_contract.dart`
- `lib/features/home/presentation/widgets/animal_carousel.dart`
- `test/animals/animal_media_and_home_fix_test.dart`

### Backend (`pranidoctor-backend`)

- `prisma/schema.prisma`
- `prisma/migrations/20260523120000_animal_photo_upload_purpose/migration.sql`
- `src/legacy/web/lib/storage/upload-service.ts`
- `src/legacy/web/routes/mobile/uploads/[id]/route.ts`
