# Backup & Recovery — Prani Doctor

**Version:** 1.0 · Phase 6

## 3-2-1 rule

- **3** copies of data  
- **2** storage types  
- **1** offsite copy  

## Database backup

Scripts: `pranidoctor-backend/scripts/backup/`

```bash
export DATABASE_URL="postgresql://..."
./scripts/backup/postgres-backup.sh /var/backups/pranidoctor
```

Schedule daily via cron (02:00 UTC example):

```cron
0 2 * * * DATABASE_URL=... /app/scripts/backup/postgres-backup.sh /var/backups/postgres
```

Retention: `BACKUP_KEEP_COUNT=14` (default).

## Restore procedure

1. Stop API workers to prevent writes.  
2. Restore to a **new** database first (staging validation):

```bash
createdb pranidoctor_restore_test
export DATABASE_URL=postgresql://.../pranidoctor_restore_test
./scripts/backup/postgres-restore.sh /var/backups/postgres/pranidoctor_YYYYMMDD.sql.gz
```

3. Run smoke tests (`GET /health`, login OTP flow).  
4. Point production `DATABASE_URL` or rename DB per runbook.

## MinIO / S3 media

- Enable bucket versioning on production bucket.  
- Mirror to offsite S3 with `mc mirror` or provider replication.  
- Document bucket name in `.env.production.example`.

## Configuration backup

- Store encrypted `.env` exports in secret manager (not git).  
- Export nginx/Caddy configs from `/etc` weekly.

## Disaster recovery

| Metric | Target |
|--------|--------|
| RPO | 24 hours (daily DB backup) |
| RTO | 4 hours (manual restore + redeploy) |

### DR steps

1. Provision standby VPS from IaC/template.  
2. Restore latest Postgres backup.  
3. Restore MinIO bucket from mirror.  
4. Deploy API + web containers from last known good image tags.  
5. Update DNS to standby if primary region lost.

## Testing

Quarterly: restore backup to staging and verify mobile login + admin panel.
