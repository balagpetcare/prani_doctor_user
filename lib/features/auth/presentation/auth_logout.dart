import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routing/nav_guard.dart';
import '../../animals/data/animal_repository.dart';
import '../../animals/presentation/animal_providers.dart';
import '../../home/presentation/home_providers.dart';
import '../../profile/presentation/profile_providers.dart';
import '../data/auth_repository.dart';

/// Signs out locally and on server; [GoRouter] redirect sends user to login.
Future<void> performAuthLogout(WidgetRef ref) async {
  await ref.read(authRepositoryProvider).signOut();
  ref.invalidate(mobileMeProvider);
  ref.invalidate(dashboardProvider);
  ref.invalidate(animalListProvider);
  ref.invalidate(animalsProvider);
  NavLog.nav('logout — redirect will route to guest');
}
