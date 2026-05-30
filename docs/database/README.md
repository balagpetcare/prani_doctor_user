# Database Compliance & Migration Validation

**Owner:** `pranidoctor-backend` (canonical schema)  
**Plan:** [database-migration-validation-plan.md](../launch/database-migration-validation-plan.md)

## Reports (regenerated)

| Report | Command |
|--------|---------|
| [migration-audit-report.md](./migration-audit-report.md) | `npm run db:audit` |
| [schema-drift-report.md](./schema-drift-report.md) | `npm run db:validate` with env URLs |
| [rollback-procedures.md](./rollback-procedures.md) | `npm run db:audit` |
| [migration-safety-checklist.md](./migration-safety-checklist.md) | Static + audit |

Machine-readable: `pranidoctor-backend/reports/db/*.json` (gitignored — regenerate locally).

## Commands

```bash
cd pranidoctor-backend
npm run db:audit          # inventory + safety (no DB)
npm run db:preflight      # pre-deploy (DATABASE_URL required)
npm run db:validate       # audit + optional seed/drift checks
npm run db:migrate:deploy # production (after backup + ALLOW_PRODUCTION_MIGRATE=true)
```
