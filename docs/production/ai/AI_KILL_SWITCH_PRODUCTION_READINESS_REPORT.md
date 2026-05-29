# AI Kill Switch Persistence — Production Readiness Verification

**Date:** 2026-05-30  
**Scope:** `pranidoctor-backend` governance module, admin governance API, `AiGovernancePanel`  
**Method:** Static code review, test execution, architecture cross-check against [ai-kill-switch-persistence-plan.md](./ai-kill-switch-persistence-plan.md)  
**Verdict:** **Conditionally ready for production** — apply migration before deploy; monitor Redis/PostgreSQL sync; two safety fixes applied during this review (bootstrap fail-closed, `internal_api` enable path).

---

## 1. Production Readiness Report

| Area | Status | Notes |
|------|--------|-------|
| PostgreSQL source of truth | **PASS** | `AiGovernanceState` + transactional update + `AiGovernanceStateHistory` |
| Redis runtime cache | **PASS** | Keys `ai:governance:llm_disabled`, `ai:governance:version`; no TTL |
| Startup recovery | **PASS** (after fix) | Hydrate from PG; on failure: Redis → env → prod fail-closed |
| Hot-path reads | **PASS** | In-process mirror; no per-request Redis/DB |
| Multi-server sync | **PASS** | Pub/sub + 45s PG poll + version monotonicity |
| Admin UI | **PASS** | State, metadata, history, reason field, `expectedVersion` |
| RBAC | **PASS** | `ADMIN`/`SUPER_ADMIN`; prod enable requires `SUPER_ADMIN` (admin UI) |
| Audit trail | **PASS** | PG history + `SYSTEM_CONFIG_CHANGE` foundation audit |
| API compatibility | **PARTIAL** | POST response additive; GET shape changed (see §7) |
| Tests | **PASS** | `ai-governance.service.test.ts` (4), `ai-health.service.test.ts` (4) |
| Operations docs | **PASS** | `pranidoctor-backend/docs/production/ai/ai-kill-switch-operations.md` |

**Pre-deploy gate:** Run migration `20260530160000_ai_governance_kill_switch` on all environments before rolling API pods.

---

## 2. Risk Report

| ID | Risk | Severity | Likelihood | Mitigation |
|----|------|----------|------------|------------|
| R1 | Redis pub/sub missed; replica stale up to poll interval (~45s) | Medium | Medium | Poll repairs; accept brief LLM calls on wrong replica during incident toggle |
| R2 | Redis cache cleared (LRU/flush); replicas rely on poll until PG rewrite | Low | Low | `pollRefresh` repopulates Redis from PG |
| R3 | Bootstrap before migration → catch path may fail-closed LLM off in prod | Low | Low | Run migration first; monitor startup logs |
| R4 | `GET /governance` no longer returns bare escalation array | Low | Low | Only `AiGovernancePanel` consumer updated |
| R5 | Foundation audit (Redis) may fail silently; PG history remains | Low | Medium | Rely on `AiGovernanceStateHistory` for compliance |
| R6 | `disableLlm()` / `applyLocalState` bypass persistence if misused | Medium | Low | Deprecated; only tests call orchestrator toggles |
| R7 | `internal_api` enable allowed with token only (break-glass) | Medium | Low | Rotate `INTERNAL_ADMIN_AI_OPS_TOKEN`; network restrict |
| R8 | No automated integration test against real Redis/Postgres | Medium | Medium | Staging drill checklist (below) |
| R9 | Prometheus `ai_llm_disabled` per-pod until sync | Low | Medium | Aggregate in Prometheus or alert on any pod = 0 when PG says 1 |
| R10 | Staging does not enforce reason / SUPER_ADMIN enable | Low | High | Document; test prod rules in staging with `NODE_ENV=production` |

---

## 3. Verification Report

### 3.1 Architecture compliance

| Requirement | Evidence | Result |
|-------------|----------|--------|
| PostgreSQL SoT | `setLlmDisabled` → `$transaction` update state + insert history | **PASS** |
| Redis cache | `writeGovernanceRedisCache` after commit | **PASS** |
| Auto Redis rebuild | `bootstrap` + `pollRefresh` write cache from PG | **PASS** |
| Startup recovery | `server.ts` → `bootstrapAiGovernance(config)` after Prisma | **PASS** |
| Fallback | PG miss on poll → `readGovernanceRedisCache`; bootstrap catch uses Redis/env/fail-closed | **PASS** |
| Feature flag | `AI_KILL_SWITCH_PERSISTENCE_ENABLED=false` → in-memory only | **PASS** |
| Emergency env | `AI_LLM_DISABLED=true` on bootstrap | **PASS** |

### 3.2 Multi-server validation

| Check | Mechanism | Result |
|-------|-----------|--------|
| Write propagation | `PUBLISH` on channel `{prefix}ai:governance:events` | **PASS** |
| Stale prevention | `applyRemoteIfNewer(version)` — ignore older | **PASS** |
| Healing | `pollRefresh` reads PG, updates mirror + Redis | **PASS** |
| Rolling deploy | New pods `ensureStateRow` / read PG seed | **PASS** |
| Writer does not rely on own pub/sub | Local `applyLocalState` after commit | **PASS** |

**Gap:** No automated multi-instance test in CI.

### 3.3 Admin validation

| Check | Result |
|-------|--------|
| UI loads `governance` + `history` from GET | **PASS** |
| Shows version, updatedAt, actor, source, reason | **PASS** |
| POST sends `disable`, `reason`, `expectedVersion` | **PASS** |
| Route RBAC `ADMIN` \| `SUPER_ADMIN` | **PASS** |
| BFF `requireAdminPanelApiAccess` on proxy | **PASS** (existing) |
| Prod enable policy | **PASS** — `SUPER_ADMIN` only via admin UI |

**Gap:** UI does not disable Enable button for non–`SUPER_ADMIN` (error only after click).

### 3.4 Audit validation

| Field | `AiGovernanceStateHistory` | Foundation audit | Result |
|-------|---------------------------|------------------|--------|
| Actor | `actorId`, `actorRole` | `actorId`, `actorRole` | **PASS** |
| Timestamp | `createdAt` | `timestamp` | **PASS** |
| Old value | `previousLlmDisabled` | `changes.before` | **PASS** |
| New value | `llmDisabled` | `changes.after` | **PASS** |
| Reason | `reason` | `details.reason` | **PASS** |
| Source | `source` | `details.source` | **PASS** |
| Rollback | `rollbackOfId` (API accepts) | — | **PARTIAL** — field exists; UI does not expose rollback flow |

**Gap:** No-op toggle (same state) skips history — correct behavior.

**Gap:** `internal_api` toggles have null actor — acceptable for token-gated path.

### 3.5 Failure testing review (code-path analysis)

| Scenario | Expected | Observed | Result |
|----------|----------|----------|--------|
| Redis unavailable at toggle | PG commit OK; warn; peers sync via poll | Implemented | **PASS** |
| PostgreSQL unavailable at toggle | `503 AI_GOVERNANCE_STORE_UNAVAILABLE` | Implemented | **PASS** |
| PostgreSQL unavailable at read (runtime) | Mirror + poll; no PG on hot path | Implemented | **PASS** |
| Backend restart | PG hydrate in bootstrap | Implemented | **PASS** |
| Cache cleared | Poll restores from PG | Implemented | **PASS** |
| Deployment rollback | `AI_KILL_SWITCH_PERSISTENCE_ENABLED=false` or old binary; PG row retained | Documented | **PASS** |
| Partial cluster restart | Surviving pods keep state; new pods hydrate | Implemented | **PASS** |
| PG down at bootstrap (prod) | Redis → env → fail-closed disabled | Fixed in review | **PASS** |

### 3.6 Security review

| Check | Result |
|-------|--------|
| Customer/mobile cannot toggle | **PASS** — admin routes only |
| Privilege escalation via admin UI enable in prod | **PASS** — `SUPER_ADMIN` required |
| `internal_api` token exposure | **RISK R7** — token = break-glass |
| Rate limit abuse | **PASS** — 10/hour per `actorId` when Redis up |
| Audit bypass via `applyLocalState` | **PASS** for prod paths; test-only on orchestrator |
| Version conflict / TOCTOU | **PASS** — optional `expectedVersion` |

### 3.7 Backward compatibility

| Surface | Compatibility | Result |
|---------|---------------|--------|
| `POST` body `{ disable }` | Unchanged | **PASS** |
| `POST` response `llmDisabled` | Preserved + `version`, `governance` | **PASS** |
| `GET` response | **Breaking:** was `Escalation[]`, now `{ escalations, governance, history }` | **PARTIAL** |
| `POST /kill-switch` | Same + extended response | **PASS** |
| DB | Additive tables only | **PASS** |
| Orchestrator `isLlmDisabled()` | Same semantics | **PASS** |

### 3.8 Rollback validation

| Type | Procedure | Result |
|------|-----------|--------|
| Operational | Admin disable or `AI_LLM_DISABLED=true` | **PASS** |
| Config | `AI_KILL_SWITCH_PERSISTENCE_ENABLED=false` | **PASS** |
| Deployment | Revert image; PG state unchanged | **PASS** |
| State recovery | Re-enable via admin / `internal_api` with token | **PASS** |

---

## 4. Remaining Gaps

1. **No CI integration test** with Redis + PostgreSQL multi-process simulation.
2. **GET governance response shape** breaks any undocumented consumer expecting an array.
3. **Foundation audit** depends on Redis (90d TTL) — not a long-term compliance store; use PG history.
4. **Fail-closed on PG bootstrap failure** disables LLM in production when hydrate fails — correct for safety, may surprise ops if migration missing.
5. **No UI guard** for `SUPER_ADMIN`-only enable in production.
6. **No alert** on PG vs Redis version mismatch (recommended in plan, not implemented).
7. **Staging** does not mirror production policy unless `NODE_ENV=production`.
8. **`rollbackOfId`** not exposed in admin UI.

---

## 5. Recommended Improvements (non-blocking)

| Priority | Item |
|----------|------|
| P1 | Staging drill: toggle on pod A, verify `isLlmDisabled()` on pod B within 2s |
| P1 | Prometheus alert: `ai_llm_disabled` inconsistent across replicas or vs PG |
| P2 | Admin UI: hide/disable Enable for non–`SUPER_ADMIN` when prod |
| P2 | Integration test: pub/sub + version monotonicity |
| P3 | Reconciliation job: compare PG `version` to Redis daily |
| P3 | Document GET response migration for API consumers |

---

## 6. Critical fixes applied in this review

1. **Bootstrap fail-closed (production):** If PostgreSQL hydrate fails, attempt Redis cache, then `AI_LLM_DISABLED`, then default **LLM disabled** in production when persistence is enabled.
2. **`internal_api` enable in production:** Break-glass Express `kill-switch` route can re-enable LLM with valid internal token (admin UI still requires `SUPER_ADMIN`).

---

## 7. Sign-off checklist

| # | Item | Status |
|---|------|--------|
| 1 | Migration applied in target environment | ⬜ Ops |
| 2 | `AI_KILL_SWITCH_PERSISTENCE_ENABLED=true` | ⬜ Ops |
| 3 | Staging two-replica toggle drill | ⬜ Ops |
| 4 | `/health/ai` reflects persisted state | ⬜ Ops |
| 5 | Admin governance panel shows correct state after restart | ⬜ Ops |
| 6 | Unit tests green | ✅ Verified |

**Recommendation:** Proceed to production after migration + staging drill. Treat **R1** (poll latency) and **R9** (per-pod metrics) as known operational limits for launch week.

---

*Related: [AI_KILL_SWITCH_VERIFICATION_REPORT.md](./AI_KILL_SWITCH_VERIFICATION_REPORT.md) (test matrix), [ai-kill-switch-operations.md](../../../pranidoctor-backend/docs/production/ai/ai-kill-switch-operations.md)*
