# Privacy Policy

**Document key:** `PRIVACY-POLICY`  
**Version:** 2026-06-01  
**Effective date:** 1 June 2026  
**Operator:** Prani Doctor / Animal Doctors  
**Contact:** support@pranidoctor.com  
**Public URL:** https://pranidoctor.com/privacy

> **Operator notice:** Aligns with platform behavior as of 2026-06-01. Counsel review required before GA.

---

## 1. Scope

This policy applies to:

- **Prani Doctor** mobile app (farmers/customers)
- **Doctor** and **admin** web portals
- APIs and customer support channels

## 2. Data we collect

| Category | Examples | Purpose |
|----------|----------|---------|
| Account | Name, phone, optional email | Authentication, account management |
| Location hierarchy | Division, district, upazila, union, village; visit notes | Service matching |
| Animals & farm | Species, breed, health, production, finance records you enter | Farm management, clinical context |
| Service & clinical | Symptoms, consultations, prescriptions, treatment notes | Service delivery with providers |
| Device | Device key, platform, app version, push token (optional) | Security, notifications |
| Session & security | IP, user agent, login audit | Fraud prevention |
| Media | Photos/documents you upload | Profiles, consultations |
| AI interactions | Chat, symptom checks, voice transcripts (text) | Assistive guidance — **not autonomous diagnosis** |
| Support | Tickets, complaints, messages | Customer support |

We **do not sell** personal data.

## 3. How we use data

- Provide and improve the service you request
- Connect you with assigned doctors or technicians
- Send **transactional** notifications (appointments, case updates)
- Operate optional AI features **only with separate AI consent**
- Secure accounts and comply with law

**Marketing** notifications are **opt-in** (`marketingEnabled` defaults off).

## 4. Legal bases (summary)

| Processing | Basis |
|------------|-------|
| Core account and bookings | Contract |
| Clinical records with providers | Contract + legitimate interest (care continuity) |
| Security logs | Legitimate interest |
| Marketing | Consent |
| AI assistive features | Consent ([AI Usage Policy](./ai-usage-policy.md)) |

## 5. Sharing

**On-platform:** Assigned doctors and technicians receive data needed to perform requested services.

**Processors (examples):**

| Provider | Purpose |
|----------|---------|
| Cloud hosting (PostgreSQL, object storage) | Storage |
| Firebase (Google) | Push; optional crash reporting |
| SMS gateway | OTP and transactional SMS |
| OpenAI / Anthropic | AI inference when enabled |
| Sentry (when enabled) | Error monitoring |

We do not sell or rent personal data.

## 6. International transfers

Some processors may process data outside Bangladesh. We use appropriate contractual safeguards per vendor agreements (DPAs on file with operations).

## 7. AI processing

- AI is **informational only** — not a licensed veterinarian
- Context (e.g. species, farm summaries) may be sent to LLM providers when you use AI features
- We do **not** use your content to train public foundation models without explicit opt-in
- **AI processing consent** is collected before first use of `/api/ai/*` features

## 8. Cookies and web analytics

The **admin** and **public web** sites may use session cookies and error monitoring (e.g. Sentry). See § Cookies in the canonical web policy. Mobile app uses device identifiers and local cache — not browser cookies.

## 9. Retention

See [Data Retention Policy](./data-retention-policy.md). Summary:

- Active account data: while account is active
- OTP: minutes
- Clinical records: multi-year where law or continuity requires
- AI chat: limited retention per schedule (purge jobs planned)
- Consent audit: up to 24 months

## 10. Your rights

You may:

- **Access** or request a copy — contact support@pranidoctor.com
- **Correct** profile and farm records in the app
- **Delete** your account — verified request via support (automated self-serve export/erasure planned)
- **Withdraw** marketing or AI consent where applicable (AI withdrawal may limit AI features)

We respond within reasonable timelines per applicable law.

## 11. Children

The service is not directed at children under 18.

## 12. Security

We use access controls, encryption in transit, hashed credentials, and audit logging. No method is 100% secure — report concerns to support@pranidoctor.com.

## 13. Changes

We publish new versions via `LegalDocument` and may prompt **re-acceptance** for material changes.

## 14. Contact

**Prani Doctor Support** — support@pranidoctor.com

---

**Canonical:** `pranidoctor-web/docs/compliance/legal/PRIVACY_POLICY.md`  
**In-app acceptance version:** `mobile.legal.config` → `privacyVersion`
