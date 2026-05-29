# Monitoring Guide — Prani Doctor

**Version:** 1.0 · Phase 6

## Health endpoints

| Service | Liveness | Readiness | Aggregate |
|---------|----------|-----------|-----------|
| Backend | `GET /live` | `GET /ready` | `GET /health` |
| Web | `GET /api/health` | `GET /api/admin/health/ready` | — |

Configure uptime checks every 60s on `/ready` (backend) and `/api/health` (web).

## Metrics (backend)

- Prometheus text: `GET /metrics` with `Authorization: Bearer $METRICS_TOKEN`
- JSON: `GET /metrics/json?token=$METRICS_TOKEN` (if token set)

Disable with `METRICS_ENABLED=false`.

## Logging

- **Backend:** Pino JSON (`LOG_FORMAT=json` in production). Redacts tokens/passwords.
- **Web:** `server-logger.ts` with correlation IDs (`X-Request-Id`).
- **Mobile:** `AppLogger` + `LogRedactor`; no network logs in release.

## Error tracking

| Repo | Hook |
|------|------|
| Backend | `ERROR_TRACKING_WEBHOOK_URL` → `captureException` in error handler |
| Web | `ERROR_TRACKING_PROVIDER=webhook` in monitoring module |
| Mobile | Wire Sentry/Crashlytics in `bootstrap.dart` (Phase 6 stub ready) |

## Recommended alerts

- 5xx rate > 1% for 5 minutes  
- `/ready` non-200  
- Redis down (backend rate limit 503 spike)  
- Backup job failure  
- Disk > 85% on VPS
