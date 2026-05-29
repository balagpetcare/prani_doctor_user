# Phase 6 — Final Validation Audit

**Audit date:** 2026-05-29  
**Auditor scope:** `pranidoctor_user`, `pranidoctor-backend`, `pranidoctor-web`  
**Reference:** [phase-6-devops-security-master-plan.md](./phase-6-devops-security-master-plan.md), [phase-6-implementation-report.md](./phase-6-implementation-report.md)

---

## Executive summary

Phase 6 delivered **meaningful security and DevOps foundations** (middleware hardening, env triads, Docker improvements, CI expansion, backup scripts, operational docs). However, **production operations are not fully exercised**: deploy workflows are placeholders, backups are not scheduled or drill-tested, TLS/nginx is documentation-only, and mobile crash telemetry is not wired.

**Final verdict:** See [Section F](#f-final-verdict) — **NOT READY FOR PRODUCTION** (full public launch).

---

## Scores at a glance

| Category | Score (0–100) | Grade |
|----------|---------------|-------|
| **A. Security** | **74** | C+ |
| **B. DevOps** | **64** | D+ |
| **C. Mobile security** | **76** | C+ |
| **D. Infrastructure** | **58** | F/D |
| **E. Production readiness** | **67%** | Not ready |

---

## 1. Security validation

### 1.1 Authentication — **PASS (with caveats)** — 82/100

| Control | Status | Evidence |
|---------|--------|----------|
| Mobile OTP | Implemented | `mobile-otp-auth.service.ts`, hourly send caps |
| Panel login (admin/doctor/tech) | Implemented | `panel-*-auth.service.ts`, legacy compat routes |
| Session binding | Implemented | JWT `sid` + Redis `getSession()` in `auth.middleware.ts` |
| OTP dev mode guard | Partial | `warnIfProdDevOtpMode()` in `otp-env.ts`; defaults to **dev** if `OTP_MODE` unset |
| MFA hook | Present | `requireMfa` option in auth middleware (usage varies by route) |

**Gaps:** OTP defaults to dev without explicit `OTP_MODE=live`. Debug OTP panel can remain enabled via env if misconfigured.

### 1.2 Authorization — **PARTIAL** — 68/100

| Layer | Status | Evidence |
|-------|--------|----------|
| Backend RBAC | Implemented | `rbac.service.ts`, `hasPermission`, role middleware |
| Foundation modules | Mixed | Some routes use auth middleware; stub modules documented |
| Web BFF | Weak | ~265 routes use `proxyRouteToBackend`; `requireAdminPanelApiAccess` **not used** in `src/app/api/admin/**` |
| Web panel HTML | Implemented | `src/proxy.ts` cookie gate for `/admin`, `/doctor`, `/enterprise` |

**Risk:** Unauthenticated clients can hit Next `/api/*` URLs; enforcement depends entirely on backend + network perimeter.

### 1.3 JWT — **PASS** — 80/100

| Control | Status | Evidence |
|---------|--------|----------|
| Channel-specific secrets | Yes | `jwt.config.ts`, `config.schema.ts` |
| Min length / no CHANGE_ME in prod | Yes | Zod `jwtSecretSchema` + production refine |
| Access TTL | Yes | Mobile 15m (config) |
| Client-side checks (mobile) | Advisory only | `jwt_utils.dart` — no signature verify (expected) |

**Gaps:** No documented key rotation runbook executed in code. Dual signing paths (legacy web lib + foundation modules).

### 1.4 Rate limiting — **PARTIAL** — 72/100

| Control | Status | Evidence |
|---------|--------|----------|
| Redis sliding window | Yes | `rate-limit.service.ts` |
| Global API limit | Yes | `whenRateLimitAvailable(rateLimitApi)` in `app.ts` |
| Auth/upload limits | Yes | `auth.routes.ts`, `media.routes.ts`, compat auth paths |
| Fail-closed staging/prod | **Yes (Phase 6)** | `safe-rate-limit.ts` returns 503 if Redis down |
| AI/search/export presets | **Not mounted** | Exported in `rate-limit.service.ts`, no route usage found |
| Web layer | **None** | No Next middleware rate limiter |

### 1.5 Upload security — **PASS** — 78/100

| Control | Status | Evidence |
|---------|--------|----------|
| Size limits | Yes | `config.schema.ts` storage max bytes |
| MIME allowlist | Yes | `media.upload.middleware.ts` |
| Magic-byte sniff | Yes | `media.validation.ts`, `mime-sniff.ts` |
| Dangerous ext/MIME block | Yes | `isDangerousExtension`, `isDangerousMime` |
| Rate limit on upload routes | Yes | `rateLimitUpload` on `media.routes.ts` |
| Virus scanning | **Missing** | No ClamAV/cloud AV |
| Presigned URL abuse caps | Partial | Legacy presigned routes — review expiry at edge |

### 1.6 Input validation — **PASS** — 76/100

| Control | Status | Evidence |
|---------|--------|----------|
| Zod body/query/params | Yes | `validate.middleware.ts` |
| Light sanitization | **Yes (Phase 6)** | `sanitize-input.middleware.ts` |
| SQL injection | Low risk | No `$queryRawUnsafe` in `src/`; Prisma parameterized raw |
| Legacy routes | Variable | Inline parsing still possible in `src/legacy/**` |

### 1.7 Secret management — **FAIL (operational)** — 52/100

| Control | Status | Evidence |
|---------|--------|----------|
| `.env` gitignored | Yes | `.gitignore` all repos |
| Env example triads | **Yes (Phase 6)** | `.env.{development,staging,production}.example` |
| Hardcoded secrets removed from examples | Partial | Backend `.env.example` still documents structure; placeholders used |
| Secret manager (Vault/SM) | **Missing** | Env-file only |
| `prisma-production-guard.mjs` | **Not wired** | Script exists; not in `package.json` migrate scripts |
| CI secrets | Partial | Mobile keystore via GitHub secrets; optional skip on non-tags |

### 1.8 Phase 6 security additions — verified

| Item | Verified |
|------|----------|
| Helmet + CSP/HSTS (staging/prod) | `helmet.config.ts`, `security-stack.ts` |
| Strict CORS | `app.ts` origin validator |
| Secure headers | `secure-headers.middleware.ts` |
| Docs auth / hide in prod | `docs-auth.middleware.ts`, `server.ts` |
| Metrics auth | `metrics.routes.ts` + `METRICS_TOKEN` |
| Error webhook hook | `error-tracking.ts`, `error.handler.ts` |

---

### A. Security Score

**Weighted calculation:**

| Sub-area | Weight | Score |
|----------|--------|-------|
| Authentication | 20% | 82 |
| Authorization | 20% | 68 |
| JWT | 15% | 80 |
| Rate limiting | 15% | 72 |
| Upload security | 10% | 78 |
| Input validation | 10% | 76 |
| Secret management | 10% | 52 |

**A. Security Score = 74 / 100**

---

## 2. Infrastructure validation

### 2.1 Docker — **PARTIAL** — 68/100

| Item | Status | Notes |
|------|--------|-------|
| Backend compose (PG, Redis, MinIO) | Yes | `docker-compose.yml` |
| Backend prod overlay | Yes | `docker-compose.prod.yml` |
| Backend Dockerfile | Yes | Multi-stage; **legacy via `tsx` runtime** |
| Web Dockerfile | Yes | Standalone Next output |
| Web prod compose | Yes | External network to backend |
| Mobile Docker | No | N/A for Flutter |
| R-001 legacy in container | Mitigated | `src/legacy` copied + `node --import tsx` — not ideal long-term |

**Risk:** Production container depends on `tsx` interpreting legacy TypeScript at runtime; performance and supply-chain surface larger than compiled bundle.

### 2.2 Environment variables — **PASS** — 75/100

| Repo | dev / staging / prod examples | Production validation |
|------|------------------------------|------------------------|
| Backend | Yes | Zod `loadConfig()` + `env:validate` script |
| Web | Yes | `validate:production-env.ts`; CI on main |
| Mobile | Yes | `assertProductionReady()` HTTPS + URL required |

**Gap:** No runtime secret store; staging/prod `.env` not committed (correct) but not provisioned in audit environment.

### 2.3 CI/CD — **PARTIAL** — 63/100

| Repo | Lint | Test | Build | Security scan | Deploy |
|------|------|------|-------|---------------|--------|
| Backend | Yes | Yes (`npm test`) | Yes | `npm audit` (continue-on-error) | **Template only** |
| Web | Yes | Yes | Yes | Weekly audit workflow | **Template only** |
| Mobile | `flutter analyze` | `flutter test` | Release workflow | None | **Template only** |

**Gaps:**
- Deploy workflows echo instructions only (`deploy-production.yml`).
- Backend `npm run typecheck` reports **pre-existing errors** in legacy/modules (not gated in CI as separate job).
- No CodeQL / gitleaks.
- No integration test job with ephemeral Postgres.

### 2.4 Backup strategy — **FAIL (operational)** — 45/100

| Item | Status |
|------|--------|
| Backup scripts | Yes — `scripts/backup/postgres-backup.sh`, `postgres-restore.sh` |
| Documentation | Yes — `docs/backup-recovery.md` |
| Scheduled cron on VPS | **Not configured** |
| Restore drill executed | **Not evidenced** |
| MinIO offsite mirror | **Documented only** |

### 2.5 Monitoring — **PARTIAL** — 62/100

| Item | Status |
|------|--------|
| Health `/health`, `/ready`, `/live` | Yes |
| Granular `/health/db`, `/health/redis`, etc. | Yes |
| Metrics `/metrics` | Yes (Phase 6) |
| Structured logging (Pino) | Yes |
| APM (Sentry/Datadog) | **Not integrated** — webhook hook only |
| Central log shipping | **Not configured** |
| Uptime alerting | **Not configured** |

### 2.6 TLS / reverse proxy — **FAIL** — 30/100

| Item | Status |
|------|--------|
| nginx example | Yes — `deploy/nginx/pranidoctor.conf.example` |
| Automated cert provisioning | **No** |
| Production VPS provisioned | **Out of repo scope — not verified** |

---

### D. Infrastructure Score

| Sub-area | Weight | Score |
|----------|--------|-------|
| Docker | 25% | 68 |
| Environment variables | 20% | 75 |
| CI/CD | 25% | 63 |
| Backup strategy | 15% | 45 |
| Monitoring + TLS | 15% | 46 |

**D. Infrastructure Score = 58 / 100**

---

## 3. Flutter validation

### 3.1 Secure storage — **PASS** — 88/100

| Control | Status | Evidence |
|---------|--------|----------|
| Token storage | Yes | `token_storage.dart`, keys namespaced |
| FlutterSecureStorage | Yes | Android `encryptedSharedPreferences`, iOS Keychain options |
| In-memory access token cache | Present | Performance trade-off documented |
| Hive for secrets | No JWT in Hive | Locale/cache only |

### 3.2 API protection — **PARTIAL** — 70/100

| Control | Status | Evidence |
|---------|--------|----------|
| Bearer injection | Yes | `auth_interceptor.dart` |
| Refresh on 401 | Yes | `refresh_interceptor.dart`, `session_manager.dart` |
| Connectivity fast-fail | Yes | `connectivity_interceptor.dart` |
| Log redaction | Yes | `log_redactor.dart`, `LoggingInterceptor` |
| HTTPS release guard | Yes | `assertProductionReady()` + staging |
| Upload URL HTTPS | Yes (Phase 6) | `uploadBaseUrl` on `AppEnv` |
| Certificate pinning | **No** | Standard Dio trust store |
| Root/jailbreak detection | **No** | — |

### 3.3 Release readiness — **PARTIAL** — 62/100

| Item | Status |
|------|--------|
| Android signing | Configured (`build.gradle.kts`, `release.yml`) |
| ProGuard / obfuscation | Yes in release script + CI |
| iOS project | **Missing** — no `ios/` directory |
| Crash reporting | **NoOp** default — `crash_reporter.dart` stub |
| CI on PR | Yes — `ci.yml` |
| Release AAB on tag | Requires secrets; **fails on tag** if missing (good) |
| Play internal track process | Documented in `STORE_RELEASE.md` — not verified live |

---

### C. Mobile Security Score

| Sub-area | Weight | Score |
|----------|--------|-------|
| Secure storage | 30% | 88 |
| API protection | 35% | 70 |
| Release readiness | 35% | 62 |

**C. Mobile Security Score = 76 / 100**

---

## 4. DevOps validation

### B. DevOps Score

Consolidates CI/CD, env discipline, documentation, and operational automation.

| Sub-area | Weight | Score |
|----------|--------|-------|
| CI quality & coverage | 30% | 62 |
| CD / deploy automation | 25% | 35 |
| Security scanning in pipeline | 15% | 50 |
| Env / config discipline | 20% | 78 |
| Runbooks & docs | 10% | 88 |

**B. DevOps Score = 64 / 100**

---

## 5. Production readiness

### E. Production Readiness Percentage

Uses the Phase 6 weighting model:

| Category | Weight | Score | Weighted |
|----------|--------|-------|----------|
| Infrastructure (D) | 20% | 58 | 11.6 |
| API / platform security (A) | 25% | 74 | 18.5 |
| DevOps (B) | 20% | 64 | 12.8 |
| Web BFF security | 15% | 68* | 10.2 |
| Mobile (C) | 20% | 76 | 15.2 |

\*Web BFF derived from authorization gap + CSP/headers (Phase 6) + proxy fix for livestock.

**E. Production Readiness = 68%** (rounded from 68.3%)

### P0 blockers (must clear before production)

| ID | Blocker | Status |
|----|---------|--------|
| P0-1 | Production TLS + reverse proxy live | **Open** |
| P0-2 | Backups scheduled + restore drill | **Open** |
| P0-3 | `OTP_MODE=live` + secrets on prod hosts | **Open** (process) |
| P0-4 | Deploy pipeline or documented manual cutover with rollback | **Open** |
| P0-5 | Crash/error telemetry (mobile + API) | **Open** |
| P0-6 | Redis required and monitored in production | **Partial** (code enforces; ops unverified) |
| P0-7 | API production routing decision executed | **Open** — `ARCHITECTURE.md` still interim web BFF |

### P1 items (acceptable only with written risk acceptance)

- No certificate pinning on mobile  
- Backend legacy `tsx` in Docker  
- Web admin APIs without Next-layer `api-guard`  
- AI/search/export rate limits not mounted  
- No virus scan on uploads  
- iOS not shipped  

---

## F. Final verdict

## NOT READY FOR PRODUCTION

### Justification

Phase 6 **successfully hardens the codebase** for a future production launch: security middleware, fail-closed rate limiting, environment templates, Docker artifacts, expanded CI, backup scripts, and operational documentation are **in place and verified in source**.

Production readiness is **not** a documentation exercise. The following **operational gaps** block a full public production launch:

1. **No proven path to production traffic** — Architecture still declares interim **Next.js BFF** as API edge; Express Docker path is improved but not validated end-to-end on a staging VPS.

2. **No exercised disaster recovery** — Backup scripts exist but **no scheduled backups** and **no restore drill** were performed during this audit.

3. **No production edge security** — TLS termination, nginx/Caddy, and WAF are **example configs only**; not deployed.

4. **Deploy automation is non-functional** — GitHub deploy workflows are **placeholders**; rollback is manual and untested.

5. **Observability gap** — No Sentry/APM; mobile uses **NoOp** crash reporter; on-call would rely on raw logs.

6. **Secret lifecycle** — No secret manager; production `.env` discipline depends on manual ops without automated scanning in CI (gitleaks/CodeQL absent).

7. **Mobile scope** — **Android-only**; no iOS; acceptable only if product scope is Android-only launch.

### Conditional paths (not full production)

| Scenario | Verdict |
|----------|---------|
| **Closed Android beta** on staging API with manual deploy, HTTPS, Redis, live OTP, backups | **Possible** with explicit risk acceptance document |
| **Public Play Store production** | **NOT READY** until P0 blockers closed |
| **Admin panel production** | **NOT READY** until TLS + env validation on real host + BFF perimeter |

### Score summary

| Letter | Metric | Value |
|--------|--------|-------|
| A | Security Score | **74** |
| B | DevOps Score | **64** |
| C | Mobile Security Score | **76** |
| D | Infrastructure Score | **58** |
| E | Production Readiness | **68%** |

---

## Appendix — Files verified in this audit

| Area | Key paths |
|------|-----------|
| Security stack | `pranidoctor-backend/src/shared/security/middleware/*`, `src/app.ts` |
| Rate limit | `safe-rate-limit.ts`, `auth.routes.ts` |
| Auth | `auth.middleware.ts`, `refresh-token.service.ts` |
| Upload | `media.validation.ts` |
| Docker | `docker/Dockerfile`, `docker-compose.prod.yml` |
| CI | `.github/workflows/ci.yml` (all repos) |
| Mobile | `app_env.dart`, `session_controller.dart`, `release.yml` |
| Web | `next.config.ts`, `proxy-to-backend.ts`, `mobile/livestock/*/route.ts` |
| Docs | `docs/security-guide.md`, `backup-recovery.md`, `phase-6-implementation-report.md` |

---

*Next: [phase-7-preparation.md](./phase-7-preparation.md)*
