# Master App Architecture Plan

**Audience:** architects, tech leads, and senior engineers working on **pranidoctor_user** (PraniDoctor end-user mobile).

**Nature:** authoritative, repository-local architecture reference. This document is **not** tied to Cursor or any ephemeral chat transcript.

---

## 1. Goals & scope

- **Primary users:** agricultural **farmers/producers** and **consumer customers** of PraniDoctor services (education, consultations, agronomy-facing workflows as product defines them).
- **Product intent:** deliver a scalable, observable **consumer mobile shell** aligned with the **pranidoctor-web** API—navigation, authenticated API access, push readiness, caching, uploads, and future live engagement—without collapsing concerns into widgets.
- **Explicitly excluded from this codebase’s scope:**
  - **Doctor-facing** clinical or telemedicine staff apps (distinct persona, approvals, HIPAA-like constraints where applicable).
  - **Administrative consoles** (/admin, enterprise dashboards, moderation, template publishing)—owned by **pranidoctor-web** and separate admin tooling.
  - **AI worker / technician** flows (bulk AI service instances, review queues, labeling tools)—explicitly modeled elsewhere (**pranidoctor-web** mobile AI-technician routes are out of persona for **pranidoctor_user**).
  - Backend business rules: **never** duplicated as source-of-truth in the app; server remains authoritative.

---

## 2. Principles

- **Feature-first layout:** code is grouped by **feature** (lib/features/<feature>/...) with **data** and **presentation** separated; shared mechanisms live under lib/core/, lib/app/, lib/routing/, lib/theme/, lib/l10n/.
- **No business logic in UI:** Widget / uild methods bind state and dispatch actions; validation, mapping, retries, and policy belong in **repositories**, **coordinators**, or **session** layers.
- **Repository pattern:** each domain area exposes a repository (e.g. AuthRepository) that owns I/O (HTTP, OAuth SDKs, local persistence), returns **ApiResult<T>**, and depends on **Dio**, **SessionController**, and **CacheStore** as appropriate—not on concrete pages.
- **DTO mapping:** JSON and wire shapes are deserialized into **DTOs** / Freezed models under lib/core/models/ (or feature-local data/ as the app grows); UI consumes stable view-friendly types, not raw Map responses.
- **Offline-first preparation:** **Hive** + **CacheStore** hold non-sensitive cache and queues; **lutter_secure_storage** holds tokens only. Full offline UX (conflict resolution, sync engine) is **incremental**—structure supports it without pretending it is finished.

---

## 3. Tech stack

| Area | Choice | Role |
|------|--------|------|
| UI framework | **Flutter** (Dart SDK as in pubspec.yaml) | Cross-platform UI, single codebase for iOS/Android. |
| State / DI | **flutter_riverpod** | Provider / StateNotifierProvider for configuration, session, router, repositories, theme. |
| Navigation | **go_router** | Declarative routes, **redirect** for auth, **StatefulShellRoute** for tab shell. |
| HTTP | **Dio** | REST client; **interceptors** for auth header, logging, error mapping, future token refresh. |
| Local cache | **hive** + **hive_flutter** | Offline-friendly box(es); wrapped by **CacheStore**. |
| Secrets & tokens | **flutter_secure_storage** | Access tokens and other secrets; **not** in Hive/shared_prefs for production. |
| Push / analytics groundwork | **firebase_core**, **firebase_messaging** | FCM initialization, permissions, foreground message hooks (NotificationService). |
| OAuth | **google_sign_in**, **flutter_facebook_auth** | Social sign-in; token exchange with **pranidoctor-web** to be wired in **AuthRepository**. |
| UI system | **Material 3** (ThemeData, ColorScheme.fromSeed, useMaterial3: true) | Consistent M3 visuals; **ThemeExtension** reserved for semantic/brand tokens as the design system tightens. |
| Immutable models & results | **freezed** + **json_serializable** | ApiResult, AppException, session state, DTOs. |
| i18n | **flutter_localizations** + **gen-l10n** | ARB-driven AppLocalizations. |

---

## 4. Canonical lib/ folder tree (this repository)

As implemented:

`	ext
lib/
  main.dart
  app/
    app.dart
    app_env.dart
    app_startup.dart
    bootstrap.dart
  core/
    cache/
      cache_providers.dart
      cache_store.dart
      hive_bootstrap.dart
    error/
      api_result.dart
      api_result.freezed.dart
      app_exception.dart
      app_exception.freezed.dart
    models/
      user_profile_dto.dart
      user_profile_dto.g.dart
    network/
      dio_provider.dart
    session/
      session_controller.dart
      session_state.dart
      session_state.freezed.dart
  features/
    auth/
      data/
        auth_repository.dart
      presentation/
        login_page.dart
    calls/
      video_call_gateway.dart
    home/
      home_page.dart
    inbox/
      inbox_page.dart
    media/
      media_upload_coordinator.dart
    notifications/
      notification_service.dart
    services/
      services_page.dart
    settings/
      settings_page.dart
  l10n/
    app_en.arb
    app_localizations.dart
    app_localizations_en.dart
  routing/
    app_router.dart
    app_routes.dart
    shell/
      app_shell_scaffold.dart
  theme/
    app_theme.dart
    theme_controller.dart
`

**Project-root config:** l10n.yaml (ARB directory, template file, generated class name), nalysis_options.yaml, pubspec.yaml (lutter: generate: true).

---

## 5. Cross-cutting systems

### 5.1 AppEnv and --dart-define

- **AppEnv.fromEnvironment()** (lib/app/app_env.dart) reads compile-time defines:
  - **API_BASE_URL**: REST base URL (default placeholder in code; override per environment).
  - **LOG_NETWORK**: toggle network logging hooks (default alse).
  - **ENABLE_PUSH**: gate FCM initialization (default 	rue).
- Builds pass values via **lutter run / lutter build** with **--dart-define=KEY=value**. No secrets belong in defines; only **non-secret** endpoints and flags.

### 5.2 Dio, interceptors, and refresh (roadmap)

- **dioProvider** (lib/core/network/dio_provider.dart) supplies a **Dio** with **BaseOptions.baseUrl** from **AppEnv**, timeouts, and an **InterceptorsWrapper**.
- **Current state:** error path forwards **DioException** (onError → handler.next); **TODO:** map to **AppException**, attach **Bearer** **Authorization** from **SessionController**, and implement **queued refresh** on 401 before retry.

### 5.3 ApiResult<T> and AppException

- **ApiResult<T>** (Freezed): **success(T data)** | **ailure(AppException error)**—standard return type from repositories for typed error handling in UI.
- **AppException**: **message**, optional **code**, optional **cause**—normalize HTTP, OAuth, and validation failures.

### 5.4 SessionController

- **SessionController** (StateNotifier<SessionState>): loads/saves **access token** in **FlutterSecureStorage** under a fixed key; exposes **estoreFromStorage**, **signOut**, **setSession**, and a **dev placeholder** sign-in for local testing.
- **sessionControllerProvider** + **secureStorageProvider** wire storage with **Android encrypted shared preferences** and **iOS keychain** accessibility appropriate for secrets.

### 5.5 go_router: ShellRoute, redirects, notifier

- **goRouterProvider**: **GoRouter** with **StatefulShellRoute.indexedStack** → **AppShellScaffold** (home, services, inbox, settings tabs).
- **RouterNotifier** implements **ChangeNotifier** and **listens** **sessionControllerProvider** so **efreshListenable** re-evaluates **edirect** when auth changes.
- **edirect**: unauthenticated users → **/login**; authenticated users on login → **/home**. **AppRoutes** centralizes path constants.

### 5.6 Theme and ThemeExtension

- **AppTheme.light() / AppTheme.dark()**: Material 3 **ColorScheme.fromSeed**, centered **AppBar**.
- **	heme_controller.dart**: **	hemeModeProvider** (system/light/dark), **lightThemeProvider**, **darkThemeProvider** injected into **MaterialApp.router**.
- **Convention:** introduce **ThemeExtension<T>** subclasses (e.g. PraniBrandColors) when semantic tokens exceed raw **ColorScheme**; register via **ThemeData.extensions**.

### 5.7 l10n (ARB + generated)

- **Source:** lib/l10n/app_en.arb (template); **l10n.yaml** sets **rb-dir**, template file, and **AppLocalizations** output.
- **lutter gen-l10n** runs when **lutter pub get** / build with **generate: true**; delegates wired in **PraniDoctorApp**.

### 5.8 NotificationService

- **NotificationService** wraps **FirebaseMessaging**: **equestPermission**, foreground **onMessage**, **getToken** (for future registration against **pranidoctor-web**). Respects **AppEnv.enablePush**; catches errors when Firebase is not yet configured.

### 5.9 MediaUploadCoordinator

- **Placeholder** queue for **resumable uploads** (Dio + isolates); intended integration with **CacheStore** for progress IDs and **ApiResult** for completion. UI must not embed upload loops.

### 5.10 VideoCallGateway

- **Abstract** API: **joinRoom**, **leaveRoom**, **connectionStates** stream. **NoOpVideoCallGateway** until a vendor (Agora, Daily, WebRTC) is selected—keeps call UI decoupled from SDK details.

### 5.11 CacheStore

- Thin **typed facade** over **Hive** **Box<dynamic>** (get/put/delete/clear). Opened in **initHiveCache** / **openCacheBox** with a fixed box name **kAppCacheBoxName**.

### 5.12 Settings “registry” pattern

- **Intent:** settings should not scatter ad hoc SharedPreferences keys. Evolve toward a **small registry**: one module listing **typed keys**, default values, and **Riverpod** notifiers/providers per preference (theme mode first; locale, notification channel toggles later). **Sensitive** values remain in **lutter_secure_storage** or server-side, not in Hive.

---

## 6. Security

- **Tokens:** access tokens **only** in **lutter_secure_storage** (see **SessionController**). Avoid logging token values; redact in **LOG_NETWORK** paths when implemented.
- **No secrets in source:** API keys for OAuth (Google/Facebook) belong in **platform config** (Android/iOS as per vendor docs). **Never** commit keystore passwords, Apple private keys, or server client secrets into Dart files.
- **Transport:** HTTPS only against **API_BASE_URL**; certificate pinning is an optional hardening phase.
- **Cache:** **CacheStore** is for **non-sensitive** denormalized data; PII minimization and retention policy should mirror backend contracts.

---

## 7. Firebase structure & version control

- **Expected FlutterFire layout (after configuration):**
  - **Android:** ndroid/app/google-services.json (from Firebase console).
  - **iOS:** ios/Runner/GoogleService-Info.plist.
  - **Dart:** optionally **lib/firebase_options.dart** from **lutterfire configure** used with **Firebase.initializeApp()** (current **ootstrap** calls **Firebase.initializeApp()** without options—add options once generated).
- **What this repo’s .gitignore already excludes:** .dart_tool/, /build/, coverage, IDE noise, etc.—**not** Firebase plist/json by default.
- **Policy guidance:** many teams **commit** **google-services.json**, **GoogleService-Info.plist**, and **irebase_options.dart** because client Firebase config is considered non-secret yet project-specific. **Do not commit** upload keys, **google-services production** credentials if enterprise policy forbids it, **key.properties**, ***.jks**, ***.keystore**, App Store provisioning secrets, or **.env** files with backend secrets—extend **.gitignore** accordingly before adding signing assets.

---

## 8. Alignment with **pranidoctor-web**

- **Base URL:** set **API_BASE_URL** **--dart-define** to the deployed **Next.js app** origin (same host as **pranidoctor-web** API routes), e.g. **https://<your-deployment>**, with REST paths consumed under **/api/...** as defined by that repo (adjust when mobile-specific routes stabilize).
- **Authentication:** **Authorization: Bearer <access_token>** on **Dio** requests once interceptor is implemented; tokens obtained via **OAuth** → backend **token exchange** (placeholders in **AuthRepository** to be replaced with real **_dio.post** to **pranidoctor-web** auth/session endpoints).
- **Contract:** request/response shapes and error codes must be treated as **server-owned**; client DTOs updated when **pranidoctor-web** OpenAPI or route handlers change.

---

## 9. Phased rollout

1. **Shell:** **ootstrap**, **ProviderScope**, **CacheStore** override, **MaterialApp.router**, **AppShellScaffold** + tab branches, **AppRoutes**, theme + l10n wiring.
2. **Core:** **AppEnv**, **dioProvider**, **ApiResult/AppException**, **CacheStore/Hive**, error mapping in interceptors (incremental).
3. **Auth:** **SessionController** persistence, **go_router edirect**, **AuthRepository** OAuth + backend exchange, Bearer interceptor, sign-out flows.
4. **Cross-cutting:** **NotificationService** + device token registration API, **MediaUploadCoordinator** + real endpoints, **VideoCallGateway** implementation, settings registry expansion, offline queue hardening.

---

## 10. ADR summary (Architecture Decision Records)

| ADR | Decision | Rationale |
|-----|----------|-----------|
| **ADR-001** | **Riverpod** for app-wide DI and session | Testable providers, granular rebuilds, fits **StateNotifier** for **SessionController**. |
| **ADR-002** | **go_router** with **StatefulShellRoute** | First-class redirects and nested tab state without a second imperative API. |
| **ADR-003** | **Dio** (not raw HttpClient) | Interceptors, timeouts, cancellation, future refresh queue. |
| **ADR-004** | **Hive** for cache; **secure_storage** for tokens | Performance/simplicity vs. separation of secrets. |
| **ADR-005** | **Freezed** for **ApiResult** / errors | Exhaustive mapping, codegen consistency with **json_serializable**. |
| **ADR-006** | **Firebase Cloud Messaging** for push | Ecosystem fit; guarded by **ENABLE_PUSH** until backend registration exists. |

*(Add numbered ADRs under docs/adr/ as decisions harden.)*

---

## 11. Explicitly out of scope for v1 scaffold

- **Full ecommerce** (cart, payments, invoicing, tax, multi-warehouse inventory).
- **Marketplace / third-party seller onboarding** unrelated to core PraniDoctor services.
- **Complete offline CRDT / sync** (only preparatory **CacheStore** and patterns).
- **Production video conferencing** (**VideoCallGateway** remains stubbed).
- **Doctor, admin, and AI-worker** surfaces (see §1).
- **End-to-end social OAuth → backend token** (present as **TODO**s in **AuthRepository** until API contracts are fixed).

---

*Document version: aligned with **pranidoctor_user** repository layout and dependencies as of authoring. Update when **lib/** structure or integrations change materially.*
