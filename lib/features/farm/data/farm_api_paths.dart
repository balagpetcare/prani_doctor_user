/// Farm module API paths — composite over mobile profile + dashboard + animals.
abstract final class FarmApiPaths {
  FarmApiPaths._();

  static const dashboardContext = '/api/mobile/profile/dashboard-context';
  static const profile = '/api/mobile/me';
  static const uploadCoverImage = '/api/mobile/uploads/cover-image';
  static const animals = '/api/mobile/animals';
}
