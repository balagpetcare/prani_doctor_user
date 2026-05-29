# Security Guide — Prani Doctor

**Version:** 1.0 · Phase 6

## Overview

Security is enforced at four layers: **edge (TLS/nginx)**, **API (Express)**, **BFF (Next.js)**, and **mobile (Flutter)**.

## API (pranidoctor-backend)

| Control | Implementation |
|---------|----------------|
| Helmet + HSTS | `src/shared/security/middleware/security-stack.ts` |
| CORS allowlist | `src/app.ts` — rejects unknown origins |
| Rate limiting | Redis sliding window; **503 if Redis down** in staging/production |
| Input sanitization | Null-byte strip + trim on body/query |
| JWT | Channel-specific secrets (≥32 chars); no `CHANGE_ME` in production |
| Refresh tokens | Hashed, rotated, reuse detection (`refresh-token.service.ts`) |
| Uploads | MIME allowlist + magic-byte sniff (`media.validation.ts`) |
| Audit | `auth-audit.service.ts`, Redis audit TTL |
| API docs | `/api/docs` hidden in production unless `API_DOCS_KEY` set |
| Metrics | `/metrics` — Bearer `METRICS_TOKEN` in production |

## Web (pranidoctor-web)

- Admin/doctor/enterprise panels: CSP + security headers (`next.config.ts`).
- API routes proxy to backend — do not add Prisma in route handlers.
- Production env validated via `npm run validate:production-env`.

## Mobile (pranidoctor_user)

- Tokens in `FlutterSecureStorage` (Android encrypted prefs).
- Release builds require HTTPS `API_BASE_URL` and `UPLOAD_URL`.
- Network logs redacted; `LOG_NETWORK` debug-only.
- Optional: certificate pinning (not enabled by default).

## Secrets

Never commit `.env`. Use:

- `.env.development.example`
- `.env.staging.example`
- `.env.production.example`

Generate JWT secrets: `openssl rand -base64 32`

## Reporting vulnerabilities

Contact the platform team privately before public disclosure.
