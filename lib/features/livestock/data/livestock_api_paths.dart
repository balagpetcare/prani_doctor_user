abstract final class LivestockApiPaths {
  LivestockApiPaths._();

  static const list = '/api/mobile/livestock';
  static String detail(String id) => '/api/mobile/livestock/$id';
  static String images(String id) => '/api/mobile/livestock/$id/images';
  static String healthRecords(String id) =>
      '/api/mobile/livestock/$id/health-records';
  static String vaccinations(String id) =>
      '/api/mobile/livestock/$id/vaccinations';
}
