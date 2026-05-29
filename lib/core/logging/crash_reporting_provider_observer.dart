import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_logger.dart';
import 'crash_reporting_context.dart';

/// Reports Riverpod provider failures as non-fatal crash events.
final class CrashReportingProviderObserver extends ProviderObserver {
  const CrashReportingProviderObserver();
  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    AppLog.error(
      'Provider failure: ${provider.name ?? provider.runtimeType}',
      tag: 'Riverpod',
      error: error,
      stackTrace: stackTrace,
      fatal: false,
      data: {
        'category': CrashErrorCategory.providerFailure,
        'provider': provider.name ?? provider.runtimeType.toString(),
      },
    );
  }
}
