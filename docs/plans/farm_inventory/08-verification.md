# Farm Inventory System V1 — Verification Report

**Date:** 2026-05-24  
**Scope:** Database, API, Flutter (state/navigation), performance, and product rules  
**Method:** Static code audit + `prisma migrate status` + `flutter analyze lib/features/inventory` (no device E2E run in this pass)

---

## Executive summary

| Area | Verdict |
|------|---------|
| Database | **PASS** — schema + migration present; DB reported up to date |
| API | **PASS** — endpoints wired; feed deduct + medicine consume enforced |
| Flutter UI | **PASS** — module complete; routes registered; analyzer clean (info only) |
| State / offline | **PASS** with gaps — cache + outbox; deduct requires online |
| Navigation | **PASS** — drawer + nested `go_router` routes align with `AppRoutes` |
| Performance | **PASS** (V1 scale) — cache-first; pagination cap documented |
| Product rules | **PASS** with **FIX NOW** UX gaps — no prescription UI; stock automation present |

**Overall V1 readiness:** **PASS** for farmer mobile happy path, pending manual smoke test (no seed inventory data).

---

## Validation matrix

| Requirement | Result | Evidence |
|-------------|--------|----------|
| Feed inventory works | **PASS** | `GET /api/mobile/inventory/feed`, Flutter `InventoryFeedListPage`, create/receipt/detail |
| Medicine inventory works | **PASS** | `GET /api/mobile/inventory/medicine`, Flutter `InventoryMedicineListPage`, create/receipt/detail |
| Stock auto reduction (feed) | **PASS** | `createFeedForCustomer` + `consumeForFeedRecord`; Flutter `FeedInput` + deduct toggle |
| Stock auto reduction (medicine) | **PASS** (partial UX) | `syncMedicineStockFromTreatment` → `POST /inventory/consume` with `FARM_TREATMENT` |
| No prescription generation | **PASS** | No prescription APIs from inventory UI; backend blocks obvious prescription/diagnosis strings on medicine create |
| No broken routes | **PASS** | All `AppRoutes.inventory*` have matching `app_router.dart` `GoRoute`s |
| No duplicated entities | **PASS** | Single catalog (`InventoryItem`); `FeedRecord` is consumption log, not a second stock table; semen inventory is separate domain |

---

## PASS

### Database

- Migration `prisma/migrations/20260524120000_farm_inventory_v1/migration.sql` creates `InventoryItem`, `InventoryBalance`, `InventoryTransaction`, `InventoryAuditLog`, enums, and `FeedRecord` link columns (`inventoryItemId`, `inventoryTransactionId`, `deductStock`).
- Prisma models in `prisma/schema.prisma` match migration; unique constraint `@@unique([customerId, farmRef, inventoryType, displayName])` prevents duplicate catalog rows per farm.
- `npx prisma migrate status` → **Database schema is up to date** (46 migrations, local DB).

### API

| Endpoint | Status |
|----------|--------|
| `GET /api/mobile/inventory?farmRef=` | Implemented (`legacy/web/routes/mobile/inventory/route.ts`) |
| `GET /api/mobile/inventory/feed` | Implemented |
| `GET /api/mobile/inventory/medicine` | Implemented |
| `POST /api/mobile/inventory/add` | Implemented; medicine keyword guard |
| `POST /api/mobile/inventory/consume` | Implemented; medicine requires clinical `sourceType` |
| `POST /api/mobile/feeds` + `deductStock` | Implemented; rollback feed row on stock failure |

- Routes auto-registered via `compat-web/route-registry.ts` filesystem walk (no manual registry entry required).
- Web proxies exist: `pranidoctor-web/src/app/api/mobile/inventory/**` → `proxyRouteToBackend`.
- Feed stock deduct uses idempotency key `feed:{feedRecordId}` (`inventory.service.ts` `consumeForFeedRecord`).
- Stock engine centralizes balance updates (`modules/inventory/stock_engine/`).

### Flutter

- Feature module `lib/features/inventory/` (data, presentation, widgets, providers).
- Single API path surface: `inventory_api_paths.dart` (no duplicate HTTP clients).
- Cache keys: `inventory_summary`, `inventory_feed_list`, `inventory_medicine_list` on `LocalCacheContract`.
- Outbox: `inventory_add`, `inventory_consume` in `sync_coordinator.dart`; invalidation via `SyncDomain.inventory`.
- **Feed flow:** `FeedEntryFormPage` — catalog dropdown, online gate for deduct, invalidates inventory on success.
- **Medicine flow:** list/detail/receipt only; disclaimer text; no treatment/prescription forms in inventory screens.
- **Navigation:** Drawer → Inventory; nested feed/medicine/history routes documented in `FLUTTER_NAVIGATION_MAP.md`.
- `flutter analyze lib/features/inventory` → **0 errors** (6 info-level lints only).

### State

- Riverpod: `inventoryDashboardProvider`, `inventoryFeedListProvider`, `inventoryMedicineListProvider` — cache-first with background refresh.
- Offline: catalog `CREATE_ITEM` can queue; feed/medicine **consume** and feed **deduct** require online (by design).

### Performance (V1)

- List requests default `limit: 50` (Flutter) vs backend max `100` — acceptable for typical farm catalogs.
- Summary + list responses cached with `profileTtl`; stale-while-revalidate pattern on providers.
- No N+1 API pattern in inventory module (one list call per screen).

### No prescription generation

- Inventory screens: stock quantities, receipts, feed log link only.
- Backend `inventory/add`: rejects medicine `CREATE_ITEM` when name/notes contain `prescription` or `diagnosis`.
- `POST /inventory/consume` does not create `Prescription` rows — only ledger movements.
- Flutter medicine sync uses `FARM_TREATMENT` only (not `PRESCRIPTION_ITEM`).

### No duplicated entities

| Concept | Storage | Notes |
|---------|---------|-------|
| Feed catalog + balance | `InventoryItem` + `InventoryBalance` | Authoritative stock |
| Feed usage log | `FeedRecord` | Optional link to inventory; not a second stock table |
| Medicine catalog | `InventoryItem` (type MEDICINE) | Separate from `FarmTreatment` clinical record |
| Semen inventory | `TechnicianSemenInventory` | Unrelated; not merged into farm inventory |

---

## FAIL

| ID | Item | Impact |
|----|------|--------|
| F1 | **No automated E2E / integration tests** for inventory | Regression risk; verification relied on static audit |
| F2 | **No seed data** for inventory in `user_app_seed.ts` | Manual catalog setup required for QA |
| F3 | **Backend R9 (open):** `PRESCRIPTION_ITEM` consume callable by any mobile customer with valid `sourceId` | Security gap if IDs are guessable; Flutter does not use this path today |

> **Note:** F3 is a backend authorization **FAIL** for hardening, not a blocker for current Flutter paths (which use `FARM_TREATMENT` only).

---

## FIX NOW

| ID | Issue | Location | Recommended fix |
|----|-------|----------|-----------------|
| FN1 | Medicine stock sync **ignores** `consumeStock` failures | `inventory_medicine_sync.dart` | Check `ApiResult`; show SnackBar on `INSUFFICIENT_STOCK` / errors; do not pop treatment success silently |
| FN2 | Treatment saved even if all medicine deducts fail | `treatment_form_page.dart` | After `syncMedicineStockFromTreatment`, report partial/failed matches |
| FN3 | Dashboard **Current stock** card `onTap` is no-op | `inventory_home_page.dart` | Navigate to feed or combined list, or remove tap |
| FN4 | **Fattening feed log** has no inventory deduct integration | `fattening_log_feed_page.dart` (no matches) | Add same `inventoryItemId` / `deductStock` pattern as `FeedEntryFormPage` if product requires |
| FN5 | **Feed list pagination** — Flutter caches page 1 with `limit: 50` only | `inventory_repository.dart` | If farms exceed 50 SKUs, add paging or raise limit with backend agreement |
| FN6 | **Days remaining** depends on global `feedListProvider` (not farm-scoped fetch) | `inventory_providers.dart` | Prefer farm-filtered feed query for accuracy on multi-farm accounts |

---

## FUTURE

| ID | Item | Rationale |
|----|------|-----------|
| FT1 | Gate `PRESCRIPTION_ITEM` / `TREATMENT_CASE` / `AI_PLAN` consume behind doctor/service RBAC | Close R9 in `BACKEND_RISK_REPORT.md` |
| FT2 | Single DB transaction for feed create + stock deduct | Remove brief non-atomic window (R1) |
| FT3 | Dedicated inventory transaction history API + UI | Today consumption history reuses feed logs |
| FT4 | l10n for inventory strings (currently hardcoded English) | i18n parity |
| FT5 | `navigation_guard.dart` inventory routes | Only if auth gating pattern extended app-wide |
| FT6 | Inventory seed fixtures in `user_app_seed.ts` | Faster QA and demos |
| FT7 | Integration tests: feed deduct, medicine consume, offline catalog create | CI confidence |
| FT8 | Fuzzy medicine name matching (not exact `displayName`) | Reduce sync misses |
| FT9 | Reserve/release reserve UI | API supports via `add` operations |
| FT10 | Screenshots in `docs/plans/farm_inventory/screenshots/` | Manual capture per `FLUTTER_INTEGRATION_NOTES.md` |

---

## Area-by-area detail

### 1. Database

```
InventoryItem (catalog)
    └── InventoryBalance (1:1 quantity)
    └── InventoryTransaction (ledger)
FeedRecord ──optional──► InventoryItem
                      └── inventoryTransactionId
```

- Soft delete / `isActive` on items supported in schema.
- `allowNegativeStock` per item (explicit product choice).

### 2. API — stock auto reduction

**Feed (verified in code):**

1. Client sends `deductStock: true`, `inventoryItemId`, `farmRef`, `amount`.
2. Server creates `FeedRecord`, then `consumeForFeedRecord`.
3. On failure: deletes feed row, returns `INSUFFICIENT_STOCK` / `INVENTORY_ITEM_NOT_FOUND`.

**Medicine (verified in code):**

1. Treatment created via existing treatment API (clinical record unchanged).
2. Optional Flutter sync calls `consume` with `sourceType: FARM_TREATMENT`, `sourceId: treatmentId`.
3. Backend validates treatment exists for customer.

### 3. Flutter — navigation smoke checklist

| Step | Route | Expected |
|------|-------|----------|
| Drawer → Inventory | `/inventory` | Dashboard + sections |
| Feed section | `/inventory/feed` | List, low-stock banner |
| Feed detail | `/inventory/feed/:id` | Stock chip, days estimate, log feeding |
| Medicine section | `/inventory/medicine` | Stock only, no Rx UI |
| Consumption history | `/inventory/consumption-history` | Feed logs |
| Log feeding + deduct | `/feeds/create?...` | Toggle + catalog |

All routes exist in `app_router.dart` under parent `/inventory`.

### 4. Flutter — state / offline

| Operation | Offline behavior |
|-----------|------------------|
| List / summary | Serve cache; refresh when online |
| Create catalog item | Queue `inventory_add` |
| Receipt / consume / feed deduct | Fail or block until online |

### 5. Performance notes

- Home loads **summary only** (not full feed+médecine lists) — good.
- Feed detail watches `inventoryFeedListProvider` + `inventoryRecentFeedLogsProvider` — acceptable; may over-fetch feed logs on large histories (FT6).
- Background `unawaited` refresh after cache hit — standard app pattern.

---

## Manual QA script (recommended before release)

1. Apply migration on target environment (`prisma migrate deploy`).
2. Create feed catalog item + receipt stock for active `farmRef`.
3. Log feed with **Deduct from stock** → verify balance decreases and `FeedRecord` links inventory.
4. Create medicine catalog item + receipt.
5. Create treatment with matching medicine name + **Update medicine stock** → verify balance decreases.
6. Confirm medicine list has **no** prescription / treatment creation buttons.
7. Airplane mode: verify cached lists show offline hint; deduct blocked with clear message.
8. Drawer deep links: Inventory, Feed stock, Medicine stock.

---

## Commands run (this verification)

```powershell
cd D:\PraniDoctor\pranidoctor-backend
npx prisma migrate status   # → Database schema is up to date

cd D:\PraniDoctor\pranidoctor_user
flutter analyze lib/features/inventory   # → 0 errors, 6 info
```

---

## Sign-off

| Role | Status |
|------|--------|
| Static verification | **Complete** |
| Device E2E | **Not run** — execute manual QA script above |
| Production security (R9) | **Defer** to FT1 unless doctor consume is enabled |

**Recommendation:** Ship V1 to internal QA after addressing **FN1–FN2** (medicine sync error surfacing). Treat **F3 / FT1** before enabling any doctor-prescription consume path from mobile.
