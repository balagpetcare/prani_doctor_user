# Operational Readiness Scorecard — Closed Beta

**Document ID:** `OPERATIONAL_READINESS_SCORECARD`  
**Audit date:** 2026-06-01  
**Method:** Static verification + automated tests (no live host, no destructive drills)  
**Framework:** [closed-beta-operational-audit-plan.md](../launch/closed-beta-operational-audit-plan.md) §5  
**Full audit:** [closed-beta-operational-audit.md](./closed-beta-operational-audit.md)

---

## Scoring scale

| Score | Label | Definition |
|------:|-------|------------|
| 0 | Missing | No artifact, no owner, or control untested |
| 1 | Partial | Artifact exists; localhost-only or unverified on host |
| 2 | Functional | Control verified in code/CI; minor live-host gaps |
| 3 | Production ready | Live host tested, staffed, drill-evidenced |

**Domain %** = `(domain_score ÷ 3) × 100`

---

## Domain scorecard (D1–D8)

| ID | Domain | Score (0–3) | % | Weight | Weighted % | Verdict |
|----|--------|------------:|--:|-------:|-----------:|---------|
| D1 | Platform Operations | **1.5** | 50 | 18% | 9.0 | Partial |
| D2 | Monitoring & Alerting | **1.8** | 60 | 14% | 8.4 | Partial |
| D3 | Doctor Operations | **1.2** | 40 | 14% | 5.6 | Partial |
| D4 | Support Operations | **1.9** | 63 | 12% | 7.6 | Functional |
| D5 | Compliance Operations | **1.7** | 57 | 14% | 8.0 | Partial |
| D6 | Security Operations | **1.8** | 60 | 10% | 6.0 | Partial |
| D7 | Incident Management | **1.3** | 43 | 10% | 4.3 | Partial |
| D8 | Launch Governance | **1.6** | 53 | 8% | 4.2 | Partial |
| | **Composite operational readiness** | — | **53** | **100%** | **53.1** | **NO GO** |

---

## Aggregate scores (requested dimensions)

| Dimension | Formula | Score | Interpretation |
|-----------|---------|------:|----------------|
| **Platform** | avg(D1, D2) | **55%** | Deploy/monitoring code strong; live host unproven |
| **Operations** | 0.35×D1 + 0.35×D3 + 0.30×D7 | **44%** | Doctor loop + incident ops not host-validated |
| **Support** | D4 | **63%** | Playbooks + feedback API; staffing/contacts unfilled |
| **Compliance** | D5 | **57%** | Code/CMS strong; counsel + live URLs open |
| **Security** | D6 | **60%** | Kill switch code pass; drills not executed |
| **Governance** | D8 | **53%** | Framework shipped; gates unsigned |

---

## Sub-score detail

### D1 — Platform Operations (1.5)

| Sub-area | Weight | Score | Evidence |
|----------|-------:|------:|----------|
| Host / TLS / deploy | 30% | 1 | `deploy-staging.yml` exists; `deploy_remote` not evidenced |
| Env / DB / migrations | 25% | 2 | `validate:production-env` in CI; migrate in deploy script |
| OTP / SMS live | 25% | 1 | `OTP_MODE=live` in workflow env; no carrier log |
| E2E smoke | 20% | 1 | Not executed; workflows documented |

### D2 — Monitoring & Alerting (1.8)

| Sub-area | Weight | Score | Evidence |
|----------|-------:|------:|----------|
| External uptime | 25% | 0 | Not configured |
| Error ingest | 25% | 1 | Sentry/webhook wired in code; DSN not confirmed live |
| Runbook linkage | 20% | 3 | `runbook.md`, `monitoring-guide.md` complete |
| Beta dashboard | 15% | 2 | `/admin/launch-ops` + metrics service in code |
| Prometheus / Grafana | 15% | 2 | `prometheus-alerts.yml` + dashboards JSON; not scraped live |

### D3 — Doctor Operations (1.2)

| Sub-area | Weight | Score | Evidence |
|----------|-------:|------:|----------|
| Onboarded pilots | 35% | 0 | No host evidence of 3–5 doctors |
| Panel E2E | 25% | 1 | Doctor web APIs exist; staging smoke not run |
| Assignment staffing | 25% | 2 | Manual assign documented in runbook §4 |
| Comms channel | 15% | 1 | Playbook template; contacts unfilled |

### D4 — Support Operations (1.9)

| Sub-area | Weight | Score | Evidence |
|----------|-------:|------:|----------|
| Channels configured | 25% | 1 | Config keys exist; numbers not verified live |
| Feedback pipeline | 25% | 2 | `POST /api/mobile/feedback/beta` → ticket prefix |
| Triage + SLA | 30% | 2 | `beta-support-playbook.md` §2 complete |
| Legal-safe macros | 20% | 2 | EN/BN macros in playbook; no training log |

### D5 — Compliance Operations (1.7)

| Sub-area | Weight | Score | Evidence |
|----------|-------:|------:|----------|
| Live legal URLs | 25% | 1 | Web routes exist; public HTTP not verified |
| Counsel sign-off | 25% | 0 | G-L14 open per legal compliance report |
| AI / emergency CMS | 25% | 2 | LaunchOpsCompliancePanel; legal messaging P0 pass |
| Consent enforcement | 25% | 3 | `requireMobileAiConsent` on AI + voice; audit API |

### D6 — Security Operations (1.8)

| Sub-area | Weight | Score | Evidence |
|----------|-------:|------:|----------|
| Kill switch drill | 30% | 1 | 12/12 unit tests; 0/10 manual drills |
| Beta access gates | 25% | 2 | `assertClosedBetaPhoneAccess`; 4/4 config tests |
| Secrets / admin RBAC | 25% | 2 | Env validation; JWT secrets required in CI |
| Auth incident path | 20% | 2 | `incident-response-guide.md` §Auth compromise |

### D7 — Incident Management (1.3)

| Sub-area | Weight | Score | Evidence |
|----------|-------:|------:|----------|
| On-call roster | 30% | 0 | Placeholder in playbook §5 |
| SEV playbooks | 25% | 2 | SEV-1/2/3 in incident guide |
| Rollback drill | 25% | 1 | `ROLLBACK_PLAN.md` complete; not exercised |
| Post-mortem process | 20% | 2 | 72h requirement documented |

### D8 — Launch Governance (1.6)

| Sub-area | Weight | Score | Evidence |
|----------|-------:|------:|----------|
| Cohort / cap controls | 30% | 2 | `maxUsers: 80`; disabled by default |
| Gate checklists | 25% | 1 | `closed-beta-checklist.md` exists; unsigned |
| Waiver register | 20% | 1 | Defined in plan; not populated |
| Sign-off matrix | 25% | 1 | Template only |

---

## Hard stops (automatic NO GO)

| ID | Condition | Status |
|----|-----------|--------|
| HS-01 | Live HTTPS host for API + admin | **FAIL** |
| HS-02 | Backup within 24h on target host | **FAIL** |
| HS-03 | On-call roster published | **FAIL** |
| HS-04 | Live SMS tested (C1) | **FAIL** |
| HS-05 | Pilot doctors onboarded on host | **FAIL** |
| HS-06 | AI kill switch operable by owner | **PARTIAL** (code yes; drill no) |
| HS-07 | Legal counsel sign-off | **FAIL** |
| HS-08 | Rollback tag recorded | **FAIL** |

**Hard stops failing:** 7 / 8 (HS-06 partial)

---

## Threshold assessment

| Criterion | Required | Actual | Met? |
|-----------|----------|--------|------|
| Composite score ≥ 70% | 70% | 53% | **No** |
| No domain < 1.5 (50%) | all ≥ 50% | D3=40%, D7=43% | **No** |
| Zero open P0 with owner | 0 | 11 open | **No** |

**Threshold verdict:** **NO GO** for C1 external users.

---

## Gate checklist summary

| Gate | Pass | Fail | Waived | Ready? |
|------|-----:|-----:|-------:|--------|
| G0 (C0 internal) | 3 | 4 | 0 | **No** — host + on-call |
| G1 (C1 ≤ 25 users) | 2 | 10 | 0 | **No** |
| G2 (C2 expansion) | 0 | 7 | 0 | **No** |

---

## Automated test evidence (2026-06-01)

| Suite | Result | Reference |
|-------|--------|-----------|
| Closed beta config | 4/4 pass | `closed-beta-config.service.test.ts` |
| AI governance | 8/8 pass | `ai-governance.service.test.ts` |
| Health response util | 5/5 pass | `health-response.util.test.ts` |
| Monitoring metrics | 6/6 pass | `monitoring.metrics.test.ts` |
| Web (launch-ops BFF) | 109/109 pass | `pranidoctor-web` vitest |

---

## Launch recommendation

| Cohort | Recommendation |
|--------|----------------|
| C0 internal | **NO GO** until HS-01 + rollback tag + on-call draft |
| C1 friendly (≤ 25) | **NO GO** until all P0 remediations closed + re-audit ≥ 70% |
| C2+ (50 users) | **NO GO** |

**Target after remediation:** **GO WITH CONDITIONS** at ≤ 25 users per [closed-beta-readiness-report.md](../launch/closed-beta-readiness-report.md).

---

*Re-score after live-host evidence bundle attached to remediation register.*
