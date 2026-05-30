# Data Retention Policy (User Summary)

**Version:** 2026-06-01  
**Full schedule:** `pranidoctor-web/docs/compliance/data/RETENTION_MAPPING.md`

---

## 1. Principles

We retain personal and farm data only as long as needed to:

- Provide the service you use  
- Meet legal, tax, or clinical record obligations  
- Resolve disputes and maintain security  

We minimize sensitive data in logs and use anonymization where full deletion is not permitted.

## 2. Retention periods (summary)

| Data type | Retention | Notes |
|-----------|-----------|-------|
| Active account profile & farm records | While account is active | Deleted or anonymized after verified erasure request |
| OTP codes | ≤ 10 minutes | Automatic expiry |
| Login sessions / devices | Until expiry or revoke | Device records may be purged after 90 days (planned job) |
| Clinical & treatment records | Multi-year | Subject to legal review; may be anonymized not deleted |
| Financial / billing | Statutory period | Per tax law |
| AI chat & symptom sessions | ~18 months inactive | Purge job **planned** — not yet automated |
| AI usage metrics | ~24 months detail | Planned aggregation |
| Voice metadata | ~90 days | Planned |
| Notifications | ~12 months | Planned |
| Consent & legal audit events | ~24 months | Append-only audit |
| Auth security audit | ~18 months | Planned purge |
| Support tickets & complaints | Case lifetime + dispute window | Manual closure |
| Media (orphan uploads) | ~90 days | Planned |

## 3. Your deletion rights

You may request account deletion via **support@pranidoctor.com**. We will:

- Verify identity  
- Anonymize or delete data per [DATA_PROCESSING_OPERATIONS](https://github.com/pranidoctor/pranidoctor-web/blob/main/docs/compliance/data/DATA_PROCESSING_OPERATIONS.md) runbook  
- Retain minimal records where law requires  

**Self-serve automated export/erasure APIs are planned** — not yet generally available (GA requirement).

## 4. Backups

Backups may retain data for a limited window after deletion; we rotate backups per operations schedule.

## 5. Changes

Retention schedules may be updated in the canonical mapping document; material changes will be reflected in the Privacy Policy.

---

**Canonical:** `pranidoctor-web/docs/compliance/legal/DATA_RETENTION.md`
