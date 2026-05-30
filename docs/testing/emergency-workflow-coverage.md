# Emergency Workflow Coverage

**Document ID:** `EMERGENCY_WORKFLOW_COVERAGE`  
**Version:** 1.0  
**Date:** 2026-06-01  
**Source of truth (code):** `pranidoctor-backend/src/modules/emergency-validation/coverage-registry.ts`

---

## Coverage summary

| Metric | Value |
|--------|------:|
| Registry cases | 22 |
| Automated (unit/static) | 18 |
| **Registry automation rate** | **82%** |
| Manual / staging only | 4 |
| P0 registry cases | 12 |
| P0 automated | 11 |

> **Note:** Registry coverage measures planned cases with an automated check. It does not include Flutter UI or live FCM/SMS delivery.

---

## Validated workflows (automation)

1. Livestock emergency service request lifecycle (create → assign → accept → audit complete event)
2. Pet emergency service request lifecycle (DOG, CAT)
3. Doctor accept / reject / reassignment
4. Customer cancellation with timeline
5. Emergency limitation legal guard (`LEGAL_CONSENT_REQUIRED`)
6. Notification handlers: submit, accept, complete; SMS path; error swallowing
7. Notification static copy legal-safe scan
8. AI symptom emergency detection and unsafe copy rejection
9. Ops escalation monitoring cycle (mocked repository)
10. Terminal state and invalid doctor assignment guards

---

## Remaining gaps

| Gap | Priority | Mitigation |
|-----|----------|------------|
| Mobile offline outbox replay (E-03) | P1 | Device lab + `offline:verify` |
| FCM push delivery | P1 | Staging with test device |
| Instant care UI journey (J-09) | P1 | Flutter integration_test |
| Admin/doctor Playwright on staging | P1 | New `e2e/emergency` web suite |
| Live SMS provider | P1 | Staging OTP/SMS checklist |
| AI triage U1 banner (compliance) | P0 product | Separate compliance sprint |
| DB integration test with real Postgres | P2 | Optional `emergency:validate:db` |
| API contract §12 broadcast engine | N/A | Not as-built — do not test |

---

## Module map

| File | Responsibility |
|------|----------------|
| `emergency-workflow.test.ts` | Pet/livestock create + happy path + cancel |
| `doctor-workflow.test.ts` | Accept, reject, reassign |
| `audit-timeline.test.ts` | Timeline actor + event chain |
| `notifications.test.ts` | In-app + SMS + failure |
| `ai-escalation.test.ts` | AI risk + copy |
| `failure-scenarios.test.ts` | Unassigned, rejection, escalation, terminal |
| `emergency-limitation.test.ts` | Legal guard |
| `static-sources.test.ts` | Notification literals |
| `scripts/emergency/run-validation.mjs` | Report generator |

---

## Commands

```bash
cd pranidoctor-backend
npm run emergency:audit      # CI gate
npm run emergency:validate   # audit + markdown report
```

---

## Related

- [emergency-e2e-test-matrix.md](./emergency-e2e-test-matrix.md)
- [emergency-e2e-results-template.md](./emergency-e2e-results-template.md)
- [e2e-emergency-validation-plan.md](../launch/e2e-emergency-validation-plan.md)
