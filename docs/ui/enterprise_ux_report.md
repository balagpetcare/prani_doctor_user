# Enterprise Home / Header / Profile UX Report

**Project:** `pranidoctor_user`  
**Date:** 2026-05-23  
**Scope:** Phases 1–10 — safe area, smart header, user hero, care bar, search, profile cover, responsive fixes

Architecture preserved: Riverpod + go_router shell, lazy home slivers, existing repositories.

---

## Before / after

| Area | Before | After |
|------|--------|-------|
| Status bar | Header/content could draw under status bar on shell tabs | Home: `SliverSafeArea` on header; other tabs: shell `SafeArea(top)` |
| Header | Location chip + logo + notifications + avatar in one row | Drawer · logo · notifications · avatar + dedicated search row |
| Greeting | Flat `HomeWelcomeCard` | 220px gradient/cover **user hero** with Bengali time greeting |
| Emergency | Red FAB + emergency quick-action tile | Horizontal **care action bar** + **instant care** bottom sheet |
| Search | None | Universal search route `/search` (doctors, services, animals, FAQ, static sources) |
| Profile | Avatar-only list header | 240px **cover header**, overlay avatar, camera/gallery upload to MinIO |
| Bottom scroll | Extra padding for FAB (96px) | Reduced to 72px (FAB removed) |

---

## Changed / new files

### Core / shell
- `lib/core/layout/shell_page_padding.dart` — shared tab page insets
- `lib/routing/shell/app_shell_scaffold.dart` — SafeArea for non-home tabs, FAB removed
- `lib/routing/app_routes.dart` — `AppRoutes.search`
- `lib/routing/app_router.dart` — search route

### Home / header
- `lib/features/home/presentation/widgets/app_header.dart` — smart 2-row header + search tap
- `lib/features/home/presentation/widgets/home_user_hero.dart` — **new** user hero
- `lib/features/home/presentation/widgets/home_care_action_bar.dart` — **new** horizontal actions
- `lib/features/home/presentation/widgets/instant_care_sheet.dart` — **new** emergency panel
- `lib/features/home/presentation/home_page.dart` — hero + care bar wired
- `lib/features/home/presentation/widgets/quick_action_grid.dart` — emergency tile removed
- `lib/features/home/presentation/widgets/summary_card.dart` — min-height metric cards
- `lib/features/home/presentation/theme/home_tokens.dart` — bottom padding adjusted

### Search
- `lib/features/search/presentation/universal_search_page.dart` — **new**
- `lib/features/search/presentation/universal_search_provider.dart` — **new**

### Profile
- `lib/features/profile/presentation/profile_page.dart` — cover layout
- `lib/features/profile/presentation/widgets/profile_cover_header.dart` — **new**
- `lib/features/profile/presentation/widgets/profile_media_actions.dart` — **new** shared upload

### Tab safe area
- `lib/features/services/services_page.dart`
- `lib/features/inbox/inbox_page.dart`
- `lib/features/settings/settings_page.dart`

### L10n
- `lib/l10n/app_en.arb` — search, hero, care, Bengali greetings

### Tests (goldens updated)
- `test/golden/goldens/home_*.png`

### Unused (replaced, can delete in follow-up)
- `lib/features/home/presentation/widgets/welcome_card.dart` — superseded by `home_user_hero.dart`
- `lib/features/home/presentation/widgets/emergency_button.dart` — no longer referenced from shell

---

## Verification

| Check | Result |
|-------|--------|
| `flutter clean` | Pass |
| `flutter pub get` | Pass |
| `flutter analyze` | 0 errors (405 info/warnings, project-wide) |
| `flutter test test/home/ test/golden/` | Pass (goldens regenerated) |
| `flutter run -d 192.168.10.107:5555` | Started (device deploy) |

---

## Screens to manually verify on device

1. **Home** — header below status bar, search opens `/search`, hero shows name/location, care bar scrolls
2. **Services / Inbox / Settings** — titles clear of status bar
3. **Profile** — cover gradient or MinIO image, avatar upload, Edit/Cover/Settings chips
4. **Emergency** — care bar → instant care sheet → routes + ETA labels
5. **Search** — text filter across doctors/services/animals/FAQ; voice mic snackbar flow
6. **Dark mode / large text / RTL** — recommended pass on physical device

---

## Remaining issues / risks

1. **Screenshots:** Not captured in CI — take device screenshots for before/after gallery.
2. **Recent searches:** In-memory only (session); add `shared_preferences` if persistence is required.
3. **Member since:** Static copy until API exposes `createdAt` on `MobileMeDto`.
4. **Profile cover actions on small widths:** Three text chips may wrap — consider icon-only on narrow screens if QA finds overflow.
5. **`welcome_card.dart` / `emergency_button.dart`:** Dead code; safe to delete in cleanup PR.
6. **Full test suite:** Pre-existing failures in settings/profile completion tests unchanged.

---

## Performance notes

- Hero/cover use cached `ProfileMediaImage` / existing MinIO URLs
- Search provider composes existing list endpoints (no duplicate HTTP layer)
- Care bar uses horizontal `ListView` (lazy off-screen items)
- `const` constructors used where practical on new widgets
