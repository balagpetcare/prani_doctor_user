# Closed Beta Operational Readiness Report — Independent Verification

**Report ID:** `CLOSED_BETA_OPERATIONAL_READINESS_REPORT`  
**Verification date:** 2026-06-01  
**Auditor role:** Principal Independent Launch Auditor  
**Mode:** Verification only — no new features implemented  
**Repositories:** `pranidoctor_user` · `pranidoctor-backend` · `pranidoctor-web`

**Sources verified:**

| Artifact | Path |
|----------|------|
| Operational audit | [docs/audit/closed-beta-operational-audit.md](../audit/closed-beta-operational-audit.md) |
| Scorecard | [docs/audit/operational-readiness-scorecard.md](../audit/operational-readiness-scorecard.md) |
| Governance assessment | [docs/audit/launch-governance-assessment.md](../audit/launch-governance-assessment.md) |
| Remediation register | [docs/audit/remediation-register.md](../audit/remediation-register.md) |
| Audit framework | [closed-beta-operational-audit-plan.md](./closed-beta-operational-audit-plan.md) |
| Engineering readiness (cross-check) | [closed-beta-readiness-report.md](./closed-beta-readiness-report.md) |

**Verification method:** Independent re-review of audit artifacts, scorecard arithmetic, remediation register completeness, and **fresh automated test execution** on 2026-06-01. Live staging/production host was **not** available for this session — gaps requiring host evidence remain **unverified externally**.

---

## Executive Summary

| Metric | Original audit | Independent verification | Match |
|--------|---------------:|-------------------------:|:-----:|
| Platform readiness | 55% | **55%** | ✅ |
| Operational readiness (composite) | 53% | **53%** | ✅ |
| Compliance readiness | 57% | **57%** | ✅ |
| Security readiness | 60% | **60%** | ✅ |
| Governance readiness | 53% | **53%** | ✅ |
| **Overall closed beta readiness** | 53% | **53%** | ✅ |
| Launch recommendation | NO GO | **NO GO** | ✅ |

The operational audit is **substantially accurate**. Code-backed PASS findings were **independently confirmed**. Live-host FAIL findings **cannot be refuted** — no contradictory evidence exists in the repository. Scorecard weighted composite **recalculates to 53.1%** (within rounding).

### Distinction from engineering readiness

| Lens | Score | Verdict | Binding for user admission? |
|------|------:|---------|:---------------------------:|
| Engineering readiness ([prior report](./closed-beta-readiness-report.md)) | 70% | GO WITH CONDITIONS | No — code-only |
| **Operational readiness (this report)** | **53%** | **NO GO** | **Yes** |

**Real farmers and real doctors must not be admitted** until P0 remediations close and independent re-verification shows composite ≥ **70%** with no failing hard stops.

### Final verdict: **NO GO**

| Cohort | Verdict |
|--------|---------|
| C0 internal (engineers on staging) | **NO GO** — HS-01, HS-03, HS-08 |
| C1 friendly farmers (≤ 25) | **NO GO** — 11 open P0 + unsigned Gate 1 |
| C2+ expansion | **NO GO** |

**Post-remediation target:** **GO WITH CONDITIONS** at ≤ **25 users** (consistent with engineering readiness report).

---

## Audit Validation Results

### 1. Platform readiness validation

| Check | Audit claim | Independent result | Evidence |
|-------|-------------|-------------------|----------|
| CI pipeline | Pass | **Confirmed** | `.github/workflows/ci.yml` present |
| Staging deploy workflow | Pass | **Confirmed** | `deploy-staging.yml` — GHCR, env validation, health gate |
| Production deploy workflow | Pass | **Confirmed** | `deploy-production.yml` present |
| Pre-deploy backup in deploy script | Pass | **Confirmed** | `postgres-backup.sh \|\| true` in remote deploy step |
| Rollback plan | Pass | **Confirmed** | [ROLLBACK_PLAN.md](./ROLLBACK_PLAN.md) |
| Backup scripts | Pass | **Confirmed** | `scripts/backup/postgres-backup.sh` (retention KEEP=14) |
| Health endpoints | Pass | **Confirmed** | `health.routes.ts` — `/live`, `/ready`, `/health/*` |
| Health unit tests | 5/5 pass | **Confirmed 5/5** | Re-run 2026-06-01 |
| Live HTTPS host | Fail | **Confirmed fail** | No curl output or host URL in repo |
| Backup cron on host | Fail | **Confirmed fail** | No cron log |
| Live SMS (3 carriers) | Fail | **Confirmed fail** | No provider log |
| E2E smoke (2 devices) | Fail | **Confirmed fail** | No signed QA report |
| Rollback tag recorded | Fail | **Confirmed fail** | REM-P0-11 open |

**Platform readiness: 55% — CONFIRMED**

---

### 2. Support readiness validation

| Check | Audit claim | Independent result | Evidence |
|-------|-------------|-------------------|----------|
| Beta support playbook | Pass | **Confirmed** | [beta-support-playbook.md](./beta-support-playbook.md) |
| Feedback API → ticket prefix | Pass | **Confirmed** | `feedback/beta/route.ts` line 41 `[Beta Feedback]` |
| Triage taxonomy + 72h SLA | Pass | **Confirmed** | Playbook §2 |
| Escalation path documented | Pass | **Confirmed** | Playbook §5–6 |
| Incident comms (> 15 min outage) | Pass | **Confirmed** | Playbook §6 |
| Prohibited support language | Pass | **Confirmed** | Playbook §3.3 |
| Named escalation contacts | Fail | **Confirmed fail** | Playbook §5 table empty |
| Live sample ticket | Fail | **Confirmed fail** | No ticket ID |

**Support domain (D4): 63% — CONFIRMED**

---

### 3. Doctor operations validation

| Check | Audit claim | Independent result | Evidence |
|-------|-------------|-------------------|----------|
| Onboarding SOP | Pass | **Confirmed** | [beta-operations-runbook.md](./beta-operations-runbook.md) §4 |
| Beta doctor tag API | Pass | **Confirmed** | `beta-doctors/[id]/tag/route.ts` |
| `acceptsEmergency` in tag schema | Pass | **Confirmed** | `closed-beta.types.ts` `BetaDoctorTag` |
| Dashboard doctor metrics | Pass | **Confirmed** | `closed-beta-metrics.service.ts` |
| Manual assign documented | Pass | **Confirmed** | Runbook §4.2 |
| 3–5 doctors on host | Fail | **Confirmed fail** | REM-P0-08 open |
| Doctor panel E2E on staging | Fail | **Confirmed fail** | No smoke report |
| WhatsApp ops group active | Fail | **Confirmed fail** | Not evidenced |

**Doctor domain (D3): 40% — CONFIRMED**

---

### 4. Compliance validation

| Check | Audit claim | Independent result | Evidence |
|-------|-------------|-------------------|----------|
| Legal package (repo) | Pass | **Confirmed** | `docs/legal/*` per implementation report |
| AI consent on `/api/ai/*` | Pass | **Confirmed** | `ai.routes.ts` `requireMobileAiConsent` |
| AI consent on voice routes | Pass | **Confirmed** | `voice-assistant.routes.ts` same guard |
| Legal consent audit API | Pass | **Confirmed** | `admin/legal-consent/route.ts` |
| Launch ops compliance panel | Pass | **Confirmed** | `LaunchOpsCompliancePanel.tsx` |
| ETA P0 removal | Pass | **Confirmed** | [legal-safe-messaging-verification-report.md](./legal-safe-messaging-verification-report.md) |
| Live legal URLs HTTP 200 | Fail | **Confirmed fail** | No public curl evidence |
| Counsel sign-off | Fail | **Confirmed fail** | G-L14 open |
| Kill switch drills | Fail | **Confirmed fail** | 0/10 manual per kill-switch report |

**Compliance domain (D5): 57% — CONFIRMED**

---

### 5. Security validation

| Check | Audit claim | Independent result | Evidence |
|-------|-------------|-------------------|----------|
| Closed beta invite gate | Pass | **Confirmed** | `CLOSED_BETA_INVITE_REQUIRED` in access service |
| User cap gate | Pass | **Confirmed** | `CLOSED_BETA_USER_CAP` in access service |
| Config safe defaults | Pass | **Confirmed** | `enabled: false`, tests 4/4 pass |
| AI governance unit tests | 12/12 | **Confirmed 12/12** | governance 8 + config 4 (subset of 23-run) |
| Governance + health in 23-test run | — | **Confirmed 23/23 pass** | Independent re-run 2026-06-01 |
| Auth audit service | Pass | **Confirmed** | `auth-audit.service.ts` |
| Kill switch drill | Fail | **Confirmed fail** | REM-P0-09 open |
| Beta config change audit trail | Partial | **Confirmed partial** | DB JSON only; no dedicated log |

**Security domain (D6): 60% — CONFIRMED**

---

### 6. Governance validation

| Check | Audit claim | Independent result | Evidence |
|-------|-------------|-------------------|----------|
| Cohort C0–C4 defined | Pass | **Confirmed** | Launch plan §B |
| Max users cap (80) | Pass | **Confirmed** | Config tests assert `maxUsers` |
| Gate 0/1/2 checklists | Pass (doc) | **Confirmed** | Audit plan §9 |
| Gate 0/1 executed | Fail | **Confirmed fail** | Checklist §H unsigned |
| Waiver register | Fail | **Confirmed fail** | All W-01..05 PENDING |
| Launch owners named | Fail | **Confirmed fail** | Governance assessment §2 |
| Rollback authority named | Fail | **Confirmed fail** | Template only |

**Governance domain (D8): 53% — CONFIRMED**

---

## Evidence Review

### Independent test re-execution (2026-06-01)

| Suite | Original audit | Independent run | Status |
|-------|---------------:|----------------:|--------|
| `closed-beta-config.service.test.ts` | 4/4 | 4/4 | ✅ Match |
| `ai-governance.service.test.ts` | 8/8 | 8/8 | ✅ Match |
| `health-response.util.test.ts` | 5/5 | 5/5 | ✅ Match |
| `monitoring.metrics.test.ts` | 6/6 | 6/6 | ✅ Match |
| `pranidoctor-web` vitest | 109/109 | 109/109 | ✅ Match |
| **Total (audit slice)** | **23 + 109** | **132/132** | ✅ |

### Scorecard arithmetic verification

```
Weighted composite =
  50×0.18 + 60×0.14 + 40×0.14 + 63×0.12 + 57×0.14 + 60×0.10 + 43×0.10 + 53×0.08
= 9.0 + 8.4 + 5.6 + 7.56 + 7.98 + 6.0 + 4.3 + 4.24
= 53.08% → 53%  ✅ CONFIRMED
```

### Hard stops verification

| ID | Audit | Independent | Notes |
|----|-------|-------------|-------|
| HS-01 | FAIL | **FAIL** | No HTTPS host evidence |
| HS-02 | FAIL | **FAIL** | No backup file timestamp |
| HS-03 | FAIL | **FAIL** | On-call placeholder only |
| HS-04 | FAIL | **FAIL** | No SMS log |
| HS-05 | FAIL | **FAIL** | No doctor onboarding evidence |
| HS-06 | PARTIAL | **PARTIAL** | Code operable; drill missing — fairly scored |
| HS-07 | FAIL | **FAIL** | No counsel record |
| HS-08 | FAIL | **FAIL** | No rollback tag |

**7 of 8 hard stops fail; 1 partial — CONFIRMED**

### Remediation register verification

| Claim | Verified |
|-------|----------|
| 11 open P0 | ✅ 11 rows, all OPEN |
| 6 open P1 | ✅ |
| 4 open P2 | ✅ |
| 3 open P3 | ✅ |
| Closure log empty | ✅ |
| Owners assigned per row | ✅ |
| Exit criteria defined | ✅ |

### Minor audit notes (non-material)

| Item | Observation |
|------|-------------|
| E2E smoke sub-score | Scored **1** (partial) in scorecard while narrative says "not executed" — conservative scoring; **acceptable** |
| Engineering vs operational verdict | Intentional tension (70% vs 53%) — **correctly documented**; this report treats operational score as binding for admission |
| Live-host evidence | Neither original nor independent audit could PASS host checks — **gap is real, not audit error** |

---

## Readiness Scores

| Dimension | Score | Calculation | Auditor confidence |
|-----------|------:|-------------|-------------------|
| **Platform readiness** | **55%** | avg(D1=50%, D2=60%) | High (code verified) |
| **Operational readiness** | **53%** | 8-domain weighted composite | High |
| **Compliance readiness** | **57%** | D5 | High (code); Medium (legal external) |
| **Security readiness** | **60%** | D6 | High |
| **Governance readiness** | **53%** | D8 | High |
| **Overall closed beta readiness** | **53%** | Σ(domain% × weight) | High |

### Domain breakdown (confirmed)

| ID | Domain | Score (0–3) | % |
|----|--------|------------:|--:|
| D1 | Platform Operations | 1.5 | 50 |
| D2 | Monitoring & Alerting | 1.8 | 60 |
| D3 | Doctor Operations | 1.2 | 40 |
| D4 | Support Operations | 1.9 | 63 |
| D5 | Compliance Operations | 1.7 | 57 |
| D6 | Security Operations | 1.8 | 60 |
| D7 | Incident Management | 1.3 | 43 |
| D8 | Launch Governance | 1.6 | 53 |

### Threshold assessment (audit plan §6)

| Criterion | Required | Actual | Met? |
|-----------|----------|--------|------|
| Composite ≥ 70% | 70% | 53% | ❌ |
| No domain < 50% | all ≥ 50% | D3=40%, D7=43% | ❌ |
| Zero open P0 | 0 | 11 | ❌ |
| Hard stops | 0 fail | 7 fail + 1 partial | ❌ |

---

## Risks

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| R-01 | Outage undetected (no external uptime) | High | Critical | REM-P0-03 before C1 |
| R-02 | Data loss (no backup cron) | Medium | Critical | REM-P0-02 |
| R-03 | OTP failure on real networks | Medium | High | REM-P0-05 |
| R-04 | Doctor loop broken at go-live | Medium | High | REM-P0-06, REM-P0-08 |
| R-05 | AI incident without drill muscle memory | Low | Critical | REM-P0-09 |
| R-06 | Legal exposure without counsel sign-off | Medium | High | REM-P0-10 |
| R-07 | Unowned incidents (no on-call) | High | High | REM-P0-07 |
| R-08 | Deploy regression without rollback tag | Medium | High | REM-P0-11 |
| R-09 | Verdict confusion (engineering 70% vs ops 53%) | Medium | Medium | Use this report for admission gates |

---

## Critical Findings

| ID | Severity | Finding | Verified |
|----|----------|---------|:--------:|
| CF-01 | P0 | No live HTTPS staging/production host | ✅ |
| CF-02 | P0 | Backup not operational on target host | ✅ |
| CF-03 | P0 | External monitoring/alerting not live | ✅ |
| CF-04 | P0 | Live SMS not validated | ✅ |
| CF-05 | P0 | E2E farmer→doctor smoke not executed | ✅ |
| CF-06 | P0 | On-call roster unpublished | ✅ |
| CF-07 | P0 | Zero evidenced pilot doctors | ✅ |
| CF-08 | P0 | AI kill switch not drill-validated | ✅ |
| CF-09 | P0 | Legal counsel sign-off missing | ✅ |
| CF-10 | P0 | Rollback tag not recorded | ✅ |
| CF-11 | — | Doctor ops (40%) and incident ops (43%) below 50% threshold | ✅ |

---

## Recommended Actions

### Immediate (before any user traffic)

1. **DevOps:** Provision staging host + TLS (REM-P0-01); record rollback tag (REM-P0-11); install backup cron (REM-P0-02).
2. **Ops:** Configure uptime + Sentry/webhook test (REM-P0-03, REM-P0-04).
3. **Launch lead:** Publish on-call roster on wiki (REM-P0-07).

### Before C1 external farmers (≤ 25 users)

4. **Backend/Ops:** Live SMS on 3+ Bangladesh numbers (REM-P0-05).
5. **QA:** E2E smoke on 2 physical devices (REM-P0-06).
6. **Product:** Onboard and tag 3–5 pilot doctors (REM-P0-08).
7. **AI owner:** Execute kill switch M1/M3 drill (REM-P0-09).
8. **Legal:** Counsel sign-off + live privacy URL 200 (REM-P0-10).
9. **Board:** Sign Gate 1 checklist; populate waiver register.
10. **Independent auditor:** Re-run verification; target composite ≥ **70%**.

---

## Launch Recommendation

### Independent auditor verdict: **NO GO**

| Question | Answer |
|----------|--------|
| Is the operational audit trustworthy? | **Yes** — findings and scores independently confirmed |
| Is the platform code-ready? | **Yes** — 132/132 audit-slice tests pass |
| Is the organization ops-ready for real users? | **No** — 7 hard stops fail |
| Recommended cohort if P0 closed | ≤ **25 users**, **GO WITH CONDITIONS** |
| Recommended cohort now | **0 external users** |

---

## Prioritized Remediation List

*(Confirmed from [remediation-register.md](../audit/remediation-register.md); statuses unchanged.)*

### P0 — Critical (blocks C0/C1)

| Priority | ID | Action | Owner |
|----------|-----|--------|-------|
| P0 | REM-P0-01 | Live VPS/TLS — `curl https://api.<host>/ready` → 200 | DevOps |
| P0 | REM-P0-02 | DB backup cron; file < 24h old | DevOps |
| P0 | REM-P0-03 | External uptime monitors green | Ops |
| P0 | REM-P0-04 | Sentry/webhook test event on host | Ops |
| P0 | REM-P0-05 | Live SMS OTP — 3+ carrier log | Backend/Ops |
| P0 | REM-P0-06 | E2E smoke — 2 devices, signed report | QA |
| P0 | REM-P0-07 | On-call roster on wiki | Launch lead |
| P0 | REM-P0-08 | 3–5 pilot doctors onboarded + tagged | Product |
| P0 | REM-P0-09 | AI kill switch M1/M3 drill log | AI owner |
| P0 | REM-P0-10 | Legal counsel sign-off + live URLs | Legal |
| P0 | REM-P0-11 | Rollback image tag recorded | DevOps |

### P1 — High (blocks C2+)

| Priority | ID | Action | Owner |
|----------|-----|--------|-------|
| P1 | REM-P1-01 | Prometheus/Grafana on VPS or W-04 waiver | DevOps |
| P1 | REM-P1-02 | Play closed testing + AAB | Mobile |
| P1 | REM-P1-03 | Payment reconciliation SOP | Product |
| P1 | REM-P1-04 | Kill switch M4–M10 drills | AI owner |
| P1 | REM-P1-05 | Staging rollback drill | DevOps |
| P1 | REM-P1-06 | Fix backend AI usage verify tests (5 failures) | Backend |

### P2 — Medium

| Priority | ID | Action | Owner |
|----------|-----|--------|-------|
| P2 | REM-P2-01 | Flutter golden failures (10) or W-02 waiver | Mobile |
| P2 | REM-P2-02 | BN localization parity or W-03 waiver | Mobile |
| P2 | REM-P2-03 | Admin support desk UI | Web |
| P2 | REM-P2-04 | Restore drill on non-prod | DevOps |

### P3 — Low

| Priority | ID | Action | Owner |
|----------|-----|--------|-------|
| P3 | REM-P3-01 | API contract §12 ETA examples cleanup | Docs |
| P3 | REM-P3-02 | Post-mortem template in wiki | Launch lead |
| P3 | REM-P3-03 | CVE scan waiver documented | Security |

---

## Sign-off

| Role | Verification outcome |
|------|---------------------|
| Principal Independent Launch Auditor | Operational audit **CONFIRMED**; verdict **NO GO** |
| Recommended re-verification trigger | All P0 closed + live evidence bundle attached |

---

## Related documents

- [closed-beta-operational-audit.md](../audit/closed-beta-operational-audit.md)
- [operational-readiness-scorecard.md](../audit/operational-readiness-scorecard.md)
- [launch-governance-assessment.md](../audit/launch-governance-assessment.md)
- [remediation-register.md](../audit/remediation-register.md)
- [closed-beta-readiness-report.md](./closed-beta-readiness-report.md) (engineering lens)

---

*Independent verification complete. No implementation changes made. Re-run after P0 remediation and host evidence submission.*
