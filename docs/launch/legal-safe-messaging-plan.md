# Legal-Safe Messaging Plan — Prani Doctor

**Document ID:** `LEGAL_SAFE_MESSAGING_PLAN`  
**Version:** 1.0  
**Date:** 2026-05-30  
**Mode:** Plan + implementation (2026-05-30) — see `docs/compliance/` on `pranidoctor-web` and code changes below  
**Scope:** User-facing copy across `pranidoctor_user` (Flutter), `pranidoctor-backend` (API, notifications, SMS, AI prompts, CMS defaults), `pranidoctor-web` (admin, doctor panel, public legal, API docs)  
**Owners:** Product Architecture · Legal/Compliance · UX Governance

**Related documents**

| Area | Document |
|------|----------|
| Emergency limitation (implemented CMS) | [emergency-service-limitation-plan.md](../../pranidoctor-web/docs/compliance/emergency/emergency-service-limitation-plan.md) |
| Emergency verification (ETA conflict cited) | [EMERGENCY_LIMITATION_VERIFICATION_REPORT.md](../../pranidoctor-web/docs/compliance/emergency/EMERGENCY_LIMITATION_VERIFICATION_REPORT.md) |
| Veterinary disclaimer CMS | [veterinary-disclaimer-plan.md](../../pranidoctor-web/docs/compliance/veterinary/veterinary-disclaimer-plan.md) |
| AI disclaimer CMS | [ai-disclaimer-plan.md](../../pranidoctor-web/docs/compliance/ai/ai-disclaimer-plan.md) |
| AI escalation disclosure CMS | [ai-escalation-disclosure-plan.md](../../pranidoctor-web/docs/compliance/ai/ai-escalation-disclosure-plan.md) |
| Terms / over-promise guardrails | [terms-of-service-plan.md](../../pranidoctor-web/docs/compliance/legal/terms-of-service-plan.md) |
| Notification + SMS design | [NOTIFICATION_SMS_PLAN.md](../../pranidoctor-web/docs/NOTIFICATION_SMS_PLAN.md) |
| API contract (aspirational ETA examples) | [API_CONTRACT_V1.md](../../pranidoctor-web/docs/api/API_CONTRACT_V1.md) §12 |
| Launch ops | [GO_LIVE_CHECKLIST.md](./GO_LIVE_CHECKLIST.md) · [LAUNCH_DAY_RUNBOOK.md](./LAUNCH_DAY_RUNBOOK.md) |

---

## Executive summary

Prani Doctor already ships **strong compliance-oriented defaults** for emergency limitation, veterinary disclaimer, AI disclaimer, and AI escalation disclosure (backend `Setting` keys + admin CMS). The **primary legal/expectation risk** today is **contradictory UX copy**: localized “Typical response: X min” strings on the Instant Care sheet sit **above** banners that state wait times are not guaranteed.

| Dimension | Assessment |
|-----------|------------|
| **Current risk** | **Medium–High** for consumer-facing ETA-style strings; **Low–Medium** for backend notifications/SMS (mostly factual status updates) |
| **Legal exposure** | Misleading trade practices, breach of stated limitations in ToS/disclaimers, aggravated liability if user delays in-person care |
| **Fastest win (P0)** | Replace/remove all `homeCare*Eta` keys and “fastest way” framing; align API docs with as-built APIs |
| **Structural win (P1)** | Central copy registry, lint/check for prohibited tokens, admin CMS guardrails |
| **Future (P2)** | Locale review, marketing site, WhatsApp template registry, email queue templates |

**Recommendation:** Treat this plan as a **launch gate** alongside emergency limitation verification. Do not ship broad production marketing that references response-time SLAs until P0 copy is merged and counsel signs off on canonical replacement strings (BN + EN).

---

## 1. Current risk assessment

### 1.1 Risk register (summary)

| ID | Finding | Severity | Likelihood | User harm | Evidence |
|----|---------|----------|------------|-----------|----------|
| R-01 | Numeric “Typical response” ETAs on Instant Care tiles | **High** | Certain (every sheet open) | User expects doctor within stated minutes | `homeCare*Eta` in `app_en.arb`, `assets/i18n/en.json`, `bn.json`; `instant_care_sheet.dart` |
| R-02 | “Instant care” / “fastest way to get help” product framing | **Medium** | Certain | Implies prioritized dispatch | `homeInstantCareTitle`, `homeInstantCareSubtitle` |
| R-03 | “Emergency available” on doctor profile without qualifier | **Medium** | High | Confused with live on-call | `emergencyAvailable`; `doctor_detail_page.dart` chip |
| R-04 | API contract documents ETA fields and “Customer notified with ETA” flow not implemented | **Medium** | Medium (integrators, future mobile) | Third-party apps may promise ETAs | `API_CONTRACT_V1.md` §12 |
| R-05 | Internal ops alerts use minute thresholds (not user-facing) | **Low** | N/A | None if kept internal | `escalation-alerts.ts` |
| R-06 | AI safety user string “Seek immediate veterinary care” | **Low** (appropriate urgency) | Medium | Could be read as “platform will provide” if shown without E2 strip | `ai-safety.service.ts` |
| R-07 | Inventory “~{days} days remaining” | **Low** | Low | Feed stock estimate, not clinical SLA | `inventoryDaysRemaining` |
| R-08 | Admin-editable CMS (emergency/vet/AI) can be overwritten with risky text | **Medium** | Low–Medium | Ops mistake → live bad copy | Admin legal panels in `pranidoctor-web` |
| R-09 | Bengali locale files partially English / mixed ETA strings | **Medium** | High in BN market | Uneven protection | `assets/i18n/bn.json` mirrors EN ETAs |
| R-10 | Symptom checker displays raw `recommendation` from API without secondary qualifier in UI | **Medium** | Medium | Model/rules text could over-promise | `symptom_checker_page.dart` |

### 1.2 What is already compliant (do not regress)

| Layer | Status | Notes |
|-------|--------|-------|
| Emergency limitation defaults | **Strong** | Explicit non-guarantee, non-dispatch language — `emergency-limitation-defaults.ts` |
| Veterinary disclaimer defaults | **Strong** | Arrival/outcome non-guarantee — `vet-disclaimer-defaults.ts` |
| AI disclaimer defaults | **Strong** | Non-diagnostic, non-examination — `ai-disclaimer-defaults.ts` |
| AI escalation disclosure defaults | **Strong** | No auto-booking, no dispatch — `ai-escalation-disclosure-defaults.ts` |
| AI system prompts (seed) | **Adequate** | No prescribe/diagnose; educational framing — `ai-prompt.service.ts` `DEFAULT_PROMPTS` |
| Production notifications (SR lifecycle) | **Adequate** | Factual events only — `notifications/events.ts` |
| SMS (SR lifecycle + OTP) | **Adequate** | No ETA in SMS bodies today |

---

## 2. Legal exposure analysis

### 2.1 Theory of harm

1. **Consumer protection / misleading conduct:** Numeric or “typical” response windows create a **reasonable expectation** of service level similar to on-demand ride/delivery apps. When assignment is manual and availability is profile-flag-based, those expectations are **unlikely to be met consistently**.
2. **Contract inconsistency:** Emergency limitation and vet disclaimer text **deny** guaranteed response/arrival. ETA subtitles on the same screen **affirm** implied SLAs → evidentiary tension in disputes (“app said 15–30 min”).
3. **Clinical delay:** Users may **wait for in-app assignment** instead of contacting a local vet/clinic when copy suggests help is imminent.
4. **AI adjunct liability:** Urgency labels plus time promises compound confusion about whether AI “confirmed” an emergency and whether the platform **activated** a response.

### 2.2 Jurisdiction note (non-legal advice)

Plan assumes Bangladesh market with BN/EN copy. Counsel should review:

- Consumer Rights Protection Act / digital service marketing norms (as applicable).
- Veterinary practice advertising restrictions.
- Telemedicine / remote advice boundaries (platform positions as **connection + education**, not clinic).

### 2.3 Evidence preservation

For incidents, preserve:

- `LegalConsentEvent` rows (emergency/vet/AI acceptance versions).
- `Setting` snapshots for `mobile.emergency.limitation.config`, `mobile.vet.disclaimer.config`, `mobile.ai.*`.
- Notification/SMS body at time of send (DB `Notification.title/body`).
- App build number + locale at time of user action.

---

## 3. Risky wording inventory (Section A)

### 3.1 P0 — Prohibited or must remove before broad launch

| Location | Key / string | Risk class | Current text (EN) |
|----------|--------------|------------|-------------------|
| Flutter l10n | `homeCareAiDoctorEta` | Exact ETA band | `Typical response: under 1 min` |
| Flutter l10n | `homeCareCallDoctorEta` | Exact ETA band | `Typical response: 5–15 min` |
| Flutter l10n | `homeCareEmergencyVisitEta` | Exact ETA band | `Typical response: 15–30 min` |
| Flutter l10n | `homeCareVideoConsultationEta` | Exact ETA band | `Typical response: 10–20 min` |
| Flutter l10n | `homeCareChatEta` | Exact ETA band | `Typical response: under 5 min` |
| Flutter l10n | `homeInstantCareSubtitle` | Speed guarantee implication | `Choose the fastest way to get help.` |
| Flutter l10n | `homeInstantCareTitle` | “Instant” service claim | `Instant care` |
| API documentation | `estimatedResponseTime`, `eta` in examples | Speculative SLA | e.g. `"30 মিনিট"`, flow “Customer notified with ETA” |
| API documentation | Emergency flow step 2 | Dispatch implication | “System broadcasts to all available providers” (not as-built) |

**Files (canonical sources):**

- `pranidoctor_user/lib/l10n/app_en.arb`
- `pranidoctor_user/assets/i18n/en.json`
- `pranidoctor_user/assets/i18n/bn.json`
- `pranidoctor_user/lib/features/home/presentation/widgets/instant_care_sheet.dart` (consumer)
- `pranidoctor-web/docs/api/API_CONTRACT_V1.md` (integrator/marketing risk)

### 3.2 P1 — Restricted (rewrite or qualify)

| Location | Key / string | Risk class | Issue |
|----------|--------------|------------|-------|
| Flutter l10n | `emergencyAvailable` | Availability guarantee | Reads as “available now” |
| Flutter l10n | `searchEmergencySubtitle` | Discovery promise | “Emergency doctors and services” without limitation |
| Flutter l10n | `homeCareNearestServiceEta` | Location ≠ ETA | Acceptable if reframed; avoid implying arrival time |
| Backend AI safety | `recommendation` emergency path | Urgency without platform scope | `Seek immediate veterinary care — possible emergency.` — OK if paired with E2/E1 banners |
| Symptom checker UI | `result.recommendation` display | Unvetted backend string | Must not introduce times/guarantees |
| AI escalation `high` contextual | “as soon as possible” | Soft timeline | Acceptable with “booking may take time” (already in BN/EN default) |
| Admin analytics | `avgResponseMinutes` column label | Internal only | Ensure not exported to farmers |

### 3.3 P2 — Monitor / clarify

| Location | Key / string | Notes |
|----------|--------------|-------|
| `inventoryDaysRemaining` | Feed estimate | Not veterinary SLA; keep “~” and “estimate” in BN |
| `dashboardHealthUpcoming` / `vaccineStatusDue` | “Due soon” | Calendar reminder, not doctor ETA |
| `bookingSubmitted` | `Consultation request submitted` | Factual — keep |
| `awaitingAssignment` | `Waiting for doctor assignment` | Factual — keep; pair with `requestPending` contextual banner |
| Notification seed/demo | Bengali demo titles | Non-prod; ensure prod templates governed |
| Marketing / blueprint docs | `MOBILE_UI_BLUEPRINT.md` | May contain aspirational UX copy — audit separately |

### 3.4 Backend-generated & channel inventory

| Channel | Implementation | ETA / guarantee in prod today? | Files |
|---------|----------------|--------------------------------|-------|
| In-app notification | `createNotificationForUser` | **No** numeric ETA | `src/legacy/web/lib/notifications/events.ts` |
| SMS | `getSmsService().sendSms` | **No** ETA (SR submit/accept/complete) | Same + `src/legacy/web/lib/sms/service.ts` |
| Email | Queue mentioned in backend docs | **Not implemented** for SR | `docs/backend/07-queue-strategy.md` |
| WhatsApp | Support link only (user-initiated) | **No** platform templates | `mobile-support/support-service.ts`, Flutter support pages |
| FCM push | Title/body from server payload | **Depends on** notification row content | `lib/features/notifications/` |
| AI chat/triage output | LLM + rules fallback | **Must not** emit times in prompts; validate output | `ai-prompt.service.ts`, orchestrator |
| Admin CMS | Emergency/vet/AI/legal settings | **Risk if edited** | `admin-emergency-limitation-service.ts`, vet/AI admin panels |

### 3.5 AI & chatbot messaging

| Asset | Purpose | Risk controls present |
|-------|---------|----------------------|
| `farmer_chat` system prompt | Farmer AI chat | No diagnose/prescribe |
| `symptom_checker` system prompt | Triage list | Educational only |
| `farm_assistant` system prompt | Farm Q&A | Management focus |
| `ai-safety.service.ts` | Post-processing urgency | Emergency recommendation string |
| `ai-escalation-disclosure` CMS | UI strips E1/E2/E3 | Strong defaults |
| Rules-based fallback provider | Offline/kill-switch | Generic care text, no ETA |

**Gap:** Prompts do not explicitly forbid “you will receive a response in X minutes” — add to P1 prompt standards and output lint.

### 3.6 Admin-configurable content

| Setting key | Admin UI | Locales |
|-------------|----------|---------|
| `mobile.emergency.limitation.config` | Emergency limitation panel | en, bn per context |
| `mobile.vet.disclaimer.config` | Vet disclaimer panel | en, bn |
| `mobile.ai.disclaimer.config` | AI disclaimer panel | en, bn |
| `mobile.ai.escalation.disclosure.config` | AI escalation panel | en, bn |
| `mobile.app.config` | App config (phones, flags) | JSON — no ETA fields today |
| Legal document seed | Terms/privacy versions | `legal-document-seed.ts` |

**Governance gap:** No server-side validator rejecting prohibited substrings in CMS saves (P1).

---

## 4. Legal-safe replacement strategy (Section B)

### 4.1 Principles

1. **Describe process, not outcome:** “Request submitted”, “Waiting for assignment”, “Doctor accepted”.
2. **Use variability language:** “may”, “can vary”, “when available”, “attempting to connect”.
3. **Separate AI from human service:** AI = educational; human = separate booking with manual steps.
4. **Never pair time ranges with emergency paths** unless counsel approves statistical disclosure with methodology footnote (not recommended for v1).
5. **One screen = one truth:** If limitation banner says no guarantee, subtitles must not imply SLA.

### 4.2 Replacement matrix (EN — draft for counsel review)

| Risky (current) | Approved replacement (EN) | Rationale |
|-----------------|---------------------------|-----------|
| `Typical response: under 1 min` | `Automated guidance — not a live veterinarian` | AI path |
| `Typical response: 5–15 min` | `We are attempting to connect you with an available veterinarian. Response times vary.` | Call/book path |
| `Typical response: 15–30 min` | `Emergency visit requests are reviewed when possible. Not an on-demand dispatch service.` | Emergency visit |
| `Typical response: 10–20 min` | `Online consultation depends on doctor availability. Not for life-threatening emergencies.` | Video/online |
| `Typical response: under 5 min` | `Support response times vary. Not emergency veterinary care.` | Chat/support |
| `Instant care` | `Urgent care options` | Removes “instant” |
| `Choose the fastest way to get help.` | `Choose how you want to seek help. Availability is not guaranteed.` | Sets expectation |
| `Emergency available` | `Accepts emergency requests (when available)` | Profile flag ≠ live status |
| `Emergency doctors and services` | `Doctors who may accept emergency requests` | Discovery |
| API example `estimatedResponseTime` | **Remove field** or rename to `internalSlaTargetMinutes` **admin-only** | Not for mobile DTO |
| API flow “Customer notified with ETA” | `Customer notified of assignment status (no guaranteed arrival time)` | Doc-only fix |

### 4.3 Replacement matrix (BN — draft for counsel review)

| EN approved concept | BN draft |
|---------------------|----------|
| Attempting to connect… times vary | `আমরা উপলব্ধ প্রাণী চিকিৎসকের সাথে যোগাযোগের চেষ্টা করছি। সাড়ার সময় পরিবর্তনশীল হতে পারে।` |
| Emergency visit reviewed | `জরুরি পরিদর্শনের অনুরোধ সম্ভব হলে পর্যালোচনা হয় — তাত্ক্ষণিক পাঠানোর সেবা নয়।` |
| Urgent care options | `জরুরি সহায়তার বিকল্প` |
| Accepts emergency requests (when available) | `জরুরি অনুরোধ গ্রহণ করতে পারেন (খালি থাকলে নয়)` |

**Note:** Replace mixed BN/EN pollution in `bn.json` during same pass (several keys still English per localization audit).

### 4.4 Patterns to avoid globally

| Prohibited pattern | Examples |
|--------------------|----------|
| Numeric response/arrival window | “within 5 minutes”, “10–15 min”, “under 1 min” |
| Certainty modals | “will arrive”, “will respond”, “guaranteed”, “assured”, “promise” |
| Outcome guarantees | “guaranteed recovery”, “cure”, “will heal” |
| Dispatch language | “we are sending”, “team dispatched”, “ambulance” |
| 24/7 clinic implication | “always available”, “instant vet”, “on-demand emergency clinic” |
| Comparative speed superlatives | “fastest”, “instant”, “immediate response” (except directing user to **external** immediate care: “contact a vet **now**” — allowed for safety) |

---

## 5. Messaging categories (Section C)

Standards apply to **all channels** (UI, push, SMS, email, WhatsApp business, AI output, admin CMS).

### 5.1 Appointment & consultation flows

| State | Allowed | Restricted | Prohibited |
|-------|---------|------------|------------|
| Booking start | “Book consultation”, disclaimers | “Schedule guaranteed” | “Doctor will see you at {time}” unless real scheduling exists |
| Submitted | “Request submitted”, reference id | “Confirmed appointment” if status is PENDING | “Doctor assigned” before assignment |
| Pending assignment | “Waiting for assignment”, contextual limitation | “Short wait” | Any minute ETA |
| Assigned / accepted | “Dr. {name} accepted your request” | “On the way” unless doctor app sends location feature | “Arriving in X min” |
| Completed | “Marked completed” | “Successfully treated” | “Your animal will recover” |

**Flutter keys:** `bookingSubmitted`, `awaitingAssignment`, `status*`, `event*`.  
**Backend:** `notifyServiceRequestSubmitted`, `notifyDoctorAcceptedRequest`, `notifyServiceRequestCompleted`.

### 5.2 Doctor assignment & discovery

| Context | Standard |
|---------|----------|
| List/filter | “May accept emergency requests” not “Available now” |
| Profile chips | Replace `emergencyAvailable` with qualified label |
| Admin assign | Internal ops language OK (“pending >15 min”) — never push ETA to customer |

### 5.3 Emergency requests (`EMERGENCY_DOCTOR`)

| Touchpoint | Required copy tier |
|------------|-------------------|
| Instant care sheet | U1 urgent + contextual `instantCare` + vet banner |
| Book emergency | Urgent + `bookingEmergency` + acceptance sheet |
| Pending SR detail | `requestPending` contextual |
| Phone dial | `phoneDial` dialog |

**Never** show numeric ETA on these paths (EL-02).

### 5.4 Livestock & AI technician service flows

| Context | Standard |
|---------|----------|
| AI technician booking | Field service request — **not** LLM emergency; use service-provider terms |
| Status `ON_THE_WAY` / `ARRIVED` | Describe **status label** only (“Provider marked: on the way”) — no predicted arrival unless doctor/tech app publishes user-generated estimate with disclaimer |

### 5.5 AI workflows (chat, triage, symptom checker, voice)

| Output type | Standard |
|-------------|----------|
| Education | “Consider…”, “Discuss with a veterinarian…” |
| Urgency | “Possible emergency based on your description” + E2 `emergency` |
| Escalation | “Does not book a veterinarian” (E2 `escalationRecorded`) |
| Refusal | No diagnosis/prescription — route to vet |

**Prompt rule (P1):** Add explicit instruction: *Never state response times, arrival times, or guarantee availability.*

### 5.6 Notifications & escalations

| Type | Standard |
|------|----------|
| REQUEST_UPDATE | Factual status only |
| SYSTEM | No marketing SLAs |
| Escalation ops webhook | Internal — no customer ETA |

### 5.7 Queue & service availability

| UI | Standard |
|----|----------|
| Queue position | If shown: “Your request is in queue” — **no** “#1 — 3 min” unless measured and disclaimed |
| Service area | “Service may not be available in all areas” (ToS alignment) |
| Offline | “Showing saved data” — no impact on vet SLA messaging |

---

## 6. Compliance rules (Section D)

### 6.1 Allowed wording (taxonomy)

| Category | Examples |
|----------|----------|
| **Process facts** | submitted, pending, assigned, accepted, completed, cancelled |
| **Variability** | may, might, when available, if possible, times vary |
| **Attempt** | attempting to connect, trying to reach, searching for available |
| **User duty (safety)** | contact a veterinarian now, seek in-person care, do not delay |
| **Platform role** | technology platform, not a clinic, not dispatch |
| **AI limits** | educational, not a diagnosis, not a prescription |
| **Estimates (non-SLA)** | feed inventory “~N days” with inventory context only |

### 6.2 Restricted wording (requires legal + UX review)

| Term | Condition |
|------|-----------|
| “Urgent” / “Emergency” | Must pair with limitation/disclaimer on same flow |
| “Immediate” | Only for **user action** (seek care now), not platform performance |
| “Available” | Qualify: “may be available”, profile flag |
| “Typical” / “Average” | **Ban** for doctor response unless backed by published statistics + methodology |
| “Soon” | OK for vaccine due dates; **not** for vet arrival |

### 6.3 Prohibited wording (zero tolerance in user-facing prod)

- Guaranteed / guarantee / assured / promise / definitely will  
- Numeric ETA bands for human veterinary response (minutes, hours)  
- “Doctor will arrive in…”, “Vet will respond within…”  
- “Instant care”, “fastest”, “on-demand emergency clinic” (marketing)  
- Recovery/outcome promises (“will recover”, “guaranteed treatment”)  
- Dispatch / ambulance / “we are sending a team” unless literally true and licensed  

### 6.4 CMS & admin guardrails (P1)

- Validate on save: reject regex `\b(\d+\s*[-–]?\s*\d*\s*(min|minute|hour)|within\s+\d+|guarantee)\b` in emergency/vet/AI CMS fields (configurable allowlist for non-SLA contexts).
- Version bump `contentVersion` on any default change; require re-acceptance only when legally mandated.
- Audit trail: existing `LegalConsentEvent` + admin publish logs.

---

## 7. Emergency communication rules (Section E)

### 7.1 Approved themes

1. **Encourage immediate local veterinary care** when life-threatening signs are described.
2. **Clarify platform limits:** not dispatch, not ambulance, not 24/7 clinic.
3. **Direct to configurable phone** with `phoneDial` contextual copy (user verifies appropriateness).
4. **Reinforce manual workflow:** request → review → assign → doctor accept.

### 7.2 Required elements by surface

| Surface | Minimum elements |
|---------|------------------|
| Instant care | U1 urgent banner + vet disclaimer + **no ETA subtitles** |
| Emergency book | Full/urgent acceptance + `bookingEmergency` + server guard |
| AI emergency triage | E2 `emergency` + optional U1 urgent (P0 gap: add to triage/chat) |
| Pending emergency SR | `requestPending` contextual |

### 7.3 Forbidden in emergency contexts

- Any numeric time-to-response or time-to-arrival.
- “Help is on the way” before provider explicitly sets in-transit status.
- AI urgency presented as confirmation of emergency or automatic vet deployment.

### 7.4 Canonical safety sentences (already in defaults — reuse, do not contradict)

From `DEFAULT_EMERGENCY_LIMITATION_URGENT` (en):

> This app does not send emergency veterinary teams. If life is at risk, contact a veterinarian or clinic immediately.

From `DEFAULT_VET_DISCLAIMER_EMERGENCY` (en):

> If your animal may die without immediate care, go to the nearest veterinary facility or call a vet now. Booking through the app does not guarantee emergency response time.

---

## 8. Rollout strategy (Section F)

### 8.1 P0 — Mandatory (launch gate)

| # | Task | Repo | Owner |
|---|------|------|-------|
| P0-1 | Replace all `homeCare*Eta` + instant care title/subtitle per §4.2 matrix | `pranidoctor_user` | Mobile + UX |
| P0-2 | Update `emergencyAvailable` + search emergency subtitle | `pranidoctor_user` | Mobile |
| P0-3 | Regenerate l10n (`app_localizations_*`) after arb/json sync | `pranidoctor_user` | Mobile |
| P0-4 | QA: Instant care sheet shows **no** minute strings; banners visible | QA | |
| P0-5 | Amend `API_CONTRACT_V1.md` §12 — remove fictional ETA fields/flows or mark **aspirational / not implemented** | `pranidoctor-web` | API owner |
| P0-6 | Legal sign-off on BN+EN replacement table §4.2–4.3 | Compliance | |
| P0-7 | Verify prod CMS emergency/vet/AI settings have not reintroduced ETAs | Ops | |

**Exit criteria:** EMERGENCY_LIMITATION verification report R-01 closed; counsel written approval filed.

### 8.2 P1 — Recommended (within 14 days of P0)

| # | Task | Repo |
|---|------|------|
| P1-1 | Add AI prompt clause forbidding time/guarantee language | `pranidoctor-backend` |
| P1-2 | Post-LLM output filter for minute/ETA patterns (log + replace with safe fallback) | `pranidoctor-backend` |
| P1-3 | CMS save validator for prohibited patterns | `pranidoctor-web` + backend |
| P1-4 | Wire U1 urgent on AI triage/chat result pages (per emergency verification EU-03) | `pranidoctor_user` |
| P1-5 | Copy registry doc or spreadsheet keyed by `translation_keys.dart` | `pranidoctor_user/docs` |
| P1-6 | CI grep/lint: fail on prohibited tokens in `assets/i18n` and `app_en.arb` | CI |
| P1-7 | Review `symptom_checker_page` — wrap `recommendation` with standard qualifier | `pranidoctor_user` |
| P1-8 | Admin notification template guidelines in NOTIFICATION_SMS_PLAN appendix | `pranidoctor-web` |

### 8.3 P2 — Future improvements

| # | Task |
|---|------|
| P2-1 | Public web `/legal` emergency limitation section (U3) |
| P2-2 | Email template library with same compliance taxonomy |
| P2-3 | WhatsApp Business template approval workflow |
| P2-4 | Marketing site / store listing audit |
| P2-5 | Statistical “typical response” only if ops data + counsel approve footnoted disclosure |
| P2-6 | Doctor panel in-app status messages audit (BN strings) |
| P2-7 | Remove or gate `EMERGENCY_ENGINE.md` aspirational designs from integrator docs |

---

## 9. Required file locations (implementation reference)

### 9.1 Flutter user app (`pranidoctor_user`)

| Purpose | Path |
|---------|------|
| Source of truth EN arb | `lib/l10n/app_en.arb` |
| Runtime JSON locales | `assets/i18n/en.json`, `assets/i18n/bn.json` |
| Key registry | `lib/core/localization/translation_keys.dart` |
| Generated l10n | `lib/core/localization/generated/app_localizations_impl.dart` |
| Instant care UI | `lib/features/home/presentation/widgets/instant_care_sheet.dart` |
| Doctor emergency chip | `lib/features/doctors/presentation/doctor_detail_page.dart` |
| SR detail / pending | `lib/features/service_requests/presentation/service_request_detail_page.dart` |
| Emergency limitation widgets | `lib/features/emergency_limitation/presentation/widgets/emergency_limitation_banner.dart` |
| Vet disclaimer widgets | `lib/features/vet_disclaimer/presentation/widgets/vet_disclaimer_banner.dart` |
| AI disclaimer / escalation | `lib/features/ai/presentation/widgets/` (banners) |
| Symptom checker | `lib/features/ai/presentation/phase8/symptom_checker_page.dart` |

### 9.2 Backend (`pranidoctor-backend`)

| Purpose | Path |
|---------|------|
| Emergency limitation defaults | `src/legacy/web/lib/emergency-limitation/emergency-limitation-defaults.ts` |
| Vet disclaimer defaults | `src/legacy/web/lib/vet-disclaimer/vet-disclaimer-defaults.ts` |
| AI disclaimer defaults | `src/legacy/web/lib/ai-disclaimer/ai-disclaimer-defaults.ts` |
| AI escalation defaults | `src/legacy/web/lib/ai-escalation-disclosure/ai-escalation-disclosure-defaults.ts` |
| Notification + SMS copy | `src/legacy/web/lib/notifications/events.ts` |
| SMS service | `src/legacy/web/lib/sms/service.ts` |
| AI prompts seed | `src/modules/ai/prompts/ai-prompt.service.ts` |
| AI safety user strings | `src/modules/ai-veterinary-core/safety/ai-safety.service.ts` |
| Ops escalation (internal) | `src/shared/monitoring/escalation/escalation-alerts.ts` |
| Admin legal APIs | `src/legacy/web/lib/admin-legal/admin-emergency-limitation-service.ts`, `admin-vet-disclaimer-service.ts` |

### 9.3 Web admin & docs (`pranidoctor-web`)

| Purpose | Path |
|---------|------|
| API contract (ETA examples) | `docs/api/API_CONTRACT_V1.md` |
| Compliance plans | `docs/compliance/emergency/`, `docs/compliance/veterinary/`, `docs/compliance/ai/` |
| Admin emergency CMS UI | `src/components/admin/settings/` (Emergency limitation panel) |
| Notification design | `docs/NOTIFICATION_SMS_PLAN.md` |

---

## 10. Implementation checklist (plan execution — not code)

Use this as the **program tracker** when implementation is authorized.

### Phase 0 — Inventory freeze

- [ ] Export full string list from `app_en.arb` + `bn.json` (script or `flutter gen-l10n` pipeline).
- [ ] Mark each key: Allowed / Restricted / Prohibited per §6.
- [ ] Counsel review §4.2–4.3 replacement table.
- [ ] Sign-off recorded in `LegalDocument.metadataJson` or compliance ticket.

### Phase 1 — Copy change (mobile)

- [ ] Apply P0 string replacements in `app_en.arb` and both JSON locales.
- [ ] Run localization generation; fix BN mixed-language regressions on touched keys.
- [ ] Visual QA on Instant Care, doctor detail, emergency book, SR pending.
- [ ] Screenshot evidence attached to launch checklist.

### Phase 2 — Docs & API

- [ ] Revise API contract §12 to match as-built (no `estimatedResponseTime` in mobile DTO until implemented).
- [ ] Add cross-link from `GO_LIVE_CHECKLIST.md` to this plan (P0 item).

### Phase 3 — Backend & AI

- [ ] Extend AI prompts with anti-ETA instruction.
- [ ] Optional output sanitizer for time patterns.
- [ ] Confirm notification/SMS templates for any new events include taxonomy §5.6.

### Phase 4 — CMS governance

- [ ] Admin validator (P1) deployed.
- [ ] Runbook: ops must not paste ETA language into CMS (training).

### Phase 5 — Verification

- [ ] Re-run emergency limitation verification (ETA conflict closed).
- [ ] Manual test matrix: EN + BN, online/offline cache of limitation snapshots.
- [ ] Store listing / marketing copy audit (if applicable).

---

## 11. Text inventory summary (counts)

| Source | Approx. user-facing keys reviewed | High-risk items |
|--------|-----------------------------------|-----------------|
| `app_en.arb` / `en.json` | ~1,400+ keys in catalog | **7** ETA + **3** framing |
| `bn.json` | Parallel | Same keys (mixed EN) |
| Backend notifications | 4 production templates | **0** ETA |
| Backend SMS | 4 production bodies | **0** ETA |
| CMS defaults (4 configs) | ~30 strings × 2 locales | **0** ETA (compliant) |
| AI prompts | 3 keys × 2 locales | **0** ETA (add explicit ban P1) |
| API contract examples | §12 emergency | **2+** ETA examples (doc only) |

---

## 12. Decision log

| Date | Decision |
|------|----------|
| 2026-05-30 | Adopt process/variability language platform-wide; remove numeric vet ETAs from Instant Care (P0). |
| 2026-05-30 | Keep internal ops minute thresholds; never surface to customers. |
| 2026-05-30 | Defer statistical “typical response” marketing until data + legal framework (P2). |

---

## 13. Open questions for legal / product

1. Is “**Accepts emergency requests**” sufficient for doctor profiles, or require icon + tooltip linking to limitation modal?
2. May AI say “**contact a veterinarian immediately**” without “possible” qualifier in highest risk band?
3. Should `ON_THE_WAY` status text be hidden from customers until in-app tracking ships?
4. Are WhatsApp support messages considered “templates” requiring pre-registration under local telecom rules?

---

*This document is the authoritative launch plan for legal-safe messaging. Implementation PRs should reference `LEGAL_SAFE_MESSAGING_PLAN` and ticket IDs from §8 checklists.*
