abstract final class Phase4FeedApiPaths {
  Phase4FeedApiPaths._();

  static const feedItems = '/api/mobile/feed-items';
  static String feedItem(String id) => '/api/mobile/feed-items/$id';
  static const feedInventory = '/api/mobile/feed-inventory';
  static const feedInventoryPurchase = '/api/mobile/feed-inventory/purchase';
  static const feedInventoryAlerts = '/api/mobile/feed-inventory/alerts';
  static const feedConsumption = '/api/mobile/feed-consumption';
}
