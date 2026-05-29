# Phase 6 — DevOps & Security Master Plan

**Document version:** 1.0.0  
**Date:** 2026-05-29  
**Status:** Phase 6 implemented — see [phase-6-implementation-report.md](./phase-6-implementation-report.md)  
**Repositories audited:**

| Role | Repository | Local path |
|------|------------|------------|
| Mobile (primary) | [prani_doctor_user](https://github.com/balagpetcare/prani_doctor_user) | `pranidoctor_user` |
| API (target production) | `pranidoctor-backend` | `pranidoctor-backend` |
| Admin / BFF (interim production API) | [pranidoctor-web](https://github.com/balagpetcare/pranidoctor-web) | `pranidoctor-web` |

**Rule:** This document is the single execution blueprint. Do not start Phase 6 implementation until stakeholders sign off on priorities, cutover strategy (Express vs Next proxy), and production hosting choice.

---

## Table of contents

1. [Executive summary](#1-executive-summary)
2. [Current status](#2-current-status)
3. [Gap analysis](#3-gap-analysis)
4. [Target architecture](#4-target-architecture)
5. [Section A — Infrastructure](#5-section-a--infrastructure)
6. [Section B — Security](#6-section-b--security)
7. [Section C — DevOps](#7-section-c--devops)
8. [Section D — Mobile app security](#8-section-d--mobile-app-security)
9. [Section E — Production checklist](#9-section-e--production-checklist)
10. [Files to create](#10-files-to-create)
11. [Files to modify](#11-files-to-modify)
12. [Step-by-step execution order](#12-step-by-step-execution-order)
13. [Risk assessment](#13-risk-assessment)
14. [Final production readiness score](#14-final-production-readiness-score)
15. [Appendix — Key evidence index](#15-appendix--key-evidence-index)

---

## 1. Executive summary

Prani Doctor is a **three-repo system** in transition:

- **Today:** Most production API traffic is served by **Next.js route handlers** in `pranidoctor-web` (BFF proxy + legacy handlers), not the Express container image.
- **Tomorrow:** `pranidoctor-backend` is the intended API owner, but its **production Docker image cannot load ~179 legacy `/api/*` routes** (R-001) because `src/legacy/**` is excluded from the build and not copied into the image.
- **Mobile:** `pranidoctor_user` has **strong client-side auth/storage patterns** (secure storage, interceptors, log redaction, release guards) but **no TLS pinning**, **no wired crash reporting**, **Android-only** (no `ios/` tree), and **CI that can pass without producing a signed release**.

Phase 6 closes the gap between **documented DevOps intent** (VPS, backup, monitoring docs in web repo) and **implemented, tested, automated infrastructure**. Security work must assume **defense in depth** at reverse proxy, API, BFF, and mobile layers.

**Recommended strategic decision (before implementation):**

| Option | Description | Phase 6 impact |
|--------|-------------|----------------|
| **A — Interim (fastest launch)** | Keep Next as API edge; harden VPS + nginx + secrets; backend `dev` on host for parity testing | Smaller Docker scope; focus on web deploy + backend staging |
| **B — Express cutover** | Fix R-001, migrate traffic to backend container, web becomes UI-only | Largest engineering effort; required for true API containerization |
| **C — Hybrid** | Public mobile → backend modules + proxied legacy; admin → web | Two operational surfaces; strict routing matrix |

**Default recommendation for planning:** **Option C** for 90 days, with explicit milestone to **Option B** when legacy compile pipeline ships.

---

## 2. Current status

### 2.1 Repository maturity snapshot

| Area | `pranidoctor_user` | `pranidoctor-backend` | `pranidoctor-web` |
|------|-------------------|----------------------|-------------------|
| Local infra (Docker) | None | Postgres, Redis, MinIO, optional API image | Postgres, MinIO only |
| Production container | N/A | Dockerfile exists; **legacy routes broken in image** | No Dockerfile |
| CI | `release.yml` (analyze, test, optional AAB) | `ci.yml` (narrow validate + 3 tests) | `ci.yml` (typecheck, test, lint, build) |
| CD / deploy automation | None | None | None |
| Auth (mobile) | JWT in secure storage + refresh interceptor | OTP, JWT, refresh rotation, Redis sessions | Proxies to backend |
| Rate limiting | N/A (client) | Redis sliding window; **fail-open without Redis** | None at Next layer |
| Observability | NoOp crash/remote logs | Pino only | Console/webhook monitoring stubs |
| TLS / SSL | Release HTTPS guard on `API_BASE_URL` | Not in repo (edge concern) | Docs only |
| Backups | N/A | Not implemented | **Documented** (`docs/devops/BACKUP_STRATEGY.md`) |
| iOS | **Missing** | N/A | N/A |

### 2.2 Environment strategy (as implemented today)

| Environment | Mobile (`AppEnv`) | Backend | Web |
|-------------|-------------------|---------|-----|
| **dev** | `APP_ENV=dev`, LAN `http://` defaults, `.env` → dart-define via scripts | `NODE_ENV=development`, `REDIS_ENABLED` optional, OTP dev mode | `OTP_MODE=dev`, local compose |
| **staging** | Enum exists; no dedicated CI/staging pipeline | Not formalized in repo | Not formalized |
| **production** | `assertProductionReady()`: requires `API_BASE_URL`, blocks cleartext | Zod rejects `CHANGE_ME`, requires Redis in prod | `validate-production-env.ts` exists; **skipped in CI** |

**Gaps:** No committed `staging.env.example` triad, no secret manager, no environment promotion workflow, no infrastructure-as-code.

### 2.3 Cross-repo conflicts (must resolve in Phase 6.0)

| ID | Conflict | Evidence |
|----|----------|----------|
| **C-01** | Prisma migration authority | `pranidoctor-backend/ARCHITECTURE.md` → backend owns schema; `prisma/migrations/README.md` + `scripts/prisma-production-guard.mjs` → web owns production migrate |
| **C-02** | API production owner | `ARCHITECTURE.md` → traffic on web until cutover; backend Docker assumes API container |
| **C-03** | Dual session models | Redis sessions (`session.storage.ts`) vs Prisma `UserSession` / mobile paths (SEC-03 in stabilization doc) |
| **C-04** | Web livestock routes vs API-consumer mode | `mobile/livestock/*` uses Prisma; `src/lib/prisma.ts` is throwing stub |
| **C-05** | Docs vs code | `docs/devops/*`, `VPS_STRUCTURE.md` describe Prometheus/K8s/web Docker — **not in repo** |

---

## 3. Gap analysis

### 3.1 Summary matrix

| Category | Exists | Partial | Missing |
|----------|--------|---------|---------|
| **A. Infrastructure** | Backend compose, health probes, web VPS docs | Backend Dockerfile | nginx configs, SSL automation, backup scripts, DR runbooks, staging envs, web image |
| **B. Security** | Helmet, CORS, JWT, refresh rotation, Zod, multer+sniff, audit services | Rate limits (presets unused), CSP off | WAF, secret manager, CSRF (cookie panels), API docs auth, dependency scanning |
| **C. DevOps** | CI in all 3 repos, vitest/flutter test | Backend narrow CI | CD, deploy workflows, full test in CI, Sentry/APM, log shipping, rollback automation |
| **D. Mobile security** | Secure storage, interceptors, redaction, ProGuard | Firebase push stub | Cert pinning, Crashlytics, iOS, mandatory signed CI artifacts |
| **E. Production readiness** | Many feature docs | Stabilization reports | Unified go-live gate, exercised backups, on-call |

---

## 4. Target architecture

### 4.1 Production architecture (target)

```
                    ┌─────────────────────────────────────────┐
                    │           Cloudflare / DNS              │
                    │    (WAF, DDoS, optional bot fight)      │
                    └──────────────────┬──────────────────────┘
                                       │ TLS 1.2+
                    ┌──────────────────▼──────────────────────┐
                    │     Reverse proxy (nginx / Caddy)       │
                    │  • TLS termination (Let's Encrypt)      │
                    │  • rate limit (edge)                    │
                    │  • /api → backend OR web proxy          │
                    │  • /admin → Next.js                     │
                    └───────┬────────────────────┬────────────┘
                            │                    │
              ┌─────────────▼─────────┐   ┌──────▼──────────────┐
              │  pranidoctor-backend  │   │  pranidoctor-web   │
              │  Express API :3000    │   │  Next.js :3001     │
              │  (after R-001 fix)    │   │  Admin UI + BFF    │
              └─────────────┬─────────┘   └─────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
   ┌────▼────┐        ┌─────▼─────┐      ┌──────▼──────┐
   │ Postgres│        │   Redis   │      │ S3 / MinIO  │
   │  (TLS)  │        │ sessions  │      │   media     │
   │         │        │ rate limit│      │             │
   └─────────┘        │ audit TTL │      └─────────────┘
                      └───────────┘

   Mobile app (pranidoctor_user) ──HTTPS──► API public URL only
```

### 4.2 Staging architecture (target)

- **Separate VPS or compose project** with distinct secrets, DB name, S3 bucket prefix, and DNS (`staging-api.*`, `staging-admin.*`).
- **Parity:** Same Docker images as production, smaller instance, anonymized or synthetic seed data.
- **Mobile:** `APP_ENV=staging` + `API_BASE_URL` pointing to staging API; internal testing track points here before prod.

### 4.3 Environment variable contract (target)

| Variable class | Storage | Rotation |
|----------------|---------|----------|
| JWT secrets (per panel) | Secret manager / VPS encrypted env | 90-day cadence + emergency revoke |
| DB URL | Secret manager | On credential change |
| S3 keys | IAM or MinIO service account | Quarterly |
| OTP provider keys | Secret manager | On vendor rotation |
| Mobile signing keystore | GitHub encrypted secrets + offline backup | Annual |

---

## 5. Section A — Infrastructure

### 5.1 Current status

| Item | Status | Location |
|------|--------|----------|
| Docker Compose (infra) | **Implemented** | `pranidoctor-backend/docker-compose.yml` |
| API Dockerfile | **Implemented** (blocked by R-001) | `pranidoctor-backend/docker/Dockerfile` |
| Bootstrap scripts | **Implemented** | `pranidoctor-backend/scripts/bootstrap.sh`, `bootstrap.ps1` |
| Health/readiness | **Implemented** | `pranidoctor-backend/src/api/health/*` |
| Web compose (DB+MinIO) | **Implemented** | `pranidoctor-web/docker-compose.yml` |
| VPS / nginx / SSL docs | **Documented only** | `pranidoctor-web/docs/devops/VPS_STRUCTURE.md` |
| Backup docs | **Documented only** | `pranidoctor-web/docs/devops/BACKUP_STRATEGY.md` |
| Mobile Docker | **Missing** | — |

### 5.2 Gap analysis

| Requirement | Gap | Priority |
|-------------|-----|----------|
| Environment strategy | No staging/prod templates per repo; CI uses fake secrets | Critical |
| Production architecture | No IaC; dual API paths unclear | Critical |
| Staging architecture | Not provisioned | High |
| Docker readiness | Backend API image incomplete for legacy routes | **Blocker (R-001)** |
| Reverse proxy design | No committed nginx/Caddy configs | Critical |
| SSL architecture | No certbot/Caddy automation in repo | Critical |
| Backup strategy | Docs only; no `pg_dump`/MinIO sync scripts | Critical |
| Disaster recovery | No RTO/RPO tested restore | Critical |

### 5.3 Implementation plan (infrastructure)

**Phase 6.1 — Decision & inventory (week 1)**  
- Publish `docs/ops/ARCHITECTURE_DECISION_RECORD.md` resolving C-01, C-02 (Prisma owner, API edge).  
- Inventory all public hostnames and which process serves them.

**Phase 6.2 — Reverse proxy & SSL (week 1–2)**  
- Add `deploy/nginx/` or `deploy/caddy/` with templates for prod + staging.  
- Document cert renewal (Let's Encrypt) and HSTS policy.  
- Terminate TLS at proxy; internal HTTP only on loopback/docker network.

**Phase 6.3 — Backup & DR (week 2–3)**  
- Implement scripts from `BACKUP_STRATEGY.md`: PostgreSQL logical backup, MinIO mirror, env snapshot (no secrets in git).  
- Offsite copy (S3/GCS/second VPS).  
- Quarterly restore drill checklist.

**Phase 6.4 — Docker production path (week 3–6, depends on cutover)**  
- **If Option B:** Legacy compile pipeline → `dist/legacy/` or pre-bundle step; update Dockerfile; compose `api` + `worker`.  
- **If Option A:** Web Dockerfile + backend infra-only compose on same VPS.

**Phase 6.5 — Staging environment (week 4)**  
- Provision staging VPS or namespace; seed script; mobile internal track URL.

---

## 6. Section B — Security

### 6.1 Authentication security

| Control | Current | Gap |
|---------|---------|-----|
| Mobile OTP | Backend `mobile-otp-auth.service.ts`, hourly caps | OTP dev mode if misconfigured |
| JWT access | `jose` HS256, channel-specific secrets, 15m mobile TTL | Client does not verify signature (by design) |
| Refresh tokens | Hashed + pepper, rotation, reuse detection | Dual session store (Redis vs Prisma) |
| Panel auth (admin/doctor) | Web cookies + JWT in `src/lib/*-auth/` | No CSRF tokens; SameSite=lax only |
| API route guards (web) | **Proxied** — backend enforces | No Next-layer `api-guard` on admin routes |

### 6.2 JWT security

**Exists:** `src/shared/security/jwt/jwt.service.ts`, `jwt.config.ts`, min 32-char secrets in Zod (`config.schema.ts`).

**Gaps:**
- Ensure all panels use distinct secrets in production (no reuse).
- Document key rotation procedure without mass logout (grace period / dual-key verify).
- Disable or protect `/api/docs` Swagger in production.

### 6.3 Refresh token strategy

**Exists:** `refresh-token.service.ts`, `MOBILE_REFRESH_SECRET`, `REFRESH_TOKEN_PEPPER`, mobile refresh via `refresh_interceptor.dart`.

**Gaps:**
- Align `AUTH_REFRESH` rate preset with refresh endpoints.
- Mobile: verify failed refresh always clears session and routes to login.
- Document max concurrent sessions per device/user.

### 6.4 API protection

| Control | Backend | Web BFF |
|---------|---------|---------|
| Bearer auth middleware | Yes | Proxied |
| RBAC helpers | Yes | N/A |
| Global API rate limit | `whenRateLimitAvailable` — **off if Redis down** | None |
| Body size limit | 10mb global | Proxied |

### 6.5 Rate limiting & brute force

**Exists:** Redis sliding window — OTP, login, API, upload presets (`rate-limit.config.ts`).

**Gaps:**
- Mount unused presets (AI, search, export) on routes.
- **Never fail-open in staging/production** — fail closed or edge limit.
- Wire `.env` `RATE_LIMIT_*` to service or remove dead config.
- Edge nginx `limit_req` for `/api/auth/*`, `/api/mobile/auth/*`.

### 6.6 CSRF review

| Surface | Risk | Recommendation |
|---------|------|----------------|
| Mobile API (Bearer) | Low | No CSRF needed |
| Admin/doctor cookie sessions | Medium | Add CSRF token for state-changing cookie routes OR SameSite=strict + double-submit |
| Next Server Actions (if used for mutations) | Review per route | Follow Next 16 guidance |

### 6.7 XSS review

| Layer | Status |
|-------|--------|
| Backend | Helmet with **CSP disabled** |
| Web admin | `sanitize-admin-html.ts` for HTML fields |
| Mobile | Flutter escapes by default; WebView usage — audit if any |

**Action:** Enable CSP for admin/enterprise (and doctor) in `next.config.ts` with nonce strategy.

### 6.8 SQL injection review

**Finding:** No `$queryRawUnsafe` in backend `src/`. Parameterized `$queryRaw` in analytics and health routes.

**Risks:** ORM-only is good; maintain ban on unsafe raw in lint rule; audit `Prisma.join` IN clauses when extended.

### 6.9 File upload security

**Exists:** Multer limits, MIME allowlist, magic-byte sniff (`media.validation.ts`, `mime-sniff.ts`), presigned upload routes in legacy.

**Gaps:**
- Virus scanning (ClamAV or cloud AV) — not present.
- Presigned URL expiry caps at edge.
- Mobile `UPLOAD_URL` not in `assertProductionReady()`.

### 6.10 Secrets management

**Current:** `.env` files gitignored; `.env.example` with placeholders; GitHub Actions secrets for mobile keystore.

**Target:** VPS `/etc/pranidoctor/*.env` with `0400` perms OR Doppler/Vault/AWS SM; never commit production values; pre-deploy `validate:production-env`.

### 6.11 Encryption requirements

| Data | At rest | In transit |
|------|---------|------------|
| Postgres | Enable provider encryption / disk encryption | `sslmode=require` in `DATABASE_URL` |
| Redis | AUTH password; private network | TLS optional (Redis 6+) |
| MinIO/S3 | SSE-S3 or SSE-KMS | HTTPS only |
| Mobile tokens | Android EncryptedSharedPreferences / iOS Keychain | HTTPS (+ optional pinning) |
| Backups | GPG or provider encryption | TLS to offsite |

### 6.12 Audit logging

**Exists:** `audit.service.ts` (Redis 90d), `auth-audit.service.ts` (Prisma `AuthAuditEvent`), Pino redaction.

**Gaps:** Ship audit logs to immutable store; admin actions on sensitive data (export, role change) — verify coverage; correlation ID end-to-end (web proxy already forwards).

---

## 7. Section C — DevOps

### 7.1 CI/CD design (target)

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌──────────────┐
│   PR open   │────►│  CI (lint,   │────►│   Staging   │────►│  Production  │
│             │     │  test, build)│     │   deploy    │     │   deploy     │
└─────────────┘     └──────────────┘     └─────────────┘     └──────────────┘
                           │                      │                    │
                           ▼                      ▼                    ▼
                    Block merge on fail    Smoke tests +        Manual approval
                    Security scan          migrate deploy       + rollback tag
```

### 7.2 Current CI/CD

| Repo | Workflow | Runs |
|------|----------|------|
| `pranidoctor_user` | `.github/workflows/release.yml` | `flutter analyze`, `flutter test`, optional AAB |
| `pranidoctor-backend` | `.github/workflows/ci.yml` | `ci:validate` (×2 duplicate), 3 vitest files |
| `pranidoctor-web` | `.github/workflows/ci.yml` | typecheck, full test, lint:release, build |

**Missing everywhere:** deploy workflow, migration smoke job, security scan, artifact registry, rollback automation.

### 7.3 Automated testing pipeline (target)

| Stage | Backend | Web | Mobile |
|-------|---------|-----|--------|
| Unit | `npm test` (all) | `npm test` | `flutter test` |
| Integration | Ephemeral Postgres + Redis in CI | Proxy contract tests | — |
| E2E | `e2e:freeze` gated | Playwright admin smoke (optional) | Patrol/integration_test (optional) |
| Coverage gate | 60% → 80% phased | Same | Critical paths only |

### 7.4 Build pipeline

- **Backend:** `npm run build` → Docker image tag `ghcr.io/.../api:${sha}`.
- **Web:** `npm run build` → Docker or Node standalone output.
- **Mobile:** `scripts/build_release.ps1` with obfuscation; CI **must fail** if keystore missing on `main` tag.

### 7.5 Deployment pipeline

- SSH or GitHub Actions deploy to VPS (documented in new `deploy/README.md`).
- Steps: pull image → `prisma migrate deploy` (single owner) → health check → traffic switch.
- Blue/green optional at nginx upstream level.

### 7.6 Rollback strategy

| Component | Rollback |
|-----------|----------|
| API container | Redeploy previous image tag (`:previous`) |
| DB | Forward-only migrations; restore from backup if bad migration |
| Mobile | Force upgrade via `MINIMUM_APP_VERSION`; cannot rollback installed APKs |
| Web | Previous Next build artifact |

### 7.7 Monitoring stack (target)

| Layer | Tool (recommended) |
|-------|-------------------|
| Uptime | Uptime Kuma / Better Stack |
| APM | Sentry (API + web + mobile) |
| Metrics | Prometheus + node_exporter (optional Phase 6.2) |
| Logs | Loki or cloud log drain from Pino JSON |
| Alerts | PagerDuty/Slack webhook on 5xx rate, disk, backup failure |

### 7.8 Logging stack

**Current:** Pino (backend), structured modules (web), `AppLogger` + redactor (mobile).

**Target:** JSON to stdout → vector agent → central store; request ID in all repos (already partial in web proxy).

### 7.9 Error tracking

**Current:** `NoOpCrashReporter` default in mobile; web `error-tracking.ts` supports webhook/console only.

**Target:** Sentry DSN per environment; source maps upload for web and Flutter split-debug-info.

---

## 8. Section D — Mobile app security

### 8.1 Current status

| Control | Status | Path |
|---------|--------|------|
| Secure storage | **Strong** | `lib/core/storage/token_storage.dart`, `session_controller.dart` |
| API keys in binary | **None** (good) | compile-time URLs only |
| Certificate pinning | **Missing** | — |
| Network security | **Strong** (no pinning) | `lib/core/network/dio_provider.dart`, interceptors |
| Device security | **Not implemented** | no root/jailbreak detection |
| Release signing | **Android partial** | `android/app/build.gradle.kts`, `release.yml` |
| iOS | **Missing** | no `ios/` directory |

### 8.2 Gap analysis & plan

| Item | Action |
|------|--------|
| Secure storage | Add optional biometric gate for high-risk farms (P2) |
| API key protection | Keep secrets server-side; document no API keys in app |
| Certificate pinning | Evaluate `ssl_pinning` or Dio adapter; pin leaf + backup; rotation runbook |
| Network security | Extend `assertProductionReady()` to `UPLOAD_URL`; remove debug cleartext from release builds |
| Device security | Optional `flutter_jailbreak_detection` for high-threat deployments |
| Release signing | Fail CI on missing keystore for version tags; Play App Signing doc in `docs/STORE_RELEASE.md` |
| Crash reporting | Wire `FirebaseCrashlyticsReporter` or Sentry in `bootstrap.dart` |
| ProGuard | Review rules for reflective JSON models |

---

## 9. Section E — Production checklist

### 9.1 Critical issues (P0 — block launch)

| ID | Issue | Repo | Mitigation |
|----|-------|------|------------|
| P0-01 | API production path undefined (web proxy vs Express container) | All | ADR + routing diagram |
| P0-02 | R-001 legacy routes broken in backend Docker | Backend | Legacy compile or defer cutover |
| P0-03 | Prisma migration authority conflict (C-01) | Backend/Web | Single `migrate deploy` owner |
| P0-04 | No automated backups + untested restore | Ops | Implement backup scripts + drill |
| P0-05 | No production TLS/nginx in repo | Ops | `deploy/` configs + provision |
| P0-06 | Rate limiting fail-open without Redis | Backend | Require Redis in prod; fail closed |
| P0-07 | Production secrets in `.env.example` patterns | All | Secret manager + validation at deploy |
| P0-08 | `OTP_MODE=dev` risk if copied to prod | Backend/Web | Deploy guard + `warnIfProdDevOtpMode` enforcement |

### 9.2 High priority (P1 — launch with risk acceptance)

| ID | Issue |
|----|-------|
| P1-01 | Backend CI runs ~3 tests only |
| P1-02 | Public `/api/docs` without auth |
| P1-03 | No Sentry/crash reporting on mobile |
| P1-04 | Web admin APIs without Next-layer defense |
| P1-05 | `mobile/livestock/*` broken vs API-consumer stub (C-04) |
| P1-06 | No CD pipeline |
| P1-07 | CSP disabled (backend + incomplete on web) |
| P1-08 | CI can skip signed mobile release (`exit 0` without keystore) |
| P1-09 | Dual session store complexity |
| P1-10 | Worker/BullMQ not in compose — background jobs may not run |

### 9.3 Medium priority (P2)

| ID | Issue |
|----|-------|
| P2-01 | No certificate pinning (mobile) |
| P2-02 | `UPLOAD_URL` not production-guarded |
| P2-03 | No dependency/CodeQL scanning |
| P2-04 | Unused rate limit presets |
| P2-05 | No virus scan on uploads |
| P2-06 | Staging environment not provisioned |
| P2-07 | Web CI skips `validate:production-env` |
| P2-08 | Helmet CSP off on API |
| P2-09 | No iOS app |
| P2-10 | Docs drift (`ADMIN_PRODUCTION.md`, CICD_PIPELINE.md) |

### 9.4 Low priority (P3)

| ID | Issue |
|----|-------|
| P3-01 | No root/jailbreak detection |
| P3-02 | No biometric gate on secure storage |
| P3-03 | Prometheus metrics (docs only) |
| P3-04 | Pre-commit hooks (husky) |
| P3-05 | Fastlane not configured |
| P3-06 | Flexible HTTP legacy (`flexible_http.dart`) |

---

## 10. Files to create

Paths are relative to each repository unless noted.

### 10.1 `pranidoctor_user` (mobile)

| Path | Purpose |
|------|---------|
| `docs/phase-6-devops-security-master-plan.md` | This document |
| `docs/ops/MOBILE_RELEASE_SECURITY.md` | Signing, pinning, crash reporting runbook |
| `.github/workflows/ci.yml` | PR checks (analyze + test on all PRs) |
| `.github/workflows/security.yml` | Dependabot/CodeQL (optional org-level) |
| `lib/core/network/certificate_pinning.dart` | Pinning adapter (when approved) |
| `lib/core/logging/sentry_crash_reporter.dart` | Real crash reporter impl |
| `integration_test/smoke_login_test.dart` | Optional release gate |
| `ios/` | Full iOS project (if iOS launch in scope) |

### 10.2 `pranidoctor-backend`

| Path | Purpose |
|------|---------|
| `deploy/nginx/pranidoctor-api.conf` | Reverse proxy template |
| `deploy/caddy/Caddyfile` | Alternative TLS automation |
| `deploy/docker-compose.prod.yml` | Production stack overlay |
| `scripts/backup/postgres-backup.sh` | Scheduled DB backup |
| `scripts/backup/minio-sync.sh` | Media backup |
| `scripts/backup/restore-drill.sh` | Restore validation |
| `.env.staging.example` | Staging template |
| `.env.production.example` | Production template (no secrets) |
| `.github/workflows/ci-full.yml` | Full test + build + lint |
| `.github/workflows/deploy-staging.yml` | Staging CD (manual approval) |
| `.github/workflows/deploy-production.yml` | Production CD |
| `.github/workflows/security.yml` | npm audit, CodeQL |
| `docs/ops/RUNBOOK.md` | Incident + rollback |
| `docs/ops/LEGACY_DOCKER_CUTOVER.md` | R-001 resolution steps |
| `scripts/compile-legacy-routes.mjs` | If Option B — bundle legacy to dist |

### 10.3 `pranidoctor-web`

| Path | Purpose |
|------|---------|
| `Dockerfile` | Production Next image |
| `deploy/nginx/pranidoctor-admin.conf` | Admin vhost |
| `deploy/docker-compose.prod.yml` | Web + proxy overlay |
| `.github/workflows/deploy-staging.yml` | Staging deploy |
| `.github/workflows/deploy-production.yml` | Production deploy |
| `docs/ops/DEPLOYMENT_RUNBOOK.md` | Single source for go-live |
| `src/middleware.ts` or extend `src/proxy.ts` | CSP + security headers for `/doctor` |
| `scripts/backup/` | Executable backup scripts (implement docs) |

### 10.4 Shared / ops (choose one home: `pranidoctor-web/docs/ops/` recommended)

| Path | Purpose |
|------|---------|
| `docs/ops/ARCHITECTURE_DECISION_RECORD.md` | C-01, C-02, cutover |
| `docs/ops/SECRETS_ROTATION.md` | JWT, DB, OTP rotation |
| `docs/ops/MONITORING_ALERTS.md` | Alert thresholds |
| `docs/ops/PRODUCTION_GO_LIVE_CHECKLIST.md` | Executable checklist derived from Section E |

---

## 11. Files to modify

### 11.1 `pranidoctor_user`

| Path | Change |
|------|--------|
| `lib/app/app_env.dart` | Validate `UPLOAD_URL` HTTPS in production |
| `lib/app/bootstrap.dart` | Wire crash reporter from env |
| `lib/core/logging/crash_reporter.dart` | Sentry/Firebase implementation |
| `lib/features/shared/upload/services/upload_service.dart` | Use `AppEnv` for upload base URL |
| `.github/workflows/release.yml` | Fail on missing keystore for tags; upload symbols to Sentry |
| `android/app/build.gradle.kts` | Fail release build if release signing missing (optional strict flag) |
| `docs/PRODUCTION_READINESS.md` | Link to Phase 6 plan |
| `docs/STORE_RELEASE.md` | Pinning + crash reporting steps |
| `pubspec.yaml` | Add `sentry_flutter` or enable `firebase_crashlytics` |

### 11.2 `pranidoctor-backend`

| Path | Change |
|------|--------|
| `docker/Dockerfile` | Copy legacy bundle when R-001 fixed |
| `tsconfig.build.json` | Include legacy compile output path |
| `docker-compose.yml` | Add `worker` service; prod secrets via env file |
| `.github/workflows/ci.yml` | Remove duplicate step; add build, lint, full test, `db:generate` |
| `src/app.ts` | Enable CSP for production; protect `/api/docs` |
| `src/shared/security/rate-limit/safe-rate-limit.ts` | Fail closed in production |
| `src/shared/config/config.loader.ts` | Wire or remove unused `RATE_LIMIT_*` |
| `package.json` | Wire `prisma-production-guard` into `db:migrate:deploy` |
| `prisma/migrations/README.md` | Align with `ARCHITECTURE.md` (single owner) |
| `ARCHITECTURE.md` | Update cutover status post-Phase 6 |
| `.env.example` | Remove weak defaults; document `sslmode` |

### 11.3 `pranidoctor-web`

| Path | Change |
|------|--------|
| `next.config.ts` | CSP, security headers for `/doctor` |
| `.github/workflows/ci.yml` | Run `validate:production-env` on release branches |
| `src/proxy.ts` | Optional admin session hardening |
| `src/lib/proxy-to-backend.ts` | Document required backend headers |
| `src/app/api/mobile/livestock/**` | Proxy only or fix imports (C-04) |
| `docs/devops/CICD_PIPELINE.md` | Align with actual workflows |
| `docs/ADMIN_PRODUCTION.md` | Update middleware → proxy references |
| `src/instrumentation.ts` | Sentry init when DSN present |
| `package.json` | Add `@sentry/nextjs` if adopted |

---

## 12. Step-by-step execution order

**Do not skip Phase 6.0 — it blocks all deployment work.**

### Phase 6.0 — Governance (Week 1)

1. Review this document with tech lead + ops.
2. Create `docs/ops/ARCHITECTURE_DECISION_RECORD.md` — resolve C-01, C-02, cutover option (A/B/C).
3. Freeze production hostnames and ports (3000 API, 3001 admin per mobile `AppEnv` comments).
4. Assign single Prisma migration owner; update both `ARCHITECTURE.md` and `prisma/migrations/README.md`.

### Phase 6.1 — Secrets & environments (Week 1–2)

5. Create `.env.staging.example` / `.env.production.example` in backend + web.
6. Provision secret store or encrypted VPS env files.
7. Enable `validate:production-env` in web CI for `main` and release branches.
8. Backend: enforce Redis + OTP live mode in production startup (fail boot if not).

### Phase 6.2 — CI hardening (Week 2)

9. Backend: expand `ci.yml` — `npm run build`, `lint`, full `npm test`, remove duplicate `ci:validate`.
10. Web: add contract test job (proxy headers to mock backend).
11. Mobile: add `ci.yml` for PRs; make `release.yml` fail without keystore on `v*` tags.
12. Add `security.yml` (npm audit, CodeQL) to backend + web.

### Phase 6.3 — Infrastructure (Week 2–4)

13. Implement `deploy/nginx` or Caddy configs (staging first).
14. Provision staging VPS; TLS certificates.
15. Implement backup scripts + cron; first restore drill.
16. Document DR RTO/RPO in `docs/ops/RUNBOOK.md`.

### Phase 6.4 — API container / cutover (Week 3–8, parallel)

17. **If Option B:** Implement legacy compile pipeline; fix Dockerfile (R-001).
18. Add `worker` to compose; register BullMQ processors for audit/notifications.
19. Staging deploy backend image; run mobile smoke against staging `API_BASE_URL`.
20. Rate limit: fail closed; mount presets on auth/upload/AI routes.
21. Protect or disable `/api/docs` in production.

### Phase 6.5 — Web production image (Week 4–5)

22. Add `Dockerfile` for Next standalone.
23. Fix C-04 livestock routes (proxy-only).
24. CSP + doctor panel headers in `next.config.ts`.
25. Optional: thin `api-guard` on `/api/admin/*` for defense in depth.

### Phase 6.6 — Mobile security (Week 4–6)

26. Wire Sentry or Crashlytics in `bootstrap.dart`.
27. Extend `assertProductionReady()` for upload URL and push/Firebase consistency.
28. Decide on certificate pinning (threat model); implement if yes.
29. Play internal testing track → staging → production promotion process.

### Phase 6.7 — CD & monitoring (Week 5–8)

30. `deploy-staging.yml` — auto on `main` merge (optional).
31. `deploy-production.yml` — manual approval; health gate.
32. Sentry projects for API, web, mobile; alert rules.
33. Uptime checks on `/health`, `/api/admin/health/ready`.
34. Log shipping agent on VPS.

### Phase 6.8 — Production gate (Week 8)

35. Execute `PRODUCTION_GO_LIVE_CHECKLIST.md` — all P0 cleared.
36. Load test auth + critical mobile paths on staging.
37. Sign off production readiness score ≥ 85/100.

---

## 13. Risk assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Deploy backend container without legacy routes | High | Critical outage | R-001 fix or keep web as API edge |
| Wrong repo runs `prisma migrate deploy` | Medium | Critical data | Single owner + CI guard script |
| Redis down in prod → no rate limits | Medium | High | Fail closed; monitoring on Redis |
| Secrets leaked via `.env` commit | Low | Critical | gitleaks in CI; secret scanning |
| Mobile debug-signed “release” APK | Medium | Medium | CI fail without keystore on tags |
| Backup never tested | High | Critical | Quarterly restore drill |
| MITM without cert pinning | Low–Med | High | HTTPS + optional pinning |
| Swagger exposes attack surface | Medium | Medium | Auth gate or disable in prod |
| Session fixation / token reuse | Low | High | Existing refresh rotation — add integration tests |
| Doc-driven ops without scripts | High | High | Phase 6.3 implements scripts from web docs |

---

## 14. Final production readiness score

Scoring model: weighted categories (0–100 each), then weighted total.

| Category | Weight | Score | Rationale |
|----------|--------|-------|-----------|
| Infrastructure | 20% | **35** | Compose + health exist; no prod proxy/SSL/backups in code |
| API security | 25% | **62** | Strong JWT/refresh/validation; fail-open limits, public docs, R-001 |
| DevOps / CI/CD | 20% | **45** | CI exists; no CD, narrow backend CI, no security scans |
| Web / BFF security | 15% | **50** | Panel auth OK; proxy-only API, no CSP, livestock bug |
| Mobile security | 20% | **58** | Storage/interceptors strong; no pinning/crash/iOS |

### Weighted total: **52 / 100** — Not production-ready for full self-hosted launch

**Target after Phase 6 completion:** **≥ 85/100**

| Milestone | Expected score |
|-----------|----------------|
| Phase 6.0–6.2 complete (ADR, secrets, CI) | 65 |
| Phase 6.3–6.4 complete (infra, backups, API path) | 78 |
| Phase 6.5–6.8 complete (CD, monitoring, mobile crashes) | 85+ |

**Launch allowed with written risk acceptance if:**

- Option A (web as API edge) is chosen **and** P0-04, P0-05, P0-06, P0-07, P0-08 are closed.
- R-001 deferred explicitly with web handling all mobile routes.

---

## 15. Appendix — Key evidence index

### Mobile

- Production guards: `lib/app/app_env.dart` (`assertProductionReady`)
- Token storage: `lib/core/storage/token_storage.dart`
- Network stack: `lib/core/network/dio_provider.dart`
- CI: `.github/workflows/release.yml`
- Stabilization audit: `docs/stabilization/flutter_production_readiness_report.md`

### Backend

- Docker gap: `docker/README.md` (R-001)
- CI: `.github/workflows/ci.yml`
- Security stack: `src/app.ts`, `src/shared/security/**`
- Stabilization: `docs/backend-stabilization-phase-1.md`
- Architecture: `ARCHITECTURE.md`

### Web

- CI: `.github/workflows/ci.yml`
- Proxy: `src/proxy.ts`, `src/lib/proxy-to-backend.ts`
- DevOps docs: `docs/devops/VPS_STRUCTURE.md`, `BACKUP_STRATEGY.md`, `CICD_PIPELINE.md`
- Production env: `scripts/validate-production-env.ts`

---

## Document control

| Version | Date | Author | Notes |
|---------|------|--------|-------|
| 1.0.0 | 2026-05-29 | Phase 6 audit | Initial master plan — implementation not started |

**Next step:** Stakeholder review of Section 12 Phase 6.0 (governance) and cutover option A/B/C. No code changes until approved.
