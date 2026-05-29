# Launch Day Runbook — Prani Doctor

**Version:** 1.0  
**Target launch type:** Closed Android beta + staging admin/doctor (pilot geography)  
**Official status at verification:** **NOT_READY_FOR_PRODUCTION** (public) — execute this runbook after closing blockers BL-01–BL-08 in [PRODUCTION_READINESS_REPORT.md](./PRODUCTION_READINESS_REPORT.md)  
**Launch window:** T-0 = traffic enabled to staging/production hosts

---

## Roles

| Role | Responsibility | Primary contact |
|------|----------------|-----------------|
| **Launch lead** | Go/no-go decisions, timeline | _Fill before launch_ |
| **DevOps** | Deploy, TLS, backups, rollback | _Fill before launch_ |
| **Backend on-call** | API health, migrations, Redis | _Fill before launch_ |
| **Web on-call** | Admin BFF, doctor panel | _Fill before launch_ |
| **Mobile on-call** | Play upload, crash reports | _Fill before launch_ |
| **QA** | Smoke matrix execution | _Fill before launch_ |
| **Product** | Scope, comms, pilot users | _Fill before launch_ |

---

## T-7 days (prep week)

| # | Task | Owner | Done |
|---|------|-------|------|
| 1 | Provision staging VPS + TLS (api + admin hostnames) | DevOps | ☐ |
| 2 | Copy `.env.staging.example` → `.env` on API and web hosts | DevOps | ☐ |
| 3 | Set `OTP_MODE=live`, rotate all JWT secrets from placeholders | DevOps | ☐ |
| 4 | `ALLOW_PRODUCTION_MIGRATE=true npm run db:migrate:deploy` on staging DB | Backend | ☐ |
| 5 | Install backup cron + manual backup test | DevOps | ☐ |
| 6 | Configure `DEPLOY_*` GitHub secrets | DevOps | ☐ |
| 7 | Run deploy-staging workflow with `deploy_remote=true` | DevOps | ☐ |
| 8 | Configure Sentry DSN or error webhook on API + web + mobile build | All | ☐ |
| 9 | Point mobile internal build to staging `API_BASE_URL` (HTTPS) | Mobile | ☐ |
| 10 | Upload AAB to Play **Internal testing** track | Mobile | ☐ |
| 11 | Set `PRIVACY_POLICY_URL` to live `https://admin.<host>/privacy` | Mobile | ☐ |
| 12 | Seed pilot geography + 3–5 verified doctors in admin | Product | ☐ |

---

## T-24 hours

| # | Task | Owner | Done |
|---|------|-------|------|
| 1 | Freeze `main`/`staging` — only hotfix PRs | Launch lead | ☐ |
| 2 | Record current image tags as rollback targets | DevOps | ☐ |
| 3 | Run full test suite: backend `npm test`, web `npm test`, flutter `flutter test` | QA | ☐ |
| 4 | Run `npm run validate:production-env` on both hosts | DevOps | ☐ |
| 5 | Verify backup from last night exists on disk + offsite | DevOps | ☐ |
| 6 | Uptime monitor on `https://api.<host>/ready` and `https://admin.<host>/api/health/ready` | DevOps | ☐ |
| 7 | Send tester invite (20+ phones) for Play internal/closed | Product | ☐ |
| 8 | Brief doctor pilot users on web login URL | Product | ☐ |
| 9 | Confirm on-call rotation for launch week | Launch lead | ☐ |
| 10 | Print/share [ROLLBACK_PLAN.md](./ROLLBACK_PLAN.md) to war-room channel | Launch lead | ☐ |

---

## T-1 hour

| # | Task | Command / check | Expected |
|---|------|-----------------|----------|
| 1 | API liveness | `curl -fsS https://api.<host>/live` | 200 |
| 2 | API readiness | `curl -fsS https://api.<host>/ready` | 200 |
| 3 | Web readiness | `curl -fsS https://admin.<host>/api/health/ready` | 200 |
| 4 | Privacy page | `curl -fsS -o /dev/null -w '%{http_code}' https://admin.<host>/privacy` | 200 |
| 5 | Admin guard | `curl -fsS -o /dev/null -w '%{http_code}' https://admin.<host>/api/admin/analytics/overview` | 401 |
| 6 | Redis up | Check `/health/redis` or API logs | connected |
| 7 | OTP dev mode off | Confirm `OTP_MODE=live` in API `.env` | live |
| 8 | Trigger test error | Temporary route or `throw` in staging only | Sentry/webhook receives |
| 9 | Open `/admin/launch-ops` | All probes green in UI | green |
| 10 | Go/no-go meeting | Launch lead + DevOps + Product | GO or NO-GO |

---

## T-0 — Launch sequence

Execute in order. **Do not skip health gates.**

### Step 1 — Enable production/staging traffic (09:00 local suggested)

```bash
# nginx already routing — verify cert valid
sudo certbot certificates
sudo nginx -t && sudo systemctl reload nginx
```

### Step 2 — Post-deploy smoke (15 minutes)

| Step | Actor | Action |
|------|-------|--------|
| 2.1 | QA | Install app from Play internal link on 2 Android devices |
| 2.2 | QA | OTP login with real Bangladesh test numbers (3 numbers) |
| 2.3 | QA | Complete profile if prompted → reach home |
| 2.4 | QA | Create animal profile |
| 2.5 | QA | Submit service request in pilot area |
| 2.6 | Admin | Log in → assign doctor to request |
| 2.7 | Doctor | Log in on web → accept → complete with billing fields |
| 2.8 | QA | Confirm request status updated in mobile |
| 2.9 | QA | Upload animal photo (small JPEG) |
| 2.10 | QA | Toggle airplane mode → create feed entry offline → reconnect → sync |

### Step 3 — Monitoring watch (first 2 hours)

| Metric | Threshold | Action |
|--------|-----------|--------|
| API 5xx rate | > 1% for 5 min | Investigate; rollback if sustained |
| `/ready` | non-200 | Page DevOps; rollback if not recovered in 15 min |
| Crash webhook | > 5 fatals in 10 min | Pause Play rollout |
| OTP failures | > 10% of attempts | Check SMS provider + logs |
| Redis 503 spike | sustained | Fix Redis before continuing |

---

## T+1 hour — Communication

| Audience | Channel | Message |
|----------|---------|---------|
| Internal team | War-room | "Launch stable" or issue summary |
| Pilot doctors | WhatsApp group | Support number + login URL |
| Test farmers | Play tester email | How to report bugs (in-app support) |
| Leadership | Email | KPI snapshot: installs, OTP success, requests created |

---

## T+24 hours

| # | Task | Owner |
|---|------|-------|
| 1 | Review Sentry/webhook error volume | Backend + Mobile |
| 2 | Review admin analytics overview (registrations, requests) | Product |
| 3 | Check backup job log `/var/log/pranidoctor-backup.log` | DevOps |
| 4 | Triage support tickets | Product |
| 5 | Document any waivers from [KNOWN_LIMITATIONS.md](./KNOWN_LIMITATIONS.md) | Launch lead |

---

## T+7 days — Stabilization review

| # | Task |
|---|------|
| 1 | Re-run [GO_LIVE_CHECKLIST.md](./GO_LIVE_CHECKLIST.md) — target all A/B items ✅ or waived |
| 2 | Update [PRODUCTION_READINESS_REPORT.md](./PRODUCTION_READINESS_REPORT.md) status |
| 3 | Decide: promote to closed testing → open testing → production |
| 4 | Schedule post-mortem if any SEV-1/SEV-2 occurred |

---

## Emergency contacts

| Situation | Action |
|-----------|--------|
| SEV-1 outage | Follow [incident-response-guide.md](../incident-response-guide.md) |
| Rollback needed | Execute [ROLLBACK_PLAN.md](./ROLLBACK_PLAN.md) §3–4 |
| Auth compromise | Rotate JWT secrets; flush Redis; force re-login |
| Data issue | Stop API writes; contact DevOps + DBA path in rollback §5 |

**War-room channel:** _Slack/WhatsApp link — fill before launch_  
**Status page:** _None — post manual updates until Statuspage configured_

---

## Go / No-Go criteria (launch day)

### GO (closed beta minimum)

- All T-1 hour checks pass  
- Smoke steps 2.1–2.8 pass on 2 devices  
- On-call named and reachable  
- Rollback tag documented  

### NO-GO

- `/ready` failing  
- OTP live SMS failing on 2+ carriers  
- Admin cannot assign doctor  
- Unauthenticated admin API returns 200 (regression)  

---

## Post-launch status upgrade path

| Current | After 7-day stable beta | After payment SOP + public DNS + push decision |
|---------|-------------------------|-----------------------------------------------|
| **NOT_READY_FOR_PRODUCTION** | **READY_WITH_MINOR_RISKS** (closed beta) | **READY_FOR_PRODUCTION** (public track) |

---

*This runbook assumes Bangladesh pilot (Android-only, manual payments, single geography). Adjust steps for expanded scope.*
