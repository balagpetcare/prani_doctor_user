# Compliance Control Matrix — Prani Doctor

**Version:** 1.0  
**Date:** 2026-06-01  
**Launch plan:** [legal-compliance-plan.md](../launch/legal-compliance-plan.md)

Legend: ✅ Implemented · ⚠️ Partial · ❌ Gap · 📄 Documentation only

---

## A. Legal documents

| Document | Repo package | Registry key | Public URL | Status |
|----------|--------------|--------------|------------|--------|
| Terms of Service (customer) | `docs/legal/terms-of-service.md` | `TOS-CUSTOMER` | `/terms` | ✅ 📄 |
| Privacy Policy | `docs/legal/privacy-policy.md` | `PRIVACY-POLICY` | `/privacy` | ✅ 📄 |
| AI Usage Policy | `docs/legal/ai-usage-policy.md` | `AI-CONSENT` | In-app | ✅ 📄 |
| AI Limitations | `docs/legal/ai-limitations.md` | CMS | In-app | ✅ |
| Emergency Disclaimer | `docs/legal/emergency-disclaimer.md` | CMS | In-app | ✅ |
| Veterinary Disclaimer | `docs/legal/veterinary-disclaimer.md` | CMS | In-app + `/legal/disclaimer` | ✅ |
| Acceptable Use (admin) | `docs/legal/acceptable-use-policy.md` | `TOS-ADMIN` | Admin gate | ✅ |
| Data Retention | `docs/legal/data-retention-policy.md` | — | Linked | ✅ 📄 |
| User Consent Policy | `docs/legal/user-consent-policy.md` | — | Internal | ✅ 📄 |
| Complaint Handling | `docs/legal/complaint-handling-policy.md` | — | Support | ✅ 📄 |
| Cookie policy | Privacy § | — | `/privacy#cookies` | ⚠️ |
| Refund policy | Web | — | `/refund` | ✅ |

---

## B. User consent framework

| Control | Backend | Mobile | Admin | Status |
|---------|---------|--------|-------|--------|
| Terms acceptance + version | `MobileUserSettings.termsAcceptedVersion` | `ReConsentPage` | Overview | ✅ |
| Privacy acceptance + version | `privacyAcceptedVersion` | `ReConsentPage` | Overview | ✅ |
| AI acknowledgement | `aiAcceptedVersion` + middleware | `AiConsentPage` | Overview | ✅ |
| Emergency acknowledgement | `emergencyAcceptedVersion` + SR guard | Accept sheet | Overview | ✅ |
| Vet acknowledgement | `vetAcceptedVersion` | Booking flow | Overview | ✅ |
| Timestamp tracking | `*AcceptedAt` fields | — | — | ✅ |
| Audit trail | `LegalConsentEvent` | — | `/api/admin/legal-consent` | ✅ |
| Privacy API enforcement | `MOBILE_ENFORCE_PRIVACY_CONSENT` | Router gate | Toggle in legal settings | ⚠️ default off |
| Registration consent audit | — | Checkbox | — | ❌ P1 |

---

## C. Legal acceptance tracking

| Capability | Implementation | Status |
|------------|----------------|--------|
| Current acceptance storage | `MobileUserSettings` | ✅ |
| History | `LegalConsentEvent` append-only | ✅ |
| Version references | `mobile.legal.config` | ✅ |
| Re-acceptance | Version mismatch → `reconsentRequired` | ✅ |
| Panel acceptance | `LegalAcceptanceEvent` | ✅ |
| Immutable document versions | `LegalDocument` | ✅ |

---

## D. AI compliance integration

| Control | Location | Status |
|---------|----------|--------|
| T1/T2 banners | `AiCompliancePageBody` | ✅ |
| T3 acceptance | `AiConsentPage` + CMS | ✅ |
| Inline output wrapper | `AiOutputComplianceWrapper` | ✅ |
| E2 escalation strips | `AiEscalationDisclosureStrip` | ✅ |
| API disclaimers | AI routes response fields | ✅ |
| CMS messaging validator | `messaging-compliance.ts` | ✅ |
| Kill switch | `AiGovernanceService` | ✅ |
| Secondary routes (knowledge, alerts) | — | ⚠️ |
| Kill switch user notice | — | ❌ P1 |
| Voice API consent parity | — | ❌ P1 |

---

## E. Privacy compliance controls

| Control | Documented | Automated | Status |
|---------|------------|-----------|--------|
| Data collection inventory | `ROPA_REGISTER.md` (web) | — | ✅ 📄 |
| Processing inventory | `DATA_PROCESSING_POLICY.md` | — | ✅ 📄 |
| Retention periods | `RETENTION_MAPPING.md` | Purge jobs | ⚠️ 📄 only |
| Deletion workflow | `DATA_PROCESSING_OPERATIONS.md` | Manual SOP | ⚠️ |
| Export workflow | Same | Self-serve API | ❌ GA |

---

## F. Complaint & escalation

| Control | Status |
|---------|--------|
| Complaint model + admin AI complaints | ✅ |
| Published complaint policy | ✅ 📄 (this package) |
| User self-serve complaint UI | ⚠️ |
| AI escalation records | ✅ |
| Ops escalation monitoring | ✅ |

---

## G. Admin compliance support

| Control | Status |
|---------|--------|
| Policy version management | ✅ `AdminLegalSettingsForm` |
| Consent overview API | ✅ `GET /api/admin/consent/overview` (extended) |
| Consent audit list | ✅ |
| Launch ops compliance panel | ✅ (this implementation) |
| Counsel sign-off metadata | ❌ P0 legal |

---

## Risk summary

| Priority | Count | Examples |
|----------|------:|----------|
| P0 | 4 | Counsel sign-off, DPAs, prod legal URLs, privacy enforce flag for public beta |
| P1 | 6 | Registration audit, voice consent, AI route coverage, kill switch notice |
| P2 | 4 | Export/erasure automation, cookie CMP, API contract ETA fields |
| P3 | 2 | Community guidelines, stale verification PDFs |
