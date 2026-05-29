# Phase 4 — Unresolved Risks

**Plan:** `PHASE_4_FINAL_STABILIZATION_AND_QA_V1`  
**Date:** 2026-05-29  
**Severity:** P0 = ship blocker · P1 = fix before scale · P2 = tech debt

---

## P0 — Production blockers (none after this pass)

All P0 items from the stabilization audit were addressed or downgraded with explicit mitigations:

| Item | Resolution |
|------|------------|
| Flutter offline livestock → wrong API | Fixed: `OutboxKind.livestockCreate` |
| Phase 4 purchase/consumption offline → legacy inventory | Fixed: dedicated outbox kinds |
| Inactive filter `ARCHIVED` enum mismatch | Fixed: `INACTIVE` |
| Missing mobile weight route | Fixed: snapshot route (see P1 for full history) |
| `InventoryStockError` invalid code | Fixed |

---

## P1 — Fix before broad production rollout

### Dual feed catalog / inventory stacks
**Risk:** Legacy `FeedCatalog` + `InventoryItem` coexist with Phase 4 `FeedItem` + `FeedInventory`. Recommendation engine reads Phase 4 only; older mobile flows may still hit legacy endpoints.

**Impact:** Duplicate masters, inconsistent recommendations, support confusion.

**Mitigation:** Route all new UX through Phase 4; deprecate legacy admin feed-items pages (already excluded from tsc). Migration script to map legacy inventory → Phase 4 where needed.

---

### Livestock weight history
**Risk:** `GET/POST .../weight` updates `Livestock.weightKg` only. No `LivestockWeightRecord` table; fattening `WeightRecord` ties to `AnimalProfile`, not Phase 4 livestock.

**Impact:** No ADG charts, no multi-point history on livestock detail.

**Mitigation:** Document API as snapshot-only; add `LivestockWeightRecord` migration in Phase 4.1.

---

### Recommendation daily GET does not persist log
**Risk:** Each daily fetch recomputes plan; accept endpoint persists. Offline/cached clients may show stale vs server recompute.

**Impact:** Audit trail gaps; inconsistent accept payload if rules change between GET and POST.

**Mitigation:** Upsert `FeedRecommendationLog` on daily GET with idempotent `(livestockId, planDate)` key.

---

### Analytics feed cost double-counting (potential)
**Risk:** Dashboard may sum consumption costs and purchase costs depending on query implementation.

**Impact:** Inflated feed spend metrics.

**Mitigation:** QA with seeded data; align analytics service to consumption-based cost only.

---

### Repo-wide TypeScript failures
**Risk:** `pnpm exec tsc` fails on unrelated legacy AI/admin paths; Phase 4 legacy routes under `src/legacy/web/routes/**` not in strict module graph.

**Impact:** Regressions may slip through CI if only full-repo tsc is gated.

**Mitigation:** Add scoped CI job: `tsc` on `src/modules/{livestock,feed-recommendation,inventory,phase4-*}` + feed-ecosystem lib paths.

---

### Admin web pre-existing tsc errors
**Risk:** TipTap duplicate packages, `api-utils` Zod typing, `FeedCatalogForm` prop mismatch.

**Impact:** Admin build may fail strict CI even though feed-ecosystem is clean.

**Mitigation:** Dedupe `@tiptap/*`, fix Zod v4 `error.issues` mapping, align form helper API.

---

## P2 — Tech debt / follow-ups

| Item | Notes |
|------|-------|
| Flutter `DropdownButtonFormField.value` deprecation | Migrate to `initialValue` when targeting Flutter 3.33+ |
| Offline queue panel labels | Hardcoded English for new outbox kinds; migrate panel to JSON i18n |
| Species form options | Form lists `OTHER` not `CUSTOM`; validation supports CUSTOM — align UX |
| Legacy web `feed-items` routes | Still in repo; remove or redirect to feed-ecosystem |
| `WeightRecord` vs Phase 4 naming in docs | Older QA docs referenced wrong service paths |
| Feed inventory validator | `displayName` optional when `feedItemId` set — confirm all mobile clients send feedItemId |
| Admin low-stock query | In-memory pagination after full low-stock fetch — acceptable now, not at 10k+ rows |
| Phase 4 route typecheck exclusion | Legacy route folder excluded from root tsconfig |

---

## Security & compliance watchlist

- **Farm scoping:** All Phase 4 writes must include `farmRef`; audit any admin list endpoints that omit farm filter.
- **Recommendation rules:** Admin JSON rules are powerful; restrict write to super-admin role; validate schema on save (already coerced v1→v2).
- **PII in logs:** Ensure recommendation explanations do not log raw health notes in production log level INFO.

---

## Decision log

| Decision | Rationale |
|----------|-----------|
| Weight route as snapshot | Ships contract compatibility without new migration |
| Exclude legacy web feed stack from tsc | Unblocks feed-ecosystem CI; legacy marked deprecated |
| Keep dual inventory outbox kinds | Legacy farm inventory feature still used outside Phase 4 hub |
