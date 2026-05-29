# Production Alerting — Readiness Report

**Version:** 1.0  
**Date:** 2026-05-30  
**Scope:** `pranidoctor-backend`, `pranidoctor-web`  
**Plan:** [alerting-plan.md](./alerting-plan.md) · [ALERTING_IMPLEMENTATION.md](./ALERTING_IMPLEMENTATION.md)

---

## Executive summary

| Area | Status | Evidence |
|------|--------|----------|
| Alert generation | **Pass** | 14 in-app trigger paths wired; webhook payload v2 validated |
| Severity routing | **Pass** | `critical` / `warning` / `info` → tier field in payload |
| Deduplication | **Pass** | Unit + integration tests; fingerprint support verified |
| Escalation flow | **Pass** | Re-fire at repeat threshold; metadata in payload |
| Production safety | **Pass with notes** | Master switch, storm caps, fail-safe logging; see §5 |
| Automated tests | **Pass** | Backend 10/10, Web 6/6 |

**Readiness verdict:** **Ready for production webhook configuration.** In-app alerting pipeline is verified. External uptime monitors, Slack/PagerDuty routing, and Sentry rules remain **ops-owned** before full paging coverage.

---

## 1. Alert generation

### 1.1 Backend triggers

| Alert ID | Function | Trigger location | Tier |
|----------|----------|------------------|------|
| ALT-DOWN-02 | `alertReadinessFailure` | `GET /ready` → 503 | Critical |
| ALT-DB-01 | `alertDependencyUnhealthy` | `GET /health/db` unhealthy | Critical |
| ALT-SEC-02 | `alertRedisUnavailable` | `GET /health/redis` unhealthy (prod only) | Critical |
| ALT-ERR-01 | `alertApiServerError` | Express error handler (5xx) | Warning |
| ALT-ERR-02 | `alertUncaughtProcessError` | `server.ts` uncaught / unhandled rejection | Critical |

All paths call `sendProductionAlert` (directly or via `sendCriticalAlert` / `sendWarningAlert`). Fire-and-forget (`void`) — request path is not blocked.

### 1.2 Admin web triggers

| Alert ID | Function | Trigger location | Tier |
|----------|----------|------------------|------|
| ALT-DOWN-04 | `alertHealthCheckFailure` | `GET /api/admin/health` backend fail | Critical |
| ALT-ERR-03 | `sendProductionAlert` | `captureException` in error-tracking | Critical |
| ALT-ERR-03 | `alertServerError` | Legacy helper (instrumentation) | Critical |
| ALT-ERR-04 | `alertAdminProxy5xx` | `proxy-to-backend.ts` status ≥500 | Warning |
| ALT-SLOW-01 | `alertAdminProxySlow` | `proxy-to-backend.ts` duration ≥ threshold | Warning |

### 1.3 Webhook payload contract

Verified fields in test suite:

```json
{
  "event": "production.alert",
  "alertId": "ALT-DOWN-04",
  "severity": "critical",
  "tier": "critical",
  "service": "<service-name>",
  "environment": "<APP_ENV|NODE_ENV>",
  "version": "<APP_VERSION>",
  "escalation": {
    "repeatCount": 1,
    "escalated": false,
    "escalationLevel": 0,
    "deduplicated": false
  },
  "runbook": "docs/incident-response-guide.md"
}
```

### 1.4 Test results

| Suite | Result |
|-------|--------|
| `pranidoctor-backend/src/shared/monitoring/alerting/` | **10/10 passed** |
| `pranidoctor-web/src/lib/monitoring/alerting/` | **6/6 passed** |
| `pranidoctor-backend/src/shared/errors/error.handler.test.ts` | **6/6 passed** (alert mock) |

---

## 2. Severity routing

| Input `severity` | Output `tier` | Intended routing |
|------------------|---------------|------------------|
| `critical` | `critical` | Page on-call / PagerDuty |
| `warning` | `warning` | Slack / team channel |
| `info` | `informational` | Digest / low-priority |

**Verified:** `severityToTier()` unit tests (backend + web).

**Wired tier usage today:**

| Tier | Wired alert IDs |
|------|-----------------|
| Critical | ALT-DOWN-02, ALT-DB-01, ALT-SEC-02, ALT-DOWN-04, ALT-ERR-02, ALT-ERR-03 |
| Warning | ALT-ERR-01, ALT-ERR-04, ALT-SLOW-01 |
| Informational | None wired yet (`sendInformationalAlert` exported, no callers) |

Severity is carried in both `severity` and `tier` fields so downstream routers (Slack vs PagerDuty) can branch without parsing titles.

---

## 3. Deduplication

### 3.1 Mechanism

- **Key:** `alertId` or `alertId:fingerprint` when fingerprint provided
- **Window:** `ALERT_DEDUP_WINDOW_MS` (default 900000 ms / 15 min)
- **Behavior:** Repeat within window → suppressed; logs `monitoring.alert.suppressed` (web) or Pino info (backend)

### 3.2 Fingerprint usage (per-route / per-dependency)

| Alert | Fingerprint source |
|-------|-------------------|
| ALT-ERR-01 | `method:path` |
| ALT-ERR-04 / ALT-SLOW-01 | `method:path` |
| ALT-DOWN-02 | `ready` |
| ALT-DB-01 | dependency name |
| ALT-DOWN-04 | endpoint |

**Verified:** Separate fingerprints for same alertId produce separate webhook deliveries (backend `alert-service.test.ts`).

### 3.3 Suppression logging

Suppressed alerts do **not** call webhook — only structured log. Prevents duplicate Slack noise while preserving repeat counts for escalation math.

---

## 4. Escalation flow

### 4.1 Rules

- Repeat count increments on every evaluation (including suppressed)
- Re-send when `repeatCount % ALERT_ESCALATION_THRESHOLD === 0` (default threshold **5**)
- Escalation metadata attached to every allowed send

### 4.2 Verified sequence (default threshold = 5)

| Call # | Webhook sent? | `escalated` | Notes |
|--------|---------------|-------------|-------|
| 1 | Yes | false | Initial alert |
| 2–4 | No | — | Deduplicated |
| 5 | Yes | true | Escalation level 1 |

**Test:** `alert-service.test.ts` → `escalates and re-sends after repeat threshold`.

Downstream systems should treat `escalation.escalated === true` as a signal to page or elevate channel priority.

---

## 5. Production safety

| Control | Status | Detail |
|---------|--------|--------|
| Master switch | ✅ | `MONITORING_ENABLED=false` → `{ sent: false, reason: 'disabled' }` |
| No webhook configured | ✅ | Logs alert locally; no `fetch`; `{ reason: 'no_webhook' }` |
| Webhook delivery failure | ✅ | Caught; logged; does not throw |
| Storm prevention | ✅ | Per-severity caps/min (10 / 30 / 60 defaults) |
| Non-blocking delivery | ✅ | `void sendProductionAlert(...)` on hot paths |
| Prod-only Redis alert | ✅ | `alertRedisUnavailable` gated by `isProduction()` |
| Backward compatibility | ✅ | Backend falls back to `ERROR_TRACKING_WEBHOOK_URL` |
| Existing Sentry / Pino | ✅ | Unchanged; alerts are additive |
| Secrets in payload | ✅ | No tokens or PII in alert metadata by default |

### 5.1 Pre-production checklist

- [ ] Set `MONITORING_ALERT_WEBHOOK_URL` in staging and production
- [ ] Configure webhook receiver to route by `tier` / `severity`
- [ ] Map `alertId` to runbook links in Slack/PagerDuty
- [ ] Deploy external uptime checks (`/ready`, `/api/admin/health/ready`)
- [ ] Confirm `MONITORING_ENABLED=true` in prod manifests
- [ ] Smoke-test: trigger health failure in staging → single webhook received

---

## 6. Coverage vs alerting plan

| Category | Plan catalog | In-app wired | Gap |
|----------|--------------|--------------|-----|
| Downtime (L1) | 8 alerts | 3 (+ health programmatic) | External uptime still required |
| Errors | 9 alerts | 5 | Spike-based rules not in-app |
| Performance | 5 alerts | 1 (per-request slow) | p95 aggregation Phase 2 |
| Database | 6 alerts | 1 | Backup/migration monitors external |
| AI / SLA / Security | 20+ alerts | 0 in-app | Metrics / ops Phase 2 |

**Phase 1 in-app scope is complete.** Full catalog (67 alerts) requires external tooling — see [ALERTING_REMAINING_RISKS.md](./ALERTING_REMAINING_RISKS.md).

---

## 7. Sign-off

| Role | Finding |
|------|---------|
| Engineering | In-app pipeline verified; tests green |
| Ops | Webhook URL + external monitors required before go-live paging |
| Security | No new secrets in repo; webhook URL env-only |

**Recommendation:** Proceed with production deployment of alerting code. Complete ops checklist (§5.1) before treating alerts as on-call paging source.

---

## Document history

| Version | Date | Change |
|---------|------|--------|
| 1.0 | 2026-05-30 | Initial verification after v2.0 implementation |
