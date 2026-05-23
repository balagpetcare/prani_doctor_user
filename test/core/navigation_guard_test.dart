import 'package:flutter_test/flutter_test.dart';
import 'package:pranidoctor_user/core/navigation/navigation_guard.dart';
import 'package:pranidoctor_user/routing/app_routes.dart';

void main() {
  group('RootRouteDetector', () {
    test('identifies bottom-nav and feature hub roots', () {
      expect(RootRouteDetector.isRootRoute(AppRoutes.home), isTrue);
      expect(RootRouteDetector.isRootRoute(AppRoutes.services), isTrue);
      expect(RootRouteDetector.isRootRoute(AppRoutes.inbox), isTrue);
      expect(RootRouteDetector.isRootRoute(AppRoutes.settings), isTrue);
      expect(RootRouteDetector.isRootRoute(AppRoutes.animals), isTrue);
      expect(RootRouteDetector.isRootRoute(AppRoutes.farms), isTrue);
      expect(RootRouteDetector.isRootRoute(AppRoutes.health), isTrue);
      expect(RootRouteDetector.isRootRoute(AppRoutes.feeds), isTrue);
      expect(RootRouteDetector.isRootRoute(AppRoutes.vaccines), isTrue);
      expect(RootRouteDetector.isShellRoot(AppRoutes.home), isTrue);
      expect(RootRouteDetector.isFeatureHubRoot(AppRoutes.farms), isTrue);
      expect(
        RootRouteDetector.isRootRoute(AppRoutes.settingsProfileComplete),
        isFalse,
      );
      expect(
        RootRouteDetector.isRootRoute(AppRoutes.settingsProfileEdit),
        isFalse,
      );
    });
  });
}
