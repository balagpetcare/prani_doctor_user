# Prani Doctor — Multi-Repository Release Report

**Generated:** 2026-05-30 (UTC)  
**Release manager mode:** Multi-repository independent validation  
**Proposed release train:** `v2.1.0` (aligned with recent commit messages; not tagged)

---

## Executive summary

| Outcome | **RELEASE BLOCKED** |
|---------|---------------------|
| Repositories validated | 3 |
| Repositories released | 0 |
| Partial release | No — policy forbids partial release |

No repository passed all gates. **No commits, tags, branch pushes, or tag pushes were performed.**

---

## Repositories in scope

| # | Repository | Path | Package version | Remote branch |
|---|------------|------|-----------------|---------------|
| 1 | `pranidoctor_user` | `D:\PraniDoctor\pranidoctor_user` | `1.0.0+1` (pubspec) | `main` → `origin/main` |
| 2 | `pranidoctor-web` | `D:\PraniDoctor\pranidoctor-web` | `0.1.0` | `main` → `origin/main` |
| 3 | `pranidoctor-backend` | `D:\PraniDoctor\pranidoctor-backend` | `1.0.0` | `main` → `origin/main` |

**Note:** Package manifest versions do not match the informal `v2.1` commit labels. Reconcile `pubspec.yaml` / `package.json` before the next release attempt.

---

## Per-repository results

### 1. `pranidoctor_user` (Flutter mobile)

| Field | Value |
|-------|-------|
| **Version (target)** | `v2.1.0` / `1.0.0+1` |
| **Commit hash** | `483a0626d400fc56cae8f46fca8ef27bab4990e7` |
| **Tag** | *(not created)* |
| **Release status** | **BLOCKED** |

#### Validation

| Gate | Result | Details |
|------|--------|---------|
| Repository state | FAIL | Dirty tree: 24 modified files, 50+ untracked paths (launch/compliance/docs, AI compliance, tests). Branch `main` in sync with `origin/main` but **uncommitted work blocks release**. |
| Build | FAIL | `flutter build apk --debug` failed (`compileFlutterBuildDebug`). Analyze/build errors prevent compilation. |
| Tests | FAIL | `flutter test`: **220 passed, 10 failed**. Failures include localization codegen drift, missing `app_config_provider` import path, `settingsProvider` undefined in router. |
| Migrations | N/A | Mobile app — no DB migrations. |
| Release notes | FAIL | No `docs/releases/RELEASE_v2.1.0.md` (or CHANGELOG entry) present. |

#### Primary failure reasons

1. **`flutter analyze`:** 260 issues (**128 errors**), including undefined `TranslationKeys` getters (phase4 feed), `settingsProvider` in `app_router.dart`, localization impl out of sync with `app_en.arb`.
2. **`flutter test`:** 10 failures — `AppLocalizationsEn` missing members; `closed_beta_banner.dart` imports `lib/app_config/...` instead of `lib/features/app_config/...`; settings integration assertion failure.
3. **Uncommitted changes** on `main` — release requires clean, committed state.
4. **Release notes** not authored.

#### Actions not taken

- Commit, tag `v2.1.0`, push branch, push tags — **skipped**

---

### 2. `pranidoctor-web` (Next.js admin / web)

| Field | Value |
|-------|-------|
| **Version (target)** | `v2.1.0` / `0.1.0` |
| **Commit hash** | `52e043310e98d5617a4bf4966b2d091c88388bf4` |
| **Tag** | *(not created)* — existing tags: `v2.0.0`, `v1.0.0` |
| **Release status** | **BLOCKED** |

#### Validation

| Gate | Result | Details |
|------|--------|---------|
| Repository state | FAIL | Dirty tree: 4 modified, 15+ untracked (launch-ops, AI compliance admin, compliance docs). |
| Build | FAIL | `next build` compiled Turbopack bundle then **TypeScript check failed** (`admin-nav.tsx`: `roles` not on `AdminNavGroup`). |
| Tests | PASS | `vitest run`: **25 files, 109 tests passed**. |
| Migrations | N/A | Uses Prisma client synced from backend; no local migration deploy in this gate. |
| Release notes | FAIL | No release notes file under `docs/releases/`. |

#### Primary failure reasons

1. **`npm run typecheck`:** 40+ TS errors (admin UI prop mismatches `subtitle`/`label`, TipTap duplicate module graph, Zod `errors` API, `admin-nav` `roles`).
2. **`npm run build`:** Blocked by same TypeScript errors.
3. **`npm run lint:release`:** Failed on Windows — path `src/app/admin/(dashboard)/launch-ops/page.tsx` breaks shell glob (`was unexpected at this time`). CI on Linux may behave differently; local release gate still failed.
4. **`npm ci`:** ERESOLVE — `@sentry/nextjs@9.47.1` peer requires `next@^13–15`, project uses `next@16.2.6`. Clean install not reproducible without lockfile/peer resolution.
5. **Uncommitted changes** and **missing release notes**.

#### Actions not taken

- Commit, tag, push — **skipped**

---

### 3. `pranidoctor-backend` (Express API)

| Field | Value |
|-------|-------|
| **Version (target)** | `v2.1.0` / `1.0.0` |
| **Commit hash** | `2f1b1ba0098c0be9c53932b60ae3aa4b11619af5` |
| **Tag** | *(not created)* |
| **Release status** | **BLOCKED** |

#### Validation

| Gate | Result | Details |
|------|--------|---------|
| Repository state | FAIL | Dirty tree: 50+ modified, 30+ untracked (AI governance, launch/GA, monitoring, emergency validation, new migration `20260601120000_ai_governance_scopes`). |
| Build | FAIL | `npm run build` (`typecheck` + `tsc`): extensive TS errors (queue error context, legacy import paths, AI compliance module resolution, `exactOptionalPropertyTypes`, missing `ai-disclaimer.service.js`, governance types). |
| Tests | FAIL | `vitest run`: **379 passed, 3 failed**; **4 test suites failed to load** (missing modules, logger not initialized in AI usage tests). |
| Migrations | PARTIAL | `node scripts/db/run-validation.mjs --audit-only`: **exit 0** — schema valid, 59 migrations inventoried (4 high-risk, 5 duplicate timestamps). `npm ci` **failed** (lockfile out of sync with `package.json` / Sentry deps). Pending migration folder not deployed in this run. |
| Release notes | FAIL | No `docs/releases/RELEASE_v2.1.0.md`. |

#### Primary failure reasons

1. **Build/typecheck** — blocking errors across `queue.service`, `ai-compliance-config`, `ai-disclaimer.resolver`, `ai-governance.service`, and legacy web shims.
2. **Tests** — missing `../../legacy/web/lib/ai-disclaimer/ai-disclaimer.service.js`; `Logger not initialized` in `ai-usage-monitoring.verify.test.ts`; archived auth test missing `cache.keys.js`.
3. **`npm ci`** — lockfile drift (`@sentry/node` and OpenTelemetry packages missing from lock).
4. **Uncommitted changes** including new migration `prisma/migrations/20260601120000_ai_governance_scopes/`.
5. **Release notes** not authored.

#### Actions not taken

- Commit, tag, push — **skipped**

---

## Cross-cutting findings

1. **All three repos** carry substantial uncommitted launch/compliance/AI governance work on `main`.
2. **Version alignment** — commit messages reference `v2.1` while package files remain `1.0.0` / `0.1.0`; define a single semver before tagging.
3. **Dependency hygiene** — both Node repos need lockfile updates (`npm install` / commit lock) and web needs Sentry/Next peer alignment.
4. **Mobile codegen** — run `dart run tool/i18n/build_localization.dart` (or project i18n script) and fix `closed_beta_banner` / router imports before re-validation.
5. **Backend** — fix module paths and logger init in tests before CI parity.

---

## Recommended remediation order

1. **pranidoctor_user:** Regenerate localizations; fix import paths; resolve analyze errors; commit; re-run `flutter analyze`, `flutter test`, `flutter build apk --debug`.
2. **pranidoctor-backend:** Sync `package-lock.json`; fix TS/build errors and test harness; commit including migration; run `npm ci`, `npm test`, `npm run build`, `npm run db:validate`.
3. **pranidoctor-web:** Fix TypeScript errors; fix `lint:release` Windows path quoting or run gate in CI/Linux; align Sentry/Next peers; `npm run typecheck`, `lint:release`, `build`.
4. **All repos:** Add `docs/releases/RELEASE_v2.1.0.md` per repo (or shared changelog policy).
5. **Re-run** this multi-repo release process; only then tag `v2.1.0` and push.

---

## Validation command log (local)

| Repo | Commands executed |
|------|-------------------|
| `pranidoctor_user` | `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk --debug` |
| `pranidoctor-web` | `npm ci` (failed), `npm run typecheck` (failed), `npm test` (pass), `npm run lint:release` (failed), `npm run build` (failed) |
| `pranidoctor-backend` | `npm ci` (failed), `npm run db:generate`, `npm test` (failed), `npm run build` (failed), `node scripts/db/run-validation.mjs --audit-only` (pass) |

---

## Final status

```
╔══════════════════════════════════════╗
║         RELEASE BLOCKED              ║
║  0 / 3 repositories ready          ║
║  No git tags or pushes performed     ║
╚══════════════════════════════════════╝
```

**Next outcome after fixes:** If 1–2 repos pass → **PARTIAL RELEASE** (still blocked by policy unless scope adjusted). If all 3 pass → **READY FOR RELEASE**.
