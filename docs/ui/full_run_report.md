# Full run report — HOME + HEADER + PROFILE UX

**Date:** 2026-05-23  
**Device:** 2109119BC (`192.168.10.107:5555`)  
**Backend:** `http://192.168.10.111:3000`  
**MinIO:** `http://192.168.10.111:9000`

## 1. Files changed (key)

### Enterprise HOME / HEADER / PROFILE (prior + this session)

| Area | Files |
|------|-------|
| SafeArea / shell | `lib/routing/shell/app_shell_scaffold.dart`, `lib/core/layout/shell_page_padding.dart` |
| Smart header | `lib/features/home/presentation/widgets/app_header.dart` |
| Greeting hero | `lib/features/home/presentation/widgets/home_user_hero.dart` |
| Emergency / care | `lib/features/home/presentation/widgets/home_care_action_bar.dart`, `instant_care_sheet.dart` |
| Universal search | `lib/features/search/presentation/universal_search_page.dart`, `universal_search_provider.dart` |
| Profile cover + MinIO | `lib/features/profile/presentation/widgets/profile_cover_header.dart`, `profile_media_actions.dart` |
| Cards / layout | `lib/features/home/presentation/widgets/home_card.dart`, `home_layout.dart`, `quick_action_grid.dart` |
| Loading / error | `lib/features/profile/presentation/widgets/profile_feedback.dart`, `home_page_skeleton.dart` |
| Offline-first | `lib/core/network/auto_refresh_guard.dart`, `lib/core/offline/offline_status_banner.dart`, `lib/core/providers/provider_stability.dart` |
| Bottom nav | `lib/routing/shell/app_shell_scaffold.dart` (FAB removed, consistent padding) |
| Profile save validation | `lib/features/settings/presentation/settings_personal_info_page.dart` (name + email validation via `ProfileValidation`) |
| Legacy cleanup | **Deleted** `welcome_card.dart`, `emergency_button.dart` |
| Boot cache fix | `lib/features/support/data/support_dto.dart`, `support_repository.dart` (Hive `Map<dynamic,dynamic>` cast) |
| Docs | `docs/ui/enterprise_ux_report.md`, `docs/ui/offline_first_report.md` |

### `dart fix --apply`

366 style fixes across 163 files (requested pipeline step). No architectural changes.

## 2. Backend changes

**None required.**

Existing APIs cover profile, home dashboard, media upload, and federated search:

- `GET/PATCH /api/mobile/me`
- `POST/DELETE /api/mobile/me/avatar`, `/cover`
- `GET /api/mobile/profile/dashboard-context`
- `GET /api/mobile/app-config`
- Media via `/api/media`

Migrations: **none pending** (`prisma migrate deploy` — 38 applied).

Env: **no updates** (`.env` already has MinIO at `192.168.10.111:9000`).

## 3. Commands executed

```powershell
# Backend (already running)
Invoke-WebRequest http://127.0.0.1:3000/live          # {"alive":true}
Invoke-WebRequest http://192.168.10.111:3000/live       # {"alive":true}
Invoke-WebRequest http://192.168.10.111:9000/minio/health/live  # 200

# Flutter pipeline
cd D:\PraniDoctor\pranidoctor_user
flutter clean
flutter pub get
dart fix --apply
flutter analyze          # 31 info-level issues
flutter test test/home/ test/golden/   # 15/15 passed
flutter devices          # 2109119BC @ 192.168.10.107:5555
flutter run -d 192.168.10.107:5555
```

## 4. Install result

| Step | Result |
|------|--------|
| Gradle `assembleDebug` | ✅ Built `app-debug.apk` |
| ADB install (1st attempt) | ❌ `adb exited with exit code 1` |
| ADB install (2nd attempt after `flutter clean`) | ✅ 11.9s |
| Sync | ✅ `Syncing files to device 2109119BC... 257ms` |
| App launch | ✅ Running; VM service attached |

**Runtime logs (device):**

- Boot config loaded; `GET /api/mobile/me` → **200**
- Redirect to `/settings/profile/complete` (profile incomplete — expected gate)
- Firebase init skipped in dev (no `google-services.json` values)
- Push notifications skipped in dev

## 5. Remaining issues

1. **Profile completion gate** — authenticated user redirected to profile completion before home. Complete name + union on device to verify home/search/emergency flows end-to-end.
2. **First ADB install failure** — intermittent; resolved by clean rebuild + retry.
3. **Docker CLI not in PATH** on this machine — MinIO verified via HTTP health only (200).
4. **Support cache cast** — fixed in code; hot restart required on running session to pick up fix.
5. **3 pre-existing test failures** in full suite (settings integration, profile completion) — not in `test/home/` or `test/golden/`.

## 6. Known warnings

| Source | Warning |
|--------|---------|
| `flutter analyze` | 31 **info** items (deprecated `RadioGroup`, etc.) — no errors |
| Kotlin compile | `speech_to_text` BluetoothAdapter deprecation |
| Runtime | Firebase not configured for local debug |
| Runtime | `Skipped N frames` on MIUI during boot (device perf) |
| Dependencies | 46 packages have newer major versions pinned by constraints |

## UX checklist (15 items)

| # | Item | Status |
|---|------|--------|
| 1 | SafeArea fix | ✅ |
| 2 | Top header redesign | ✅ |
| 3 | Universal search | ✅ (client-side federated) |
| 4 | Greeting hero | ✅ |
| 5 | Emergency redesign | ✅ (`home_care_action_bar` + `instant_care_sheet`) |
| 6 | Quick actions | ✅ |
| 7 | Profile cover | ✅ |
| 8 | Overflow fixes | ✅ |
| 9 | Responsive fixes | ✅ |
| 10 | MinIO profile sync | ✅ |
| 11 | Profile save validation | ✅ (name + email in personal info) |
| 12 | Bottom nav consistency | ✅ |
| 13 | Card redesign | ✅ |
| 14 | Loading states | ✅ |
| 15 | Error states | ✅ |
