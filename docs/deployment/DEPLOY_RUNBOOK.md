# Deployment Runbook — Phase 7

**Applies to:** `pranidoctor-backend`, `pranidoctor-web`, `pranidoctor_user`

---

## 1. Staging stand-up

### 1.1 VPS prerequisites

- Ubuntu 22.04+ with Docker and Docker Compose
- DNS: `api.staging.example.com`, `admin.staging.example.com`
- Firewall: 80, 443 open

### 1.2 Backend

```bash
git clone <backend-repo> /app/pranidoctor-backend
cd /app/pranidoctor-backend
cp .env.staging.example .env
# Edit secrets — OTP_MODE=live, JWT secrets, DATABASE_URL, REDIS_URL
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
ALLOW_PRODUCTION_MIGRATE=true npm run db:migrate:deploy
curl -fsS http://127.0.0.1:3000/ready
```

### 1.3 TLS (nginx)

```bash
sudo cp deploy/nginx/pranidoctor.conf.example /etc/nginx/sites-available/pranidoctor
# Edit hostnames and cert paths
sudo certbot --nginx -d api.staging.example.com -d admin.staging.example.com
sudo nginx -t && sudo systemctl reload nginx
```

### 1.4 Web admin

```bash
cd /app/pranidoctor-web
cp .env.staging.example .env
# BACKEND_URL=https://api.staging.example.com
npm run validate:production-env
docker compose -f docker-compose.prod.yml up -d
curl -fsS http://127.0.0.1:3001/api/health/ready
```

### 1.5 Backups

```bash
sudo ./scripts/backup/install-backup-cron.sh /app/pranidoctor-backend /var/backups/pranidoctor
./scripts/backup/postgres-backup.sh /var/backups/pranidoctor  # manual test
```

---

## 2. CI/CD deploy

### GitHub secrets (both repos)

| Secret | Purpose |
|--------|---------|
| `DEPLOY_HOST` | VPS IP/hostname |
| `DEPLOY_USER` | SSH user |
| `DEPLOY_SSH_KEY` | Private key |
| `DEPLOY_PATH` | App directory on VPS |

### Trigger

1. **Staging:** Actions → Deploy Staging → `deploy_remote=true`
2. **Production:** Actions → Deploy Production → set tag + `deploy_remote=true`

Health gate: workflow polls `http://127.0.0.1:3000/ready` on the VPS.

---

## 3. Mobile release

```powershell
cd pranidoctor_user
.\scripts\build_release.ps1 `
  -ApiBaseUrl "https://api.staging.example.com" `
  -AppEnv staging `
  -AppBundle `
  -PrivacyPolicyUrl "https://admin.staging.example.com/privacy" `
  -CrashWebhookUrl "https://your-sentry-or-webhook"
```

Upload `build/app/outputs/bundle/release/app-release.aab` to Play **Internal testing**.

---

## 4. Rollback

```bash
cd /app/pranidoctor-backend
docker compose pull api  # previous tag
docker compose up -d api
```

Database: forward-only migrations — restore from backup if schema corruption.

---

## 5. Smoke test (launch gate)

1. OTP login on staging mobile build
2. Create animal → service request
3. Doctor web accept → complete
4. Admin analytics overview loads
5. `/privacy` returns 200

See [../launch/PHASE_7_IMPLEMENTATION_REPORT.md](../launch/PHASE_7_IMPLEMENTATION_REPORT.md).
