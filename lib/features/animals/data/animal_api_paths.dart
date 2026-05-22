abstract final class AnimalApiPaths {
  AnimalApiPaths._();

  static const animals = '/api/mobile/animals';
  static String animal(String id) => '/api/mobile/animals/$id';
  static String deactivate(String id) => '/api/mobile/animals/$id/deactivate';
  static const uploadImage = '/api/mobile/uploads/profile-image';
}
