# Phase 7 — Preparation Plan

**Date:** 2026-05-29  
**Prerequisite:** [phase-6-final-audit.md](./phase-6-final-audit.md)  
**Phase 6 outcome:** Foundations implemented; **67–68% production readiness** — **NOT READY FOR PRODUCTION**

---

## 1. Purpose of Phase 7

Phase 7 converts Phase 6 **code and documentation** into **operational production capability**:

- Live staging environment with real TLS, secrets, and monitoring  
- Exercised backups and incident runbooks  
- Automated or repeatable deploy with rollback  
- Observability (Sentry or equivalent) on API, web, and mobile  
- Clear API edge ownership (BFF vs Express) with smoke-tested cutover  

---

## 2. Remaining blockers (from Phase 6 audit)

### P0 — Must resolve before public launch

| ID | Blocker | Owner | Exit criteria |
|----|---------|-------|---------------|
| B-01 | Production/staging VPS + TLS | Ops | HTTPS valid on `api.*` and `admin.*`; HSTS enabled |
| B-02 | Backup schedule + restore drill | Ops | Cron runs `postgres-backup.sh`; restore tested on staging DB |
| B-03 | Real deploy pipeline | DevOps | `deploy-staging.yml` / `deploy-production.yml` SSH or registry push + health gate |
| B-04 | Error tracking live | All repos | Sentry DSN or webhook receiving test 500 + mobile crash |
| B-05 | Production env on hosts | Ops | `.env` from `.env.production.example`; `OTP_MODE=live`; no `CHANGE_ME` |
| B-06 | Redis monitored in prod | Ops | Alert if Redis down; rate limits never 503-spike unexplained |
| B-07 | API routing ADR executed | Arch | Document which hostname hits Express vs Next; smoke mobile + admin |

### P1 — High priority (launch with risk doc if deferred)

| ID | Item |
|----|------|
| B-08 | Mount `rateLimitAiChat`, `rateLimitSearch`, `rateLimitExport` on routes |
| B-09 | Next-layer `api-guard` on `/api/admin/*` (defense in depth) |
| B-10 | Wire `prisma-production-guard.mjs` into `db:migrate:deploy` |
| B-11 | CodeQL + gitleaks in CI |
| B-12 | Compile legacy routes to `dist/` — remove runtime `tsx` in Docker |
| B-13 | Certificate pinning (mobile) — threat-model decision |
| B-14 | Virus scan on uploads (ClamAV sidecar or cloud AV) |

### P2 — Medium (post-launch hardening)

| ID | Item |
|----|------|
| B-15 | iOS app scaffold + TestFlight |
| B-16 | Central log shipping (Loki / CloudWatch) |
| B17 | Prometheus + Grafana dashboards |
| B-18 | CSRF tokens for cookie-based admin mutations |
| B-19 | Secret manager (Doppler / Vault) |
| B-20 | Full backend `typecheck` clean in CI |

---

## 3. Recommended improvements (prioritized)

### Week 1–2: Staging stand-up

1. Provision Hetzner (or chosen) VPS — follow `docs/deployment-guide.md`.  
2. Deploy `docker-compose.yml` + `docker-compose.prod.yml` (backend).  
3. Apply `deploy/nginx/pranidoctor.conf.example` with Let's Encrypt.  
4. Point mobile internal track to `APP_ENV=staging` + staging API URL.  
5. Run `npm run validate:production-env` on web before first admin deploy.

### Week 2–3: Observability + backups

1. Create Sentry projects: `api`, `admin-web`, `mobile-android`.  
2. Wire backend `registerErrorCapture` → Sentry SDK (replace webhook-only).  
3. Wire mobile `GlobalErrorHandler.install(crashReporter: ...)`.  
4. Schedule `postgres-backup.sh`; offsite copy; **run restore drill**.  
5. Uptime Kuma / Better Stack on `/ready` and `/api/health`.

### Week 3–4: CD + quality gates

1. Implement real `deploy-staging.yml` (build image → push GHCR → SSH pull → compose up).  
2. Add CodeQL workflow to backend + web.  
3. Fix or quarantine backend `typecheck` errors; add `typecheck` job to CI.  
4. Integration job: ephemeral Postgres + `npm test` + migrate smoke.

### Week 4–6: API cutover (if choosing Express edge)

1. Implement legacy compile pipeline (remove `tsx` from production CMD).  
2. Load test auth + top 10 mobile endpoints on staging Express.  
3. Switch public DNS `api.*` to Express; keep Next as admin-only.  
4. Update `ARCHITECTURE.md` to reflect final state.

---

## 4. Future scaling strategy

### Phase 7 (launch readiness) — single VPS

```
Internet → nginx → Express :3000 (API)
                 → Next   :3001 (admin)
                 → Postgres + Redis + MinIO (same host or managed DB)
```

**Triggers to scale:** >500 concurrent mobile users, DB >30GB, API p95 >800ms.

### Phase 8 (growth) — split services

- Managed PostgreSQL (RDS / Supabase / Neon)  
- Managed Redis (ElastiCache / Upstash)  
- S3 instead of self-hosted MinIO  
- Second app VPS behind load balancer  
- CDN for media (`MINIO_PUBLIC_URL` → CloudFront)

### Phase 9 (scale) — horizontal

- Stateless API replicas (2+) behind nginx upstream  
- BullMQ workers on separate container (`worker.ts` processors implemented)  
- Read replica for analytics queries  
- Optional Kubernetes when team size supports ops overhead  

### Mobile scaling

- Android: Play App Signing, staged rollouts (`MINIMUM_APP_VERSION` force upgrade)  
- iOS: separate pipeline when `ios/` added  
- Feature flags via remote config (future)

---

## 5. Estimated workload for Phase 7

Assumes **1 senior full-stack + 0.5 DevOps**, part-time QA.

| Workstream | Tasks | Estimate |
|------------|-------|----------|
| **7.1 Staging infra** | VPS, Docker, nginx, TLS, env secrets | **5–8 days** |
| **7.2 Backups & DR** | Cron, offsite, restore drill, runbook sign-off | **2–3 days** |
| **7.3 Observability** | Sentry ×3, alerts, dashboards | **3–5 days** |
| **7.4 CD pipeline** | GHCR, deploy workflows, rollback test | **4–6 days** |
| **7.5 Security closure** | api-guard, rate limits, CodeQL, OTP prod checklist | **3–5 days** |
| **7.6 Mobile release** | Play internal → closed testing, crash symbols upload | **3–4 days** |
| **7.7 QA & sign-off** | Smoke E2E, load smoke, go-live checklist | **5–7 days** |
| **7.8 API cutover (optional)** | Legacy compile, staging parity, DNS switch | **8–12 days** |

### Total estimates

| Scope | Calendar time |
|-------|----------------|
| **Minimum viable launch** (Android, BFF edge, manual deploy acceptable) | **3–4 weeks** |
| **Recommended launch** (automated deploy, Sentry, backups drilled, staging parity) | **5–7 weeks** |
| **Full Express cutover + iOS scaffold** | **8–11 weeks** |

### Suggested Phase 7 milestones

| Milestone | Deliverable | Week |
|-----------|-------------|------|
| M1 | Staging HTTPS live, mobile hits staging API | 1–2 |
| M2 | Backups + restore drill documented | 2 |
| M3 | Sentry receiving errors (API + mobile) | 3 |
| M4 | Deploy staging automated; production runbook | 4–5 |
| M5 | Go/no-go review — target **≥ 85%** readiness | 5–6 |
| M6 (optional) | Express public API cutover | 7–10 |

---

## 6. Phase 7 success criteria

Phase 7 is complete when:

- [ ] [phase-6-final-audit.md](./phase-6-final-audit.md) P0 blockers B-01 through B-07 are closed  
- [ ] Production readiness **≥ 85%** on same scoring model  
- [ ] Verdict updated to **READY FOR PRODUCTION** (or scoped **READY FOR ANDROID BETA**)  
- [ ] `docs/phase-7-implementation-report.md` published  

---

## 7. Immediate next actions (this week)

1. **Ops:** Provision staging VPS; copy `.env.staging.example` → `.env`.  
2. **Backend:** Set `API_DOCS_KEY`, `METRICS_TOKEN`, `OTP_MODE=live` on staging.  
3. **Mobile:** Point internal track build to staging `API_BASE_URL`.  
4. **DevOps:** Run first `postgres-backup.sh` manually; document output path.  
5. **Product:** Confirm launch scope — **Android-only** vs iOS required.  

---

*Related: [phase-6-final-audit.md](./phase-6-final-audit.md) · [deployment-guide.md](./deployment-guide.md) · [incident-response-guide.md](./incident-response-guide.md)*
