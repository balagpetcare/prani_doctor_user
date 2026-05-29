# Farm Inventory System V1 — Conflict Analysis

**Plan ID:** `FARM_INVENTORY_SYSTEM_V1`  
**Date:** 2026-05-24

Classification: **SAFE** (additive, low risk) · **WARNING** (needs design guard) · **BLOCKER** (must resolve before ship)

---

## Summary Table

| ID | Area | Severity | Resolution strategy |
|----|------|----------|---------------------|
| C-01 | Feed log vs stock double semantics | WARNING | Optional deduct; clear UX labels |
| C-02 | Finance FEED/MEDICINE vs inventory | WARNING | Document; optional link V1.1 |
| C-03 | Farmer FarmTreatment vs medicine policy | WARNING | Separate UI; no auto-deduct V1 |
| C-04 | FeedType enum vs farmer catalog | WARNING | Map catalog → enum; keep both |
| C-05 | farmRef / farmId inconsistency | WARNING | Standardize on `farmRef` = app `Farm.id` |
| C-06 | Fattening feed log paths | SAFE | Reuse feed deduct hook |
| C-07 | Legacy FeedRecord.batchId | SAFE | No inventory coupling to legacy batchId |
| C-08 | Doctor Prescription vs inventory | SAFE (V1) | Defer consumption to V1.2 |
| C-09 | Duplicate prescription concepts | WARNING | Naming + API namespace discipline |
| C-10 | ROI aggregates vs stock cost | SAFE | ROI unchanged; stock is parallel |
| C-11 | Offline outbox ordering | WARNING | Movement idempotency keys |
| C-12 | No Farm table in DB | WARNING | Accept farmRef string scoping |
| C-13 | Extending FeedRecord schema | SAFE | Nullable columns |
| C-14 | Inventory module in drawer vs feed entry | WARNING | IA clarity in UI spec |
| C-15 | AI treatment future vs farmer Rx ban | BLOCKER (policy) | RBAC on consumption API |

---

## Detailed Findings

### C-01 — Feed consumption log vs stock balance (WARNING)

**Conflict:** `FeedRecord` records **what was fed**; inventory records **what remains**. Users may think logging feed always updates stock, or may log feed without selecting a catalog item.

**Risk:** Double-entry confusion; balances drift if some logs deduct and others do not.

**Mitigation:**
- UI: separate **“Log feeding”** (existing) from **“Stock in/out”** (new).
- API: `deductStock` explicit boolean; default `false` for backward compatibility.
- When `inventoryItemId` set and `deductStock=true`, use DB transaction: movement + feed row.

---

### C-02 — Finance expenses vs inventory receipts (WARNING)

**Conflict:** `FinanceRecord` with `ExpenseCategory.FEED | MEDICINE` tracks money spent; inventory tracks physical quantity. Users may enter both for the same purchase.

**Risk:** Double data entry; ROI/finance totals vs stock unrelated.

**Mitigation:**
- V1: no automatic finance → inventory sync.
- V1.1 (optional): “Record purchase” flow creates RECEIPT movement + optional finance row with shared `referenceId`.
- Docs and UI copy: finance = **money**, inventory = **quantity**.

---

### C-03 — FarmTreatment medicines vs medicine inventory policy (WARNING)

**Conflict:** Business rule: *“Farmer NEVER decides treatment”* but today farmers create `FarmTreatment` with `medicinesJson` (dosage, frequency).

**Risk:** Product appears to violate policy; merging inventory into treatment form implies clinical authority.

**Mitigation:**
- **Do not** add stock fields to `treatment_form_page.dart`.
- Medicine inventory screens: quantity only, no dosage fields.
- V1: no stock deduction from `medicinesJson`.
- Long-term: rebrand farmer module to “Health notes” or restrict medicine JSON to doctor-imported records (out of V1 scope).

**Severity note:** Policy tension is **product-level**, not technical BLOCKER, if inventory stays separate.

---

### C-04 — Global FeedType enum vs per-farm catalog (WARNING)

**Conflict:** `FeedRecord.feedType` is required enum; catalog items are free-text names with optional enum mapping.

**Risk:** Analytics break if catalog uses names outside enum; mismatched filters on feed list.

**Mitigation:**
- Catalog item: optional `feedType: FeedType?` for reporting alignment.
- Feed log: still requires `feedType` (pre-fill from catalog when selected).
- Allow catalog-only “custom feed” with `feedType: OTHER`.

---

### C-05 — farmRef vs FatteningBatch.farmId (WARNING)

**Conflict:** Operational records use `farmRef`; fattening uses `farmId` string with no shared FK.

**Risk:** Inventory scoped to wrong farm; fattening log feed deducts from another farm’s stock.

**Mitigation:**
- Inventory scoped by `farmRef` only.
- Fattening log feed: inherit `farmRef` from active farm when posting `FeedRecord`.
- QA checklist: active farm id matches `FatteningBatch.farmId` on create.

---

### C-06 — Fattening log feed reuses FeedRepository (SAFE)

**Conflict:** None if deduct hook lives in backend `feed-service` centrally.

**Mitigation:** Single server-side path for `createFeed`; Flutter fattening page unchanged except optional inventory picker.

---

### C-07 — Legacy FeedRecord.batchId (SAFE)

**Conflict:** Herd “batch” (`lib/features/batches/`) is local-only; legacy `batchId` on feed rows may not tie to fattening.

**Mitigation:** Inventory does not key on `batchId`; only `farmRef` + optional `inventoryItemId`.

---

### C-08 — Doctor Prescription domain (SAFE for V1)

**Conflict:** Future consumption from `PrescriptionItem` requires name matching to farmer catalog.

**Mitigation:** Defer to V1.2; design `sourceType: PRESCRIPTION_ITEM` on movements now.

---

### C-09 — Two “prescription” shapes (WARNING)

**Conflict:**
- Doctor: `Prescription` + `PrescriptionItem`
- Farmer: `FarmTreatment.prescription` (text) + `medicinesJson`

**Risk:** Developers expose inventory endpoints named `/prescription` or wire wrong model.

**Mitigation:**
- API namespace: `/api/mobile/inventory/medicine/*` only — **no** `/prescription` under inventory.
- Flutter route prefix: `/inventory/medicine`, not `/treatments/prescription`.

---

### C-10 — Fattening ROI vs stock (SAFE)

**Conflict:** ROI sums `FeedRecord.costBdt` and finance exclusions — stock levels do not affect ROI math.

**Mitigation:** No change to `roi-service.ts` in V1.

---

### C-11 — Offline sync ordering (WARNING)

**Conflict:** Outbox may replay feed create before catalog create; movements may reference missing items.

**Risk:** Sync failures, negative balances.

**Mitigation:**
- Client-generated UUIDs for catalog items and movements.
- Outbox dependency: `inventory_item_create` before `feed_create` with `inventoryItemId`.
- Server idempotency on `idempotencyKey`.

---

### C-12 — No Farm database entity (WARNING)

**Conflict:** Cannot FK inventory to `Farm` table.

**Mitigation:** `farmRef` string + `customerId` composite uniqueness; validate `farmRef` against farms list API client-side.

---

### C-13 — FeedRecord schema extension (SAFE)

**Conflict:** Adding nullable `inventoryItemId`, `stockMovementId` to `FeedRecord` is backward compatible.

**Mitigation:** Migration additive only; old clients ignore new fields.

---

### C-14 — Navigation: Feed entry vs Inventory (WARNING)

**Conflict:** Drawer already has **Feed entry** under Farm section; new **Inventory** may confuse users.

**Mitigation:** See `06-ui-flow.md`:
- “Feed entry” = daily log (unchanged)
- “Feed stock” under Inventory = warehouse

---

### C-15 — Medicine consumption authorization (BLOCKER for V1.2, policy for V1)

**Conflict:** Any API allowing farmer to deduct medicine without clinical event violates *“AI/doctor generated treatment can consume stock”*.

**Mitigation:**
- V1: farmer may only `RECEIPT` and `ADJUSTMENT` on medicine.
- `CONSUMPTION` on medicine requires `authorizedBy` ∈ {`PRESCRIPTION`, `TREATMENT_CASE`, `AI_PLAN`} — **reject** `FARMER` except manual adjustment type `ADJUSTMENT` with reason “wastage/expired”.
- RBAC enforced server-side, not UI-only.

---

## B. Conflict Report (consolidated)

### SAFE ✅

| Item | Notes |
|------|-------|
| New inventory tables | No existing tables dropped |
| Existing `/api/mobile/feeds/*` | Unchanged request/response without new fields |
| Fattening modules | Additive integration |
| Semen inventory | Separate domain; no merge |
| Flutter feed/treatment features | New `inventory` feature folder |
| Prisma migrations | Additive columns on `FeedRecord` optional |

### WARNING ⚠️

| Item | Owner action before build |
|------|---------------------------|
| Feed log vs stock UX | Copy + form design review |
| Finance double entry | Document; optional linked purchase flow |
| FarmTreatment vs medicine cabinet | IA separation |
| FeedType vs catalog | Mapping rules in API |
| farmRef consistency | Active farm QA matrix |
| Offline ordering | Outbox sequence spec |
| Drawer navigation | User testing labels (EN + BN later) |

### BLOCKER 🚫

| Item | Gate |
|------|------|
| Medicine CONSUMPTION without clinical authorization | **Must not ship** farmer-facing “use medicine” that mimics prescribing; consumption API RBAC required before V1.2 |
| Policy: inventory generates prescriptions | **Forbidden** — no API/UI; static analysis checklist |

*Note:* V1 can ship with **medicine stock tracking only** (catalog + RECEIPT/ADJUST) if consumption remains unimplemented — no BLOCKER for V1 scope if V1.2 is gated.

---

## C. Backward Compatibility Checklist

- [ ] Existing feed list/detail/create works without `inventoryItemId`
- [ ] Existing treatment CRUD unchanged
- [ ] Finance categories unchanged
- [ ] Fattening ROI/dashboards unchanged without deduct enabled
- [ ] Cache keys for feeds/treatments unchanged until inventory feature enabled
- [ ] Web proxies: add new routes only; do not alter feed route shapes

---

## D. Migration Strategy (conflict-aware)

| Phase | Scope | Conflicts addressed |
|-------|-------|---------------------|
| **Phase 0** | Planning docs only | This document |
| **Phase 1** | DB + inventory CRUD APIs (no feed deduct) | C-12, C-13 |
| **Phase 2** | Flutter inventory UI | C-14, C-03 |
| **Phase 3** | Feed log optional deduct | C-01, C-06, C-11 |
| **Phase 4** | Medicine consumption (doctor/AI) | C-15, C-08, C-09 |
| **Phase 5** | Ration engine + purchase recommendations | C-04, C-02 |

Rollback: disable feature flag `inventory_v1_enabled`; feed/treatment paths unaffected.
