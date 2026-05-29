import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/language_controller.dart';
import '../data/ai_disclaimer_dto.dart';
import '../data/ai_disclaimer_repository.dart';

final aiDisclaimerProvider =
    AsyncNotifierProvider<AiDisclaimerNotifier, AiDisclaimerBundle?>(
  AiDisclaimerNotifier.new,
);

class AiDisclaimerNotifier extends AsyncNotifier<AiDisclaimerBundle?> {
  @override
  Future<AiDisclaimerBundle?> build() async {
    final result = await ref.read(aiDisclaimerRepositoryProvider).loadDisclaimer();
    return result.when(success: (b) => b, failure: (_) => null);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result =
        await ref.read(aiDisclaimerRepositoryProvider).loadDisclaimer(forceRefresh: true);
    state = AsyncData(result.when(success: (b) => b, failure: (_) => null));
  }

  Future<bool> accept(AiDisclaimerAcceptSurface surface) async {
    final current = state.value;
    if (current == null) return false;
    final result = await ref.read(aiDisclaimerRepositoryProvider).accept(
          version: current.version,
          surface: surface,
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

final aiDisclaimerLocaleProvider = Provider<String>((ref) {
  final locale = ref.watch(profileLocaleControllerProvider);
  return locale.languageCode;
});

final aiDisclaimerBannerTextProvider = Provider<String?>((ref) {
  final bundle = ref.watch(aiDisclaimerProvider).valueOrNull;
  if (bundle == null) return null;
  return bundle.bannerForLocale(ref.watch(aiDisclaimerLocaleProvider));
});

final aiDisclaimerContextualProvider =
    Provider.family<String?, AiDisclaimerFeature>((ref, feature) {
  final bundle = ref.watch(aiDisclaimerProvider).valueOrNull;
  if (bundle == null) return null;
  return bundle.contextualFor(feature, ref.watch(aiDisclaimerLocaleProvider));
});

final aiDisclaimerAcceptanceRequiredProvider = Provider<bool>((ref) {
  final bundle = ref.watch(aiDisclaimerProvider).valueOrNull;
  return bundle?.acceptanceRequired ?? false;
});
