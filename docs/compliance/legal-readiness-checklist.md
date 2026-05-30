# Legal Readiness Checklist

**Version:** 1.0  
**Date:** 2026-06-01  
**Related:** [legal-compliance-plan.md](../launch/legal-compliance-plan.md) · [compliance-matrix.md](./compliance-matrix.md)

Use this checklist at release gates. Mark **Done** only with evidence (link, screenshot, or query output).

---

## Controlled Beta gate

### Legal documents (P0)

- [ ] Counsel reviewed BN+EN customer ToS and Privacy (beta addendum OK)
- [ ] `docs/legal/*` package matches published `LegalDocument` content
- [ ] `seedLegalDocuments()` run on staging/production
- [ ] `https://<host>/privacy` and `/terms` return HTTP 200
- [ ] LLM + SMS vendor DPAs executed or beta limited to rules-only AI

### Consent & enforcement

- [ ] AI middleware active on `/api/ai/*`
- [ ] Emergency `EMERGENCY_DOCTOR` acceptance guard verified
- [ ] Vet disclaimer on booking + instant care verified on device
- [ ] `MOBILE_ENFORCE_PRIVACY_CONSENT` decision documented (may be `false` for CB)
- [ ] Admin consent overview shows plausible acceptance counts

### AI & messaging

- [ ] No prohibited ETA strings in production l10n
- [ ] CMS messaging validator rejects non-compliant admin copy
- [ ] Symptom checker + triage analyze clean (`dart analyze`)
- [ ] Primary AI routes show T1/T2 + inline disclaimers

### Ops

- [ ] Complaint SOP shared with support (`complaint-handling-policy.md`)
- [ ] DSAR manual process documented for pilot users
- [ ] TLS + backup drill per closed-beta plan

**Gate verdict:** ≥ 65 compliance score → **Conditional GO**

---

## Public Beta gate

All Controlled Beta items, plus:

- [ ] `MOBILE_ENFORCE_PRIVACY_CONSENT=true` in production
- [ ] `legalGateEnabled` true; re-consent flow tested after version bump
- [ ] Registration consent → `LegalConsentEvent` (or documented workaround removed)
- [ ] Play Store Data Safety + privacy URL accurate
- [ ] AI secondary routes gated or hidden
- [ ] Voice API AI consent parity
- [ ] Marketplace provider ToS if AI technician / semen live
- [ ] BN legal strings complete for material flows
- [ ] Re-run verification reports (ToS, privacy, consent, emergency, vet)

**Gate verdict:** ≥ 78 compliance score

---

## General Availability gate

All Public Beta items, plus:

- [ ] Automated retention purge jobs operational
- [ ] Self-serve data export API
- [ ] Automated erasure / anonymization job with proof
- [ ] Cookie / analytics consent on web admin
- [ ] Full `RETENTION_MAPPING` for production models
- [ ] Published complaint SLA (counsel-approved)
- [ ] Counsel sign-off recorded in `LegalDocument.metadataJson`
- [ ] Annual compliance review scheduled

**Gate verdict:** ≥ 88 compliance score

---

## Quick verification commands

```bash
# Backend consent overview (admin auth required)
curl -s -H "Cookie: ..." https://<api>/api/admin/consent/overview | jq .

# Mobile legal status (customer auth)
curl -s -H "Authorization: Bearer ..." https://<api>/api/mobile/consent/status | jq .
```

---

## Sign-off

| Role | Name | Date | Beta | Public Beta | GA |
|------|------|------|:----:|:-----------:|:--:|
| Legal counsel | | | | | |
| Compliance lead | | | | | |
| Engineering lead | | | | | |
| Launch ops | | | | | |
