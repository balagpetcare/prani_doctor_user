// ignore_for_file: avoid_print
/// Converts lib/l10n/app_en.arb → assets/i18n/*.json and generates Dart l10n.
///
/// Run: dart run tool/i18n/build_localization.dart
import 'dart:convert';
import 'dart:io';

import 'bn_translate.dart';

void main() {
  final root = _findProjectRoot();
  final arbPath = File('${root.path}/lib/l10n/app_en.arb');
  if (!arbPath.existsSync()) {
    stderr.writeln('Missing ${arbPath.path}');
    exit(1);
  }

  final arb = jsonDecode(arbPath.readAsStringSync()) as Map<String, dynamic>;
  final entries = <String, String>{};
  final placeholders = <String, Map<String, String>>{};

  for (final entry in arb.entries) {
    final key = entry.key;
    if (key.startsWith('@@') || key.startsWith('@')) continue;
    if (entry.value is! String) continue;
    final value = entry.value as String;
    entries[key] = value;
    final inline = RegExp(r'\{(\w+)\}').allMatches(value);
    if (inline.isNotEmpty && !placeholders.containsKey(key)) {
      placeholders[key] = {
        for (final m in inline) m.group(1)!: 'Object',
      };
    }
  }

  for (final entry in arb.entries) {
    final key = entry.key;
    if (!key.startsWith('@') || key.startsWith('@@')) continue;
    final name = key.substring(1);
    final meta = entry.value;
    if (meta is! Map) continue;
    final ph = meta['placeholders'];
    if (ph is Map) {
      placeholders[name] = ph.map(
        (k, v) => MapEntry(k.toString(), (v as Map)['type']?.toString() ?? 'Object'),
      );
    }
  }

  final enDir = Directory('${root.path}/assets/i18n');
  enDir.createSync(recursive: true);

  final enJson = Map<String, dynamic>.from(entries);
  for (final e in placeholders.entries) {
    enJson['@${e.key}'] = {'placeholders': e.value};
  }

  File('${enDir.path}/en.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(enJson),
  );

  final bnEntries = <String, String>{};
  for (final e in entries.entries) {
    bnEntries[e.key] = _translateToBn(e.key, e.value);
  }
  _finishingPass(root, bnEntries, entries);

  final bnJson = Map<String, dynamic>.from(bnEntries);
  for (final e in placeholders.entries) {
    bnJson['@${e.key}'] = {'placeholders': e.value};
  }

  File('${enDir.path}/bn.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(bnJson),
  );

  _appendApiAndErrorKeys(enDir);
  final allKeys = {...entries.keys, ..._errorKeys.keys}.toList()..sort();

  _writeTranslationKeys(root, allKeys);
  _writeAppLocalizationsBase(root);
  _writeAppLocalizationsImpl(root, entries, placeholders);

  print('Generated ${entries.length} keys → assets/i18n/{en,bn}.json');
}

void _writeAppLocalizationsBase(Directory root) {
  final source = File('${root.path}/lib/l10n/app_localizations.dart');
  if (!source.existsSync()) {
    stderr.writeln('Run flutter gen-l10n once before build_localization.');
    return;
  }
  final lines = source.readAsLinesSync();
  final end = lines.indexWhere((l) => l.startsWith('class _AppLocalizationsDelegate'));
  if (end < 0) {
    stderr.writeln('Could not find delegate in app_localizations.dart');
    return;
  }
  final head = lines.sublist(0, end).join('\n');
  var patched = head.replaceFirst(
    "import 'app_localizations_en.dart';",
    "import 'generated/app_localizations_impl.dart';",
  );
  patched = patched.replaceFirst(
    'abstract class AppLocalizations {\n  AppLocalizations(String locale)\n    : localeName = intl.Intl.canonicalizedLocale(locale.toString());\n\n  final String localeName;',
    '''
abstract class AppLocalizations {
  AppLocalizations(this._localeCode)
      : localeName = intl.Intl.canonicalizedLocale(_localeCode);

  final String _localeCode;

  /// BCP-47 language code (`bn`, `en`).
  String get localeCode => _localeCode;

  final String localeName;

  @protected
  String tr(String key, [Map<String, Object?>? args]) => LocalizationFormat.format(
        LocalizationLoader.lookup(_localeCode, key),
        args,
      );

  /// Maps API error [code] to localized text; falls back to [code] if unknown.
  String apiError(String code) {
    final normalized = code.trim();
    if (normalized.isEmpty) return tr('errorGeneric');
    final key = 'api_error_\${normalized.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_')}';
    final value = tr(key);
    if (value != key) return value;
    return tr('errorGeneric');
  }

  String get errorGeneric => tr('errorGeneric');
  String get errorGenericTitle => tr('errorGenericTitle');
  String get errorSessionExpiredTitle => tr('errorSessionExpiredTitle');
  String get errorPermissionDeniedTitle => tr('errorPermissionDeniedTitle');
  String get errorNotFoundTitle => tr('errorNotFoundTitle');
  String get errorSettingsUnavailableTitle => tr('errorSettingsUnavailableTitle');
  String get errorServiceUnavailableTitle => tr('errorServiceUnavailableTitle');
  String get errorServerTitle => tr('errorServerTitle');
  String get errorNetworkTitle => tr('errorNetworkTitle');
  String get errorSettingsLoadTitle => tr('errorSettingsLoadTitle');
''',
  );
  if (!patched.contains('import \'localization_loader.dart\';')) {
    patched = patched.replaceFirst(
      "import 'generated/app_localizations_impl.dart';",
      "import 'generated/app_localizations_impl.dart';\nimport 'localization_loader.dart';\nimport 'localization_format.dart';",
    );
  }

  File('${root.path}/lib/core/localization/app_localizations_base.dart')
      .writeAsStringSync('$patched\n');
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  while (!File('${dir.path}/pubspec.yaml').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not find pubspec.yaml');
    }
    dir = parent;
  }
  return dir;
}

String _translateToBn(String key, String en) {
  final curated = lookupCuratedBn(key, en);
  if (curated != null) return polishBn(curated);

  final legacy = _keyOverrides[key];
  if (legacy != null) return polishBn(legacy);

  if (key.endsWith('Bn') && _containsBengali(en)) return en;

  for (final entry in _phraseOverrides.entries) {
    if (en == entry.key) return polishBn(entry.value);
  }

  var result = en;
  final sortedPhrases = _phraseOverrides.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final phrase in sortedPhrases) {
    result = result.replaceAll(phrase, _phraseOverrides[phrase]!);
  }

  final secondPass = lookupCuratedBn(key, result);
  if (secondPass != null) return polishBn(secondPass);

  if (_containsBengali(result)) return polishBn(result);
  return polishBn(result);
}

bool _containsBengali(String s) => RegExp(r'[\u0980-\u09FF]').hasMatch(s);

void _finishingPass(
  Directory root,
  Map<String, String> bnEntries,
  Map<String, String> enEntries,
) {
  for (final e in enEntries.entries) {
    final current = bnEntries[e.key]!;
    final needsWork = current == e.value ||
        !_containsBengali(current) ||
        RegExp(r'[A-Za-z]{5,}').hasMatch(current);
    if (needsWork) {
      final forced = forceTranslateBn(e.key, e.value);
      // Avoid mixed garbage: only use force pass if it adds Bengali script.
      if (_containsBengali(forced)) {
        bnEntries[e.key] = forced;
      }
    }
  }
  final curatedFile = File('${root.path}/assets/i18n/bn_curated.json');
  if (curatedFile.existsSync()) {
    final curated = jsonDecode(curatedFile.readAsStringSync()) as Map<String, dynamic>;
    for (final e in curated.entries) {
      if (e.key.startsWith('@') || e.value is! String) continue;
      bnEntries[e.key] = e.value as String;
    }
  }
}

void _writeTranslationKeys(Directory root, List<String> keys) {
  final buf = StringBuffer('''
// GENERATED by tool/i18n/build_localization.dart — do not edit by hand.

/// Stable translation key constants for dynamic lookup.
abstract final class TranslationKeys {
  TranslationKeys._();
''');

  for (final key in keys) {
    buf.writeln("  static const String $key = '$key';");
  }
  buf.writeln('}');

  File('${root.path}/lib/core/localization/translation_keys.dart')
      .writeAsStringSync(buf.toString());
}

void _writeAppLocalizationsImpl(
  Directory root,
  Map<String, String> entries,
  Map<String, Map<String, String>> placeholders,
) {
  final buf = StringBuffer('''
// GENERATED by tool/i18n/build_localization.dart — do not edit by hand.

import '../app_localizations_base.dart';

''');

  for (final locale in ['en', 'bn']) {
    final className = locale == 'en' ? 'AppLocalizationsEn' : 'AppLocalizationsBn';
    buf.writeln('class $className extends AppLocalizations {');
    buf.writeln("  $className() : super('$locale');");
    buf.writeln();

    for (final key in entries.keys) {
      final ph = placeholders[key];
      if (ph == null || ph.isEmpty) {
        buf.writeln("  @override");
        buf.writeln("  String get $key => tr('$key');");
        buf.writeln();
      } else {
        final params = ph.entries
            .map((e) => '${_dartType(e.value)} ${e.key}')
            .join(', ');
        final mapArgs = ph.keys.map((p) => "'$p': $p").join(', ');
        buf.writeln('  @override');
        buf.writeln('  String $key($params) => tr("$key", {$mapArgs});');
        buf.writeln();
      }
    }
    buf.writeln('}');
    buf.writeln();
  }

  final genDir = Directory('${root.path}/lib/core/localization/generated');
  genDir.createSync(recursive: true);
  File('${genDir.path}/app_localizations_impl.dart').writeAsStringSync(buf.toString());
}

String _dartType(String arbType) {
  return switch (arbType) {
    'int' => 'int',
    'double' => 'double',
    'String' => 'String',
    _ => 'Object',
  };
}

void _appendApiAndErrorKeys(Directory enDir) {
  for (final file in ['en.json', 'bn.json']) {
    final path = File('${enDir.path}/$file');
    final isBn = file.startsWith('bn');
    final map = jsonDecode(path.readAsStringSync()) as Map<String, dynamic>;
    for (final entry in _errorKeys.entries) {
      map[entry.key] = isBn ? entry.value.bn : entry.value.en;
    }
    path.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(map));
  }
}

class _ErrorPair {
  const _ErrorPair({required this.en, required this.bn});
  final String en;
  final String bn;
}

const _errorKeys = <String, _ErrorPair>{
  'errorGeneric': _ErrorPair(
    en: 'Something went wrong',
    bn: 'সমস্যা হয়েছে',
  ),
  'errorGenericTitle': _ErrorPair(en: 'Something went wrong', bn: 'সমস্যা হয়েছে'),
  'errorSessionExpiredTitle': _ErrorPair(
    en: 'Session expired',
    bn: 'সময় শেষ',
  ),
  'errorPermissionDeniedTitle': _ErrorPair(
    en: 'Permission denied',
    bn: 'অনুমতি নেই',
  ),
  'errorNotFoundTitle': _ErrorPair(en: 'Not found', bn: 'খুঁজে পাওয়া যায়নি'),
  'errorSettingsUnavailableTitle': _ErrorPair(
    en: 'Settings unavailable',
    bn: 'সেটিংস পাওয়া যায়নি',
  ),
  'errorServiceUnavailableTitle': _ErrorPair(
    en: 'Service unavailable',
    bn: 'সেবা চালু নেই',
  ),
  'errorServerTitle': _ErrorPair(en: 'Server problem', bn: 'সার্ভার সমস্যা'),
  'errorNetworkTitle': _ErrorPair(en: 'Network problem', bn: 'ইন্টারনেট সমস্যা'),
  'errorSettingsLoadTitle': _ErrorPair(
    en: 'Unable to load settings',
    bn: 'সেটিংস লোড হয়নি',
  ),
  'api_error_USER_NOT_FOUND': _ErrorPair(
    en: 'User not found',
    bn: 'ব্যবহারকারী খুঁজে পাওয়া যায়নি',
  ),
  'api_error_NETWORK_ERROR': _ErrorPair(
    en: 'Check your internet connection',
    bn: 'ইন্টারনেট সংযোগ পরীক্ষা করুন',
  ),
  'api_error_OFFLINE': _ErrorPair(
    en: 'You are offline',
    bn: 'আপনি অফলাইনে আছেন',
  ),
  'inventoryTitle': _ErrorPair(en: 'Stock', bn: 'মজুদ'),
  'inventoryFarmOverview': _ErrorPair(
    en: 'Farm stock overview',
    bn: 'খামারের মজুদ সংক্ষেপ',
  ),
  'inventorySections': _ErrorPair(en: 'Sections', bn: 'অংশ'),
  'inventoryDailyFeedHint': _ErrorPair(
    en:
        'Daily feed logging is under Farm → Feed entry. Stock updates when you deduct from inventory.',
    bn:
        'প্রতিদিনের খাদ্য তথ্য খামার → খাদ্য এন্ট্রি থেকে দিন। মজুদ থেকে খাওয়ানো লিখলে স্টক আপডেট হয়।',
  ),
  'inventorySelectFarmFirst': _ErrorPair(
    en: 'Select a farm first',
    bn: 'আগে খামার বেছে নিন',
  ),
  'inventoryFeedStock': _ErrorPair(en: 'Feed stock', bn: 'খাদ্য মজুদ'),
  'inventoryMedicineStock': _ErrorPair(en: 'Medicine stock', bn: 'ওষুধ মজুদ'),
  'inventoryAddFeed': _ErrorPair(en: 'Add feed', bn: 'খাদ্য যোগ করুন'),
  'inventoryAddMedicine': _ErrorPair(en: 'Add medicine', bn: 'ওষুধ যোগ করুন'),
  'inventoryGoToFarms': _ErrorPair(en: 'Go to farms', bn: 'খামারে যান'),
  'inventoryNoFarmHint': _ErrorPair(
    en: 'Add a farm to manage feed and medicine stock.',
    bn: 'খাদ্য ও ওষুধ মজুদের জন্য আগে খামার যোগ করুন।',
  ),
  'inventoryFeedItem': _ErrorPair(en: 'Feed item', bn: 'খাদ্য আইটেম'),
  'inventoryMedicineItem': _ErrorPair(en: 'Medicine item', bn: 'ওষুধ আইটেম'),
  'inventoryItemNotFound': _ErrorPair(en: 'Item not found', bn: 'খুঁজে পাওয়া যায়নি'),
  'inventoryAddStock': _ErrorPair(en: 'Add stock', bn: 'মজুদ যোগ করুন'),
  'inventoryLogFeeding': _ErrorPair(
    en: 'Log feeding (deduct stock)',
    bn: 'খাওয়ানো লিখুন',
  ),
  'inventoryRecordPurchase': _ErrorPair(
    en: 'Record purchase',
    bn: 'কেনাকাটা লিখুন',
  ),
  'inventoryConsumptionHistory': _ErrorPair(
    en: 'Feeding history',
    bn: 'খাওয়ানোর তালিকা',
  ),
  'inventoryNoFeedingLogs': _ErrorPair(
    en: 'No feeding logs yet.',
    bn: 'এখনো খাওয়ানোর তথ্য নেই।',
  ),
  'inventoryLogFeed': _ErrorPair(en: 'Log feed', bn: 'খাওয়ানো লিখুন'),
  'inventoryAddFeedToStock': _ErrorPair(
    en: 'Add feed to stock',
    bn: 'মজুদে খাদ্য যোগ করুন',
  ),
  'inventoryCurrentStock': _ErrorPair(en: 'Current stock', bn: 'বর্তমান মজুদ'),
  'inventoryLowStock': _ErrorPair(en: 'Low stock', bn: 'মজুদ কম'),
  'inventoryConsumptionHistoryMenu': _ErrorPair(
    en: 'Feeding history',
    bn: 'খাওয়ানোর তালিকা',
  ),
  'inventoryCachedStockHint': _ErrorPair(
    en: 'Showing saved stock. Connect to refresh.',
    bn: 'সংরক্ষিত মজুদ দেখানো হচ্ছে। আপডেট করতে ইন্টারনেট চালু করুন।',
  ),
  'inventoryReserved': _ErrorPair(en: 'Reserved', bn: 'সংরক্ষিত'),
  'inventorySelectFeedFromList': _ErrorPair(
    en: 'Choose feed from the list',
    bn: 'তালিকা থেকে একটি খাদ্য বেছে নিন',
  ),
  'inventoryNameRequired': _ErrorPair(en: 'Name is required', bn: 'নাম প্রয়োজন'),
  'inventoryFromList': _ErrorPair(en: 'From list', bn: 'তালিকা থেকে'),
  'inventoryCustomFeed': _ErrorPair(en: 'Custom feed', bn: 'নিজের খাদ্য'),
  'inventoryListLoadFailed': _ErrorPair(
    en: 'Could not load list',
    bn: 'তালিকা লোড হয়নি',
  ),
  'inventorySearch': _ErrorPair(en: 'Search', bn: 'খুঁজুন'),
  'fatteningCachedDataHint': _ErrorPair(
    en: 'Showing saved data — connect to sync',
    bn: 'সংরক্ষিত তথ্য দেখানো হচ্ছে। আপডেট করতে ইন্টারনেট চালু করুন।',
  ),
  'fatteningOpenCached': _ErrorPair(en: 'Open cached', bn: 'সংরক্ষিত দেখুন'),
  'fatteningNoBatchesYet': _ErrorPair(
    en: 'No fattening batches yet',
    bn: 'এখনো কোনো ফ্যাটেনিং ব্যাচ নেই',
  ),
  'Dismiss': _ErrorPair(en: 'Dismiss', bn: 'বন্ধ করুন'),
  'Refresh': _ErrorPair(en: 'Refresh', bn: 'আপডেট করুন'),
  'fatteningAnimalsAdded': _ErrorPair(
    en: 'Animals added to batch',
    bn: 'ব্যাচে পশু যোগ হয়েছে',
  ),
  'fatteningFeedLogged': _ErrorPair(
    en: 'Feed logged',
    bn: 'খাদ্যের তথ্য সংরক্ষিত',
  ),
  'settingsProfileAppearance': _ErrorPair(
    en: 'Profile appearance',
    bn: 'প্রোফাইল ছবি ও নাম',
  ),
  'settingsProfileAppearanceHint': _ErrorPair(
    en: 'Photo, cover, display name',
    bn: 'ছবি, কভার, দেখানোর নাম',
  ),
  'settingsPersonalInfo': _ErrorPair(
    en: 'Personal information',
    bn: 'ব্যক্তিগত তথ্য',
  ),
  'settingsPersonalInfoHint': _ErrorPair(
    en: 'Email and phone',
    bn: 'ইমেইল ও মোবাইল',
  ),
  'uploadCamera': _ErrorPair(en: 'Camera', bn: 'ক্যামেরা'),
  'uploadGallery': _ErrorPair(en: 'Gallery', bn: 'গ্যালারি'),
  'uploadComplete': _ErrorPair(en: 'Upload complete', bn: 'আপলোড সম্পন্ন'),
  'uploadCancelled': _ErrorPair(en: 'Upload cancelled', bn: 'আপলোড বাতিল'),
  'searchAiAssistant': _ErrorPair(en: 'AI assistant', bn: 'এআই সহকারী'),
  'searchAiSubtitle': _ErrorPair(
    en: 'Ask about animal health',
    bn: 'পশুর স্বাস্থ্য সম্পর্কে জিজ্ঞেস করুন',
  ),
  'searchMarketplace': _ErrorPair(en: 'Marketplace', bn: 'বাজার'),
  'searchMarketplaceSubtitle': _ErrorPair(
    en: 'Services and offers',
    bn: 'সেবা ও অফার',
  ),
  'searchReports': _ErrorPair(en: 'Reports', bn: 'হিসাব'),
  'searchReportsSubtitle': _ErrorPair(
    en: 'Health records and reports',
    bn: 'স্বাস্থ্য তথ্য ও রিপোর্ট',
  ),
  'searchEmergency': _ErrorPair(en: 'Emergency', bn: 'জরুরি'),
  'searchEmergencySubtitle': _ErrorPair(
    en: 'Emergency doctors and services',
    bn: 'জরুরি ডাক্তার ও সেবা',
  ),
  'animalCreateTitle': _ErrorPair(
    en: 'Add animal',
    bn: 'নতুন পশু যোগ করুন',
  ),
  'addImage': _ErrorPair(en: 'Add photo', bn: 'ছবি দিন'),
  'chooseCategory': _ErrorPair(en: 'Choose type', bn: 'ধরন বেছে নিন'),
  'locationPermission': _ErrorPair(
    en: 'Allow location access',
    bn: 'অবস্থান ব্যবহারের অনুমতি দিন',
  ),
};

const _keyOverrides = <String, String>{
  'languageTitle': 'ভাষা',
  'languageBangla': 'বাংলা',
  'languageEnglish': 'English',
  'appTitle': 'প্রাণী ডাক্তার',
  'navHome': 'হোম',
  'navServices': 'সেবা',
  'navInbox': 'ইনবক্স',
  'navSettings': 'সেটিংস',
  'loginTitle': 'প্রবেশ করুন',
  'registerTitle': 'নতুন অ্যাকাউন্ট খুলুন',
  'cancel': 'বাতিল',
  'save': 'সংরক্ষণ করুন',
  'retry': 'আবার চেষ্টা করুন',
  'loading': 'লোড হচ্ছে',
  'profileTitle': 'প্রোফাইল',
  'offlineModeBanner': 'অফলাইন মোড — সর্বশেষ সংরক্ষিত তথ্য দেখানো হচ্ছে',
  'homeGreetingMorningBn': 'সুপ্রভাত',
  'homeGreetingAfternoonBn': 'শুভ অপরাহ্ন',
  'homeGreetingEveningBn': 'শুভ সন্ধ্যা',
  'homeUniversalSearchHint': 'ডাক্তার, সেবা, AI, চিকিৎসা সার্চ করুন',
};

const _phraseOverrides = <String, String>{
  'PraniDoctor': 'প্রাণী ডাক্তার',
  'Home': 'হোম',
  'Services': 'সেবা',
  'Inbox': 'ইনবক্স',
  'Settings': 'সেটিংস',
  'Menu': 'মেনু',
  'Farm': 'খামার',
  'Profile': 'প্রোফাইল',
  'Language': 'ভাষা',
  'Bangla': 'বাংলা',
  'English': 'English',
  'Login': 'প্রবেশ করুন',
  'Log in': 'প্রবেশ করুন',
  'Sign up': 'নতুন অ্যাকাউন্ট খুলুন',
  'Save': 'সংরক্ষণ করুন',
  'Cancel': 'বাতিল',
  'Delete': 'মুছে ফেলুন',
  'Edit': 'সম্পাদনা',
  'Add': 'যোগ করুন',
  'Retry': 'আবার চেষ্টা করুন',
  'Try again': 'আবার চেষ্টা করুন',
  'Loading': 'লোড হচ্ছে',
  'Pending': 'অপেক্ষমাণ',
  'Completed': 'সম্পন্ন',
  'Error': 'সমস্যা হয়েছে',
  'Something went wrong': 'সমস্যা হয়েছে',
  'OK': 'ঠিক আছে',
  'Continue': 'এগিয়ে যান',
  'Back': 'পিছনে',
  'Next': 'পরের ধাপ',
  'Animal': 'পশু',
  'Animals': 'পশু',
  'Cow': 'গরু',
  'Doctor': 'ডাক্তার',
  'Appointment': 'সেবা বুকিং',
  'Notification': 'বার্তা',
  'Notifications': 'বার্তা',
  'Offline': 'অফলাইন',
  'Online': 'অনলাইন',
  'Password': 'পাসওয়ার্ড',
  'Email': 'ইমেইল',
  'Phone': 'মোবাইল',
  'OTP': 'ওটিপি',
  'Camera': 'ক্যামেরা',
  'Gallery': 'গ্যালারি',
  'Location': 'লোকেশন',
  'Search': 'খুঁজুন',
  'Inventory': 'মজুদ',
  'Feed': 'খাদ্য',
  'Medicine': 'ওষুধ',
  'Treatment': 'চিকিৎসা',
  'Vaccine': 'টিকা',
  'Milk': 'দুধ',
  'No results': 'কিছু পাওয়া যায়নি',
  'No data': 'এখনো কোনো তথ্য নেই',
  'Failed': 'কাজ সম্পন্ন হয়নি',
  'Upload failed': 'ছবি পাঠানো যায়নি',
  'Upload complete': 'আপলোড সম্পন্ন',
  'Upload cancelled': 'আপলোড বাতিল',
  'Dismiss': 'বন্ধ করুন',
  'Refresh': 'আপডেট করুন',
  'Create account': 'নতুন অ্যাকাউন্ট খুলুন',
  'Session expired. Please sign in again.': 'সময় শেষ। আবার প্রবেশ করুন।',
  'Network error. Please try again.': 'ইন্টারনেট সমস্যা। আবার চেষ্টা করুন।',
  'Permission denied.': 'এই কাজের অনুমতি নেই।',
  'Server problem. Please try again.': 'সার্ভার সমস্যা। আবার চেষ্টা করুন।',
  'Please try again': 'আবার চেষ্টা করুন',
  'Saved offline — will sync when online':
      'অফলাইনে সংরক্ষিত — অনলাইনে গেলে যুক্ত হবে',
  'Select a farm first': 'আগে খামার বেছে নিন',
  'Feed stock': 'খাদ্য মজুদ',
  'Medicine stock': 'ওষুধ মজুদ',
  'Add stock': 'মজুদ যোগ করুন',
  'Add feed': 'খাদ্য যোগ করুন',
  'Add medicine': 'ওষুধ যোগ করুন',
  'Record purchase': 'কেনাকাটা লিখুন',
  'Showing cached stock. Connect to refresh.':
      'সংরক্ষিত মজুদ দেখানো হচ্ছে। আপডেট করতে ইন্টারনেট চালু করুন।',
  'Showing cached data — connect to sync':
      'সংরক্ষিত তথ্য দেখানো হচ্ছে। আপডেট করতে ইন্টারনেট চালু করুন।',
  'No fattening batches yet': 'এখনো কোনো ফ্যাটেনিং ব্যাচ নেই',
  'Create batch': 'ব্যাচ তৈরি করুন',
  'Animals added to batch': 'ব্যাচে পশু যোগ হয়েছে',
  'Feed logged': 'খাদ্যের তথ্য সংরক্ষিত',
  'Profile appearance': 'প্রোফাইল ছবি ও নাম',
  'Photo, cover, display name': 'ছবি, কভার, দেখানোর নাম',
  'Personal information': 'ব্যক্তিগত তথ্য',
  'Email and phone': 'ইমেইল ও মোবাইল',
  'AI Assistant': 'এআই সহকারী',
  'Ask health questions': 'পশুর স্বাস্থ্য সম্পর্কে জিজ্ঞেস করুন',
  'Marketplace': 'বাজার',
  'Services and offers': 'সেবা ও অফার',
  'Reports': 'হিসাব',
  'Health records and reports': 'স্বাস্থ্য তথ্য ও রিপোর্ট',
  'Emergency': 'জরুরি',
  'Emergency doctors and services': 'জরুরি ডাক্তার ও সেবা',
  'Go to farms': 'খামারে যান',
  'Item not found': 'খুঁজে পাওয়া যায়নি',
  'Log feeding (deduct stock)': 'খাওয়ানো লিখুন',
  'Consumption history': 'খাওয়ানোর তালিকা',
  'No feeding logs yet.': 'এখনো খাওয়ানোর তথ্য নেই।',
  'Log feed': 'খাওয়ানো লিখুন',
  'Add feed to stock': 'মজুদে খাদ্য যোগ করুন',
  'Feed item': 'খাদ্য আইটেম',
  'Medicine item': 'ওষুধ আইটেম',
  'Current stock': 'বর্তমান মজুদ',
  'Low stock': 'মজুদ কম',
};
