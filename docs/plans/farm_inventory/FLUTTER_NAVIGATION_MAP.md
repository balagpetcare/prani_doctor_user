# Farm Inventory V1 — Flutter Navigation Map

## Route table

| Screen | Path | `go_router` name |
|--------|------|------------------|
| Inventory home | `/inventory` | `inventory` |
| Feed stock | `/inventory/feed` | `inventoryFeed` |
| Add feed catalog item | `/inventory/feed/create` | `inventoryFeedCreate` |
| Feed item detail | `/inventory/feed/:id` | `inventoryFeedDetail` |
| Feed stock receipt | `/inventory/feed/:id/receipt` | `inventoryFeedReceipt` |
| Medicine stock | `/inventory/medicine` | `inventoryMedicine` |
| Add medicine catalog item | `/inventory/medicine/create` | `inventoryMedicineCreate` |
| Medicine item detail | `/inventory/medicine/:id` | `inventoryMedicineDetail` |
| Medicine stock receipt | `/inventory/medicine/:id/receipt` | `inventoryMedicineReceipt` |
| Consumption history | `/inventory/consumption-history` | `inventoryConsumptionHistory` |

## Cross-feature links

| From | To | Mechanism |
|------|-----|-----------|
| Feed detail | Log feeding | `/feeds/create?inventoryItemId={id}&deductStock=1` |
| Drawer | Inventory / Feed / Medicine | `AppRoutes.inventory*` |
| Feed form | Catalog picker | `inventoryFeedListProvider` |
| Treatment form (create) | Medicine deduct | `syncMedicineStockFromTreatment` after save |

## User flow (required V1)

```
Home (drawer)
  └─ Inventory
       ├─ Dashboard cards (current / low / history)
       ├─ Feed section → Feed list → Detail → Receipt | Log feeding
       └─ Medicine section → Medicine list → Detail → Receipt
```

Medicine list: **stock only** — no treatment creation UI.

## Provider invalidation

After any stock change, call:

```dart
InventoryNavigation.afterStockChange(ref, farmRef);
```

Invalidates: `inventoryDashboardProvider`, `inventoryFeedListProvider`, `inventoryMedicineListProvider` for that farm.
