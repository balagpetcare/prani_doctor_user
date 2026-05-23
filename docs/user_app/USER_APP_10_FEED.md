# USER_APP_10 — Feed Management

**Project:** PraniDoctor User App (`pranidoctor_user`)  
**Module:** Feed consumption & cost tracking  
**Status:** COMPLETE  
**Date:** 2026-05-22

---

## Phase 1 — Audit summary

### Already implemented (~85%)

| Capability | Location |
|------------|----------|
| CRUD + optimistic updates | `FeedRepository` |
| Animal + batch targets | `FeedEntryFormPage` |
| Cost + analytics API | Backend + `FeedCostPage` |
| Search + feed type filter | `FeedEntryPage` |
| Offline cache + outbox | Repository |
| Backend API deployed | `/api/mobile/feeds/*` |

### Gaps fixed this pass

| Gap | Resolution |
|-----|------------|
| No cache-first list | Cached records → silent refresh |
| No detail screen | `FeedDetailPage` at `/feeds/:id` |
| No date range filters | From/to date pickers on list |
| No animal/batch filter UI | Dropdown filters |
| No summary cards | Cost/entries/pending sync cards |
| No dedicated analytics screen | `FeedAnalyticsPage` at `/feeds/analytics` |
| No navigation helper | `FeedNavigation` |
| Cost/analytics not cache-first | Cached read → silent refresh |

### Out of scope (schema)

| Field | Reason |
|-------|--------|
| supplier | Not in backend `FeedRecord` |
| unit_cost (separate) | Uses `costBdt` total only |

---

## API mapping

| UI action | Client method | HTTP |
|-----------|---------------|------|
| List | `listRecords` | `GET /api/mobile/feeds` |
| Detail | `getRecord` | `GET /api/mobile/feeds/:id` |
| Create | `createRecord` | `POST /api/mobile/feeds` |
| Update | `updateRecord` | `PATCH /api/mobile/feeds/:id` |
| Delete | `deleteRecord` | `DELETE /api/mobile/feeds/:id` |
| Cost | `getCost` | `GET /api/mobile/feeds/cost` |
| Analytics | `getAnalytics` | `GET /api/mobile/feeds/analytics` |

## Manual QA checklist

- [ ] List cache-first paint + refresh
- [ ] Date range + animal + type + search filters
- [ ] Summary cards on list
- [ ] Create/edit animal and batch feed entries
- [ ] Detail → edit → delete
- [ ] Cost page with charts
- [ ] Analytics page independent load
- [ ] Offline create with pending sync badge

## Verification

```bash
flutter gen-l10n
dart analyze lib/features/feed
flutter test test/feed/
```
