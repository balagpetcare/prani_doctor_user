# AI Monitoring Verification Report

**Date:** 2026-05-30  
**Scope:** AI usage monitoring v1.1 (`pranidoctor-backend`, `pranidoctor-web`, admin AI Ops)  
**Verifier:** `npm run ai:usage-verify` + targeted unit/integration tests  
**Related:** [ai-usage-monitoring-plan.md](./ai-usage-monitoring-plan.md) · [token-tracking-plan.md](./token-tracking-plan.md)

---

## Executive summary

| Result | Detail |
|--------|--------|
| **Overall** | **PASS** — all 13 structural/wiring checks and 20 automated tests passed |
| **Request tracking** | PASS — every orchestrator attempt recorded with `feature`, `provider`, `model` |
| **Failure tracking** | PASS — LLM failures persisted with `errorCode` before fallback |
| **Cost visibility** | PASS — estimated USD on successes; Prometheus + admin KPIs |
| **Provider visibility** | PASS — per-provider/model breakdown in DB summary and admin table |
| **Reporting accuracy** | PASS — rate math and rollup logic validated; live DB sample N/A (no traffic) |

Monitoring is **functionally correct** at the instrumentation layer. Production alerting (Alertmanager rules AI-001–AI-012) and budget caps remain **planned**, not verified here.

---

## Verification methodology

| Layer | Method | Outcome |
|-------|--------|---------|
| Static structure | `scripts/ai-usage-monitoring-verify.ts` | 8/8 files + schema fields present |
| Wiring | Source inspection via verify script | 4/4 integration points confirmed |
| Unit tests | `ai-usage.unit.test.ts` (8 tests) | PASS |
| Behaviour tests | `ai-usage-monitoring.verify.test.ts` (12 tests) | PASS |
| Admin UI | Type + field binding review | PASS |
| Live DB / traffic | Not run — no production LLM traffic in dev workspace | N/A |

**Command to reproduce:**

```bash
cd pranidoctor-backend
npm run ai:usage-verify
```

---

## 1. Request tracking — PASS

### Expected behaviour

Every call to `AiOrchestratorService.complete()` emits one `recordAttempt()` per provider try (success or failure).

### Evidence

| Check | Result |
|-------|--------|
| Success path records `feature`, `provider`, `model`, tokens, latency | Verified in `ai-usage-monitoring.verify.test.ts` |
| Prometheus `ai_requests_total{feature,provider,model,status}` | Exported via `/metrics` |
| PostgreSQL `AiUsageRecord` row per attempt | `persistAttempt()` transaction |
| Daily bucket `AiUsageDailyRollup.requestCount` incremented | Upsert on each attempt |

### Instrumentation path

```
AiOrchestratorService.complete()
  → getAiUsageService().recordAttempt()
      → recordAiUsageMetrics()     [hot / Prometheus]
      → persistAttempt()           [warm / PostgreSQL + rollup]
```

### Features metered

| Feature | Entry point |
|---------|-------------|
| `CHAT` | `AiVeterinaryCoreService.chat` |
| `FARM_BRIEFING` | `AiAssistantService.farmBriefing` |
| `FARM_QUERY` | `AiAssistantService.farmQuery` |

**Note:** Symptom checker, triage, and recommendations are **not** LLM-metered (by design).

---

## 2. Failure tracking — PASS

### Expected behaviour

When an LLM provider throws, the orchestrator records a **failure row** (`success: false`, `errorCode`) before trying the next provider or rules-based fallback.

### Evidence

| Scenario | Records | Verified |
|----------|---------|----------|
| OpenAI fails → rules fallback | 2 rows (1 failure + 1 success fallback) | Yes |
| Failure `errorCode` for 503 | `provider_5xx` | Yes |
| Failure has zero tokens / zero cost | `inputTokens: 0`, `costUsd: 0` | Yes |
| Prometheus `status="failure"` | Present in metrics export | Yes |
| Fallback flagged | `isFallback: true`, `fromProvider: llm_chain` | Yes |

### Error classification matrix (verified)

| Input | `errorCode` |
|-------|-------------|
| HTTP 429 / rate limit | `rate_limit` |
| HTTP 401 / 403 | `auth` |
| Timeout / ETIMEDOUT | `timeout` |
| HTTP 5xx | `provider_5xx` |
| Other | `provider_error` |

### Prometheus fallback counter

`ai_fallbacks_total{from_provider="llm_chain",to_provider="rules-based"}` increments when `isFallback` + `fromProvider` set.

---

## 3. Cost visibility — PASS

### Expected behaviour

Cost is estimated only on **successful** completions using the extensible `ai-usage.cost` registry.

### Verified formulas

| Provider / model | Input rate | Output rate | Sample (10k in / 5k out) |
|------------------|------------|-------------|---------------------------|
| `openai` / `gpt-4o-mini` | $0.15/M | $0.60/M | **$0.0045** |
| `anthropic` / `claude-3-5-haiku-20241022` | $0.25/M | $1.25/M | **$0.00875** |
| `rules-based` | $0 | $0 | **$0** |

Failures always store **$0** cost (no token charge on failed upstream calls).

### Visibility surfaces

| Surface | Fields |
|---------|--------|
| `AiUsageRecord.costUsd` | Per attempt |
| `AiUsageDailyRollup.costUsd` | Daily aggregate |
| `getUsageSummary().totals.costUsd` | Rolling window |
| Prometheus `ai_cost_usd_total` | Real-time counter |
| Admin AI Ops | **Est. cost (USD)** KPI + model table |

### Limitation (documented)

Rates are **static estimates**, not live provider invoice data. Monthly reconciliation against OpenAI/Anthropic billing is still required (Phase C in monitoring plan).

---

## 4. Provider visibility — PASS

### Expected behaviour

Each attempt is attributed to `provider` + `model`. Admin and API expose breakdown by model.

### Evidence

| Check | Result |
|-------|--------|
| Failure rows use `resolveDefaultModel(provider)` when upstream fails before response | PASS |
| Success rows use model from provider response | PASS |
| `getUsageSummary().byModel[]` groups requests + cost | PASS |
| `getUsageSummary().byFeatureProvider[]` groups feature × provider × model | PASS |
| Kill switch sets `ai_llm_disabled 1` gauge | PASS |
| Future provider support via `registerProviderRates()` | PASS (unit test) |

### Provider chain (runtime)

```
AI_PROVIDER env → [openai | anthropic] → rules-based fallback
Kill switch ON  → [rules-based only]
```

---

## 5. Reporting accuracy — PASS

### Rate calculations

`getUsageSummary()` computes:

```
successRate = round(successes / requests × 100, 2)
failureRate = round(failures / requests × 100, 2)
successRate + failureRate = 100%   (verified for mixed samples)
avgLatencyMs = sum(latencyMs) / requests
```

### Rollup consistency model

Each `recordAttempt()` atomically:

1. Inserts `AiUsageRecord`
2. Upserts `AiUsageDailyRollup` for UTC `bucketDate` + `(feature, provider, model)`

Rollup increments verified against simulated 3-attempt batch:

| Attempt | success | cost | rollup.requestCount | rollup.successCount | rollup.failureCount |
|---------|---------|------|---------------------|---------------------|---------------------|
| 1 | true | $0.001 | 1 | 1 | 0 |
| 2 | false | $0 | 2 | 1 | 1 |
| 3 | true (fallback) | $0.002 | 3 | 2 | 1 |

**Success rate:** 66.67% — matches formula.

### Admin API contract

`GET /api/admin/ai-ops/overview` returns:

```json
{
  "usage": {
    "totals": { "requests", "successes", "failures", "successRate", "failureRate", "costUsd", "avgLatencyMs", "fallbackCount", ... },
    "byFeatureProvider": [...],
    "byModel": [{ "provider", "model", "requests", "costUsd" }]
  }
}
```

`AiOpsOverview.tsx` binds all `usage.totals` KPIs and renders `byModel` table — **field parity confirmed**.

### Live data note

No `AiUsageRecord` rows exist in the local dev database at verification time. Reporting accuracy is validated via **logic tests and rollup simulation**, not live SQL reconciliation. After first production traffic, run:

```sql
SELECT COUNT(*) AS records FROM "AiUsageRecord";
SELECT SUM("requestCount") AS rollup_requests FROM "AiUsageDailyRollup";
-- counts should correlate (rollup ≤ records if migration applied mid-day)
```

---

## 6. Prometheus metrics inventory

Verified series on `GET /metrics`:

| Metric | Type | Labels |
|--------|------|--------|
| `ai_requests_total` | counter | `feature`, `provider`, `model`, `status` |
| `ai_request_duration_seconds` | histogram | `feature`, `provider`, `model` |
| `ai_tokens_total` | counter | `feature`, `provider`, `model`, `type` |
| `ai_cost_usd_total` | counter | `feature`, `provider`, `model` |
| `ai_fallbacks_total` | counter | `from_provider`, `to_provider` |
| `ai_llm_disabled` | gauge | — |

---

## 7. Test results summary

```
Test Files  2 passed (2)
Tests       20 passed (20)

Structural checks  13/13 passed
```

| Suite | Tests | Status |
|-------|-------|--------|
| `ai-usage.unit.test.ts` | 8 | PASS |
| `ai-usage-monitoring.verify.test.ts` | 12 | PASS |

---

## 8. Gaps and recommendations

| Item | Severity | Recommendation |
|------|----------|----------------|
| No Alertmanager rules wired | Medium | Deploy AI-001–AI-012 from monitoring plan |
| Static cost rates | Low | Monthly invoice reconciliation job |
| Kill switch state in-memory | Medium | Persist to Redis/DB; survive restarts |
| `/metrics/json` omits AI series | Low | Add `ai` block for JSON consumers |
| No live production traffic sample | Info | Re-run SQL checks after go-live week 1 |
| Non-LLM AI features un-metered | Info | Expected — track via session tables |

---

## 9. Sign-off checklist

| Validation area | Status |
|-----------------|--------|
| Request tracking | ✅ PASS |
| Failure tracking | ✅ PASS |
| Cost visibility | ✅ PASS |
| Provider visibility | ✅ PASS |
| Reporting accuracy | ✅ PASS |
| Automated verify script | ✅ `npm run ai:usage-verify` |
| Documentation | ✅ [ai-usage-monitoring-plan.md](./ai-usage-monitoring-plan.md) v1.1 |

**Verdict:** AI usage monitoring v1.1 is **verified and ready for production traffic**. Enable Prometheus scraping on `/metrics` and apply migration `20260530120000_ai_usage_monitoring` before relying on rollup tables in admin dashboards.

---

*Next review: after first 7 days of production LLM traffic or any provider pricing change.*
