import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pranidoctor_user/features/home/data/dashboard_context_dto.dart';
import 'package:pranidoctor_user/features/home/data/home_api_guard.dart';
import 'package:pranidoctor_user/features/home/presentation/home_providers.dart';
import 'package:pranidoctor_user/features/home/presentation/widgets/home_load_failure_view.dart';
import 'package:pranidoctor_user/features/home/presentation/widgets/home_skeleton_timeout_guard.dart';
import 'package:pranidoctor_user/features/home/home_page.dart';

import '../helpers/widget_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Home ANR guards', () {
    test('DashboardContext.degraded renders offline shell fields', () {
      final ctx = DashboardContext.degraded(
        user: const DashboardContextUser(
          id: 'offline',
          name: 'Guest',
          phone: '',
          email: '',
        ),
      );
      expect(ctx.fromCache, isTrue);
      expect(ctx.user.name, 'Guest');
    });

    testWidgets('skeleton timeout guard escalates to Bengali retry UI', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: testMaterialApp(
            home: Scaffold(
              body: HomeSkeletonTimeoutGuard(
                timeout: const Duration(milliseconds: 50),
                onRetry: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(HomeSkeletonTimeoutGuard), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump();

      expect(find.text(HomeLoadFailureView.defaultMessageBn), findsOneWidget);
      expect(find.text(HomeLoadFailureView.defaultRetryLabelBn), findsOneWidget);
    });

    testWidgets('home shows skeleton timeout guard while dashboard loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardProvider.overrideWith(_NeverCompletingDashboard.new),
            dashboardPollProvider.overrideWith(_StubPollNotifier.new),
          ],
          child: testMaterialApp(home: const Scaffold(body: HomePage())),
        ),
      );

      await tester.pump();
      expect(find.byType(HomeSkeletonTimeoutGuard), findsOneWidget);
    });
  });

  group('HomeApiGuard', () {
    test('skeleton timeout is shorter than dashboard load timeout', () {
      expect(
        HomeApiGuard.skeletonMaxDisplay,
        lessThan(HomeApiGuard.dashboardLoadTimeout),
      );
    });
  });
}

class _NeverCompletingDashboard extends DashboardNotifier {
  @override
  Future<DashboardContext?> build() async {
    await Completer<void>().future;
    return null;
  }
}

class _StubPollNotifier extends DashboardPollNotifier {
  @override
  int build() => 0;
}
