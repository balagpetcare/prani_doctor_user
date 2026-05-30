# P0 Compliance Verification Report

**Date:** 2026-05-30  
**Engineer:** Product Compliance (automated + manual audit)  
**Repos:** `pranidoctor_user`, `pranidoctor-backend`, `pranidoctor-web` (reference)  
**Plan:** [p0-compliance-fix-plan.md](./p0-compliance-fix-plan.md)

---

## Executive summary

| P0 item | Result |
|---------|--------|
| 1. Remove guaranteed ETA wording | **PASS** |
| 2. Emergency limitation banners | **PASS** |
| 3. AI limitation banners | **PASS** |
| 4. Emergency flow audit | **PASS** |
| 5. AI flow audit | **PASS** |
| 6. Verification report | **PASS** (this document) |

**Overall P0 status: PASS** — no remaining P0 compliance blockers for closed-beta / GA messaging.

---

## 1. ETA wording verification

### Static scan (mobile production strings)

Patterns checked: `Typical response`, `within N min`, `under N min`, minute ranges, `will arrive`, positive `guarantee`.

| Location | Result |
|----------|--------|
| `assets/i18n/en.json` | **Pass** — no prohibited patterns |
| `assets/i18n/bn.json` | **Pass** — no prohibited patterns |
| `lib/l10n/app_en.arb` | **Pass** — legal-safe copy; `searchEmergencySubtitle` synced |
| `lib/**/*.dart` (user UI) | **Pass** — only negated “not guaranteed” in `homeInstantCareSubtitle` |

### Approved replacements (sample)

| Key | Approved EN copy |
|-----|------------------|
| `homeCareCallDoctorEta` | Response times may vary |
| `homeCareEmergencyVisitEta` | Not an on-demand dispatch service |
| `homeInstantCareTitle` | Urgent care options |
| `emergencyAvailable` | Accepts emergency requests (when available) |
| `searchEmergencySubtitle` | Doctors who may accept emergency requests |
| `aiSymptomGuidanceNote` | Guidance only — not a diagnosis. Response and booking times may vary. |

BN overrides: `tool/i18n/build_localization.dart` (`_keyOverrides`).

### Backend CMS guard

| Check | Command | Result |
|-------|---------|--------|
| Messaging validator | `pnpm exec vitest run src/shared/compliance/messaging-compliance.test.ts` | **12/12 pass** |
| AI safety strip | `pnpm exec vitest run src/modules/ai-veterinary-core/safety` | **Pass** |

---

## 2. Emergency limitation banner matrix

| User journey | File | Context | Status |
|--------------|------|---------|--------|
| Home → Urgent care sheet | `instant_care_sheet.dart` | `instantCare` + urgent | **Pass** |
| Drawer → Emergency doctors | `services_page.dart` (filter) | `discoveryEmergency` | **Pass** |
| Universal search emergency tile | `universal_search_provider.dart` | Subtitle key legal-safe | **Pass** |
| Doctor profile (emergency-capable) | `doctor_detail_page.dart` | `discoveryEmergency` + vet disclaimer | **Pass** *(2026-05-30)* |
| Book consultation → Emergency | `book_consultation_page.dart` | `bookingEmergency` | **Pass** |
| Service request detail (pending emergency) | `service_request_detail_page.dart` | `requestPending` | **Pass** |
| AI triage / symptom emergency output | `ai_output_compliance_wrapper.dart` | `aiEmergency` | **Pass** |

**Booking logic:** unchanged — banners are display-only; acceptance flows preserved.

---

## 3. AI limitation banner matrix

| Route / screen | T1/T2 (`AiCompliancePageBody` / `AiDisclaimerBanner`) | T3 output (`AiOutputComplianceWrapper`) | Status |
|----------------|------------------------------------------------------|----------------------------------------|--------|
| `/ai` home | `AiCompliancePageBody` (chat) | N/A | **Pass** |
| `/ai/chat` | `AiCompliancePageBody` (chat) | `AiMessageBubble` | **Pass** |
| `/ai/voice` | `AiCompliancePageBody` (voice) | N/A | **Pass** |
| `/ai/result` | `AiCompliancePageBody` (triage) | `TriageCard` | **Pass** *(2026-05-30)* |
| `/ai/history` | `AiCompliancePageBody` (chat) | `AiMessageBubble` | **Pass** *(2026-05-30)* |
| `/ai/settings` | `AiCompliancePageBody` (chat) | N/A | **Pass** *(2026-05-30)* |
| Phase 8 symptom checker | `AiCompliancePageBody` (symptomCheck) | `_ResultView` wrapper | **Pass** *(2026-05-30)* |
| Smart alerts | `AiCompliancePageBody` (alerts) | Per-item | **Pass** |
| Farm health dashboard | `AiDisclaimerBanner` (advisory) | N/A | **Pass** |
| Smart recommendations | `AiDisclaimerBanner` (recommendations) | N/A | **Pass** |

Home dashboard AI card (`ai_section.dart`): entry point only — full compliance on AI routes. **Accepted (P1 note).**

---

## 4. Implementation delta (this session)

| File | Change |
|------|--------|
| `lib/features/ai/presentation/ai_result_page.dart` | Wrapped body in `AiCompliancePageBody` (triage) |
| `lib/features/ai/presentation/ai_history_page.dart` | Wrapped body in `AiCompliancePageBody` (chat) |
| `lib/features/ai/presentation/ai_settings_page.dart` | Wrapped body in `AiCompliancePageBody` (chat) |
| `lib/features/ai/presentation/phase8/symptom_checker_page.dart` | `AiCompliancePageBody` + l10n guidance note |
| `lib/features/doctors/presentation/doctor_detail_page.dart` | Emergency + vet limitation banners when `doctor.emergency` |
| `lib/l10n/app_en.arb` | Added `searchEmergencySubtitle` |

---

## 5. Automated verification

| Test | Result |
|------|--------|
| `flutter test test/ai/ai_compliance_test.dart` | **3/3 pass** |
| `flutter analyze` (changed files) | **0 errors** (pre-existing RadioListTile deprecation info only) |
| Backend `messaging-compliance.test.ts` | **Pass** |

### Recommended CI commands

```bash
# Mobile
cd pranidoctor_user
flutter analyze
flutter test test/ai/ai_compliance_test.dart

# Backend
cd pranidoctor-backend
pnpm exec vitest run src/shared/compliance/messaging-compliance.test.ts
```

---

## 6. Residual items (non-P0)

| Item | Priority | Notes |
|------|----------|-------|
| Home AI section inline disclaimer | P1 | Entry card; banners on destination routes |
| Symptom checker BN UI strings | P1 | Form labels still BN-hardcoded; guidance uses l10n |
| Kill-switch user-facing notice | P1 | Governance exists; copy surfacing TBD |
| Cookie policy standalone page | P1 | Linked from privacy |

---

## Sign-off

P0 compliance blockers for **legal-safe messaging** (ETA, emergency limitations, AI limitations) are **resolved**. Workflows and booking logic were not modified.

**Verified by:** compliance audit pipeline + code review  
**Next review:** On CMS copy change or new emergency/AI surface addition
