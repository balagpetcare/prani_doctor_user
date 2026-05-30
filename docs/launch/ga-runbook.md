# GA Operations Runbook — Prani Doctor

**Document ID:** `GA_OPERATIONS_RUNBOOK`  
**Version:** 1.0  
**Date:** 2026-06-01  
**Audience:** Launch lead, SRE, product ops  
**Companion:** [general-availability-launch-plan.md](./general-availability-launch-plan.md) · [ga-checklist.md](./ga-checklist.md)

---

## 1. GA configuration

### 1.1 Setting key

| Key | Purpose |
|-----|---------|
| `launch.ga.config` | Phase, caps, ownership, gate checklist, Go/No-Go |

**Env overrides:**

| Variable | Effect |
|----------|--------|
| `GA_LAUNCH_ENABLED=true` | Forces GA mode on |
| `GA_LAUNCH_PHASE=SOFT_LAUNCH` | Overrides DB phase |

### 1.2 Admin APIs

| Method | Path | Purpose |
|--------|------|---------|
| GET/PATCH | `/api/admin/launch/ga-config` | Config + checklist |
| GET | `/api/admin/launch/ga-dashboard` | GA KPI snapshot |
| GET/POST | `/api/admin/launch/ga-readiness` | Readiness scores + gate review |

**UI:** `/admin/launch-ops` → General availability panel.

### 1.3 Enabling soft launch

1. Confirm [ga-checklist.md](./ga-checklist.md) P0 pass or board waivers.
2. Set `closedBeta.enabled: false` via beta-config PATCH.
3. PATCH GA config: `{ "phase": "SOFT_LAUNCH", "playRolloutPct": 10, "weeklyRegistrationCap": 500 }`.
4. **Do not** set `GA_LAUNCH_ENABLED=true` until board GO recorded.
5. Monitor GA dashboard 48h before increasing Play rollout.

---

## 2. Phased rollout

| Phase | Play % | Weekly cap | Districts | Marketing |
|-------|-------:|-----------:|-----------|-----------|
| SOFT_LAUNCH | 10 | 500 | 2 | None paid |
| GRADUAL_ROLLOUT | 50 | 2,000 | 5 | Organic only |
| FULL_LAUNCH | 100 | null | National | Full campaign |
| PAUSED | hold | — | — | Stop acquisition |

Advance phase only when [ga-success-metrics.md](./ga-success-metrics.md) targets met for 7 days.

---

## 3. Scaling readiness (no architecture change)

### 3.1 API

| Signal | Action |
|--------|--------|
| p95 > 1s sustained | Scale API container ×2 in compose |
| 5xx > 0.5% | Rollback; investigate |
| Event loop lag alert | Check memory; restart API |

**Gate:** k6 20 RPS load test before soft launch (checklist H7).

### 3.2 Database

| Signal | Action |
|--------|--------|
| Connections > 80% max | Tune pool; plan read replica |
| Slow queries rising | Index review; `pg_stat_statements` |
| Disk > 70% | Expand volume; archive logs |

### 3.3 Queue

| Signal | Action |
|--------|--------|
| `queue_waiting > 100` | Split worker container |
| Failed jobs spike | [runbook.md](../../pranidoctor-backend/docs/monitoring/runbook.md) §Queue |

### 3.4 Notifications

| Channel | GA requirement |
|---------|----------------|
| SMS OTP | Provider quota ≥ 10k/mo |
| FCM | Required (`ENABLE_PUSH=true`) |
| In-app | Default fallback |

### 3.5 AI workload

| Signal | Action |
|--------|--------|
| Cost > daily budget | Throttle scopes; review prompts |
| Provider outage | Kill switch → rules fallback |
| Escalation backlog | Staff AI ops queue |

---

## 4. Production readiness validation

| Control | Verify |
|---------|--------|
| Monitoring | Uptime + Grafana links in `monitoringLinks` |
| Alerting | Webhook test event |
| Backups | Cron + file age < 24h |
| Recovery | Restore drill log |
| Kill switch | `/admin/ai-ops/governance` + drill log |
| Compliance | Launch ops compliance panel green |

Run: `GET /api/admin/launch/ga-readiness` before each phase gate.

---

## 5. Rollback

See [ROLLBACK_PLAN.md](./ROLLBACK_PLAN.md) and GA triggers GA-RB-01–08 in [general-availability-launch-plan.md](./general-availability-launch-plan.md).

| Action | Owner |
|--------|-------|
| Pause Play rollout | Mobile on-call |
| Rollback API/web image | DevOps |
| PATCH `phase: "PAUSED"` | Launch lead |
| Comms template | [ga-war-room-procedures.md](./ga-war-room-procedures.md) |

---

## 6. Daily ops (GA week 1)

| Time | Action |
|------|--------|
| 08:00 BDT | Review GA dashboard + readiness scores |
| 12:00 | Doctor backlog check; assign pending SRs |
| 18:00 | Support ticket triage; AI escalation queue |
| 22:00 | On-call handoff note |

---

*Production-safe: config disabled by default. No automatic traffic enable.*
