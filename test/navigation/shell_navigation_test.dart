import 'package:flutter_test/flutter_test.dart';
import 'package:pranidoctor_user/routing/app_routes.dart';

import 'package:pranidoctor_user/core/navigation/shell_navigation.dart';

void main() {
  group('ShellNavigation', () {
    test('rootForBranch returns shell tab roots', () {
      expect(ShellNavigation.rootForBranch(0), AppRoutes.home);
      expect(ShellNavigation.rootForBranch(1), AppRoutes.services);
      expect(ShellNavigation.rootForBranch(2), AppRoutes.inbox);
      expect(ShellNavigation.rootForBranch(3), AppRoutes.settings);
    });

    test('rootForBranch falls back to home for invalid index', () {
      expect(ShellNavigation.rootForBranch(-1), AppRoutes.home);
      expect(ShellNavigation.rootForBranch(99), AppRoutes.home);
    });

    test('branchRoots covers all bottom-nav tabs', () {
      expect(ShellNavigation.branchRoots.length, 4);
    });
  });
}
