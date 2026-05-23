# USER_APP_08 — Batch Management

**Project:** PraniDoctor User App (`pranidoctor_user`)  
**Module:** Animal batches / groups  
**Status:** COMPLETE  
**Date:** 2026-05-22

---

## Phase 1 — Audit summary

### Already implemented (~75%)

| Capability | Location |
|------------|----------|
| List + search + filters | `BatchListPage` |
| CRUD (create/update) | `BatchRepository` |
| Move / merge animals | `BatchMoveDialog`, `BatchMergeDialog` |
| Detail + members + movements | `BatchDetailPage` |
| Form + animal assignment | `BatchFormPage` |
| Draft recovery | Repository cache |
| Offline / local-only mode | API 404 → local + outbox |
| Auto-seed from animals | When API unavailable |

### Backend reality

| Operation | Path | Status |
|-----------|------|--------|
| List | `GET /api/mobile/batches` | Client-ready; **not deployed** in web/backend yet |
| Create | `POST /api/mobile/batches` | Client-ready |
| Detail | `GET /api/mobile/batches/:id` | Client-ready |
| Update | `PATCH /api/mobile/batches/:id` | Client-ready |
| Move | `POST /api/mobile/batches/:id/move` | Client-ready |
| Merge | `POST /api/mobile/batches/merge` | Client-ready |
| Delete | — | **Local remove only** until API ships |

When API returns 404, module operates in **local-only mode** with disk cache + outbox sync.

### Gaps fixed this pass

| Gap | Resolution |
|-----|------------|
| No cache-first list | Cached batches → silent refresh |
| No sort | `BatchSort` + dropdown |
| No summary cards | Stats row (total, with animals, pending sync) |
| No delete UI | Local delete with confirm |
| Detail missing refresh | Pull-to-refresh |
| Filter empty conflated with no batches | Separate empty vs no-results |
| No navigation helper | `BatchNavigation` |

### Out of scope

| Item | Reason |
|------|--------|
| Farm-linked batches | No `farm_id` in schema |
| Batch image upload | No image field in API DTO |
| Server pagination | Full list client-side |
| Bengali ARB | English keys ready |

---

## Verification

```bash
flutter gen-l10n
dart analyze lib/features/batches
flutter test test/batches/
```

---

## API mapping

| UI action | Client method | HTTP (when deployed) |
|-----------|---------------|----------------------|
| List | `listBatches` | `GET /api/mobile/batches` |
| Detail | `getBatch` | `GET /api/mobile/batches/:id` |
| Create | `createBatch` | `POST /api/mobile/batches` |
| Update | `updateBatch` | `PATCH /api/mobile/batches/:id` |
| Delete | `deleteBatch` | `DELETE /api/mobile/batches/:id` |
| Move animals | `moveAnimals` | `POST /api/mobile/batches/:id/move` |
| Merge | `mergeBatches` | `POST /api/mobile/batches/merge` |

## State / provider flow

```
batchListProvider (AsyncNotifier)
  ├─ build: readCachedList → silent refresh
  ├─ batchSearchProvider / batchFilterProvider / batchSortProvider
  └─ batchRepositoryProvider → API or local cache + outbox

batchDetailProvider (family FutureProvider)
  └─ getBatch → detail cache + animal summaries

batchOptionsProvider → move/merge target picker
```

## Cache strategy

- **List:** `LocalCacheContract.batchesListKey` — full batch array + summary stats
- **Detail:** `LocalCacheContract.batchDetailKey(id)`
- **Drafts:** `batchDraftKey` / `batchEditDraftKey(id)`
- **Flow:** cache-first paint → silent network refresh → offline hint when `fromCache`
- **Local-only:** API 404 triggers permanent local mode + auto-seed from cached animals

## Remaining blockers

| Blocker | Impact |
|---------|--------|
| `/api/mobile/batches` not deployed | Local-only + outbox until backend ships |
| No `farm_id` on batch DTO | Farm-scoped batches not possible yet |
| No batch image field | Media upload N/A |

## Manual QA checklist

- [ ] Open batch list — cached batches appear instantly, then refresh
- [ ] Search / filter / sort combinations
- [ ] Summary cards match batch counts
- [ ] Create batch with animal assignment
- [ ] Edit batch — draft recovery after app restart
- [ ] Detail pull-to-refresh
- [ ] Move animals between batches
- [ ] Merge batch into another
- [ ] Delete batch with confirmation
- [ ] Offline create — pending sync badge + outbox entry
- [ ] Empty vs no-results states
