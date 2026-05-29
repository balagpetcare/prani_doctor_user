# Location persistence fix report (V1)

**Date:** 2026-05-24  
**Audit:** [location_persistence_audit.md](./location_persistence_audit.md)

---

## Root cause (summary)

Location data was **replaced** instead of **merged** at three boundaries:

1. **GET `/api/mobile/me`** — response sometimes omitted optional `villageName`; full-profile cache overwrote the dedicated address snapshot without field-level merge.
2. **`hydrateFromProfile`** — every profile load replaced `profile_location_draft`, discarding in-progress picker state and draft village text.
3. **PATCH payloads** — partial `address` objects could be sent without merging against cached address, risking cleared hierarchy on the server.

Farm create flow used `profile.address != null` instead of `hasHierarchy`, so an empty address object blocked the location draft fallback.

---

## Affected files

| File | Change |
|------|--------|
| `lib/core/location/location_merge.dart` | **New** — `preserveExistingIfNull` |
| `lib/features/profile/data/mobile_me_dto.dart` | `mergeForPatch`, `mergeFromCache`, field-level `mergeAddress` |
| `lib/features/profile/data/profile_repository.dart` | Merge patch input; address cache on save |
| `lib/features/profile/presentation/profile_providers.dart` | Draft hydrate: merge vs replace; offline save |
| `lib/features/profile/presentation/profile_location_draft_provider.dart` | `mergePreserving`, `hydrateFromProfile(replace:)` |
| `lib/features/profile/presentation/profile_address_page.dart` | Init from merged draft + profile (no overwrite hydrate) |
| `lib/features/farm/data/farm_dto.dart` | `toPatchInput(existingProfile)`, village in `locationLabel` |
| `lib/features/farm/data/farm_location.dart` | `mergeWith` |
| `lib/features/farm/data/farm_repository.dart` | Pass cached profile into patch |
| `lib/features/farm/presentation/farm_form_page.dart` | Create init: profile + draft merge |
| `lib/features/farm/presentation/farm_detail_page.dart` | Village visible in location line |
| `lib/features/area/presentation/area_picker.dart` | Refresh preserves selection |
| `test/integration/location/location_persistence_test.dart` | **New** integration-style unit tests |
| `docs/fixes/location_persistence_audit.md` | **New** audit |

---

## Before / after

| Scenario | Before | After |
|----------|--------|-------|
| Background profile refresh | Draft replaced; village lost | Server merged into draft; village kept if omitted |
| Open address screen | Server hydrate overwrote draft | UI loads merge(draft, profile) |
| PATCH farm/profile | Partial address could drop IDs | `mergeForPatch` with cached address |
| Create farm with empty profile address | Skipped location draft | Merges profile + `profile_location_draft` |
| Farm PATCH `area` | Could set `area` to farm name | Uses `areaLabel` or existing profile `area` |
| Area refresh | Selection could feel reset | IDs and labels preserved across invalidate |

---

## Migration

No database migration. Existing Hive/local cache keys unchanged:

- `profile_snapshot`
- `profile_address_snapshot`
- `profile_location_draft`
- `farm_draft_new` / `farm_draft:{id}`

Users with stale cache benefit automatically on next GET (field merge). No manual cache clear required.

---

## Manual QA checklist

- [ ] **Save profile** — Set division → union + custom village → Save
- [ ] **Kill app** — Force stop
- [ ] **Reopen** — Address and village still shown on profile/address screen
- [ ] **Save farm** — Create with location + village
- [ ] **Edit farm** — Location prefilled including village
- [ ] **Village retained** — After pull-to-refresh / background sync
- [ ] **Continue to home** — Name + union (no village required)
- [ ] **Offline** — Airplane mode save → cached UI, no picker reset
- [ ] **Area refresh** — Tap refresh; selection unchanged

---

## Tests

```bash
cd pranidoctor_user
flutter test test/integration/location/location_persistence_test.dart
flutter test test/profile/profile_integration_test.dart
```

---

## Acceptance criteria

| Criterion | Status |
|-----------|--------|
| Save profile → kill app → reopen → location retained | Fixed (merge + draft) |
| Save farm → edit → location visible | Fixed |
| Village retained | Fixed |
| Continue to home enabled (name + union) | Unchanged (correct) |
| No TODO / placeholders in implementation | Done |
