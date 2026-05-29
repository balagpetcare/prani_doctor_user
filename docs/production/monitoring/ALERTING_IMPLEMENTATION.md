# Production Alerting — Implementation Report

**Version:** 1.0  
**Date:** 2026-05-30  
**Plan:** [alerting-plan.md](./alerting-plan.md)

---

## Summary

Production alerting is **implemented in code** on the API and admin web layers. Mobile continues to use crash webhooks (see [flutter-crash-reporting-plan](../mobile/flutter-crash-reporting-plan.md)). All alerts flow through a shared **`sendProductionAlert`** pipeline with:

- **Three tiers:** `critical`, `warning`, `info`
- **Deduplication** by `alertId` + optional `fingerprint` (15 min default window)
- **Escalation** — re-notify when repeat count hits `ALERT_ESCALATION_THRESHOLD`
- **Storm prevention** — per-severity per-minute caps
- **Existing workflows preserved** — Sentry, Pino logs, incident-response runbooks unchanged

---

## Alert tiers → severity mapping

| Tier | `severity` field | Page on-call? | Storm cap/min |
|------|------------------|---------------|---------------|
| Critical | `critical` | Yes (via webhook/PagerDuty) | 10 |
| Warning | `warning` | Slack | 30 |
| Informational | `info` | Digest / optional | 60 |

---

## Wired alert IDs (Phase 1 code)

### Backend (`pranidoctor-backend`)

| Alert ID | Trigger | Tier |
|----------|---------|------|
| ALT-DOWN-02 | `/ready` returns 503 | Critical |
| ALT-DB-01 | `/health/db` unhealthy | Critical |
| ALT-DB-01 | `/health/redis` unhealthy (prod) | Critical |
| ALT-ERR-01 | Express 5xx via error handler | Warning |
| ALT-ERR-02 | `uncaughtException` / `unhandledRejection` | Critical |

### Admin web (`pranidoctor-web`)

| Alert ID | Trigger | Tier |
|----------|---------|------|
| ALT-DOWN-04 | `/api/admin/health` backend down | Critical |
| ALT-ERR-03 | Next.js `onRequestError` | Critical |
| ALT-ERR-03 | `captureException` (deduped) | Critical |
| ALT-ERR-04 | Admin proxy 5xx | Warning |
| ALT-SLOW-01 | Admin proxy slow (threshold exceeded) | Warning |

---

## Webhook payload (v2)

```json
{
  "event": "production.alert",
  "alertId": "ALT-DOWN-04",
  "title": "Admin health check failed",
  "message": "/api/admin/health — Backend API unreachable",
  "severity": "critical",
  "tier": "critical",
  "service": "pranidoctor-web-admin",
  "environment": "production",
  "version": "1.0.0",
  "timestamp": "2026-05-30T12:00:00.000Z",
  "escalation": {
    "repeatCount": 1,
    "escalated": false,
    "escalationLevel": 0,
    "deduplicated": false
  },
  "runbook": "docs/incident-response-guide.md",
  "metadata": { "endpoint": "/api/admin/health" }
}
```

Suppressed duplicates log `monitoring.alert.suppressed` (no webhook).

---

## Ops checklist

- [ ] Set `MONITORING_ALERT_WEBHOOK_URL` on web + API hosts (same Slack incoming webhook OK)
- [ ] Configure PagerDuty route for payloads where `severity=critical`
- [ ] External uptime on `/ready` and `/api/admin/health/ready` (complements in-app alerts)
- [ ] Run fire drill: stop API container → verify single critical alert (not storm)
- [ ] Document on-call rotation in team wiki

---

## Document history

| Date | Change |
|------|--------|
| 2026-05-30 | v1.0 — Initial implementation report |
| 2026-05-30 | Verification: [ALERTING_READINESS_REPORT.md](./ALERTING_READINESS_REPORT.md), [ALERTING_REMAINING_RISKS.md](./ALERTING_REMAINING_RISKS.md) |
