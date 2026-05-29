# Phase 7 — Implementation Report

**Date:** 2026-05-29  
**Plan:** [PHASE_7_LAUNCH_PREP_PLAN.md](./PHASE_7_LAUNCH_PREP_PLAN.md)  
**Status:** Engineering implementation complete — **ops validation still required on real hosts**

---

## Summary

Phase 7 code and configuration changes address **P0/P1 engineering blockers** from the launch audit. Operational items (VPS provisioning, TLS certificates, Play Console upload, on-call roster) remain **host-specific** and are documented in [../deployment/DEPLOY_RUNBOOK.md](../deployment/DEPLOY_RUNBOOK.md).

| Area | Implemented | Remaining (ops) |
|------|-------------|-----------------|
| Backend security & rate limits | Yes | WAF, virus scan |
| Backend monitoring | Sentry + webhook + metrics | Prometheus scrape on VPS |
| Backend deploy CI | GHCR push + optional SSH | Configure DEPLOY_* secrets |
| Backend backups | Cron installer script | Run on VPS + restore drill |
| Web admin BFF guard | Yes | Pen-test sample routes |
| Web legal pages | `/privacy`, `/terms`, `/refund` | DNS to admin host |
| Flutter crash reporting | Webhook reporter | Sentry DSN optional |
| Flutter release guards | keystore + HTTPS checks | Play listing assets |

---

## Backend (`pranidoctor-backend`)

| Item | Change |
|------|--------|
| P1-01 Rate limits | `rateLimitAiChat` on AI/voice chat; `rateLimitSearch` on area search; `rateLimitExport` on CSV reports |
| P1-03 Prisma guard | `scripts/prisma-production-guard.mjs` wired to `db:migrate:deploy` |
| P0-04 Telemetry | Optional `@sentry/node` via `SENTRY_DSN`; webhook retained |
| Health probes | `/health`, `/ready`, `/live` mounted **before** global rate limit; probe exemption middleware |
| Deploy | Real GHCR build/push; SSH deploy with `/ready` gate (`deploy_remote` input) |
| CI security | `security-scan.yml` — CodeQL + gitleaks |
| Env validation | `npm run validate:production-env` |
| Infra | nginx example (TLS redirect, probe bypass); Prometheus alert rules; backup cron installer |

---

## Admin Web (`pranidoctor-web`)

| Item | Change |
|------|--------|
| P0-10 / P1-02 BFF guard | `proxyRouteToBackend` calls `requireAdminPanelApiAccess` for `/api/admin/*` (auth + health exempt) |
| P0-08 Legal | Public pages: `/privacy`, `/terms`, `/refund`, `/legal/disclaimer` |
| Health | `/api/health/live`, `/api/health/ready` |
| Monitoring | `@sentry/nextjs` optional via `SENTRY_DSN`; instrumentation boot |
| Ops UI | `/admin/launch-ops` — live probe dashboard |
| CI | `security-scan.yml` |

---

## Flutter (`pranidoctor_user`)

| Item | Change |
|------|--------|
| P0-04 Crash reporting | `WebhookCrashReporter` + `CRASH_REPORTING_WEBHOOK_URL` dart-define |
| P0-09 Release script | `build_release.ps1` — keystore guard, HTTPS, auto `ENABLE_PUSH=false` without Firebase |
| Production validation | `assertProductionReady()` — HTTPS privacy URL; `assertPushReady()` after Firebase init |
| Bootstrap | Wires crash reporter into `GlobalErrorHandler.runGuarded` |

---

## Updated readiness estimate

| Metric | Before | After (engineering) |
|--------|--------|------------------------|
| Composite score | 66% | **~82%** (ops not exercised) |
| Public production | NOT READY | **Conditional** — after VPS + secrets + drill |
| Closed Android beta | Conditional | **Ready for internal track** with staging API |

---

## Verification checklist

- [ ] `npm run validate:production-env` in backend and web
- [ ] `curl https://admin.*/ready` and `curl https://api.*/ready`
- [ ] Unauthenticated `GET /api/admin/analytics/overview` → 401 from web BFF
- [ ] `GET https://admin.*/privacy` → 200
- [ ] Trigger test 500 → Sentry/webhook receives event
- [ ] `ALLOW_PRODUCTION_MIGRATE=true npm run db:migrate:deploy` on staging clone
- [ ] `./scripts/backup/install-backup-cron.sh` on VPS
- [ ] Flutter release AAB with `key.properties` + `CRASH_REPORTING_WEBHOOK_URL`

---

*Next: execute [DEPLOY_RUNBOOK.md](../deployment/DEPLOY_RUNBOOK.md) on staging VPS and update go/no-go in launch plan.*
