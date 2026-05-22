import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/network_errors.dart';
import '../data/mobile_me_dto.dart';
import '../data/profile_repository.dart';
import 'profile_locale_controller.dart';

final mobileMeProvider =
    AsyncNotifierProvider<MobileMeNotifier, MobileMeDto?>(MobileMeNotifier.new);

class MobileMeNotifier extends AsyncNotifier<MobileMeDto?> {
  bool _reloadInFlight = false;

  @override
  Future<MobileMeDto?> build() async {
    final result = await ref.read(profileRepositoryProvider).getMe();
    final profile = result.when(
      success: (data) {
        ref.read(profileLocaleControllerProvider.notifier).syncFromProfile(data.locale);
        return data;
      },
      failure: (_) => null,
    );
    return profile;
  }

  Future<String?> save(PatchMobileMeInput input) async {
    final result = await ref.read(profileRepositoryProvider).patchMe(input);
    return result.when(
      success: (data) {
        state = AsyncData(data);
        if (input.locale != null) {
          ref.read(profileLocaleControllerProvider.notifier).syncFromProfile(input.locale!);
        }
        return null;
      },
      failure: (error) {
        if (error.code == offlineQueuedCode) {
          final optimistic = error.cause;
          if (optimistic is MobileMeDto) {
            state = AsyncData(optimistic);
          }
          return null;
        }
        return error.message;
      },
    );
  }

  Future<String?> uploadAvatar(String filePath) async {
    final result =
        await ref.read(profileRepositoryProvider).uploadProfilePhoto(filePath);
    return result.when(
      success: (url) {
        final current = state.value;
        if (current != null) {
          state = AsyncData(current.copyWith(profilePhotoUrl: url));
        } else {
          reload();
        }
        return null;
      },
      failure: (error) => error.message,
    );
  }

  Future<void> reload({bool forceRefresh = false}) async {
    if (_reloadInFlight) return;
    _reloadInFlight = true;
    state = const AsyncLoading();
    try {
      final result =
          await ref.read(profileRepositoryProvider).getMe(forceRefresh: forceRefresh);
      final profile = result.when(success: (data) {
        ref.read(profileLocaleControllerProvider.notifier).syncFromProfile(data.locale);
        return data;
      }, failure: (_) => null);
      state = AsyncData(profile);
    } finally {
      _reloadInFlight = false;
    }
  }
}

/// Applies profile locale to MaterialApp when available.
final profileLocaleControllerProvider =
    StateNotifierProvider<ProfileLocaleController, Locale?>((ref) {
  return ProfileLocaleController();
});
