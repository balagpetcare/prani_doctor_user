/// Semantic version helpers for force-update checks.
abstract final class VersionUtils {
  VersionUtils._();

  static List<int> parse(String version) {
    final core = version.split('+').first.trim();
    final parts = core.split('.');
    return [
      for (var i = 0; i < 3; i++)
        i < parts.length ? int.tryParse(parts[i]) ?? 0 : 0,
    ];
  }

  /// Returns `true` when [current] is strictly below [minimum].
  static bool isBelowMinimum(String current, String minimum) {
    final a = parse(current);
    final b = parse(minimum);
    for (var i = 0; i < 3; i++) {
      if (a[i] < b[i]) return true;
      if (a[i] > b[i]) return false;
    }
    return false;
  }
}
