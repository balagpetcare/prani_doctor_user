# Rollback Procedures

**Prisma migrations are forward-only.** Production rollback is **application image revert** or **database restore from backup** — not `migrate down`.

## Quick decision matrix

| Symptom | Action |
|---------|--------|
| 5xx after deploy, schema unchanged | Redeploy previous API image |
| migrate deploy failed | Stop traffic; fix forward or restore backup |
| Data corruption | Stop writes; restore from pre-migrate backup |

## Non-reversible migrations in chain

Count: **4** (DROP COLUMN, DELETE, DROP TABLE, type changes)

- `20260508195220_prani_doctor_mvp_schema`
- `20260509120000_knowledge_hub_content`
- `20260509120000_service_request_booking_enums_fields`
- `20260523220000_phase6_weight_hardening`

## Backup scripts

- Backup: `scripts/backup/postgres-backup.sh` — exists: true
- Restore: `scripts/backup/postgres-restore.sh` — exists: true

## Restore validation (no production writes)

1. Restore to `pranidoctor_restore_test` database
2. Run `npm run db:snapshot -- --label restore-test`
3. Compare row counts vs production metrics
4. Smoke OTP + SR list

See `pranidoctor_user/docs/launch/ROLLBACK_PLAN.md` for full ops steps.

**Report generated:** 2026-05-29T22:30:13.697Z