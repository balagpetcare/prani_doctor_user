# Beta Support Playbook — Prani Doctor

**Document ID:** `BETA_SUPPORT_PLAYBOOK`  
**Version:** 1.0  
**Date:** 2026-05-30  
**Audience:** Product support, launch ops, pilot doctor coordinators

---

## 1. Support channels

| Audience | Primary channel | Secondary | SLA (beta) |
|----------|-----------------|-----------|------------|
| **Farmers (C1–C2)** | In-app support ticket | WhatsApp pilot group (C1 only) | C1: 4h BH · C2: 24h |
| **Doctors (C3)** | WhatsApp doctor ops group | Admin phone | 2h during pilot hours |
| **Internal (C0)** | Engineering war-room | — | Immediate |

Configure contacts in:

- `mobile.app.config` → `supportPhone`, `supportWhatsapp`
- `launch.closedBeta.config` → `userSupportWhatsapp`, `doctorSupportWhatsapp`

---

## 2. Feedback intake taxonomy

All structured beta feedback from the app uses:

**`POST /api/mobile/feedback/beta`** → creates support ticket with subject prefix **`[Beta Feedback]`**.

### 2.1 Triage tags

| Tag | Examples | Priority | Route to |
|-----|----------|----------|----------|
| `crash` | App closes, white screen | P0 | Mobile on-call |
| `otp` | SMS not received, wrong code | P0 | Backend on-call |
| `booking` | Cannot create SR, assign stuck | P1 | Ops + admin |
| `doctor` | Doctor cannot login/complete | P1 | Web on-call |
| `payment` | Manual payment confusion | P2 | Product |
| `ai-safety` | Harmful AI output, wrong urgency | P0 | AI kill switch owner |
| `copy/legal` | Misleading ETA, disclaimer issue | P0 | Legal + mobile hotfix |
| `livestock` | Feed/inventory/offline sync | P2 | Engineering backlog |
| `other` | General UX | P3 | Product backlog |

**Rule:** Triage every item within **72 hours** (SC-09).

### 2.2 Ticket workflow

1. User submits via app (Support → ticket **or** beta feedback API).
2. Ops labels ticket in admin (manual until support desk UI ships).
3. P0 → GitHub issue + war-room within 24h.
4. Close with resolution note; farmer notified via ticket reply if applicable.

---

## 3. User support flow

### 3.1 Common scenarios

| Issue | First response (EN) | Action |
|-------|---------------------|--------|
| OTP not received | "Please wait 60s and retry. Check signal. If still failing, send your number to support." | Check SMS provider logs |
| Not on invite list | "Closed beta is invite-only. We will add your number if approved." | Add to `invitedPhones` |
| Request pending long | "A team member will assign a doctor soon. For urgent animal emergencies, contact a local vet now." | Admin assign; no ETA promises |
| Payment question | "Payments are manual during beta. Follow instructions from our team after consultation." | Billing SOP |
| AI concern | "AI gives educational guidance only. For serious symptoms, contact a veterinarian immediately." | Review session; escalate if safety |

### 3.2 Bengali macro (OTP)

> OTP পাচ্ছেন না? ১ মিনিট অপেক্ষা করে আবার চেষ্টা করুন। সমস্যা থাকলে সাপোর্টে মেসেজ করুন।

### 3.3 Prohibited support language

Do **not** promise:

- Doctor arrival/response times in minutes  
- Guaranteed outcomes or recovery  
- Emergency dispatch ("team is on the way")

See [legal-safe-messaging-plan.md](./legal-safe-messaging-plan.md).

---

## 4. Doctor support flow

| Issue | Action |
|-------|--------|
| Cannot log in | Reset credentials via admin; verify doctor JWT / URL |
| No requests visible | Confirm assignment; check working areas |
| Complete flow error | Capture request ID; web on-call |
| Emergency flag | Confirm `acceptsEmergency`; explain manual workflow |

**Weekly:** 15-min call with C3 cohort for feedback (doctor satisfaction tracking).

---

## 5. Escalation contacts

Fill before launch (store in team wiki, not git):

| Role | Name | Phone | Hours |
|------|------|-------|-------|
| Launch lead | | | |
| On-call engineer | | | 24/7 launch week |
| Backend on-call | | | |
| Mobile on-call | | | |
| AI safety owner | | | BH |
| Legal/compliance | | | On call for P0 copy |

**Escalation path:** Support → Product lead → On-call → Launch lead → Rollback authority.

---

## 6. Incident response (support-triggered)

When support identifies SEV-1/2:

1. Open war-room thread with symptom + time + user count.
2. On-call runs `/health`, `/ready`, recent deploys.
3. If AI safety: disable LLM at `/admin/ai-ops/governance`.
4. Communicate to affected cohorts if outage > 15 min.
5. Post-mortem within 72h.

See [incident-response-guide.md](../incident-response-guide.md) and [beta-operations-runbook.md](./beta-operations-runbook.md) §6.

---

## 7. Beta satisfaction tracking

| Method | Frequency | Owner |
|--------|-----------|-------|
| Optional 1–5 rating on beta feedback API | Per submission | Product |
| WhatsApp pulse (C1) | Weekly | Product |
| Doctor call (C3) | Weekly | Product |
| NPS micro-survey | Optional post-consultation | Product |

Aggregate ratings from ticket bodies (`Rating: N/5` line) until analytics UI ships.

---

## 8. API reference (support tooling)

| Endpoint | Auth | Purpose |
|----------|------|---------|
| `POST /api/mobile/feedback/beta` | Mobile customer | Structured feedback |
| `POST /api/mobile/support/tickets` | Mobile customer | General tickets |
| `GET /api/mobile/support/help` | Mobile customer | FAQ + contacts |

---

*Align all public-facing copy with [legal-safe-messaging-plan.md](./legal-safe-messaging-plan.md) before C2 ramp.*
