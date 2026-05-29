# FEED_MULTI_SELECT_AND_BANGLADESH_FEED_MASTER_EXPANSION_V1

See backend plan: `pranidoctor-backend/docs/plans/FEED_MULTI_SELECT_AND_BANGLADESH_FEED_MASTER_EXPANSION_V1.md`

## Flutter Changes

- Multi-select `FilterChip` UI on `InventoryFeedCreatePage`
- Selection model: `Set<String> feedCatalogIds` (draft migrates legacy `feedCatalogId`)
- Draft key: `inventory_feed_create_draft`
- Offline asset: `assets/seeds/feed_catalog.json`
- Extended DTO: `aliases`, `nutrientTags`, `isPopular`

## Run seed (backend)

```bash
pnpm db:seed:feed-catalog
```
