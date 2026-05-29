# Farm Inventory V1 — Migration Report

**Migration:** `20260524120000_farm_inventory_v1`  
**Date:** 2026-05-24

---

## Changes applied

### New enums
- `InventoryType` (FEED, MEDICINE)
- `MedicineUnit`
- `InventoryTransactionType` (RECEIPT, CONSUMPTION, ADJUSTMENT, RESERVE, RELEASE_RESERVE, VOID)
- `InventoryTransactionSourceType`

### New tables
| Table | Rows expected (prod start) |
|-------|----------------------------|
| `InventoryItem` | 0 |
| `InventoryBalance` | 0 |
| `InventoryTransaction` | 0 |
| `InventoryAuditLog` | 0 |

### Altered tables
| Table | Columns added | Nullable | Default |
|-------|---------------|----------|---------|
| `FeedRecord` | `inventoryItemId` | YES | — |
| `FeedRecord` | `inventoryTransactionId` | YES | — |
| `FeedRecord` | `deductStock` | NO | `false` |

---

## Safety assessment

| Check | Status |
|-------|--------|
| Additive-only DDL | PASS |
| No column drops | PASS |
| No renames on existing tables | PASS |
| FK `ON DELETE` safe (SET NULL on feed links) | PASS |
| Existing feed rows unaffected | PASS (`deductStock` defaults false) |
| Unique constraints non-blocking on empty DB | PASS |

---

## Rollback procedure

If migration must be reversed **before production data**:

```sql
ALTER TABLE "FeedRecord" DROP CONSTRAINT IF EXISTS "FeedRecord_inventoryTransactionId_fkey";
ALTER TABLE "FeedRecord" DROP CONSTRAINT IF EXISTS "FeedRecord_inventoryItemId_fkey";
ALTER TABLE "FeedRecord" DROP COLUMN IF EXISTS "inventoryTransactionId";
ALTER TABLE "FeedRecord" DROP COLUMN IF EXISTS "inventoryItemId";
ALTER TABLE "FeedRecord" DROP COLUMN IF EXISTS "deductStock";
DROP TABLE IF EXISTS "InventoryAuditLog";
DROP TABLE IF EXISTS "InventoryTransaction";
DROP TABLE IF EXISTS "InventoryBalance";
DROP TABLE IF EXISTS "InventoryItem";
DROP TYPE IF EXISTS "InventoryTransactionSourceType";
DROP TYPE IF EXISTS "InventoryTransactionType";
DROP TYPE IF EXISTS "MedicineUnit";
DROP TYPE IF EXISTS "InventoryType";
```

**Warning:** Do not rollback after farmers have inventory data unless exporting balances first.

---

## Post-migrate verification

```sql
SELECT COUNT(*) FROM "InventoryItem";
SELECT column_name FROM information_schema.columns
  WHERE table_name = 'FeedRecord' AND column_name LIKE 'inventory%';
```

---

## Backfill policy

**No automatic backfill.** Farmers set opening balances via `POST /inventory/add` with `operation: CREATE_ITEM` and optional `quantity`.

---

## Index summary

- `InventoryItem`: unique `(customerId, farmRef, inventoryType, displayName)`
- `InventoryTransaction`: unique `(customerId, idempotencyKey)` — partial usage when key provided
- `FeedRecord`: unique `inventoryTransactionId`
