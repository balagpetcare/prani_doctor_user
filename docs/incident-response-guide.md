# Incident Response Guide — Prani Doctor

**Version:** 1.0 · Phase 6

## Severity levels

| Level | Example | Response time |
|-------|---------|---------------|
| SEV-1 | API down, data breach suspected | Immediate |
| SEV-2 | Auth broken, elevated 5xx | < 1 hour |
| SEV-3 | Degraded feature, single tenant | < 1 day |

## SEV-1 playbook

1. **Acknowledge** — assign incident lead, open war room channel.  
2. **Contain** — block abusive IPs at nginx; rotate `MOBILE_JWT_SECRET` if token leak suspected.  
3. **Assess** — check `/health`, logs, recent deploys.  
4. **Recover** — rollback container image tag; restore DB only if corruption confirmed (see `backup-recovery.md`).  
5. **Communicate** — status to stakeholders; user-facing message if outage > 15 min.  
6. **Post-mortem** — within 72 hours, blameless write-up.

## Auth compromise

1. Revoke all refresh tokens: run admin script / flush Redis session keys.  
2. Rotate JWT secrets and `REFRESH_TOKEN_PEPPER`.  
3. Force mobile re-login (increment `MINIMUM_APP_VERSION` if needed).

## Rollback

```bash
# Backend
docker compose -f docker-compose.yml -f docker-compose.prod.yml pull api:previous
docker compose up -d api
```

Database migrations are forward-only — do not rollback schema without restore.

## Contacts

Document on-call rotation in your team wiki (not in git).
