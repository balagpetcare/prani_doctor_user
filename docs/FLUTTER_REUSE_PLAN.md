# Flutter Reuse Plan — pranidoctor_user

**Generated:** 2026-05-22  
**Inputs:** `docs/FLUTTER_CURRENT_STATE.md`, `pranidoctor-web/docs/INTEGRATION_MATRIX.md`  
**Goal:** Integrate backend APIs by **extending what exists** — no redesign, no duplicate layers.

---

## Principles

| Rule | Action |
|------|--------|
| **Reuse theme** | Keep `AppTheme`, `themeModeProvider`, M3 seed colors; extend via `ThemeData` / `ThemeExtension` only when a screen needs a semantic token |
| **Reuse widgets** | Extract from existing pages (`LoginPage`, `SettingsPage`, `AppShellScaffold`); do not introduce a parallel design system |
| **Reuse services** | Extend `SessionController`, `AuthRepository`, `NotificationService`, `MediaUploadCoordinator`, `CacheStore` — do not add second auth/cache/upload stacks |
| **Reuse DTOs** | Wire existing `lib/core/*/ *_dto.dart` and contracts to Dio; add mobile-only DTOs only where no foundation/legacy shape exists |
| **Reuse screens** | Evolve the 5 existing routes + shell; add nested routes under current tabs before creating new top-level navigation |
| **Avoid redesign** | Same tab order (Home → Services → Inbox → Settings), same drawer, same login layout structure |
| **Avoid duplicate** | One API path per concern; one repository per domain; no parallel `/api/mobile/locations` **and** `/api/area` clients |

---

## API Surface Decision (Avoid Duplication)

Before implementation, lock these choices so repositories are not built twice:

| Concern | **Use (reuse)** | **Do not duplicate** | Rationale |
|---------|-----------------|----------------------|-----------|
| End-user auth | Extend `AuthRepository` → **`/api/mobile/auth/*`** | New `FoundationAuthRepository` for `/api/auth/*` | Web BFF already proxies mobile auth; backend parity proven |
| Profile | `UserProfileDto` + **`GET/PATCH /api/mobile/me`** | Separate `/api/users/me` client | Mobile path matches inbox/services persona |
| Locations | Existing **`AreaRepositoryContract`** → **`/api/area/*`** | Legacy `/api/mobile/locations/*` repository | Flutter contracts already aligned to foundation backend |
| Service bookings | New **`MobileServiceRequestRepository`** → `/api/mobile/service-requests/*` | `TreatmentRepositoryContract` for customer UI | Treatment contract is **doctor-only** (`/api/cases/*`) |
| AI chat | Existing **`AiRepositoryContract`** → `/api/ai/*` | Second chat client or duplicate DTOs | DTOs + paths already match backend |
| Uploads | Extend **`MediaUploadCoordinator`** → `/api/mobile/uploads/*` | Foundation `/api/media/*` (503 stub) | Integration matrix: use legacy uploads |
| Notifications | Extend **`NotificationService`** + repo → `/api/mobile/notifications/*` | Foundation `/api/notifications/*` stub | Same |
| Offline sync | Existing **`OfflineRepositoryContract`** → `/api/sync/*`, `/api/offline/*` | Custom sync REST layer | Contracts + DTOs ready |
| Voice | Existing **`VoiceRepositoryContract`** → `/api/voice/*` | — | Contract-only today; implement once |

**`API_BASE_URL`:** Point at **web BFF origin** for `/api/mobile/*` (proxied). Point at **backend origin** for foundation modules (`/api/area`, `/api/ai`, `/api/voice`, `/api/sync`) — or use a single backend URL if web does not proxy foundation (current state). Document in `AppEnv`; do not hardcode two Dio instances unless required.

---

## 1. Theme — Reuse Plan

### Keep as-is

| Asset | Path | Reuse in |
|-------|------|----------|
| `AppTheme.light()` / `AppTheme.dark()` | `lib/theme/app_theme.dart` | All new screens |
| `themeModeProvider` | `lib/theme/theme_controller.dart` | Settings (already); persist later via `CacheStore` |
| `lightThemeProvider` / `darkThemeProvider` | `lib/theme/theme_controller.dart` | `PraniDoctorApp` — no change |
| M3 `ColorScheme.fromSeed` (teal seed) | `app_theme.dart` | Cards, lists, buttons on feature pages |

### Extend (minimal)

| Addition | Where | Avoid |
|----------|-------|-------|
| Persist theme mode | `SettingsPage` → `CacheStore.put('settings.themeMode', …)` on toggle | New preferences package or duplicate `SharedPreferences` layer |
| `ThemeExtension` for status colors | `app_theme.dart` only if service-request status chips need fixed semantic colors | Full rebrand or new color palette |
| Bengali locale | Add `app_bn.arb`; keep same `ThemeData` | Separate theme per locale |

---

## 2. Widgets — Reuse Plan

**Current state:** No `lib/shared/widgets/`. Plan: **extract once, reuse everywhere** — patterns copied from existing screens, not redesigned.

### Extract from existing screens (Phase 1)

| New shared widget | Source pattern | Used by |
|-------------------|----------------|---------|
| `AppLoadingView` | Replace inline loading need | Home, Services, Inbox when `AsyncValue.loading` |
| `AppErrorView` | SnackBar + retry pattern from login | All list/detail screens |
| `AppEmptyView` | Centered `Text` from placeholder pages | Inbox, Services, animals list |
| `AppPrimaryButton` | `FilledButton` in `LoginPage` | OTP verify, book service, submit forms |
| `AppOutlinedButton` | `OutlinedButton` in `LoginPage` | Google/Facebook (wire to `AuthRepository`) |
| `AppSectionTitle` | `headlineSmall` in Home/Services/Inbox | Section headers on Home dashboard |

**Location:** `lib/shared/widgets/` — first additions only when second screen needs the same pattern.

### Reuse shell components (no changes to structure)

| Widget | Path | Reuse |
|--------|------|-------|
| `AppShellScaffold` | `lib/routing/shell/app_shell_scaffold.dart` | Keep bottom nav + drawer; add badge on Inbox tab later via `navigationShell` wrapper, not new scaffold |
| `AppBar` from shell | Same | Title stays `l10n.appTitle`; feature subtitles go in page body |
| `SwitchListTile` | `SettingsPage` | Template for notification toggles when settings registry grows |
| `ListView` + padding | `SettingsPage` | Template for Settings subsections (profile, devices) |

### Do not create

- Parallel `PraniButton`, `PraniCard` design system
- Custom bottom navigation (shell already has `NavigationBar`)
- Duplicate drawer menu (extend `ListTile`s only if new tab added — prefer nested routes instead)

---

## 3. Services — Reuse Plan

### Extend in place

| Service | Path | Extension (not duplicate) |
|---------|------|---------------------------|
| **SessionController** | `lib/core/session/session_controller.dart` | Add `accessToken` getter for Dio interceptor; keep `setSession` / `signOut`; remove `signInDevPlaceholder` behind `kDebugMode` only |
| **AuthRepository** | `lib/features/auth/data/auth_repository.dart` | Add `requestOtp`, `verifyOtp`, `register`, `refreshToken` → `/api/mobile/auth/*`; wire Google/Facebook to existing methods; reuse injected `_dio` |
| **dioProvider** | `lib/core/network/dio_provider.dart` | Add auth interceptor reading `SessionController`; map errors to `AppException`; single Dio instance |
| **NotificationService** | `lib/features/notifications/notification_service.dart` | After login, call `POST /api/mobile/devices/register` with FCM token; keep existing `initialize()` |
| **MediaUploadCoordinator** | `lib/features/media/media_upload_coordinator.dart` | Implement queue drain with `_dio.post('/api/mobile/uploads')`; use `CacheStore` for pending IDs per architecture plan |
| **CacheStore** | `lib/core/cache/cache_store.dart` | Area cache (`AreaCacheContract`), AI drafts (`AiDraftContract`), theme preference, upload queue metadata |
| **AppStartup** | `lib/app/app_startup.dart` | Chain: restore session → register device if authenticated → optional sync status poll |

### Implement contracts (one class each — no duplicates)

| Contract | Implementation file (new) | Reuses |
|----------|---------------------------|--------|
| `AreaRepositoryContract` | `lib/features/area/data/area_repository.dart` | `AreaNodeDto`, `AreaApiPaths`, `dioProvider`, `AreaCacheContract` + `CacheStore` |
| `AiRepositoryContract` | `lib/features/ai/data/ai_repository.dart` | `ai_dto.dart`, `AiApiPaths`, `ApiResult` |
| `OfflineRepositoryContract` | `lib/features/offline/data/offline_repository.dart` | `offline_dto.dart`, `SyncCoordinatorContract` impl in same feature |
| `VoiceRepositoryContract` | `lib/features/voice/data/voice_repository.dart` | `voice_dto.dart`, defer until P2 |
| Mobile service requests | `lib/features/services/data/service_request_repository.dart` | **New** mobile DTOs mirroring backend JSON only — do not reuse `TreatmentDto` |
| Mobile profile | `lib/features/profile/data/profile_repository.dart` | Extend **`UserProfileDto`** for `/api/mobile/me` response shape |
| Mobile notifications | `lib/features/notifications/data/notification_repository.dart` | Separate from `NotificationService` (SDK vs REST) — service handles FCM, repo handles API |

### Do not implement (wrong persona / duplicate)

| Contract | Reason |
|----------|--------|
| `TreatmentRepositoryContract` | Doctor `/api/cases/*` — use `/api/mobile/service-requests/*` for end-user |
| Second `AuthService` / `TokenManager` | Extend `SessionController` + `AuthRepository` |
| Foundation `/api/media/*` client | Use `MediaUploadCoordinator` + mobile uploads |
| `NoOpVideoCallGateway` replacement until vendor chosen | Keep stub; do not add call UI |

---

## 4. DTO — Reuse Plan

### Reuse directly (wire to repositories — no renames)

| DTO file | Types | Backend alignment |
|----------|-------|-------------------|
| `lib/core/ai/ai_dto.dart` | `AiChatResponseDto`, `AiTriageResponseDto`, `AiMemoryEntryDto`, `AiEscalationDto` | `/api/ai/*` foundation |
| `lib/core/ai/ai_conversation_model.dart` | `AiConversationModel`, `AiConversationMessage` | Local UI state only; pair with `AiDraftContract` + `CacheStore` |
| `lib/core/area/area_dto.dart` | `AreaNodeDto`, `AreaSearchHitDto`, `AreaPage<T>` | `/api/area/*` |
| `lib/core/voice/voice_dto.dart` | All voice response DTOs | `/api/voice/*` |
| `lib/core/offline/offline_dto.dart` | `SyncStatusDto`, `SyncItemInput`, `OfflineQueueItemDto`, enums | `/api/sync/*`, `/api/offline/*` |
| `lib/core/error/api_result.dart` | `ApiResult<T>` | All repository return types |
| `lib/core/error/app_exception.dart` | `AppException` | Error mapping from Dio |
| `lib/core/session/session_state.dart` | `SessionState` | Auth snapshot in UI |
| `lib/core/models/user_profile_dto.dart` | `UserProfileDto` | Extend fields if `/api/mobile/me` returns more keys |

### Extend (add fields only — do not fork)

| DTO | Change |
|-----|--------|
| `UserProfileDto` | Add optional phone, avatarUrl, locale from mobile me payload |
| `AreaRepositoryContract` | Add `getSeedVersion()` + constant in `AreaApiPaths` when implementing cache invalidation |

### Add new (mobile-only — no existing DTO)

Place under `lib/features/<feature>/data/` to avoid polluting `core/`:

| Feature | New DTOs (examples) | API |
|---------|---------------------|-----|
| Services | `ServiceCategoryDto`, `ServiceRequestDto`, `ServiceRequestTimelineEventDto` | `/api/mobile/service-*` |
| Providers | `ProviderDoctorDto`, `ProviderTechnicianDto` | `/api/mobile/providers/*` |
| Animals | `AnimalDto` | `/api/mobile/animals/*` |
| Notifications | `MobileNotificationDto` | `/api/mobile/notifications/*` |
| AI services (product) | `AiServiceRequestDto` | `/api/mobile/ai-services/*` |

Use `json_serializable` + `build_runner` same as `UserProfileDto` — do not hand-write duplicate parsers if codegen fits.

### Do not duplicate

| Avoid | Use instead |
|-------|-------------|
| Copy `AreaNodeDto` for `/api/mobile/locations` | Single `AreaRepository` on `/api/area/*` |
| Copy AI response types for voice chat | `VoiceChatResponseDto` already distinct; share disclaimer/refused flags in UI only |
| `TreatmentAggregateDto` in customer flows | Mobile service request DTOs |
| Parallel Freezed models for same JSON | One DTO per wire shape |

### Defer / park

| DTO file | Action |
|----------|--------|
| `lib/core/treatment/treatment_dto.dart` | **Park** — no repository impl in end-user app v1; keep file for future doctor app or shared package |

---

## 5. Screens — Reuse Plan

### Evolve existing routes (no new tab bar items)

| Screen | Path | Route | Reuse strategy |
|--------|------|-------|----------------|
| **LoginPage** | `features/auth/presentation/login_page.dart` | `/login` | Keep layout: add OTP phone field + verify step; wire Google/Facebook to existing `authRepositoryProvider`; keep dev button under debug flag |
| **HomePage** | `features/home/home_page.dart` | `/home` | Replace centered text with dashboard sections fed by `GET /api/mobile/profile/dashboard-context`; reuse `AppShellScaffold` AppBar |
| **ServicesPage** | `features/services/services_page.dart` | `/services` | List from `GET /api/mobile/service-categories`; tap → nested `GoRoute` `/services/book` (child of shell branch 1) |
| **InboxPage** | `features/inbox/inbox_page.dart` | `/inbox` | **Dual reuse:** service requests list (`/api/mobile/service-requests`) + notifications (`/api/mobile/notifications`); segmented control or tabs **inside page** — not new bottom nav item |
| **SettingsPage** | `features/settings/settings_page.dart` | `/settings` | Keep theme toggle + sign out; add profile summary from session + `/api/mobile/me`; reuse `ListView` pattern |

### Add nested routes under existing shell (extend `app_router.dart`)

| New route | Parent branch | Purpose |
|-----------|---------------|---------|
| `/services/request/:id` | Services (branch 1) | Service request detail + timeline |
| `/services/book` | Services (branch 1) | Create service request |
| `/inbox/notifications/:id` | Inbox (branch 2) | Notification detail |
| `/settings/profile` | Settings (branch 3) | Edit profile (`PATCH /api/mobile/me`) |
| `/home/ai-chat` | Home (branch 0) | AI assistant using `AiRepositoryContract` |

**Reuse:** `NoTransitionPage`, `AppShellScaffold`, existing `AppRoutes` constants — append paths in `app_routes.dart` only.

### Screen ↔ API mapping (reuse plan)

| Screen | APIs (from integration matrix) | Priority |
|--------|----------------------------------|----------|
| LoginPage | `/api/mobile/auth/otp/*`, register, refresh; OAuth via AuthRepository | P0 |
| HomePage | `/api/mobile/profile/dashboard-context`, `/api/mobile/me` | P0 |
| ServicesPage | `/api/mobile/service-categories`, POST service-requests | P0 |
| InboxPage | `/api/mobile/service-requests`, `/api/mobile/notifications` | P0 / P1 |
| SettingsPage | sign out (existing), `/api/mobile/me`, theme persist | P0 / P1 |
| Nested: book service | POST service-requests, `AreaRepository` picker, animals list | P0 |
| Nested: AI chat | `/api/ai/chat`, `/api/ai/triage` | P1 |
| Nested: providers | `/api/mobile/providers/*` | P1 |

### Do not add (avoid scope creep / duplicate UX)

| Skip v1 | Reason |
|---------|--------|
| New “Cases” or “Treatment” tab | Doctor persona; customer uses Inbox + service requests |
| Separate “Notifications” tab | Reuse InboxPage |
| Redesigned onboarding splash | Not in current shell; add later as route outside shell if needed |
| Duplicate login screen | One `LoginPage` with steps |

---

## 6. Riverpod — Reuse Plan

Extend provider graph; do not parallel `ProviderScope` trees.

| New provider | Builds on | Pattern |
|--------------|-----------|---------|
| `authInterceptorProvider` | `sessionControllerProvider`, `dioProvider` | Middleware only |
| `profileRepositoryProvider` | `dioProvider` | Same as `authRepositoryProvider` |
| `serviceRequestRepositoryProvider` | `dioProvider`, `ApiResult` | Same |
| `areaRepositoryProvider` | `dioProvider`, `cacheStoreProvider` | Same |
| `aiRepositoryProvider` | `dioProvider` | Same |
| `dashboardProvider` | `profileRepository` or dedicated repo | `FutureProvider` / `AsyncNotifier` |
| `serviceCategoriesProvider` | `serviceRequestRepository` | `FutureProvider` |
| `inboxRequestsProvider` | `serviceRequestRepository` | `AsyncNotifier` for pull-to-refresh |

**Reuse:** `ConsumerWidget` / `ConsumerStatefulWidget` as in `LoginPage` and `SettingsPage`.

---

## 7. l10n — Reuse Plan

| Asset | Reuse |
|-------|-------|
| `lib/l10n/app_en.arb` | Add keys for OTP, errors, empty states — keep `appTitle`, `navHome`, etc. |
| `AppLocalizations` in shell + pages | All new strings via ARB, not hardcoded (replace Settings “Dark mode”, “Sign out”) |
| `loginDevContinue`, `nav*` keys | Keep; used by existing screens |

Add Bengali (`app_bn.arb`) when implementing area/AI locale defaults — reuse same keys.

---

## 8. Implementation Phases (Reuse-Ordered)

### Phase A — Wire core (reuse session + auth + dio)

1. Extend `dioProvider` interceptor → `SessionController`
2. Extend `AuthRepository` with mobile OTP paths
3. Wire `LoginPage` → `authRepositoryProvider` (remove SnackBar stubs)
4. Reuse `AppStartup` session restore (already exists)

**Reuse score:** 100% existing auth stack extended.

### Phase B — First data on existing screens

1. `profileRepository` + `UserProfileDto` → **HomePage**, **SettingsPage**
2. `serviceRequestRepository` + new mobile DTOs → **ServicesPage**, **InboxPage**
3. Extract `AppLoadingView` / `AppEmptyView` when second list screen needs them

**Reuse score:** 5/5 existing screens evolved; 0 new top-level routes.

### Phase C — Foundation modules (reuse contracts)

1. `AreaRepository` implements `AreaRepositoryContract` — use in book-service flow
2. `AiRepository` implements `AiRepositoryContract` — nested `/home/ai-chat`
3. Extend `NotificationService` + notification repo → **InboxPage**

**Reuse score:** All foundation DTOs/contracts; no second AI/area client.

### Phase D — Cross-cutting (reuse coordinators)

1. `MediaUploadCoordinator` → `/api/mobile/uploads`
2. `OfflineRepository` + `SyncCoordinatorContract` → background only; optional queue UI in Settings
3. `VoiceRepository` — P2; reuse `voice_dto.dart`

---

## 9. Anti-Duplication Checklist

Before merging any PR, verify:

- [ ] No second Dio client for the same base URL without documented reason
- [ ] No new auth token storage outside `SessionController` / `FlutterSecureStorage`
- [ ] No `/api/mobile/locations` repo if `/api/area` repo exists
- [ ] No customer UI calling `/api/cases/*`
- [ ] No foundation `/api/media` or `/api/notifications` client
- [ ] New UI uses `Theme.of(context)` / existing `AppTheme`, not inline one-off colors
- [ ] New lists use extracted shared widgets once second copy would appear
- [ ] New strings in ARB, not duplicated hardcoded labels
- [ ] New routes are nested under existing shell branches unless explicitly new product area
- [ ] DTOs added only for wire shapes not already in `lib/core/`

---

## 10. Reuse Summary Matrix

| Layer | Exists today | Reuse action | Do not duplicate |
|-------|--------------|--------------|------------------|
| **Theme** | M3 light/dark, theme providers | Persist mode in CacheStore | New design system |
| **Widgets** | Shell, login/settings patterns | Extract 5–6 shared widgets when needed | Custom nav/scaffold |
| **Services** | Session, Auth (partial), FCM, upload stub, cache | Extend + implement contracts | Parallel auth/upload/sync |
| **DTOs** | AI, area, voice, offline, user profile, errors | Wire to repos; add mobile-only in features | Location/treatment forks |
| **Screens** | 5 pages + shell | Evolve + nested routes | New tab bar, second login |
| **Routing** | go_router + auth redirect | Add child routes | Second router |
| **State** | 11 providers | Add feature repos as providers | Global singletons |

---

## 11. Expected Outcomes

| Metric | Before | After reuse plan (target) |
|--------|--------|---------------------------|
| Top-level tabs | 4 | 4 (unchanged) |
| New shared widget library | 0 | 5–6 extracted widgets |
| Duplicate API clients per domain | 0 planned | 0 (enforced by checklist) |
| Foundation DTOs reused | 0 wired | 4 domains wired (area, ai, voice, offline) |
| Screens replaced | 0 | 0 — all 5 extended |
| Scaffold completion | 62% | ~85% after Phase C |
| End-user product completion | 20% | ~45% after Phase C |

---

*Reuse plan complete. No code changes were made.*
