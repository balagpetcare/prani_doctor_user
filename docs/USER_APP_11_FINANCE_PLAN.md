# USER_APP_11 — Finance Module Plan

**Project:** `pranidoctor_user`  
**Module:** `USER_APP_11_FINANCE`  
**Date:** 2026-05-22

## Audit

| Area | Status |
|------|--------|
| Flutter finance module | **None** |
| Backend `/api/mobile/finance` | **None** |
| Pattern reference | `lib/features/feed/`, `lib/features/milk/` |

**Decision:** Add Prisma `FinanceRecord`, real mobile API, web proxies, Flutter feature — no mocks.

## Data model

```
FinanceRecord {
  customerId, type (EXPENSE|INCOME),
  amountBdt, recordedDate,
  category? (expense), source? (income),
  farmRef?, notes?
}
```

## API

| Method | Path | Purpose |
|--------|------|---------|
| GET/POST | `/api/mobile/finance/expenses` | List/create expenses |
| GET/PATCH/DELETE | `/api/mobile/finance/expenses/:id` | Expense CRUD |
| GET/POST | `/api/mobile/finance/income` | List/create income |
| GET/PATCH/DELETE | `/api/mobile/finance/income/:id` | Income CRUD |
| GET | `/api/mobile/finance/profit` | Profit + period compare |
| GET | `/api/mobile/finance/charts` | Income/expense/profit trends |
| GET | `/api/mobile/finance/reports` | Aggregates + export hooks |

## Flutter

```
lib/features/finance/
├── data/
└── presentation/
    ├── finance_expense_page.dart
    ├── finance_expense_form_page.dart
    ├── finance_income_page.dart
    ├── finance_income_form_page.dart
    ├── finance_profit_page.dart
    └── widgets/
```

## Routes

| Route | Screen |
|-------|--------|
| `/finance/expenses` | Expense list + filters |
| `/finance/expenses/create` | Create expense |
| `/finance/expenses/:id/edit` | Edit expense |
| `/finance/income` | Income list + history |
| `/finance/income/create` | Create income |
| `/finance/income/:id/edit` | Edit income |
| `/finance/profit` | Profit + charts + reports |

## Offline

Cache keys, outbox (`finance_expense_*`, `finance_income_*`), sync coordinator, optimistic updates.
