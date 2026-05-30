# Database Migration Validation — Verification Report

**Report ID:** `DB_MIGRATION_VERIFICATION_2026-06-01`  
**Date:** 2026-06-01  
**Mode:** Verification only — no new functionality  
**Auditor:** Principal Database Auditor / Production Readiness Reviewer  
**Plan:** [database-migration-validation-plan.md](./database-migration-validation-plan.md)  
**Implementation:** [database-migration-implementation-report.md](./database-migration-implementation-report.md)

**Methodology:** Ran `npm run db:audit`, `npx prisma validate`, `npx vitest run scripts/db/migration-safety.test.mjs`, `npx prisma migrate status`, `npx prisma migrate deploy` (local disposable DB), filesystem audit of `prisma/migrations/`, review of CI/deploy workflows and generated docs. No staging/production hosts exercised.

---

## Executive Summary

The **validation framework** (audit scripts, preflight, CI job, deploy hooks, documentation) is **implemented and partially effective**. The **migration chain itself is not deploy-ready** because one folder in the history is **broken**.

| Area | Result |
|------|--------|
| 1. Migration inventory | **FAIL** — orphan folder without `migration.sql` |
| 2. Schema integrity | **PASS WITH WARNINGS** — Prisma schema valid; local DB behind repo |
| 3. Drift detection | **FAIL** — no multi-env snapshots; local pending migrations |
| 4. Backup validation | **PASS WITH WARNINGS** — scripts exist; no gzip/restore drill |
| 5. Rollback validation | **PASS WITH WARNINGS** — documented; 4 non-reversible migrations |
| 6. Seed validation | **NOT RUN** (blocked by failed migrate deploy mid-chain) |
| 7. Application compatibility | **PASS WITH WARNINGS** — static + 328/331 unit tests; unrelated logger failures |
| 8. Launch scores | See §Production Readiness Score |

### Final verdict

| Scope | Verdict |
|-------|---------|
| **Validation framework (tooling)** | **PASS WITH WARNINGS** |
| **Migration deploy readiness (chain)** | **FAIL** |
| **Overall production migration readiness** | **FAIL** |

**Blocker:** `prisma migrate deploy` fails with **P3015** on `20260530180000_user_consent_registry` (missing `migration.sql`). CI `db-validate` job would fail at the same step unless the folder is absent on CI branch (verified present on disk).

---

## Migration Inventory Results

### Automated audit (`npm run db:audit`)

| Check | Expected | Actual | Result |
|-------|----------|--------|--------|
| Folder count | All have `migration.sql` | **59 folders, 1 missing SQL** | **FAIL** |
| Ordering | Lexicographic sort | Sorted | **PASS** |
| Duplicate migrations (same folder) | None | None | **PASS** |
| Duplicate timestamps | Informational | 5 groups (10 folders) | **PASS** (valid for Prisma) |
| High-risk count | Documented | 4 (P1) | **PASS** |
| Non-reversible count | Documented | 4 | **PASS** |
| `prisma validate` | Pass | Pass | **PASS** |

### Duplicate timestamp groups (not failures)

| Timestamp | Folders |
|-----------|---------|
| `20260509120000` | knowledge_hub_content, service_request_booking_enums_fields |
| `20260523120000` | animal_photo_upload_purpose, phase1_fattening_batches |
| `20260529120000` | notification_user_created_index, phase4_livestock_feed_ecosystem |
| `20260530180000` | legal_consent, **user_consent_registry** |
| `20260601120000` | ai_governance_scopes, phase8_ai_ecosystem |

### Failed inventory item

| Folder | Issue |
|--------|-------|
| `20260530180000_user_consent_registry` | Directory exists; **`migration.sql` missing** — empty folder |

**Effective deployable migrations:** **58** (not 59).

### Local `prisma migrate status` (evidence)

```
59 migrations found in prisma/migrations
Following migrations have not yet been applied:
  ... (9 pending including user_consent_registry)
```

### Local `prisma migrate deploy` (evidence)

```
Applying migration `20260530180000_legal_consent`
Error: P3015 — Could not find the migration file at migration.sql.
Please delete the directory or restore the migration file.
```

---

## Schema Validation Results

| Check | Method | Result |
|-------|--------|--------|
| Prisma schema syntax | `npx prisma validate` | **PASS** (~100 models) |
| Migration SQL parse | Safety rules on file content | **PASS** for 58 files with SQL |
| Tables/columns/FK/indexes/enums on DB | `schema-introspect.mjs` | **NOT RUN** (deploy blocked) |
| CI empty-DB apply | `db-validate` workflow design | **Would FAIL** at P3015 (same chain) |

**Schema integrity (repository):** **PASS WITH WARNINGS** — schema file valid; chain incomplete on disk.

**Schema integrity (local DB):** **WARN** — 9 migrations pending before failure; DB not aligned with repo head after partial apply.

---

## Drift Analysis Results

| Environment pair | Executed | Drift detected | Result |
|------------------|----------|----------------|--------|
| Local vs Development | No | — | **NOT RUN** |
| Development vs Staging | No | — | **NOT RUN** |
| Staging vs Production | No | — | **NOT RUN** |
| Repo vs local DB | `migrate status` | 9 pending migrations | **WARN** |

**Tooling:** `db:snapshot`, `db:compare-schema`, multi-URL `db:validate` — **implemented**, not executed in this verification (no `DATABASE_URL_*` set).

**CI substitute:** Postgres 16 service + full `migrate deploy` in `db-validate` — **correct design**, currently **blocked by P3015**.

**Drift risk score:** **62 / 100** — high until deploy succeeds on clean DB and staging/prod snapshots compared.

---

## Backup Validation Results

| Check | Result |
|-------|--------|
| `postgres-backup.sh` exists | **PASS** |
| `postgres-restore.sh` exists | **PASS** |
| Documented in `DEPLOY_RUNBOOK.md` / `ROLLBACK_PLAN.md` | **PASS** |
| Production deploy: backup before migrate | **PASS** (fail-closed, no `\|\| true`) |
| Staging deploy: backup before migrate | **PASS WITH WARNINGS** (`\|\| true` still) |
| `BACKUP_VERIFY_DIR` gzip integrity | **NOT RUN** |
| Restore drill logged | **FAIL** (no evidence in repo) |
| `pg_dump` on auditor machine | **NOT AVAILABLE** (warning in audit) |

**Backup readiness score:** **68 / 100**

---

## Rollback Validation Results

| Check | Result |
|-------|--------|
| Forward-only policy documented | **PASS** |
| App image rollback documented | **PASS** |
| DB restore procedure documented | **PASS** |
| `rollback-procedures.md` generated | **PASS** |
| Emergency matrix in `ROLLBACK_PLAN.md` | **PASS** |
| `db:preflight` script | **PASS** (cannot complete on broken chain mid-deploy) |

### Non-reversible migrations (confirmed by safety scan)

| Migration | Risk |
|-----------|------|
| `20260508195220_prani_doctor_mvp_schema` | DROP COLUMN |
| `20260509120000_knowledge_hub_content` | DROP COLUMN, constraint/index changes |
| `20260509120000_service_request_booking_enums_fields` | ALTER TYPE |
| `20260523220000_phase6_weight_hardening` | DELETE FROM + SET NOT NULL |

**Rollback readiness score:** **74 / 100** — procedures exist; restore not drilled.

---

## Seed Validation Results

| Data | Validator | Result |
|------|-----------|--------|
| Roles (6) | `seed-validate.mjs` | **NOT RUN** — deploy stopped at P3015 |
| Settings keys (legal, AI disclaimer) | Same | **NOT RUN** |
| LegalDocument | Same | **NOT RUN** |
| Feed / semen masters (optional) | Same | **NOT RUN** |

**Note:** `npm run db:validate` (non–audit-only) would run seed checks when `DATABASE_URL` is set and migrations are fully applied.

**Seed validation:** **INCONCLUSIVE** in this pass — treat as **WARN** until migrate deploy succeeds.

---

## Application Compatibility Validation

| Check | Method | Result |
|-------|--------|--------|
| Backend build/typecheck | Not re-run full build | **WARN** |
| Unit tests | `npm test` | **328 passed / 3 failed / 5 files failed** |
| Migration safety tests | 3/3 pass | **PASS** |
| Failed tests | Logger/workflow in AI usage verify tests | **Unrelated to migrations** |
| API modules (auth, SR, AI, treatment) | Static — schema models present | **PASS** |
| Startup validation script | `validate:startup` exists | **NOT RUN** |
| Live API smoke | Not run | **NOT RUN** |

**No migration-related test regressions identified.** Application compatibility: **PASS WITH WARNINGS** (test suite not fully green).

---

## Risks

### P0 — Critical

| ID | Risk |
|----|------|
| R-P0-01 | **P3015** — empty `20260530180000_user_consent_registry` blocks **all** full-chain deploys |
| R-P0-02 | CI `db-validate` **migrate deploy** step fails until folder fixed |
| R-P0-03 | Audit tool **does not fail** on missing `migration.sql` (counts folder, empty safety scan) |

### P1 — High

| ID | Risk |
|----|------|
| R-P1-01 | No multi-environment schema snapshot comparison executed |
| R-P1-02 | Local/staging DBs may be **9 migrations behind** repo head |
| R-P1-03 | Restore drill not performed |

### P2 — Medium

| ID | Risk |
|----|------|
| R-P1-04 | Staging backup still fail-open (`\|\| true`) |
| R-P1-05 | `db:push` remains available in package.json |

---

## Findings

### Passed

- **PC-01** — 58 migrations with valid `migration.sql` inventoried  
- **PC-02** — Lexicographic ordering correct  
- **PC-03** — No duplicate folder names  
- **PC-04** — Safety unit tests 3/3 pass  
- **PC-05** — `prisma validate` passes  
- **PC-06** — Backup/restore scripts present  
- **PC-07** — Production deploy workflow: backup + migrate + health  
- **PC-08** — Staging deploy workflow now includes migrate  
- **PC-09** — Docs in `docs/database/*` generated and aligned with audit output  
- **PC-10** — Non-reversible migrations listed consistently  

### Failed checks

| ID | Check |
|----|-------|
| **FC-01** | `20260530180000_user_consent_registry` missing `migration.sql` — **P3015 on deploy** |
| **FC-02** | `db:audit` reports 59 migrations without flagging missing SQL |
| **FC-03** | Multi-env drift validation not executed |
| **FC-04** | Backup gzip integrity not validated |
| **FC-05** | Restore drill not evidenced |
| **FC-06** | Seed validation not completed |

### Warnings

| ID | Check |
|----|-------|
| **WC-01** | 5 duplicate timestamp groups (acceptable) |
| **WC-02** | Local DB 9 pending migrations |
| **WC-03** | `pg_dump` not on verification host |
| **WC-04** | 3 unrelated unit test failures |

---

## Recommended Fixes

| Priority | Fix | Owner |
|----------|-----|-------|
| **P0** | **Delete** empty `prisma/migrations/20260530180000_user_consent_registry` **or** restore `migration.sql`** (if content was merged into `legal_consent`, remove orphan from chain and repair `_prisma_migrations` on affected DBs per Prisma repair doc) | Engineering |
| **P0** | Extend `buildMigrationInventory()` to **fail** when `migration.sql` is missing | Engineering |
| **P0** | Re-run `npx prisma migrate deploy` on CI and local after fix | Engineering |
| **P1** | Run `DATABASE_URL_STAGING` / `PRODUCTION` snapshots + `db:compare-schema` before next prod deploy | Ops |
| **P1** | Log quarterly restore drill | Ops |
| **P1** | Set `BACKUP_VERIFY_DIR` in deploy preflight | Ops |
| **P2** | Remove staging backup `\|\| true` | DevOps |
| **P2** | Audit: exclude folders without SQL from `migrationCount` | Engineering |

---

## Production Readiness Score

| Pillar | Weight | Score | Weighted |
|--------|--------|------:|---------:|
| Migration readiness | 30% | 35 | 10.5 |
| Rollback readiness | 20% | 74 | 14.8 |
| Backup readiness | 20% | 68 | 13.6 |
| Drift risk (inverse) | 15% | 62 | 9.3 |
| Framework / tooling | 15% | 82 | 12.3 |
| **Total** | 100% | — | **60.5 → 61** |

### Sub-scores (requested)

| Metric | Score | Notes |
|--------|------:|-------|
| Migration readiness | **35** | P3015 blocker |
| Rollback readiness | **74** | Docs + scripts; no drill |
| Backup readiness | **68** | Scripts; no integrity test |
| Drift risk | **62** | Higher risk = worse; not validated across envs |

---

## Launch stage verdicts

| Stage | Verdict | Rationale |
|-------|---------|-----------|
| **Validation framework** | **PASS WITH WARNINGS** | Tooling, CI job, docs exist; audit gap on empty folders |
| **Controlled Beta DB deploy** | **FAIL** | Cannot complete full `migrate deploy` until FC-01 fixed |
| **Public Beta** | **FAIL** | Same + drift/restore gaps |
| **General Availability** | **FAIL** | Same |

### Overall final verdict: **FAIL**

The platform **must not** run production `db:migrate:deploy` until **FC-01** is resolved and `migrate deploy` succeeds on a clean PostgreSQL instance.

After P0 fix, re-verify:

```bash
cd pranidoctor-backend
npm run db:audit          # should report 58 migrations, 0 missing SQL
npx prisma migrate deploy
npm run db:preflight
npm run db:validate
```

---

## Appendix — Commands executed

```text
npm run db:audit                    → exit 0 (does not detect missing SQL)
npx vitest run scripts/db/migration-safety.test.mjs → 3/3 pass
npx prisma validate                 → pass
npx prisma migrate status           → 9 pending
npx prisma migrate deploy           → P3015 at user_consent_registry
Get-ChildItem prisma/migrations     → 59 folders, 1 missing migration.sql
npm test                            → 328/331 pass (failures unrelated)
```

---

*Verification complete. No implementation changes made.*
