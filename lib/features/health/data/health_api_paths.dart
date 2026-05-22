abstract final class HealthApiPaths {
  HealthApiPaths._();

  static const history = '/api/mobile/health/history';
  static const timeline = '/api/mobile/health/timeline';

  static String record(String id) => '/api/mobile/health/history/$id';
}
