import 'package:flutter/widgets.dart';

import '../error/app_exception.dart';
import '../localization/api_error_mapper.dart';
import '../localization/app_localizations.dart';
import 'network_exception.dart';

/// Single entry point for user-facing error copy (localized when possible).
///
/// Prefer this over `error.toString()` in widgets — raw exceptions may contain
/// internal paths, status codes, or English-only Dio messages.
abstract final class UserErrorMapper {
  UserErrorMapper._();

  /// Localized message when [context] has [AppLocalizations]; otherwise falls
  /// back to [apiFailureMessage].
  static String message(BuildContext? context, Object error) {
    if (context != null) {
      final l10n = AppLocalizations.of(context);
      if (l10n != null) return ApiErrorMapper.message(l10n, error);
    }
    return apiFailureMessage(error);
  }

  /// Localized error title for dialogs and full-page error states.
  static String title(
    BuildContext context,
    Object error, {
    bool settings = false,
  }) {
    return ApiErrorMapper.title(
      AppLocalizations.of(context)!,
      error,
      settings: settings,
    );
  }

  /// Whether the error indicates the device is offline or the request timed out.
  static bool isOffline(Object error) {
    if (error is AppException) return error.isOffline;
    return false;
  }

  /// Whether the user should be prompted to sign in again.
  static bool isUnauthorized(Object error) {
    if (error is AppException) return error.isUnauthorized;
    return false;
  }

  /// Whether a retry action is likely to succeed.
  static bool isRetryable(Object error) {
    if (error is AppException) {
      final type = error.networkType;
      return type == NetworkErrorType.noConnection ||
          type == NetworkErrorType.timeout ||
          type == NetworkErrorType.server ||
          type == NetworkErrorType.badResponse;
    }
    return true;
  }
}
