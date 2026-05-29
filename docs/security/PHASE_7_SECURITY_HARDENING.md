# Phase 7 — Security Hardening

**Date:** 2026-05-29

---

## Controls implemented

### Authentication & sessions

- Backend: OTP rate limits, Redis session binding, `OTP_MODE=live` enforced in production env validation
- Mobile: tokens in `FlutterSecureStorage`; release requires HTTPS API URL

### Authorization

- **Backend:** RBAC on Express routes (canonical enforcement)
- **Web BFF:** `requireAdminPanelApiAccess` on all `/api/admin/*` proxies except auth login/logout and health probes
- **HTML panels:** Cookie gate in `proxy.ts` for `/admin`, `/doctor`, `/enterprise`

### Rate limiting

| Preset | Routes |
|--------|--------|
| `API_STANDARD` | Global (exempts `/health`, `/ready`, `/live`, `/metrics`) |
| `AI_CHAT` | `/api/ai/chat`, `/api/ai/triage`, `/api/voice/chat` |
| `SEARCH` | `/api/area/search` |
| `EXPORT` | `/api/admin/analytics/reports?format=csv` |
| Auth presets | OTP, login, upload (existing) |

Fail-closed: staging/production return 503 if Redis unavailable.

### Secrets & migrations

- `validate:production-env` in backend and web CI/deploy
- `prisma-production-guard.mjs` blocks prod-looking hosts without `ALLOW_PRODUCTION_MIGRATE=true`
- gitleaks + CodeQL workflows on backend and web

### Error tracking

| Service | Mechanism |
|---------|-----------|
| Backend | `SENTRY_DSN` + `ERROR_TRACKING_WEBHOOK_URL` |
| Web | `SENTRY_DSN` + webhook provider |
| Mobile | `CRASH_REPORTING_WEBHOOK_URL` dart-define |

### Edge / TLS

- nginx example: HSTS, HTTP→HTTPS redirect, auth path rate limit, probe bypass
- Helmet + CORS on Express (existing Phase 6)

---

## Operational requirements (not auto-enforced)

- Rotate JWT secrets on compromise — see [../incident-response-guide.md](../incident-response-guide.md)
- Configure `METRICS_TOKEN` and scrape `/metrics` from private network
- Virus scan on uploads (ClamAV) — deferred P1-12
- Certificate pinning on mobile — deferred P2-06

---

## Verification commands

```bash
# BFF admin guard (expect 401 without session cookie)
curl -i https://admin.example.com/api/admin/analytics/overview

# Rate limit probe exempt
curl -i https://api.example.com/ready

# Production env dry-run
cd pranidoctor-backend && npm run validate:production-env
cd pranidoctor-web && npm run validate:production-env
```

---

See also [../security-guide.md](../security-guide.md) and [../monitoring-guide.md](../monitoring-guide.md).
