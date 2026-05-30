# Beta Success Metrics — Prani Doctor

**Document ID:** `BETA_SUCCESS_METRICS`  
**Version:** 1.0  
**Date:** 2026-05-30  
**Measurement window:** Closed beta days 1–14 (extend at day-7 review)  
**Companion:** [closed-beta-launch-plan.md §G](./closed-beta-launch-plan.md#g-metrics)

---

## 1. How metrics are collected

| Metric family | Source | Access |
|---------------|--------|--------|
| Beta ops snapshot | `GET /api/admin/launch/beta-dashboard` | `/admin/launch-ops` |
| Platform analytics | Admin analytics + dashboard page-data | `/admin/analytics` |
| Reliability | UptimeRobot, Sentry, Crashlytics | External dashboards |
| AI usage | `AiUsageRecord`, Prometheus `ai_*` | `/admin/ai-ops` |
| Feedback | Support tickets `[Beta Feedback]*` | DB / future admin desk |

---

## 2. Success criteria (exit targets)

Aligned with [closed-beta-launch-plan.md §A.4](./closed-beta-launch-plan.md#a4-success-criteria-closed-beta).

| ID | Metric | Target | Window |
|----|--------|--------|--------|
| SC-01 | Core loop completion rate | ≥ 60% submitted → `COMPLETED` | Days 1–14 |
| SC-02 | OTP success rate | ≥ 95% | Launch week |
| SC-03 | API availability (synthetic) | ≥ 99.5% | Launch week |
| SC-04 | Crash-free sessions | ≥ 99.0% | 7-day rolling |
| SC-05 | Doctor accept rate (within 4h of assign) | ≥ 70% | Days 1–14 |
| SC-06 | SEV-1 unresolved > 2h | 0 | Launch week |
| SC-07 | Compliance P0 checklist | 100% | Pre-launch |
| SC-08 | Pilot doctor retention (active ≥ 4d / 14d) | ≥ 80% | Day 14 |
| SC-09 | Beta feedback triaged | 100% within 72h | Ongoing |
| SC-10 | CRITICAL AI escalation reviewed | 100% within 30 min | Launch week |

---

## 3. Product metrics

### 3.1 Registration & activation

| Metric | Definition | Target | Dashboard field |
|--------|------------|--------|-----------------|
| **Activation rate** | Profile complete + ≥1 animal within 72h of OTP | ≥ 70% | `activatedLast7Days` / registrations |
| **Registration completion** | OTP verify → home | ≥ 90% | Auth audit / analytics |
| **First request rate** | Activated users with ≥1 SR in 14d | ≥ 50% | Analytics SR count |
| **D7 retention** | App open on day 7 | ≥ 40% | External (Crashlytics) |
| **D14 retention** | App open on day 14 | ≥ 30% | Analytics |

### 3.2 Consultation & emergency

| Metric | Definition | Target | Dashboard field |
|--------|------------|--------|-----------------|
| **Completion rate** | `COMPLETED` / all SRs | ≥ 60% (SC-01) | `completionRatePct` |
| **Pending backlog** | Non-terminal SRs | Trend down | `consultations.pending` |
| **Emergency SR count** | Type `EMERGENCY_DOCTOR` | Track baseline | `emergencyRequests` |
| **Emergency workflow success** | Emergency SR assigned + accepted | ≥ 60% | Manual cohort review |

*Note: Success = workflow completed, not clinical outcome or arrival time.*

---

## 4. Doctor metrics

| Metric | Definition | Target |
|--------|------------|--------|
| **Doctor response rate** | Accepted within 4h / assigned | ≥ 70% |
| **Time to accept (p50)** | Assign → accept | < 2h (pilot hours) |
| **Rejection rate** | Rejected / assigned | < 15% |
| **Beta doctors tagged** | C3 cohort | 3–5 |
| **Active doctor days** | Login ≥ 4 days in 14 | ≥ 80% of C3 |

---

## 5. Reliability metrics

| Metric | Target | Tool |
|--------|--------|------|
| API 5xx rate | < 0.5% | Prometheus / logs |
| `/ready` uptime | ≥ 99.5% | UptimeRobot |
| OTP failure rate | < 5% | Backend logs |
| Crash-free sessions | ≥ 99% | Crashlytics / Sentry |
| Offline sync success | ≥ 95% | Support tickets + logs |

---

## 6. AI metrics

| Metric | Definition | Target / note |
|--------|------------|---------------|
| **AI adoption** | MAU using ≥1 AI feature | Track baseline |
| **Sessions (7d)** | `AiAssistantSession` count | Dashboard `ai.sessionsLast7Days` |
| **Fallback rate** | Rules-only / LLM attempts | < 20% unless kill switch |
| **LLM disabled** | Kill switch active | 0 unplanned |
| **Open escalations** | PENDING_REVIEW + QUEUED | Review SLAs (SC-10) |
| **Consent acceptance** | Current `aiAcceptedVersion` | ≥ 99% |

---

## 7. Support & feedback metrics

| Metric | Target | Source |
|--------|--------|--------|
| Feedback submissions / WAU | Track | `betaFeedbackTicketsLast7Days` |
| Triage SLA | 100% in 72h | Product tracker |
| Open P0 bugs at day 7 | 0 | Issue tracker |
| Avg beta satisfaction (1–5) | Track | Feedback API optional `rating` |

---

## 8. Review cadence

| When | Review | Output |
|------|--------|--------|
| **Daily** (launch week) | Launch ops dashboard | Slack summary |
| **Day 7** | All §2 criteria | Continue / pause / adjust cohort |
| **Day 14** | Exit criteria (plan §A.5) | Graduate to open beta prep or extend |

---

## 9. Reporting template (weekly)

```markdown
## Beta week N summary

- Cohort: C_
- Beta users tagged: _ / 80
- Registrations (7d): _
- Activations (7d): _
- SR completion rate: _%
- Crash-free: _%
- Open P0: _
- Top 3 issues: 1) … 2) … 3) …
- Decision: continue / pause / expand
```

---

*Update targets after baseline week if sample size is small (< 20 active users).*
