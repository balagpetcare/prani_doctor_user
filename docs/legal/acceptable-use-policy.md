# Acceptable Use Policy — Admin & Support

**Document key:** `TOS-ADMIN`  
**Version:** 2026-06-01  
**Audience:** `ADMIN`, `SUPER_ADMIN`, `SUPPORT`  
**Enforcement:** `AdminLegalGate` on admin web console

---

## 1. Acceptance

By accessing the Prani Doctor **admin console**, you agree to this Acceptable Use Policy and applicable employment or contractor agreements.

## 2. Authorized use

You may use admin tools only to:

- Operate the platform per your assigned role  
- Verify providers, moderate content, and resolve support cases  
- Configure legal, AI, and emergency disclaimer copy per approved procedures  
- View compliance and consent reports as authorized  

## 3. Data protection obligations

- Access **minimum necessary** customer, provider, and clinical data  
- Do **not** export bulk personal data without written authorization  
- Do **not** share credentials or session tokens  
- Report suspected breaches immediately per incident runbook  

## 4. Prohibited conduct

- Sharing admin credentials or bypassing authentication  
- Disabling audit trails, consent logs, or moderation workflows without approval  
- Using admin tools for personal, political, or unauthorized commercial purposes  
- Publishing unapproved legal text to production CMS fields  
- Entering user-facing copy that guarantees response times, clinical outcomes, or emergency dispatch  

CMS saves for emergency, vet, and AI legal fields are **validated** server-side against messaging compliance rules.

## 5. AI operations

Personnel with access to AI ops (prompts, kill switch, knowledge base) must:

- Follow change-control for prompt updates  
- Not enable LLM features in production without DPAs and legal sign-off  
- Document kill-switch activations in operations logs  

## 6. Enforcement

Violations may result in access revocation, disciplinary action, and legal reporting where required.

## 7. Acknowledgement

Acceptance is recorded via panel legal status (`TOS-ADMIN` / `LegalAcceptanceEvent`).

---

**Canonical:** `pranidoctor-web/docs/compliance/legal/TERMS_OF_SERVICE_ADMIN.md`
