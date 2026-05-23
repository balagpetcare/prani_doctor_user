import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/core/session/session_auth.dart';
import 'package:pranidoctor_user/core/session/session_controller.dart';
import 'package:pranidoctor_user/features/auth/data/auth_dto.dart';

import '../helpers/test_jwt.dart';

void main() {
  group('SessionController', () {
    late Map<String, String> store;
    late SessionController controller;

    setUp(() {
      store = {};
      controller = SessionController(
        const FlutterSecureStorage(),
        testStore: store,
      );
    });

    test(
      'login success persists token and sets sessionReady + isAuthenticated',
      () async {
        final token = testJwt(sub: 'user-1');
        await controller.applyAuthTokens(
          AuthTokensDto(
            accessToken: token,
            expiresInSeconds: 3600,
            refreshToken: 'refresh-1',
            user: const AuthUserDto(
              id: 'user-1',
              name: 'Rahim',
              mobile: '01712345678',
            ),
          ),
          phone: '01712345678',
        );

        expect(controller.state.isAuthenticated, isTrue);
        expect(controller.state.sessionReady, isTrue);
        expect(controller.state.userId, 'user-1');
        expect(SessionAuth.canCallProtectedApis(controller.state), isTrue);
        expect(await controller.readAccessToken(), token);
        expect(store['auth.accessToken'], token);
      },
    );

    test(
      'restore session reloads valid token after simulated app restart',
      () async {
        final token = testJwt(sub: 'user-restart');
        store['auth.accessToken'] = token;
        store['auth.userId'] = 'user-restart';
        store['auth.displayName'] = 'Restart User';

        final restarted = SessionController(
          const FlutterSecureStorage(),
          testStore: store,
        );
        await restarted.restoreFromStorage();

        expect(restarted.state.sessionReady, isTrue);
        expect(restarted.state.isAuthenticated, isTrue);
        expect(restarted.state.userId, 'user-restart');
        expect(await restarted.readAccessToken(), token);
      },
    );

    test('logout clears storage and blocks protected APIs', () async {
      await controller.applyAuthTokens(
        AuthTokensDto(
          accessToken: testJwt(sub: 'user-2'),
          expiresInSeconds: 3600,
        ),
      );
      await controller.signOut();

      expect(controller.state.isAuthenticated, isFalse);
      expect(controller.state.sessionReady, isTrue);
      expect(SessionAuth.canCallProtectedApis(controller.state), isFalse);
      expect(store.containsKey('auth.accessToken'), isFalse);
      expect(await controller.readAccessToken(), isNull);
    });

    test('expired token restore signs out guest state', () async {
      store['auth.accessToken'] = testJwt(
        sub: 'user-expired',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await controller.restoreFromStorage();

      expect(controller.state.sessionReady, isTrue);
      expect(controller.state.isAuthenticated, isFalse);
      expect(store.containsKey('auth.accessToken'), isFalse);
    });

    test('invalid token restore rejects dev-token pseudo auth', () async {
      store['auth.accessToken'] = 'dev-token';

      await controller.restoreFromStorage();

      expect(controller.state.sessionReady, isTrue);
      expect(controller.state.isAuthenticated, isFalse);
      expect(store.containsKey('auth.accessToken'), isFalse);
    });

    test('memory cache serves token before async storage read', () async {
      final token = testJwt(sub: 'user-mem');
      await controller.applyAuthTokens(
        AuthTokensDto(accessToken: token, expiresInSeconds: 3600),
      );

      expect(await controller.readAccessToken(), token);
      store.remove('auth.accessToken');
      expect(await controller.readAccessToken(), token);
    });
  });
}
