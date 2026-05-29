# Monitoring Guide — Prani Doctor

**Version:** 1.1 · Phase 6

## Alerting

Full platform alert catalog, severity matrix, and escalation workflow: [production/monitoring/alerting-plan.md](./production/monitoring/alerting-plan.md).

Implementation: [production/monitoring/ALERTING_IMPLEMENTATION.md](./production/monitoring/ALERTING_IMPLEMENTATION.md) — deduplicated webhook alerts on API + admin web (`sendProductionAlert`).

Verification: [ALERTING_READINESS_REPORT.md](./production/monitoring/ALERTING_READINESS_REPORT.md) · [ALERTING_REMAINING_RISKS.md](./production/monitoring/ALERTING_REMAINING_RISKS.md)

## Health endpoints

| Service | Liveness | Readiness | Aggregate |
|---------|----------|-----------|-----------|
| Backend | `GET /live` | `GET /ready` | `GET /health` |
| Web | `GET /api/health` | `GET /api/admin/health/ready` | — |

Configure uptime checks every 60s on `/ready` (backend) and `/api/health` (web).

## Metrics (backend)

- Prometheus text: `GET /metrics` with `Authorization: Bearer $METRICS_TOKEN`
- JSON: `GET /metrics/json?token=$METRICS_TOKEN` (if token set)
- **AI series (v1.1):** `ai_requests_total`, `ai_request_duration_seconds`, `ai_tokens_total`, `ai_cost_usd_total`, `ai_fallbacks_total`, `ai_llm_disabled`
- **Token rollups (B1):** `AiUsageUserDailyRollup`, `AiUsageCustomerDailyRollup` — see [token-tracking-plan.md](./production/ai/token-tracking-plan.md)

Disable with `METRICS_ENABLED=false`.

## Logging

- **Backend:** Pino JSON (`LOG_FORMAT=json` in production). Redacts tokens/passwords.
- **Web:** `server-logger.ts` with correlation IDs (`X-Request-Id`).
- **Mobile:** `AppLogger` + `LogRedactor`; no network logs in release.

## Error tracking

| Repo | Hook |
|------|------|
| Backend | `SENTRY_DSN` + `ERROR_TRACKING_WEBHOOK_URL` → `captureException` (5xx, jobs, uncaught) |
| Web | `SENTRY_DSN` / `NEXT_PUBLIC_SENTRY_DSN`; provider `sentry` when DSN set |
| Mobile | `SENTRY_DSN` dart-define → `SentryCrashReporter` + Crashlytics/webhook composite; see [sentry-integration-plan.md](./production/monitoring/sentry-integration-plan.md) |

## Recommended alerts

See [alerting-plan.md](./alerting-plan.md) for the full catalog. Phase 1 minimum:

- 5xx rate > 1% for 5 minutes  
- `/ready` non-200  
- Redis down (backend rate limit 503 spike)  
- Backup job failure  
- Disk > 85% on VPS
