abstract final class VaccineApiPaths {
  VaccineApiPaths._();

  static const vaccines = '/api/mobile/vaccines';
  static const reminders = '/api/mobile/vaccines/reminders';

  static String record(String id) => '/api/mobile/vaccines/$id';
}
