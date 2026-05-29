import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/language_controller.dart';
import '../data/ai_escalation_disclosure_dto.dart';
import '../data/ai_escalation_disclosure_repository.dart';

final aiEscalationDisclosureProvider =
    AsyncNotifierProvider<AiEscalationDisclosureNotifier, AiEscalationDisclosureBundle?>(
  AiEscalationDisclosureNotifier.new,
);

class AiEscalationDisclosureNotifier extends AsyncNotifier<AiEscalationDisclosureBundle?> {
  @override
  Future<AiEscalationDisclosureBundle?> build() async {
    final result = await ref.read(aiEscalationDisclosureRepositoryProvider).load();
    return result.when(success: (b) => b, failure: (_) => null);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result =
        await ref.read(aiEscalationDisclosureRepositoryProvider).load(forceRefresh: true);
    state = AsyncData(result.when(success: (b) => b, failure: (_) => null));
  }
}

final aiEscalationDisclosureLocaleProvider = Provider<String>((ref) {
  return ref.watch(profileLocaleControllerProvider).languageCode;
});

final aiEscalationDisclosureBannerProvider = Provider<String?>((ref) {
  final bundle = ref.watch(aiEscalationDisclosureProvider).valueOrNull;
  if (bundle == null) return null;
  return bundle.bannerForLocale(ref.watch(aiEscalationDisclosureLocaleProvider));
});

String? resolveEscalationDisclosureText(
  WidgetRef ref, {
  required AiEscalationDisclosureTrigger? trigger,
  String? apiDisclosure,
}) {
  if (apiDisclosure != null && apiDisclosure.isNotEmpty) return apiDisclosure;
  if (trigger == null) return null;
  final bundle = ref.watch(aiEscalationDisclosureProvider).valueOrNull;
  if (bundle == null) return null;
  return bundle.textFor(trigger, ref.watch(aiEscalationDisclosureLocaleProvider));
}

String? resolveSupportVsVetNote(WidgetRef ref) {
  final bundle = ref.watch(aiEscalationDisclosureProvider).valueOrNull;
  if (bundle == null) return null;
  return bundle.textFor(
    AiEscalationDisclosureTrigger.supportVsVet,
    ref.watch(aiEscalationDisclosureLocaleProvider),
  );
}

String? resolveKeywordLimitationNote(WidgetRef ref) {
  final bundle = ref.watch(aiEscalationDisclosureProvider).valueOrNull;
  if (bundle == null) return null;
  return bundle.textFor(
    AiEscalationDisclosureTrigger.keywordLimitation,
    ref.watch(aiEscalationDisclosureLocaleProvider),
  );
}
