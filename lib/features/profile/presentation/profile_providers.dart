import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/network_errors.dart';
import '../data/mobile_me_dto.dart';
import '../data/profile_repository.dart';

final mobileMeProvider =
    AsyncNotifierProvider<MobileMeNotifier, MobileMeDto?>(MobileMeNotifier.new);

class MobileMeNotifier extends AsyncNotifier<MobileMeDto?> {
  @override
  Future<MobileMeDto?> build() async {
    final result = await ref.read(profileRepositoryProvider).getMe();
    return result.when(
      success: (data) => data,
      failure: (_) => null,
    );
  }

  Future<String?> save(PatchMobileMeInput input) async {
    final result = await ref.read(profileRepositoryProvider).patchMe(input);
    return result.when(
      success: (data) {
        state = AsyncData(data);
        return null;
      },
      failure: (error) {
        if (error.code == offlineQueuedCode) {
          return null;
        }
        return error.message;
      },
    );
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
  }
}
