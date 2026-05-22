# USER_APP_09 — Milk Management Report

**Project:** `pranidoctor_user` (+ backend API)  
**Module:** `USER_APP_09_MILK`  
**Phase:** 4 — Dairy  
**Status:** Complete  
**Date:** 2026-05-22

## Summary

Delivered end-to-end milk management: Prisma `MilkRecord` model, real `/api/mobile/milk/*` backend routes, web proxies, and Flutter screens for entry CRUD, daily summary, and production charts — with offline cache, outbox sync, and optimistic updates.

## Backend API (new)

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/mobile/milk` | List entries (`from`, `to`, `animalId`, `page`, `limit`) |
| `POST` | `/api/mobile/milk` | Create entry |
| `GET` | `/api/mobile/milk/:id` | Entry detail |
| `PATCH` | `/api/mobile/milk/:id` | Edit entry |
| `DELETE` | `/api/mobile/milk/:id` | Delete entry |
| `GET` | `/api/mobile/milk/summary` | Daily/range totals (`date` or `from`/`to`) |
| `GET` | `/api/mobile/milk/charts` | Daily, weekly, monthly trends + session split |

**Schema:** `MilkRecord` — `customerId`, `animalId`, `farmRef`, `recordedDate`, `session` (`MORNING`/`EVENING`), `quantityLiters`, `notes`. Unique per animal/date/session.

**Backend files:**
- `prisma/schema.prisma`, migration `20260522120000_phase4_milk_records`
- `src/legacy/web/lib/mobile-milk/*`
- `src/legacy/web/routes/mobile/milk/*`

**Web proxies:** `pranidoctor-web/src/app/api/mobile/milk/*`

## Flutter module

```
lib/features/milk/
├── data/
│   ├── milk_api_paths.dart
│   ├── milk_dto.dart
│   ├── milk_validation.dart
│   ├── milk_repository_contract.dart
│   └── milk_repository.dart
└── presentation/
    ├── milk_providers.dart
    ├── milk_entry_page.dart
    ├── milk_entry_form_page.dart
    ├── milk_daily_summary_page.dart
    ├── milk_charts_page.dart
    └── widgets/
```

### Screens

1. **Milk Entry** (`/milk`) — list, morning/evening FABs, pull-to-refresh, pagination
2. **Daily Summary** (`/milk/summary`) — totals, per-animal, per-day, date navigation
3. **Charts** (`/milk/charts`) — daily/weekly/monthly bar charts, morning vs evening split

Form fields: farm, animal (cattle/livestock), date, session, quantity, notes — with validation and draft save.

### Offline

- Cache: `milk_list_snapshot`, `milk_detail:{id}`, `milk_summary:*`, `milk_charts_snapshot`, drafts
- Outbox: `milk_create`, `milk_patch`, `milk_delete`
- Optimistic create/update/delete on list cache
- `SyncCoordinator` drains to real milk endpoints

### Routes & navigation

- Home quick action: **Record milk** → `/milk`
- Entry list links to summary and charts

### Tests

`test/milk/milk_integration_test.dart` — DTO parsing, validation, summary payload (8 tests).

Run migration before API use:

```bash
cd pranidoctor-backend
npx prisma migrate deploy
npx prisma generate
```

```bash
cd pranidoctor_user
flutter test test/milk/
dart analyze lib/features/milk
```

---

**Module token:** `USER_APP_09_MILK_COMPLETE`
