import 'package:dio/dio.dart';

import '../session/session_controller.dart';
import '../session/session_manager.dart';

/// Shared refresh-token rotation used by Dio interceptors and boot/session flows.
Future<bool> refreshAccessToken({
  required Dio dio,
  required SessionController session,
  SessionManager? sessionManager,
  int maxAttempts = 2,
}) {
  final manager = sessionManager ?? SessionManager(session);
  return manager.refreshAccessToken(dio: dio, maxAttempts: maxAttempts);
}
