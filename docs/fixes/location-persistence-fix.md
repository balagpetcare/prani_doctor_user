# Farm location persistence fix

**Date:** 2026-05-31  
**Scope:** `pranidoctor_user` (Flutter) + `pranidoctor-backend` (`GET/PATCH /api/mobile/me`)

---

## 1. Root cause

After logout and login, the app showed Farm Location / profile setup again even when the user had previously saved their location. Five compounding issues:

| # | Root cause | Symptom |
|---|------------|---------|
| 1 | **Cache-first profile load** — `MobileMeNotifier` returned Hive cache before calling the API | Stale or empty profile used for routing after session change |
| 2 | **Unsafe cache merge for completion** — `MobileMeDto.mergeAddress()` injected cached `unionId` when the server response had no `address` | Local “complete” state that did not match the server; after logout (cache cleared) user correctly appeared incomplete — but during the same session decisions were wrong |
| 3 | **Post-auth fetch not forced** — `navigateAfterAuth` and boot restore called `getMe()` without `forceRefresh: true` | Could reuse in-flight/stale reads during login |
| 4 | **Router ignored profile updates** — `RouterNotifier` did not listen to `mobileMeProvider` | Boot exit could route to home before profile loaded, or miss re-route when API returned incomplete profile |
| 5 | **Backend `profileComplete` mismatch** — server used `areaLabel` / `primaryVillageId`, client required `unionId` | `profileComplete` flag from API did not align with mobile onboarding rules |

**Primary fix:** treat the **server profile as source of truth** for completion (`full_name` + `union_id`); use cache only for optional display fields (village name) and only when server and cache agree on completion status.

---

## 2. Files changed

### Flutter (`pranidoctor_user`)

| File | Change |
|------|--------|
| `lib/features/profile/services/profile_completion_service.dart` | **New** — central completion rules, server/cache reconciliation, debug logs |
| `lib/features/profile/data/mobile_me_dto.dart` | Added `profileCompleted`, `hasOptionalVillage` getters |
| `lib/features/profile/data/profile_repository.dart` | API-first fetch; `reconcileWithServer`; completion logs on fetch/save |
| `lib/features/profile/presentation/profile_providers.dart` | Removed cache-first short-circuit; added `profileCompletionProvider` |
| `lib/features/auth/presentation/auth_navigation.dart` | `getMe(forceRefresh: true)` + `ProfileCompletionService` onboarding decision |
| `lib/features/boot/boot_controller.dart` | Force refresh on session restore; completion logs |
| `lib/routing/nav_guard.dart` | Profile-aware boot exit with `ONBOARDING_DECISION` logs |
| `lib/routing/app_router.dart` | Listen to `mobileMeProvider` for redirect refresh |
| `test/profile/profile_completion_service_test.dart` | **New** unit tests |

### Backend (`pranidoctor-backend`)

| File | Change |
|------|--------|
| `src/modules/profile/customer-address.schema.ts` | `isProfileComplete` now requires `unionId` in `addressJson` |
| `src/modules/profile/customer-address.schema.test.ts` | Updated expectations |

---

## 3. API flow

```
Login (OTP / password)
  → POST /api/mobile/auth/otp/verify (tokens)
  → GET /api/mobile/me (forceRefresh — no cache-only routing)
  → CustomerProfileService.serializeMobileMe
       address ← addressJson (divisionId…unionId…villageName)
       profileComplete ← isProfileComplete(name + unionId)
  → ProfileCompletionService.evaluate (client)
  → IF profileCompleted → /home
     ELSE → /settings/profile/complete

Save farm / profile location
  → PATCH /api/mobile/me { area, address: { divisionId…unionId, villageName? } }
  → CustomerAddressService.patchMobileMe
       validate hierarchy → persist addressJson + primaryVillageId
       set profileCompletedAt when complete
  → GET response body returned to client
  → ProfileCompletionService.reconcileWithServer (optional village merge only)

Logout
  → POST /api/mobile/auth/logout (best effort)
  → Clear tokens + profile_snapshot + profile_address_snapshot + farm caches

Cold start (remember session)
  → Boot restore tokens → GET /api/mobile/me (forceRefresh)
  → hydrate mobileMeProvider → nav_guard boot exit
```

### Completion rules (aligned client + server)

| Field | Required for completion |
|-------|-------------------------|
| `name` / `displayName` | Yes |
| `address.unionId` | Yes |
| `address.villageId` / `villageName` | No (optional) |
| Profile photo | No |

---

## 4. Debug logs

Filter logcat / console for:

| Tag | When |
|-----|------|
| `PROFILE_COMPLETION_CHECK` | Every completion evaluation (name, union, source) |
| `LOCATION_SETUP_STATUS` | Fetch, save, merge, boot hydrate |
| `ONBOARDING_DECISION` | Post-auth route, boot exit |

---

## 5. Test cases

### Automated

```bash
cd pranidoctor_user
flutter test test/profile/profile_completion_service_test.dart
flutter test test/integration/location/
flutter test test/profile/
```

| Test | Verifies |
|------|----------|
| `profileCompleted requires name and unionId` | Core gate |
| `village is optional for completion` | Optional village |
| `reconcileWithServer trusts server when cache would inflate completion` | Server wins on mismatch |
| `reconcileWithServer merges optional village from cache` | Display merge only |
| Existing `location_persistence_test.dart` | Address merge / farm patch |

### Manual QA

1. **Happy path:** Set name + union (+ optional village) → Continue → Home → Logout → Login → lands on Home (not setup).
2. **Farm form:** Create farm with full hierarchy → save → logout → login → farm list shows location; no setup prompt.
3. **Kill app:** Complete profile → force-stop → reopen → still on Home with location visible.
4. **Offline save:** Save address offline → see cached values → go online → sync → logout → login → location retained from server.
5. **Incomplete server:** (staging) User with name only → always routed to profile completion after login.

---

## 6. Rollback procedure

1. Revert Flutter commits touching `profile_completion_service.dart`, `profile_providers.dart`, `profile_repository.dart`, `auth_navigation.dart`, `nav_guard.dart`, `app_router.dart`, `boot_controller.dart`.
2. Revert backend `customer-address.schema.ts` to prior `isProfileComplete` (areaLabel / primaryVillageId).
3. Run `flutter test test/profile/ test/integration/location/` and backend `customer-address.schema.test.ts`.
4. Deploy backend first if rolling back server rule; old mobile clients still use client-side `unionId` check.

**Risk of rollback:** Restores cache-first behaviour and server/client completion mismatch.

---

## 7. Verification checklist

- [ ] `PROFILE_COMPLETION_CHECK completed=true` after save with union
- [ ] `ONBOARDING_DECISION post-auth-home` after login when complete
- [ ] Logout clears `profile_snapshot` (existing `AuthRepository._clearAuthCaches`)
- [ ] GET `/api/mobile/me` returns `address.unionId` when saved
- [ ] No regression on offline PATCH / outbox sync
