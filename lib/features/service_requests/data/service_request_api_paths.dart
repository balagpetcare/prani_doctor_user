abstract final class ServiceRequestApiPaths {
  ServiceRequestApiPaths._();

  static const serviceRequests = '/api/mobile/service-requests';
  static String serviceRequest(String id) => '/api/mobile/service-requests/$id';
  static String cancel(String id) => '/api/mobile/service-requests/$id/cancel';
  static String timeline(String id) => '/api/mobile/service-requests/$id/timeline';
  static const serviceCategories = '/api/mobile/service-categories';
  static const animals = '/api/mobile/animals';
}
