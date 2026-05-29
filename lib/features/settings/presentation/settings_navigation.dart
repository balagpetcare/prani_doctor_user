import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_providers.dart';

abstract final class SettingsNavigation {
  SettingsNavigation._();

  static void afterSync(WidgetRef ref) {
    ref.invalidate(settingsProvider);
    ref.invalidate(settingsPendingSyncCountProvider);
  }

  static void afterLegalAccept(WidgetRef ref) {
    ref.invalidate(privacyDocumentProvider);
    ref.invalidate(termsDocumentProvider);
    ref.invalidate(aiConsentDocumentProvider);
    ref.invalidate(settingsProvider);
  }

  static void invalidateAll(WidgetRef ref) {
    ref.invalidate(settingsProvider);
    ref.invalidate(privacyDocumentProvider);
    ref.invalidate(termsDocumentProvider);
    ref.invalidate(aiConsentDocumentProvider);
    ref.invalidate(settingsPendingSyncCountProvider);
  }
}
