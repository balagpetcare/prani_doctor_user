import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pranidoctor_user/core/localization/localization_loader.dart';

/// Global test bootstrap — mirrors production [main] l10n preload.
Future<void> testExecutable(Future<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await LocalizationLoader.ensureInitialized();
  await testMain();
}
