import 'package:dio/dio.dart';

import '../error/app_exception.dart';
import 'app_localizations.dart';

/// Maps API / HTTP errors to localized user-facing copy.
abstract final class ApiErrorMapper {
  static String message(AppLocalizations l10n, Object error) {
    final code = _codeOf(error);
    if (code != null) {
      final mapped = l10n.apiError(code);
      if (mapped != code) return mapped;
    }
    if (error is AppException && error.message.isNotEmpty) {
      final fromException = l10n.apiError(error.message);
      if (fromException != error.message) return fromException;
    }
    return l10n.errorGeneric;
  }

  static String title(AppLocalizations l10n, Object error, {bool settings = false}) {
    final code = _codeOf(error);
    return switch (code) {
      '401' || 'UNAUTHORIZED' || 'UNAUTHORIZED_BEARER_REQUIRED' || 'TOKEN_INVALID' =>
        l10n.errorSessionExpiredTitle,
      '403' || 'FORBIDDEN' || 'FORBIDDEN_CUSTOMER_REQUIRED' || 'LEGAL_CONSENT_REQUIRED' =>
        l10n.errorPermissionDeniedTitle,
      '404' || 'NOT_FOUND' => settings
          ? l10n.errorSettingsUnavailableTitle
          : l10n.errorNotFoundTitle,
      '405' || 'METHOD_NOT_ALLOWED' => l10n.errorServiceUnavailableTitle,
      '500' || '502' || '503' || '504' => l10n.errorServerTitle,
      'NETWORK_ERROR' || 'OFFLINE' => l10n.errorNetworkTitle,
      _ => settings ? l10n.errorSettingsLoadTitle : l10n.errorGenericTitle,
    };
  }

  static String? _codeOf(Object error) {
    if (error is AppException) return error.code ?? error.message;
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final err = data['error'];
        if (err is Map<String, dynamic>) {
          return err['code'] as String? ?? error.response?.statusCode?.toString();
        }
      }
      return error.response?.statusCode?.toString();
    }
    return null;
  }
}
