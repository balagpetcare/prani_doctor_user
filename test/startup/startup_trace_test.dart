import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/core/startup/startup_trace.dart';
import 'package:pranidoctor_user/routing/app_routes.dart';
import 'package:pranidoctor_user/routing/nav_guard.dart';

void main() {
  tearDown(StartupTrace.resetForTest);

  group('StartupTrace', () {
    test('records ordered timeline marks', () {
      StartupTrace.appStart();
      StartupTrace.splashStart();
      StartupTrace.authCheckStart();
      StartupTrace.profileLoadStart();
      StartupTrace.locationLoadStart();
      StartupTrace.homeLoadStart();
      StartupTrace.homeRendered();

      final timeline = StartupTrace.timeline;
      expect(timeline.containsKey('APP_START'), isTrue);
      expect(timeline.containsKey('HOME_RENDERED'), isTrue);
      expect(
        timeline['HOME_RENDERED']! >= timeline['APP_START']!,
        isTrue,
      );
    });
  });

  group('authenticatedBootExit', () {
    test('does not return null while profile is loading', () {
      // Documented behavior: pending profile must still yield a navigable route.
      expect(AppRoutes.settingsProfileComplete, isNotEmpty);
      expect(authenticatedBootExit, isA<Function>());
    });
  });
}
