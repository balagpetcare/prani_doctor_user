# AI Usage Monitoring Plan — Prani Doctor

**Repos:** `pranidoctor-backend` (source of truth) · `pranidoctor-web` (admin BFF) · `pranidoctor_user` (mobile client)  
**Version:** 1.1  
**Date:** 2026-05-30  
**Status:** **Implemented (v1)** — orchestrator instrumentation, daily rollups, Prometheus AI metrics, admin usage panel  
**Related:** [monitoring-guide.md](../../monitoring-guide.md) · [token-tracking-plan.md](./token-tracking-plan.md) · [phase-8-ai-smart-ecosystem-master-plan.md](../../phase-8-ai-smart-ecosystem-master-plan.md)

---

## Executive summary

Prani Doctor’s AI ecosystem routes all LLM traffic through a **single orchestrator** with three provider adapters (OpenAI, Anthropic, rules-based fallback). Usage is **persisted to PostgreSQL** (`AiUsageRecord`) on successful completions, and **admin analytics** aggregate session counts and cost summaries. **Prometheus AI metrics, failure accounting, latency SLO alerting, and cost dashboards are not yet production-ready.**

| Dimension | v1 implementation | Remaining gap |
|-----------|-------------------|---------------|
| **Requests** | Every orchestrator attempt → `AiUsageRecord` + `AiUsageDailyRollup` | Non-LLM features still use session tables only |
| **Success rate** | `getUsageSummary()` returns success/failure counts and rates | Alert rules not wired in Alertmanager |
| **Failure rate** | Failed provider attempts persisted with `errorCode` | — |
| **Latency** | Per-row `latencyMs`; rollup avg; Prometheus histogram | p95 SLO alerts pending |
| **Cost** | Extensible `ai-usage.cost` registry; daily rollup sums | Budget env + AI-005/006 alerts pending |

**Implementation (v1.1):** `AiUsageService.recordAttempt()` at orchestrator boundary; in-memory Prometheus export via `/metrics`; admin AI Ops usage KPIs. See §10 for file index.

---

## 1. AI provider inventory

All LLM calls flow through `AiOrchestratorService` (`pranidoctor-backend/src/modules/ai/orchestrator/`).

| Provider | Adapter | Config | Default model | Cost profile | Role |
|----------|---------|--------|---------------|--------------|------|
| **OpenAI** | `OpenAiProvider` | `OPENAI_API_KEY`, `OPENAI_MODEL` | `gpt-4o-mini` | ~$0.15/M input, ~$0.60/M output (hardcoded estimate) | Primary when `AI_PROVIDER=openai` (default) |
| **Anthropic** | `AnthropicProvider` | `ANTHROPIC_API_KEY`, `ANTHROPIC_MODEL` | `claude-3-5-haiku-20241022` | ~$0.25/M input, ~$1.25/M output (hardcoded estimate) | Secondary / preferred when `AI_PROVIDER=anthropic` |
| **Rules-based** | `RulesBasedProvider` | Always available | `rules-based-v1` | $0 | Tertiary fallback; sole provider when LLM kill switch active |

### 1.1 Provider selection & fallback chain

```
Request → resolveChain()
            │
            ├─ llmDisabled? ──yes──► [rules-based only]
            │
            └─ no ──► sort by AI_PROVIDER env
                        │
                        ▼
              for each provider (skip unconfigured LLM):
                        │
                        try complete()
                        ├─ success ──► record usage ──► return
                        └─ catch ──► try next (no failure record)
                        │
              all failed ──► rules-based fallback ──► record usage ──► return
```

**Environment variables (backend):**

| Variable | Purpose | Default |
|----------|---------|---------|
| `AI_PROVIDER` | Preferred LLM (`openai` \| `anthropic`) | `openai` |
| `OPENAI_API_KEY` | OpenAI auth | — |
| `OPENAI_MODEL` | OpenAI model id | `gpt-4o-mini` |
| `ANTHROPIC_API_KEY` | Anthropic auth | — |
| `ANTHROPIC_MODEL` | Anthropic model id | `claude-3-5-haiku-20241022` |

### 1.2 Non-LLM “AI” capabilities (no provider billing)

These features are **intelligent but not metered** via `AiUsageRecord` today:

| Capability | Module | Mechanism | Usage tracking |
|------------|--------|-----------|----------------|
| Triage | `ai-veterinary-core` | Rule guardrails (`evaluateTriage`) | Session table `AiTriageRecord` only |
| Symptom checker | `symptom-checker` | Taxonomy graph + rules + optional RAG text | `AiSymptomCheckSession` only |
| Smart recommendations | `smart-recommendation` | Rule/score engine | `SmartRecommendation` counts |
| Feed intelligence | `feed-recommendation` | Rules engine (non-LLM) | Feed analytics module |
| Farm risk scoring | `risk-scoring` | Deterministic scores | `FarmRiskSnapshot` |
| Knowledge search | `ai-knowledge` | DB full-text (no embedding API yet) | None |

When monitoring **total AI ecosystem activity**, include these session/event tables—not only LLM usage.

---

## 2. Service architecture (monitoring touchpoints)

### 2.1 Layer diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Mobile (Flutter)          Admin (Next.js)                                 │
│  POST /api/mobile/ai/*     GET /api/admin/ai-ops/*                         │
└───────────────────────────────┬─────────────────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────────────────┐
│  API layer — ai.routes.ts, ai-veterinary-core.routes.ts                      │
│  Rate limits: AI_CHAT (20/min), AI_CHAT_DAILY (100/user/day)                 │
└───────────────────────────────┬─────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
 AiAssistantService    AiVeterinaryCoreService   SymptomCheckerService
 (RAG + chat v2)        (chat, triage, memory)     (rules + audit)
        │                       │
        └───────────┬───────────┘
                    ▼
         AiOrchestratorService  ◄── kill switch (admin POST /kill-switch)
                    │
      ┌─────────────┼─────────────┐
      ▼             ▼             ▼
  OpenAiProvider  AnthropicProvider  RulesBasedProvider
                    │
                    ▼
           AiUsageService.record() ──► AiUsageRecord (PostgreSQL)
                    │
                    ▼
           AiAnalyticsService.getOverview() ──► Admin AI Ops dashboard
```

### 2.2 LLM feature tags (`AiUsageRecord.feature`)

| Feature | Entry point | Notes |
|---------|-------------|-------|
| `CHAT` | `AiVeterinaryCoreService.chat` | Farmer chat (v1 + v2 enriched path) |
| `FARM_BRIEFING` | `AiAssistantService.farmBriefing` | Daily farm summary LLM narrative |
| `FARM_QUERY` | `AiAssistantService.farmQuery` | Natural-language farm Q&A |

Prompt templates resolved via `AiPromptService` (`farmer_chat`, `farm_assistant`, etc.).

### 2.3 Safety & governance (parallel audit trail)

| Store | Service | Contents |
|-------|---------|----------|
| `AiSafetyAuditLog` | `AiAuditService` | Policy refusals, triage actions, Phase 8 chat enrichment |
| `AiEscalationRecord` | `AiAuditService.listEscalations` | Human handoff queue |
| Kill switch | `AiGovernanceService` + `AiOrchestratorService` | Forces rules-only; persisted in PostgreSQL + Redis (see [ai-kill-switch-persistence-plan.md](./ai-kill-switch-persistence-plan.md)) |

Governance events **complement** usage metrics—they explain *why* requests were refused or escalated, not token spend.

---

## 3. Existing analytics & instrumentation audit

### 3.1 Database — `AiUsageRecord`

**Schema** (`pranidoctor-backend/prisma/schema.prisma`):

| Field | Type | Monitoring use |
|-------|------|----------------|
| `feature` | string | Breakdown by product surface |
| `provider`, `model` | string | Vendor/model attribution |
| `inputTokens`, `outputTokens` | int | Token volume |
| `costUsd` | decimal | Estimated spend |
| `latencyMs` | int | Per-request latency |
| `success` | boolean | Outcome (today always `true` on insert) |
| `userId`, `customerId` | string? | Per-user / tenant attribution |
| `createdAt` | datetime | Time-series aggregation |

**Indexes:** `(createdAt, feature)`, `(userId)`.

**Aggregation API:** `AiUsageService.getUsageSummary(since)` — groups by `feature` + `provider`; returns totals for tokens, cost, count.

**Cost estimation** (`AiUsageService.estimateCost`): static per-token rates for OpenAI and Anthropic; **$0 for rules-based**. Does not read live provider pricing APIs.

### 3.2 Admin analytics — `AiAnalyticsService`

`GET /api/admin/ai-ops/overview` (30-day default) returns:

| Block | Source | Shown in admin UI today |
|-------|--------|-------------------------|
| `usage` | `AiUsageService.getUsageSummary` | **No** — API returns it; `AiOpsOverview.tsx` ignores |
| `sessions.chat` | `AiAssistantSession.count` | Yes |
| `sessions.triage` | `AiTriageRecord.count` | Yes |
| `sessions.symptomChecks` | `AiSymptomCheckSession.count` | Yes |
| `escalations` | `AiEscalationRecord.count` | Yes |
| `recommendations` | `SmartRecommendation.count` | Yes |
| `avgHerdHealth` | `FarmRiskSnapshot` avg | Yes |

`GET /api/admin/ai-ops/analytics/risk` — outbreak signals + high-risk farms (clinical ops, not LLM usage).

**Governance panel** (`AiGovernancePanel.tsx`): escalations list + LLM kill switch. No usage/cost widgets.

### 3.3 Prometheus / metrics endpoint

`GET /metrics` (`pranidoctor-backend/src/api/metrics/metrics.routes.ts`) exports:

- `pranidoctor_process_uptime_seconds`
- `pranidoctor_heap_used_bytes`
- `pranidoctor_compat_routes`

**No AI-specific Prometheus metrics are implemented**, despite design docs in `pranidoctor-web/docs/devops/MONITORING.md` and `docs/ai/COST_OPTIMIZATION.md` (`ai_requests_total`, `ai_cost_usd_total`, `ai_request_duration_seconds`, etc.).

### 3.4 Rate limiting (quota proxy)

| Preset | Limit | Key | Monitoring note |
|--------|-------|-----|-----------------|
| `AI_CHAT` | 20 req / 60s | `rl:ai:chat:` | Per-IP/user burst protection |
| `AI_CHAT_DAILY` | 100 req / 86400s | `rl:ai:daily:` | Per-user daily LLM quota |

429 responses with `AI_DAILY_LIMIT` indicate quota exhaustion—track via HTTP metrics, not `AiUsageRecord`.

### 3.5 Logging

- Backend: Pino JSON (`LOG_FORMAT=json` in production); no structured AI span fields today.
- Orchestrator errors on provider failure are **swallowed** (empty `catch`)—invisible in usage DB and likely absent from structured logs unless added.

### 3.6 Instrumentation status (v1.1)

| Item | Status |
|------|--------|
| Failed provider attempts recorded with `errorCode` | **Done** |
| Prometheus `ai_*` metrics on `/metrics` | **Done** |
| Admin UI usage/cost/latency KPIs | **Done** |
| Daily rollup table `AiUsageDailyRollup` | **Done** |
| Alertmanager rules (AI-001–AI-012) | Planned |
| Budget env + AI-005/006 alerts | Planned |
| Request correlation ids on usage rows | Planned |

---

## 4. Metrics to track

### 4.1 Core KPIs

| KPI | Definition | Primary source (target) | Current source |
|-----|------------|-------------------------|----------------|
| **Requests** | Count of AI completion attempts | `ai_requests_total{feature,provider,status}` | `AiUsageRecord` count (success only) |
| **Success rate** | `success / total_attempts` | Prometheus + DB | N/A (denominator missing) |
| **Failure rate** | `failed / total_attempts` | Prometheus + DB | N/A |
| **Latency** | Time from orchestrator entry to provider response | `ai_request_duration_seconds` histogram | `AiUsageRecord.latencyMs` (success only) |
| **Cost** | Estimated USD spend | `ai_cost_usd_total` + daily DB rollup | `AiUsageRecord.costUsd` sum |

### 4.2 Recommended label dimensions

| Label | Values (examples) | Use |
|-------|-------------------|-----|
| `feature` | `CHAT`, `FARM_BRIEFING`, `FARM_QUERY` | Product cost allocation |
| `provider` | `openai`, `anthropic`, `rules-based` | Vendor reliability & spend |
| `model` | `gpt-4o-mini`, `claude-3-5-haiku-20241022`, `rules-based-v1` | Model-level tuning |
| `status` | `success`, `error`, `fallback` | SLO and alert routing |
| `cached` | `true`, `false` | Future cache hit tracking |

### 4.3 Secondary metrics (ecosystem health)

| Metric | Source | Purpose |
|--------|--------|---------|
| Chat sessions / day | `AiAssistantSession` | Adoption |
| Symptom checks / day | `AiSymptomCheckSession` | Feature usage (non-LLM) |
| Escalation rate | `AiEscalationRecord` / chat sessions | Safety signal |
| Refusal rate | `AiSafetyAuditLog` where `refused=true` | Policy effectiveness |
| Rules-only ratio | `provider=rules-based` / total requests | Fallback / kill-switch indicator |
| Daily quota hits | HTTP 429 `AI_DAILY_LIMIT` | Capacity planning |
| Token efficiency | `outputTokens / inputTokens` | Prompt optimization |

### 4.4 SLO targets (proposed)

| Feature | p95 latency | Success rate | Notes |
|---------|-------------|--------------|-------|
| `CHAT` | ≤ 8s | ≥ 99% | User-facing; includes safety evaluation |
| `FARM_BRIEFING` | ≤ 12s | ≥ 98% | Batch-friendly |
| `FARM_QUERY` | ≤ 10s | ≥ 98% | |
| Provider fallback | ≤ 2 fallbacks / 100 requests | — | Indicates upstream degradation |

Emergency triage paths that must stay rules-first should **not** depend on LLM SLOs.

---

## 5. Monitoring architecture

### 5.1 Target data flow

```
┌──────────────────┐     every attempt      ┌─────────────────────┐
│ AiOrchestrator   │ ─────────────────────► │ Prometheus metrics   │
│ (instrumented)   │     async persist      │ (real-time SLO)      │
└────────┬─────────┘ ─────────────────────► └──────────┬──────────┘
         │                                              │
         │ success + failure rows                       │ scrape /metrics
         ▼                                              ▼
┌──────────────────┐                          ┌─────────────────────┐
│ AiUsageRecord    │ ◄── nightly rollup ───── │ Grafana dashboards   │
│ (PostgreSQL)     │                          │ + Alertmanager       │
└────────┬─────────┘                          └──────────┬──────────┘
         │                                              │
         │ admin API                                    │ PagerDuty / Slack
         ▼                                              ▼
┌──────────────────┐                          ┌─────────────────────┐
│ Admin AI Ops UI  │                          │ On-call notifications│
│ (usage + cost)   │                          └─────────────────────┘
└──────────────────┘
```

### 5.2 Storage tiers

| Tier | Technology | Retention | Role |
|------|------------|-----------|------|
| **Hot** | Prometheus (+ optional Redis counters) | 15–30 days | Alerting, real-time dashboards |
| **Warm** | PostgreSQL `AiUsageRecord` | 12 months (proposed) | Billing reconciliation, ad-hoc SQL |
| **Cold** | S3 parquet / CSV export (monthly) | 7 years | Finance audit |
| **Audit** | `AiSafetyAuditLog`, `AiEscalationRecord` | 24 months | Compliance, incident review |

### 5.3 Instrumentation points (implementation checklist — doc only)

1. **Orchestrator boundary** — increment counters, observe histogram, record failures before fallback.
2. **Provider adapters** — tag errors with HTTP status / error class (rate limit, timeout, 5xx).
3. **HTTP middleware** — count 429 `AI_DAILY_LIMIT` on `/api/mobile/ai/*`.
4. **Admin kill switch** — ✅ persisted (PostgreSQL + Redis); gauge `ai_llm_disabled`.
5. **Metrics endpoint** — register `ai_*` series alongside existing `pranidoctor_*` gauges.

Reference metric names (align with `pranidoctor-web/docs/ai/COST_OPTIMIZATION.md`):

```
ai_requests_total{feature,provider,model,status}
ai_request_duration_seconds{feature,provider,model}
ai_tokens_total{feature,provider,model,type}   # type=input|output
ai_cost_usd_total{feature,provider,model}
ai_fallbacks_total{from_provider,to_provider,reason}
ai_budget_usage_percent{scope}                   # scope=global|daily
ai_llm_disabled                                  # gauge 0|1
```

### 5.4 Dashboard layout (Grafana)

| Row | Panels |
|-----|--------|
| **Overview** | Requests/min, success rate, error rate, rules-only %, LLM disabled status |
| **Latency** | p50/p95/p99 by feature; heatmap by provider |
| **Cost** | USD/hour, USD/day, MTD projection, top features by spend |
| **Providers** | OpenAI vs Anthropic split, fallback count, provider error codes |
| **Safety** | Escalations/day, refusal rate, kill switch events |
| **Adoption** | Chat sessions, symptom checks, farm briefings (from DB queries) |

### 5.5 Admin panel extensions (pranidoctor-web)

Extend `/admin/ai-ops` with a **Usage & Cost** view consuming existing `usage` payload from overview API:

- Total requests, tokens, estimated USD (30d / 7d / 24h toggle)
- Table: feature × provider × count × avg latency × cost
- Provider health: rules-only ratio spike indicator
- Link to governance kill switch

No backend contract changes required for v1 display—data already returned by `AiAnalyticsService.getOverview`.

---

## 6. Reporting plan

### 6.1 Report catalog

| Report | Audience | Cadence | Delivery | Data source |
|--------|----------|---------|----------|-------------|
| **Daily AI ops snapshot** | Engineering | Daily 08:00 BDT | Slack `#ai-ops` | Prometheus + DB rollup |
| **Weekly usage summary** | Product + Engineering | Monday | Email / Notion | `AiUsageRecord` aggregation |
| **Monthly cost report** | Finance + Leadership | 1st business day | PDF + CSV | DB export vs provider invoices |
| **Safety & escalation review** | Clinical advisor + Admin | Weekly | Admin AI Ops UI | `AiEscalationRecord`, audit log |
| **Incident post-mortem** | On-call | Ad hoc | Doc template | Prometheus + audit + sample traces |

### 6.2 Daily snapshot template

```
AI Daily Snapshot — {date}
─────────────────────────
Requests:     {total} (↑/↓ vs 7d avg)
Success rate: {pct}%   Failures: {n}   Fallbacks: {n}
Latency p95:  {ms}ms (CHAT: {ms}ms)
Cost:         ${usd} (MTD: ${mtd})
Top feature:  {feature} ({pct}% of cost)
Alerts:       {none | list}
Actions:      {none | list}
```

### 6.3 Monthly cost reconciliation

1. Export `AiUsageRecord` grouped by `provider`, `model`, day.
2. Compare summed `costUsd` to OpenAI / Anthropic billing dashboards.
3. Record variance > 5% → update `estimateCost` coefficients in `AiUsageService`.
4. Archive CSV to `s3://pranidoctor-ops/ai-usage/{yyyy}/{mm}/`.

### 6.4 SQL reference queries (operations)

**Daily request & cost by feature (last 7 days):**

```sql
SELECT
  date_trunc('day', "createdAt") AS day,
  feature,
  provider,
  COUNT(*) AS requests,
  SUM("inputTokens" + "outputTokens") AS tokens,
  SUM("costUsd") AS cost_usd,
  AVG("latencyMs")::int AS avg_latency_ms
FROM "AiUsageRecord"
WHERE "createdAt" >= NOW() - INTERVAL '7 days'
GROUP BY 1, 2, 3
ORDER BY 1 DESC, cost_usd DESC;
```

**Rules-only ratio (fallback indicator):**

```sql
SELECT
  COUNT(*) FILTER (WHERE provider = 'rules-based') * 100.0 / NULLIF(COUNT(*), 0) AS rules_pct
FROM "AiUsageRecord"
WHERE "createdAt" >= NOW() - INTERVAL '24 hours';
```

**Ecosystem activity (non-LLM):**

```sql
SELECT
  (SELECT COUNT(*) FROM "AiAssistantSession" WHERE "createdAt" >= NOW() - INTERVAL '24 hours') AS chat_sessions,
  (SELECT COUNT(*) FROM "AiSymptomCheckSession" WHERE "createdAt" >= NOW() - INTERVAL '24 hours') AS symptom_checks,
  (SELECT COUNT(*) FROM "AiEscalationRecord" WHERE "flaggedAt" >= NOW() - INTERVAL '24 hours') AS escalations;
```

---

## 7. Alert plan

### 7.1 Severity matrix

| Severity | Response | Channels |
|----------|----------|----------|
| **P1 — Critical** | Page on-call within 15 min | PagerDuty + Slack |
| **P2 — High** | Respond within 1 hour | Slack `#ai-ops` |
| **P3 — Warning** | Next business day | Slack `#engineering` |
| **P4 — Info** | Log only | Dashboard annotation |

### 7.2 Alert rules

| ID | Condition | Severity | Rationale |
|----|-----------|----------|-----------|
| **AI-001** | LLM success rate < 95% over 10 min | P1 | User-facing chat degraded |
| **AI-002** | `ai_llm_disabled = 1` (unexpected) | P1 | Kill switch engaged — verify incident |
| **AI-003** | Rules-only ratio > 30% over 15 min | P2 | Provider outage or misconfiguration |
| **AI-004** | CHAT p95 latency > 12s for 10 min | P2 | UX degradation |
| **AI-005** | Daily cost > `$AI_DAILY_BUDGET_USD` (proposed env) | P2 | Budget overrun |
| **AI-006** | MTD projected cost > 110% of monthly budget | P2 | Finance escalation |
| **AI-007** | OpenAI/Anthropic error rate > 10% (5 min) | P2 | Upstream provider issue |
| **AI-008** | Escalations > 3× 7-day average in 1 hour | P2 | Possible safety incident or bad deploy |
| **AI-009** | `AI_DAILY_LIMIT` 429 rate > 50/hour | P3 | Quota too low or abuse |
| **AI-010** | Zero `AiUsageRecord` rows for 2 hours during business hours | P3 | Instrumentation break or traffic anomaly |
| **AI-011** | Token spike: 3× hourly baseline | P3 | Prompt regression or loop |
| **AI-012** | Metrics scrape failure on `/metrics` | P3 | Observability blind spot |

### 7.3 Alert routing

```
Alertmanager
    │
    ├─ severity=critical ──► PagerDuty (on-call rotation)
    │
    ├─ severity=high ──────► Slack #ai-ops + tag @ai-oncall
    │
    └─ severity=warning ───► Slack #engineering (business hours)
```

**Runbook links (to maintain):**

- Provider outage → enable kill switch via Admin → Governance; confirm rules-based responses acceptable.
- Budget exceeded → tighten `AI_CHAT_DAILY`, review top `userId` by `costUsd`, disable non-essential features.
- Latency SLO breach → check provider status pages, review prompt token sizes, consider model downgrade.

### 7.4 Kill switch & incident playbooks

| Scenario | Immediate action | Monitoring signal |
|----------|------------------|-------------------|
| Provider key leak | Rotate keys; disable LLM | N/A — manual |
| Unsafe model output spike | Admin kill switch ON | Escalation + audit log spike |
| Runaway cost | Kill switch ON; lower daily quota | AI-005 / AI-006 |
| Provider regional outage | Fallback chain should activate | AI-003 + AI-007 |

Document kill switch drills quarterly: verify rules-based path, confirm mobile disclaimers still render, confirm alerts fire when switch toggled.

---

## 8. Implementation phases

| Phase | Scope | Status |
|-------|-------|--------|
| **A — Visibility** | Admin UI usage KPIs; enhanced `getUsageSummary()` | **Done (v1.1)** |
| **B — Reliability metrics** | Failure + fallback recording; Prometheus `ai_*` on `/metrics` | **Done (v1.1)** |
| **C — Cost governance** | `AI_DAILY_BUDGET_USD`, budget gauge, monthly reconciliation job | Planned |
| **D — Advanced** | Request correlation ids, cache hits, voice LLM unified metering | Planned |

### 8.1 v1.1 backend modules

| Module | Role |
|--------|------|
| `usage/ai-usage.service.ts` | `recordAttempt()`, daily rollup upsert, summary API |
| `usage/ai-usage.cost.ts` | Provider/model cost registry (extensible) |
| `usage/ai-usage.metrics.ts` | In-memory Prometheus counters/histograms |
| `usage/ai-usage.errors.ts` | Provider error classification |
| `orchestrator/ai-orchestrator.service.ts` | Records every attempt (success, failure, fallback) |
| `api/metrics/metrics.routes.ts` | Exports `ai_*` series |
| `AiUsageDailyRollup` (Prisma) | Pre-aggregated daily buckets for efficient admin queries |

### 8.2 Prometheus metrics (live)

```
ai_requests_total{feature,provider,model,status}
ai_request_duration_seconds{feature,provider,model}
ai_tokens_total{feature,provider,model,type}
ai_cost_usd_total{feature,provider,model}
ai_fallbacks_total{from_provider,to_provider}
ai_llm_disabled
```

Scrape: `GET /metrics` with `Authorization: Bearer $METRICS_TOKEN`.

**Verification:** [AI_MONITORING_VERIFICATION_REPORT.md](./AI_MONITORING_VERIFICATION_REPORT.md) — run `npm run ai:usage-verify` in `pranidoctor-backend`.

## 9. Appendix — evidence index

| Topic | Location |
|-------|----------|
| Orchestrator + usage recording | `pranidoctor-backend/src/modules/ai/orchestrator/ai-orchestrator.service.ts` |
| OpenAI / Anthropic / rules providers | `pranidoctor-backend/src/modules/ai/orchestrator/providers/` |
| Usage persistence & cost estimate | `pranidoctor-backend/src/modules/ai/usage/ai-usage.service.ts` |
| Cost registry (future providers) | `pranidoctor-backend/src/modules/ai/usage/ai-usage.cost.ts` |
| Prometheus AI metrics | `pranidoctor-backend/src/modules/ai/usage/ai-usage.metrics.ts` |
| Daily rollup model | `pranidoctor-backend/prisma/schema.prisma` → `AiUsageDailyRollup` |
| Admin overview analytics | `pranidoctor-backend/src/modules/ai/analytics/ai-analytics.service.ts` |
| Safety audit | `pranidoctor-backend/src/modules/ai/audit/ai-audit.service.ts` |
| Chat LLM entry | `pranidoctor-backend/src/modules/ai-veterinary-core/ai-veterinary-core.service.ts` |
| Farm LLM features | `pranidoctor-backend/src/modules/ai/assistant/ai-assistant.service.ts` |
| Rate limits | `pranidoctor-backend/src/shared/security/rate-limit/rate-limit.config.ts` |
| Metrics endpoint (no AI yet) | `pranidoctor-backend/src/api/metrics/metrics.routes.ts` |
| Admin UI (sessions + usage) | `pranidoctor-web/src/components/admin/ai-ops/AiOpsOverview.tsx` |
| Governance / kill switch | `pranidoctor-web/src/components/admin/ai-ops/AiGovernancePanel.tsx` |
| Planned Prometheus AI metrics | `pranidoctor-web/docs/devops/MONITORING.md` §3.3 |
| Cost tracking design | `pranidoctor-web/docs/ai/COST_OPTIMIZATION.md` §7–8 |
| Orchestrator design (target) | `pranidoctor-web/docs/ai/AI_ORCHESTRATOR.md` |
| Phase 8 master plan | `pranidoctor_user/docs/phase-8-ai-smart-ecosystem-master-plan.md` |

---

*Document owner: Platform / AI Ops. Review quarterly or after any provider pricing change, new LLM feature launch, or production AI incident.*
