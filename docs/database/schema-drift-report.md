# Schema Drift Report

**Generated:** 2026-06-01  
**Tool:** `pranidoctor-backend` → `npm run db:validate` / `db:snapshot` / `db:compare-schema`

---

## Status (baseline run)

No live multi-environment comparison was executed in the baseline audit (no `DATABASE_URL_STAGING` / `DATABASE_URL_PRODUCTION` in CI secrets).

**To detect drift:**

```bash
cd pranidoctor-backend

# Per environment (read-only snapshot):
DATABASE_URL="postgresql://..." npm run db:snapshot -- --label staging
DATABASE_URL="postgresql://..." npm run db:snapshot -- --label production

# Compare JSON files:
npm run db:compare-schema -- \
  --expected reports/db/schema-staging.json \
  --actual reports/db/schema-production.json
```

Or set all URLs in one run:

```bash
DATABASE_URL_LOCAL=... \
DATABASE_URL_STAGING=... \
DATABASE_URL_PRODUCTION=... \
npm run db:validate
```

## What is compared

| Dimension | Source |
|-----------|--------|
| Tables | `information_schema.tables` |
| Columns + types + nullability | `information_schema.columns` |
| Indexes | `pg_indexes` |
| Constraints | `information_schema.table_constraints` |
| Enums | `pg_enum` |
| Failed migrations | `_prisma_migrations` |

## CI coverage

The `db-validate` job applies **`prisma migrate deploy`** on empty PostgreSQL 16 — confirms chain applies cleanly (schema matches migrations + `schema.prisma`).

## Expected drift scenarios

| Scenario | Detection |
|----------|-----------|
| Staging not migrated | Pending migrations in `migrate status` |
| `db:push` on dev | Prisma drift line in preflight |
| Web client stale | `sync-prisma-from-backend.ps1` not run |
| Manual DDL on prod | Snapshot compare vs staging |

---

*Regenerate after each release: `npm run db:validate` with environment URLs set.*
