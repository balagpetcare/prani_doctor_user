# Token Tracking Plan — Prani Doctor AI

**Repos:** `pranidoctor-backend` (source of truth) · `pranidoctor-web` (admin BFF) · `pranidoctor_user` (mobile client)  
**Version:** 1.1  
**Date:** 2026-05-30  
**Status:** **Implemented (B1)** — total tokens, billable flag, user/tenant daily rollups, customerId resolution on all LLM calls  
**Related:** [ai-usage-monitoring-plan.md](./ai-usage-monitoring-plan.md) · [AI_MONITORING_VERIFICATION_REPORT.md](./AI_MONITORING_VERIFICATION_REPORT.md) · [phase-8-ai-smart-ecosystem-master-plan.md](../../phase-8-ai-smart-ecosystem-master-plan.md) · `pranidoctor-web/docs/ai/COST_OPTIMIZATION.md`

---

## Executive summary

Prani Doctor meters **LLM tokens at the orchestrator boundary**. OpenAI and Anthropic return authoritative token counts on successful completions; failures record **zero tokens**; the rules-based fallback uses **synthetic estimates** (character length ÷ 4). Token totals, estimated USD cost, and per-request attribution are stored in **`AiUsageRecord`**; platform-level daily aggregates live in **`AiUsageDailyRollup`**.

| Dimension | B1 implementation | Remaining |
|-----------|-------------------|-----------|
| **Input tokens** | Provider-reported; stored on `AiUsageRecord` + rollups | Prompt-cache split (future) |
| **Output tokens** | Same | — |
| **Total tokens** | `totalTokens` column + rollup sums | — |
| **Cost estimates** | `ai-usage.cost.ts` + `rateVersion` on rows | DB rate catalog (Phase C) |
| **User usage** | `AiUsageUserDailyRollup` + `getUserConsumption()` | Token-based quota (B2) |
| **Tenant usage** | `AiUsageCustomerDailyRollup` + auto `customerId` + `getCustomerConsumption()` | Per-farm attribution (B3) |

**Verification:** [TOKEN_TRACKING_VERIFICATION_REPORT.md](./TOKEN_TRACKING_VERIFICATION_REPORT.md) — run `npm run ai:usage-verify` and `npm run test -- src/modules/ai/usage/ai-token-tracking.verify.test.ts`

---

## 1. AI integration inventory

### 1.1 LLM-integrated services (token-metered)

All paths below converge on `AiOrchestratorService.complete()` → `AiUsageService.recordAttempt()`.

| Integration | Module / route | Feature tag | `userId` | `customerId` | Token source |
|-------------|----------------|-------------|----------|--------------|--------------|
| Farmer chat (v1) | `ai-veterinary-core` · `POST /api/ai/chat` | `CHAT` | Yes | **No** | Provider API |
| Farmer chat (v2 + RAG) | `ai-assistant` · `POST /api/ai/chat/v2` | `CHAT` | Yes | **No** | Provider API (via core) |
| Voice → AI reply | `voice-assistant` → `ai-veterinary-core.chat` | `CHAT` | Yes | **No** | Provider API |
| Daily farm briefing | `ai-assistant` · `POST /api/ai/briefing/daily` | `FARM_BRIEFING` | Yes | Yes | Provider API |
| Farm natural-language query | `ai-assistant` · `POST /api/ai/farm-query` | `FARM_QUERY` | Yes | Yes | Provider API |

**Providers:**

| Provider | Token fields (API) | Default model | Billable |
|----------|-------------------|---------------|----------|
| OpenAI | `usage.prompt_tokens`, `usage.completion_tokens` | `gpt-4o-mini` | Yes |
| Anthropic | `usage.input_tokens`, `usage.output_tokens` | `claude-3-5-haiku-20241022` | Yes |
| Rules-based | `ceil(chars/4)` synthetic | `rules-based-v1` | No ($0) |

### 1.2 AI-adjacent services (not token-metered today)

| Integration | Module | Mechanism | Token implication |
|-------------|--------|-----------|-------------------|
| Triage | `ai-veterinary-core` · `POST /api/ai/triage` | Rule guardrails | 0 LLM tokens |
| Symptom checker | `symptom-checker` · `POST /api/ai/symptom-check` | Taxonomy + rules + DB RAG snippet | 0 LLM tokens (orchestrator imported but unused) |
| Knowledge search | `ai-knowledge` · `GET /api/ai/knowledge/search` | PostgreSQL full-text | 0 tokens (no embedding API) |
| Smart recommendations | `smart-recommendation` | Rule/score engine | 0 LLM tokens |
| Farm risk / health dashboard | `farm-health`, `risk-scoring` | Deterministic scores | 0 LLM tokens |
| Feed intelligence | `feed-recommendation` | Rules engine | 0 LLM tokens |
| Admin kill switch | `POST /api/admin/ai-ops/kill-switch` | Disables LLM chain | Forces rules-based ($0 tokens) |

### 1.3 Client surfaces (Flutter)

Mobile calls backend AI APIs only — **no on-device LLM**. Token accounting is entirely server-side.

| Flutter feature | API path | Metered |
|-----------------|----------|---------|
| AI chat / history | `/api/ai/chat`, `/api/ai/chat/v2` | Yes (`CHAT`) |
| Voice input | `/api/voice/*` → core chat | Yes (`CHAT`) |
| Symptom checker | `/api/ai/symptom-check` | No |
| Farm briefing / query | `/api/ai/briefing/daily`, `/api/ai/farm-query` | Yes |

---

## 2. Current usage storage review

### 2.1 Event ledger — `AiUsageRecord`

```prisma
model AiUsageRecord {
  id           String
  userId       String?      // Auth user (mobile login)
  customerId   String?      // CustomerProfile.id — farmer "tenant"
  feature      String       // CHAT | FARM_BRIEFING | FARM_QUERY
  provider     String
  model        String
  inputTokens  Int
  outputTokens Int
  costUsd      Decimal?
  latencyMs    Int
  success      Boolean
  errorCode    String?
  isFallback   Boolean
  createdAt    DateTime

  @@index([createdAt, feature])
  @@index([createdAt, provider, success])
  @@index([userId])
}
```

**Strengths:** Append-only ledger; supports failures (0 tokens); feature + model attribution.  
**Gaps:**

| Gap | Impact |
|-----|--------|
| No `@@index([customerId])` | Slow tenant queries at scale |
| `CHAT` / voice omit `customerId` | Tenant rollups under-count farmer chat |
| No `sessionId` / `requestId` | Hard to tie tokens to conversation |
| No `totalTokens` computed column | Rollups must sum input + output |
| No distinction billable vs synthetic | Rules-based mixed with LLM in totals |

### 2.2 Daily platform rollup — `AiUsageDailyRollup`

Aggregates by `(bucketDate, feature, provider, model)` — **no user or customer dimension**.

| Field | Purpose |
|-------|---------|
| `inputTokens`, `outputTokens` | Platform daily token volume |
| `costUsd` | Platform daily estimated spend |
| `requestCount`, `successCount`, `failureCount` | Request accounting |

Used for efficient admin dashboards and long-range reporting. **Not suitable for per-user or per-tenant billing** without schema extension.

### 2.3 Real-time metrics — Prometheus

| Metric | Token relevance |
|--------|-----------------|
| `ai_tokens_total{type="input\|output"}` | Hot-path counters; success only |
| `ai_cost_usd_total` | Derived from token counts × rate registry |

### 2.4 Rate limiting (quota proxy)

| Preset | Limit | Basis |
|--------|-------|-------|
| `AI_CHAT_DAILY` | 100 / user / day | **Request count**, not tokens |
| `AI_CHAT` | 20 / min | Burst requests |

Token-based quotas are **not implemented** — design target in §4.

### 2.5 Identity model (user vs tenant)

```
User (auth)  ──1:1──►  CustomerProfile (customerId)  ──1:N──►  Farm / Livestock
```

| Term in this doc | Schema field | Meaning |
|------------------|--------------|---------|
| **User usage** | `AiUsageRecord.userId` | Authenticated mobile account |
| **Tenant usage** | `AiUsageRecord.customerId` | Farmer customer profile (`CustomerProfile.id`) |

Prani Doctor does **not** use multi-tenant SaaS `tenantId` on AI usage rows today. For B2B/co-op scenarios, `customerId` is the **tenant boundary** for farmer billing and farm-scoped analytics. Platform-wide `tenantId` on unrelated models (e.g. deployment metadata) does not apply to AI token ledgers.

---

## 3. Token accounting strategy

### 3.1 Definitions

| Term | Definition |
|------|------------|
| **Input tokens** | Tokens charged for prompt/system/context sent to the LLM (provider-reported) |
| **Output tokens** | Tokens charged for model completion (provider-reported) |
| **Total tokens** | `inputTokens + outputTokens` (computed at query time) |
| **Billable tokens** | Tokens on `success = true` AND `provider IN (openai, anthropic)` AND not `isFallback` OR fallback from LLM with real usage |
| **Synthetic tokens** | Rules-based `ceil(char/4)` — tracked, **never billed** |
| **Failed attempt tokens** | Always **0** — upstream call did not complete |

### 3.2 Measurement rules

```
┌─────────────────────────────────────────────────────────────────┐
│                    TOKEN ACCOUNTING FLOW                         │
├─────────────────────────────────────────────────────────────────┤
│  Provider success (OpenAI / Anthropic)                           │
│    inputTokens  ← API usage field                                │
│    outputTokens ← API usage field                                │
│    costUsd      ← estimateAiCostUsd(provider, model, in, out)    │
│                                                                  │
│  Provider failure                                                │
│    inputTokens = 0, outputTokens = 0, costUsd = 0                │
│                                                                  │
│  Rules-based success (fallback or kill switch)                   │
│    inputTokens  ← synthetic estimate                             │
│    outputTokens ← synthetic estimate                             │
│    costUsd = 0                                                   │
└─────────────────────────────────────────────────────────────────┘
```

**Rules:**

1. **Single write point** — only `AiUsageService.recordAttempt()` mutates token fields (orchestrator boundary).
2. **No double counting** — each provider *attempt* is one row; a failed OpenAI try + successful rules fallback = 2 rows.
3. **RAG / prompt inflation** — enriched user messages (chat v2) inflate input tokens; attribute to `feature` that initiated the call (`CHAT`).
4. **Voice** — same `CHAT` feature; no separate feature tag (optional future: `CHAT_VOICE`).
5. **Currency** — USD estimates only; BDT display is a presentation-layer conversion.

### 3.3 Cost estimation

Registry: `src/modules/ai/usage/ai-usage.cost.ts`

```
costUsd = inputTokens × inputRate(model) + outputTokens × outputRate(model)
```

| Provider / model | Input ($/token) | Output ($/token) |
|------------------|-----------------|------------------|
| openai / gpt-4o-mini | 0.00000015 | 0.0000006 |
| openai / gpt-4o | 0.0000025 | 0.00001 |
| anthropic / claude-3-5-haiku-20241022 | 0.00000025 | 0.00000125 |
| anthropic / claude-3-5-sonnet-20241022 | 0.000003 | 0.000015 |
| rules-based | 0 | 0 |
| Unknown provider | 0 (register via `registerProviderRates`) | |

**Operational requirements:**

- Update rates when providers change pricing (quarterly review).
- Monthly reconciliation: sum `costUsd` vs provider invoices; adjust coefficients if variance > 5%.
- Store `rateVersion` on rows (future) for auditability.

### 3.4 User usage accounting

**Current:**

- Every orchestrator call accepts `userId`; chat/voice paths pass it.
- Daily request quota: `checkRateLimit('user:{userId}', AI_CHAT_DAILY)`.
- Aggregation: ad-hoc SQL on `AiUsageRecord` grouped by `userId`.

**Target:**

| Capability | Phase |
|------------|-------|
| `getUserUsageSummary(userId, since)` API | B1 |
| `AiUsageUserDailyRollup` table | B1 |
| Token-based daily cap (env `AI_USER_DAILY_TOKEN_LIMIT`) | B2 |
| User-facing usage widget in mobile AI settings | B3 |

**User rollup query (today, no migration):**

```sql
SELECT
  "userId",
  COUNT(*) AS requests,
  SUM("inputTokens") AS input_tokens,
  SUM("outputTokens") AS output_tokens,
  SUM("inputTokens" + "outputTokens") AS total_tokens,
  SUM("costUsd") AS cost_usd
FROM "AiUsageRecord"
WHERE "userId" = $1
  AND "createdAt" >= $2
  AND success = true
  AND provider IN ('openai', 'anthropic')
GROUP BY "userId";
```

### 3.5 Tenant usage accounting

**Current:**

- `customerId` populated for `FARM_BRIEFING` and `FARM_QUERY` only.
- `CHAT` and voice paths record `userId` but leave `customerId` null despite 1:1 `CustomerProfile` mapping.

**Target:**

| Capability | Phase |
|------------|-------|
| Resolve and persist `customerId` on all farmer LLM calls | B1 |
| `@@index([customerId, createdAt])` on `AiUsageRecord` | B1 |
| `AiUsageCustomerDailyRollup` | B1 |
| Admin tenant usage report (top customers by tokens/cost) | B2 |
| Per-farm attribution via optional `farmRef` column | B3 |

**Tenant resolution rule (proposed):**

```
on orchestrator entry:
  customerId = input.customerId
            ?? await AiRepository.resolveCustomerId(userId)
            ?? null
```

**Tenant rollup query (after customerId backfill):**

```sql
SELECT
  "customerId",
  feature,
  SUM("inputTokens") AS input_tokens,
  SUM("outputTokens") AS output_tokens,
  SUM("costUsd") AS cost_usd
FROM "AiUsageRecord"
WHERE "customerId" = $1
  AND "createdAt" >= $2
  AND success = true
GROUP BY "customerId", feature;
```

### 3.6 Aggregation hierarchy

```
                    ┌─────────────────────┐
                    │  AiUsageRecord      │  ← canonical event (all attempts)
                    │  (per attempt)      │
                    └──────────┬──────────┘
                               │
         ┌─────────────────────┼─────────────────────┐
         ▼                     ▼                     ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ AiUsageDaily    │  │ AiUsageUser     │  │ AiUsageCustomer │
│ Rollup          │  │ DailyRollup     │  │ DailyRollup     │
│ (platform)      │  │ (planned B1)    │  │ (planned B1)    │
│ EXISTS v1       │  │                 │  │                 │
└─────────────────┘  └─────────────────┘  └─────────────────┘
         │                     │                     │
         └─────────────────────┴─────────────────────┘
                               ▼
                    Admin / finance / quota APIs
```

**Retention:**

| Store | Retention | Rationale |
|-------|-----------|-----------|
| `AiUsageRecord` | 12 months hot | Dispute resolution, user support |
| Daily rollups | 24 months | Finance dashboards |
| Cold export (S3 CSV) | 7 years | Audit |

---

## 4. Data model plan

### 4.1 Phase A — No migration (use existing schema)

Use `AiUsageRecord` with SQL/API aggregations for user and tenant reports. Document `customerId` backfill as operational debt.

### 4.2 Phase B1 — User & tenant rollups (recommended next)

**Extend `AiUsageRecord`:**

| Column | Type | Purpose |
|--------|------|---------|
| `totalTokens` | Int (computed or stored) | Query convenience |
| `billable` | Boolean | `provider IN (openai,anthropic) AND success` |
| `rateVersion` | String? | Cost coefficient audit trail |

**New index:**

```prisma
@@index([customerId, createdAt])
@@index([userId, createdAt])
```

**New table — `AiUsageUserDailyRollup`:**

```prisma
model AiUsageUserDailyRollup {
  id           String   @id @default(cuid())
  bucketDate   DateTime @db.Date
  userId       String
  feature      String
  provider     String
  model        String
  requestCount Int      @default(0)
  inputTokens  Int      @default(0)
  outputTokens Int      @default(0)
  costUsd      Decimal  @default(0) @db.Decimal(12, 6)
  updatedAt    DateTime @updatedAt

  @@unique([bucketDate, userId, feature, provider, model])
  @@index([userId, bucketDate])
}
```

**New table — `AiUsageCustomerDailyRollup`:**

```prisma
model AiUsageCustomerDailyRollup {
  id           String   @id @default(cuid())
  bucketDate   DateTime @db.Date
  customerId   String
  feature      String
  provider     String
  model        String
  requestCount Int      @default(0)
  inputTokens  Int      @default(0)
  outputTokens Int      @default(0)
  costUsd      Decimal  @default(0) @db.Decimal(12, 6)
  updatedAt    DateTime @updatedAt

  @@unique([bucketDate, customerId, feature, provider, model])
  @@index([customerId, bucketDate])
}
```

Upsert these in the same transaction as `AiUsageRecord` insert (mirror platform rollup pattern).

### 4.3 Phase B2 — Optional attribution columns

| Column | Type | Purpose |
|--------|------|---------|
| `sessionId` | String? | Tie tokens to `AiAssistantSession` |
| `farmRef` | String? | Farm-scoped tenant analytics |
| `requestId` | String? | Correlation / tracing |

### 4.4 Phase C — Rate catalog (finance-grade)

```prisma
model AiModelRate {
  id              String   @id @default(cuid())
  provider        String
  model           String
  inputPerToken   Decimal  @db.Decimal(12, 10)
  outputPerToken  Decimal  @db.Decimal(12, 10)
  effectiveFrom   DateTime
  effectiveTo     DateTime?
  source          String   // 'manual' | 'provider_api' | 'invoice_recon'

  @@unique([provider, model, effectiveFrom])
}
```

`estimateAiCostUsd` reads active rate row instead of in-memory constants.

### 4.5 API surface (planned, non-breaking)

| Endpoint | Audience | Returns |
|----------|----------|---------|
| `GET /api/admin/ai-ops/usage` | Admin | Platform summary (exists via overview) |
| `GET /api/admin/ai-ops/usage/users/:userId` | Admin | User token/cost breakdown |
| `GET /api/admin/ai-ops/usage/customers/:customerId` | Admin | Tenant token/cost breakdown |
| `GET /api/ai/usage/me` | Mobile | Current user's daily/monthly tokens (optional) |

Existing mobile AI routes remain unchanged.

---

## 5. Reporting & visibility

### 5.1 Admin (current v1.1)

`GET /api/admin/ai-ops/overview` → `usage.totals`:

- `inputTokens`, `outputTokens`, `costUsd` (platform, 30-day window)
- `byModel[]` — provider/model requests and cost

**Gap:** No per-user or per-customer breakdown in admin UI.

### 5.2 Finance monthly report (template)

```
Month: YYYY-MM
Platform billable tokens:  {input} in / {output} out
Estimated USD:             ${cost}
By provider:               openai ${x} | anthropic ${y}
By feature:                CHAT ${a} | FARM_BRIEFING ${b} | FARM_QUERY ${c}
Top 10 customers (cost):   [customerId, tokens, USD]
Invoice variance:          {pct}%
```

### 5.3 Prometheus token alerts (planned)

| Alert | Condition |
|-------|-----------|
| TOK-001 | Platform daily billable tokens > 3× 7-day average |
| TOK-002 | Single user daily tokens > `AI_USER_DAILY_TOKEN_LIMIT` |
| TOK-003 | Single customer daily cost > threshold |

---

## 6. Verification plan

### 6.1 Automated checks (existing)

| Check | Command / test | Validates |
|-------|----------------|-----------|
| Cost formula | `ai-usage.unit.test.ts` | Input/output → USD |
| Metrics export | `ai-usage-monitoring.verify.test.ts` | `ai_tokens_total` |
| Orchestrator records tokens | verify test mock | Success/failure token counts |
| Structural wiring | `npm run ai:usage-verify` | Files + rollup upsert |

### 6.2 Token-specific verification matrix

| ID | Scenario | Expected `inputTokens` | Expected `outputTokens` | Expected `costUsd` |
|----|----------|------------------------|-------------------------|-------------------|
| T-01 | OpenAI success (100/50) | 100 | 50 | `estimateAiCostUsd('openai','gpt-4o-mini',100,50)` |
| T-02 | Anthropic success | API values | API values | Per haiku rates |
| T-03 | OpenAI failure → rules fallback | 0 then synthetic | 0 then synthetic | 0 |
| T-04 | Kill switch (rules only) | synthetic | synthetic | 0 |
| T-05 | FARM_BRIEFING with customerId | provider values | provider values | > 0 if LLM |
| T-06 | CHAT without customerId | provider values | provider values | > 0; customerId null (debt) |

### 6.3 Reporting accuracy checks

Run after migration deploy and first traffic week:

```sql
-- R1: Row totals match platform rollup (UTC day)
SELECT
  date_trunc('day', r."createdAt" AT TIME ZONE 'UTC') AS day,
  SUM(r."inputTokens") AS row_input,
  SUM(r."outputTokens") AS row_output,
  SUM(r."costUsd") AS row_cost
FROM "AiUsageRecord" r
WHERE r."createdAt" >= NOW() - INTERVAL '7 days'
GROUP BY 1
ORDER BY 1;

-- Compare to AiUsageDailyRollup for same days

-- R2: Billable tokens exclude rules-based
SELECT
  provider,
  SUM("inputTokens" + "outputTokens") AS total_tokens
FROM "AiUsageRecord"
WHERE success = true
  AND "createdAt" >= NOW() - INTERVAL '7 days'
GROUP BY provider;

-- R3: User sum ≤ platform sum
SELECT SUM("inputTokens") FROM "AiUsageRecord" WHERE "userId" IS NOT NULL;
SELECT SUM("inputTokens") FROM "AiUsageRecord";

-- R4: Customer coverage (after backfill)
SELECT
  COUNT(*) FILTER (WHERE "customerId" IS NOT NULL) * 100.0 / COUNT(*) AS customer_id_pct
FROM "AiUsageRecord"
WHERE feature IN ('CHAT','FARM_BRIEFING','FARM_QUERY')
  AND success = true
  AND provider IN ('openai','anthropic');
```

**Pass criteria:**

| Check | Threshold |
|-------|-----------|
| R1 rollup vs rows | Token sums match within 0.01% |
| R2 rules-based cost | `SUM(costUsd) WHERE provider='rules-based' = 0` |
| R3 user allocation | User-grouped sum = platform sum |
| R4 customer coverage | ≥ 95% of billable farmer LLM rows have `customerId` |

### 6.4 Manual verification checklist

| Step | Action | Pass |
|------|--------|------|
| 1 | Send chat message via mobile | Row in `AiUsageRecord` with tokens > 0 |
| 2 | Trigger farm briefing | Row with `customerId` populated |
| 3 | Disable LLM (kill switch) | New rows: `rules-based`, costUsd = 0 |
| 4 | Inspect `/metrics` | `ai_tokens_total` increments |
| 5 | Open Admin AI Ops | Input/output token KPIs visible |
| 6 | Compare one row cost to manual formula | Match to 6 decimal places |

### 6.5 Verification deliverables

| Artifact | Location |
|----------|----------|
| Monitoring verify script | `pranidoctor-backend/scripts/ai-usage-monitoring-verify.ts` |
| Unit + behaviour tests | `src/modules/ai/usage/ai-usage*.test.ts` |
| Monitoring report | [AI_MONITORING_VERIFICATION_REPORT.md](./AI_MONITORING_VERIFICATION_REPORT.md) |
| Token reconciliation SQL | This doc §6.3 |
| Post-implementation report | `docs/production/ai/TOKEN_TRACKING_VERIFICATION_REPORT.md` (after B1) |

**Suggested CI gate:**

```bash
npm run ai:usage-verify   # includes token/cost unit tests
```

---

## 7. Implementation roadmap

| Phase | Scope | Status |
|-------|-------|--------|
| **A** | Orchestrator metering, platform rollup | **Done** |
| **B1** | `totalTokens`, `billable`, user/customer rollups, `customerId` on chat | **Done** |
| **B2** | Token-based quotas; admin per-tenant drill-down routes | Planned |
| **B3** | `farmRef`, mobile usage UI, `AiModelRate` table | Planned |
| **C** | Prompt-cache split, embedding metering | Planned |

### B1 implementation index

| Module | Role |
|--------|------|
| `usage/ai-usage.tokens.ts` | `totalTokens`, `billable`, rate version helpers |
| `usage/ai-usage.service.ts` | User/tenant rollup upserts + consumption APIs |
| `orchestrator/ai-orchestrator.service.ts` | Resolves `customerId` from `userId` once per request |
| `AiUsageUserDailyRollup` / `AiUsageCustomerDailyRollup` | Prisma models |
| `analytics/ai-analytics.service.ts` | Overview includes `topUsers`, `topCustomers` |

---

## 8. Risks & open decisions

| Risk | Mitigation |
|------|------------|
| `CHAT` missing `customerId` | B1: resolve at orchestrator entry |
| Request quota ≠ token quota | B2: add token limit env vars |
| Static rates drift from invoices | Monthly reconciliation job |
| Rules-based synthetic tokens skew totals | Filter `billable = true` in finance reports |
| Voice indistinguishable from text chat | Optional `CHAT_VOICE` feature tag |
| Future embedding API for knowledge | New feature tag `KNOWLEDGE_EMBED`; separate rate |

---

## 9. Appendix — evidence index

| Topic | Location |
|-------|----------|
| Token capture (OpenAI) | `src/modules/ai/orchestrator/providers/openai.provider.ts` |
| Token capture (Anthropic) | `src/modules/ai/orchestrator/providers/anthropic.provider.ts` |
| Synthetic tokens (rules) | `src/modules/ai/orchestrator/providers/rules.provider.ts` |
| Persistence + rollup | `src/modules/ai/usage/ai-usage.service.ts` |
| Cost registry | `src/modules/ai/usage/ai-usage.cost.ts` |
| Prometheus tokens | `src/modules/ai/usage/ai-usage.metrics.ts` |
| Chat without customerId | `src/modules/ai-veterinary-core/ai-veterinary-core.service.ts` |
| Farm paths with customerId | `src/modules/ai/assistant/ai-assistant.service.ts` |
| Voice → core chat | `src/modules/voice-assistant/voice-assistant.service.ts` |
| Schema | `prisma/schema.prisma` → `AiUsageRecord`, `AiUsageDailyRollup` |
| Customer identity | `prisma/schema.prisma` → `CustomerProfile.userId` |

---

*Document owner: Platform / AI Ops. Review when adding LLM providers, embedding APIs, or B2B tenant models.*
