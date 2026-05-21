import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/session/session_controller.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/offline/data/sync_coordinator.dart';
import '../features/profile/presentation/profile_providers.dart';

/// Runs startup side effects once the [ProviderScope] exists.
class AppStartup extends ConsumerStatefulWidget {
  const AppStartup({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends ConsumerState<AppStartup> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_restoreSession);
  }

  Future<void> _restoreSession() async {
    final session = ref.read(sessionControllerProvider.notifier);
    await session.restoreFromStorage();

    final expired = await session.isAccessTokenExpired();
    if (expired) {
      final refreshToken = await session.readRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await ref.read(authRepositoryProvider).refreshSession();
      } else {
        await session.signOut();
        return;
      }
    }

    if (ref.read(sessionControllerProvider).isAuthenticated) {
      await ref.read(mobileMeProvider.notifier).reload();
      await ref.read(syncCoordinatorProvider).syncNow(background: true);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
