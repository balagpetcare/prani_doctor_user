# User Consent Policy

**Version:** 2026-06-01  
**Status:** Implemented — engineering process document

---

## 1. Purpose

Defines how Prani Doctor collects, versions, stores, and enforces **user consent** across mobile and API layers without redesigning onboarding.

## 2. Consent types

| Key | `LegalConsentType` | Version field | Hard API gate | Re-consent UX |
|-----|-------------------|---------------|---------------|---------------|
| Privacy | `PRIVACY` | `privacyVersion` | Yes when `MOBILE_ENFORCE_PRIVACY_CONSENT=true` | `ReConsentPage` |
| Terms | `TERMS` | `termsVersion` | Client gate when `legalGateEnabled` | `ReConsentPage` |
| AI processing | `AI_PROCESSING` | `aiConsentVersion` | `/api/ai/*` middleware | `AiConsentPage` |
| Vet advice | `VET_ADVICE` | `vetDisclaimerVersion` | Per service-request accept | Booking flow |
| Emergency limitation | `EMERGENCY_SERVICE` | `emergencyLimitationVersion` | First `EMERGENCY_DOCTOR` SR | Accept sheet |

Registry: `pranidoctor-backend/src/legacy/web/lib/mobile-settings/consent-registry.ts`

## 3. Version source of truth

Published versions live in PostgreSQL `Setting` key **`mobile.legal.config`**, with defaults in `legal-defaults.ts`:

| Field | Default (2026-06-01) |
|-------|----------------------|
| `privacyVersion` | `2026-06-01` |
| `termsVersion` | `2026-06-01` |
| `aiConsentVersion` | `2026-06-01` |
| `vetDisclaimerVersion` | `2026-05-30.1` |
| `emergencyLimitationVersion` | `2026-05-30.1` |

Immutable legal text history: `LegalDocument` table (seed on deploy).

## 4. Storage model

| Store | Purpose |
|-------|---------|
| `MobileUserSettings.*AcceptedVersion` | Current accepted version per type |
| `MobileUserSettings.*AcceptedAt` | Timestamp of last grant |
| `LegalConsentEvent` | Append-only audit (grant / withdraw in metadata) |
| `LegalAcceptanceEvent` | Panel (admin/doctor) acceptance audit |

**Never delete** consent audit rows.

## 5. Collection channels

| Action | API / UI |
|--------|----------|
| Accept privacy + terms | `POST /api/mobile/settings/sync` |
| AI consent | `POST /api/mobile/legal/ai-disclaimer/accept` + settings sync |
| Vet disclaimer | `POST /api/mobile/legal/vet-disclaimer/accept` |
| Emergency limitation | `POST /api/mobile/legal/emergency-limitation/accept` |
| Withdraw | `POST /api/mobile/consent/withdraw` |
| Status | `GET /api/mobile/consent/status`, `GET /api/mobile/legal/status` |

## 6. Re-acceptance after material updates

1. Legal publishes new `LegalDocument` with `requiresReaccept=true`  
2. Admin bumps version in `mobile.legal.config`  
3. Users with stale `*AcceptedVersion` appear in `reconsentRequired`  
4. Mobile redirects to `/reconsent` or feature-specific consent screens  

## 7. Registration gap (known)

Registration may not yet write `LegalConsentEvent` for initial checkbox — **track as P1** for public beta. Workaround: post-login `ReConsentPage`.

## 8. Admin visibility

- `GET /api/admin/consent/overview` — acceptance counts vs current versions  
- `GET /api/admin/legal-consent` — audit log  
- Admin → Settings → Legal  

---

**Implementation:** `pranidoctor-web/docs/compliance/consent/USER_CONSENT_IMPLEMENTATION.md`
