# Closed Beta Readiness Report — Prani Doctor

**Report ID:** `CLOSED_BETA_READINESS_REPORT`  
**Verification date:** 2026-06-01  
**Auditor role:** Principal Launch Auditor & Production Readiness Reviewer  
**Mode:** Verification only — no new features implemented  
**Repositories:** `pranidoctor_user` · `pranidoctor-backend` · `pranidoctor-web`  
**Reference plans:** [closed-beta-launch-plan.md](./closed-beta-launch-plan.md) · [closed-beta-checklist.md](./closed-beta-checklist.md) · [PRODUCTION_READINESS_REPORT.md](./PRODUCTION_READINESS_REPORT.md)

**Verification method:** Static codebase audit, automated test execution (local CI), documentation cross-review, closed-beta framework inspection. **No live staging/production host, Play Console, or external monitoring SaaS was exercised in this session.**

---

## Executive Summary

| Metric | Value |
|--------|------:|
| **Overall launch readiness** | **70 / 100** |
| **Technical readiness** | **83%** |
| **Operational readiness** | **54%** |
| **Compliance readiness** | **71%** |
| **Support readiness** | **61%** |
| **Final verdict** | **GO WITH CONDITIONS** |
| **Recommended initial cohort** | **25 users** (C0 + C1); cap **50** after 7-day stable burn-in |

Prani Doctor is **engineering-ready for a controlled closed beta**: core farmer/doctor/admin workflows, livestock modules, AI governance, legal-safe messaging (P0 ETA removal), and a **closed-beta operations framework** (config, access gates, dashboard, feedback API) are implemented and largely test-backed.

**Public or broad beta is not supported.** Operational perimeter items — live VPS/TLS, backup cron + restore drill, external uptime/Sentry on prod, live SMS verification, executed E2E smoke on devices, pilot doctors onboarded on host, and legal counsel sign-off on live URLs — remain **unverified or open**.

### Final Verdict: **GO WITH CONDITIONS**

Proceed with **≤ 25 real users** (internal + friendly cohort) **only after** closing the **P0 conditions** in §Recommended Fixes. Do **not** expand to 50+ users until day-7 metrics review and ops P0 checklist pass.

### Recommended beta cohort size

| Option | Recommendation | Rationale |
|--------|----------------|-----------|
| **25 users** | **✅ Recommended start** | Matches C0 (5–10) + C1 (10–15); within manual ops capacity |
| 50 users | Conditional after 7 days | Plan max before stabilization review; requires P0 ops closed |
| 100 users | **Not recommended** | Exceeds plan cap (80) without ops maturity |
| 250 users | **No** | No auto-routing, manual assign, single-VPS |
| 500 users | **No** | Infrastructure and support not sized |

---

## Launch Readiness Score

| Dimension | Weight | Score | Weighted |
|-----------|--------|------:|---------:|
| Technical readiness | 28% | 83 | 23.2 |
| Operational readiness | 27% | 54 | 14.6 |
| Compliance readiness | 20% | 71 | 14.2 |
| Support readiness | 13% | 61 | 7.9 |
| Metrics & beta ops | 12% | 78 | 9.4 |
| **Total** | **100%** | — | **69.3 → 70** |

**Interpretation:** 70 = strong **code + documentation** readiness; **ops deployment** is the binding constraint.

---

## 1. Infrastructure Results

| Check | Status | Evidence |
|-------|--------|----------|
| Docker Compose (dev/staging shape) | ✅ Pass | `docker-compose.yml`, `docker-compose.prod.yml` |
| Production TLS / public DNS | ❌ Fail | No live host verified ([PRODUCTION_READINESS_REPORT](./PRODUCTION_READINESS_REPORT.md) BL-01) |
| Deploy pipeline E2E on host | ❌ Fail | GHCR defined; `deploy_remote` not evidenced |
| Environment validation scripts | ✅ Pass | `validate:production-env` in CI |
| `CLOSED_BETA_*` env documented | ✅ Pass | `.env.staging.example`, `.env.production.example` |
| DB backup cron | ❌ Fail | Scripts exist; cron not installed on live host |
| Restore drill | ❌ Fail | No drill log |
| Single-VPS HA | ⚠️ Waived | Documented limitation L-07 for pilot |

**Infrastructure score: 48 / 100**

---

## 2. Monitoring, Alerting & Recovery

| Check | Status | Evidence |
|-------|--------|----------|
| Health probes (`/live`, `/ready`, `/health/*`) | ✅ Pass | Backend + BFF routes |
| Prometheus metrics in app | ✅ Pass | [production-monitoring-verification-report.md](./production-monitoring-verification-report.md) — 88/100 instrumentation |
| Prometheus/Grafana deployed | ❌ Fail | Rules in `deploy/monitoring/`; not scraped live |
| External uptime monitors | ❌ Fail | Not configured |
| In-app webhook alerts | ⚠️ Partial | Code shipped; `MONITORING_ALERT_WEBHOOK_URL` not confirmed live |
| Sentry / crash ingest live | ❌ Fail | Hooks wired; DSN not confirmed on prod |
| Rollback plan documented | ✅ Pass | [ROLLBACK_PLAN.md](./ROLLBACK_PLAN.md) |
| Rollback exercised on host | ❌ Fail | Not evidenced |

**Monitoring score: 72 / 100** (blended app + ops per monitoring verification report)

**Recovery readiness: Fail** — forward-only migrations + backup scripts exist; **no proven RPO/RTO** on live infrastructure.

---

## 3. Application / Workflow Results

### 3.1 Automated test summary (2026-06-01)

| Repo | Result | Notes |
|------|--------|-------|
| `pranidoctor-web` | **109 / 109 pass** | Vitest |
| `pranidoctor-backend` | **323 / 328 pass** (98.5%) | 5 failures — logger init in AI usage verify suite (orthogonal to launch framework) |
| `pranidoctor-backend` closed-beta + governance | **16 / 16 pass** | `closed-beta-config`, `ai-governance`, `ai-health` |
| `pranidoctor_user` | **220 / 230 pass** (95.7%) | 10 failures — mostly golden/widget diffs |

### 3.2 Workflow validation

| Workflow | Code | Live E2E | Verdict |
|----------|------|----------|---------|
| **Authentication (OTP)** | ✅ | ❌ | Conditional — beta invite/cap gate in `mobile-otp-auth.service.ts`; live SMS unverified |
| **Doctor workflow** | ✅ | ❌ | Conditional — web APIs + panel; staging smoke not run |
| **Consultation (SR lifecycle)** | ✅ | ❌ | Conditional — manual assign; payment manual |
| **Emergency workflow** | ✅ | ❌ | Conditional — limitation banners on instant care/booking; not live-tested |
| **Livestock / feed / inventory** | ✅ | ❌ | Conditional — modules shipped; pilot scope dependent |
| **AI (chat, triage, symptom)** | ✅ | ❌ | Conditional — consent on `/api/ai/*` and `/api/voice/*`; kill switch 12/12 unit tests |
| **Notifications** | ⚠️ | ❌ | Partial — in-app yes; FCM absent (`ENABLE_PUSH=false` waiver) |

**Application score: 83 / 100**

---

## 4. Compliance Results

| Area | Status | Evidence |
|------|--------|----------|
| Legal pages (web) | ✅ Pass (code) | `/privacy`, `/terms`, `/refund`, `/legal/disclaimer` |
| Legal pages live HTTP 200 | ❌ Fail | Not verified on public host |
| ETA / SLA copy (P0) | ✅ Pass | [legal-safe-messaging-verification-report.md](./legal-safe-messaging-verification-report.md) — Instant Care keys legal-safe |
| AI disclosures (T1/T2/T3, E2) | ✅ Pass (core) | CMS + `AiDisclaimerGate`, `AiOutputComplianceWrapper` |
| Emergency limitation (U1/U2) | ✅ Pass (enhanced) | Instant care + `AiOutputComplianceWrapper` emergency path |
| AI consent middleware | ✅ Pass | `requireMobileAiConsent` on AI + voice routes |
| Consent tracking | ✅ Pass | `LegalConsentEvent`, `MobileUserSettings` |
| Counsel sign-off | ❌ Fail | G-L14 open ([legal-compliance-implementation-report.md](./legal-compliance-implementation-report.md)) |
| Play Data Safety | ❌ Fail | Not completed |
| API contract ETA examples | ⚠️ Warn | `API_CONTRACT_V1.md` §12 still aspirational |

**Compliance score: 71 / 100**

---

## 5. Operational Results

| Area | Status | Evidence |
|------|--------|----------|
| Closed beta launch plan | ✅ Pass | [closed-beta-launch-plan.md](./closed-beta-launch-plan.md) |
| Beta operations runbook | ✅ Pass | [beta-operations-runbook.md](./beta-operations-runbook.md) |
| Beta support playbook | ✅ Pass | [beta-support-playbook.md](./beta-support-playbook.md) |
| Beta success metrics | ✅ Pass | [beta-success-metrics.md](./beta-success-metrics.md) |
| Launch day runbook | ✅ Pass | [LAUNCH_DAY_RUNBOOK.md](./LAUNCH_DAY_RUNBOOK.md) |
| Incident response guide | ✅ Pass | [incident-response-guide.md](../incident-response-guide.md) |
| On-call roster | ❌ Fail | Placeholder — not in repo/wiki |
| Payment reconciliation SOP | ❌ Fail | CB-P0-12 open |
| AI emergency runbook | ✅ Pass | `pranidoctor-backend/docs/operations/ai-emergency-runbook.md` |
| Kill switch staging drills M1–M10 | ❌ Fail | [ai-kill-switch-verification-report.md](../../pranidoctor-web/docs/launch/ai-kill-switch-verification-report.md) — 0/10 manual |

**Operational score: 54 / 100**

---

## 6. Doctor Readiness Validation

| Check | Status | Evidence |
|-------|--------|----------|
| Admin doctor CRUD / verify | ✅ Pass | `/admin/doctors`, verify/approve APIs |
| Doctor web panel | ✅ Pass | `/doctor` accept/reject/complete |
| Beta doctor tagging API | ✅ Pass | `POST /api/admin/launch/beta-doctors/:id/tag` |
| 3–5 pilot doctors onboarded on host | ❌ Fail | CB-P0-13 — not evidenced |
| `acceptsEmergency` controls | ✅ Pass | `DoctorProfile.acceptsEmergency` + admin APIs |
| Doctor communication channel | ⚠️ Partial | `doctorSupportWhatsapp` in config; not populated |
| Doctor onboarding SOP | ⚠️ Partial | Described in beta-operations-runbook; not signed externally |

**Doctor readiness score: 58 / 100**

---

## 7. Metrics Validation

| Check | Status | Evidence |
|-------|--------|----------|
| Beta dashboard API | ✅ Pass | `GET /api/admin/launch/beta-dashboard` |
| Launch ops UI | ✅ Pass | `/admin/launch-ops` — probes + beta tiles + compliance panel |
| Admin analytics (SR, farmers, doctors) | ✅ Pass | `/admin/analytics/*`, dashboard page-data |
| AI usage metrics | ✅ Pass | DB + Prometheus `ai_*` series |
| KPI targets documented | ✅ Pass | [beta-success-metrics.md](./beta-success-metrics.md) |
| External alert coverage live | ❌ Fail | Uptime/webhook/Sentry not on prod |
| Beta feedback → ticket pipeline | ✅ Pass | `POST /api/mobile/feedback/beta` → `[Beta Feedback]` prefix |
| Weekly reporting template | ✅ Pass | beta-success-metrics §9 |

**Metrics score: 78 / 100**

---

## 8. User Experience Validation

| Check | Status | Evidence |
|-------|--------|----------|
| OTP → profile onboarding | ✅ Pass (code) | Auth + profile completion flow |
| Closed beta banner | ✅ Pass | `ClosedBetaBanner` + `app-config.closedBeta` |
| Beta access gate messaging | ✅ Pass | `CLOSED_BETA_INVITE_REQUIRED`, `CLOSED_BETA_USER_CAP` |
| In-app support + help | ✅ Pass | Support tickets + help API |
| Beta feedback API | ✅ Pass | `submitBetaFeedback()` + backend route |
| Error handling / crash hooks | ✅ Pass | Global error handler + composite crash reporter |
| Push notifications | ❌ Fail | FCM not configured — waiver for beta |
| BN localization (secondary) | ⚠️ Partial | Critical flows improved; ~430 keys mixed EN |

**UX score: 74 / 100**

---

## 9. Closed Beta Framework Verification

| Component | Status | Location |
|-----------|--------|----------|
| Config store `launch.closedBeta.config` | ✅ | `closed-beta-config.service.ts` |
| OTP invite/cap enforcement | ✅ | `closed-beta-access.service.ts` |
| Auto-tag on first login | ✅ | `mobile-otp-auth.service.ts` |
| Admin config/dashboard/tag APIs | ✅ | `routes/admin/launch/*` |
| Mobile beta status + feature flags | ✅ | `/api/mobile/launch/beta-status`, `/api/mobile/feature-flags` |
| Seed defaults (disabled) | ✅ | `prisma/seed-demo.ts` |
| Unit tests | ✅ | 4/4 config parse tests |

---

## 10. Findings

### Strengths

1. **Closed-beta control plane** — config, caps, invite list, tagging, dashboard, and feedback pipeline are production-safe and backward-compatible (disabled by default).
2. **Test stability (web)** — 109/109 vitest pass; admin launch-ops integrates beta + compliance panels.
3. **Legal-safe messaging P0** — ETA strings removed from Instant Care; admin CMS validator + AI output stripping shipped.
4. **AI governance** — PostgreSQL-backed kill switch; orchestrator choke point; 12/12 governance unit tests.
5. **Monitoring instrumentation** — metrics, health, webhook alert code, Prometheus rules, Grafana JSON (ops deploy pending).
6. **Operational documentation** — runbooks, checklists, support playbook, and metrics targets are complete for beta ops.

### Gaps

1. **No live infrastructure proof** — TLS, deploy, backups, restore drill unverified.
2. **No external observability on prod** — uptime, Sentry, webhook not confirmed receiving.
3. **Live SMS and device E2E** — OTP on real carriers and full farmer→doctor loop not executed.
4. **Pilot doctors not seeded on target host** — tagging API exists; cohort empty until ops runs.
5. **Backend test regressions** — 5 failures in AI usage verify (logger initialization); non-blocking but should be tracked.
6. **Legal counsel + live URL verification** — repo docs strong; external sign-off and DNS not done.

---

## 11. Failed Checks

| ID | Check | Severity | Blocks beta? |
|----|-------|----------|--------------|
| FC-01 | Production/staging VPS + TLS live | P0 | **Yes** (real users off localhost) |
| FC-02 | DB backup cron + first backup file | P0 | **Yes** |
| FC-03 | Live SMS OTP (3+ carriers) | P0 | **Yes** |
| FC-04 | E2E smoke OTP → doctor complete (2 devices) | P0 | **Yes** |
| FC-05 | External uptime on `/ready` + BFF | P0 | **Yes** |
| FC-06 | Sentry/webhook test exception on host | P0 | **Yes** |
| FC-07 | On-call roster documented | P0 | **Yes** |
| FC-08 | 3–5 pilot doctors onboarded | P0 | **Yes** (for doctor loop) |
| FC-09 | Kill switch M1/M3/M4 staging drill | P0 | **Yes** |
| FC-10 | Legal counsel sign-off + live privacy URL | P0 | **Yes** (external users) |
| FC-11 | Play closed testing track + AAB | P1 | Yes for Play distribution |
| FC-12 | Backend 5 test failures (AI usage verify) | P2 | No |
| FC-13 | Flutter 10 test failures (goldens) | P2 | No (with QA waiver) |
| FC-14 | FCM push | P1 | No (with waiver) |

---

## 12. Remaining Risks

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| R-01 | Outage undetected | High | Critical | FC-05, FC-06 before C1 |
| R-02 | Data loss (no backup cron) | Medium | Critical | FC-02 |
| R-03 | OTP failure on real networks | Medium | High | FC-03 |
| R-04 | Manual assign bottleneck | High | Medium | Ops on-call; cap at 25 users |
| R-05 | Doctor no-show / slow accept | Medium | High | WhatsApp ops group; 3–5 vetted doctors |
| R-06 | AI harmful output | Low | High | Kill switch; escalation queue |
| R-07 | Support overload | Medium | Medium | C0→C1 ramp; 72h triage SLA |
| R-08 | Compliance doc vs live CMS drift | Low | Medium | Launch ops compliance panel review |

---

## 13. Recommended Fixes

### P0 — Before first external user (C1)

| # | Action | Owner | Exit criteria |
|---|--------|-------|---------------|
| 1 | Provision staging/production VPS + TLS | DevOps | `curl https://api.<host>/ready` → 200 |
| 2 | Install backup cron; verify file | DevOps | Backup < 24h old |
| 3 | Deploy stack; record rollback tag | DevOps | LAUNCH_DAY_RUNBOOK T-24h |
| 4 | `OTP_MODE=live`; test 3 SMS numbers | Backend/Ops | Delivery log |
| 5 | Run E2E smoke on 2 Android devices | QA | Signed report |
| 6 | Configure uptime + Sentry/webhook | Ops | Test alert received |
| 7 | Document on-call roster | Launch lead | Wiki link |
| 8 | Onboard 3–5 doctors; tag via beta API | Product | Admin list + tags |
| 9 | Kill switch M1/M3 on staging | Backend/Ops | Drill log |
| 10 | Legal counsel sign-off; privacy URL 200 | Legal/Ops | External record |

### P1 — Before expanding to 50 users

| # | Action |
|---|--------|
| 11 | Play closed testing track + policy URLs |
| 12 | Payment reconciliation SOP published |
| 13 | Complete kill switch M4–M10 |
| 14 | Fix backend AI usage verify test logger init |
| 15 | BN `homeInstantCareSubtitle` parity |

### P2 — Post-beta

| # | Action |
|---|--------|
| 16 | Prometheus + Grafana on VPS |
| 17 | FCM or permanent push-off decision |
| 18 | Admin support ticket desk UI |

---

## 14. Go / No-Go Decision Matrix

| Scenario | Verdict |
|----------|---------|
| **C0 internal (5–10, staging host, engineers only)** | **GO WITH CONDITIONS** after P0 items 1, 5, 6 (minimal), 7 |
| **C1 friendly (10–15 real farmers)** | **GO WITH CONDITIONS** after **all P0** (§13) |
| **50 users** | **GO WITH CONDITIONS** after 7-day metrics + P1 |
| **100+ users** | **NO GO** |
| **Public production Play track** | **NO GO** |

---

## 15. Evidence Index

| Artifact | Path |
|----------|------|
| Closed beta plan | `docs/launch/closed-beta-launch-plan.md` |
| Closed beta checklist | `docs/launch/closed-beta-checklist.md` |
| Beta framework (backend) | `pranidoctor-backend/src/shared/launch/` |
| Launch ops UI | `pranidoctor-web/src/app/admin/(dashboard)/launch-ops/page.tsx` |
| Production readiness (2026-05-29) | `docs/launch/PRODUCTION_READINESS_REPORT.md` |
| Monitoring verification | `docs/launch/production-monitoring-verification-report.md` |
| Legal messaging verification | `docs/launch/legal-safe-messaging-verification-report.md` |
| AI kill switch verification | `pranidoctor-web/docs/launch/ai-kill-switch-verification-report.md` |
| Legal compliance report | `docs/launch/legal-compliance-implementation-report.md` |

---

## 16. Sign-Off

| Role | Name | Date | Verdict |
|------|------|------|---------|
| Launch lead | | | GO WITH CONDITIONS / NO GO |
| Engineering | | | |
| Product | | | |
| Legal | | | |
| DevOps | | | |

---

**Official status as of 2026-06-01:** **GO WITH CONDITIONS** for controlled closed beta at **≤ 25 users** after P0 ops closure. **NOT GO** for 100, 250, or 500 user cohorts.

*Re-run this report after staging burn-in and P0 checklist completion to update scores and verdict.*
