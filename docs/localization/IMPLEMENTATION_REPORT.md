# Localization Implementation Report (V1)

**Date:** 2026-05-24  
**Plan:** [LOCALIZATION_MASTER_PLAN.md](./LOCALIZATION_MASTER_PLAN.md)  
**Status:** Implemented — see [FINAL_LANGUAGE_AUDIT.md](./FINAL_LANGUAGE_AUDIT.md) for finishing-pass quality metrics (~67% catalog / ~92% P0 journeys)

---

## 1. Summary

The Prani Doctor User app now uses a **JSON-based localization stack** under `lib/core/localization/` with **Bangla (`bn`) as default**, **local Hive persistence before first frame**, and **live language switching** on Settings → Preferences (no restart).

Existing UI code continues to use `AppLocalizations` via `package:pranidoctor_user/l10n/app_localizations.dart` (re-export). New/dynamic keys use `context.tr.t('key')` or `TranslationKeys`.

---

## 2. Architecture delivered

| Component | Path |
|-----------|------|
| Loader (preload in bootstrap) | `lib/core/localization/localization_loader.dart` |
| Locale storage (`bn` / `en`) | `lib/core/localization/locale_storage.dart` |
| Riverpod language state | `lib/core/localization/language_controller.dart` |
| Delegate + lookup | `lib/core/localization/app_localizations_delegate.dart` |
| Abstract API + `translate()` | `lib/core/localization/app_localizations_base.dart` |
| Generated getters (en/bn) | `lib/core/localization/generated/app_localizations_impl.dart` |
| Key constants | `lib/core/localization/translation_keys.dart` |
| `context.tr` extension | `lib/core/localization/localization_extensions.dart` |
| API error mapping | `lib/core/localization/api_error_mapper.dart` |
| Public export | `lib/core/localization/app_localizations.dart` |
| Legacy import barrel | `lib/l10n/app_localizations.dart` |
| Strings (canonical) | `assets/i18n/en.json`, `assets/i18n/bn.json` |
| Codegen tool | `tool/i18n/build_localization.dart` |

**Bootstrap:** `LocalizationLoader.ensureInitialized()` runs after `initHiveCache()` in `lib/app/bootstrap.dart`.

**MaterialApp:** `locale` from `languageControllerProvider`; `localeListResolutionCallback` prefers stored locale over device language.

**API tags:** `bn` ↔ `bn-BD`, `en` ↔ `en-US` via `LocaleStorage`.

---

## 3. String counts

| Metric | Count |
|--------|------:|
| ARB-derived UI keys | 1,226 |
| Extra keys (inventory, API errors, settings, search, …) | ~138 |
| **Total JSON keys (bn.json)** | **~1,364** |
| Generated `TranslationKeys` constants | ~1,364 |
| Files importing `app_localizations` | ~180 (unchanged pattern) |
| Hardcoded `Text('English…')` in `lib/features/**` (remaining) | **~9** instances in 5 files |
| `AppException(message: '…')` in data layer (remaining) | **~120** (developer-facing; map at UI) |

---

## 4. Screens / modules completed

| Module | Status |
|--------|--------|
| App shell, boot, splash | ✅ Uses loaded locale; bn default |
| Settings → Preferences | ✅ Inline **ভাষা** / বাংলা / English radios; live switch |
| Settings → Language (legacy route) | ✅ Syncs `LanguageController` + API |
| Inventory (all presentation pages) | ✅ Migrated to `context.tr` / `t()` |
| Fattening feedback & snackbars | ✅ |
| Upload progress / media picker | ✅ |
| Profile / settings account tiles | ✅ |
| Home drawer (inventory labels) | ✅ |
| Universal search static shortcuts | ✅ |
| Onboarding back / next / start | ✅ |
| Auth, home, animals, finance, … | ✅ Existing `l10n.*` getters (JSON-backed) |

---

## 5. Translation approach

- **Bangla:** Meaning-first; phrase dictionary + key overrides in `tool/i18n/build_localization.dart`.
- **English:** Sourced from former `app_en.arb`.
- **Technical terms:** এপিআই, ওটিপি, ক্যামেরা, etc. per style guide.
- **Examples implemented:**

| English | Bangla (bn.json) |
|---------|------------------|
| Add animal (pattern) | নতুন পশু যোগ করুন (`animalCreateTitle`) |
| Add photo | ছবি দিন (`addImage`) |
| Choose type | ধরন বেছে নিন (`chooseCategory`) |
| Allow location access | অবস্থান ব্যবহারের অনুমতি দিন (`locationPermission`) |
| No data | এখনো কোনো তথ্য নেই (`No data` phrase map) |
| Failed | কাজ সম্পন্ন হয়নি (`Failed` phrase map) |

---

## 6. API error mapping

`ApiErrorMapper` maps `error.code` → `api_error_<CODE>` keys in JSON.

| Code | Bangla |
|------|--------|
| `USER_NOT_FOUND` | ব্যবহারকারী খুঁজে পাওয়া যায়নি |
| `NETWORK_ERROR` | ইন্টারনেট সংযোগ পরীক্ষা করুন |
| `OFFLINE` | আপনি অফলাইনে আছেন |

HTTP status titles use `errorSessionExpiredTitle`, `errorNetworkTitle`, etc.

**Note:** Repositories still throw English `AppException.message`; UI layers should use `ApiErrorMapper.message(context.tr, error)` when displaying errors (gradual adoption).

---

## 7. Accessibility / layout

- Prefer short Bangla labels on buttons; longer copy in `bodySmall` / subtitles.
- **Recommended manual QA widths:** 320, 360, 393, 430 dp (see master plan §9).
- Use `maxLines` + `overflow: TextOverflow.ellipsis` on dense tiles where needed (inventory subtitles).

---

## 8. Remaining issues (follow-up)

1. **Repository / sync layer** — ~120 English `AppException` messages; introduce `error.code` only and map in UI.
2. **Hardcoded UI (~9)** — `feed_entry_form_page`, `treatment_form_page`, `profile_appearance_page`, `settings_personal_info_page`, `services_page` (minor labels).
3. **Inventory form helper text** — some English literals used via `t('…')` before keys added to JSON; run `dart run tool/i18n/build_localization.dart` after adding keys to `_errorKeys`.
4. **Bangla copy QA** — ~1,226 keys use phrase-replacement; native speaker review recommended (see [BN_LANGUAGE_STYLE_GUIDE.md](./BN_LANGUAGE_STYLE_GUIDE.md)).
5. **`TranslationKeys` vs string literals** — prefer adding new keys to `_errorKeys` in build script, then regenerate.
6. **Flutter `generate: false`** — `l10n.yaml` retained for reference; codegen is `tool/i18n/build_localization.dart`.
7. **`homeGreeting*Bn` keys** — still named `*Bn`; consider renaming to locale-agnostic keys in a future pass.
8. **`HttpErrorMapper`** — still English for non-UI callers; migrate call sites to `ApiErrorMapper` + `context.tr`.

---

## 9. Developer commands

```bash
# Regenerate JSON + Dart after editing lib/l10n/app_en.arb or _errorKeys
dart run tool/i18n/build_localization.dart

# Analyze
flutter analyze lib
```

---

## 10. Usage reference

```dart
import 'package:pranidoctor_user/l10n/app_localizations.dart';
import 'package:pranidoctor_user/core/localization/localization_extensions.dart';
import 'package:pranidoctor_user/core/localization/translation_keys.dart';

// Typed getter (generated)
Text(context.tr.navHome);

// Dynamic key
Text(context.tr.t(TranslationKeys.inventoryTitle));
Text(context.tr.t('api_error_USER_NOT_FOUND'));

// Errors
ApiErrorMapper.message(context.tr, error);
```

---

## 11. Sign-off checklist

- [x] Default language Bangla on first install
- [x] Locale persisted in Hive (`app_locale`)
- [x] Loaded before `runApp` (JSON preload)
- [x] Live switch without restart
- [x] `bn` + `en` supported
- [x] Inventory module localized
- [ ] Full native Bangla review of all 1,364 strings
- [ ] Repository error code migration
- [ ] Width overflow QA on physical devices

---

*End of implementation report.*
