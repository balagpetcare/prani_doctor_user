# Phase 4 — Flutter Implementation Report

**Plan ID:** `PHASE_4_FLUTTER_IMPLEMENTATION_V1`  
**App:** `pranidoctor_user`  
**Status:** Initial implementation complete

---

## 1. Screen Summary

| Module | Route | Screen | Purpose |
|--------|-------|--------|---------|
| Ecosystem | `/ecosystem` | `EcosystemHubPage` | Hub linking all Phase 4 modules |
| Livestock | `/livestock` | `LivestockListPage` | Paginated list, search, filters |
| Livestock | `/livestock/create` | `LivestockFormPage` | Add livestock + image upload + draft |
| Livestock | `/livestock/:id` | `LivestockDetailPage` | Profile, health, links to timeline/ration/vaccines |
| Livestock | `/livestock/:id/edit` | `LivestockFormPage` | Edit with draft cache |
| Livestock | `/livestock/:id/timeline` | `LivestockTimelinePage` | Health + vaccination history (merged client-side) |
| Livestock | `/livestock/:id/qr` | `LivestockQrPage` | QR payload / ear tag display + copy |
| Phase 4 Feed | `/feed-ecosystem` | `Phase4FeedHubPage` | Feed catalog, inventory, purchase, consumption |
| Phase 4 Feed | `/feed-ecosystem/items` | `Phase4FeedItemListPage` | Master feed item catalog |
| Phase 4 Feed | `/feed-ecosystem/items/:id` | `Phase4FeedItemDetailPage` | Nutrition + pricing detail |
| Phase 4 Feed | `/feed-ecosystem/inventory` | `Phase4FeedInventoryListPage` | Farm feed stock + low-stock badges |
| Phase 4 Feed | `/feed-ecosystem/purchase` | `Phase4FeedPurchasePage` | Stock purchase entry (offline draft) |
| Phase 4 Feed | `/feed-ecosystem/consumption` | `Phase4FeedConsumptionPage` | Consumption log + optional stock deduct |
| Recommendations | `/recommendations/:livestockId` | `DailyRationPage` | Daily ration, warnings, accept |
| Analytics | `/analytics/livestock` | `LivestockDashboardPage` | Expense dashboard + species chart |
| Analytics | `/analytics/livestock/feed-efficiency` | `FeedEfficiencyPage` | FCR / cost per animal metrics |

**Existing modules retained:** legacy `/animals`, `/feeds`, `/inventory` routes unchanged for backward compatibility.

---

## 2. State Flow Summary

```
activeFarmIdProvider → activeFarmRefProvider (farmRef scope)
        │
        ├── livestockListProvider (AsyncNotifier, paginated)
        │     ├── livestockSearchProvider / livestockFilterProvider / livestockSortProvider
        │     └── livestockRepositoryProvider
        │
        ├── livestockDetailProvider(id) / livestockTimelineProvider(id)
        │
        ├── phase4FeedItemsProvider / phase4FeedInventoryProvider
        │     └── phase4FeedRepositoryProvider
        │
        ├── dailyRecommendationProvider(livestockId)
        │     └── recommendationRepositoryProvider
        │
        └── livestockDashboardProvider / feedEfficiencyProvider / profitLossProvider
              └── livestockAnalyticsRepositoryProvider
```

**Offline:** list/detail/recommendation/analytics read through `LocalCacheService` with TTL keys in `LocalCacheContract`. Create livestock / purchase / consumption enqueue to outbox on transient network errors (`offlineQueuedCode`).

**Invalidation:** form submit invalidates list + detail providers; purchase/consumption invalidates inventory + consumption providers.

---

## 3. API Integration Summary

| Feature | Method | Path | Notes |
|---------|--------|------|-------|
| Livestock list | GET | `/api/mobile/livestock` | `farmRef`, pagination, search |
| Livestock CRUD | GET/PATCH/POST | `/api/mobile/livestock/:id` | Create returns `{ livestock }` |
| Images | POST | `/api/mobile/livestock/:id/images` | After upload service |
| Timeline (partial) | GET | `.../health-records`, `.../vaccinations` | Merged client-side |
| Feed catalog | GET | `/api/mobile/feed-items` | Global catalog |
| Feed inventory | GET/POST | `/api/mobile/feed-inventory` | Farm-scoped |
| Purchase | POST | `/api/mobile/feed-inventory/purchase` | Returns `{ inventory }` |
| Low stock | GET | `/api/mobile/feed-inventory/alerts` | Hub badge |
| Consumption | GET/POST | `/api/mobile/feed-consumption` | Optional `deductStock` |
| Daily ration | GET | `/api/mobile/recommendations/daily` | `livestockId`, `planDate` |
| Accept ration | POST | `/api/mobile/recommendations/accept` | |
| Dashboard | GET | `/api/mobile/analytics/livestock/dashboard` | `farmRef`, date range |
| Feed efficiency | GET | `/api/mobile/analytics/livestock/feed-efficiency` | |
| Profit/loss | GET | `/api/mobile/analytics/livestock/profit-loss` | Breakdown chart |

---

## 4. Folder Structure

```
lib/features/livestock/          # data + presentation
lib/features/phase4_feed/        # Phase 4 feed master + inventory + consumption
lib/features/feed_recommendations/
lib/features/livestock_analytics/
lib/features/ecosystem/          # hub + activeFarmRefProvider
```

---

## 5. Remaining TODOs

| Priority | Item |
|----------|------|
| P0 | Add dedicated `OutboxKind.livestockCreate` + sync handler targeting `/api/mobile/livestock` (currently reuses `animalCreate`) |
| P0 | Wire dedicated timeline API when backend ships `GET /livestock/:id/timeline` |
| P1 | Add `qr_flutter` or native QR render on `LivestockQrPage` |
| P1 | Livestock form: breed picker from `/api/mobile/livestock/breeds` |
| P1 | Phase 4 purchase/consumption: dedicated outbox kinds + sync payload mapping |
| P1 | Extend `sync_invalidation.dart` for Phase 4 entity kinds |
| P2 | Livestock detail tabs (overview / feed / health) instead of action buttons |
| P2 | Phase 4 feed item search UI on catalog list |
| P2 | Date range picker on analytics dashboard |
| P2 | Deep link from low-stock alerts → purchase pre-filled |
| P3 | Deprecate `/animals` routes in favor of `/livestock` alias redirect |
| P3 | Unit/widget tests for list merge + offline cache read paths |

---

## 6. Navigation Entry Points

- Drawer: **খাদ্য ও পশু** → `/ecosystem`
- Livestock detail → Recommendations, Timeline, Vaccines (existing module)
- Ecosystem hub → Livestock, Feed hub, Inventory (legacy), Analytics

---

## 7. Localization

All new UI strings use `context.tr.t(TranslationKeys.*)` with entries in `assets/i18n/bn.json` (primary) and `en.json`.
