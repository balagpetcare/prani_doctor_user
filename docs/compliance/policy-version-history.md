# Policy Version History

**Maintained by:** Legal operations + release engineering  
**Source of truth (runtime):** `Setting` key `mobile.legal.config` and `LegalDocument` table

---

## Current published versions (defaults)

| Policy | Document key / CMS | Default version | Effective |
|--------|-------------------|-----------------|-----------|
| Privacy Policy | `PRIVACY-POLICY` | `2026-06-01` | 2026-06-01 |
| Terms of Service (customer) | `TOS-CUSTOMER` | `2026-06-01` | 2026-06-01 |
| AI Usage / consent | `AI-CONSENT` | `2026-06-01` | 2026-06-01 |
| Veterinary disclaimer | CMS vet disclaimer | `2026-05-30.1` | 2026-05-30 |
| Emergency limitation | CMS emergency | `2026-05-30.1` | 2026-05-30 |
| Admin AUP | `TOS-ADMIN` | `2026-06-01` | 2026-06-01 |
| Provider doctor ToS | `TOS-PROVIDER-DOCTOR` | `2026-06-01` | 2026-06-01 |
| Data retention policy doc | — | `2026-06-01` | 2026-06-01 |
| Legal package (repo) | `docs/legal/*` | `2026-06-01` | 2026-06-01 |

Code defaults: `pranidoctor-backend/src/legacy/web/lib/mobile-settings/legal-defaults.ts`

---

## Changelog

### 2026-06-01 — Launch legal package v1

- Unified customer legal docs under `pranidoctor_user/docs/legal/`
- Aligned privacy/terms/AI consent versions to `2026-06-01`
- Added complaint handling policy (SOP)
- Extended admin consent overview (vet + emergency counts)
- Compliance matrix and legal readiness checklist published

**Engineering actions required on bump:**

1. Insert `LegalDocument` rows (do not edit in place)  
2. Update `mobile.legal.config` version fields  
3. Set `requiresReaccept` for material changes  
4. Deploy backend → web → mobile  
5. Record counsel sign-off in `metadataJson` when available  

### 2026-05-30 — Compliance tracks

- Emergency limitation framework (`2026-05-30.1`)
- Vet disclaimer CMS (`2026-05-30.1`)
- Legal-safe messaging (ETA removal)
- `LegalConsentType` extended with `EMERGENCY_SERVICE`, `VET_ADVICE`
- Privacy policy draft `2026-05-30` superseded by `2026-06-01` for enforcement alignment

### Earlier

- `LegalDocument` registry migration `20260601180000`
- Legal consent audit `20260530180000`
- AI disclaimer / escalation CMS tracks

---

## Version drift watchlist

| Location | Risk |
|----------|------|
| `docs/legal/*.md` vs `pranidoctor-web/docs/compliance/legal/*.md` | Content drift — sync on each legal release |
| `docs/legal/PRIVACY_POLICY.md` (legacy path) | Prefer `privacy-policy.md` |
| Flutter hardcoded fallbacks | Must match CMS defaults |
| Play Store Data Safety form | Must match RoPA |
| `API_CONTRACT_V1.md` ETA examples | Integrator confusion — P2 |

---

## How to query acceptance drift (PostgreSQL)

```sql
-- Customers not on current privacy version (replace version string)
SELECT u.id, u.phone, m."privacyAcceptedVersion"
FROM "User" u
LEFT JOIN "MobileUserSettings" m ON m."userId" = u.id
WHERE u.role = 'CUSTOMER' AND u.status = 'ACTIVE'
  AND (m."privacyAcceptedVersion" IS DISTINCT FROM '2026-06-01');
```

See `pranidoctor-web/docs/compliance/legal/LEGAL_OPERATIONS.md` for full runbook.
