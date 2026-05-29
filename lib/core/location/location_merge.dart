/// Shared helpers for merging Bangladesh location fields without wiping saved data.
abstract final class LocationMerge {
  /// Uses [incoming] when non-empty; otherwise keeps [existing].
  static String? preserveExistingIfNull(String? incoming, String? existing) {
    if (incoming != null && incoming.trim().isNotEmpty) {
      return incoming.trim();
    }
    if (existing != null && existing.trim().isNotEmpty) {
      return existing.trim();
    }
    return null;
  }
}
