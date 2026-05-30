# Legal Document Package — Prani Doctor

**Version:** 2026-06-01  
**Status:** Launch-ready draft — **requires counsel sign-off before GA**

This folder is the **mobile/repo legal package** for Controlled Beta, Public Beta, and GA. Canonical operator copies with full schedules live in `pranidoctor-web/docs/compliance/legal/`.

## Documents

| File | Document key | In-app / public |
|------|----------------|-----------------|
| [terms-of-service.md](./terms-of-service.md) | `TOS-CUSTOMER` | `/terms`, Settings |
| [privacy-policy.md](./privacy-policy.md) | `PRIVACY-POLICY` | `/privacy`, Settings |
| [ai-usage-policy.md](./ai-usage-policy.md) | `AI-CONSENT` | AI consent screen |
| [ai-limitations.md](./ai-limitations.md) | CMS `mobile.ai.disclaimer.config` | T1/T2/T3 banners |
| [emergency-disclaimer.md](./emergency-disclaimer.md) | CMS emergency limitation | U1/U2/U3 |
| [veterinary-disclaimer.md](./veterinary-disclaimer.md) | CMS vet disclaimer | Booking, instant care |
| [acceptable-use-policy.md](./acceptable-use-policy.md) | `TOS-ADMIN` | Admin gate |
| [data-retention-policy.md](./data-retention-policy.md) | — | Linked from privacy |
| [user-consent-policy.md](./user-consent-policy.md) | — | Process / engineering |
| [complaint-handling-policy.md](./complaint-handling-policy.md) | — | Support SOP |

## Version alignment

Published versions are controlled by backend `Setting` key `mobile.legal.config`. See [policy-version-history.md](../compliance/policy-version-history.md).

## Implementation

- Acceptance: `MobileUserSettings` + `LegalConsentEvent` (append-only)
- Enforcement: `MOBILE_ENFORCE_PRIVACY_CONSENT`, AI middleware, emergency SR guard
- Launch gate: [legal-readiness-checklist.md](../compliance/legal-readiness-checklist.md)
