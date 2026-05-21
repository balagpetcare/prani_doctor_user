import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/session/session_controller.dart';

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
    Future.microtask(() async {
      await ref.read(sessionControllerProvider.notifier).restoreFromStorage();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
