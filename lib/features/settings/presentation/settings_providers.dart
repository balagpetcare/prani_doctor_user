import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../data/settings_dto.dart';
import '../data/settings_repository.dart';

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsBundle?>(SettingsNotifier.new);

class SettingsNotifier extends AsyncNotifier<SettingsBundle?> {
  Future<ApiResult<SettingsBundle>>? _inFlight;

  @override
  Future<SettingsBundle?> build() async {
    final cached = await ref.read(settingsRepositoryProvider).readCachedSettings();
    if (cached != null) {
      _refreshInBackground();
      return cached;
    }
    return _load(forceRefresh: false);
  }

  Future<SettingsBundle?> _load({required bool forceRefresh}) async {
    if (_inFlight != null) {
      final result = await _inFlight!;
      return result.when(success: (b) => b, failure: (_) => null);
    }
    final future = ref.read(settingsRepositoryProvider).getSettings(forceRefresh: forceRefresh);
    _inFlight = future;
    try {
      final result = await future;
      return result.when(
        success: (bundle) => bundle,
        failure: (e) => throw e,
      );
    } finally {
      _inFlight = null;
    }
  }

  void _refreshInBackground() {
    Future(() async {
      final result = await ref.read(settingsRepositoryProvider).getSettings(forceRefresh: true);
      result.when(
        success: (bundle) => state = AsyncData(bundle),
        failure: (_) {},
      );
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await _load(forceRefresh: true));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> syncTheme(SettingsTheme theme) async {
    await ref.read(settingsRepositoryProvider).sync(SettingsSyncInput(theme: theme));
    await refresh();
  }
}

final privacyDocumentProvider = FutureProvider<LegalDocumentDto>((ref) async {
  final result = await ref.read(settingsRepositoryProvider).getPrivacy();
  return result.when(success: (doc) => doc, failure: (e) => throw e);
});

final termsDocumentProvider = FutureProvider<LegalDocumentDto>((ref) async {
  final result = await ref.read(settingsRepositoryProvider).getTerms();
  return result.when(success: (doc) => doc, failure: (e) => throw e);
});
