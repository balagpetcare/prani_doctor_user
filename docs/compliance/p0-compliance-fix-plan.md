# P0 Compliance Fix Plan

**Role:** Product Compliance Engineer  
**Date:** 2026-05-30  
**Scope:** Mobile (`pranidoctor_user`), backend CMS validator, cross-repo wording audit  
**Constraints:** Preserve workflows · No booking logic changes · Legal-safe wording only

---

## P0 blockers (definition)

| ID | Blocker | Risk |
|----|---------|------|
| P0-ETA | Guaranteed or typical response-time copy in user-facing surfaces | Implied SLA / false promise |
| P0-EMG | Emergency flows without limitation banners | Users may treat app as dispatch |
| P0-AI | AI flows without persistent limitation banners | Users may treat output as diagnosis |
| P0-AUD | Unverified emergency + AI surface coverage | Release without evidence |

---

## Plan

### 1. Remove guaranteed ETA wording

**Source of truth:** `pranidoctor-web/docs/compliance/eta-wording-matrix.md`

| Action | Owner surface |
|--------|---------------|
| Verify EN/BN i18n keys (`homeCare*Eta`, `homeInstantCare*`, `emergencyAvailable`, `searchEmergencySubtitle`, `aiSymptomGuidanceNote`) | Mobile l10n |
| Confirm BN overrides in `tool/i18n/build_localization.dart` | Mobile i18n pipeline |
| Grep prohibited patterns across `assets/i18n`, `lib/l10n`, Dart UI strings | Mobile |
| Rely on backend `messaging-compliance.ts` for admin CMS saves | Backend |

**No API or booking logic changes.**

### 2. Emergency limitation banners

**Widget:** `EmergencyLimitationBanner` + CMS-backed copy via `emergencyLimitationProvider`

| Flow | Context | Surface |
|------|---------|---------|
| Home → Instant care sheet | `instantCare` + urgent | `instant_care_sheet.dart` |
| Services → Emergency filter | `discoveryEmergency` | `services_page.dart` |
| Doctor detail (emergency doctor) | `discoveryEmergency` | `doctor_detail_page.dart` *(added)* |
| Book consultation → Emergency type | `bookingEmergency` | `book_consultation_page.dart` |
| Service request pending (emergency) | `requestPending` | `service_request_detail_page.dart` |
| AI output → emergency triage | `aiEmergency` | `ai_output_compliance_wrapper.dart` |

### 3. AI limitation banners

**Widgets:** `AiCompliancePageBody` (T1/T2 persistent) + `AiOutputComplianceWrapper` (per-output)

| Screen | Surface | Status |
|--------|---------|--------|
| AI home | `chat` | Existing |
| AI chat | `chat` | Existing |
| AI voice | `voice` | Existing |
| AI result / triage | `triage` | **Added** |
| AI history | `chat` | **Added** |
| AI settings | `chat` | **Added** |
| Symptom checker (form + result) | `symptomCheck` | **Added** |
| Smart alerts | `alerts` | Existing |
| Farm health / recommendations | `advisory` / `recommendations` | Existing (`AiDisclaimerBanner`) |

### 4–5. Audits

- Static grep for prohibited ETA/guarantee patterns (mobile + backend user strings)
- Map every emergency entry point to banner presence
- Map every AI route to T1/T2 + output wrapper where applicable
- Run `messaging-compliance.test.ts` (backend) and `test/ai/ai_compliance_test.dart` (mobile)

### 6. Verification report

Deliver `docs/compliance/p0-compliance-verification-report.md` with pass/fail matrix and evidence commands.

---

## Out of scope (P1+)

- Kill-switch user notice copy
- Voice API consent parity
- Registration consent audit checkbox
- Home AI section inline disclaimer (entry card only; full banners on AI routes)

---

## Success criteria

- Zero prohibited ETA strings in production mobile i18n
- All emergency user journeys show contextual limitation copy before commitment
- All AI routes show persistent AI limitation banner
- Backend CMS validator tests green
- Verification report signed **PASS** for P0 items
