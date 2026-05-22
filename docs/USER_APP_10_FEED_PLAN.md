# USER_APP_10 — Feed Management Plan

**Project:** `pranidoctor_user`  
**Module:** `USER_APP_10_FEED`  
**Date:** 2026-05-22

## Audit summary

| Area | Status |
|------|--------|
| Flutter feed module | **None** |
| Backend `/api/mobile/feeds` | **None** (ERD mentions `FeedRecord` — not implemented) |
| Prisma model | **None** |
| Existing patterns | Milk (`lib/features/milk/`), Animals, Farm, Batches |

**Decision:** Add Prisma `FeedRecord`, real mobile API (mirror milk module), web proxies, Flutter feature module — no mocks.

## Architecture (reuse)

- `lib/features/feed/data/` — paths, DTO, validation, repository
- `lib/features/feed/presentation/` — providers, pages, widgets
- Riverpod `AsyncNotifierProvider` for list; `FutureProvider` for cost/analytics
- `LocalCacheService` + `OutboxService` + `SyncCoordinator`
- `*Feedback` widgets pattern

## API design

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/mobile/feeds` | List/history (`from`, `to`, `animalId`, `batchId`, `feedType`, `search`, `page`, `limit`) |
| `POST` | `/api/mobile/feeds` | Create |
| `GET` | `/api/mobile/feeds/:id` | Detail |
| `PATCH` | `/api/mobile/feeds/:id` | Update |
| `DELETE` | `/api/mobile/feeds/:id` | Delete |
| `GET` | `/api/mobile/feeds/cost` | Daily/weekly/monthly cost + per animal |
| `GET` | `/api/mobile/feeds/analytics` | Cost breakdown, consumption trend, efficiency |

## Data model

```
FeedRecord {
  customerId, farmRef?, animalId?, batchId?, batchName?,
  feedType (GRASS|STRAW|CONCENTRATE|MINERAL|SILAGE|OTHER),
  amount, unit (KG|BAG|BUNDLE|LITER|OTHER),
  costBdt?, recordedDate, notes?
}
```

## Flutter screens & routes

| Route | Screen |
|-------|--------|
| `/feeds` | Feed entry + history (search/filter/pagination) |
| `/feeds/create` | Create entry |
| `/feeds/:id/edit` | Edit/delete entry |
| `/feeds/cost` | Feed cost + analytics |

## Offline

- Cache: `feeds_list_snapshot`, `feed_detail:{id}`, `feed_cost_snapshot`, `feed_analytics_snapshot`, drafts
- Outbox: `feed_create`, `feed_patch`, `feed_delete`
- Optimistic list updates; sync via `SyncCoordinator`

## Implementation order

1. Prisma + migration + backend lib/routes
2. Web proxy routes
3. Flutter data layer + providers
4. Feed entry + form + cost/analytics screens
5. Routes, l10n, sync, tests, report
