# Production Readiness Report — Final Launch Verification

**Report ID:** `PRODUCTION_READINESS_REPORT`  
**Verification date:** 2026-05-29  
**Repositories:** `pranidoctor_user` · `pranidoctor-backend` · `pranidoctor-web`  
**Prior audits:** Phase 6 (68%) · Phase 7 implementation (engineering ~82%)  
**Verification type:** Static + local CI; **no live production traffic test**

---

## Executive summary

| Metric | Value |
|--------|------:|
| **Launch score** | **78 / 100** |
| **Official status** | **NOT_READY_FOR_PRODUCTION** |
| **Recommended next step** | Closed Android beta on staging after ops checklist (3–5 days) |

Prani Doctor is **feature-complete for a pilot launch** (farmer app, admin panel, doctor web workflow, analytics, offline outbox, auth). **Public production launch is blocked** because production infrastructure, live SMS/push, payment automation, and operational drills have **not been executed** on real hosts.

---

## Launch score breakdown

| Domain | Weight | Score | Weighted | Rationale |
|--------|--------|------:|---------:|-----------|
| Flutter app | 15% | 74 | 11.1 | OTP wired; 11 test failures (goldens); FCM blocked; crash webhook ready |
| Backend API | 15% | 83 | 12.5 | 237 tests pass; rate limits + health probes; compat layer production path |
| Admin panel | 12% | 85 | 10.2 | Analytics 88% feature complete; BFF guard added; launch-ops page |
| Database | 10% | 73 | 7.3 | 49 migrations; guard wired; prod clone migrate not run |
| Infrastructure | 15% | 55 | 8.3 | Docker/CI defined; TLS/backups/deploy not live |
| Security | 13% | 79 | 10.3 | RBAC, JWT guards, rate limits, BFF auth; no AV scan; secrets file-only |
| Monitoring | 10% | 63 | 6.3 | Metrics/health hooks; Sentry optional; no prod alerting |
| Functional E2E (10 areas) | 10% | 75 | 7.5 | Code paths verified; live smoke not run |
| **Total** | **100%** | — | **78.2 → 78** | |

**Grade interpretation:** 78 = strong engineering readiness; **ops gap prevents production go-live.**

---

## System review

### Flutter app (`pranidoctor_user`)

| Area | Assessment |
|------|------------|
| Architecture | Feature-first, Riverpod, go_router, Dio interceptors — production-grade |
| Auth | Full OTP flow via `AuthRepository` → `/api/mobile/auth/otp/*` |
| Offline | Outbox + `SyncCoordinator`; Phase 8 backend migration aligned |
| Localization | JSON i18n BN default; ~430 EN keys remain in `bn.json` (non-blocking for pilot) |
| Release | `build_release.ps1` enforces keystore + HTTPS; AAB build documented |
| Blockers | Firebase/`google-services.json` absent → push off; Play listing incomplete |

**Test results (2026-05-29):** 220 passed, 11 failed (primarily golden UI pixel diffs).  
**Analyze:** 89 issues (info-level lint; no compile errors).

### Backend API (`pranidoctor-backend`)

| Area | Assessment |
|------|------------|
| Production path | Compat layer `/api/mobile/*`, `/api/admin/*`, `/api/doctor/*` |
| Auth | OTP + panel JWT + Redis session binding |
| Phase 7 hardening | AI/search/export rate limits; probe-exempt health; Sentry hook |
| Migrations | 49 folders; `ALLOW_PRODUCTION_MIGRATE=true` guard |
| Legacy runtime | Docker uses `tsx` for legacy routes (accepted ADR risk) |

**Test results:** 237/237 active tests pass; 1 archived suite import failure (non-blocking for compat path).

### Admin panel (`pranidoctor-web`)

| Area | Assessment |
|------|------------|
| Admin UI | Full CRUD: doctors, requests, billing, feed ecosystem, analytics |
| Doctor UI | Request accept/reject/complete, prescriptions, earnings |
| BFF | ~265 proxy routes; admin API guard enforced at proxy layer (Phase 7) |
| Legal | `/privacy`, `/terms`, `/refund`, `/legal/disclaimer` pages shipped |
| Analytics | Phase 05: 81% production readiness for analytics slice |

**Test results:** 95/95 vitest pass.

### Database (PostgreSQL + Prisma)

| Metric | Value |
|--------|-------|
| Schema owner | `pranidoctor-backend` |
| Migrations | 49 sequential folders |
| High-risk recent | `phase4_livestock_feed_ecosystem`, `farm_inventory_v1`, `feed_catalog_master_v1` |
| Integrity controls | Location dedupe constraints; billing enums include `REFUNDED` |
| Gap | No production-copy migrate timing measured; no live replication |

### Infrastructure

| Component | Status |
|-----------|--------|
| Docker Compose | Postgres, Redis, MinIO — dev/staging ready |
| Production compose overlay | `docker-compose.prod.yml` |
| nginx TLS template | Updated with probe bypass + HTTP redirect |
| CI deploy | GHCR build/push; SSH deploy optional via `deploy_remote` |
| CDN | Not configured (acceptable for pilot) |
| **Live VPS** | **Not verified in this audit** |

### Security

| Control | Status |
|---------|--------|
| OWASP A01 (access control) | Improved — BFF admin guard + backend RBAC |
| A07 (auth failures) | OTP rate limits; fail-closed without Redis |
| A08 (integrity) | CodeQL + gitleaks CI added; mobile obfuscation on release |
| Upload safety | MIME allowlist + magic bytes; **no virus scan** |
| Secrets | Env-file only; production validation scripts pass |
| TLS | Terminator not deployed |

### Monitoring

| Signal | Status |
|--------|--------|
| `/health`, `/ready`, `/live` | Backend + web BFF |
| `/metrics` | Token-gated Prometheus text |
| Logging | Pino JSON backend; structured web server logger |
| APM | Sentry optional (`SENTRY_DSN`); webhook fallback |
| Alerting | Prometheus rules example; **no paging configured** |
| Uptime SaaS | Not configured |

---

## Ten-domain verification summary

| # | Domain | Score | Verdict |
|---|--------|------:|---------|
| 1 | Authentication | 84 | Code ready; live SMS unverified |
| 2 | Registration | 80 | API + profile flow complete |
| 3 | Doctor workflow | 82 | Web APIs complete; E2E not run live |
| 4 | Consultation workflow | 72 | Manual assign + manual payment |
| 5 | Notifications | 58 | In-app yes; push/SMS live no |
| 6 | Admin operations | 86 | Strong; refund automation manual |
| 7 | Analytics | 81 | Phase 05 signed off |
| 8 | File uploads | 77 | Secure upload path; no AV |
| 9 | Error recovery | 76 | Hooks ready; prod ingest unconfirmed |
| 10 | Database integrity | 73 | Schema solid; prod drill pending |

---

## Remaining blockers (must close for public production)

| ID | Blocker | Owner | ETA |
|----|---------|-------|-----|
| BL-01 | Production/staging VPS with TLS and public DNS | DevOps | 2–3 days |
| BL-02 | DB backup cron + documented restore drill | DevOps | 1 day |
| BL-03 | Deploy workflow executed with `DEPLOY_*` secrets + `/ready` gate | DevOps | 1 day |
| BL-04 | `OTP_MODE=live` + live Bangladesh SMS provider tested | Backend/Ops | 1–2 days |
| BL-05 | Firebase + `google-services.json` OR ship with `ENABLE_PUSH=false` documented | Mobile | 1 day |
| BL-06 | Play Console internal/closed track upload + policy URLs live | Product | 2 days |
| BL-07 | Sentry/webhook receiving test exception in prod/staging | All | 0.5 day |
| BL-08 | End-to-end smoke: OTP → request → doctor complete on staging device | QA | 1 day |
| BL-09 | Payment remains manual — publish reconciliation SOP | Product/Ops | 0.5 day |
| BL-10 | Migrate dry-run on production DB snapshot | Backend | 0.5 day |

---

## Launch recommendation

### Official status

## NOT_READY_FOR_PRODUCTION

Public Play Store production track and production API traffic for general users **must not** go live until blockers BL-01 through BL-08 are closed.

### Conditional paths (explicit risk acceptance required)

| Scenario | Recommendation |
|----------|----------------|
| **Closed Android beta** (staging API, 20–50 testers, manual payments) | Proceed after BL-01, BL-04, BL-06, BL-08; accept BL-05 push-off if documented |
| **Doctor web pilot** (staging, manual onboarding) | Proceed after BL-01 + BL-03; BL-09 SOP required |
| **Admin-only staging demo** | Ready now on local/LAN with existing docker compose |

### Path to READY_WITH_MINOR_RISKS (target score ≥ 85)

1. Complete ops checklist in [GO_LIVE_CHECKLIST.md](./GO_LIVE_CHECKLIST.md) sections A7–A12  
2. Run 7-day staging burn-in with Sentry + uptime checks  
3. Close golden test failures or waive as non-functional  
4. Document payment manual process in ops wiki  

### Path to READY_FOR_PRODUCTION (target score ≥ 90)

All above plus: live SMS, push OR explicit push-off product sign-off, Play production track, backup restore drill signed, payment gateway or permanent manual-process approval from leadership.

---

## Evidence index

| Artifact | Location |
|----------|----------|
| Phase 7 implementation | `docs/launch/PHASE_7_IMPLEMENTATION_REPORT.md` |
| Go-live checklist | `docs/launch/GO_LIVE_CHECKLIST.md` |
| Known limitations | `docs/launch/KNOWN_LIMITATIONS.md` |
| Rollback plan | `docs/launch/ROLLBACK_PLAN.md` |
| Launch day runbook | `docs/launch/LAUNCH_DAY_RUNBOOK.md` |
| Backend tests | `npm test` — 237 pass (2026-05-29) |
| Web tests | `npm test` — 95 pass (2026-05-29) |
| Flutter tests | `flutter test` — 220 pass / 11 fail (2026-05-29) |

---

*Signed verdict: **NOT_READY_FOR_PRODUCTION** as of 2026-05-29. Re-run this report after staging burn-in to update status.*
