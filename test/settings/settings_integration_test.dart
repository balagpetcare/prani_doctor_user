import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/core/cache/cache_store.dart';
import 'package:pranidoctor_user/core/offline/local_cache_contract.dart';
import 'package:pranidoctor_user/features/offline/data/local_cache_service.dart';
import 'package:pranidoctor_user/features/offline/data/outbox_service.dart';
import 'package:pranidoctor_user/core/session/session_providers.dart';
import 'package:pranidoctor_user/features/settings/data/settings_dto.dart';
import 'package:pranidoctor_user/features/settings/data/settings_repository.dart';
import 'package:pranidoctor_user/features/settings/presentation/settings_providers.dart';

class _MemoryCacheStore implements CacheStore {
  final Map<String, dynamic> _data = {};

  @override
  String get name => 'memory';

  @override
  T? read<T>(String key) => _data[key] as T?;

  @override
  Future<void> put(String key, dynamic value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> clear() async => _data.clear();

  @override
  Iterable<dynamic> get values => _data.values;
}

SettingsBundle _sampleBundle({bool fromCache = false}) =>
    SettingsBundle.fromJson({
      'settings': {'theme': 'LIGHT', 'updatedAt': '2026-05-22T08:00:00.000Z'},
      'legal': {
        'privacyPolicyUrl': 'https://example.com/privacy',
        'termsOfServiceUrl': 'https://example.com/terms',
        'privacyVersion': '2026-05-01',
        'termsVersion': '2026-05-01',
        'privacyAccepted': false,
        'termsAccepted': false,
      },
    }, fromCache: fromCache);

void main() {
  group('SettingsBundle', () {
    test('parses settings and legal summary', () {
      final bundle = SettingsBundle.fromJson({
        'settings': {
          'theme': 'DARK',
          'locale': 'bn-BD',
          'updatedAt': '2026-05-22T08:00:00.000Z',
        },
        'legal': {
          'privacyPolicyUrl': 'https://example.com/privacy',
          'termsOfServiceUrl': 'https://example.com/terms',
          'privacyVersion': '2026-05-01',
          'termsVersion': '2026-05-01',
          'privacyAccepted': false,
          'termsAccepted': true,
        },
      });
      expect(bundle.settings.theme, SettingsTheme.dark);
      expect(bundle.legal.termsAccepted, isTrue);
    });

    test('round trips to json', () {
      final bundle = SettingsBundle.fromJson({
        'settings': {'theme': 'LIGHT', 'updatedAt': '2026-05-22T08:00:00.000Z'},
        'legal': {
          'privacyPolicyUrl': 'a',
          'termsOfServiceUrl': 'b',
          'privacyVersion': '1',
          'termsVersion': '1',
          'privacyAccepted': false,
          'termsAccepted': false,
        },
      });
      expect(bundle.toJson()['settings'], isA<Map<String, dynamic>>());
    });
  });

  group('LegalDocumentDto', () {
    test('parses document wrapper', () {
      final doc = LegalDocumentDto.fromJson({
        'document': {
          'type': 'privacy',
          'version': '2026-05-01',
          'url': 'https://example.com/privacy',
          'title': 'Privacy',
          'content': 'Content here',
          'accepted': true,
        },
      });
      expect(doc.accepted, isTrue);
      expect(doc.version, '2026-05-01');
    });
  });

  group('SettingsSyncInput', () {
    test('serializes acceptance fields', () {
      const input = SettingsSyncInput(
        theme: SettingsTheme.dark,
        acceptTermsVersion: '2026-05-01',
      );
      final json = input.toJson();
      expect(json['theme'], 'DARK');
      expect(json['acceptTermsVersion'], '2026-05-01');
    });
  });

  group('SettingsThemeApi', () {
    test('maps api values', () {
      expect(SettingsThemeApi.fromApi('LIGHT'), SettingsTheme.light);
      expect(SettingsThemeApi.fromApi('UNKNOWN'), SettingsTheme.system);
    });
  });

  group('LocalCacheContract settings keys', () {
    test('defines settings cache keys', () {
      expect(LocalCacheContract.userSettingsKey, 'user_settings_snapshot');
      expect(
        LocalCacheContract.privacyDocumentKey,
        'privacy_document_snapshot',
      );
      expect(LocalCacheContract.termsDocumentKey, 'terms_document_snapshot');
    });
  });

  group('SettingsRepository cache', () {
    late LocalCacheService cache;
    late SettingsRepository repository;

    setUp(() {
      final store = _MemoryCacheStore();
      cache = LocalCacheService(store);
      repository = SettingsRepository(Dio(), cache, OutboxService(store));
    });

    test('readCachedSettings returns stored bundle', () async {
      final bundle = _sampleBundle();
      await cache.write(
        LocalCacheContract.userSettingsKey,
        bundle.toJson(),
        LocalCacheContract.profileTtl,
      );

      final cached = await repository.readCachedSettings();
      expect(cached?.settings.theme, SettingsTheme.light);
      expect(cached?.fromCache, isTrue);
    });

    test('readCachedPrivacy returns stored document', () async {
      final doc = LegalDocumentDto.fromJson({
        'document': {
          'type': 'privacy',
          'version': '1',
          'url': 'https://example.com/privacy',
          'title': 'Privacy',
          'content': 'Body',
          'accepted': false,
        },
      });
      await cache.write(
        LocalCacheContract.privacyDocumentKey,
        doc.toJson(),
        LocalCacheContract.appConfigTtl,
      );

      final cached = await repository.readCachedPrivacy();
      expect(cached?.type, 'privacy');
      expect(cached?.fromCache, isTrue);
    });
  });

  group('Settings theme mapping', () {
    test('maps theme modes', () {
      expect(themeModeToSettings(ThemeMode.dark), SettingsTheme.dark);
      expect(settingsThemeToMode(SettingsTheme.light), ThemeMode.light);
    });
  });

  group('SettingsNotifier provider', () {
    test('loads cached settings on first read', () async {
      final store = _MemoryCacheStore();
      final cache = LocalCacheService(store);
      final repository = SettingsRepository(Dio(), cache, OutboxService(store));
      final bundle = _sampleBundle();
      await cache.write(
        LocalCacheContract.userSettingsKey,
        bundle.toJson(),
        LocalCacheContract.profileTtl,
      );

      final container = ProviderContainer(
        overrides: [
          protectedApisEnabledProvider.overrideWithValue(true),
          settingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final value = await container.read(settingsProvider.future);
      expect(value?.settings.theme, SettingsTheme.light);
    });
  });
}
