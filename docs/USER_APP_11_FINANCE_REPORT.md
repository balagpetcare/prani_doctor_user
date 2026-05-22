# USER_APP_11 — Finance Module Report

**Project:** `pranidoctor_user`  
**Module:** `USER_APP_11_FINANCE`  
**Date:** 2026-05-22  
**Status:** COMPLETE

## Summary

Finance module delivered end-to-end: Prisma model, backend API, web proxies, Flutter feature with offline-first repository, three screens (Expense, Income, Profit), charts, and reports.

## Backend

| Component | Path |
|-----------|------|
| Schema | `prisma/schema.prisma` — `FinanceRecord`, `ExpenseCategory`, `IncomeSource` |
| Migration | `prisma/migrations/20260522160000_phase4_finance_records/` |
| Service | `src/legacy/web/lib/mobile-finance/finance-service.ts` |
| Routes | `src/legacy/web/routes/mobile/finance/**` |

### API endpoints

| Method | Path |
|--------|------|
| GET/POST | `/api/mobile/finance/expenses` |
| GET/PATCH/DELETE | `/api/mobile/finance/expenses/:id` |
| GET/POST | `/api/mobile/finance/income` |
| GET/PATCH/DELETE | `/api/mobile/finance/income/:id` |
| GET | `/api/mobile/finance/profit` |
| GET | `/api/mobile/finance/charts` |
| GET | `/api/mobile/finance/reports` |

## Web proxies

`pranidoctor-web/src/app/api/mobile/finance/**` — auto-proxy via `proxyRouteToBackend`.

## Flutter

```
lib/features/finance/
├── data/
│   ├── finance_api_paths.dart
│   ├── finance_dto.dart
│   ├── finance_validation.dart
│   ├── finance_repository_contract.dart
│   └── finance_repository.dart
└── presentation/
    ├── finance_providers.dart
    ├── finance_expense_page.dart
    ├── finance_expense_form_page.dart
    ├── finance_income_page.dart
    ├── finance_income_form_page.dart
    ├── finance_profit_page.dart
    └── widgets/
        ├── finance_feedback.dart
        ├── finance_labels.dart
        └── finance_record_card.dart
```

## Features

| Screen | Capabilities |
|--------|-------------|
| Expense | CRUD, category filter, search, pagination, offline cache |
| Income | CRUD, source filter, history search, pagination |
| Profit | Net profit, period compare, income/expense/profit charts, category/source aggregates, export path hooks |

## Offline

- Cache keys in `LocalCacheContract`
- Outbox kinds: `finance_expense_*`, `finance_income_*`
- Sync coordinator drains outbox and invalidates finance providers
- Optimistic list updates on create/update/delete

## Routes

| Route | Screen |
|-------|--------|
| `/finance/expenses` | Expense list |
| `/finance/expenses/create` | Create expense |
| `/finance/expenses/:id/edit` | Edit expense |
| `/finance/income` | Income list |
| `/finance/income/create` | Create income |
| `/finance/income/:id/edit` | Edit income |
| `/finance/profit` | Profit + charts + reports |

## Integration

- `app_router.dart` — finance routes
- `app_startup.dart` — warm cached expense/income lists
- `home_quick_actions.dart` — Finance quick action
- `app_en.arb` — localization strings

## Tests

`test/finance/finance_integration_test.dart` — DTO parsing, validation, profit/charts payloads.

## Verify

```bash
cd pranidoctor-backend
npx prisma migrate deploy
npx prisma generate

cd ../pranidoctor_user
flutter gen-l10n
flutter test test/finance/
dart analyze lib/features/finance
```

## Notes

- Charts reuse `MilkSimpleBarChart` from the milk module.
- Export endpoints are reserved hooks (CSV/PDF paths returned in reports); copy-to-clipboard in UI.
- Architecture mirrors feed/milk modules: Riverpod, repository contract, real API only.

**USER_APP_11_FINANCE_COMPLETE**
