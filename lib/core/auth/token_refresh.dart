import 'package:dio/dio.dart';

import '../../features/auth/data/auth_api_paths.dart';
import '../../features/auth/data/auth_dto.dart';
import '../network/dio_helpers.dart';
import '../session/session_controller.dart';

/// Shared refresh-token rotation used by Dio interceptors and boot/session flows.
Future<bool> refreshAccessToken({
  required Dio dio,
  required SessionController session,
}) async {
  final refreshToken = await session.readRefreshToken();
  if (refreshToken == null || refreshToken.isEmpty) return false;

  try {
    final data = await postJson(dio, AuthApiPaths.refresh, {
      'refreshToken': refreshToken,
    });
    await session.applyAuthTokens(AuthTokensDto.fromJson(data));
    return true;
  } catch (_) {
    await session.signOut();
    return false;
  }
}
