abstract final class MilkApiPaths {
  MilkApiPaths._();

  static const milk = '/api/mobile/milk';
  static const summary = '/api/mobile/milk/summary';
  static const charts = '/api/mobile/milk/charts';

  static String record(String id) => '/api/mobile/milk/$id';
}
