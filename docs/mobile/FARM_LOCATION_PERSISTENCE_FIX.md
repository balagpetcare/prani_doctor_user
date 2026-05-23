# Farm Location Persistence Fix

**Date:** 2026-05-23  
**Scope:** Flutter `pranidoctor_user` + backend `GET /api/mobile/me`

---

## 1. Root Cause

Farm location is **not a separate entity** — it is stored via `PATCH /api/mobile/me` on the customer profile address. Persistence failed due to **five compounding bugs**:

| # | Root cause | Symptom |
|---|------------|---------|
| 1 | `FarmFormPage` never hydrated location from profile/draft on **create** | Picker empty after restart despite saved profile |
| 2 | Form dropped `villageName` — only `villageId` captured | Custom village text lost; validation blocked save |
| 3 | `FarmValidation.validateVillage` required `villageId` only | UI showed selection but save failed with "Select your village…" |
| 4 | `Farm.fromProfile` required `villageId` to build farm | Farm list empty after login when only union + villageName saved |
| 5 | Logout cleared profile cache but not farm caches; GET omitted `primaryVillageId` fallback | Stale/wrong data after session change; village missing on fresh login |

---

## 2. Files Changed

### Flutter
- `lib/features/farm/data/farm_location.dart` *(new)*
- `lib/features/farm/data/farm_dto.dart`
- `lib/features/farm/data/farm_validation.dart`
- `lib/features/farm/presentation/farm_form_page.dart`
- `lib/features/farm/presentation/farm_providers.dart`
- `lib/features/auth/data/auth_repository.dart`
- `test/farm/farm_location_test.dart` *(new)*
- `test/farm/farm_integration_test.dart`

### Backend
- `src/modules/profile/customer-profile.service.ts`

---

## 3. API Payload Before / After

### PATCH `/api/mobile/me` (unchanged shape)

**Before (farm form sent):**
```json
{
  "area": "Farm Name",
  "address": {
    "divisionId": "...",
    "districtId": "...",
    "upazilaId": "...",
    "unionId": "...",
    "villageId": "..."
  }
}
```
Missing: `villageName` for custom villages.

**After (farm form sends):**
```json
{
  "area": "Village Label or Farm Name",
  "address": {
    "divisionId": "...",
    "districtId": "...",
    "upazilaId": "...",
    "unionId": "...",
    "villageId": "...",
    "villageName": "Custom Village"
  }
}
```

### GET `/api/mobile/me` response

**Before:** `address.villageId` missing when only `primaryVillageId` set in DB.

**After:** `serializeAddress` falls back `primaryVillageId` → `address.villageId`.

---

## 4. Migration Impact

- **No database migration** — uses existing `CustomerProfile.addressJson` + `primaryVillageId`.
- **Farm id format:** union-only farms use `farm-union:{unionId}` (was impossible before).
- **Draft key unchanged:** `farm_draft_new` (not `farm_create_draft`).
- **Logout:** clears farm list, farm draft, active farm id, profile location draft.
- **Deploy backend first** for best login-restore on legacy rows with `primaryVillageId` only.

---

## 5. Test Results

```
flutter test test/farm/farm_location_test.dart test/farm/farm_integration_test.dart
→ All farm location tests pass
```

Coverage:
- `create_farm_location_test` → union hierarchy + villageName/custom village
- `location_restore_test` → `Farm.fromProfile` with union + villageName
- `draft_restore_test` → `FarmInput` round-trip with location block
- `custom_village_test` → validation passes without villageId
- `logout_login_restore` → auth cache clear (unit-level); E2E manual

---

## 6. Remaining Risks

| Risk | Mitigation |
|------|------------|
| Empty village master data | Free-text `villageName` supported; union still required |
| Multi-user same device | Logout now clears farm + location drafts |
| Legacy farms with old id `farm-{villageId}` only | New union-only farms use `farm-union:{id}` — edit still works via profile |
| Offline PATCH queued without full address merge | Existing offline queue behavior; profile cache merge on GET |

---

## Manual Test Matrix

| Step | Expected |
|------|----------|
| Select village → create | Saves; farm appears in list |
| Save draft | `farm_draft_new` + `profile_location_draft` updated |
| Kill app → reopen create form | Location restored from draft or profile |
| Logout → login | Location from GET `/me`; no stale farm cache |
| Edit farm | Existing location pre-filled |
| Custom village text | Saves with `villageName`; no validation error |
| Offline save | Queued PATCH; optimistic farm with `fromCache` |
