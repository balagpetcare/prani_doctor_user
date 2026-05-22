# USER_APP_09 — Milk Management Plan

**Project:** `pranidoctor_user`  
**Phase:** 4 — Dairy  
**Priority:** Highest  
**Date:** 2026-05-22

## Analysis summary

### Current Flutter architecture (reuse as-is)

| Layer | Pattern | Reference |
|-------|---------|-----------|
| Data | `*api_paths`, `*_dto`, `*_validation`, `*_repository_contract`, `*_repository` | `lib/features/animals/` |
| State | Riverpod `AsyncNotifierProvider` (lists), `FutureProvider.family` (detail), `StateProvider` (filters) | `animal_providers.dart` |
| UI | `*Feedback` widgets, list + form pages, go_router | `animal_list_page.dart` |
| Offline | `LocalCacheService`, `OutboxService`, `SyncCoordinator` | `local_cache_contract.dart` |

### Existing providers & routes

- Auth/session: `sessionControllerProvider`, `dioProvider`
- Animals: `animalListProvider`, `animalRepositoryProvider` — required for animal picker (cattle)
- Farms: `farmListProvider` — composite farm label for `farmRef` field
- Routes today: `/home`, `/farms/*`, `/animals/*`, `/batches/*` — **no milk routes**

### API discovery

| Source | Milk API |
|--------|----------|
| `pranidoctor-backend` | **None** — must add Prisma `MilkRecord` + `/api/mobile/milk/*` |
| `pranidoctor-web` | Docs only (`APP_FLOW.md` §10 dairy dashboard) |
| `pranidoctor_user` | **None** |

**Decision:** Implement real backend API first (Prisma + legacy mobile routes + web proxy), then connect Flutter repository — **no mocks**.

### Planned API (`/api/mobile/milk`)

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/mobile/milk` | List entries (`from`, `to`, `animalId`, `page`, `limit`) |
| `POST` | `/api/mobile/milk` | Create entry |
| `GET` | `/api/mobile/milk/:id` | Entry detail |
| `PATCH` | `/api/mobile/milk/:id` | Edit entry |
| `DELETE` | `/api/mobile/milk/:id` | Delete entry |
| `GET` | `/api/mobile/milk/summary` | Daily / range aggregation |
| `GET` | `/api/mobile/milk/charts` | Daily, weekly, monthly, session split |

### Data model

```
MilkRecord {
  id, customerId, animalId, farmRef?,
  recordedDate (date), session (MORNING|EVENING),
  quantityLiters, notes?, createdAt, updatedAt
}
Unique: (customerId, animalId, recordedDate, session)
```

### Flutter module layout

```
lib/features/milk/
├── data/          (paths, dto, validation, repository)
└── presentation/
    ├── milk_providers.dart
    ├── milk_entry_page.dart      # Screen 1 — list + quick add
    ├── milk_entry_form_page.dart # create / edit
    ├── milk_daily_summary_page.dart  # Screen 2
    ├── milk_charts_page.dart     # Screen 3
    └── widgets/
        ├── milk_feedback.dart
        ├── milk_entry_card.dart
        └── milk_simple_chart.dart
```

### Routes

| Route | Screen |
|-------|--------|
| `/milk` | Milk entry list |
| `/milk/create` | New entry (optional `?session=morning\|evening`) |
| `/milk/:id/edit` | Edit entry |
| `/milk/summary` | Daily summary |
| `/milk/charts` | Production charts |

Entry from **Home quick actions** → `/milk`.

### Offline strategy

- Cache keys: `milk_list_snapshot`, `milk_detail:{id}`, `milk_summary:{date}`, `milk_charts:{period}`, drafts
- Outbox: `milk_create`, `milk_patch`, `milk_delete`
- Optimistic list update on create/edit/delete; enqueue on network failure
- Sync coordinator drains to real endpoints; invalidate `milkListProvider`, `milkSummaryProvider`, `milkChartsProvider`

### Charts (no new dependency)

Custom bar widgets (`milk_simple_chart.dart`) — daily bars, weekly/monthly trend lines via `CustomPainter`.

### Localization

Add `milk*` keys to `lib/l10n/app_en.arb` only.

### Tests

- `test/milk/milk_integration_test.dart` — DTO, validation, aggregation helpers

### Implementation order

1. Prisma `MilkRecord` + migration
2. Backend `mobile-milk` lib + routes
3. Web proxy routes
4. Flutter data layer + providers
5. Three screens + form
6. Offline/sync wiring
7. Tests + `USER_APP_09_MILK_REPORT.md`
