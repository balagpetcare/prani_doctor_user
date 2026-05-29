# Token Tracking Verification Report

**Date:** 2026-05-30  
**Scope:** Token usage tracking B1 (`pranidoctor-backend`, `pranidoctor-web`)  
**Verifier:** `npm run ai:usage-verify` + `ai-token-tracking.verify.test.ts`  
**Related:** [token-tracking-plan.md](./token-tracking-plan.md) · [AI_MONITORING_VERIFICATION_REPORT.md](./AI_MONITORING_VERIFICATION_REPORT.md)

---

## Executive summary

| Result | Detail |
|--------|--------|
| **Overall** | **PASS** — 41 automated tests; 18 structural/wiring checks |
| **Accounting accuracy** | PASS — `totalTokens = input + output`; billable rules enforced |
| **Cost calculations** | PASS — OpenAI/Anthropic formulas verified; billable cost excludes rules/failures |
| **Tenant separation** | PASS — independent customer rollups; `customerId` resolved at orchestrator |
| **User reporting** | PASS — user rollups + admin APIs + overview KPIs |
| **Data integrity** | PASS — rollup increments additive; billable ≤ total |

Live PostgreSQL reconciliation was **not run** (no production LLM traffic in dev workspace). Logic, wiring, and batch simulations validated.

---

## Verification methodology

| Layer | Method | Outcome |
|-------|--------|---------|
| Token accounting unit tests | `ai-usage.tokens.unit.test.ts` (6) | PASS |
| Token tracking matrix | `ai-token-tracking.verify.test.ts` (15) | PASS |
| Cost + metrics + orchestrator | `ai-usage*.test.ts` (20) | PASS |
| Structural / wiring | `scripts/ai-usage-monitoring-verify.ts` | 18/18 PASS |
| Admin UI field binding | Source review `AiOpsOverview.tsx` | PASS |
| Live DB rollup reconciliation | SQL R1–R4 (see token-tracking-plan §6.3) | N/A — no traffic |

**Reproduce:**

```bash
cd pranidoctor-backend
npm run ai:usage-verify
npm run test -- src/modules/ai/usage/ai-token-tracking.verify.test.ts
```

---

## 1. Accounting accuracy — PASS

### Rules verified

| Rule | Implementation | Test ID |
|------|----------------|---------|
| `totalTokens = inputTokens + outputTokens` | `computeTotalTokens()` / `accountTokens()` | V-ACC-01 |
| Failures → 0 tokens, not billable | Orchestrator passes zeros on catch | V-ACC-02 |
| Rules-based → tracked, not billable | `isBillableUsage('rules-based')` false | V-ACC-03 |
| Platform rollup mirrors row fields | `buildPlatformRollupFields()` | V-ACC-04 |

### Billable semantics

```
billable = success AND provider ∈ {openai, anthropic}
billableTokens = billable ? totalTokens : 0
billableCostUsd = billable ? costUsd : 0
```

Synthetic rules-based completions contribute to **totalTokens** (observability) but **not** to billable totals used for finance reporting.

### Provider token sources

| Provider | Input | Output |
|----------|-------|--------|
| OpenAI | `usage.prompt_tokens` | `usage.completion_tokens` |
| Anthropic | `usage.input_tokens` | `usage.output_tokens` |
| Rules-based | `ceil(chars/4)` estimate | `ceil(chars/4)` estimate |

---

## 2. Cost calculations — PASS

### Formula verification

| Model | Input rate | Output rate | Sample (10k in / 5k out) | Test |
|-------|------------|-------------|--------------------------|------|
| `gpt-4o-mini` | $0.15/M | $0.60/M | **$0.0045** | V-COST-01 |
| `claude-3-5-haiku-20241022` | $0.25/M | $1.25/M | **$0.00875** | V-COST-02 |

Registry: `src/modules/ai/usage/ai-usage.cost.ts`  
Rate version stamped on rows: `AI_RATE_VERSION = '2026-05-30'`

### Billable cost isolation (V-COST-04)

Simulated 3-attempt batch:

| Attempt | Provider | Success | Input | Output | Billable cost |
|---------|----------|---------|-------|--------|---------------|
| 1 | openai | yes | 1000 | 500 | $0.00045 |
| 2 | openai | no | 0 | 0 | $0 |
| 3 | rules-based | yes | 200 | 100 | $0 |

**Totals:** `totalTokens = 1800`, `billableTokens = 1500`, `billableCostUsd = $0.00045`

Failures never receive cost estimation (`costUsd = 0` when `success = false` in `recordAttempt`).

---

## 3. Tenant separation — PASS

### Identity model

| Scope | Field | Rollup table |
|-------|-------|--------------|
| User (auth) | `userId` | `AiUsageUserDailyRollup` |
| Tenant (farmer) | `customerId` (`CustomerProfile.id`) | `AiUsageCustomerDailyRollup` |

### Orchestrator enrichment (V-TEN)

`AiOrchestratorService.complete()` resolves `customerId` once per request:

```
customerId = input.customerId ?? resolveCustomerId(userId)
```

This ensures **CHAT** and **voice** paths (previously missing tenant attribution) now populate tenant rollups without changing mobile API contracts.

### Separation guarantees

| Check | Result |
|-------|--------|
| User rollup keyed by `(bucketDate, userId, feature, provider, model)` | Unique constraint in schema |
| Tenant rollup keyed by `(bucketDate, customerId, feature, provider, model)` | Unique constraint in schema |
| Scoped rollups use same token math, independent storage | V-TEN-01 |
| Non-billable provider excluded from billable tenant totals | V-TEN-03 |
| Index `(customerId, createdAt)` on ledger | Schema present |

**Note:** User and tenant rollups for the same request are **correlated but not identical scopes** — one user maps to one customer profile in the farmer app; both rollups increment for attributed requests.

---

## 4. User reporting — PASS

### Backend APIs

| Endpoint | Returns |
|----------|---------|
| `GET /api/admin/ai-ops/overview` | Platform totals + `topUsers` + `topCustomers` |
| `GET /api/admin/ai-ops/usage/users/:userId` | `getUserConsumption()` — rollup-backed |
| `GET /api/admin/ai-ops/usage/customers/:customerId` | `getCustomerConsumption()` — rollup-backed |

### Summary fields (30-day overview)

| Field | Source |
|-------|--------|
| `inputTokens`, `outputTokens` | `AiUsageRecord` groupBy |
| `totalTokens`, `billableTokens` | Row sums / billable filter |
| `costUsd`, `billableCostUsd` | Aggregated estimates |
| `topUsers[]` | `AiUsageUserDailyRollup` groupBy `userId` |
| `topCustomers[]` | `AiUsageCustomerDailyRollup` groupBy `customerId` |

### Admin UI (`AiOpsOverview.tsx`)

Verified bindings:

- Total tokens / billable tokens KPIs
- Billable cost (USD) KPI
- Model table: total + billable token columns
- Top users / top tenants tables by billable tokens

### Read-path performance

User and tenant consumption reads use **daily rollup tables** (not full ledger scans) for efficient long-window queries — aligned with performance requirements in token-tracking-plan.

---

## 5. Data integrity — PASS

### Rollup consistency

Each `recordAttempt()` transaction atomically:

1. Inserts `AiUsageRecord` (canonical event)
2. Upserts `AiUsageDailyRollup` (platform)
3. Upserts `AiUsageUserDailyRollup` (if `userId`)
4. Upserts `AiUsageCustomerDailyRollup` (if `customerId`)

### Simulation results (V-INT)

| Check | Result |
|-------|--------|
| Platform rollup increments additive across attempts | PASS (430 tokens over 2 attempts) |
| `totalTokens = inputTokens + outputTokens` in batch | PASS |
| `billableTokens ≤ totalTokens` always | PASS |

### Post-deploy SQL checks (run after migration + traffic)

```sql
-- Ledger vs platform rollup (UTC day)
SELECT date_trunc('day', "createdAt" AT TIME ZONE 'UTC') AS day,
       SUM("totalTokens") AS ledger_total,
       SUM("billableTokens") FILTER (WHERE billable) AS ledger_billable
FROM "AiUsageRecord"
WHERE "createdAt" >= NOW() - INTERVAL '7 days'
GROUP BY 1;

SELECT "bucketDate", SUM("totalTokens"), SUM("billableTokens")
FROM "AiUsageDailyRollup"
WHERE "bucketDate" >= CURRENT_DATE - 7
GROUP BY 1;

-- User rollup ≤ platform rollup
SELECT SUM("totalTokens") FROM "AiUsageUserDailyRollup"
WHERE "bucketDate" >= CURRENT_DATE - 7;

-- Tenant coverage on farmer LLM features
SELECT COUNT(*) FILTER (WHERE "customerId" IS NOT NULL) * 100.0 / COUNT(*)
FROM "AiUsageRecord"
WHERE feature IN ('CHAT','FARM_BRIEFING','FARM_QUERY') AND success = true;
```

**Pass thresholds:** ledger ≈ platform rollup; user sum ≤ platform sum; customerId coverage ≥ 95% on farmer LLM rows.

---

## 6. Test results summary

```
Test Files  4 passed (4)
Tests       41 passed (41)

Structural checks  18/18 passed
```

| Suite | Tests | Status |
|-------|-------|--------|
| `ai-usage.unit.test.ts` | 8 | PASS |
| `ai-usage.tokens.unit.test.ts` | 6 | PASS |
| `ai-token-tracking.verify.test.ts` | 15 | PASS |
| `ai-usage-monitoring.verify.test.ts` | 12 | PASS |

### Verification matrix coverage

| ID | Area | Status |
|----|------|--------|
| V-ACC-01–04 | Accounting accuracy | PASS |
| V-COST-01–04 | Cost calculations | PASS |
| V-TEN-01–03 | Tenant separation | PASS |
| V-USR-01 | User reporting | PASS |
| V-INT-01–03 | Data integrity | PASS |

---

## 7. Gaps and recommendations

| Item | Severity | Action |
|------|----------|--------|
| No live DB reconciliation | Info | Run SQL checks after go-live week 1 |
| `gemini` registered but not billable until added to `BILLABLE_PROVIDERS` | Low | Update `isBillableProvider` when provider goes live |
| Token-based quotas still request-based | Medium | Phase B2 in token-tracking-plan |
| Invoice reconciliation not automated | Low | Monthly finance job |
| Historical rows pre-migration lack `customerId` on CHAT | Low | Optional backfill from `CustomerProfile.userId` |

---

## 8. Sign-off checklist

| Validation area | Status |
|-----------------|--------|
| Accounting accuracy | ✅ PASS |
| Cost calculations | ✅ PASS |
| Tenant separation | ✅ PASS |
| User reporting | ✅ PASS |
| Data integrity | ✅ PASS |
| Automated verify | ✅ `npm run ai:usage-verify` |
| Documentation | ✅ [token-tracking-plan.md](./token-tracking-plan.md) v1.1 |

**Verdict:** Token usage tracking B1 is **verified and ready for production traffic** after applying migration `20260530140000_ai_token_tracking`.

---

*Next review: 7 days post-launch with live SQL reconciliation, or when adding a new billable LLM provider.*
