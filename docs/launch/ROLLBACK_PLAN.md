# Rollback Plan — Prani Doctor

**Version:** 1.0  
**Effective date:** 2026-05-29  
**Applies to:** API (Express), Admin Web (Next.js), Mobile (Android), PostgreSQL  
**Incident severity trigger:** SEV-1 or SEV-2 per [incident-response-guide.md](../incident-response-guide.md)

---

## 1. Rollback principles

1. **Application rollback is fast** — redeploy previous container image tag.  
2. **Database rollback is slow** — migrations are **forward-only**; do not `migrate reset` on production.  
3. **Restore database only** when corruption or bad migration confirmed — not for ordinary app bugs.  
4. **Mobile rollback** — use Play staged rollout pause + prior AAB if available.  
5. **Document every rollback** — incident lead logs actions in war-room channel.

---

## 2. Decision matrix

| Symptom | First action | DB restore? |
|---------|--------------|-------------|
| 5xx spike after deploy | Roll back API/web image | No |
| Auth broken for all users | Roll back API; check Redis + JWT secrets | No |
| Bad migration partially applied | Stop traffic; assess migration state | Maybe — see §5 |
| Data corruption confirmed | Stop writes; restore from backup | **Yes** |
| Mobile crash spike > 2% | Pause Play rollout; ship hotfix or prior AAB | No |
| Redis down | Fix Redis; API returns 503 on rate limit (expected) | No |
| Admin only broken | Roll back web image only | No |

---

## 3. API (Express) rollback

### 3.1 Prerequisites

- Previous image tag recorded before deploy (e.g. `ghcr.io/org/pranidoctor-backend:staging-previous`).  
- SSH access to VPS.  
- `.env` unchanged between versions (or documented delta).

### 3.2 Steps

```bash
# 1. Announce maintenance / degraded mode (if user-facing)
# 2. On VPS
cd /app/pranidoctor-backend

# 3. Pin previous image (replace TAG)
export API_IMAGE=ghcr.io/<org>/pranidoctor-backend:<PREVIOUS_TAG>

# 4. Pull and restart
docker compose -f docker-compose.yml -f docker-compose.prod.yml pull api
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d api

# 5. Health gate
for i in $(seq 1 30); do
  curl -fsS http://127.0.0.1:3000/ready && break
  sleep 2
done

# 6. Smoke
curl -fsS http://127.0.0.1:3000/health
curl -fsS -X POST http://127.0.0.1:3000/api/mobile/auth/otp/request \
  -H 'Content-Type: application/json' \
  -d '{"phone":"+8801XXXXXXXXX"}'  # expect structured response, not 5xx
```

### 3.3 Time estimate

**5–15 minutes** if image tag known.

### 3.4 GitHub Actions rollback

Re-run **Deploy Staging** or **Deploy Production** workflow with previous `image_tag` input and `deploy_remote=true`.

---

## 4. Admin web (Next.js) rollback

```bash
cd /app/pranidoctor-web
docker compose -f docker-compose.prod.yml pull web
docker compose -f docker-compose.prod.yml up -d web

curl -fsS http://127.0.0.1:3001/api/health/ready
curl -fsS http://127.0.0.1:3001/api/health/live
```

**Note:** Web BFF rollback does **not** require DB migration rollback if schema unchanged.

**Time estimate:** 5–10 minutes.

---

## 5. Database rollback (last resort)

### 5.1 When to use

- Confirmed migration data loss  
- Accidental destructive SQL  
- Unrecoverable schema inconsistency  

### 5.2 When NOT to use

- Application logic bug  
- UI regression  
- Rate limit 503 spikes  

### 5.3 Procedure

```bash
# 1. STOP WRITES — scale API to 0 or maintenance mode at nginx
docker compose -f docker-compose.yml -f docker-compose.prod.yml stop api

# 2. Identify backup file
ls -lt /var/backups/pranidoctor/

# 3. Restore to NEW database first (validation)
createdb pranidoctor_restore_test
export DATABASE_URL=postgresql://USER:PASS@localhost:5432/pranidoctor_restore_test
./scripts/backup/postgres-restore.sh /var/backups/pranidoctor/pranidoctor_YYYYMMDD.sql.gz

# 4. Smoke on restore DB
DATABASE_URL=.../pranidoctor_restore_test npm run validate:startup  # if available
psql $DATABASE_URL -c "SELECT COUNT(*) FROM \"User\";"

# 5. If valid — maintenance window to swap (coordinate with leadership)
# Option A: Rename databases (requires connection drain)
# Option B: Point DATABASE_URL to restored DB and restart API

# 6. Restart API
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d api
```

### 5.4 Data loss window

Restoring backup **loses all writes since backup timestamp**. Communicate to stakeholders before executing.

**RPO:** Daily backup at 02:00 UTC → up to **24 hours** data loss unless incremental backups added.  
**RTO target:** 2–4 hours including validation.

---

## 6. Mobile (Android) rollback

### 6.1 Play Console staged rollout

1. Open Play Console → Release → Production/Closed testing.  
2. **Halt rollout** immediately if crash rate > 2%.  
3. Promote previous release from release library OR upload prior AAB from secure archive.  
4. If forced upgrade deployed via `MINIMUM_APP_VERSION`, revert server config before shipping old APK.

### 6.2 Sideload / internal testers

Distribute previous `internal-release.apk` from secure artifact store (`release/internal-release.apk` archive).

### 6.3 Time estimate

**15 minutes – 24 hours** (Play propagation delay for production track).

---

## 7. Configuration rollback

| Change type | Rollback method |
|-------------|-----------------|
| Bad `.env` value | Restore encrypted `.env` backup from secret store |
| JWT secret rotation gone wrong | Restore previous secrets; flush Redis sessions; force re-login |
| `OTP_MODE` mis-set | Set `OTP_MODE=live`; restart API |
| nginx mis-config | `sudo nginx -t`; restore previous `/etc/nginx/sites-available/pranidoctor` |

**JWT compromise rollback** (from incident guide):

1. Rotate `MOBILE_JWT_SECRET`, `ADMIN_JWT_SECRET`, `DOCTOR_JWT_SECRET`, `REFRESH_TOKEN_PEPPER`.  
2. Flush Redis session keys.  
3. Increment `MINIMUM_APP_VERSION` if needed to force mobile re-auth.

---

## 8. Redis / MinIO rollback

| Service | Rollback |
|---------|----------|
| Redis | Restart container; sessions cleared → users re-login (acceptable) |
| MinIO | Restore bucket from mirror; do not delete bucket on rollback |

---

## 9. Communication templates

### User-facing (Bengali + English short)

> Prani Doctor সাময়িকভাবে maintenance এ আছে। কিছুক্ষণ পর আবার চেষ্টা করুন।  
> Prani Doctor is temporarily under maintenance. Please try again shortly.

### Internal (Slack/WhatsApp)

> ROLLBACK IN PROGRESS — API tag `<PREVIOUS_TAG>` — lead: `<NAME>` — ETA 15 min — thread for updates.

---

## 10. Post-rollback requirements

Within **72 hours**:

1. Blameless post-mortem (template in incident guide).  
2. Root cause + preventive action item.  
3. Update [KNOWN_LIMITATIONS.md](./KNOWN_LIMITATIONS.md) if new risk discovered.  
4. Re-run smoke checklist before re-attempting deploy.

---

## 11. Rollback verification checklist

- [ ] `/ready` returns 200 on API  
- [ ] `/api/health/ready` returns 200 on web  
- [ ] OTP request returns non-5xx  
- [ ] Admin login succeeds  
- [ ] Doctor login succeeds  
- [ ] Error rate below 1% for 15 minutes  
- [ ] Stakeholders notified of stable state  

---

*Related: [LAUNCH_DAY_RUNBOOK.md](./LAUNCH_DAY_RUNBOOK.md) · [../backup-recovery.md](../backup-recovery.md)*
