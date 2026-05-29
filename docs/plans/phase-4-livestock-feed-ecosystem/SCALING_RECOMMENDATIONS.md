# Phase 4 — Scaling Recommendations

**Plan:** `PHASE_4_FINAL_STABILIZATION_AND_QA_V1`  
**Date:** 2026-05-29  
**Context:** Bangladesh livestock/feed ecosystem — growing farms, catalog size, and recommendation compute

---

## 1. Database

### Indexes (verify / add)
- `FeedInventory(customerId, farmRef, isActive)` — already indexed; monitor slow queries  
- `FeedConsumption(livestockId, recordedDate)` — add composite if consumption history queries grow  
- `FeedRecommendationLog(livestockId, planDate)` — unique index for idempotent daily logs  
- `Livestock(customerId, farmRef, lifecycleStatus)` — list filter performance  

### Query patterns
- **Admin low-stock:** Replace in-memory filter with SQL `quantityOnHand < lowStockThreshold` + indexed partial condition, or materialized `isLowStock` column updated by stock engine triggers.  
- **Analytics dashboard:** Extend `FeedAnalyticsCache` TTL strategy; precompute nightly per `(customerId, farmRef, period)`.  
- **Catalog search:** Move alias/n-gram search to Postgres `tsvector` or dedicated search service if catalog exceeds ~500 items per locale.

### Partitioning (future)
- Partition `FeedConsumption` and `InventoryTransaction` by `recordedDate` year when rows > 10M.

---

## 2. Recommendation engine

| Concern | Recommendation |
|---------|----------------|
| CPU per request | Cache daily plan per `(livestockId, planDate, rulesVersion)` in Redis 24h |
| Rules load | Keep 60s in-process cache; publish invalidation event on admin save |
| Cold start | Warm rules JSON on deploy from `Setting` + fallback `bd-v2-default.json` |
| Batch farms | Background job: precompute recommendations for dairy herds at 05:00 local |
| Explainability payload | Strip alternatives from mobile response when `?compact=1` |

### Horizontal scale
- Stateless API workers behind load balancer  
- Sticky sessions **not** required  
- Consider dedicated `recommendation-worker` queue for accept + analytics side effects  

---

## 3. API & backend

- **Connection pooling:** PgBouncer transaction mode for Prisma in production  
- **Rate limits:** Per-customer limits on recommendation recompute (e.g. 60/min)  
- **CDN:** Feed item images + static catalog JSON for offline mobile seed  
- **Read replicas:** Route analytics + admin aggregate queries to replica  

### Legacy route consolidation
- Single ingress for mobile feed APIs; deprecate duplicate legacy inventory paths to reduce maintenance surface.

---

## 4. Mobile (Flutter)

- **List virtualization:** Livestock list already paginated; ensure `ListView.builder` + keep scroll cache  
- **Image cache:** Livestock photos via existing `image_cache_config` limits  
- **Offline:** Cap outbox size per kind; prune dead items with user-visible retry  
- **Provider scope:** Keep `autoDispose` on heavy Phase 4 providers to prevent state leaks on farm switch  
- **Bundle size:** Lazy-load recommendation intelligence widgets if not on critical path  

---

## 5. Admin panel

- **Server-side pagination:** All feed-ecosystem tables should pass `page/limit` to backend (inventory fixed for low-stock)  
- **Edge caching:** Do not cache authenticated admin API responses at CDN  
- **Bulk operations:** Seed/moderation panels should use background jobs for >100 rows  

---

## 6. Observability

```text
Metrics to export (Prometheus / similar):
  feed_recommendation_compute_ms histogram
  feed_inventory_stock_error_total{code}
  mobile_outbox_drain_total{kind,status}
  admin_feed_ecosystem_request_duration_ms{route}
```

- Trace recommendation pipeline per module (dm-base, seasonal, item-selection) to find slow rules  
- Log `rulesVersion` on every recommendation response for support correlation  

---

## 7. Capacity planning (rough)

| Scale | Farms | Livestock | Notes |
|-------|-------|-----------|-------|
| Launch | < 1k | < 20k | Current architecture sufficient |
| Growth | 1k–10k | 200k | Redis recommendation cache + analytics precompute |
| Scale | 10k+ | 1M+ | Read replicas, consumption partitioning, search index |

---

## 8. Priority roadmap

1. **Sprint +1:** Persist recommendation log on daily GET; SQL low-stock pagination  
2. **Sprint +2:** Redis plan cache; analytics nightly job  
3. **Sprint +3:** `LivestockWeightRecord` + ADG API  
4. **Sprint +4:** Legacy catalog/inventory deprecation + data migration  

---

## Related

- [FINAL_QA_REPORT.md](./FINAL_QA_REPORT.md)  
- [UNRESOLVED_RISKS.md](./UNRESOLVED_RISKS.md)  
- [PRODUCTION_DEPLOYMENT_CHECKLIST.md](./PRODUCTION_DEPLOYMENT_CHECKLIST.md)
