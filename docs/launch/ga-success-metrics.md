# GA Success Metrics — Prani Doctor

**Document ID:** `GA_SUCCESS_METRICS`  
**Version:** 1.0  
**Date:** 2026-06-01  
**Window:** GA days 1–30 (extend at day-14 review)  
**Companion:** [general-availability-launch-plan.md](./general-availability-launch-plan.md) §G

---

## 1. Collection sources

| Family | Source | Access |
|--------|--------|--------|
| GA ops | `GET /api/admin/launch/ga-dashboard` | `/admin/launch-ops` |
| Readiness | `GET /api/admin/launch/ga-readiness` | Same |
| Analytics | Admin analytics | `/admin/analytics` |
| Reliability | Uptime, Sentry, Prometheus | External links in GA config |
| AI | `ai_*` metrics + admin AI ops | `/admin/ai-ops` |

---

## 2. Success criteria (14-day window)

| ID | Metric | Target |
|----|--------|--------|
| GA-SC-01 | SR completion rate | ≥ **65%** |
| GA-SC-02 | API availability | ≥ **99.9%** monthly |
| GA-SC-03 | Crash-free sessions | ≥ **99.5%** |
| GA-SC-04 | OTP success | ≥ **97%** |
| GA-SC-05 | P0 tickets over SLA | **0** |
| GA-SC-06 | SEV-1 unresolved > 1h | **0** |
| GA-SC-07 | CRITICAL AI escalation reviewed | **100%** < 15 min |
| GA-SC-08 | Compliance P0 | **100%** |
| GA-SC-09 | Doctor accept (2h) | ≥ **75%** |
| GA-SC-10 | Play rating (≥ 50 reviews) | ≥ **4.0** |

---

## 3. Adoption metrics

| Metric | Day 7 | Day 30 |
|--------|------:|-------:|
| DAU | Baseline + 20% | 2× beta peak |
| Activated farmers | 500 | 2,000 |
| D7 retention | ≥ 45% | — |
| D30 retention | — | ≥ 25% |
| First SR rate (14d) | ≥ 50% | — |

---

## 4. Reliability metrics

| Metric | Target |
|--------|--------|
| p95 API latency | < 800 ms |
| 5xx rate | < 0.1% |
| MTTR SEV-1 | < 1 h |
| Backup age | < 24 h |

---

## 5. Doctor metrics

| Metric | Soft launch | Day 30 |
|--------|------------:|-------:|
| Active doctors (7d) | 15 | 40 |
| Accept rate (2h) | ≥ 75% | ≥ 75% |
| Completion rate | ≥ 65% | ≥ 65% |

---

## 6. Emergency metrics

| Metric | Target |
|--------|--------|
| Emergency SR volume | Track baseline |
| Time to human touch | < 30 min BH |
| AI emergency banner rate | 100% when triggered |

---

## 7. AI metrics

| Metric | Target |
|--------|--------|
| Sessions / day | Within budget |
| Cost USD / MAU | ≤ budget + 10% |
| Fallback rate | < 20% |
| Open escalations | Trend down |

---

## 8. Phase gate reviews

| Review | When | Decision |
|--------|------|----------|
| Soft → Gradual | Day 7 | Metrics + readiness ≥ 85% |
| Gradual → Full | Day 21 | Support SLA + doctor supply |
| Day 30 retrospective | Day 30 | Scale plan + cost review |

Report template: export GA dashboard JSON + checklist summary + incident log.

---

*Aligns with beta metrics [beta-success-metrics.md](./beta-success-metrics.md); GA targets are stricter.*
