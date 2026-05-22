abstract final class TreatmentApiPaths {
  TreatmentApiPaths._();

  static const treatments = '/api/mobile/treatments';

  static String record(String id) => '/api/mobile/treatments/$id';
}
