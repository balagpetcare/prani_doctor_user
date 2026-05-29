# Localization Migration Checklist — Prani Doctor User App

**Plan:** [LOCALIZATION_MASTER_PLAN.md](./LOCALIZATION_MASTER_PLAN.md)  
**Style:** [BN_LANGUAGE_STYLE_GUIDE.md](./BN_LANGUAGE_STYLE_GUIDE.md)  
**Terms:** [TRANSLATION_GLOSSARY.md](./TRANSLATION_GLOSSARY.md)  
**Status:** Planning — check boxes during implementation phases

---

## How to use

1. Complete **Phase 0** before feature string work.
2. Mark `[x]` when file is fully migrated (UI + errors + validators wired).
3. For ARB-only keys, note key prefix in the Notes column.
4. Run `flutter gen-l10n` after each ARB batch.

---

## Phase 0 — Foundation (blocking)

### Configuration & tooling

- [ ] Create `lib/l10n/app_bn.arb` (copy structure from `app_en.arb`, translate values to BN)
- [ ] Keep `lib/l10n/app_en.arb` in parity with `app_bn.arb`
- [ ] Update `l10n.yaml`: `template-arb-file: app_bn.arb`
- [ ] Run `flutter gen-l10n` — verify `supportedLocales` includes `bn` and `en`
- [ ] Add `app_localizations_bn.dart` to build
- [ ] CI script: fail if ARB key sets differ between bn/en
- [ ] CI script (optional): flag `Text('` with ASCII in `presentation/`

### Locale persistence & boot

- [ ] Add `LocaleBootstrap` (read `app_locale` from Hive/settings box before `runApp`)
- [ ] Default `app_locale` = `bn` when missing (first install)
- [ ] `profileLocaleControllerProvider`: initial state `Locale('bn')` not `null`
- [ ] `MaterialApp.locale` + `localeListResolutionCallback` → fallback `bn`
- [ ] On language save: write local storage **before** API PATCH
- [ ] Sync server `bn-BD` / `en-US` ↔ local `bn` / `en`
- [ ] Remove `warmFromDisk(locale: 'en')` forced EN at startup — use active UI locale
- [ ] QA: cold start, system language English, app Bangla → no English splash strings

### ARB cleanup (anti-patterns)

- [ ] Remove `homeGreetingMorningBn` / `AfternoonBn` / `EveningBn` — use normal keys per locale file
- [ ] Remove `offlineModeBannerBn` from EN ARB — `offlineModeBanner` in each locale file
- [ ] Remove `homeUniversalSearchHint` Bangla embedded in EN-only generated file
- [ ] Audit all `*Bn` / `*En` suffix keys — eliminate

---

## Phase 1 — P0 user-visible gaps

### Inventory module (no l10n today)

| File | Work |
|------|------|
| [ ] `lib/features/inventory/presentation/inventory_home_page.dart` | All titles, empty, CTA |
| [ ] `lib/features/inventory/presentation/inventory_feed_list_page.dart` | |
| [ ] `lib/features/inventory/presentation/inventory_medicine_list_page.dart` | |
| [ ] `lib/features/inventory/presentation/inventory_feed_detail_page.dart` | Feed + medicine detail |
| [ ] `lib/features/inventory/presentation/inventory_feed_create_page.dart` | Replace inline Bangla + English mix with l10n |
| [ ] `lib/features/inventory/presentation/inventory_medicine_create_page.dart` | |
| [ ] `lib/features/inventory/presentation/inventory_stock_receipt_page.dart` | |
| [ ] `lib/features/inventory/presentation/inventory_consumption_history_page.dart` | |
| [ ] `lib/features/inventory/presentation/widgets/inventory_feedback.dart` | Retry, cached banner |
| [ ] `lib/features/inventory/presentation/widgets/inventory_dashboard_cards.dart` | Labels |
| [ ] `lib/features/inventory/presentation/widgets/inventory_item_card.dart` | Review dynamic text |
| [ ] `lib/features/inventory/presentation/utils/inventory_days_remaining.dart` | Relative days strings |

**ARB prefix suggestion:** `inventory_*`

### Core error & offline

| File | Work |
|------|------|
| [ ] `lib/core/error/http_error_mapper.dart` | Replace static English with l10n lookup / error codes |
| [ ] `lib/core/offline/offline_status_banner.dart` | Use locale-specific banner key |
| [ ] `lib/features/offline/data/offline_repository.dart` | Exception codes → mapped messages |
| [ ] `lib/features/offline/data/sync_coordinator.dart` | Dev messages only; user strings via codes |
| [ ] `lib/features/offline/presentation/offline_queue_panel.dart` | Review |

### Fattening feedback & snackbars

| File | Work |
|------|------|
| [ ] `lib/features/fattening/presentation/widgets/fattening_feedback.dart` | Full file |
| [ ] `lib/features/fattening/presentation/add_animal_page.dart` | Snackbar |
| [ ] `lib/features/fattening/presentation/fattening_log_feed_page.dart` | Snackbar |

### Drawer / home gaps

| File | Work |
|------|------|
| [ ] `lib/features/home/presentation/widgets/drawer_menu.dart` | Inventory, feed/medicine stock |
| [ ] `lib/features/search/presentation/universal_search_provider.dart` | Static entries + categories |

---

## Phase 2 — P1 mixed UI & branding

### Onboarding & brand

| File | Work |
|------|------|
| [ ] `lib/core/branding/brand_assets.dart` | Move `titleBn` / `bodyBn` to ARB or locale-aware brand loader |
| [ ] `lib/features/onboarding/presentation/onboarding_page.dart` | `পিছনে`, `পরের ধাপ`, `শুরু করুন` |
| [ ] `lib/features/boot/presentation/boot_page.dart` | Verify boot messages with bn-first locale |
| [ ] `lib/features/boot/presentation/pages/splash_page.dart` | Neutral + localized status |

### Settings & profile (hardcoded English)

| File | Work |
|------|------|
| [ ] `lib/features/settings/presentation/settings_account_page.dart` | Profile appearance, personal info |
| [ ] `lib/features/profile/presentation/profile_page.dart` | Same strings |
| [ ] `lib/features/profile/presentation/profile_appearance_page.dart` | |
| [ ] `lib/features/profile/presentation/widgets/profile_media_actions.dart` | Camera, Gallery |
| [ ] `lib/features/settings/presentation/settings_personal_info_page.dart` | Review |

### Shared upload

| File | Work |
|------|------|
| [ ] `lib/features/shared/upload/widgets/upload_progress.dart` | Cancel, Retry, complete/cancelled |
| [ ] `lib/features/shared/upload/widgets/image_picker_tile.dart` | Upload failed |
| [ ] `lib/features/shared/upload/widgets/file_picker_tile.dart` | |
| [ ] `lib/features/shared/upload/services/upload_validation.dart` | Return codes; map in UI |

### Feed form

| File | Work |
|------|------|
| [ ] `lib/features/feed/presentation/feed_entry_form_page.dart` | Hardcoded Text review |

### Treatment form

| File | Work |
|------|------|
| [ ] `lib/features/treatment/presentation/treatment_form_page.dart` | Hardcoded Text review |

### Services

| File | Work |
|------|------|
| [ ] `lib/features/services/services_page.dart` | |

### AI locale sync

| File | Work |
|------|------|
| [ ] `lib/features/ai/presentation/ai_providers.dart` | Default `AiLocale` follows app locale |
| [ ] `lib/features/ai/presentation/ai_settings_page.dart` | Document relationship to app language |
| [ ] `lib/features/ai/data/ai_repository.dart` | Offline message mapping |

### Area cache

| File | Work |
|------|------|
| [ ] `lib/app/app_startup.dart` | Warm area for active locale only |
| [ ] `lib/features/area/data/area_repository.dart` | Call sites pass UI locale |
| [ ] `lib/features/area/presentation/area_picker.dart` | |

---

## Phase 3 — P2 repositories & validators

### Validators (inject l10n or error codes)

| File | Status |
|------|--------|
| [ ] `lib/features/fattening/data/fattening_validation.dart` | English returns |
| [ ] `lib/features/feed/data/feed_validation.dart` | `Invalid cost` |
| [ ] `lib/features/shared/upload/services/upload_validation.dart` | |
| [ ] `lib/features/animals/data/animal_validation.dart` | Already uses injected messages — verify all call sites |
| [ ] `lib/features/farm/data/farm_validation.dart` | |
| [ ] `lib/features/vaccine/data/vaccine_validation.dart` | |
| [ ] `lib/features/health/data/health_validation.dart` | |
| [ ] `lib/features/treatment/data/treatment_validation.dart` | |
| [ ] `lib/features/milk/data/milk_validation.dart` | |
| [ ] `lib/features/batches/data/batch_validation.dart` | |
| [ ] `lib/features/finance/data/finance_validation.dart` | |
| [ ] `lib/features/support/data/support_validation.dart` | |
| [ ] `lib/features/area/data/area_validation.dart` | |
| [ ] `lib/features/ai/data/ai_validation.dart` | |
| [ ] `lib/features/profile/data/profile_validation.dart` | |

### Repositories (`AppException` → codes)

| File | Notes |
|------|-------|
| [ ] `lib/features/auth/data/auth_repository.dart` | OTP, login failed |
| [ ] `lib/features/finance/data/finance_repository.dart` | Offline saved, not found |
| [ ] `lib/features/feed/data/feed_repository.dart` | |
| [ ] `lib/features/milk/data/milk_repository.dart` | |
| [ ] `lib/features/animals/data/animal_repository.dart` | |
| [ ] `lib/features/farm/data/farm_repository.dart` | |
| [ ] `lib/features/batches/data/batch_repository.dart` | |
| [ ] `lib/features/fattening/data/fattening_repository.dart` | |
| [ ] `lib/features/health/data/health_repository.dart` | |
| [ ] `lib/features/vaccine/data/vaccine_repository.dart` | |
| [ ] `lib/features/treatment/data/treatment_repository.dart` | |
| [ ] `lib/features/notifications/data/notification_repository.dart` | |
| [ ] `lib/features/support/data/support_repository.dart` | |
| [ ] `lib/features/service_requests/data/service_request_repository.dart` | |
| [ ] `lib/features/home/data/dashboard_repository.dart` | |
| [ ] `lib/features/profile/data/profile_repository.dart` | |
| [ ] `lib/features/inventory/data/inventory_repository.dart` | |
| [ ] `lib/features/feed_catalog/data/feed_catalog_repository.dart` | |
| [ ] `lib/features/doctors/data/doctor_repository.dart` | |
| [ ] `lib/core/network/api_envelope.dart` | Generic failures |
| [ ] `lib/features/auth/data/social_auth_provider.dart` | Social sign-in unavailable |

### Enum / status label maps

| File | Work |
|------|------|
| [ ] `lib/features/treatment/presentation/widgets/treatment_labels.dart` | Pattern reference |
| [ ] `lib/features/finance/presentation/widgets/finance_labels.dart` | |
| [ ] `lib/features/vaccine/presentation/widgets/vaccine_labels.dart` | |
| [ ] `lib/features/health/presentation/widgets/health_labels.dart` | |
| [ ] `lib/features/support/presentation/widgets/support_status_badge.dart` | |
| [ ] `lib/features/service_requests/presentation/service_request_status_chip.dart` | |
| [ ] `lib/features/fattening/presentation/widgets/fattening_status_chip.dart` | |
| [ ] Animal `gender` / `species` display on detail pages | Map API values |

### Dev-only (confirm not user-visible)

| File | Work |
|------|------|
| [ ] `lib/core/network/network_service.dart` | Dev health messages — gate behind debug |
| [ ] `lib/features/animals/presentation/animal_detail_page.dart` | `Text('$e')` → user-safe message |

---

## Phase 4 — Already on l10n (verification pass)

> ~180 files import `AppLocalizations`. Spot-check for interpolated English, API raw values, and date formatting.

### Auth
- [ ] `login_page.dart`, `otp_page.dart`, `register_page.dart`, `welcome_page.dart`, `forgot_password_page.dart`

### Home & dashboard
- [ ] `home_page.dart`, all `lib/features/home/presentation/widgets/*`
- [ ] `orders_page.dart`, `marketplace_page.dart`, `community_page.dart`

### Animals, farm, batches
- [ ] All `lib/features/animals/presentation/**`
- [ ] All `lib/features/farm/presentation/**`
- [ ] All `lib/features/batches/presentation/**`

### Fattening (except Phase 1)
- [ ] Remaining `lib/features/fattening/**` pages

### Feed, milk, finance
- [ ] All presentation pages — verify offline snackbars use l10n

### Health, vaccine, treatment
- [ ] All presentation pages

### Doctors & service requests
- [ ] `doctor_detail_page.dart`, `book_consultation_page.dart`
- [ ] Service request pages

### Notifications & support
- [ ] All presentation pages

### Settings
- [ ] `settings_page.dart`, theme, data sync, about, terms, privacy, connection check
- [ ] `settings_language_page.dart` — verify save flow + persistence

### Profile
- [ ] All profile pages including `profile_language_page.dart`

---

## ARB bulk translation checklist

- [ ] Export key list from `app_bn.arb` (~1,298 keys)
- [ ] Prioritize: boot → auth → home → animals → appointments → settings
- [ ] Finance / fattening / clinical terms reviewed against glossary
- [ ] `@` placeholders and plurals reviewed
- [ ] English `app_en.arb` second pass (not literal from Google Translate)
- [ ] Native speaker sign-off on random 50-string sample per module

---

## QA test matrix

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Fresh install, system EN | Bangla UI, no EN flash |
| 2 | Fresh install, system BN | Bangla UI |
| 3 | Switch to EN in settings | Immediate EN UI |
| 4 | Kill app, reopen | Language preserved |
| 5 | Airplane mode, change language | Local persists; sync when online |
| 6 | Offline boot | Bangla offline banner (not English) |
| 7 | Inventory full flow | All BN when locale bn |
| 8 | OTP / login errors | Bangla messages |
| 9 | Area picker | Division names in selected language |
| 10 | AI voice | `bn_BD` when app bn |

---

## Sign-off

| Role | Name | Date |
|------|------|------|
| Product | | |
| Bangla reviewer | | |
| Engineering lead | | |
| QA | | |

---

*Update this checklist when audit finds new hardcoded files.*
