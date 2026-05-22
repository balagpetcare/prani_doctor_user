import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_preferences.dart';

final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  return ref.read(authPreferencesProvider).isOnboardingCompleted();
});
