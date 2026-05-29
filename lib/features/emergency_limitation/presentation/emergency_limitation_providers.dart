import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/language_controller.dart';
import '../data/emergency_limitation_dto.dart';
import '../data/emergency_limitation_repository.dart';

final emergencyLimitationProvider =
    AsyncNotifierProvider<EmergencyLimitationNotifier, EmergencyLimitationBundle?>(
  EmergencyLimitationNotifier.new,
);

class EmergencyLimitationNotifier extends AsyncNotifier<EmergencyLimitationBundle?> {
  @override
  Future<EmergencyLimitationBundle?> build() async {
    final result = await ref.read(emergencyLimitationRepositoryProvider).loadLimitation();
    return result.when(success: (b) => b, failure: (_) => null);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await ref
        .read(emergencyLimitationRepositoryProvider)
        .loadLimitation(forceRefresh: true);
    state = AsyncData(result.when(success: (b) => b, failure: (_) => null));
  }

  Future<bool> accept(
    EmergencyLimitationAcceptSurface surface, {
    String? serviceRequestId,
  }) async {
    final current = state.value;
    if (current == null) return false;
    final result = await ref.read(emergencyLimitationRepositoryProvider).accept(
          version: current.version,
          surface: surface,
          serviceRequestId: serviceRequestId,
        );
    return result.when(
      success: (bundle) {
        state = AsyncData(bundle);
        return true;
      },
      failure: (_) => false,
    );
  }
}

final emergencyLimitationLocaleProvider = Provider<String>((ref) {
  final locale = ref.watch(profileLocaleControllerProvider);
  return locale.languageCode;
});

final emergencyLimitationAcceptanceRequiredProvider = Provider<bool>((ref) {
  final bundle = ref.watch(emergencyLimitationProvider).valueOrNull;
  return bundle?.acceptanceRequired ?? false;
});

final emergencyLimitationContextualProvider =
    Provider.family<String?, EmergencyLimitationContext>((ref, context) {
  final bundle = ref.watch(emergencyLimitationProvider).valueOrNull;
  if (bundle == null) return null;
  return bundle.contextualFor(context, ref.watch(emergencyLimitationLocaleProvider));
});

final emergencyLimitationUrgentTextProvider = Provider<String?>((ref) {
  final bundle = ref.watch(emergencyLimitationProvider).valueOrNull;
  if (bundle == null) return null;
  return bundle.urgentForLocale(ref.watch(emergencyLimitationLocaleProvider));
});

final emergencyLimitationBannerTextProvider = Provider<String?>((ref) {
  final bundle = ref.watch(emergencyLimitationProvider).valueOrNull;
  if (bundle == null) return null;
  return bundle.bannerForLocale(ref.watch(emergencyLimitationLocaleProvider));
});
