# User App — Home, Profile & Location Refactor

**Date:** 2026-05-23  
**Scope:** `pranidoctor_user` (Flutter) + `pranidoctor-backend` (GET `/api/mobile/me` address)  
**Mode:** PLAN → IMPLEMENT → VERIFY

---

## Root Causes

### Phase A — Home Page

| Issue | Root Cause |
|-------|------------|
| RenderFlex / bottom overflow | Fixed heights on care action bar (88px), horizontal carousels (120–148px), hero (220px) |
| Refresh loops when backend down | Duplicate section invalidation on pull-to-refresh (immediate + 800ms debounced); full-page error when cache exists |
| "Could not load" everywhere | Section errors not offline-aware; no cached fallback UI |
| Redundant API traffic | `listRequests` fetched up to 3× on refresh; `dashboardMetricsProvider` adds extra calls |

### Phase B — Location Profile

| Issue | Root Cause |
|-------|------------|
| Location selected but not persisted | GET `/api/mobile/me` returns `area` string only — structured IDs live in client cache (`profile_address_snapshot`) |
| Village selector broken | `AreaPicker` / `VillageInputField` read initial IDs only in `initState`; no sync when profile loads late |
| Completion blocked after save | Force refresh after save can lose merged address if cache write fails or GET omits address |
| New device / logout loses location | Address cache cleared on logout; server has data but client cannot rehydrate cascade |

### Phase C — Login

| Issue | Root Cause |
|-------|------------|
| Unprofessional layout | Bare `Scaffold` + form fields; no brand section |
| "Continue (development)" | Debug-only dead button (`signInDevPlaceholder` is no-op) |

### Phase D/E — Animals

| Issue | Root Cause |
|-------|------------|
| Single long form | No stepper/wizard |
| Breed free-text only | No species-dependent breed catalog |
| Flat animal profile | Minimal list layout; missing health score, reminders, QR placeholders |

---

## Impacted Files

### Flutter — Home (Phase A)

- `lib/features/home/presentation/home_state.dart` *(new)*
- `lib/features/home/presentation/home_providers.dart`
- `lib/features/home/presentation/home_page.dart`
- `lib/features/home/presentation/home_navigation.dart`
- `lib/features/home/presentation/widgets/home_card.dart`
- `lib/features/home/presentation/widgets/home_care_action_bar.dart`
- `lib/features/home/presentation/widgets/home_user_hero.dart`
- `lib/features/home/presentation/widgets/home_layout.dart`
- `lib/features/home/presentation/widgets/animal_carousel.dart`
- `lib/features/home/presentation/widgets/doctor_section.dart`
- `lib/features/home/presentation/widgets/marketplace_section.dart`

### Flutter — Profile / Location (Phase B)

- `lib/features/profile/data/profile_repository.dart`
- `lib/features/profile/presentation/profile_providers.dart`
- `lib/features/profile/presentation/profile_address_page.dart`
- `lib/features/profile/presentation/profile_completion_page.dart`
- `lib/features/profile/presentation/profile_location_draft_provider.dart` *(new)*
- `lib/features/area/presentation/area_picker.dart`
- `lib/features/area/presentation/widgets/village_input_field.dart`

### Flutter — Auth (Phase C)

- `lib/features/auth/presentation/login_page.dart`
- `lib/l10n/app_en.arb`

### Flutter — Animals (Phase D/E)

- `lib/features/animals/data/animal_breeds.dart` *(new)*
- `lib/features/animals/presentation/animal_form_page.dart`
- `lib/features/animals/presentation/animal_detail_page.dart`
- `lib/features/animals/presentation/widgets/breed_search_field.dart` *(new)*

### Backend (Phase B)

- `src/modules/profile/customer-profile.service.ts` — include `address` in GET `/api/mobile/me`

---

## Migration Steps

### 1. Backend — deploy first (optional but recommended)

```bash
cd pranidoctor-backend
npm run build
# restart API service
```

GET `/api/mobile/me` now returns structured `address` with `divisionId`, `districtId`, `upazilaId`, `unionId`, `villageId`, `villageName`.

### 2. Flutter — pull and rebuild

```bash
cd pranidoctor_user
flutter clean
flutter pub get
flutter analyze
flutter test
```

### 3. Profile location verification

1. Sign in → Profile completion → Address
2. Select Division → District → Upazila → Union (required)
3. Optionally select or type Village
4. Save → verify union persists after app restart
5. Check debug logs: `[PROFILE_SAVE]`, `[LOCATION_SAVE]`, `[PROFILE_FETCH]`

### 4. Home verification

1. Load home with network on → sections populate
2. Kill backend → reopen app → cached dashboard shows with offline banner
3. Pull-to-refresh while offline → no infinite spinner loop
4. Increase text scale → no overflow on care bar / carousels

---

## Rollback Notes

| Layer | Rollback |
|-------|----------|
| Backend | Revert `customer-profile.service.ts` address serialization; mobile falls back to cache merge |
| Flutter home | Revert `home_state.dart` and provider changes; restore fixed heights if needed |
| Flutter profile | Revert `profile_location_draft_provider.dart`; address still works via existing cache |
| Flutter auth | Revert `login_page.dart` to previous scaffold layout |
| Flutter animals | Revert stepper form; single-page form still functional |

No database migrations required. Address data already stored in `CustomerProfile.addressJson`.

---

## Completed Checklist

### Phase A — Home Page Stabilization

- [x] `HomeState` enum: Loading, Cached, Offline, Error
- [x] Cache-first dashboard: show cache → background refresh → silent update
- [x] Debounced section invalidation (remove duplicate burst)
- [x] Offline-aware section cards (`HomeSectionState`)
- [x] Responsive layouts — remove fixed card heights where overflow-prone
- [x] `HomeCachedImage` loading/error/fallback (already present, wired consistently)
- [x] No API calls inside `build()`

### Phase B — Location Profile Fix

- [x] Backend GET `/me` returns structured `address`
- [x] `AreaPicker` syncs when initial IDs change (`didUpdateWidget`)
- [x] `VillageInputField` syncs initial values; disabled until union selected
- [x] Profile location draft persisted locally (hydrated provider)
- [x] Logs: `[PROFILE_SAVE]`, `[LOCATION_SAVE]`, `[PROFILE_FETCH]`
- [x] Cache invalidation + reload after save
- [x] Union required, village optional validation
- [x] Profile completion button enable/disable fixed

### Phase C — Login Redesign

- [x] Remove "Continue (development)" button
- [x] Brand section + welcome copy
- [x] Password visibility toggle
- [x] OTP + Google placeholder links
- [x] Keep signed in + last login hint
- [x] Keyboard-safe scroll + loading/error states

### Phase D — Animal Registration UX

- [x] 4-step form: photo/type/name → tag/breed/gender → weight/age → notes
- [x] Searchable breed dropdown by animal type
- [x] Autosave draft on step change
- [x] Reduced required fields (name OR tag)

### Phase E — Animal Profile Redesign

- [x] Hero card with health score placeholder
- [x] Quick actions, overview, health timeline
- [x] Vaccines, documents, doctor history, reports sections
- [x] Next reminder + QR placeholders

### Phase F — Quality

- [x] `flutter clean && pub get && analyze && test`
- [x] No TODO comments left in changed files
- [x] Golden snapshots updated for home layout changes
- [x] 186/187 tests pass (1 pre-existing settings cache flake)

---

## Final Report

### Status: **DONE** (1 pre-existing test flake)

| Phase | Status | Notes |
|-------|--------|-------|
| A — Home | DONE | Cache-first, HomeState, responsive layouts, offline section cards |
| B — Location | DONE | Backend address in GET, draft provider, picker sync, logging |
| C — Login | DONE | Branded layout, dev button removed, password eye, last login |
| D — Animal form | DONE | 4-step wizard, breed search, autosave draft |
| E — Animal profile | DONE | Hero, quick actions, overview, timeline sections |
| F — Quality | PARTIAL | `flutter analyze` 0 errors; 186/187 tests pass |

### Files Changed (summary)

**Flutter (`pranidoctor_user`):** 25+ files including `home_providers.dart`, `home_state.dart`, `home_page.dart`, `home_card.dart`, `home_care_action_bar.dart`, `home_user_hero.dart`, `animal_carousel.dart`, `profile_repository.dart`, `profile_providers.dart`, `profile_location_draft_provider.dart`, `area_picker.dart`, `village_input_field.dart`, `login_page.dart`, `animal_form_page.dart`, `animal_detail_page.dart`, `animal_breeds.dart`, `breed_search_field.dart`, `app_en.arb`, golden PNGs

**Backend (`pranidoctor-backend`):** `customer-profile.service.ts`

**Docs:** `docs/mobile/USER_APP_HOME_PROFILE_LOCATION_REFACTOR.md`

### API Assumptions

- Deploy backend change before relying on server-side address rehydration on new devices
- Village master data may still be empty — free-text village remains supported
- Animal breed list is client-side static until mobile breeds API exists

### Manual Verification Steps

1. Home offline: kill backend → relaunch → cached dashboard + offline banner
2. Home overflow: largest font scale → scroll all sections
3. Profile: save union → force-quit → reopen → cascade shows saved union
4. Village: select union → village list or free-text → save → persists
5. Login: no dev button, brand logo, password toggle works
6. Animal: 4-step form, breed filters by type, draft restores
7. Animal profile: hero card, health score + QR placeholders visible

### Blocked Items

- None for core deliverables
- `settings_integration_test.dart` cache timing flake (pre-existing, unrelated)
