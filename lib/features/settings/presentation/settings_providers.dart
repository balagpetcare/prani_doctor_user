import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/auto_refresh_guard.dart';
import '../../../core/providers/provider_stability.dart';
import '../../../core/session/session_providers.dart';
import '../../profile/data/profile_validation.dart';
import '../../profile/presentation/profile_providers.dart';
import '../../../theme/theme_controller.dart';
import '../data/settings_dto.dart';
import '../data/settings_repository.dart';
import '../../offline/data/outbox_item.dart';
import '../../offline/offline_providers.dart';

final settingsUpdateInFlightProvider = StateProvider<bool>((ref) => false);

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, SettingsBundle?>(
      SettingsNotifier.new,
    );

class SettingsNotifier extends AsyncNotifier<SettingsBundle?>
    with AsyncRefreshGuard {
  Future<ApiResult<SettingsBundle>>? _inFlight;

  void _log(String message) {
    if (kDebugMode) debugPrint('[SETTINGS] $message');
  }

  @override
  Future<SettingsBundle?> build() async {
    ref.persistProvider('settings');
    if (!ref.watch(protectedApisEnabledProvider)) {
      return null;
    }
    final cached = await ref
        .read(settingsRepositoryProvider)
        .readCachedSettings();
    if (cached != null) {
      _applyFromBundle(cached);
      _log('serving cached settings');
      ref.scheduleSilentRefresh(_refreshInBackground);
      return cached;
    }
    return _load(forceRefresh: false);
  }

  void _applyFromBundle(SettingsBundle bundle) {
    final theme = bundle.settings.theme;
    ref.read(themeModeProvider.notifier).state = switch (theme) {
      SettingsTheme.dark => ThemeMode.dark,
      SettingsTheme.light => ThemeMode.light,
      SettingsTheme.system => ThemeMode.system,
    };
    final locale = bundle.settings.locale;
    if (locale != null && ProfileValidation.isSupportedLocale(locale)) {
      ref
          .read(profileLocaleControllerProvider.notifier)
          .syncFromProfile(locale);
    }
  }

  Future<SettingsBundle?> _load({required bool forceRefresh}) async {
    if (_inFlight != null) {
      final result = await _inFlight!;
      return result.when(success: (b) => b, failure: (_) => null);
    }
    final future = ref
        .read(settingsRepositoryProvider)
        .getSettings(forceRefresh: forceRefresh);
    _inFlight = future;
    try {
      final result = await future;
      if (result is ApiSuccess<SettingsBundle>) {
        _applyFromBundle(result.data);
        _log('settings loaded from API');
        return result.data;
      }
      final error = (result as ApiFailure<SettingsBundle>).error;
      _log('settings fetch failed: ${error.code ?? error.message}');
      final cached = await ref
          .read(settingsRepositoryProvider)
          .readCachedSettings();
      if (cached != null) {
        _applyFromBundle(cached);
        _log('settings recovery — using cache');
        return cached;
      }
      throw error;
    } finally {
      _inFlight = null;
    }
  }

  Future<void> _refreshInBackground() async {
    if (!guardRefresh(silent: true)) return;
    final result = await ref
        .read(settingsRepositoryProvider)
        .getSettings(forceRefresh: true);
    result.when(
      success: (bundle) {
        _applyFromBundle(bundle);
        state = AsyncData(bundle);
      },
      failure: (_) {},
    );
    endRefresh();
  }

  Future<void> refresh() async {
    if (!guardReload()) return;
    final previous = state.value;
    if (previous != null) {
      state = AsyncData(previous);
    } else {
      state = const AsyncLoading();
    }
    try {
      state = AsyncData(await _load(forceRefresh: true));
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      endReload();
    }
  }

  Future<ApiResult<SettingsBundle>> syncInput(SettingsSyncInput input) async {
    if (ref.read(settingsUpdateInFlightProvider)) {
      return const ApiResult.failure(
        AppException(
          message: 'Update already in progress',
          code: 'SETTINGS_IN_FLIGHT',
        ),
      );
    }
    ref.read(settingsUpdateInFlightProvider.notifier).state = true;
    try {
      final result = await ref.read(settingsRepositoryProvider).sync(input);
      result.when(
        success: (bundle) {
          _applyFromBundle(bundle);
          state = AsyncData(bundle);
        },
        failure: (_) {},
      );
      return result;
    } finally {
      ref.read(settingsUpdateInFlightProvider.notifier).state = false;
    }
  }

  Future<ApiResult<SettingsBundle>> syncTheme(SettingsTheme theme) =>
      syncInput(SettingsSyncInput(theme: theme));

  Future<ApiResult<SettingsBundle>> syncLocale(String locale) =>
      syncInput(SettingsSyncInput(locale: locale));
}

final privacyDocumentProvider = FutureProvider<LegalDocumentDto>((ref) async {
  final result = await ref.read(settingsRepositoryProvider).getPrivacy();
  return result.when(success: (doc) => doc, failure: (e) => throw e);
});

final termsDocumentProvider = FutureProvider<LegalDocumentDto>((ref) async {
  final result = await ref.read(settingsRepositoryProvider).getTerms();
  return result.when(success: (doc) => doc, failure: (e) => throw e);
});

final settingsPendingSyncCountProvider = FutureProvider<int>((ref) async {
  final items = await ref.read(outboxServiceProvider).listAll();
  return items.where((i) => i.kind == OutboxKind.settingsSync).length;
});

final settingsLastSyncProvider = Provider<DateTime?>((ref) {
  return ref.watch(settingsProvider).valueOrNull?.settings.updatedAt;
});

ThemeMode settingsThemeToMode(SettingsTheme theme) => switch (theme) {
  SettingsTheme.dark => ThemeMode.dark,
  SettingsTheme.light => ThemeMode.light,
  SettingsTheme.system => ThemeMode.system,
};

SettingsTheme themeModeToSettings(ThemeMode mode) => switch (mode) {
  ThemeMode.dark => SettingsTheme.dark,
  ThemeMode.light => SettingsTheme.light,
  ThemeMode.system => SettingsTheme.system,
};
