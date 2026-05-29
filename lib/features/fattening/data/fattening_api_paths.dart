abstract final class FatteningApiPaths {
  FatteningApiPaths._();

  static const batches = '/api/mobile/fattening/batches';

  static String batch(String id) => '/api/mobile/fattening/batches/$id';

  static String start(String id) => '/api/mobile/fattening/batches/$id/start';

  static String animals(String id) => '/api/mobile/fattening/batches/$id/animals';

  static const weight = '/api/mobile/fattening/weight';

  static const weightHistory = '/api/mobile/fattening/weight/history';

  static String batchProgress(String batchId) =>
      '/api/mobile/fattening/batches/$batchId/progress';

  static String feedPlan(String batchId) =>
      '/api/mobile/fattening/batches/$batchId/feed-plan';

  static String feedDashboard(String batchId) =>
      '/api/mobile/fattening/batches/$batchId/feed-dashboard';

  static String roi(String batchId) =>
      '/api/mobile/fattening/batches/$batchId/roi';

  static String qurbani(String batchId) =>
      '/api/mobile/fattening/batches/$batchId/qurbani';
}
