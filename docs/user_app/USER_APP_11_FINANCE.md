# USER_APP_11 — Finance

**Project:** PraniDoctor User App (`pranidoctor_user`)  
**Module:** Farm finance (income, expense, profit)  
**Status:** COMPLETE  
**Date:** 2026-05-22

---

## Phase 1 — Audit summary

### Already implemented (~85%)

| Capability | Location |
|------------|----------|
| Expense CRUD | `FinanceRepository`, `FinanceExpenseFormPage` |
| Income CRUD | `FinanceIncomeFormPage` |
| Profit + charts + reports | `FinanceProfitPage` |
| Search + category/source filters | Expense/Income list pages |
| Offline cache + outbox | Repository |
| Backend API | `/api/mobile/finance/*` |

### Gaps fixed this pass

| Gap | Resolution |
|-----|------------|
| No finance dashboard | `FinanceDashboardPage` at `/finance` |
| No cache-first lists | Cached records → silent refresh |
| No detail screens | `FinanceDetailPage` |
| No date range on lists | From/to date pickers |
| No summary cards | Income/expense/profit cards on lists + dashboard |
| No ledger / transaction history | Merged ledger on dashboard |
| No navigation helper | `FinanceNavigation` |
| Analytics not cache-first | Profit/charts/reports cache-first |
| Dedicated reports route | `FinanceReportsPage` |

### Out of scope (schema)

| Field | Reason |
|-------|--------|
| payment_method, reference_no | Not in backend DTO |
| animal_id, batch_id, milk/feed links | Not in API |
| currency (multi) | BDT only via `amountBdt` |

---

## API mapping

| UI action | HTTP |
|-----------|------|
| List expenses | `GET /api/mobile/finance/expenses` |
| List income | `GET /api/mobile/finance/income` |
| Expense detail | `GET /api/mobile/finance/expenses/:id` |
| Income detail | `GET /api/mobile/finance/income/:id` |
| Create/update/delete expense | POST/PATCH/DELETE expenses |
| Create/update/delete income | POST/PATCH/DELETE income |
| Profit summary | `GET /api/mobile/finance/profit` |
| Charts | `GET /api/mobile/finance/charts` |
| Reports | `GET /api/mobile/finance/reports` |

## Verification

```bash
flutter gen-l10n
dart analyze lib/features/finance
flutter test test/finance/
```
