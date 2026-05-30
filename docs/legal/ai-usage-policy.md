# AI Usage Policy

**Document key:** `AI-CONSENT`  
**Version:** 2026-06-01  
**Effective date:** 1 June 2026  
**Applies to:** Machine-assisted AI features (not human “AI Technician” field services)

---

## 1. Purpose

This policy explains how Prani Doctor uses artificial intelligence to provide **assistive livestock guidance** and what you agree to when you enable AI features.

## 2. Features covered

When you consent, the following may use AI inference (rules and/or external LLM providers):

| Feature | Behavior |
|---------|----------|
| AI chat | Conversational guidance from your messages and optional farm context |
| Symptom checker | Structured symptom flow with triage-style output |
| AI triage | Free-text urgency assessment in chat |
| Smart recommendations / farm health | Rule-based and aggregated suggestions |
| Voice input | Speech-to-text then chat (same AI path) |
| Farm briefing / query (when exposed) | Summaries from farm data |

**Not covered:** Booking human AI (artificial insemination) technicians — those are governed by provider terms and human service agreements.

## 3. What AI does and does not do

**AI may:**

- Suggest educational next steps
- Flag possible urgency keywords
- Recommend contacting a veterinarian or support

**AI does not:**

- Diagnose disease with clinical certainty
- Prescribe medicines or dosages as a treating veterinarian
- Examine your animal physically
- Dispatch emergency services or guarantee doctor arrival times
- Replace a licensed veterinarian

## 4. Data sent to providers

When you use AI features, we may send:

- Your messages and symptom descriptions
- Limited animal/farm context (species, labels, health summaries you have entered)
- Session metadata for safety and audit

Providers may include **OpenAI** and **Anthropic** when LLM mode is enabled. A rules-only fallback may apply when LLM is disabled by operations.

## 5. Your choices

- You must accept this policy (version tracked) before first use of AI APIs
- You may decline AI and still use non-AI parts of the app
- You can review acceptance in **Settings → AI consent**
- Withdrawal of AI consent is recorded in our audit log and may block AI routes

## 6. Accuracy and limitations

Outputs may be **wrong, incomplete, or outdated**. Voice transcription may contain errors. Always use professional judgment and seek licensed veterinary care when symptoms are serious.

See [AI Limitations](./ai-limitations.md) for banner tiers and escalation notices.

## 7. Safety and escalation

The platform may:

- Block prohibited content (e.g. requests for unsupervised prescription)
- Show **escalation** notices when urgency is detected
- Record escalation events for operations review (not a treatment plan)

Escalation **does not** mean a doctor has been assigned or is en route.

## 8. Emergency

If you believe an animal’s life is at risk, contact a **local veterinarian or emergency services immediately**. Do not delay care while using the app. See [Emergency Disclaimer](./emergency-disclaimer.md).

## 9. Changes

We may update this policy. A new `aiConsentVersion` in `mobile.legal.config` will require re-acceptance when configured.

## 10. Contact

support@pranidoctor.com

---

**Technical enforcement:** `POST /api/mobile/settings/sync` (`acceptAiVersion`), `LegalConsentEvent` type `AI_PROCESSING`, middleware on `/api/ai/*`.

**Canonical summaries:** `pranidoctor-backend` → `DEFAULT_AI_CONSENT_SUMMARY` in `legal-defaults.ts`
