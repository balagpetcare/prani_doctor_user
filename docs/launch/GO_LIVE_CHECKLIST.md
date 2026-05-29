# Go-Live Checklist — Prani Doctor

**Verification date:** 2026-05-29  
**Scope:** Flutter user app · Express backend · Next.js admin/doctor BFF · PostgreSQL · Redis · MinIO  
**Auditor method:** Automated test runs, static code review, env validation dry-run, cross-repo workflow inspection. **No production VPS was exercised in this session.**

---

## How to use this checklist

| Symbol | Meaning |
|--------|---------|
| ✅ | Verified in this audit (code or local CI) |
| ⚠️ | Partially verified — risk documented |
| ❌ | Not verified or failed |
| 🔧 | Ops task — requires live host |

Mark each item on launch day in [LAUNCH_DAY_RUNBOOK.md](./LAUNCH_DAY_RUNBOOK.md).

---

## A. Platform readiness

| # | Item | Status | Evidence / notes |
|---|------|--------|------------------|
| A1 | Backend unit tests green | ⚠️ | 237/237 tests pass; 1 archived suite fails (`auth.repository.test.ts` import path) |
| A2 | Web unit tests green | ✅ | 95/95 vitest pass (`pranidoctor-web`) |
| A3 | Flutter unit tests green | ⚠️ | 220 pass / 11 fail — golden pixel diffs + widget tests |
| A4 | Flutter analyze clean (errors) | ⚠️ | 89 issues (mostly info/lint); 0 blocking errors reported |
| A5 | Backend `validate:production-env` | ✅ | Passes with production-shaped env (2026-05-29 dry-run) |
| A6 | Web `validate:production-env` in CI | ✅ | Job on main branch in `ci.yml` |
| A7 | Production TLS live | ❌ | nginx example only; no cert deployed in repo |
| A8 | `/ready` health gate on API | 🔧 | Code exists; not curl-tested against public hostname |
| A9 | DB backup cron installed | 🔧 | `install-backup-cron.sh` exists; not run on VPS |
| A10 | Restore drill completed | ❌ | No drill log in repo |
| A11 | Deploy workflow executed E2E | ❌ | GHCR push defined; SSH deploy requires `DEPLOY_*` secrets + manual trigger |
| A12 | Sentry / webhook receiving errors | ❌ | Hooks wired; no live DSN confirmed |
| A13 | Legal pages HTTP 200 | ⚠️ | Pages exist at `/privacy`, `/terms`, `/refund` on web app; `pranidoctor.com` DNS not verified live |

---

## B. Functional verification (10 domains)

### 1. Authentication

| # | Check | Status | Evidence |
|---|-------|--------|----------|
| B1.1 | Mobile OTP request API | ✅ | `POST /api/mobile/auth/otp/request` — legacy compat + Flutter `AuthApiPaths.otpRequest` |
| B1.2 | Mobile OTP verify + JWT | ✅ | `otp/verify/route.ts` → `mobile-auth.adapter`; session refresh in `refresh_interceptor.dart` |
| B1.3 | Admin panel login | ✅ | `/admin/login` + `/api/admin/auth/login` proxied |
| B1.4 | Doctor panel login | ✅ | `/doctor/login` + doctor JWT stack |
| B1.5 | Token refresh on 401 | ✅ | `SessionManager` + `refresh_interceptor.dart` |
| B1.6 | `OTP_MODE=live` on prod host | 🔧 | Zod blocks dev defaults; must set on server `.env` |
| B1.7 | Live SMS delivery | ❌ | SMS abstraction exists; production Bangladesh provider not verified in this audit |
| B1.8 | Rate limits on auth paths | ✅ | `rateLimitOtpRequest`, `rateLimitOtpVerify`, `rateLimitLogin` on compat router |

### 2. Registration

| # | Check | Status | Evidence |
|---|-------|--------|----------|
| B2.1 | Mobile register endpoint | ✅ | `POST /api/mobile/auth/register` |
| B2.2 | Profile completion after OTP | ✅ | `ProfileCompletionPage` tests pass (union/name flow) |
| B2.3 | Device registration for push | ⚠️ | `/api/mobile/devices/register` exists; FCM token requires Firebase config |
| B2.4 | Terms/privacy acceptance | ✅ | Settings bundle + `PrivacyPage` / `TermsPage` in Flutter |

### 3. Doctor workflow

| # | Check | Status | Evidence |
|---|-------|--------|----------|
| B3.1 | Doctor list assigned requests | ✅ | `/api/doctor/service-requests` |
| B3.2 | Accept request | ✅ | `accept/route.ts` → `acceptServiceRequestForDoctor` |
| B3.3 | Reject request | ✅ | `reject/route.ts` |
| B3.4 | Complete + billing payload | ✅ | `complete/route.ts` with billing schema validation |
| B3.5 | Prescriptions / treatment cases | ✅ | `/api/doctor/service-requests/[id]/prescriptions`, treatment-cases routes |
| B3.6 | Doctor web UI E2E on staging | ❌ | Not executed in this audit session |
| B3.7 | Real-time doctor monitoring (admin) | ❌ | Phase 3 gap — not built |

### 4. Consultation workflow (farmer → doctor)

| # | Check | Status | Evidence |
|---|-------|--------|----------|
| B4.1 | Farmer creates service request | ✅ | Flutter service request repo + `/api/mobile/service-requests` |
| B4.2 | Admin assigns doctor | ✅ | `/api/admin/service-requests/[id]/assign-doctor` |
| B4.3 | Farmer cancels request | ✅ | Mobile cancel route |
| B4.4 | Treatment record linkage | ✅ | Phase 5 treatment workflow migration + APIs |
| B4.5 | Payment capture (automated) | ❌ | Manual reconciliation only; no payment gateway |
| B4.6 | End-to-end smoke OTP→complete | ❌ | Requires staging device run (see INTERNAL_TEST_REPORT) |

### 5. Notifications

| # | Check | Status | Evidence |
|---|-------|--------|----------|
| B5.1 | In-app notification list | ✅ | Flutter inbox + `/api/mobile/notifications` |
| B5.2 | Mark read / unread count | ✅ | API routes present |
| B5.3 | FCM push delivery | ❌ | `google-services.json` not in repo; internal builds use `ENABLE_PUSH=false` |
| B5.4 | Notification deep links | ✅ | `NotificationDeepLink` + unit tests |
| B5.5 | Local notifications (foreground) | ✅ | `LocalNotificationService` |
| B5.6 | SMS for OTP (live) | ❌ | Not verified on production SMS provider |

### 6. Admin operations

| # | Check | Status | Evidence |
|---|-------|--------|----------|
| B6.1 | Admin HTML auth gate | ✅ | `proxy.ts` for `/admin/*` |
| B6.2 | Admin BFF API auth gate | ✅ | `proxy-to-backend.ts` → `requireAdminPanelApiAccess` (Phase 7) |
| B6.3 | Doctor approve/suspend | ✅ | Admin doctor management APIs |
| B6.4 | Service request assignment | ✅ | assign-doctor / assign-technician |
| B6.5 | Feed catalog / inventory admin | ✅ | Feed ecosystem + inventory admin routes |
| B6.6 | Launch ops dashboard | ✅ | `/admin/launch-ops` health probe UI |
| B6.7 | Billing refund processing UI | ⚠️ | Schema supports `REFUNDED`; admin workflow manual |

### 7. Analytics

| # | Check | Status | Evidence |
|---|-------|--------|----------|
| B7.1 | Eight analytics API endpoints | ✅ | Phase 05 report — all pass |
| B7.2 | Seven dashboard pages render | ✅ | `/admin/analytics/*` |
| B7.3 | CSV export + rate limit | ✅ | Export rate limit mounted (Phase 7) |
| B7.4 | Date range validation | ✅ | 366-day max, Zod |
| B7.5 | PDF/Excel export | ❌ | Deferred product scope |
| B7.6 | Materialized snapshot cron | ❌ | Not implemented |

### 8. File uploads

| # | Check | Status | Evidence |
|---|-------|--------|----------|
| B8.1 | Mobile upload API | ✅ | `/api/mobile/upload`, presigned, multipart |
| B8.2 | MIME + magic-byte validation | ✅ | `media.validation.ts`, `mime-sniff.ts` |
| B8.3 | Size limits | ✅ | Config schema + multer limits |
| B8.4 | Upload rate limiting | ✅ | `rateLimitUpload` on media routes |
| B8.5 | MinIO/S3 storage | ⚠️ | Docker compose + config; prod bucket not verified |
| B8.6 | Virus scanning | ❌ | Not implemented |
| B8.7 | Flutter upload service | ✅ | `upload_service.dart` with progress UI |

### 9. Error recovery

| # | Check | Status | Evidence |
|---|-------|--------|----------|
| B9.1 | Central API error handler | ✅ | `error.handler.ts` + mobile mappers |
| B9.2 | Global Flutter error zone | ✅ | `GlobalErrorHandler.runGuarded` |
| B9.3 | Crash webhook reporter | ✅ | `WebhookCrashReporter` (Phase 7) |
| B9.4 | Offline outbox + sync | ✅ | `sync_coordinator.dart`, outbox UI |
| B9.5 | Graceful API degradation (Redis down) | ✅ | Fail-closed 503 on rate limit in prod |
| B9.6 | Incident runbook | ✅ | `incident-response-guide.md` |
| B9.7 | Prod error ingest confirmed | ❌ | Webhook/Sentry not live-tested |

### 10. Database integrity

| # | Check | Status | Evidence |
|---|-------|--------|----------|
| B10.1 | Prisma schema owner | ✅ | `pranidoctor-backend/prisma/SCHEMA_OWNER.md` |
| B10.2 | Migration count | ✅ | 49 applied migration folders |
| B10.3 | Production migrate guard | ✅ | `prisma-production-guard.mjs` on `db:migrate:deploy` |
| B10.4 | Migrate on prod DB clone | ❌ | Not executed in this audit |
| B10.5 | Unique constraints (location) | ✅ | Dedupe migration `20260511133000` |
| B10.6 | Forward-only rollback policy | ✅ | Documented in backup-recovery + rollback plan |
| B10.7 | Seed data for pilot geography | 🔧 | `prisma/seed.ts` — requires ops run on staging |

---

## C. Launch-day sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Engineering lead | | | |
| DevOps | | | |
| Product | | | |
| QA | | | |

**Minimum to sign:** All ❌ items in sections A7–A12 and B4.6 either closed or explicitly waived with written risk acceptance stored outside git.

---

*Related: [PRODUCTION_READINESS_REPORT.md](./PRODUCTION_READINESS_REPORT.md) · [LAUNCH_DAY_RUNBOOK.md](./LAUNCH_DAY_RUNBOOK.md)*
