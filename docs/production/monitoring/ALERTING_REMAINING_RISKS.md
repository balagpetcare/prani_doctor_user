# Production Alerting — Remaining Risks Report

**Version:** 1.0  
**Date:** 2026-05-30  
**Related:** [ALERTING_READINESS_REPORT.md](./ALERTING_READINESS_REPORT.md) · [alerting-plan.md](./alerting-plan.md)

---

## Executive summary

The in-app alerting pipeline is **functionally ready**, but **full production paging coverage is not complete**. This report lists residual risks by severity, owner, and recommended mitigation.

| Risk level | Count | Launch blocker? |
|------------|-------|---------------|
| **High** | 4 | 2 are ops blockers (external monitors, webhook config) |
| **Medium** | 6 | No — mitigatable post-launch |
| **Low** | 5 | No |

---

## High priority

### R1 — External uptime monitors not in repo (ops-owned)

**Risk:** Synthetic downtime (ALT-DOWN-01, ALT-DOWN-03, ALT-DOWN-05, ALT-DOWN-06) will not page until UptimeRobot / Better Stack / k8s probes are configured.

**Impact:** Process crash or network partition may go unnoticed if in-app hooks never run.

**Mitigation:**
- Configure probes per [alerting-plan.md § Phase 1](./alerting-plan.md)
- Minimum: `GET /ready`, `GET /live`, `GET /api/admin/health/ready`

**Owner:** Ops / DevOps  
**Target:** Before go-live

---

### R2 — Webhook URL not configured in production

**Risk:** Without `MONITORING_ALERT_WEBHOOK_URL`, alerts log locally only (`reason: no_webhook`). No Slack/PagerDuty delivery.

**Impact:** All wired in-app alerts are silent to on-call.

**Mitigation:** Set webhook in staging + prod secrets; smoke-test one critical path.

**Owner:** Ops  
**Target:** Before go-live

---

### R3 — In-memory deduplication is single-process

**Risk:** `AlertDeduplicator` state lives in each Node process. With **multiple API or web replicas**, the same alert can fire once per instance.

**Impact:** Duplicate notifications during incidents (partial storm protection only per pod).

**Mitigation (short term):**
- Acceptable for small replica counts if webhook receiver dedupes by `alertId` + time bucket
- Tune storm caps conservatively

**Mitigation (Phase 2):**
- Redis-backed dedup store shared across instances
- Or delegate dedup to Alertmanager / PagerDuty event orchestration

**Owner:** Engineering  
**Target:** Phase 2 if scaling beyond 2 replicas

---

### R4 — Dual webhook delivery on admin `captureException`

**Risk:** `error-tracking.ts` sends **two** webhook posts on each exception:
1. Legacy `postWebhookEvent("exception", …)` — raw exception shape
2. `sendProductionAlert` — v2 `production.alert` shape (deduped)

**Impact:** Duplicate Slack messages for the same error during rollout; confusing routing rules.

**Mitigation:**
- Configure receiver to ignore `event: exception` once v2 is confirmed
- Or remove `postWebhookEvent` for exceptions in a follow-up PR

**Owner:** Engineering  
**Target:** Within 2 weeks post-launch

---

## Medium priority

### R5 — Per-event alerts vs spike-based rules

**Risk:** Plan defines ALT-ERR-01 and ALT-ERR-04 as **rate/spike** alerts (>1% 5xx, >5% proxy 5xx). Code fires **one alert per 5xx response** (deduped per route).

**Impact:** Sustained low-rate errors may not page; single burst on many routes may still produce many distinct fingerprints.

**Mitigation:** Add log/metrics aggregation (Loki, Prometheus) for spike rules; keep per-event as early signal.

**Owner:** Engineering / Ops  
**Target:** Phase 2 (Prometheus + Alertmanager)

---

### R6 — ALT-SLOW-01 is per-request, not p95

**Risk:** Slow proxy alert fires when **individual** requests exceed threshold, not when p95 breaches over 15 minutes (plan ALT-SLOW-01 / ALT-SLOW-02).

**Impact:** Noisy warnings on occasional slow requests; may miss sustained degradation if individual requests stay under threshold.

**Mitigation:** Log aggregation for p95; tune `ADMIN_SLOW_PROXY_THRESHOLD_MS`.

**Owner:** Engineering  
**Target:** Phase 2

---

### R7 — Informational tier not wired

**Risk:** `sendInformationalAlert` exists but no production callers. ALT-INFO-* catalog entries have no in-app source.

**Impact:** No automated digest-style notifications (deploy notices, quota warnings).

**Mitigation:** Wire deploy hooks and quota checks when needed; low urgency.

**Owner:** Engineering  
**Target:** Post-launch backlog

---

### R8 — `ALERT_*` env read at module import

**Risk:** Deduplicator is constructed once at module load. Changing `ALERT_DEDUP_WINDOW_MS` or storm caps requires process restart.

**Impact:** Low — env vars are static in production; hot reload not expected.

**Mitigation:** Document in runbook; restart pods after alert tuning.

**Owner:** Engineering  
**Target:** Documentation only

---

### R9 — No webhook authentication

**Risk:** Alert webhooks are unsigned POSTs. A leaked URL allows spoofed alerts.

**Impact:** False-positive pages or alert channel noise.

**Mitigation:**
- Use Slack incoming webhook with secret path
- PagerDuty Events API v2 with routing key in URL
- Optional: HMAC signing in Phase 2

**Owner:** Security / Ops  
**Target:** Use provider-native secrets; signing optional Phase 2

---

### R10 — Mobile alerts on separate path

**Risk:** Flutter uses `CRASH_REPORTING_WEBHOOK_URL` / Crashlytics, not `production.alert` v2 schema.

**Impact:** Unified alert routing requires separate rules for mobile vs API/admin.

**Mitigation:** Webhook receiver normalizes mobile events; documented in [flutter-crash-reporting-plan](../mobile/flutter-crash-reporting-plan.md).

**Owner:** Mobile / Ops  
**Target:** Configure parallel routing rules at launch

---

## Low priority

### R11 — Redis alert ID catalog mismatch

**Risk:** Redis unhealthy uses `ALT-SEC-02` in code vs `ALT-DB-*` / dependency naming in plan.

**Impact:** Runbook lookup by ID may need cross-reference.

**Mitigation:** Align ID in follow-up or document mapping in webhook receiver.

**Owner:** Engineering  
**Target:** Optional cleanup

---

### R12 — Backend `captureException` does not call `sendProductionAlert`

**Risk:** Backend errors go to Sentry hook + optional `notifyErrorWebhook` (legacy shape), while 5xx also triggers ALT-ERR-01 separately.

**Impact:** Two channels for related signals; not duplicate if webhook receiver filters by event type.

**Mitigation:** Consolidate backend error webhook to v2 schema in Phase 2.

**Owner:** Engineering  
**Target:** Backlog

---

### R13 — Webhook HTTP response not validated

**Risk:** `fetch` success is not checked for `response.ok`. 4xx/5xx from receiver still returns `{ sent: true }`.

**Impact:** Silent delivery failures if receiver rejects payload.

**Mitigation:** Check `response.ok`; retry with backoff (Phase 2).

**Owner:** Engineering  
**Target:** Backlog

---

### R14 — No alert delivery metrics

**Risk:** No Prometheus counters for `alerts_sent_total`, `alerts_suppressed_total`, `alerts_storm_suppressed_total`.

**Impact:** Cannot dashboard alert pipeline health.

**Mitigation:** Add counters when `/metrics` middleware matures.

**Owner:** Engineering  
**Target:** Phase 2

---

### R15 — Escalation is in-process only

**Risk:** Escalation re-fires webhook with metadata but does not auto-page a secondary on-call tier without receiver-side rules.

**Impact:** Escalation depends on Slack/PagerDuty interpreting `escalation.escalated`.

**Mitigation:** Configure PagerDuty escalation policy on `escalationLevel >= 1`.

**Owner:** Ops  
**Target:** Webhook receiver config at launch

---

## Risk matrix

| ID | Risk | Likelihood | Impact | Priority |
|----|------|------------|--------|----------|
| R1 | No external uptime | High if skipped | SEV-1 blind spot | **High** |
| R2 | No webhook URL | High if skipped | No paging | **High** |
| R3 | Multi-replica dedup | Medium | Duplicate noise | **High** |
| R4 | Dual exception webhooks | High (web errors) | Duplicate noise | **High** |
| R5 | Spike vs per-event | Medium | Under/over alert | Medium |
| R6 | Slow p95 vs per-request | Medium | Noisy / missed | Medium |
| R7 | Info tier unwired | Low | Missing digests | Medium |
| R8 | Env at import | Low | Ops confusion | Medium |
| R9 | No webhook auth | Low | Spoofing | Medium |
| R10 | Mobile separate path | Certain | Split routing | Medium |
| R11 | Redis alert ID | Low | Runbook friction | Low |
| R12 | Backend legacy webhook | Low | Split schema | Low |
| R13 | No response.ok check | Low | Silent fail | Low |
| R14 | No alert metrics | Medium | No visibility | Low |
| R15 | Escalation receiver-side | Medium | Manual policy | Low |

---

## Recommended launch sequence

1. **Block launch:** Configure R1 + R2 (external probes + webhook URL)
2. **Week 1:** Resolve R4 (remove legacy exception webhook or filter at receiver)
3. **Week 2–4:** R5, R6 via log/metrics stack; R3 if replica count > 2
4. **Phase 2:** Prometheus Alertmanager, Redis dedup, alert metrics (R14)

---

## Document history

| Version | Date | Change |
|---------|------|--------|
| 1.0 | 2026-05-30 | Initial risk assessment after alerting verification |
