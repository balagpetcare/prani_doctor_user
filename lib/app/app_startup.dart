import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/startup/startup_cache_warmup.dart';

/// Preloads cached app config after [ProviderScope] is available.
///
/// Warmups run in the background via [StartupCacheWarmup] so the first frame
/// is not blocked; failures are logged and do not crash the app.
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StartupCacheWarmup.hydrate(ref);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
