# Emergency E2E Results — Run Template

**Run ID:** `EMERGENCY-E2E-YYYYMMDD-NN`  
**Date:**  
**Environment:** Local / Development / Staging / Pre-production  
**Executor:**  
**Backend tag / commit:**  
**Mobile build (if device tests):**  

---

## Automated suite (required for CI gate)

| Command | Pass? | Notes |
|---------|:-----:|-------|
| `npm run emergency:audit` (backend) | ☐ | Vitest emergency-validation module |
| `npm run emergency:validate` (backend) | ☐ | Writes `reports/emergency/emergency-validation-report.md` |

**Vitest summary**

| Metric | Value |
|--------|------:|
| Tests passed | / |
| Tests failed | |
| Registry automated coverage | % |

---

## P0 manual staging (if automated pass)

| ID | Journey | Pass? | SR ID / evidence |
|----|---------|:-----:|------------------|
| J-01 | Livestock happy path | ☐ | |
| J-02 | Pet happy path | ☐ | |
| J-03 | Doctor accept | ☐ | |
| J-04 | Doctor reject | ☐ | |
| J-05 | Reassign | ☐ | |
| J-08 | AI → book (no dispatch copy) | ☐ | Screenshots |
| J-10 | Legal gate first emergency | ☐ | |

| ID | Edge | Pass? | Notes |
|----|------|:-----:|-------|
| E-01 | Unassigned + ops alert | ☐ | |
| E-03 | Offline create replay | ☐ | Device |
| E-04 | Push-less degraded | ☐ | |

---

## Failure / recovery

| ID | Scenario | Pass? | Notes |
|----|----------|:-----:|-------|
| RR-01 | API rollback, SR readable | ☐ | Staging only |
| E-05 | AI kill switch drill | ☐ | Admin governance |

---

## Compliance spot-check

| Check | Pass? |
|-------|:-----:|
| No ETA / dispatch strings in farmer UI | ☐ |
| Pending SR shows `requestPending` copy | ☐ |
| Notification SMS received (if enabled) | ☐ |

---

## Verdict

| Score component | Weight | Score |
|-----------------|-------:|------:|
| P0 automated | 70% | |
| P1 automated | 20% | |
| Compliance UI (manual) | 10% | |
| **Total** | 100% | |

**Launch recommendation:** GO / CONDITIONAL GO / NO-GO  

**Blockers:**

1. 
2. 

**Sign-off:** QA __ · Ops __ · Compliance __
