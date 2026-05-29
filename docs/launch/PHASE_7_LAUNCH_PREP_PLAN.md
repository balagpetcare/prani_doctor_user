# Phase 7 — Launch Preparation Plan & Readiness Audit

**Document ID:** `PHASE_7_LAUNCH_PREP_PLAN`  
**Audit date:** 2026-05-29  
**Scope:** Prani Doctor multi-repo platform  
**Repositories audited:**

| Repo | Role |
|------|------|
| `pranidoctor_user` | Flutter farmer/customer app |
| `pranidoctor-backend` | Express API, Prisma owner, Redis, MinIO |
| `pranidoctor-web` | Next.js admin panel, doctor panel, BFF (`/api/*` proxy) |

**Related documents:**

- [phase-6-final-audit.md](../phase-6-final-audit.md) — security & DevOps baseline (68% readiness)
- [phase-7-preparation.md](../phase-7-preparation.md) — operational workstream estimates
- [phase-6-devops-security-master-plan.md](../phase-6-devops-security-master-plan.md)
- [flutter_production_readiness_report.md](../stabilization/flutter_production_readiness_report.md)
- [STORE_RELEASE.md](../STORE_RELEASE.md) · [INTERNAL_TEST_REPORT.md](../INTERNAL_TEST_REPORT.md)
- Backend: `pranidoctor-backend/docs/ops/ARCHITECTURE_DECISION_RECORD.md`
- Web: `pranidoctor-web/docs/phases/PHASE_05_ADMIN_ANALYTICS_REPORT.md`

**Audit method:** Static codebase review, workflow/config inspection, and cross-reference of existing audit reports. **No production hosts were exercised** during this audit. Operational items marked **Open (ops)** require validation on real staging/production infrastructure.

**Implementation policy for Phase 7:** Engineering changes tracked in [PHASE_7_IMPLEMENTATION_REPORT.md](./PHASE_7_IMPLEMENTATION_REPORT.md). Ops tasks remain in [../deployment/DEPLOY_RUNBOOK.md](../deployment/DEPLOY_RUNBOOK.md).

---

## Executive summary

Prani Doctor has **strong application-layer foundations**: mobile OTP auth, offline outbox, structured API errors, admin analytics (Phase 05), feed/livestock/fattening/inventory modules, RBAC on the Express backend, and extensive operational runbooks from Phase 6. **Public launch is blocked by operational and perimeter gaps**, not by absence of core features.

| Verdict | Detail |
|---------|--------|
| **Overall launch readiness** | **66%** (weighted; see §Scoring) |
| **Public Play Store + production API** | **NOT READY** |
| **Closed Android beta (staging API, written risk acceptance)** | **Possible** after P0 infra subset |
| **Admin panel on public HTTPS** | **NOT READY** until TLS + BFF perimeter closed |
| **Recommended calendar to “recommended launch”** | **5–7 weeks** (1 senior full-stack + 0.5 DevOps) per [phase-7-preparation.md](../phase-7-preparation.md) |

---

## Launch readiness score

### Composite score: **66 / 100**

| Domain | Weight | Score | Weighted | Grade |
|--------|--------|------:|---------:|-------|
| 1. Backend production | 18% | 72 | 13.0 | C+ |
| 2. Flutter app release | 18% | 70 | 12.6 | C |
| 3. Admin panel & ops workflows | 12% | 78 | 9.4 | C+ |
| 4. Security (OWASP-oriented) | 15% | 71 | 10.7 | C |
| 5. Infrastructure & DevOps | 17% | 52 | 8.8 | F |
| 6. Compliance & legal | 8% | 48 | 3.8 | F |
| 7. App Store readiness | 7% | 55 | 3.9 | F |
| 8. Operational readiness | 5% | 62 | 3.1 | D |
| **Total** | **100%** | — | **65.3 → 66** | **Not ready** |

**Score interpretation**

| Range | Meaning |
|-------|---------|
| ≥ 85 | Ready for public production launch |
| 70–84 | Staged / closed beta with documented risks |
| 50–69 | Engineering-ready; ops/legal/store blockers remain |
| &lt; 50 | Do not expose to end users |

Phase 6 reported **68%** on a slightly different weighting (infra/security/DevOps/mobile/BFF). Phase 7 adds **compliance, store, and operational** dimensions, which lowers the composite despite unchanged technical cores.

---

## Critical blockers (P0)

Must be resolved before **any** public production launch (Play production track, marketing traffic, production doctor payouts).

| ID | Blocker | Repos | Evidence / notes |
|----|---------|-------|------------------|
| **P0-01** | **Production/staging VPS with TLS** | Ops | `deploy/nginx/pranidoctor.conf.example` only; no deployed HSTS/TLS in repo |
| **P0-02** | **Scheduled DB backups + restore drill** | Backend | Scripts exist (`scripts/backup/postgres-backup.sh`); cron and drill **not evidenced** ([backup-recovery.md](../backup-recovery.md)) |
| **P0-03** | **Real deploy pipeline or tested manual cutover** | All | `deploy-production.yml` / `deploy-staging.yml` are **echo placeholders** in backend and web |
| **P0-04** | **Live error/crash telemetry** | All | Backend webhook hook only; mobile `NoOp` crash reporter; no Sentry integration verified |
| **P0-05** | **Production secrets & `OTP_MODE=live`** | Backend | Zod blocks `CHANGE_ME` in prod; hosts must be provisioned; `OTP_MODE` defaults toward dev if unset |
| **P0-06** | **Redis monitored in production** | Backend | Fail-closed rate limit returns 503 if Redis down; alerting **not configured** |
| **P0-07** | **API edge ADR executed & smoke-tested** | Arch | [ADR](https://github.com/balagpetcare/pranidoctor-backend/blob/main/docs/ops/ARCHITECTURE_DECISION_RECORD.md): BFF interim; Express path not E2E validated on VPS |
| **P0-08** | **Hosted legal pages (privacy at minimum)** | Product/Ops | In-app URL `https://pranidoctor.com/privacy` returned **404** in [INTERNAL_TEST_REPORT.md](../INTERNAL_TEST_REPORT.md); API routes exist (`/api/mobile/settings/privacy`) |
| **P0-09** | **Play Store production signing & listing** | Mobile | Internal AAB built; production track, assets, and policy URLs incomplete ([STORE_RELEASE.md](../STORE_RELEASE.md)) |
| **P0-10** | **Web admin API defense in depth** | Web | `requireAdminPanelApiAccess` in `api-guard.ts` — **not applied** across `/api/admin/*`; ~265 routes proxy to backend; HTML `/admin` gated via `proxy.ts` only |

---

## Task backlog by priority

### High priority (P1) — launch with written risk acceptance if deferred

| ID | Task | Owner | Exit criteria |
|----|------|-------|---------------|
| P1-01 | Mount `rateLimitAiChat`, `rateLimitSearch`, `rateLimitExport` on routes | Backend | Presets in `rate-limit.service.ts` wired to AI/search/export paths |
| P1-02 | Apply `requireAdminPanelApiAccess` to `/api/admin/**` BFF routes | Web | Spot-audit 403 without session on sample admin APIs |
| P1-03 | Wire `prisma-production-guard.mjs` into `db:migrate:deploy` | Backend | CI/deploy fails on wrong `DATABASE_URL` host |
| P1-04 | CodeQL + gitleaks in CI | DevOps | Workflows on backend + web |
| P1-05 | Firebase + FCM for Android (`google-services.json`, `firebase_options.dart`) | Mobile | Push E2E on staging; or ship with `ENABLE_PUSH=false` + documented limitation |
| P1-06 | Sentry (or equivalent) on API, web, mobile | All | Test exception appears in dashboard within 5 min |
| P1-07 | Staging migration dry-run on production-copy DB | Backend | ~50 migrations apply cleanly; rollback = forward fix only |
| P1-08 | Bengali localization audit closure | Mobile | ~430 keys still English in `bn.json` per flutter readiness report; critical flows BN-complete |
| P1-09 | Offline outbox soak test | Mobile | Airplane mode → write → reconnect → no data loss on top 5 entity types |
| P1-10 | Doctor web workflow QA sign-off | Web/QA | Accept/reject/complete/prescription path on staging |
| P1-11 | Uptime checks on `/ready` and `/api/health` | Ops | [monitoring-guide.md](../monitoring-guide.md) alerts configured |
| P1-12 | Virus scan on uploads (ClamAV or cloud AV) | Security | Media upload path documented |
| P1-13 | Legacy route compile pipeline (remove runtime `tsx` in Docker) | Backend | Production image runs compiled `dist/legacy` |
| P1-14 | Payment/refund operational process | Product/Ops | Schema has `REFUNDED`; no gateway — manual reconciliation SOP required for marketplace pilot |

### Medium priority (P2) — post-launch hardening (first 30–60 days)

| ID | Task | Notes |
|----|------|-------|
| P2-01 | iOS scaffold + TestFlight | No `ios/` in `pranidoctor_user` |
| P2-02 | Central log shipping (Loki / CloudWatch) | Pino JSON ready; no aggregator |
| P2-03 | Prometheus + Grafana dashboards | `/metrics` + `METRICS_TOKEN` exist |
| P2-04 | CSRF tokens for cookie-based admin mutations | Session cookies on admin panel |
| P2-05 | Secret manager (Doppler / Vault) | Env-file discipline only today |
| P2-06 | Certificate pinning (mobile) | Threat-model decision |
| P2-07 | Hive cache TTL / eviction | Offline cache growth risk |
| P2-08 | Analytics materialized snapshots + read replica | Phase 05 report §gate to 90% |
| P2-09 | Admin doctor monitoring dashboard | [ADMIN_PANEL_GAPS.md](https://github.com/balagpetcare/pranidoctor-web/blob/main/docs/phases/phase-3-real-doctor-workflow/ADMIN_PANEL_GAPS.md) — planned, not shipped |
| P2-10 | Automated assignment / routing rules | Manual admin assign works |
| P2-11 | Technician HTML dashboard | APIs exist; no `/technician` UI |
| P2-12 | `typecheck:legacy` in CI | Backend legacy tree excluded from prod `tsc` |
| P2-13 | CDN for media | MinIO/self-hosted; migrate to S3 + CloudFront at scale |
| P2-14 | WAF / bot management at edge | nginx example only |

### Nice-to-have (P3)

| ID | Task |
|----|------|
| P3-01 | PDF/Excel analytics exports (Phase 05 backlog) |
| P3-02 | Geography heat map UI |
| P3-03 | Root/jailbreak detection on mobile |
| P3-04 | Feature flags / remote config |
| P3-05 | Kubernetes migration | Only when team ops capacity supports |
| P3-06 | iOS App Store parallel track |
| P3-07 | Real-time admin WebSocket doctor status grid |

---

## 1. Backend audit

### 1.1 Production readiness — **72/100**

| Area | Status | Findings |
|------|--------|----------|
| Config validation | **Pass** | Zod `loadConfig()`; `.env.{development,staging,production}.example` |
| Production guards | **Pass** | Redis required in prod; `skipStartupValidation` forbidden; `CHANGE_ME` JWT blocked |
| Health probes | **Pass** | `/live`, `/ready`, `/health`, granular `/health/db`, `/health/redis` |
| Graceful shutdown | **Pass** | Documented in stabilization reports |
| Legacy API surface | **Partial** | ~179+ legacy routes; Docker runs `tsx` on `src/legacy` per ADR |
| Foundation modules | **Partial** | Auth, media, offline, treatment mature; some domains stub/unmounted |
| Worker separation | **Partial** | BullMQ/worker paths documented; not split in prod compose by default |

**Gap:** Production traffic path not proven on real host; compat layer (`/api/mobile/*`, `/api/admin/*`) is the intended production route set per `backend-stabilization-final-report.md`.

### 1.2 Environment variables — **75/100**

| Repo | Templates | Validation |
|------|-----------|------------|
| Backend | `.env.example` + triads | `npm run env:validate` |
| Web | `.env.production.example` | `npm run validate:production-env` in CI |
| Mobile | dart-defines / `.env.*.example` | `assertProductionReady()` HTTPS + `API_BASE_URL` |

**Critical production variables (non-exhaustive):**

- `DATABASE_URL`, `REDIS_URL`, `REDIS_ENABLED=true`
- `MOBILE_JWT_SECRET`, `ADMIN_JWT_SECRET`, `DOCTOR_JWT_SECRET`, `REFRESH_TOKEN_PEPPER`
- `OTP_MODE=live`, SMS provider (`SMS_HTTP_*` or equivalent)
- `MINIO_*` or S3-compatible storage
- `API_DOCS_KEY`, `METRICS_TOKEN` (if docs/metrics exposed)
- `ERROR_TRACKING_WEBHOOK_URL`
- `CORS_ORIGINS` restricted to admin/app origins

### 1.3 API stability — **70/100**

| Factor | Assessment |
|--------|------------|
| Response envelope | Stable `{ ok, data }` / error codes on compat routes |
| Mobile auth | OTP request/verify via BFF → backend (`/api/mobile/auth/otp/*`) |
| Versioning | No formal `/v1` prefix; mobile uses `MINIMUM_APP_VERSION` pattern (config-level) |
| Breaking changes risk | **High** during active Phase 4 migrations (feed ecosystem, inventory, fattening) |
| BFF duplication | Web and backend both expose routes; ADR: backend owns Prisma |

**Action:** Freeze API contract checklist for launch scope ([api-contracts.md](https://github.com/balagpetcare/pranidoctor-web/blob/main/docs/plans/phase-4-livestock-feed-ecosystem/api-contracts.md)) and run smoke on **top 20 mobile endpoints**.

### 1.4 Error handling — **78/100**

| Control | Status |
|---------|--------|
| Central error handler | Yes — `error.handler.ts`, mapped codes |
| Zod validation middleware | Yes |
| Mobile error mapper | Yes — `http_error_mapper.dart`, `user_error_mapper.dart` |
| Sanitized client messages | Yes |
| Error tracking | **Hook only** — webhook URL env |

### 1.5 Logging — **80/100**

| Control | Status |
|---------|--------|
| Structured Pino | Yes, redaction |
| Request correlation | `X-Request-Id` on web |
| Mobile logging | `AppLogger` + `LogRedactor`; network logs off in release |
| Log retention / search | **Not configured** |

### 1.6 Monitoring — **58/100**

| Control | Status |
|---------|--------|
| Prometheus `/metrics` | Yes, token-gated |
| Health endpoints | Yes |
| APM | **Missing** |
| Alerting | **Documented only** ([monitoring-guide.md](../monitoring-guide.md)) |
| Uptime SaaS | **Not configured** |

### 1.7 Database migrations — **65/100**

| Metric | Value |
|--------|-------|
| Migration count | ~50 SQL folders under `prisma/migrations/` |
| Owner | **Backend only** (web must not run `migrate deploy` on prod) |
| Recent high-risk | `phase4_livestock_feed_ecosystem`, `farm_inventory_v1`, `feed_catalog_master_v1`, fattening phases |
| Production guard script | Exists, **not wired** to deploy |
| Rollback strategy | Forward-only; restore from backup |

**Pre-launch:** Apply migrations to a **production snapshot** on staging; measure lock time; document maintenance window if &gt; 30s on large tables.

### 1.8 Backup strategy — **45/100**

| Item | Status |
|------|--------|
| `postgres-backup.sh` / `postgres-restore.sh` | Present |
| 3-2-1 documentation | [backup-recovery.md](../backup-recovery.md) |
| Scheduled cron | **Open (ops)** |
| Restore drill | **Open (ops)** |
| MinIO offsite mirror | Documented, not verified |

---

## 2. Flutter app audit

### 2.1 Release readiness — **62–70/100** (mixed reports)

| Item | Status | Evidence |
|------|--------|----------|
| CI (`flutter analyze`, test) | **Yes** | `.github/workflows/ci.yml` |
| Release workflow | **Yes** | `release.yml` (keystore secrets on tags) |
| Obfuscation / split debug info | **Yes** | `build_release.ps1` |
| Android signing | **Partial** | Internal report: signed AAB; `STORE_RELEASE.md` still notes debug signing TODO — **reconcile before prod** |
| iOS | **No** | No `ios/` directory |
| `assertProductionReady()` | **Yes** | HTTPS + `API_BASE_URL` in release |
| Package ID | `com.pranidoctor.user.pranidoctor_user` | |

### 2.2 Crash risks — **65/100**

| Severity | Finding |
|----------|---------|
| High | ~244 force-unwraps in presentation layer |
| High | DTO `as` casts — schema drift → runtime cast errors |
| Medium | `failure: (e) => throw e` on some providers |
| Fixed (recent) | OTP `mounted` guards, localization SafeParse, feed catalog asset parse |

**Mitigation plan:** Prioritize crash fixes on auth, home, service request, feed entry, and offline sync paths; wire crash reporter before scaling testers.

### 2.3 Offline handling — **78/100**

| Control | Status |
|---------|--------|
| Outbox pattern | Yes — `outbox_item.dart`, `sync_coordinator.dart` |
| Phase 8 architecture migration | Backend migration `phase8_offline_architecture` |
| Connectivity interceptor | Fast-fail when offline |
| Cache warmup | `StartupCacheWarmup` (post-frame) |
| Hive growth / TTL | **Open** — no eviction policy |
| Conflict resolution | Documented per entity; **needs QA matrix** |

### 2.4 Performance — **72/100**

| Item | Status |
|------|--------|
| Image cache caps | `ImageCacheConfig` (200 img / 50 MB) |
| `AppNetworkImage` | Used on key surfaces |
| Sequential startup warmups | Improved via deferred warmup |
| Home dashboard rebuilds | Medium — `.select` optimization deferred |
| List virtualization | Generally OK on audited lists |

### 2.5 Localization — **76/100**

| Item | Status |
|------|--------|
| Architecture | JSON i18n (`en.json`, `bn.json`), Bengali default |
| Coverage | Large BN glossary; **~430 keys still English** in `bn.json` |
| Date/number formatting | `app_date_format.dart`, helpers |
| Feed disclaimers | BN disclaimers on recommendations |
| Store listing BN | **Not prepared** |

### 2.6 Push notifications — **40/100**

| Item | Status |
|------|--------|
| Firebase deps | Present in `pubspec` |
| `NotificationService` | Implemented with FCM handlers |
| `google-services.json` | **Missing** (example only) |
| Gradle plugin | **Not fully wired** per store docs |
| Deep link on notification open | `NotificationDeepLink` + tests exist |
| Launch default | `ENABLE_PUSH=false` on internal builds |

### 2.7 Deep links — **68/100**

| Item | Status |
|------|--------|
| In-app routing | `go_router`, `home_navigation.handleDeepLinkEntry` |
| Notification → route | `notification_deeplink.dart` |
| Universal / App Links | **Not verified** — no documented `assetlinks.json` / intent filters audit in repo |
| Play App Links | **P1** for marketing campaigns |

**Flutter sub-score (weighted): 70/100**

---

## 3. Admin panel audit

### 3.1 RBAC — **74/100**

| Layer | Status |
|-------|--------|
| Backend `rbac.service.ts` | Role + permission checks on Express |
| Admin HTML routes | Cookie/session gate in `proxy.ts` for `/admin`, `/doctor`, `/enterprise` |
| Admin JSON `/api/admin/*` | **Proxied to backend**; Next `api-guard` **not systematically applied** |
| Doctor panel | Separate JWT stack; privacy masking on case detail (phone hidden) |
| Multi-role | Admin, doctor, technician, enterprise paths coexist |

**Risk:** Direct access to BFF URL bypasses Next HTML middleware; relies on backend auth + network perimeter.

### 3.2 Analytics — **81/100** (Phase 05)

| Deliverable | Status |
|-------------|--------|
| 8 analytics endpoints | Implemented + proxied |
| 7 dashboard sections | Overview, revenue, doctors, farmers, livestock, geography, system |
| CSV export | Reports route |
| Date range validation | Zod, 366-day max |
| Gaps | No APM, PDF/Excel, snapshot cron, map UI |

### 3.3 Reporting — **70/100**

| Type | Status |
|------|--------|
| Admin analytics CSV | Yes |
| Feed ecosystem analytics | `/admin/feed-analytics`, feed-ecosystem pages |
| Operational PDFs | **Missing** |
| Scheduled reports | **Missing** |

### 3.4 Operational workflows — **78/100**

| Workflow | Status |
|----------|--------|
| Doctor approve/reject/suspend | Admin APIs present |
| Service request assign doctor/technician | Present |
| AI technician applications | Present |
| Feed catalog / feed items CRUD | Present |
| Feed ecosystem moderation/seed | Present |
| Billing admin views | Schema + UI; **payment automation immature** |
| Doctor monitoring real-time grid | **Not built** (Phase 3 gap doc) |

**Admin sub-score: 78/100**

---

## 4. Security audit (OWASP-oriented)

### 4.1 OWASP Top 10 mapping (summary)

| Risk | Status | Notes |
|------|--------|-------|
| A01 Broken access control | **Partial** | Backend RBAC good; BFF admin API guard gap (P0-10) |
| A02 Cryptographic failures | **Partial** | TLS not deployed; secrets in env files; secure mobile storage OK |
| A03 Injection | **Low** | Prisma parameterized; `sanitize-input.middleware.ts` |
| A04 Insecure design | **Partial** | AI disclaimers in product; manual payment model |
| A05 Security misconfiguration | **Medium** | Swagger/docs gated in prod; OTP dev mode if misconfigured |
| A06 Vulnerable components | **Partial** | `npm audit` in CI (continue-on-error) |
| A07 Auth failures | **Mostly OK** | OTP rate limits, session binding, refresh rotation |
| A08 Software/data integrity | **Partial** | No CodeQL; mobile obfuscation yes |
| A09 Logging failures | **Partial** | Logs exist; no central SIEM |
| A10 SSRF | **Low-Medium** | Review presigned URL and SMS HTTP adapters |

### 4.2 Authentication — **82/100**

- Mobile OTP with hourly caps; panel login for admin/doctor/technician.
- Refresh tokens + Redis session (`sid`).
- **Gap:** `OTP_MODE` must be `live` on production; dev OTP panel locked via env.

### 4.3 Authorization — **68/100**

- See §3.1 and P0-10.

### 4.4 Secrets management — **52/100**

- `.env` gitignored; triad examples; no Vault/SM.
- Mobile keystore via GitHub secrets (good).
- **Gap:** gitleaks not in CI; rotation runbook not exercised.

### 4.5 Abuse prevention — **72/100**

- Global API rate limit + auth/upload limits; fail-closed without Redis in prod.
- AI/search/export limiters **exported but not mounted**.
- No WAF; no Next-layer rate limit.

**Security sub-score: 71/100**

---

## 5. Infrastructure audit

### 5.1 Docker — **68/100**

| Artifact | Status |
|----------|--------|
| `docker-compose.yml` | Postgres, Redis, MinIO |
| `docker-compose.prod.yml` | Production overlay |
| Backend `docker/Dockerfile` | Multi-stage; legacy via `tsx` |
| Web `Dockerfile` | Standalone Next output |
| Mobile | N/A |

### 5.2 Reverse proxy — **30/100**

- Example: `pranidoctor-backend/deploy/nginx/pranidoctor.conf.example`
- **Not deployed** in repo; cert automation absent.

### 5.3 SSL/TLS — **30/100**

- Helmet HSTS in app when behind TLS — **requires terminator**
- Let's Encrypt process: documentation only.

### 5.4 CDN — **20/100**

- No CDN for API; media via MinIO public URL pattern.
- **Launch:** acceptable for Bangladesh pilot; plan CDN at Phase 8 scale.

### 5.5 File storage — **75/100**

- MinIO integration documented; upload MIME + magic-byte validation.
- Bucket versioning / mirror: **ops task**.

### 5.6 Monitoring & alerting — **55/100**

- See §1.6; incident guide exists ([incident-response-guide.md](../incident-response-guide.md)).

**Infrastructure sub-score: 52/100**

---

## 6. Compliance audit

### 6.1 Policy documents

| Document | In-app / API | Hosted public URL | Status |
|----------|--------------|-------------------|--------|
| Privacy Policy | `PrivacyPage`, `settings/privacy`, API `settings/privacy` | `PRIVACY_POLICY_URL` → **404** | **BLOCKER** |
| Terms of Service | `terms_page`, API `settings/terms` | Not verified | **Likely gap** |
| Refund Policy | Billing enums only | No dedicated page found | **Missing** |
| Doctor Disclaimer | AI/chat disclaimers in copy | Partial | **Needs legal review** |
| Veterinary Disclaimer | `aiDisclaimer`, feed `disclaimerBn` | In-feature | **Not substitute for ToS/legal** |

### 6.2 Data privacy (Bangladesh context)

| Topic | Status |
|-------|--------|
| PII in admin analytics | Phase 05: aggregates only by design |
| Voice/transcript retention | Phase 7 voice docs: metadata default |
| User data export/delete | **Verify** against product requirements — not audited as complete |
| OTP phone storage | Backend challenge model — confirm retention policy in privacy doc |

### 6.3 Play / store policies

- Data safety form requires accurate disclosure of location, phone, health-adjacent livestock data.
- **Medical disclaimer** must appear where AI/triage is shown (partially implemented).

**Compliance sub-score: 48/100**

---

## 7. App Store readiness (Google Play)

### 7.1 Play Store requirements

| Requirement | Status |
|-------------|--------|
| Target API level / 64-bit | Verify against current `compileSdk` before upload |
| Data safety section | **Not completed** in repo |
| Content rating questionnaire | **Ops task** |
| App Signing | Play App Signing enrollment on first upload |
| Privacy policy URL | **BLOCKER** (404) |

### 7.2 Assets

| Asset | Status |
|-------|--------|
| App icon | Verify `@mipmap/ic_launcher` branding vs default |
| Feature graphic | **Missing** in repo |
| Screenshots (phone/tablet) | **Missing** — capture from staging |
| Short/long description (EN/BN) | **Missing** in repo |
| Release notes | Template needed per track |

### 7.3 Release tracks (recommended path)

1. **Internal testing** — `INTERNAL_TEST_READY` per engineering report; upload `internal-release.aab`.
2. **Closed testing** — 20+ testers, device smoke matrix ([INTERNAL_TEST_REPORT.md](../INTERNAL_TEST_REPORT.md)).
3. **Open testing / production** — only after P0 blockers closed.

**App Store sub-score: 55/100** (Android only; iOS N/A)

---

## 8. Operational readiness

### 8.1 Support process — **60/100**

| Item | Status |
|------|--------|
| In-app support tickets | Mobile `support/tickets` APIs + UI |
| Help content | `support/help` API |
| Public support email/chat | **Not in repo** — define in ops wiki |
| SLA for farmer issues | **Undefined** |

### 8.2 Escalation process — **55/100**

| Item | Status |
|------|--------|
| Incident severity table | [incident-response-guide.md](../incident-response-guide.md) SEV-1–3 |
| On-call rotation | **Placeholder** — “document in team wiki” |
| Escalation to engineering | Implied in incident guide; **no named roles** |

### 8.3 Incident process — **70/100**

| Item | Status |
|------|--------|
| SEV-1 playbook | Auth compromise, rollback commands |
| Post-mortem template | 72-hour blameless |
| Status communication | Described; no Statuspage integration |

### 8.4 Doctor onboarding process — **58/100**

| Step | Status |
|------|--------|
| Admin doctor CRUD + verify/approve | Web admin APIs |
| Working areas / fees / categories | Admin configuration |
| Doctor web login + case workflow | `/doctor` panel |
| Documented SOP for new doctor | **Not in repo** — use admin UI informally |
| Credential issuance | Manual; no self-service portal audit |
| Technician onboarding | AI technician apply flow on mobile; admin review |

**Operations sub-score: 62/100**

---

## 9. Multi-role doctor system (cross-cutting)

| Role | Client | Auth | Launch note |
|------|--------|------|-------------|
| Farmer/customer | Flutter `pranidoctor_user` | Mobile OTP JWT | Primary launch surface |
| Doctor | Web `/doctor` | Doctor JWT | Staging QA required (P1-10) |
| Admin | Web `/admin` | Admin session | Analytics + assignment ready |
| AI Technician | Mobile + admin review | Technician JWT / mobile flows | Higher operational complexity |
| Enterprise | Web `/enterprise` | Separate panel | Confirm scope for v1 launch |

**Recommendation:** Launch v1 with **farmer app + admin + doctor web** in pilot geography; defer enterprise marketing unless contractually required.

---

## 10. Launch scenarios & go/no-go

| Scenario | Readiness | Conditions |
|----------|-----------|------------|
| **A. Public Play Production** | **No** | All P0 cleared; score ≥ 85%; 7-day staging burn-in |
| **B. Closed Android beta** | **Conditional** | Staging HTTPS, live OTP on staging, backups, Sentry, signed build, legal URLs live, risk doc signed |
| **C. Admin-only production** | **No** | P0-01, P0-10, TLS, env validation on host |
| **D. Doctor pilot (web)** | **Conditional** | Staging + manual doctor onboarding SOP + support channel |

### Go/no-go checklist (abbreviated)

- [ ] P0-01 … P0-10 closed or explicitly waived with sign-off
- [ ] Staging smoke: OTP → animal → service request → doctor accept → complete
- [ ] Feed/inventory/fattening flows in scope tested or feature-flagged off
- [ ] `flutter test` + backend `npm test` green on release branch
- [ ] Migration applied on staging DB clone
- [ ] Restore drill completed & logged
- [ ] Privacy + terms URLs return 200
- [ ] On-call named for launch week
- [ ] Rollback tag documented for API and web images

---

## 11. Recommended execution timeline

Aligned with [phase-7-preparation.md](../phase-7-preparation.md):

| Week | Focus | Outcomes |
|------|-------|----------|
| 1–2 | Staging VPS, TLS, env secrets, mobile → staging API | M1 |
| 2 | Backups cron + restore drill | M2 |
| 3 | Sentry ×3, uptime alerts | M3 |
| 4–5 | Deploy automation, security P1 (api-guard, rate limits) | M4 |
| 5–6 | QA sign-off, legal pages, Play closed testing | M5 |
| 7–10 (optional) | Express public API cutover | M6 |

| Scope | Calendar |
|-------|----------|
| Minimum viable launch (Android, manual deploy, BFF edge) | 3–4 weeks |
| Recommended launch | 5–7 weeks |
| Full Express cutover + iOS scaffold | 8–11 weeks |

---

## 12. Phase 7 success criteria (exit)

Phase 7 launch prep is **complete** when:

1. Composite readiness **≥ 85%** on this scoring model (or explicit scenario scorecard for beta).
2. All **P0 blockers** closed or waived with written risk acceptance stored outside git.
3. Verdict updated to **READY FOR PRODUCTION** (or **READY FOR ANDROID BETA** with scope footnote).
4. Companion doc published: `docs/phase-7-implementation-report.md` (post-execution, not part of this audit).

---

## 13. Immediate next actions (week 1)

| # | Action | Owner |
|---|--------|-------|
| 1 | Provision staging VPS; apply nginx example + Let's Encrypt | Ops |
| 2 | Copy `.env.staging.example` → `.env`; set `OTP_MODE=live` on staging | Backend |
| 3 | Run first `postgres-backup.sh`; schedule cron | Ops |
| 4 | Publish privacy + terms at public URLs; fix 404 | Product/Legal |
| 5 | Point internal Flutter build to staging `API_BASE_URL` | Mobile |
| 6 | Create Sentry projects; wire DSNs (no-op removal) | All |
| 7 | Product sign-off: launch scope (Android-only, pilot geography, payment manual) | Product |
| 8 | Implement real `deploy-staging.yml` or document manual cutover with rollback test | DevOps |
| 9 | Admin API spot-test: unauthenticated `/api/admin/analytics/overview` → must 401/403 | Security |
| 10 | Upload AAB to Play **internal** track; recruit 5 testers | Mobile/QA |

---

## Appendix A — Evidence index

| Area | Key paths |
|------|-----------|
| Backend app | `pranidoctor-backend/src/app.ts`, `src/shared/security/` |
| Migrations | `pranidoctor-backend/prisma/migrations/` |
| Backup | `pranidoctor-backend/scripts/backup/` |
| Deploy workflows | `*/.github/workflows/deploy-*.yml` |
| Mobile env | `pranidoctor_user/lib/app/app_env.dart` |
| Mobile offline | `pranidoctor_user/lib/features/offline/` |
| Push | `pranidoctor_user/lib/features/notifications/notification_service.dart` |
| Web BFF | `pranidoctor-web/src/app/api/**/route.ts` (proxy pattern) |
| Web api-guard | `pranidoctor-web/src/lib/admin-auth/api-guard.ts` |
| Ops docs | `pranidoctor_user/docs/{deployment-guide,security-guide,backup-recovery,incident-response-guide,monitoring-guide}.md` |

---

## Appendix B — Score reconciliation with Phase 6

| Source | Score | Note |
|--------|------:|------|
| Phase 6 production readiness | 68% | Infra-weighted; no compliance/store |
| Phase 7 composite (this doc) | **66%** | Adds compliance (48) and store (55), infra 52 |
| Flutter-only report | 74% | App code quality; excludes ops/store |
| Admin analytics Phase 05 | 81% prod readiness | Feature slice only |

---

*This document supersedes informal launch notes for Phase 7 planning. Do not implement code from this file without a separate execution ticket. After operational work completes, update the verdict in `docs/phase-7-implementation-report.md`.*
