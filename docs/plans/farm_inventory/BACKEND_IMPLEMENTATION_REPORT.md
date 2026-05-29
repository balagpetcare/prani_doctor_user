# Farm Inventory V1 — Backend Implementation Report

**Date:** 2026-05-24  
**Repo:** `pranidoctor-backend` (+ web proxies in `pranidoctor-web`)

---

## Summary

Implemented the **Farm Inventory** domain as a modular package under `src/modules/inventory/` with legacy mobile routes at `/api/mobile/inventory/*`. The design follows the approved planning docs with user-requested naming (`InventoryItem`, `InventoryTransaction`, `InventoryType`).

---

## Module layout

```
src/modules/inventory/
├── index.ts
├── inventory.controller.ts
├── inventory.dto.ts
├── inventory.events.ts
├── inventory.mapper.ts
├── inventory.repository.ts
├── inventory.schemas.ts
├── inventory.service.ts
├── feed/feed-inventory.service.ts
├── medicine/medicine-inventory.service.ts
├── transactions/transaction.service.ts
└── stock_engine/
    ├── stock-engine.service.ts
    └── stock-engine.types.ts
```

---

## API endpoints (mobile)

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/mobile/inventory?farmRef=` | Summary (feed + medicine counts, low stock) |
| GET | `/api/mobile/inventory/feed?farmRef=` | Feed catalog + balances + low-stock alerts |
| GET | `/api/mobile/inventory/medicine?farmRef=` | Medicine catalog + balances + alerts |
| POST | `/api/mobile/inventory/add` | Create item, receipt, adjustment, reserve, release, set threshold |
| POST | `/api/mobile/inventory/consume` | Consumption (feed from `FEED_RECORD`, medicine from clinical sources) |

**Web proxies:** `pranidoctor-web/src/app/api/mobile/inventory/**`

---

## Data model

| Model | Role |
|-------|------|
| `InventoryItem` | Catalog (FEED / MEDICINE), soft-delete via `deletedAt` + `isActive` |
| `InventoryBalance` | Projected `quantityOnHand`, `quantityReserved` |
| `InventoryTransaction` | Immutable ledger |
| `InventoryAuditLog` | Append-only audit trail |
| `FeedRecord` (extended) | Optional `inventoryItemId`, `inventoryTransactionId`, `deductStock` |

---

## Features delivered

### Feed inventory
- Create catalog item (`operation: CREATE_ITEM`)
- Add stock (`RECEIPT`), adjust (`ADJUSTMENT`)
- Consume via `POST /inventory/consume` or feed log (`deductStock` + `inventoryItemId`)
- Low-stock detection on list + summary

### Medicine inventory
- Create catalog (name + unit only — no diagnosis/prescription fields)
- Add / adjust stock
- Reserve / release reserve (`RESERVE`, `RELEASE_RESERVE`)
- Consume linked to `FARM_TREATMENT`, `PRESCRIPTION_ITEM`, `TREATMENT_CASE`, `AI_PLAN`
- Route guard rejects medicine payloads containing prescription/diagnosis keywords on create

### Cross-cutting
- **Idempotency:** unique `(customerId, idempotencyKey)` on transactions
- **Soft delete:** `deletedAt` + `isActive=false` (deactivate path via future PATCH; schema ready)
- **Audit:** `InventoryAuditLog` on item create and every stock mutation
- **Events:** `inventory.events.ts` action constants used for audit actions

---

## Feed integration (backward compatible)

`POST /api/mobile/feeds` accepts optional:

```json
{
  "inventoryItemId": "...",
  "deductStock": true
}
```

- Omitted fields → legacy behaviour unchanged
- On stock failure, feed row is rolled back (deleted)
- Errors: `INSUFFICIENT_STOCK`, `INVENTORY_ITEM_NOT_FOUND`, `INVENTORY_ITEM_MISMATCH`

---

## Files touched

### Backend
- `prisma/schema.prisma`
- `prisma/migrations/20260524120000_farm_inventory_v1/migration.sql`
- `src/modules/inventory/**`
- `src/legacy/web/routes/mobile/inventory/**`
- `src/legacy/web/lib/mobile-feeds/schemas.ts`
- `src/legacy/web/lib/mobile-feeds/feed-service.ts`
- `src/legacy/web/routes/mobile/feeds/route.ts`

### Web
- `src/app/api/mobile/inventory/**`

---

## Deploy steps

1. `npx prisma migrate deploy` (or `db:migrate` in dev)
2. `npx prisma generate`
3. Restart backend + web dev servers

---

## Not in this pass

- Flutter UI (`lib/features/inventory/`)
- Doctor prescription auto-matcher
- Finance → inventory receipt linking
- PATCH deactivate item endpoint (schema supports soft delete)
