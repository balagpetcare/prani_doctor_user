import 'package:flutter_test/flutter_test.dart';
import 'package:pranidoctor_user/app/app_env.dart';
import 'package:pranidoctor_user/core/network/network_constants.dart';

void main() {
  group('AppEnv', () {
    test('fromEnvironment exposes port and url source', () {
      final env = AppEnv.fromEnvironment();
      expect(env.apiPort, 3000);
      expect(env.apiUrlSource, isNotNull);
      expect(env.webBaseUrl, isNotEmpty);
    });

    test('devWifiApiBaseUrl uses origin-only path (no /api/v1 suffix)', () {
      expect(
        NetworkConstants.devWifiApiBaseUrl(),
        'http://${NetworkConstants.defaultDevWifiHost}:3000',
      );
    });
  });
}
