# Migration Safety Checklist

Use before every release with new `prisma/migrations/*` folders.

## Pre-migrate

- [ ] `npm run db:audit` — review high-risk table
- [ ] `npm run db:preflight` on target host (DATABASE_URL set)
- [ ] `postgres-backup.sh` completed; `gzip -t` on artifact
- [ ] Staging `migrate deploy` applied and smoke tests pass
- [ ] `ALLOW_PRODUCTION_MIGRATE=true` only on production host

## Automated rules (CI)

| Rule ID | Severity | Pattern |
|---------|----------|---------|
| DROP_TABLE | P0 | DROP TABLE |
| DROP_COLUMN | P1 | DROP COLUMN |
| DELETE_ROWS | P1 | DELETE FROM |
| ALTER_TYPE | P1 | ALTER COLUMN TYPE |
| SET_NOT_NULL | P2 | SET NOT NULL |

## Post-migrate

- [ ] `npx prisma migrate status` — up to date
- [ ] `GET /ready` OK
- [ ] Optional: `npm run db:validate` with seed checks

## Forbidden on shared environments

- `npm run db:push`
- `prisma migrate reset` on staging/production
- Editing applied migration SQL in place
