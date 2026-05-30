# Legal-Safe Messaging & ETA Wording Removal — Verification Report

**Document ID:** `LEGAL_SAFE_MESSAGING_VERIFICATION`  
**Version:** 1.0  
**Date:** 2026-05-30  
**Mode:** Verification only (static audit + targeted tests; no new product features)  
**Scope:** `pranidoctor_user` · `pranidoctor-backend` · `pranidoctor-web` (docs)  
**Reference implementation plan:** [legal-safe-messaging-plan.md](./legal-safe-messaging-plan.md)  
**Governance docs:** [legal-safe-messaging-policy.md](../../pranidoctor-web/docs/compliance/legal-safe-messaging-policy.md) · [eta-wording-matrix.md](../../pranidoctor-web/docs/compliance/eta-wording-matrix.md) · [messaging-governance.md](../../pranidoctor-web/docs/compliance/messaging-governance.md)

---

## Executive Summary

Static verification confirms **P0 ETA removal is implemented** in Flutter production l10n (`app_en.arb`, `assets/i18n/en.json`, `assets/i18n/bn.json`) and wired on the Instant Care sheet. Backend **admin CMS validation**, **AI prompt guardrails**, and **output ETA stripping** are present and unit-tested. Production notification and SMS templates remain **factual and ETA-free**.

**Verdict: PASS WITH WARNINGS**

| Dimension | Result |
|-----------|--------|
| ETA removal (user-facing code) | **Pass** |
| Legal-safe replacements | **Pass** (EN primary; BN partial) |
| Emergency / AI limitation UX | **Pass** (enhanced vs prior emergency audit) |
| Admin governance | **Pass** (code-level) |
| Regression (build) | **Fail** — `symptom_checker_page.dart` analyzer error |
| Documentation / integrator risk | **Warn** — API contract + stale compliance reports |

**Production readiness score: 79 / 100** — suitable for **controlled launch** after fixing the symptom-checker compile blocker and completing BN subtitle + doc refresh. Not a full **unconditional PASS** until regression is green.

---

## 1. Coverage Results

### 1.1 Global text validation

| Surface | Method | Prohibited ETA in prod paths? | Result |
|---------|--------|-------------------------------|--------|
| Flutter l10n (EN) | Grep `Typical response`, minute ranges, `fastest way`, `Instant care` title | **None** in `assets/i18n/en.json`, `app_en.arb` | **Pass** |
| Flutter Dart UI | Grep `lib/**/*.dart` | **No matches** for legacy ETA strings | **Pass** |
| Backend user strings | Grep `src/**/*.ts` (excl. tests) | Only test fixtures + prompt “Never state guaranteed…” | **Pass** |
| Notifications | `notifications/events.ts` | Factual status only | **Pass** |
| SMS | Same + OTP | No ETA | **Pass** |
| Email templates | `notifications.service.ts` | `EMAIL` channel TODO — **no templates shipped** | **N/A Pass** |
| WhatsApp | `support-service.ts` | User-initiated dial; label only | **Pass** |
| AI system prompts | `ai-prompt.service.ts` `DEFAULT_PROMPTS` | Anti-ETA/guarantee clauses present | **Pass** |
| AI runtime output | `stripProhibitedEtaPhrases()` in `ai-safety.guardrails.ts` | Sanitization active | **Pass** |
| Admin CMS defaults | `emergency-limitation-defaults.ts`, vet/AI defaults | Negated guarantees only | **Pass** |
| Admin CMS saves | `messaging-compliance.ts` + 4 admin services | Validator wired; routes return 422 | **Pass** |

### 1.2 Instant Care wiring (regression spot-check)

`instant_care_sheet.dart` consumes legal-safe l10n keys and shows **VetDisclaimerBanner** + **EmergencyLimitationBanner (urgent + instantCare)** before action tiles — aligned with plan §5.3.

```97:109:lib/features/home/presentation/widgets/instant_care_sheet.dart
          Text(l10n.homeInstantCareTitle, style: theme.textTheme.titleLarge),
          ...
          const VetDisclaimerBanner(
            context: VetDisclaimerContext.instantCare,
            emergency: true,
          ),
          ...
          const EmergencyLimitationBanner(urgent: true),
          const EmergencyLimitationBanner(
            context: EmergencyLimitationContext.instantCare,
          ),
```

Subtitles use `homeCare*Eta` keys — verified EN/BN values are **non-SLA** (see §2).

---

## 2. ETA Validation

### 2.1 Search matrix (production assets)

| Pattern | Flutter `assets/i18n` | Backend `src` (prod) | Result |
|---------|----------------------|----------------------|--------|
| `Typical response` | **0** | Tests only | **Pass** |
| `under N min` / `5–15 min` / `15–30 min` | **0** | **0** | **Pass** |
| `will arrive in` | **0** | **0** | **Pass** |
| `will respond within` | **0** | **0** | **Pass** |
| `fastest way` | **0** (subtitle uses “not guaranteed”) | **0** | **Pass** |
| `Instant care` (title) | Replaced with **Urgent care options** | N/A | **Pass** |
| `estimatedResponseTime` / `"eta":` | N/A | N/A in code | **Warn** — still in `API_CONTRACT_V1.md` §12 |

### 2.2 Approved replacements verified (EN)

| Key | Verified EN value |
|-----|-------------------|
| `homeCareAiDoctorEta` | Automated guidance — not a live veterinarian |
| `homeCareCallDoctorEta` | We are attempting to connect you… Response times may vary. |
| `homeCareEmergencyVisitEta` | Emergency visit requests are reviewed when possible… |
| `homeCareVideoConsultationEta` | Online consultation depends on doctor availability… |
| `homeCareChatEta` | Support response times may vary… |
| `homeInstantCareTitle` | Urgent care options |
| `homeInstantCareSubtitle` | Choose how you want to seek help. Availability is not guaranteed. |
| `emergencyAvailable` | Accepts emergency requests (when available) |
| `searchEmergencySubtitle` | Doctors who may accept emergency requests |

### 2.3 Bengali (BN) localization

| Key | Status |
|-----|--------|
| `homeCare*Eta` (6) | **Pass** — curated BN in `bn.json` |
| `homeInstantCareTitle` | **Pass** — BN |
| `homeInstantCareSubtitle` | **Warn** — still **English** in `bn.json` |
| `emergencyAvailable`, `searchEmergencySubtitle` | **Pass** |

---

## 3. Compliance Results

### 3.1 Legal safety (no improper guarantees)

| Risk | Verification | Result |
|------|--------------|--------|
| Timing guarantees | No numeric SLA in l10n/SMS/notifications | **Pass** |
| Medical / treatment / recovery guarantees | No matches in Flutter user strings | **Pass** |
| Positive “guarantee” in CMS defaults | Uses “does not guarantee” / “not guaranteed” | **Pass** |
| `homeInstantCareSubtitle` | Contains **“Availability is not guaranteed”** (allowed negation) | **Pass** |

### 3.2 Emergency messaging

| Requirement | Evidence | Result |
|-------------|----------|--------|
| Encourages professional care | `DEFAULT_EMERGENCY_LIMITATION_URGENT`, vet emergency interstitial | **Pass** |
| Avoids dispatch promises | U1/U2/U3 + instant care subtitles | **Pass** |
| Instant Care no longer contradicts banners | ETA strings removed (fixes EL-02 from prior audit) | **Pass** |

### 3.3 AI messaging

| Requirement | Evidence | Result |
|-------------|----------|--------|
| AI limitation language | `AiDisclaimerBanner`, `AiEscalationDisclosureStrip`, `AiOutputComplianceWrapper` | **Pass** |
| No diagnosis/treatment/outcome guarantees in prompts | `DEFAULT_PROMPTS` | **Pass** |
| Triage/chat urgent tier | `AiOutputComplianceWrapper` sets `EmergencyLimitationBanner(urgent: true)` when `showUrgentBanner` | **Pass** |
| Symptom checker | Uses wrapper + `fromSymptomCheck`; **compile error** (see §6) | **Fail** |
| Backend triage string | “does not dispatch emergency services” in `ai-safety.service.ts` | **Pass** |

### 3.4 Admin validation

| Control | Location | Result |
|---------|----------|--------|
| Pattern validator | `src/shared/compliance/messaging-compliance.ts` | **Pass** |
| Admin assert helpers | `messaging-compliance-admin.ts` | **Pass** |
| PUT routes 422 on violation | 4 routes + `messaging-compliance-route.ts` | **Pass** |
| Unit tests | `messaging-compliance.test.ts` — **4/4 passed** (2026-05-30 run) | **Pass** |
| CI grep gate | Not in repo | **Warn** — recommended P1 |

**Note:** Validator allows negated “guarantee” (e.g. “does not guarantee immediate response”) — confirmed compatible with shipped defaults.

---

## 4. Remaining Risks

| ID | Risk | Severity | Type |
|----|------|----------|------|
| RR-01 | `symptom_checker_page.dart` references `result.disclaimer` (undefined) — **build failure** | **High** | Regression |
| RR-02 | `API_CONTRACT_V1.md` §12 still documents `estimatedResponseTime`, `eta`, “Customer notified with ETA” | **Medium** | Integrator / doc |
| RR-03 | Prior compliance reports (e.g. `EMERGENCY_LIMITATION_VERIFICATION_REPORT.md`) still state EL-02 **Fail** for ETAs — **doc drift** | **Low** | Process |
| RR-04 | Production `Setting` rows may contain pre-edit admin copy — **not scanned at runtime** | **Medium** | Ops |
| RR-05 | LLM output sanitizer is regex-based — novel SLA phrasing may slip through | **Low** | AI |
| RR-06 | BN `homeInstantCareSubtitle` English-only | **Low** | Localization |
| RR-07 | No automated Flutter/integration test asserting zero ETA strings | **Low** | QA |

---

## 5. Findings

### 5.1 Passed checks

- **F-01** P0 Instant Care ETA keys replaced in EN and primary BN paths.
- **F-02** `emergencyAvailable` and `searchEmergencySubtitle` qualified per matrix.
- **F-03** Instant Care sheet shows vet + emergency limitation banners above actions.
- **F-04** Notification and SMS bodies remain factual without SLA language.
- **F-05** Admin CMS save path rejects `Typical response: 5–15 min` (unit test).
- **F-06** AI prompts include explicit bans on response/arrival/guarantee language.
- **F-07** `stripProhibitedEtaPhrases()` applied in `sanitizeAssistantOutput()`.
- **F-08** Triage card uses `AiOutputComplianceWrapper` with urgent emergency banner when `result.emergency`.
- **F-09** Governance policy docs published under `pranidoctor-web/docs/compliance/`.

### 5.2 Warnings

- **W-01** API contract aspirational ETA examples unchanged (scope decision: no API contract edits).
- **W-02** BN `homeInstantCareSubtitle` not translated.
- **W-03** Stale sibling verification reports contradict current codebase (misleading for auditors).
- **W-04** Email channel not implemented — no violation, but no template governance yet.
- **W-05** No CI gate on l10n prohibited tokens.

### 5.3 Failed checks

- **X-01** `dart analyze` on `symptom_checker_page.dart`: **error** `undefined_getter` for `result.disclaimer` on `SymptomCheckResultModel` (line 136). Blocks clean build of AI symptom-check result flow.

---

## 6. Regression Validation

| Area | Check | Result |
|------|-------|--------|
| Instant Care UI | Analyzer on `instant_care_sheet.dart` | **Pass** (no issues) |
| Symptom checker UI | Analyzer on `symptom_checker_page.dart` | **Fail** (X-01) |
| l10n generation | Keys present in `app_localizations_impl.dart` for `homeCare*Eta`, `aiSymptomGuidanceNote` | **Pass** |
| Notifications | Static read `events.ts` | **Pass** (unchanged, safe) |
| SMS | Static read | **Pass** |
| Admin PUT | Validator + route wiring | **Pass** (static) |

**Workflow impact:** Symptom checker result screen may not compile until `disclaimer` reference is removed or model field added. Other messaging paths appear intact.

---

## 7. Recommended Fixes (no implementation in this verification)

| Priority | Action | Owner |
|----------|--------|-------|
| **P0** | Fix `symptom_checker_page.dart`: remove `inlineDisclaimer: result.disclaimer` or add optional `disclaimer` to `SymptomCheckResultModel` + API mapping | Mobile |
| **P0** | Run full `dart analyze` / CI on `pranidoctor_user` before release | Engineering |
| **P1** | Translate `homeInstantCareSubtitle` to BN in `build_localization.dart` overrides | Mobile/i18n |
| **P1** | Update `EMERGENCY_LIMITATION_VERIFICATION_REPORT.md` EL-02 status to **Pass** (or link to this report) | Compliance |
| **P1** | Add CI grep for `Typical response` / `\d+\s*[-–]\s*\d+\s*min` in `assets/i18n` and `app_en.arb` | Engineering |
| **P2** | Reconcile `API_CONTRACT_V1.md` §12 with as-built (separate change request) | API |
| **P2** | Audit production `Setting` JSON for admin-pasted SLA text | Ops |

---

## 8. Production Readiness Assessment

### 8.1 Messaging coverage

| Channel | Planned | Verified in code | Coverage |
|---------|---------|------------------|----------|
| Flutter UI (P0 keys) | 11 | 11 replaced | **100%** |
| Notifications | Maintain | Unchanged, safe | **100%** |
| SMS | Maintain | Unchanged, safe | **100%** |
| Email | N/A | Not shipped | **N/A** |
| WhatsApp | Support link | No templates | **100%** |
| AI prompts | 3 | 3 updated | **100%** |
| AI output sanitize | 1 | 1 | **~85%** (heuristic) |
| Admin CMS validation | 4 settings | 4 wired | **100%** |

**Weighted messaging coverage: ~92%**

### 8.2 Compliance coverage

| Pillar | Score (0–100) | Notes |
|--------|---------------|-------|
| ETA removal | **95** | Code clean; API doc + DB unknown |
| Limitation banners | **90** | Instant care + book + SR + AI wrapper |
| AI non-guarantee | **88** | Prompts + strips; build blocker on symptom checker |
| Admin governance | **90** | Validator live; no CI gate |
| Localization BN | **80** | One EN leak on subtitle |
| Regression / build | **60** | Symptom checker analyze failure |

**Weighted compliance coverage: ~86%**

### 8.3 Operational readiness

| Item | Ready? |
|------|--------|
| Counsel sign-off on replacement matrix | **Unknown** — not in repo |
| QA matrix (Instant Care EN/BN) | **Recommended** before marketing |
| Ops runbook for CMS violations (422) | Documented in messaging-governance.md |
| Monitoring for bad push copy | **Manual** — no automated scan of `Notification.body` |

---

## 9. Production Readiness Score

| Domain | Weight | Score | Weighted |
|--------|--------|-------|----------|
| ETA removal (code) | 30% | 95 | 28.5 |
| Legal-safe copy quality | 20% | 88 | 17.6 |
| Emergency + AI UX | 25% | 85 | 21.25 |
| Admin + AI backend controls | 15% | 90 | 13.5 |
| Build / regression | 10% | 40 | 4.0 |

**Total: 79 / 100**

---

## 10. Final Verdict

### PASS WITH WARNINGS

**Rationale**

- **Pass:** Core implementation objective met — prohibited Instant Care ETA wording removed from production l10n; approved replacements in place; emergency and AI limitation stacks present; admin validator and tests operational.
- **Warnings:** API contract drift, incomplete BN subtitle, stale compliance documents, no CI l10n gate, production CMS not runtime-audited.
- **Blocking warning treated as fail-grade for release:** Symptom checker **does not analyze clean** — must be resolved before calling messaging work fully production-ready.

**Not FAIL** because the primary EL-02 contradiction (Instant Care ETAs) is **resolved** in shipped strings and the majority of user journeys are compliant.

---

## 11. Verification evidence log

| Activity | Date | Outcome |
|----------|------|---------|
| Ripgrep prohibited patterns across `pranidoctor_user` assets + dart | 2026-05-30 | No legacy ETA in prod l10n |
| Read `instant_care_sheet.dart`, `notifications/events.ts`, `messaging-compliance.ts` | 2026-05-30 | Wiring confirmed |
| `npm test -- messaging-compliance.test.ts` | 2026-05-30 | 4/4 pass |
| `dart analyze` instant_care + symptom_checker | 2026-05-30 | Instant care OK; symptom checker **error** |

---

## 12. Sign-off checklist (for release gate)

- [ ] X-01 resolved — green analyze on symptom checker
- [ ] Manual QA Instant Care EN + BN — no minute-based subtitles
- [ ] Counsel acknowledges [eta-wording-matrix.md](../../pranidoctor-web/docs/compliance/eta-wording-matrix.md)
- [ ] Refresh or supersede `EMERGENCY_LIMITATION_VERIFICATION_REPORT.md` EL-02 line
- [ ] Optional: production CMS spot-check for SLA strings

---

*End of verification report. No product code was modified during this audit.*
