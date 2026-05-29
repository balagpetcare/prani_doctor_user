# Location persistence — final verification (V1)

**Date:** 2026-05-24  
**Scope:** Verify fixes from `GLOBAL_LOCATION_PERSISTENCE_AUDIT_AND_FIX_V1` only — no new features.  
**Prior docs:** [location_persistence_audit.md](./location_persistence_audit.md), [location_persistence_report.md](./location_persistence_report.md)

---

## Executive summary

| Layer | Result |
|-------|--------|
| Automated tests (51) | **PASS** |
| Static code-path review | **PASS** |
| Device E2E (cold restart, logout, screenshots) | **MANUAL — required for sign-off** |

**Fix applied during verification:** `Farm.fromProfile` farm display `name` restored to prefer `profile.area` over `profile.name` (regression caught by `test/farm/farm_integration_test.dart`). Re-tested — all green.

```bash
cd pranidoctor_user
flutter test test/integration/location/ test/profile/ test/farm/
# Result: 00:02 +51: All tests passed!
```

---

## 1. Profile location

| Step | Automated | Device manual | Result |
|------|-----------|---------------|--------|
| Set division→district→upazila→union→village | `profile_address_validation_test.dart` (payloads) | Screenshot: address screen filled | **PASS** (unit) / **MANUAL** |
| Save | `ProfileRepository._mergePatchInput` + `mobileMeProvider.save` | Screenshot: success / home | **PASS** (code) / **MANUAL** |
| Force refresh | `profileRefresh(forceRefresh: true)` + `hydrateFromProfile(replace: false)` | Pull profile / reopen address | **PASS** (code) / **MANUAL** |
| Kill app | `profile_location_draft` + `profile_address_snapshot` persist in Hive | Force-stop → reopen | **MANUAL** |
| Relaunch | `ProfileLocationDraftNotifier.build()` reads `profile_location_draft` | Same IDs + village | **PASS** (unit round-trip) / **MANUAL** |
| Logout/login | Session clears tokens; cache keys survive until explicit clear | Re-login → GET `/me` | **MANUAL** |
| Exact values retained | `mergeAddress` + `mergePreserving` | Compare UI to saved IDs | **PASS** (unit) / **MANUAL** |

**Code paths verified**

- Save: `ProfileAddressPage._save` → `PatchMobileMeInput` → `ProfileRepository.patchMe` (merge) → cache write → `hydrateFromProfile(replace: true)` → `profileRefresh`.
- Refresh without wipe: background `_refreshProfileInBackground` uses `hydrateFromProfile(replace: false)`.
- Open editor: `_initFromSources` = `draft.mergeForPatch(profile.address)` — does not call replace hydrate on paint.

---

## 2. Farm location

| Step | Automated | Device manual | Result |
|------|-----------|---------------|--------|
| Create farm | `FarmLocation.mergeWith` + `toPatchInput(existingProfile)` | Create flow | **PASS** (unit) / **MANUAL** |
| Edit farm | `farm_form_page` edit branch loads `farmDetailProvider` | Edit screen prefilled | **PASS** (code) / **MANUAL** |
| Reopen | `farm_draft` + profile cache | Kill app → edit again | **MANUAL** |
| No hierarchy lost | `mergeForPatch` on save | All 4 levels + union visible | **PASS** (unit) / **MANUAL** |
| Village in detail | `Farm.fromProfile` `locationLabel` + `_formatLocationLabel` | Farm detail subtitle | **PASS** (unit) / **MANUAL** |

**Create-mode init (verified in code)**

1. Farm draft (if any)  
2. Else edit: farm detail  
3. Else: `FarmLocation.fromAddress(profile)` **merged with** `profile_location_draft` when `hasHierarchy`

---

## 3. Network cases

| Case | Behavior (code) | Automated | Device | Result |
|------|-----------------|-----------|--------|--------|
| Slow network | `ProfileFetchPolicy` retries; UI keeps prior `AsyncData` on refresh error | — | Throttle network | **MANUAL** |
| Save offline | `patchMe` → outbox `profile_patch` + optimistic cache merge + draft `replace: true` | `offline_restore` test | Airplane mode save | **PASS** (unit) / **MANUAL** |
| Reopen offline | `readCachedProfile` + `mergeAddress` | `mergeAddress` test | Open app offline | **PASS** (unit) / **MANUAL** |
| Reconnect sync | `SyncCoordinator` drains `OutboxKind.profilePatch` → `PATCH /api/mobile/me` | — | Toggle online | **MANUAL** |
| Cache/server consistency | After sync, `getMe` + field merge | — | Compare village after sync | **MANUAL** |

**Offline PATCH body:** merged payload (full hierarchy) is enqueued — not a partial strip.

---

## 4. API contract

### PATCH payload (after client merge)

Example full save (from tests / `toPatchJson`):

```json
{
  "area": "Custom Para",
  "address": {
    "divisionId": "div1",
    "districtId": "dist1",
    "upazilaId": "up1",
    "unionId": "un1",
    "villageName": "Custom Para"
  }
}
```

Partial UI patch **before** wire (client merges with cache):

```dart
// Input: union + new village only
// Output after mergeForPatch(existing): divisionId, districtId, upazilaId, unionId, villageName preserved
```

| Rule | Verified |
|------|----------|
| Village never disappears on GET | `mergeAddress` field-level | **PASS** |
| Empty patch fields do not clear existing | `preserveExistingIfNull` in `mergeForPatch` | **PASS** |
| Empty `villageName` not sent | `toPatchJson` omits empty village | **PASS** |
| `villageName` trimmed | `toPatchJson` | **PASS** |

### GET response handling

```dart
// profile_repository.dart
final profile = await _mergeCachedAddress(MobileMeDto.fromJson(data));
// mobile_me_dto.dart — if both exist:
address: address!.mergeFromCache(cachedAddress)
```

### Cached JSON keys

| Key | Content |
|-----|---------|
| `profile_snapshot` | Full `MobileMeDto.toJson()` |
| `profile_address_snapshot` | `MobileMeAddressDto.toJson()` |
| `profile_location_draft` | `ProfileLocationDraft.toJson()` |
| `farm_draft_new` / `farm_draft:{id}` | `FarmInput.toDraftJson()` |

**Capture on device (screenshots / logs):**

- [ ] DevTools log `[LOCATION_SAVE] union=… village=… villageName=…`
- [ ] `[PROFILE_FETCH] ok union=… village=…` after refresh
- [ ] Hive/debug dump of `profile_address_snapshot` after save

---

## 5. Profile completion

| Rule | Test | Result |
|------|------|--------|
| Name + union → `canContinueToHome` | `profile_integration_test`, `profile_completion_page_test` | **PASS** |
| Village optional | `profile_address_validation_test` union-only | **PASS** |
| Continue disabled without union | `ProfileCompletionPage disables continue when union is missing` | **PASS** |
| Server `profileComplete` ignored | By design (`canContinueToHome` client-side) | **PASS** (documented) |

---

## 6. Regression

| Area | Touched by location fix? | Verification | Result |
|------|--------------------------|--------------|--------|
| Profile image upload | No logic change in `uploadProfileMedia` / avatar paths | `profile_integration_test` avatar aliases | **PASS** |
| Farm cover image | `FarmImageUpload` unchanged | `farm_integration_test` draft with `coverPhotoUrl` | **PASS** |
| Farm draft autosave | Still `saveDraft` 500ms debounce | `FarmInput draft round-trip` tests | **PASS** |
| Home / dashboard refresh | `saveOptimistic` still invalidates `dashboardProvider` | No changes to invalidation list | **PASS** (code review) |
| Fattening / animals | Not in location diff | — | **PASS** (no files touched) |

---

## Files touched (verification + fix)

| File | Verification action |
|------|---------------------|
| `lib/features/farm/data/farm_dto.dart` | **Fixed** `Farm.fromProfile` `name` ← `profile.area` |
| `lib/core/location/location_merge.dart` | Reviewed |
| `lib/features/profile/data/mobile_me_dto.dart` | Reviewed + tests |
| `lib/features/profile/data/profile_repository.dart` | Reviewed |
| `lib/features/profile/presentation/profile_providers.dart` | Reviewed |
| `lib/features/profile/presentation/profile_location_draft_provider.dart` | Reviewed |
| `lib/features/profile/presentation/profile_address_page.dart` | Reviewed |
| `lib/features/farm/presentation/farm_form_page.dart` | Reviewed |
| `lib/features/farm/presentation/farm_detail_page.dart` | Reviewed |
| `lib/features/farm/data/farm_repository.dart` | Reviewed |
| `lib/features/farm/data/farm_location.dart` | Reviewed |
| `lib/features/area/presentation/area_picker.dart` | Reviewed |
| `test/integration/location/location_persistence_test.dart` | Executed |
| `test/profile/*` | Executed |
| `test/farm/*` | Executed |

---

## Screenshots needed (device sign-off)

1. **Profile address** — full hierarchy + custom village selected, before save  
2. **Profile address** — same screen after cold restart  
3. **Profile completion** — Continue enabled (name + union, no village)  
4. **Farm create** — picker prefilled from profile/draft  
5. **Farm edit** — same IDs after reopen  
6. **Offline** — snackbar “saved offline” + picker still filled  
7. **Online** — after reconnect, address screen matches server  

---

## Remaining risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Device-only flows not run in CI | High | Complete manual checklist above |
| Logout may clear local cache (if implemented elsewhere) | Medium | Confirm on logout whether Hive box is wiped |
| Server returns empty `address` object `{}` | Low | `hasHierarchy` false → draft merge on farm create |
| Nav guard only enforces completion after `/boot` | Low | Pre-existing; not part of location fix |
| Outbox sync uses enqueued body; server reject leaves drift | Medium | Manual reconnect test + queue panel |

---

## PASS / FAIL matrix

| # | Requirement | Status |
|---|-------------|--------|
| 1 | Profile location save/merge/refresh | **PASS** (automated + code) |
| 2 | Farm create/edit/reopen hierarchy | **PASS** (automated + code) |
| 3 | Offline + reconnect | **PASS** (unit); **MANUAL** for E2E |
| 4 | API contract village + no empty overwrite | **PASS** |
| 5 | Profile completion rules | **PASS** |
| 6 | Regression (media, draft, home) | **PASS** |
| 7 | Cold restart exact values | **MANUAL PENDING** |
| 8 | Logout/login exact values | **MANUAL PENDING** |

---

## Sign-off criteria (user-defined)

> Success only if: cold restart → reopen → edit again → all retain exact location.

- **Engineering sign-off:** **Conditional PASS** — all automated verification green; merge logic confirmed.  
- **Product sign-off:** **Blocked** until manual checklist + screenshots completed on a physical device or emulator.

---

## Commands to re-run verification

```bash
cd D:\PraniDoctor\pranidoctor_user
flutter test test/integration/location/ test/profile/ test/farm/
flutter analyze lib/core/location lib/features/profile lib/features/farm lib/features/area/presentation/area_picker.dart
```
