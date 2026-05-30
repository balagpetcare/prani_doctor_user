# GA Support Playbook — Prani Doctor

**Document ID:** `GA_SUPPORT_PLAYBOOK`  
**Version:** 1.0  
**Date:** 2026-06-01  
**Audience:** Product support, launch ops, doctor coordinators  
**Companion:** [beta-support-playbook.md](./beta-support-playbook.md) (supersedes for GA tier)

---

## 1. Support channels & SLAs

| Audience | Primary | Secondary | SLA |
|----------|---------|-----------|-----|
| **Farmers** | In-app ticket | Phone/WhatsApp (published in app config) | P0: 1h · P1: 4h BH · P2: 24h |
| **Doctors** | WhatsApp doctor ops | Admin phone | 2h BH |
| **Internal** | War room | On-call | Immediate |

Configure in `mobile.app.config` + `launch.ga.config` ownership fields.

---

## 2. Triage taxonomy

| Tag | Examples | Priority | Route |
|-----|----------|----------|-------|
| `crash` | App crash, white screen | P0 | Mobile on-call |
| `otp` | SMS failure | P0 | Backend + SMS provider |
| `booking` | SR stuck | P1 | Ops + admin assign |
| `doctor` | Panel login/complete | P1 | Web on-call |
| `payment` | Manual payment confusion | P2 | Product ops ([ga-runbook.md](./ga-runbook.md)) |
| `ai-safety` | Harmful AI output | P0 | AI kill switch owner |
| `copy/legal` | Misleading copy | P0 | Legal + hotfix |
| `livestock` | Feed/offline sync | P2 | Engineering backlog |
| `ga-feedback` | `[GA Feedback]` tickets | P2 | Product |

**Rule:** Triage all tickets within **24h**; P0 within **1h**.

---

## 3. User support flow

| Issue | First response | Action |
|-------|----------------|--------|
| OTP not received | Wait 60s; retry; check signal | SMS logs |
| Cannot register | Verify phone format + cap | Check weekly cap |
| Request pending | No ETA promises; assign soon | Admin assign |
| Payment | Manual beta/GA process | Billing SOP |
| AI concern | Educational only; contact vet if urgent | Review session |

### Prohibited language

No doctor arrival times, guaranteed outcomes, or emergency dispatch language. See [legal-safe-messaging-plan.md](./legal-safe-messaging-plan.md).

---

## 4. Doctor support flow

| Issue | Action |
|-------|--------|
| Cannot log in | Admin credential reset |
| No requests | Verify areas + assignment |
| Complete error | Capture SR ID; web on-call |
| Emergency SR | Confirm `acceptsEmergency`; manual workflow |

**Weekly:** Doctor cohort call during soft launch.

---

## 5. Escalation

Support → Product lead → On-call → Launch lead → Rollback authority.

Fill ownership in GA config (`ownership.*`) — store contact details in wiki, not git.

See [ga-war-room-procedures.md](./ga-war-room-procedures.md) for SEV-1.

---

## 6. GA vs beta differences

| Item | Beta | GA |
|------|------|-----|
| SLA | 4h BH (C1) | Tiered 1h/4h/24h |
| Cap | Invite + 80 users | Weekly registration cap |
| Feedback prefix | `[Beta Feedback]` | `[GA Feedback]` (when enabled) |
| WhatsApp pilot | C1 only | Published support line |

---

*Brief support team using [ga-war-room-procedures.md](./ga-war-room-procedures.md) §Support briefing before soft launch.*
