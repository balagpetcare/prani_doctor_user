# Beta Operations Runbook — Prani Doctor

**Document ID:** `BETA_OPERATIONS_RUNBOOK`  
**Version:** 1.0  
**Date:** 2026-05-30  
**Audience:** Launch lead, on-call engineer, product ops  
**Companion:** [closed-beta-launch-plan.md](./closed-beta-launch-plan.md) · [LAUNCH_DAY_RUNBOOK.md](./LAUNCH_DAY_RUNBOOK.md)

---

## 1. Purpose

Day-to-day operations for the **controlled closed beta**: cohort ramp, config changes, monitoring, incident response, and rollback — without public production exposure.

---

## 2. Launch configuration

### 2.1 Setting key

All closed-beta controls persist in PostgreSQL:

| Key | Purpose |
|-----|---------|
| `launch.closedBeta.config` | Cohort, caps, invites, tags, banners, support contacts |
| `mobile.app.config` | Support phone/WhatsApp (farmer-facing) |
| `mobile.feature.flags` | Feature toggles including `closedBetaFeedback` |

**Env overrides (optional):**

| Variable | Effect |
|----------|--------|
| `CLOSED_BETA_ENABLED=true` | Forces beta mode on (overrides DB `enabled`) |
| `CLOSED_BETA_ENFORCE_INVITE=true` | Forces invite-list gate |

### 2.2 Admin APIs

| Method | Path | Purpose |
|--------|------|---------|
| GET/PATCH | `/api/admin/launch/beta-config` | Read/update beta config |
| GET | `/api/admin/launch/beta-dashboard` | Live beta KPI snapshot |
| POST | `/api/admin/launch/beta-users/:userId/tag` | Tag farmer cohort |
| POST | `/api/admin/launch/beta-doctors/:doctorProfileId/tag` | Tag pilot doctor |

**UI:** `/admin/launch-ops` — health probes + beta dashboard tiles.

### 2.3 Enabling closed beta (staging)

1. Set `CLOSED_BETA_ENABLED=true` **or** PATCH config `{ "enabled": true, "activeCohort": "C0" }`.
2. Start with `enforceInviteList: false` for internal C0; enable before C1 friendly users.
3. Confirm mobile `GET /api/mobile/app-config` returns `closedBeta` block.
4. Verify home banner (Flutter) and OTP flow for invited numbers.

### 2.4 AI controls

| Control | Surface | Action |
|---------|---------|--------|
| LLM kill switch | `/admin/ai-ops/governance` | Disable global LLM; rules fallback continues |
| Per-feature scope | Same panel | Disable `CHAT`, `FARM_BRIEFING`, etc. |
| Emergency | [ai-emergency-runbook.md](../../pranidoctor-backend/docs/operations/ai-emergency-runbook.md) | Break-glass internal API |

**Health:** `GET /health/ai` — `llmDisabled`, `governanceHydrated`.

---

## 3. Cohort ramp procedure

Follow [closed-beta-launch-plan.md §B](./closed-beta-launch-plan.md#b-beta-cohorts). **Max ~80 users** until day-7 review.

| Step | Action |
|------|--------|
| 1 | Complete checklist for target cohort |
| 2 | Update `activeCohort` in beta config |
| 3 | Add phones to `invitedPhones` if enforce list on |
| 4 | Send Play closed-testing invites (farmers) or doctor credentials |
| 5 | Monitor `/admin/launch-ops` for 48h before next cohort |
| 6 | Pause ramp if rollback criteria triggered (plan §A.6) |

---

## 4. Doctor operations

### 4.1 Onboarding (manual)

1. Create/verify doctor in `/admin/doctors`.
2. Set working areas + service categories.
3. Set `acceptsEmergency` if pilot includes emergency SRs.
4. Tag: `POST /api/admin/launch/beta-doctors/:id/tag` with `{ "cohort": "C3" }`.
5. Send web login URL + WhatsApp ops group invite.
6. Run accept/complete smoke on staging.

### 4.2 Assignment

- **No auto-routing** in beta — admin manually assigns via `/admin/service-requests`.
- Ops on-call during pilot hours for pending backlog > 15 min (OPS-REQ alerts).

---

## 5. Monitoring & alerting

### 5.1 Phase 0 minimum (pre-launch)

| Signal | Tool | Threshold |
|--------|------|-----------|
| API `/ready` | UptimeRobot | 2 failures → page |
| BFF ready | UptimeRobot | 2 failures |
| 5xx / uncaught | Webhook / Sentry | SEV-1 |
| Backup stale | Cron check | > 26h SEV-2 |

See [production-monitoring-plan.md](./production-monitoring-plan.md) §7.2.

### 5.2 Beta dashboard metrics

Refresh at `/admin/launch-ops` or `GET /api/admin/launch/beta-dashboard`:

- Beta users tagged / cap remaining  
- Registrations & activations (7d)  
- Consultations pending / completion rate  
- Emergency SR count  
- AI sessions, open escalations, LLM status  
- Beta feedback tickets (7d)

### 5.3 Escalation matrix

| Severity | Example | Response | Channel |
|----------|---------|----------|---------|
| SEV-1 | API down, auth breach | ≤ 15 min ack | On-call + `#incidents` |
| SEV-2 | OTP failures, AI backlog | ≤ 1 hour | `#pranidoctor-alerts` |
| SEV-3 | Support ticket aging | Business hours | Product lead |

Full playbook: [incident-response-guide.md](../incident-response-guide.md).

---

## 6. Rollback & pause

### 6.1 Pause beta (no deploy)

1. Set `enabled: false` in beta config **or** halt Play rollout.
2. Set `maintenanceMode: true` in `mobile.app.config` if hard block needed.
3. Notify cohorts via WhatsApp template (support playbook).

### 6.2 Application rollback

Follow [ROLLBACK_PLAN.md](./ROLLBACK_PLAN.md) — redeploy prior API/web image tag. **No DB migration rollback** for ordinary bugs.

### 6.3 AI incident

1. Disable LLM in governance panel.  
2. Review `AiEscalationRecord` backlog.  
3. Post-mortem ≤ 72h.

---

## 7. Daily ops rhythm (launch week)

| Time | Task | Owner |
|------|------|-------|
| Morning | Check launch-ops dashboard + uptime | On-call |
| Morning | Triage `[Beta Feedback]` tickets | Product |
| Midday | Review pending service requests | Ops |
| Evening | Slack summary: installs, OTP, SRs, crashes | Launch lead |
| Weekly | Cohort review vs [beta-success-metrics.md](./beta-success-metrics.md) | Leadership |

---

## 8. Related documents

| Doc | Use |
|-----|-----|
| [closed-beta-checklist.md](./closed-beta-checklist.md) | Pre-launch gates |
| [beta-support-playbook.md](./beta-support-playbook.md) | User/doctor support |
| [beta-success-metrics.md](./beta-success-metrics.md) | KPI targets |
| [ROLLBACK_PLAN.md](./ROLLBACK_PLAN.md) | Deploy rollback |
| [KNOWN_LIMITATIONS.md](./KNOWN_LIMITATIONS.md) | Accepted beta limits |

---

*Configuration-first changes do not require app redeploy. Tag API and dashboard require backend + web deploy.*
