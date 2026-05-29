# FIX_OUTBOX_ENUM_EXHAUSTIVE_SWITCH_AND_OFFLINE_PIPELINE_AUDIT_V1

**Date:** 2026-05-24  
**Project:** `pranidoctor_user` (Flutter)

---

## 1. Root cause

`OutboxKind` gained two values for farm inventory V1:

- `inventoryAdd` (`inventory_add`)
- `inventoryConsume` (`inventory_consume`)

`sync_coordinator.dart` and `sync_invalidation.dart` were updated. **`offline_queue_panel.dart`** `_itemLabel()` switch was not — Dart 3 exhaustive `switch` on enums fails compile.

Serialization is unaffected: `OutboxItem.toJson` / `fromJson` use `kind.apiValue` strings (backward compatible with stored queue items).

---

## 2. OutboxKind inventory (enum source)

File: `lib/features/offline/data/outbox_item.dart`

| Value | `apiValue` |
|-------|------------|
| `inventoryAdd` | `inventory_add` |
| `inventoryConsume` | `inventory_consume` |

Full enum: 41 values (service request through `settingsSync`).

---

## 3. Audit — all `OutboxKind` consumers

| File | Role | `inventoryAdd` / `inventoryConsume` |
|------|------|-------------------------------------|
| `outbox_item.dart` | Enum + JSON `fromApi` / `toJson` | Defined; `fromApi` unknown → `serviceRequest` (legacy fallback) |
| `sync_coordinator.dart` | Replay: `POST` add/consume | **Handled** |
| `sync_invalidation.dart` | Maps to `SyncDomain.inventory` | **Handled** |
| `offline_queue_panel.dart` | UI labels | **MISSING → fix** |
| `outbox_service.dart` | Storage list/enqueue | Kind-agnostic |
| `inventory_repository.dart` | Enqueues `inventoryAdd` only | Producer |
| Other repositories | Enqueue other kinds | N/A |

No `offline_sync_service.dart`, `outbox_repository.dart`, or `outbox_storage.dart` in this project — storage is `OutboxService` + `CacheStore`.

Other `switch (kind)` hits are **unrelated enums** (`NetworkProbeKind`, community/marketplace kinds, upload validation).

---

## 4. Implementation plan

1. Add cases to `offline_queue_panel.dart`:
   - `inventoryAdd` → label (catalog create / receipt queued as add)
   - `inventoryConsume` → label (consumption pending)
2. Use user-approved fallback copy: **"Inventory sync pending"** (both kinds; distinguish later via l10n if needed).
3. Run `flutter analyze` + `flutter test`.

---

## 5. Sync safety checklist

| Step | Status |
|------|--------|
| Serialize `kind` as `apiValue` | OK |
| Deserialize `fromApi` | OK (`inventory_add` / `inventory_consume`) |
| Queue restore (`listAll`) | OK |
| Retry / dead letter | OK (generic outbox) |
| Replay `inventoryAdd` | OK → `InventoryApiPaths.add` |
| Replay `inventoryConsume` | OK → `InventoryApiPaths.consume` |
| Post-sync invalidation | OK → `SyncDomain.inventory` |

**Note:** Only `inventory_repository.addStock` enqueues today (`CREATE_ITEM` offline). `inventoryConsume` path exists in coordinator for forward compatibility.

---

## 6. Backward compatibility

- Existing outbox JSON with new `kind` strings loads correctly.
- Unknown legacy `kind` strings still map to `serviceRequest` via `fromApi` orElse (unchanged).
- No schema migration on outbox storage.

---

## 7. Remaining risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Unknown `kind` → mislabeled as service request | Low | Only if corrupt storage |
| `inventoryConsume` queued but never enqueued from app | None | Coordinator ready if added later |
| No automated test for queue labels | Low | Manual QA on offline queue screen |

---

## 8. Implementation result (2026-05-24)

**Changed:** `lib/features/offline/presentation/offline_queue_panel.dart` — added:

```dart
case OutboxKind.inventoryAdd:
case OutboxKind.inventoryConsume:
  return 'Inventory sync pending';
```

## 9. Final verification checklist

- [x] `flutter analyze lib/features/offline` — no issues
- [x] Project-wide — no `not exhaustively matched` on `OutboxKind`
- [ ] `flutter test` — 227 passed, **4 failed** (pre-existing: settings/profile; unrelated to outbox)
- [ ] `flutter run` — manual (not run in CI pass)
- [ ] Settings → offline queue shows "Inventory sync pending" for inventory items
- [ ] Sync now replays `inventory_add` and refreshes inventory providers
- [ ] Pre-existing queue items (feed, treatment, etc.) still labeled correctly
