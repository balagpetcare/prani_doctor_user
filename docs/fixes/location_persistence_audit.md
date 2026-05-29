# Location persistence audit (GLOBAL_LOCATION_PERSISTENCE_AUDIT_AND_FIX_V1)

**Date:** 2026-05-24  
**Scope:** `pranidoctor_user` (Flutter) with API contract from `pranidoctor-backend` / `pranidoctor-web` proxy.

---

## 1. Entry points inventory

### User / profile location

| Label (task) | Actual screen / route | File |
|--------------|----------------------|------|
| CompleteProfile | `ProfileCompletionPage` | `lib/features/profile/presentation/profile_completion_page.dart` → `/settings/profile/complete` |
| EditProfile | `ProfileAppearancePage` (avatar/cover only) | `lib/features/profile/presentation/profile_appearance_page.dart` → `/settings/profile/edit` |
| ProfileSetup | `profileSetupRoute()` → completion or home | `lib/features/profile/presentation/profile_navigation.dart` |
| Onboarding | `OnboardingPage` (slides only, **no location**) | `lib/features/onboarding/presentation/onboarding_page.dart` |
| Profile refresh | `MobileMeNotifier` | `lib/features/profile/presentation/profile_providers.dart` |
| Address editor | `ProfileAddressPage` | `lib/features/profile/presentation/profile_address_page.dart` → `/settings/profile/address` |

### Farm location

| Label | Screen | File |
|-------|--------|------|
| CreateFarm | `FarmFormPage(farmId: null)` | `lib/features/farm/presentation/farm_form_page.dart` |
| EditFarm | `FarmFormPage(farmId: id)` | same |
| FarmDetails | `FarmDetailPage` | `lib/features/farm/presentation/farm_detail_page.dart` |
| Farm draft | `FarmRepository.saveDraft` / `readDraft` | `lib/features/farm/data/farm_repository.dart` |
| Farm cache | `farms_list_snapshot`, `farm_detail:{id}` | `lib/core/offline/local_cache_contract.dart` |
| Farm repository | `FarmRepository` (patches profile) | `lib/features/farm/data/farm_repository.dart` |

### Shared location UI

| Component | File |
|-----------|------|
| `AreaPicker` (division → village) | `lib/features/area/presentation/area_picker.dart` |
| `VillageInputField` | `lib/features/area/presentation/widgets/village_input_field.dart` |
| Location draft | `profileLocationDraftProvider` | `lib/features/profile/presentation/profile_location_draft_provider.dart` |

### Animal

No animal-level location fields in the user app; farm/profile location only.

---

## 2. Flow map

```
UI (ProfileAddressPage / FarmFormPage / AreaPicker)
  → profileLocationDraftProvider.saveDraft (local: profile_location_draft)
  → mobileMeProvider.save / farmRepository.saveFarm
  → ProfileRepository.patchMe
  → PATCH /api/mobile/me (pranidoctor-web proxy → pranidoctor-backend)
  → CustomerProfile.addressJson + primaryVillageId
  → GET /api/mobile/me response
  → profile_snapshot + profile_address_snapshot (Hive/local cache)
  → MobileMeNotifier.build / profileRefresh / background refresh
  → hydrateFromProfile → profile_location_draft (rehydrate)
```

Area hierarchy (picker only):

```
AreaPicker → area_providers → AreaRepository → GET /api/mobile/locations/*
  → AreaCacheStore (TTL keys in area_cache_contract.dart)
```

---

## 3. Data contract by layer

### Wire format (mobile ↔ backend)

| Field | PATCH accept | GET return | Flutter DTO |
|-------|:------------:|:----------:|-------------|
| `divisionId` | ✓ | ✓ | `MobileMeAddressDto.divisionId` |
| `districtId` | ✓ | ✓ | `districtId` |
| `upazilaId` | ✓ | ✓ | `upazilaId` |
| `unionId` | ✓ | ✓ | `unionId` |
| `villageId` | ✓ | ✓ | `villageId` |
| `villageName` | ✓ | ✓ (`villageNameBn` alias on read) | `villageName` |
| `line1` | ✓ | ✓ | `line1` |
| `postalCode` | ✓ | ✓ | `postalCode` |
| `area` (top-level) | ✓ | ✓ | `MobileMeDto.area` / `FarmLocation.displayAddress` |
| `divisionName` … `unionName` | ✗ | ✗ (stored server-side as `*NameBn`, not exposed) | Resolved in UI via area catalog labels |
| `fullAddress` | ✗ | ✗ | Client getter on `FarmLocation.fullAddress` |
| `lat` / `lng` | ✗ | ✗ | Not on profile; catalog rows use `latitude`/`longitude` |
| `updatedAt` | ✗ | ✗ | Not in mobile contract |

**Profile completion (client):** `name` non-empty + `address.unionId` non-empty. Village optional. Server `profileComplete` is parsed but not used for navigation.

**Farm:** No separate farm table; `PATCH /api/mobile/me` with `area` + `address`. Client builds synthetic `Farm` from profile + `dashboard-context` `farmSummary`.

---

## 4. Serialization surfaces

| Model | fromJson | toJson / toPatchJson | copyWith / merge |
|-------|----------|----------------------|------------------|
| `MobileMeAddressDto` | ✓ aliases `villageNameBn` | `toPatchJson` omits empty village | **Added** `mergeForPatch`, `mergeFromCache` |
| `MobileMeDto` | ✓ | `toJson` | `copyWith`, `mergeAddress` (field-level after fix) |
| `ProfileLocationDraft` | ✓ | ✓ | `copyWith`, **Added** `mergePreserving` |
| `FarmLocation` | ✓ | ✓ | `copyWith`, uses `LocationMerge` |
| `Farm` / `FarmInput` | ✓ | draft + patch | `FarmInput.toPatchInput(existingProfile)` |

---

## 5. Root cause analysis

| ID | Symptom | Root cause | Fix |
|----|---------|------------|-----|
| **BUG-B** | Save OK, then location disappears | Background `getMe` returns partial `address`; overwrites cache/draft | Field-level `mergeAddress` + draft `mergePreserving` on hydrate |
| **BUG-G** | Draft lost when opening address | `hydrateFromProfile` always replaces draft on profile load | Merge server into draft; `replace: true` only after explicit save |
| **BUG-C** | Village missing after refresh | GET omits `villageName`; full address replace | `profile_address_snapshot` merged per-field into GET address |
| **BUG-E** | PATCH drops hierarchy fields | Partial `MobileMeAddressDto` in patch | `mergeForPatch` with cached/existing address before PATCH |
| **BUG-J** | Create farm empty location | Init uses `profile.address != null` even when union empty; skips draft | Init: `hasHierarchy` check + merge profile + location draft |
| **BUG-H** | Completion stuck / wrong | Stale profile without union in cache | Stronger cache merge; refresh after save (already present) |
| **BUG-A** | Local-only feel | Offline patch merges into cache (OK); draft overwrite felt like local-only loss | Draft merge + address snapshot |
| **BUG-F** | Race on open | `_initFromProfile` + async hydrate | Init from merged draft+profile; defer server hydrate until save |
| **BUG-I** | N/A | Keys consistent (`profile_snapshot`, `profile_address_snapshot`, `profile_location_draft`) | No change |
| **Farm area** | Farm name overwrites `area` | `toPatchInput` used `areaLabel ?? name` | Prefer `areaLabel`, then existing profile `area`, not farm name |

**Not bugs (by design):**

- No dedicated farm CRUD API.
- `profileComplete` from server unused; client uses `canContinueToHome`.
- Onboarding does not collect location.
- Nav guard only forces completion when exiting `/boot` (documented; out of scope for this fix).

---

## 6. Implementation plan (executed in V1)

1. Add `lib/core/location/location_merge.dart` with `preserveExistingIfNull`.
2. Extend `MobileMeAddressDto` / `MobileMeDto` merge helpers.
3. `ProfileRepository`: field-level address merge on read; merge patch input before send.
4. `ProfileLocationDraftNotifier`: `hydrateFromProfile(replace: bool)` with merge default.
5. `ProfileAddressPage` / `FarmFormPage`: init from merged sources; replace hydrate only after save.
6. `FarmInput.toPatchInput(existingProfile)` + `Farm.fromProfile` village in label.
7. `AreaPicker`: refresh invalidates hierarchy without clearing selection.
8. Tests under `test/integration/location/`.
9. Report: `location_persistence_report.md`.

---

## 7. Manual QA checklist

- [ ] Save profile address with union + custom village → kill app → reopen → location retained
- [ ] Save farm → edit farm → hierarchy + village prefilled
- [ ] Profile completion: name + union → Continue enabled (village optional)
- [ ] Offline: save address → see cached values, no picker reset
- [ ] Area refresh icon: reloads lists, keeps selected division…union
- [ ] Farm create after partial profile: draft location applied
