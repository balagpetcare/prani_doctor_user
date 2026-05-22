abstract final class BatchApiPaths {
  BatchApiPaths._();

  static const batches = '/api/mobile/batches';

  static String batch(String id) => '/api/mobile/batches/$id';

  static String move(String id) => '/api/mobile/batches/$id/move';

  static const merge = '/api/mobile/batches/merge';
}
