/// Scalable single-import surface for the localization subsystem.
///
/// Aggregates the active custom localization stack (typed + dynamic-key
/// `AppLocalizations`, the `context.tr` extension, `TranslationKeys`), the
/// locale controller/storage, the JSON loader and the localized API error
/// mapper. The legacy public shim `lib/l10n/app_localizations.dart` remains for
/// backward compatibility.
///
/// `import 'package:pranidoctor_user/core/localization/localization.dart';`
library;

export 'app_date_format.dart';
export 'app_localizations.dart';
export 'api_error_mapper.dart';
export 'language_controller.dart';
export 'locale_storage.dart';
export 'localization_helpers.dart';
export 'localization_loader.dart';
