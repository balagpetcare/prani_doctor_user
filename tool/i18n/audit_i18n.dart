// ignore_for_file: avoid_print
/// Audits bn.json quality. Run: dart run tool/i18n/audit_i18n.dart
import 'dart:convert';
import 'dart:io';

void main() {
  var root = Directory.current;
  while (!File('${root.path}/pubspec.yaml').existsSync()) {
    root = root.parent;
  }
  final bnPath = File('${root.path}/assets/i18n/bn.json');
  final enPath = File('${root.path}/assets/i18n/en.json');
  final bn = jsonDecode(bnPath.readAsStringSync()) as Map<String, dynamic>;
  final en = jsonDecode(enPath.readAsStringSync()) as Map<String, dynamic>;

  var total = 0;
  var sameAsEn = 0;
  var hasLatin = 0;
  var hasBengali = 0;
  var awkward = 0;
  final latinRe = RegExp(r'[A-Za-z]{4,}');
  final allow = {
    'English',
    'Google',
    'Facebook',
    'PraniDoctor',
    'development',
    'identifier',
  };

  final issues = <String>[];

  for (final entry in bn.entries) {
    final key = entry.key;
    if (key.startsWith('@')) continue;
    if (entry.value is! String) continue;
    total++;
    final bv = entry.value as String;
    final ev = en[key] as String?;

    if (ev != null && bv == ev) {
      sameAsEn++;
      issues.add('SAME_AS_EN|$key');
    }
    if (RegExp(r'[\u0980-\u09FF]').hasMatch(bv)) hasBengali++;
    final latin = latinRe.allMatches(bv).map((m) => m.group(0)!).where((w) {
      return !allow.contains(w) &&
          !{
            'optional',
            'identifier',
            'development',
          }.contains(w.toLowerCase());
    }).toList();
    if (latin.isNotEmpty) {
      hasLatin++;
      if (issues.length < 200) issues.add('LATIN|$key|$bv');
    }
    if (bv.contains('বাতিলled') ||
        bv.contains('যোগ করুন your') ||
        bv.contains('সংরক্ষণ করুন profile')) {
      awkward++;
    }
  }

  final bnPct = (hasBengali / total * 100).toStringAsFixed(1);
  final enLeftPct = (sameAsEn / total * 100).toStringAsFixed(1);
  final latinPct = (hasLatin / total * 100).toStringAsFixed(1);
  final completion = (100 - double.parse(enLeftPct)).toStringAsFixed(1);

  final report = StringBuffer()
    ..writeln('TOTAL_KEYS=$total')
    ..writeln('BN_SCRIPT_COVERAGE=$bnPct%')
    ..writeln('IDENTICAL_TO_EN=$sameAsEn ($enLeftPct%)')
    ..writeln('CONTAINS_LATIN_WORDS=$hasLatin ($latinPct%)')
    ..writeln('AWKWARD_PARTIAL=$awkward')
    ..writeln('ESTIMATED_COMPLETION=$completion%');

  File('${root.path}/docs/localization/.audit_metrics.txt')
      .writeAsStringSync(report.toString());
  print(report);

  File('${root.path}/docs/localization/.audit_sample_issues.txt')
      .writeAsStringSync(issues.take(80).join('\n'));
}
