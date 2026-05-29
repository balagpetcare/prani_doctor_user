/// Interpolates `{name}` placeholders in JSON translation templates.
abstract final class LocalizationFormat {
  static String format(String template, [Map<String, Object?>? args]) {
    if (args == null || args.isEmpty) return template;
    var result = template;
    for (final entry in args.entries) {
      result = result.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return result;
  }
}
