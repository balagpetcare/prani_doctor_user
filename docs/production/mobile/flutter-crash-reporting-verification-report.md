# Flutter Crash Reporting — Verification Report

**Repo:** `pranidoctor_user`  
**Date:** 2026-05-30  
**Auditor:** Automated unit tests + static code review  
**Plan reference:** [flutter-crash-reporting-plan.md](./flutter-crash-reporting-plan.md)  
**Test suite:** [`test/core/crash_reporting_verification_test.dart`](../../../test/core/crash_reporting_verification_test.dart)

---

## Executive summary

| Validation area | Result | Evidence |
|-----------------|--------|----------|
| Crash capture (framework / UI) | **PASS** | Unit tests V1; `GlobalErrorHandler` + `AppLog` funnel |
| Async exception capture | **PASS** | Unit test V2; zone + `PlatformDispatcher` handlers wired |
| Startup crash capture | **PASS** (code) / **PARTIAL** (runtime) | Zone wraps full bootstrap; boot E10 tested; pre-`runApp` fatals need device smoke |
| Release tagging | **PASS** | Unit test V4; `CrashReportingBootstrap.applyReleaseInfo` |
| Production safety | **PASS** | Debug → `NoOpCrashReporter`; redaction; throttle; HTTPS-only webhook |

**Overall verdict:** **PASS for engineering verification** — core reporting pipeline is correctly wired and covered by automated tests. **Manual release smoke** (Crashlytics dashboard + webhook ingest on a signed release build) remains **PENDING** until ops configures secrets and Firebase.

```
flutter test test/core/crash_reporting_verification_test.dart
→ 11/11 passed (2026-05-30)

flutter analyze lib/core/logging … crash_reporting_network_interceptor.dart
→ No issues found
```

---

## 1. Crash capture

### Expected behavior

Unhandled framework and UI errors flow: **Error source → `AppLog.error` → `CrashReporter.recordError`**, with error category tags (E01–E04).

### Code paths verified

| Source | Handler | Category | Fatal | Status |
|--------|---------|----------|-------|--------|
| `FlutterError.onError` | `GlobalErrorHandler._onFlutterError` | E01 | Yes | Wired |
| `ErrorWidget.builder` | `GlobalErrorHandler` → `AppGracefulErrorWidget` | E03 | No | Wired |
| `AppErrorBoundary` | `AppLog.error` | E04 | No | Wired |
| `SafeNavigation` failures | `AppLog.error` | E05 | No | Wired |

### Automated tests

| Test | Result |
|------|--------|
| Zone handler records fatal error with E02 | ✅ PASS |
| `AppLog.error` merges release/env context + E03 category | ✅ PASS |

### Gaps

- `FlutterError.onError` and `ErrorWidget.builder` are not exercised in unit tests (require full widget binding / render tree).
- **Manual check (optional):** Debug-only throw in a button → confirm webhook/Crashlytics receives E01/E03 on release build with `ENABLE_CRASH_REPORTING=true`.

---

## 2. Async exception capture

### Expected behavior

Uncaught async errors in the main isolate are caught by `runZonedGuarded` and `PlatformDispatcher.instance.onError`, both delegating to `AppLog.error` with category **E02**.

### Code paths verified

```text
main() → bootstrap()
  → GlobalErrorHandler.runGuarded(_bootstrapApp)
      → runZonedGuarded(..., handleZoneError)
      → PlatformDispatcher.instance.onError = _onPlatformError
```

`AppLog.recordError` uses **`unawaited`** — reporting does not block the error path.

### Automated tests

| Test | Result |
|------|--------|
| `handleZoneError` → recorder, fatal=true, E02 | ✅ PASS |
| `runZonedGuarded` + delayed throw → recorder | ✅ PASS |

### Gaps

- `PlatformDispatcher.onError` not directly invoked in tests (same funnel as zone handler — low risk).

---

## 3. Startup crash capture

### Expected behavior

Failures during cold start (Hive, locale, `assertProductionReady`, Firebase) occur inside `GlobalErrorHandler.runGuarded` and are reported as fatals when release reporting is enabled.

Boot-time **recoverable** config failures (offline API) report as **non-fatal E10**.

### Bootstrap sequence (verified by static review)

| Step | Reporting |
|------|-----------|
| `resolveCrashReporter` before zone | Initial reporter (webhook if release) |
| `CrashReportingBootstrap.applyEnvironment` | Custom keys: `app_env`, `api_host` |
| `ensureFirebaseInitialized` + `activateFirebaseReporting` | Rebinds composite with Crashlytics |
| `applyReleaseInfo` | Sets `release`, `app_version`, `build_number` |
| `ProviderScope(observers: [CrashReportingProviderObserver])` | Riverpod failures → E12 |

### Automated tests

| Test | Result |
|------|--------|
| Boot E10 non-fatal via `AppLog.error` | ✅ PASS |

### Gaps

| Gap | Severity | Notes |
|-----|----------|-------|
| Full `bootstrap()` not integration-tested | Medium | Would need Hive/Firebase test harness |
| `assertProductionReady` throw before reporter rebind | Low | Still caught by zone; env keys set early |
| **Manual:** Kill API at boot → retry UI | Pending | Documented in plan V8 |

---

## 4. Release tagging

### Expected behavior

Every crash event includes compile-time and runtime release metadata.

### Metadata sources

| Field | Source |
|-------|--------|
| `app_env` | `APP_ENV` dart-define → `CrashReportingContext` |
| `release` | `PackageInfo`: `{version}+{buildNumber}` |
| `app_version` / `build_number` | `CrashReportingBootstrap.applyReleaseInfo` |
| `api_host` | `AppEnv.apiHost` (host only, not full URL) |
| Webhook top-level `service` | Constant `pranidoctor-user` |

### Automated tests

| Test | Result |
|------|--------|
| Webhook JSON includes `service`, `release`, `app_env`, nested `context` | ✅ PASS |
| `AppLog.error` context includes `release`, `app_env`, `api_host` | ✅ PASS |
| `CompositeCrashReporter` fan-out to all delegates | ✅ PASS |

### CI / build pipeline

| Item | Status |
|------|--------|
| `--obfuscate --split-debug-info=build/debug-info` in `build_release.ps1` | ✅ Present |
| `debug-info` artifact upload in `release.yml` | ✅ Present |
| `CRASH_REPORTING_WEBHOOK_URL` in release workflow | ✅ Present (secret) |
| Firebase symbol upload automation | ❌ Not automated (manual ops) |

---

## 5. Production safety

### Controls verified

| Control | Implementation | Test |
|---------|----------------|------|
| No reporting in debug by default | `crashReportingEnabled()` → `kReleaseMode` | ✅ PASS |
| Opt-in debug QA | `ENABLE_CRASH_REPORTING=true` dart-define | Documented |
| Webhook HTTPS-only | Factory rejects non-`https://` URLs | ✅ Static |
| PII redaction | `LogRedactor` on webhook message/reason | ✅ PASS |
| Network noise suppression | Skip 401/403/404/422; throttle 1/min per route | ✅ PASS |
| Non-blocking I/O | `unawaited(recordError)` in `AppLog` + composite | ✅ Static |
| Webhook timeout | 5s send/receive; silent catch | ✅ Static |
| Session identity | Opaque `userId` via `setUserId`; cleared on sign-out | ✅ Code review |
| Crashlytics off in debug | `setCrashlyticsCollectionEnabled(crashReportingEnabled(...))` | ✅ Static |

### Network failure reporting

| HTTP / Dio type | Reported? | Verified |
|-----------------|-----------|----------|
| 503 server error | Yes (E07, non-fatal) | ✅ PASS |
| 401 unauthorized | No | ✅ PASS |
| Duplicate 503 within 1 min | Throttled | ✅ PASS |

### Background isolate (FCM)

| Item | Status |
|------|--------|
| `firebaseMessagingBackgroundHandler` try/catch | ✅ Code review |
| Crashlytics `recordError` with E11 + release info | ✅ Code review |
| Unit test in VM | ❌ Not tested (requires Firebase init) |

### Remaining risks (unchanged from stability audit)

| Risk | Impact on reporting |
|------|---------------------|
| ~244 force-unwraps in presentation | Uncaught → E01/E02 if zone doesn't catch sync throw |
| Partial `SafeParse` adoption | Schema errors may surface as E07/E08 |
| No Crashlytics without `google-services.json` | Webhook-only until Firebase configured |

---

## 6. Test matrix (automated)

| ID | Description | Result |
|----|-------------|--------|
| V1a | Zone fatal + E02 category | ✅ |
| V1b | UI path context + E03 metadata | ✅ |
| V2 | Async throw inside `runZonedGuarded` | ✅ |
| V3 | Boot recoverable E10 non-fatal | ✅ |
| V4a | Webhook release/env payload | ✅ |
| V4b | Composite fan-out | ✅ |
| V5a | Debug → `NoOpCrashReporter` | ✅ |
| V5b | Bearer token redaction | ✅ |
| V5c | 401 not reported | ✅ |
| V5d | 503 reported once (throttled) | ✅ |
| V5e | Throttle duplicate keys | ✅ |

**Total: 11/11 passed**

---

## 7. Manual verification checklist (ops / QA)

Run on a **signed release build** with secrets configured:

| # | Step | Pass criteria |
|---|------|---------------|
| M1 | Build with `-CrashWebhookUrl https://…` and Firebase config | AAB succeeds |
| M2 | Force non-fatal network error (airplane mode → API call) | Single E07 in webhook; user sees offline UI |
| M3 | Login → trigger test crash | Crash tagged with opaque user id |
| M4 | Sign out → crash | User id cleared in Crashlytics |
| M5 | Firebase Crashlytics console | Event within ~15 min; release = `1.0.0+{build}` |
| M6 | Download CI `debug-info` artifact | `flutter symbolize` produces readable frames |

---

## 8. Recommendations

| Priority | Action |
|----------|--------|
| P1 | Configure `CRASH_REPORTING_WEBHOOK_URL` + `GOOGLE_SERVICES_JSON` in release CI secrets |
| P1 | Execute manual checklist M1–M6 on internal track before production rollout |
| P2 | Automate Firebase symbol upload in `release.yml` tag builds |
| P3 | Add integration test for `SessionController._syncCrashUserId` |
| P3 | Add widget test forcing `ErrorWidget` path (E03) |

---

## 9. Sign-off

| Role | Status | Date |
|------|--------|------|
| Engineering (automated) | **PASS** — 11/11 tests, analyzer clean | 2026-05-30 |
| Ops (webhook + Crashlytics live) | **PENDING** | — |
| QA (device smoke M1–M6) | **PENDING** | — |

---

## Document history

| Date | Change |
|------|--------|
| 2026-05-30 | Initial verification report after crash reporting implementation |
