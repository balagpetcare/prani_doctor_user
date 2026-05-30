# Veterinary Advice Disclaimer

**CMS setting:** Vet disclaimer config  
**Default version:** `2026-05-30.1`  
**Consent type:** `VET_ADVICE`  
**Framework:** V0 / V1 / V2 / V3

---

## 1. Purpose

This disclaimer clarifies the relationship between **you (the farmer)**, **licensed veterinarians and providers on the platform**, and **Prani Doctor** when you book or receive veterinary-related services.

## 2. Platform role

Prani Doctor:

- Facilitates discovery, booking, and communication  
- Stores records you and providers enter  
- Does **not** provide veterinary diagnosis, treatment, or prescription as the platform operator  

## 3. Provider role

Licensed veterinarians and qualified field providers:

- Are **independent professionals**  
- Are responsible for examination, diagnosis, treatment plans, and prescriptions they issue  
- Must hold valid credentials required for their jurisdiction  

## 4. Your role

You are responsible for:

- Accurate information about animals and symptoms  
- Following provider instructions and applicable law for medicines and withdrawal periods  
- Seeking timely care when conditions worsen  

## 5. No guarantee of outcomes

We do **not** guarantee:

- Clinical success of any treatment  
- Availability of a specific doctor  
- Response or arrival times (see [Emergency Disclaimer](./emergency-disclaimer.md))  
- That online or home-visit booking equals immediate examination  

## 6. When shown

| Context | Tier | Acceptance |
|---------|------|------------|
| Book consultation / home visit | V1 + contextual | Per service-request flow |
| Instant care | V1 | Banner |
| Treatment journal entry | V1 | Banner |
| Prescription view (farmer) | Contextual | Verify wiring before GA |

## 7. AI vs human advice

**AI guidance** is separate and informational only — see [AI Limitations](./ai-limitations.md).  
**Human veterinary advice** through booked services is subject to this disclaimer and provider professional duty.

## 8. Acceptance

Vet disclaimer version is stored on `MobileUserSettings` (`vetAcceptedVersion`, `vetAcceptedAt`) and audited via `LegalConsentEvent` when accepted through service flows.

## 9. Contact

Clinical questions for a booked case: contact your assigned provider through the app.  
Platform issues: support@pranidoctor.com

---

**Canonical:** `pranidoctor-web/docs/compliance/veterinary/veterinary-disclaimer-plan.md`  
**Public summary:** https://pranidoctor.com/legal/disclaimer
