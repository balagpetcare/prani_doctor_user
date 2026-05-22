abstract final class FeedApiPaths {
  FeedApiPaths._();

  static const feeds = '/api/mobile/feeds';
  static const cost = '/api/mobile/feeds/cost';
  static const analytics = '/api/mobile/feeds/analytics';

  static String record(String id) => '/api/mobile/feeds/$id';
}
