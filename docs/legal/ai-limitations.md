# AI Limitation Notice

**CMS setting:** `mobile.ai.disclaimer.config`  
**Default consent version:** `2026-06-01` (aligned with AI consent document)  
**Framework:** T1 / T2 / T3 + per-output inline disclosure + E2 escalation

---

## 1. Purpose

This notice is displayed in the app so users understand **limits of machine-assisted guidance** before and during use. It complements the [AI Usage Policy](./ai-usage-policy.md).

## 2. Disclosure tiers (as implemented)

| Tier | UI component | When shown |
|------|--------------|------------|
| **T1** | Persistent banner (`AiCompliancePageBody`) | AI hub and gated AI screens |
| **T2** | Contextual banner | Chat, recommendations, advisory features |
| **T3** | Acceptance modal (`AiConsentPage`) | First AI use when `enforceAcceptance` is on |
| **Inline** | `AiOutputComplianceWrapper` | Each assistant message / triage / symptom result |
| **E2** | `AiEscalationDisclosureStrip` | When urgency or escalation is detected |
| **Fallback** | `AiComplianceFallbackCopy` | When CMS unavailable (EN/BN) |

## 3. Required themes (all tiers)

Every AI surface must communicate:

1. **Assistive tool** — not a licensed veterinarian  
2. **Accuracy limits** — may be wrong or incomplete  
3. **No physical exam** — cannot see or test the animal  
4. **Non-diagnostic** — not diagnosis, prescription, or treatment plan  
5. **User responsibility** — seek professional care when serious  

## 4. Canonical wording (English defaults)

**Banner (T1/T2):**  
*"Prani Doctor AI provides general livestock guidance. It cannot see or examine your animal, run tests, or verify what you report. Answers may be wrong, incomplete, or outdated."*

**Inline:**  
*"This is educational guidance only — not a veterinary diagnosis, prescription, or treatment plan."*

**Escalation (E2):**  
Urgency messaging must **not** imply dispatch, guaranteed response time, or that a veterinarian is assigned. Approved patterns reference seeking local care and optional platform escalation to human review.

## 5. Prohibited claims (engineering-enforced)

Admin CMS saves are validated (`messaging-compliance.ts`) to reject:

- Guaranteed response times or SLAs to users  
- “Typical response in X minutes” style ETA promises  
- Language implying the platform is an emergency clinic or ambulance service  

AI system prompts strip prohibited ETA phrases server-side.

## 6. Surface coverage

| Surface | T1/T2 | T3 | Inline | E2 |
|---------|:-----:|:--:|:------:|:--:|
| AI hub / chat | ✅ | ✅ | ✅ | ✅ |
| Triage / symptom checker | ✅ | ✅ | ✅ | ✅ |
| Smart recommendations / farm health | ✅ | ✅ | partial | partial |
| Knowledge / alerts / follow-ups | ⚠️ | ⚠️ | — | — |

⚠️ = disable route or complete gating before public beta if exposed.

## 7. Kill switch

Operations may disable external LLM inference. Users should see operational notice when rules-only mode is active (planned copy — verify before GA).

## 8. Admin management

**Admin → Settings → AI Disclaimer** — versioned copy, `enforceAcceptance`, locale BN/EN.

**Audit:** AI consent via `LegalConsentEvent`; escalation via `AiEscalationRecord`.

---

**Related:** `pranidoctor-web/docs/compliance/ai-disclosure-policy.md`, `docs/launch/ai-compliance-plan.md`
