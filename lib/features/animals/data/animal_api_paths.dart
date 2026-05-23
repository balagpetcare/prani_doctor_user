abstract final class AnimalApiPaths {
  AnimalApiPaths._();

  static const animals = '/api/mobile/animals';
  static String animal(String id) => '/api/mobile/animals/$id';
  static String deactivate(String id) => '/api/mobile/animals/$id/deactivate';
  /// Generic upload with purpose=ANIMAL_PHOTO (see [UploadService.uploadAnimalPhoto]).
  static const uploadImage = '/api/mobile/upload';
}
