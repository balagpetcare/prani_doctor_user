# GA War Room Procedures — Prani Doctor

**Document ID:** `GA_WAR_ROOM_PROCEDURES`  
**Version:** 1.0  
**Date:** 2026-06-01  
**Companion:** [incident-response-guide.md](../incident-response-guide.md) · [ga-runbook.md](./ga-runbook.md)

---

## 1. War room activation

| Trigger | Activate? |
|---------|:---------:|
| API `/ready` down > 5 min | Yes |
| SEV-1 any cause | Yes |
| OTP success < 85% for 1h | Yes |
| Confirmed AI safety incident | Yes |
| Crash-free < 98% for 24h | Yes |
| 5xx > 5% for 10 min | Yes |

**Channel:** Configure URL in `launch.ga.config.monitoringLinks.warRoom` (Slack/WhatsApp — wiki holds invite).

---

## 2. Incident ownership

| Role | Responsibility |
|------|----------------|
| **Incident commander** | Timeline, decisions, comms approval |
| **SRE on-call** | Infra, deploy, rollback execution |
| **Backend on-call** | API, DB, SMS, queue |
| **Mobile on-call** | Play rollout pause, hotfix |
| **AI safety owner** | Kill switch, escalation queue |
| **Legal liaison** | Copy, breach, user comms review |
| **Rollback authority** | Approves image rollback + Play pause |

Assign names in GA config `ownership` (roles only in git; contacts in wiki).

---

## 3. Escalation matrix (GA)

| Severity | Example | Response | Update cadence |
|----------|---------|----------|----------------|
| SEV-1 | Outage, breach, AI harm | 15 min | Every 15 min |
| SEV-2 | OTP degraded, 5xx spike | 1 h | Every 30 min |
| SEV-3 | Single feature | 1 day | Daily |

---

## 4. Recovery expectations

| Scenario | RTO | First action |
|----------|-----|--------------|
| Bad deploy | 15 min | Rollback API/web tag |
| Redis down | 30 min | Restart redis |
| DB issue | 4 h | Stop writes; assess backup |
| Play bad release | 1 h | Pause staged rollout |
| AI provider down | 5 min | Enable kill switch |

---

## 5. Incident communication

### 5.1 Internal template

> **Incident:** [title]  
> **Severity:** SEV-X  
> **Start:** [UTC]  
> **Impact:** [users affected / features]  
> **Commander:** [name]  
> **Status:** Investigating / Mitigating / Resolved  
> **Next update:** [time]

### 5.2 User-facing (outage > 30 min)

> Prani Doctor is experiencing technical difficulties. Our team is working to restore service. For urgent animal emergencies, contact a local veterinarian directly. We apologize for the inconvenience.

**BN:** Provide Bengali equivalent — no ETA promises.

### 5.3 Doctor comms

WhatsApp doctor ops group: brief factual update + expected ops impact (manual assign may delay).

---

## 6. Support team briefing (pre-launch)

| Topic | Cover |
|-------|-------|
| GA SLAs | [ga-support-playbook.md](./ga-support-playbook.md) §1 |
| Prohibited language | No ETA / dispatch |
| P0 routes | crash, otp, ai-safety, copy/legal |
| War room trigger | When to page on-call |
| Payment | Manual reconciliation SOP |
| Escalation | Support → lead → on-call |

---

## 7. Internal launch communication

| Audience | When | Content |
|----------|------|---------|
| Engineering | T-7 | GA checklist, on-call rotation |
| Support | T-3 | Playbook walkthrough |
| Doctors | T-1 | Login URL, ops hours, WhatsApp group |
| Board | T-1 | Readiness scores + GO vote |
| All staff | T-0 | Soft launch live; war room link |

---

## 8. Post-incident

1. Resolve and confirm metrics green.  
2. Blameless post-mortem within **72h**.  
3. Update checklist items if process gap found.  
4. PATCH gate review via `POST /api/admin/launch/ga-readiness`.

---

## 9. Dry-run checklist

| Step | Pass |
|------|:----:|
| War room channel created | ☐ |
| All ownership roles named | ☐ |
| On-call receives test page | ☐ |
| Rollback tag identified | ☐ |
| Kill switch M1 drill | ☐ |
| Comms templates approved | ☐ |

---

*Store tabletop notes in war-room drive; link from gate checklist L4 evidence field.*
