# Farm Inventory System V1 — API Contract

**Plan ID:** `FARM_INVENTORY_SYSTEM_V1`  
**Date:** 2026-05-24  
**Base path:** `/api/mobile/inventory` (new)  
**Auth:** Same mobile session as existing `/api/mobile/feeds` (customer JWT)

Web layer: add proxies under `pranidoctor-web/src/app/api/mobile/inventory/**` mirroring feed routes.

---

## 1. Design Conventions

| Convention | Value |
|------------|-------|
| JSON casing | camelCase |
| Dates | ISO 8601 date (`YYYY-MM-DD`) for business dates; ISO datetime for `createdAt` |
| Money | Not primary in inventory V1 (use finance module) |
| Quantities | number, max 3 decimal places |
| Errors | `{ "error": { "code": "...", "message": "..." } }` |
| Pagination | `page`, `limit` (default 20, max 100) |
| Farm scope | `farmRef` query param or body field **required** on farm-scoped endpoints |

---

## 2. Resource Models (DTOs)

### 2.1 `InventoryItemDto`

```json
{
  "id": "clx...",
  "customerId": "clx...",
  "farmRef": "farm-uuid",
  "domain": "FEED",
  "displayName": "Mustard oil cake",
  "feedType": "CONCENTRATE",
  "feedUnit": "KG",
  "medicineUnit": null,
  "lowStockThreshold": 50,
  "allowNegativeStock": false,
  "isActive": true,
  "notes": null,
  "quantityOnHand": 120.5,
  "isLowStock": false,
  "createdAt": "2026-05-24T10:00:00.000Z",
  "updatedAt": "2026-05-24T10:00:00.000Z"
}
```

`quantityOnHand` joined from balance projection.

### 2.2 `InventoryMovementDto`

```json
{
  "id": "clx...",
  "inventoryItemId": "clx...",
  "farmRef": "farm-uuid",
  "domain": "FEED",
  "type": "CONSUMPTION",
  "quantityDelta": -12.5,
  "unitSnapshot": "KG",
  "sourceType": "FEED_RECORD",
  "sourceId": "feed-record-id",
  "reason": null,
  "recordedAt": "2026-05-24T10:00:00.000Z",
  "createdAt": "2026-05-24T10:00:00.000Z"
}
```

### 2.3 `LowStockRecommendationDto`

```json
{
  "inventoryItemId": "clx...",
  "displayName": "Mineral mix",
  "domain": "FEED",
  "quantityOnHand": 5,
  "lowStockThreshold": 10,
  "suggestedAction": "PURCHASE",
  "message": "Stock is below your alert level."
}
```

**Not a prescription** — `suggestedAction` ∈ `PURCHASE` | `RESTOCK` only.

---

## 3. Feed Subdomain Endpoints

### 3.1 List feed catalog

`GET /api/mobile/inventory/feed/items`

| Query | Type | Required |
|-------|------|----------|
| `farmRef` | string | yes |
| `activeOnly` | boolean | no (default true) |
| `search` | string | no |

**Response 200:**

```json
{
  "items": [ "InventoryItemDto..." ],
  "page": 1,
  "limit": 20,
  "total": 3
}
```

### 3.2 Create feed catalog item

`POST /api/mobile/inventory/feed/items`

**Body:**

```json
{
  "farmRef": "farm-uuid",
  "displayName": "Silage",
  "feedType": "SILAGE",
  "feedUnit": "KG",
  "lowStockThreshold": 100,
  "initialQuantity": 500,
  "notes": "Pit A",
  "idempotencyKey": "client-uuid-optional"
}
```

**Response 201:** `InventoryItemDto`

### 3.3 Patch feed catalog item

`PATCH /api/mobile/inventory/feed/items/:id`

Allowed: `displayName`, `feedType`, `feedUnit`, `lowStockThreshold`, `isActive`, `notes`  
**Not allowed:** direct `quantityOnHand` patch (use movements).

### 3.4 Record feed stock receipt / adjustment

`POST /api/mobile/inventory/feed/items/:id/movements`

**Body:**

```json
{
  "type": "RECEIPT",
  "quantity": 200,
  "recordedAt": "2026-05-24",
  "reason": "Purchase from Rajshahi feed mill",
  "idempotencyKey": "client-uuid"
}
```

`type`: `RECEIPT` | `ADJUSTMENT` (signed quantity for adjustment)

**Response 201:** `{ "movement": InventoryMovementDto, "item": InventoryItemDto }`

### 3.5 Feed movement history

`GET /api/mobile/inventory/feed/items/:id/movements?from=&to=&page=&limit=`

---

## 4. Medicine Subdomain Endpoints

Mirror feed paths under `/api/mobile/inventory/medicine/`:

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/medicine/items` | List medicine catalog |
| POST | `/medicine/items` | Create (no dosage fields) |
| PATCH | `/medicine/items/:id` | Update metadata |
| POST | `/medicine/items/:id/movements` | RECEIPT / ADJUSTMENT only in V1 |
| GET | `/medicine/items/:id/movements` | History |

**Create body example:**

```json
{
  "farmRef": "farm-uuid",
  "displayName": "Oxytetracycline LA",
  "medicineUnit": "ML",
  "lowStockThreshold": 100,
  "initialQuantity": 500,
  "idempotencyKey": "..."
}
```

### 4.1 Medicine consumption (V1.2 — spec only)

`POST /api/mobile/inventory/medicine/items/:id/consume`

**Forbidden for farmer tokens in V1.**

**Body (doctor/service):**

```json
{
  "quantity": 10,
  "sourceType": "PRESCRIPTION_ITEM",
  "sourceId": "prescription-item-id",
  "authorizedBy": "doctor:user-id",
  "idempotencyKey": "..."
}
```

**Response 403** if `authorizedBy` role insufficient.

---

## 5. Shared Endpoints

### 5.1 Low stock recommendations

`GET /api/mobile/inventory/recommendations?farmRef=&domain=FEED|MEDICINE|ALL`

**Response 200:**

```json
{
  "recommendations": [ "LowStockRecommendationDto..." ]
}
```

### 5.2 Farm inventory summary

`GET /api/mobile/inventory/summary?farmRef=`

```json
{
  "farmRef": "farm-uuid",
  "feed": { "activeItems": 5, "lowStockCount": 1 },
  "medicine": { "activeItems": 8, "lowStockCount": 2 }
}
```

---

## 6. Changes to Existing Feed API (backward compatible)

### 6.1 `POST /api/mobile/feeds` — extended body

**New optional fields:**

```json
{
  "inventoryItemId": "clx...",
  "deductStock": true
}
```

**Behavior:**
- If `deductStock` is false or omitted → no inventory interaction (legacy).
- If `deductStock` is true → `inventoryItemId` required; server runs consumption transaction.

**New error codes:**

| HTTP | code | When |
|------|------|------|
| 409 | `INSUFFICIENT_STOCK` | Balance < amount |
| 400 | `INVENTORY_ITEM_MISMATCH` | Item domain ≠ FEED or wrong farmRef |
| 404 | `INVENTORY_ITEM_NOT_FOUND` | Invalid id |

### 6.2 `GET /api/mobile/feeds/:id` — extended response

Optional fields: `inventoryItemId`, `deductStock`, `stockMovementId`, nested `inventoryItem` summary.

### 6.3 Patch/Delete feed

- **Patch** amount with `deductStock=true`: V1 policy — **disallow** changing deducted amount; require void + new log (future).
- **Delete**: if movement linked, create VOID movement + restore balance (V1.1).

---

## 7. Explicit Non-Goals (API)

| Forbidden endpoint | Reason |
|--------------------|--------|
| `POST .../inventory/medicine/prescription` | Inventory never prescribes |
| `POST .../inventory/*/treatment-plan` | Clinical domain |
| `PUT .../items/:id/quantity` | Bypasses ledger |

---

## 8. Zod Schema Sketch (backend)

Location (planned): `src/legacy/web/lib/mobile-inventory/schemas.ts`

```typescript
// Illustrative — not implemented
const farmRefSchema = z.string().trim().min(1).max(200);
const createFeedItemSchema = z.object({
  farmRef: farmRefSchema,
  displayName: z.string().trim().min(1).max(120),
  feedType: z.nativeEnum(FeedType).optional(),
  feedUnit: z.nativeEnum(FeedUnit),
  lowStockThreshold: z.coerce.number().min(0).optional(),
  initialQuantity: z.coerce.number().min(0).optional(),
  idempotencyKey: z.string().trim().max(64).optional(),
}).strict();
```

---

## 9. Flutter Repository Mapping (planned)

| Provider | API prefix |
|----------|------------|
| `inventoryFeedRepositoryProvider` | `/api/mobile/inventory/feed` |
| `inventoryMedicineRepositoryProvider` | `/api/mobile/inventory/medicine` |
| `feedRepositoryProvider` (existing) | Extended create body only |

Cache keys (planned additions to `LocalCacheContract`):

- `inventoryFeedListKey(farmRef)`
- `inventoryMedicineListKey(farmRef)`
- `inventoryRecommendationsKey(farmRef)`

Outbox ops:

- `inventory_feed_item_create`
- `inventory_movement_create`
- `feed_create` (unchanged; may embed inventory fields when online)

---

## 10. Versioning

| Header | Purpose |
|--------|---------|
| `X-Inventory-Version: 1` | Optional; server defaults to v1 |

Future breaking changes → v2 prefix `/api/mobile/inventory/v2`.
