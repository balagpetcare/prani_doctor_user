# USER_APP_09 — Milk Management

**Project:** PraniDoctor User App (`pranidoctor_user`)  
**Module:** Dairy / milk production  
**Status:** COMPLETE  
**Date:** 2026-05-22

---

## Phase 1 — Audit summary

### Already implemented (~85%)

| Capability | Location |
|------------|----------|
| CRUD + optimistic updates | `MilkRepository` |
| List + pagination | `MilkEntryPage` |
| Morning/evening entry FABs | `MilkEntryPage` |
| Form (farm, animal, date, session, qty) | `MilkEntryFormPage` |
| Daily summary | `MilkDailySummaryPage` |
| Charts (daily/weekly/monthly/split) | `MilkChartsPage` |
| Offline cache + outbox | Repository + `SyncCoordinator` |
| Backend API | `pranidoctor-backend` + web proxy |
| l10n | `app_en.arb` |
| Tests | `test/milk/` |

### Gaps fixed this pass

| Gap | Resolution |
|-----|------------|
| No cache-first list | Cached records → silent refresh |
| No detail screen | `MilkDetailPage` at `/milk/:id` |
| No date range / filters on history | Date range + animal + session + search |
| No summary cards on list | `MilkSummarySection` + today summary provider |
| No navigation helper | `MilkNavigation` |
| Summary/charts not cache-first | Cached read → silent refresh |
| Double-submit on form | Early return guard |
| Card navigates to edit | Card → detail → edit |

### Out of scope (schema)

| Field | Reason |
|-------|--------|
| fat, snf, temperature | Not in backend `MilkRecord` |
| batch_id | Not in API |
| price, revenue | Not in API |
| Export file generation | Report-ready JSON via summary DTO |

---

## API mapping

| UI action | Client method | HTTP |
|-----------|---------------|------|
| List | `listRecords` | `GET /api/mobile/milk` |
| Detail | `getRecord` | `GET /api/mobile/milk/:id` |
| Create | `createRecord` | `POST /api/mobile/milk` |
| Update | `updateRecord` | `PATCH /api/mobile/milk/:id` |
| Delete | `deleteRecord` | `DELETE /api/mobile/milk/:id` |
| Summary | `getSummary` | `GET /api/mobile/milk/summary` |
| Charts | `getCharts` | `GET /api/mobile/milk/charts` |

## State / provider flow

```
milkListProvider (AsyncNotifier)
  ├─ build: readCachedList → silent refresh
  ├─ milkFromDateProvider / milkToDateProvider / milkAnimalFilterProvider
  ├─ milkSearchProvider / milkSessionFilterProvider (client filter)
  └─ milkRepositoryProvider

milkTodaySummaryProvider → independent cache-first summary for list cards
milkSummaryProvider → daily summary page (date picker)
milkChartsProvider → cache-first charts page
milkRecordProvider → detail + edit bootstrap
```

## Cache strategy

- **List:** `milk_list_snapshot`
- **Detail:** `milk_detail:{id}`
- **Summary:** `milk_summary:{date|range}`
- **Charts:** `milk_charts_snapshot`
- **Drafts:** `milk_draft_new` / `milk_draft:{id}`
- **Flow:** cache-first paint → silent network refresh

## Remaining blockers

| Blocker | Impact |
|---------|--------|
| Quality/price fields absent | Cannot capture fat/SNF/revenue until schema extends |
| No batch_id on API | Batch-wise entry not available |
| Client session/search filter | Applies to loaded cache window, not server-side |

## Manual QA checklist

- [ ] List shows cached entries instantly, then refreshes
- [ ] Date range filter reloads history
- [ ] Animal filter + session chips + search
- [ ] Summary cards show today's liters
- [ ] Morning/evening FAB → pre-selected session on form
- [ ] Create/edit with validation + draft recovery
- [ ] Detail view → edit → delete
- [ ] Daily summary date navigation + pull-to-refresh
- [ ] Charts load from cache offline
- [ ] Offline create shows pending sync badge

## Verification

```bash
flutter gen-l10n
dart analyze lib/features/milk
flutter test test/milk/
```
