import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import 'auth_dto.dart';

enum SocialProvider { google, facebook, apple }

/// Hook surface for future OAuth — no SDK wired yet.
abstract class SocialAuthProvider {
  bool get isAvailable;

  Future<ApiResult<AuthTokensDto>> signIn(SocialProvider provider);
}

class StubSocialAuthProvider implements SocialAuthProvider {
  @override
  bool get isAvailable => false;

  @override
  Future<ApiResult<AuthTokensDto>> signIn(SocialProvider provider) async {
    return ApiResult.failure(
      AppException(
        message: 'Social sign-in is not available yet.',
        code: 'NOT_IMPLEMENTED',
      ),
    );
  }
}

final socialAuthProvider = Provider<SocialAuthProvider>((ref) {
  return StubSocialAuthProvider();
});
