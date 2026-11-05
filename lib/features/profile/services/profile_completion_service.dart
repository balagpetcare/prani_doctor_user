import 'package:flutter/foundation.dart';

import '../data/mobile_me_dto.dart';

/// Result of evaluating whether the user has finished required profile setup.
class ProfileCompletionStatus {
  const ProfileCompletionStatus({
    required this.profileCompleted,
    required this.hasDisplayName,
    required this.hasUnion,
    required this.hasVillage,
    required this.source,
  });

  final bool profileCompleted;
  final bool hasDisplayName;
  final bool hasUnion;
  final bool hasVillage;
  final ProfileCompletionSource source;

  static const incomplete = ProfileCompletionStatus(
    profileCompleted: false,
    hasDisplayName: false,
    hasUnion: false,
    hasVillage: false,
    source: ProfileCompletionSource.unknown,
  );
}

enum ProfileCompletionSource { server, cache, reconciled, unknown }

/// Central rules for profile / farm location onboarding gates.
///
/// Required: [MobileMeDto.name] (full name) + [MobileMeAddressDto.unionId].
/// Village (id or free-text name) is optional and never blocks completion.
abstract final class ProfileCompletionService {
  ProfileCompletionService._();

  static void _log(String tag, String message) {
    if (kDebugMode) debugPrint('[$tag] $message');
  }

  static ProfileCompletionStatus evaluate(
    MobileMeDto? profile, {
    ProfileCompletionSource source = ProfileCompletionSource.unknown,
  }) {
    if (profile == null) {
      _log(
        'PROFILE_COMPLETION_CHECK',
        'profile=null completed=false source=$source',
      );
      return ProfileCompletionStatus.incomplete.copyWithSource(source);
    }

    final hasDisplayName = profile.name.trim().isNotEmpty;
    final unionId = profile.address?.unionId?.trim();
    final hasUnion = unionId != null && unionId.isNotEmpty;
    final villageId = profile.address?.villageId?.trim();
    final villageName = profile.address?.villageName?.trim();
    final hasVillage =
        (villageId != null && villageId.isNotEmpty) ||
        (villageName != null && villageName.isNotEmpty);

    final completed = hasDisplayName && hasUnion;

    _log(
      'PROFILE_COMPLETION_CHECK',
      'completed=$completed name=$hasDisplayName union=$hasUnion '
      'unionId=${unionId ?? 'null'} village=$hasVillage source=$source',
    );

    return ProfileCompletionStatus(
      profileCompleted: completed,
      hasDisplayName: hasDisplayName,
      hasUnion: hasUnion,
      hasVillage: hasVillage,
      source: source,
    );
  }

  /// Logs saved / restored location identifiers for debugging persistence.
  static void logLocationSetupStatus({
    required String phase,
    MobileMeDto? profile,
    MobileMeAddressDto? address,
  }) {
    final addr = address ?? profile?.address;
    _log(
      'LOCATION_SETUP_STATUS',
      'phase=$phase union=${addr?.unionId ?? 'null'} '
      'villageId=${addr?.villageId ?? 'null'} '
      'villageName=${addr?.villageName ?? 'null'} '
      'area=${profile?.area ?? 'null'}',
    );
  }

  /// Logs navigation / onboarding routing decisions.
  static void logOnboardingDecision({
    required String decision,
    required ProfileCompletionStatus status,
    String? route,
  }) {
    _log(
      'ONBOARDING_DECISION',
      'decision=$decision completed=${status.profileCompleted} '
      'route=${route ?? 'null'} source=${status.source}',
    );
  }

  /// Server profile is authoritative for completion-critical fields (name, union).
  /// Cached address may only fill optional display gaps (village, line1, etc.).
  static MobileMeDto reconcileWithServer({
    required MobileMeDto server,
    MobileMeDto? cachedProfile,
    MobileMeAddressDto? cachedAddress,
  }) {
    final cachedAddr =
        cachedAddress ?? cachedProfile?.address;
    if (cachedAddr == null) {
      logLocationSetupStatus(phase: 'reconcile-server-only', profile: server);
      return server;
    }

    final serverStatus = evaluate(server, source: ProfileCompletionSource.server);
    final merged = server.mergeAddress(cachedAddr);
    final mergedStatus = evaluate(
      merged,
      source: ProfileCompletionSource.reconciled,
    );

    if (serverStatus.profileCompleted != mergedStatus.profileCompleted) {
      _log(
        'PROFILE_COMPLETION_CHECK',
        'cache/server mismatch — trusting server '
        'serverCompleted=${serverStatus.profileCompleted} '
        'mergedCompleted=${mergedStatus.profileCompleted}',
      );
      logLocationSetupStatus(phase: 'reconcile-trust-server', profile: server);
      return server;
    }

    logLocationSetupStatus(phase: 'reconcile-merged', profile: merged);
    return merged;
  }

  /// Whether onboarding / profile setup should be skipped.
  static bool shouldBypassOnboarding(MobileMeDto? profile) {
    return evaluate(profile).profileCompleted;
  }
}

extension _ProfileCompletionStatusCopy on ProfileCompletionStatus {
  ProfileCompletionStatus copyWithSource(ProfileCompletionSource source) {
    return ProfileCompletionStatus(
      profileCompleted: profileCompleted,
      hasDisplayName: hasDisplayName,
      hasUnion: hasUnion,
      hasVillage: hasVillage,
      source: source,
    );
  }
}
