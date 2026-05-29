# AI Kill Switch — Verification Report (Test Matrix)

**Date:** 2026-05-30

## Automated tests executed

```bash
cd pranidoctor-backend
pnpm exec vitest run src/modules/ai/governance src/api/health/ai-health.service.test.ts
```

| Suite | Tests | Result |
|-------|-------|--------|
| `ai-governance.service.test.ts` | 4 | PASS |
| `ai-health.service.test.ts` | 4 | PASS |

### Covered behaviors

- Local mirror / hot-path `isLlmDisabled`
- Persisted toggle with version increment
- Optimistic concurrency (`AI_GOVERNANCE_VERSION_CONFLICT`)
- Persistence flag off (`AI_KILL_SWITCH_PERSISTENCE_ENABLED=false`)
- Health check reflects kill switch via orchestrator → governance

## Manual / staging matrix (ops)

| ID | Scenario | Steps | Expected | Status |
|----|----------|-------|----------|--------|
| M1 | Persist disable | Admin disable with reason (prod rules) | PG `llmDisabled=true`, history row, all pods rules-only within poll window | ⬜ |
| M2 | Persist enable | `SUPER_ADMIN` enable | PG `llmDisabled=false`, LLM chain resumes | ⬜ |
| M3 | Restart | Disable → rolling restart all API pods | Still disabled without re-toggle | ⬜ |
| M4 | Two replicas | Toggle on replica 1 | Replica 2 `ai_llm_disabled=1` ≤2s (pub/sub) or ≤45s (poll) | ⬜ |
| M5 | Redis down | Stop Redis, toggle via admin | 503 or PG-only success; alert | ⬜ |
| M6 | PG down | Block DB, attempt toggle | 503, no state change | ⬜ |
| M7 | Cache flush | `FLUSHDB` on Redis | Poll restores from PG ≤45s | ⬜ |
| M8 | Version conflict | Two admins concurrent toggle | Second request 400 conflict | ⬜ |
| M9 | Internal API | `POST /kill-switch` with token | Persists; enable works in prod | ⬜ |
| M10 | Unauthorized | Customer token to governance | 401/403 | ⬜ |

---

*Complete readiness assessment: [AI_KILL_SWITCH_PRODUCTION_READINESS_REPORT.md](./AI_KILL_SWITCH_PRODUCTION_READINESS_REPORT.md)*
