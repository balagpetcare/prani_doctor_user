/// Typed route paths for go_router.
abstract final class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const services = '/services';
  static const inbox = '/inbox';
  static const settings = '/settings';
  static const settingsProfile = '/settings/profile';
  static String doctorDetail(String id) => '/services/doctor/$id';
  static String bookConsultation(String doctorId) => '/services/doctor/$doctorId/book';
  static String serviceRequestDetail(String id) => '/inbox/request/$id';
  static String serviceRequestHistory(String id) => '/inbox/request/$id/history';
}
