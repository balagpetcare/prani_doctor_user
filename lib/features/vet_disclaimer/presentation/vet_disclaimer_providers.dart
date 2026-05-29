import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/language_controller.dart';
import '../data/vet_disclaimer_dto.dart';
import '../data/vet_disclaimer_repository.dart';

final vetDisclaimerProvider =
    AsyncNotifierProvider<VetDisclaimerNotifier, VetDisclaimerBundle?>(
  VetDisclaimerNotifier.new,
);

class VetDisclaimerNotifier extends AsyncNotifier<VetDisclaimerBundle?> {
  @override
  Future<VetDisclaimerBundle?> build() async {
    final result = await ref.read(vetDisclaimerRepositoryProvider).loadDisclaimer();
    return result.when(success: (b) => b, failure: (_) => null);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result =
        await ref.read(vetDisclaimerRepositoryProvider).loadDisclaimer(forceRefresh: true);
    state = AsyncData(result.when(success: (b) => b, failure: (_) => null));
  }

  Future<bool> accept(
    VetDisclaimerAcceptSurface surface, {
    String? serviceRequestId,
  }) async {
    final current = state.value;
    if (current == null) return false;
    final result = await ref.read(vetDisclaimerRepositoryProvider).accept(
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

final vetDisclaimerLocaleProvider = Provider<String>((ref) {
  final locale = ref.watch(profileLocaleControllerProvider);
  return locale.languageCode;
});

final vetDisclaimerAcceptanceRequiredProvider = Provider<bool>((ref) {
  final bundle = ref.watch(vetDisclaimerProvider).valueOrNull;
  return bundle?.acceptanceRequired ?? false;
});

final vetDisclaimerContextualProvider =
    Provider.family<String?, VetDisclaimerContext>((ref, context) {
  final bundle = ref.watch(vetDisclaimerProvider).valueOrNull;
  if (bundle == null) return null;
  return bundle.contextualFor(context, ref.watch(vetDisclaimerLocaleProvider));
});

final vetDisclaimerBannerTextProvider = Provider<String?>((ref) {
  final bundle = ref.watch(vetDisclaimerProvider).valueOrNull;
  if (bundle == null) return null;
  return bundle.bannerForLocale(ref.watch(vetDisclaimerLocaleProvider));
});

final vetDisclaimerEmergencyTextProvider = Provider<String?>((ref) {
  final bundle = ref.watch(vetDisclaimerProvider).valueOrNull;
  if (bundle == null) return null;
  return bundle.emergencyForLocale(ref.watch(vetDisclaimerLocaleProvider));
});
