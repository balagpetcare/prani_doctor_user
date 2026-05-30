# Emergency E2E Test Matrix

**Document ID:** `EMERGENCY_E2E_TEST_MATRIX`  
**Version:** 1.0  
**Date:** 2026-06-01  
**Automation:** `pranidoctor-backend` → `npm run emergency:audit`  
**Plan:** [e2e-emergency-validation-plan.md](../launch/e2e-emergency-validation-plan.md)

---

## Matrix legend

| Mode | Meaning |
|------|---------|
| **AUTO** | Vitest `src/modules/emergency-validation/*.test.ts` |
| **STATIC** | Source copy scan (legal-safe messaging) |
| **STAGING** | Manual or Playwright on staging — not in CI unit gate |
| **MANUAL** | Device lab / ops drill |

| Result | Meaning |
|--------|---------|
| ✅ | Covered by automation |
| 🔶 | Partial (handler mocked; delivery not live) |
| ⬜ | Manual only |

---

## A. Critical emergency journeys

| ID | Journey | Pet | Livestock | Mode | Result |
|----|---------|:---:|:---------:|------|:------:|
| J-01 | Emergency request → assign → accept → complete | — | ✅ | AUTO | ✅ |
| J-02 | Pet emergency same pipeline | ✅ | — | AUTO | ✅ |
| J-03 | Doctor acceptance | ✅ | ✅ | AUTO | ✅ |
| J-04 | Doctor rejection | ✅ | ✅ | AUTO | ✅ |
| J-05 | Doctor reassignment | ✅ | ✅ | AUTO | ✅ |
| J-06 | Emergency cancellation | ✅ | ✅ | AUTO | ✅ |
| J-07 | Emergency closure / timeline complete | ✅ | ✅ | AUTO | ✅ |
| J-08 | AI emergency escalation (no dispatch) | ✅ | ✅ | AUTO | ✅ |
| J-09 | Instant care → book | — | — | STAGING | ⬜ |
| J-10 | First emergency legal gate | ✅ | ✅ | AUTO | ✅ |

---

## B. Edge cases

| ID | Scenario | Mode | Result |
|----|----------|------|:------:|
| E-01 | No doctor available | AUTO | ✅ |
| E-02 | Multiple doctor rejection | AUTO | ✅ |
| E-03 | Network interruption | MANUAL | ⬜ |
| E-04 | Notification failure | AUTO | ✅ |
| E-05 | AI disabled / kill switch | AUTO | 🔶 |
| E-06 | System degraded | STAGING | ⬜ |
| E-07 | User cancellation | AUTO | ✅ |
| E-11 | Legal consent enforcement | AUTO | ✅ |

---

## C. Doctor workflow

| Step | AUTO file | Result |
|------|-----------|:------:|
| Accept emergency | `doctor-workflow.test.ts` | ✅ |
| Reject emergency | `doctor-workflow.test.ts` | ✅ |
| Reassignment | `doctor-workflow.test.ts` | ✅ |
| Escalation ops alert | `failure-scenarios.test.ts` | ✅ |
| Availability (invalid doctor) | `failure-scenarios.test.ts` | ✅ |

---

## D. Notifications

| Channel | Validation | Result |
|---------|------------|:------:|
| In-app (`createNotificationForUser`) | `notifications.test.ts` | ✅ |
| SMS (`sendSms`) | `notifications.test.ts` | 🔶 |
| Email | Not implemented | N/A |
| Push (FCM) | Not in backend unit suite | ⬜ |
| Copy compliance | `static-sources.test.ts` | ✅ |
| Failure handling (no throw) | `notifications.test.ts` | ✅ |

---

## E. AI emergency

| Check | File | Result |
|-------|------|:------:|
| Emergency symptom detection | `ai-escalation.test.ts` | ✅ |
| Refusal of prescription input | `ai-escalation.test.ts` | ✅ |
| Safe vs unsafe escalation copy | `ai-escalation.test.ts` | ✅ |
| Governance kill-switch API surface | `ai-escalation.test.ts` | 🔶 |

---

## F. Audit

| Event | File | Result |
|-------|------|:------:|
| CREATED | `emergency-workflow.test.ts` | ✅ |
| ASSIGNED / REASSIGNED | `doctor-workflow.test.ts` | ✅ |
| ACCEPTED | `audit-timeline.test.ts` | ✅ |
| REJECTED | `audit-timeline.test.ts` | ✅ |
| COMPLETED | `audit-timeline.test.ts` | ✅ |
| CANCELLED | `emergency-workflow.test.ts` | ✅ |

---

## G. CI integration

| Gate | Command | Workflow job |
|------|---------|--------------|
| PR / main | `npm run emergency:audit` | `emergency-validate` |
| Release report | `npm run emergency:validate` | Local / optional staging |

---

## H. Environment execution

| Environment | Automated | Manual sign-off |
|-------------|:---------:|:---------------:|
| Local | ✅ `emergency:audit` | Optional |
| Development | ✅ CI | — |
| Staging | Partial health probe | Full matrix STAGING column |
| Pre-production | Same as staging | Launch ops |
