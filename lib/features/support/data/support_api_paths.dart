abstract final class SupportApiPaths {
  SupportApiPaths._();

  static const tickets = '/api/mobile/support/tickets';
  static const upload = '/api/mobile/support/upload';
  static const help = '/api/mobile/support/help';

  static String ticket(String id) => '/api/mobile/support/tickets/$id';

  static String reply(String id) => '/api/mobile/support/tickets/$id/reply';
}
