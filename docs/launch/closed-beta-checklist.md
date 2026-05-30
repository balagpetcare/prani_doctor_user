# Closed Beta Checklist — Prani Doctor

**Document ID:** `CLOSED_BETA_CHECKLIST`  
**Version:** 1.0  
**Date:** 2026-05-30  
**Companion:** [closed-beta-launch-plan.md](./closed-beta-launch-plan.md)

Use this checklist to track **engineering + ops** readiness for controlled closed beta. Mark items in admin **Launch Operations** (`/admin/launch-ops`) where noted.

---

## A. Launch configuration

| # | Item | Owner | Status | Evidence |
|---|------|-------|--------|----------|
| A1 | `launch.closedBeta.config` seeded (disabled by default) | Backend | ☐ | Setting key in DB / seed-demo |
| A2 | `CLOSED_BETA_ENABLED` documented in `.env.*.example` | DevOps | ☐ | `pranidoctor-backend/.env.staging.example` |
| A3 | `mobile.feature.flags` includes `closedBetaFeedback` | Backend | ☐ | seed-demo |
| A4 | AI governance migrations applied | Backend | ☐ | `AiGovernanceState` table |
| A5 | Kill switch tested on staging (M1/M3) | Ops | ☐ | `/admin/ai-ops/governance` |
| A6 | `MONITORING_ALERT_WEBHOOK_URL` or Sentry DSN set | Ops | ☐ | Test alert received |
| A7 | External uptime on `/ready` + BFF ready | Ops | ☐ | UptimeRobot green |
| A8 | `OTP_MODE=live` on staging/production host | DevOps | ☐ | Env validation pass |

**API:** `GET/PATCH /api/admin/launch/beta-config`

---

## B. Beta access controls

| # | Item | Owner | Status | Evidence |
|---|------|-------|--------|----------|
| B1 | Closed beta config reviewed (`enabled`, caps, cohort) | Product | ☐ | Admin PATCH or DB |
| B2 | Invite list populated (if `enforceInviteList`) | Product | ☐ | `invitedPhones[]` |
| B3 | OTP gate tested: non-invited phone → 403 | QA | ☐ | `CLOSED_BETA_INVITE_REQUIRED` |
| B4 | User cap tested (`enforceUserCap`, max 80) | QA | ☐ | `CLOSED_BETA_USER_CAP` |
| B5 | Auto-tag on first login verified | QA | ☐ | `betaUserTags` updated |
| B6 | Pilot doctors tagged via admin API | Product | ☐ | `POST …/beta-doctors/:id/tag` |
| B7 | Pilot geography seeded | Product | ☐ | Admin areas/doctors |

**APIs:**

- `POST /api/admin/launch/beta-users/:userId/tag`
- `POST /api/admin/launch/beta-doctors/:doctorProfileId/tag`
- Mobile OTP (integrated access check)

---

## C. Operational readiness

| # | Item | Owner | Status | Evidence |
|---|------|-------|--------|----------|
| C1 | Launch ops dashboard loads metrics | Ops | ☐ | `/admin/launch-ops` |
| C2 | [beta-operations-runbook.md](./beta-operations-runbook.md) shared with team | Launch lead | ☐ | War-room link |
| C3 | [incident-response-guide.md](../incident-response-guide.md) contacts filled | Launch lead | ☐ | Wiki (not git) |
| C4 | [ROLLBACK_PLAN.md](./ROLLBACK_PLAN.md) rollback tag recorded | DevOps | ☐ | Image tag |
| C5 | Backup cron installed | DevOps | ☐ | Cron log |
| C6 | On-call roster primary + backup | Launch lead | ☐ | Wiki |
| C7 | AI emergency runbook linked | AI owner | ☐ | `docs/operations/ai-emergency-runbook.md` |

---

## D. Feedback collection

| # | Item | Owner | Status | Evidence |
|---|------|-------|--------|----------|
| D1 | `feedbackEnabled: true` in beta config | Product | ☐ | beta-config |
| D2 | Mobile beta feedback API tested | QA | ☐ | `POST /api/mobile/feedback/beta` |
| D3 | Tickets appear with `[Beta Feedback]` prefix | QA | ☐ | Support DB |
| D4 | [beta-support-playbook.md](./beta-support-playbook.md) triage taxonomy agreed | Product | ☐ | Playbook §2 |
| D5 | Closed beta banner visible on home (when enabled) | QA | ☐ | Flutter `ClosedBetaBanner` |

---

## E. Launch metrics

| # | Item | Owner | Status | Evidence |
|---|------|-------|--------|----------|
| E1 | Beta dashboard shows user/doctor counts | Ops | ☐ | `/api/admin/launch/beta-dashboard` |
| E2 | Consultation completion rate visible | Product | ☐ | Launch ops UI |
| E3 | Emergency SR count tracked | Product | ☐ | Dashboard metric |
| E4 | AI sessions + escalations tracked | AI ops | ☐ | Dashboard + `/admin/ai-ops` |
| E5 | [beta-success-metrics.md](./beta-success-metrics.md) targets agreed | Product | ☐ | Sign-off |

---

## F. Doctor readiness

| # | Item | Owner | Status | Evidence |
|---|------|-------|--------|----------|
| F1 | 3–5 doctors verified in admin | Product | ☐ | `/admin/doctors` |
| F2 | Doctor web login smoke (accept/complete) | QA | ☐ | Smoke report |
| F3 | Emergency participation flags set | Product | ☐ | `acceptsEmergency` |
| F4 | Doctor WhatsApp support channel defined | Product | ☐ | `doctorSupportWhatsapp` in config |
| F5 | Manual assignment SOP understood | Ops | ☐ | Runbook §4 |

---

## G. Support readiness

| # | Item | Owner | Status | Evidence |
|---|------|-------|--------|----------|
| G1 | User support phone/WhatsApp in `mobile.app.config` | Product | ☐ | App settings |
| G2 | In-app support tickets path verified | QA | ☐ | Mobile support flow |
| G3 | Escalation contacts documented | Launch lead | ☐ | Support playbook §5 |
| G4 | Payment manual reconciliation SOP | Product | ☐ | Ops wiki |

---

## H. Go / No-Go (summary)

**GO** when all P0 items in [closed-beta-launch-plan.md §E](./closed-beta-launch-plan.md#e-gonogo-checklist) pass.

**NO-GO** triggers: `/ready` down, OTP failing, doctor loop broken, prohibited ETA copy live.

| Role | Name | Date | Decision |
|------|------|------|----------|
| Launch lead | | | GO / NO-GO |
| Engineering | | | |
| Product | | | |
| Legal | | | |

---

*Update this checklist at T-7, T-1, and T+7 per [closed-beta-launch-plan.md §F](./closed-beta-launch-plan.md#f-launch-timeline).*
