# Home Production Readiness Report

**Project:** `pranidoctor_user`  
**Date:** 2026-05-23  
**Status:** Phase 2 complete — all home TODO items from `home_final_report.md` addressed

---

## Executive summary

Home redesign polish is unchanged. Phase 2 connected marketplace, community, and orders to existing backend surfaces, completed profile hero continuity, removed legacy widgets, fixed `SemanticsService.announce` deprecation, added golden tests, and ran the full verify pipeline.

**Architecture preserved:** `CustomScrollView` + lazy slivers, Riverpod section providers, go_router shell navigation. No visual redesign in this phase.

---

## Screens delivered

| Screen | Route | Data source | States |
|--------|-------|-------------|--------|
| Home dashboard | `/` (tab 0) | Existing dashboard + section providers | loading, error, offline, empty per section |
| Marketplace | `/marketplace` | Service categories + doctor offers | loading, empty, error, pull refresh |
| Community | `/community` | Support FAQ → posts/tips/articles | pagination, cache, pull refresh |
| Orders | `/orders` | Service requests | summary (pending/completed/cancelled), list, empty, error |
| Profile (hero target) | settings profile routes | `mobileMeProvider` | Hero from header/drawer |

### Home preview sections

- **Marketplace preview:** horizontal cards, View all → `/marketplace`
- **Community preview:** horizontal cards from FAQ mapping
- **Orders:** drawer entry + full page with summary row

---

## Build & verify (2026-05-23)

| Command | Result |
|---------|--------|
| `flutter clean` | Pass |
| `flutter pub get` | Pass |
| `dart format .` (home/profile scope) | Pass — 0 files changed (already formatted) |
| `flutter analyze` | **0 errors**, 393 info/warnings (project-wide, pre-existing) |
| `flutter test test/home/ test/golden/` | **14/14 pass** |
| `flutter test` (full suite) | **183 pass, 3 fail** (pre-existing; see risks) |
| `flutter build apk --release` | Pass |

### Release APK

| Metric | Value |
|--------|-------|
| Path | `build/app/outputs/flutter-apk/app-release.apk` |
| Size | **87.7 MB** (91,910,320 bytes) |
| Notes | Kotlin incremental-cache warnings during build; APK output succeeded |

---

## Golden tests

Location: `test/golden/`

| Test | Baseline |
|------|----------|
| Home light (390×844) | `test/golden/goldens/home_light.png` |
| Home dark | `test/golden/goldens/home_dark.png` |
| Home tablet (900×1200) | `test/golden/goldens/home_tablet.png` |
| Drawer light | `test/golden/goldens/drawer_light.png` |

Run:

```bash
flutter test test/golden/
```

Update baselines after intentional UI changes:

```bash
flutter test test/golden/ --update-goldens
```

Drawer golden uses the production `ProfileHeroAvatar` + drawer header layout (avoids mocking `StatefulNavigationShell`).

---

## Performance

| Target | Status |
|--------|--------|
| First paint < 2s | **Not instrumented** — lazy slivers, `RepaintBoundary`, cached profile images, and horizontal lists with `primary: false` are in place |
| Scroll 60fps | **Design intent met** — single `CustomScrollView`, deferred section mount via `HomeLazySliver` / `HomePageController` |

Recommend profiling on a mid-range Android device with DevTools timeline for production sign-off.

---

## Accessibility QA

| Area | Code status | Manual QA |
|------|-------------|-----------|
| Large text | `maxLines` + `ellipsis` on drawer/header names | Recommended on device |
| Dark mode | `AppTheme.dark()` + `HomeThemeExtension`; golden baseline | Golden pass |
| RTL | `EdgeInsetsDirectional`, `AlignmentDirectional` in home tokens | Recommended on device |
| Small phones | Horizontal lists + scroll padding tokens | Recommended |
| Tablet | Golden baseline 900×1200 | Golden pass |
| Offline | `HomeOfflineBanner`, provider cache via `persistProvider` | Smoke pass in tests |
| Semantics | `HomeSectionScope`, `homeAnnounce` → `sendAnnouncement` | Fixed deprecation |

---

## Phase 2 checklist (from `home_final_report.md`)

| # | Item | Status |
|---|------|--------|
| 1 | Profile hero complete (tag, navigation, reverse anim, missing image, cache) | Done |
| 2 | Real marketplace (preview + page, no duplicate API) | Done |
| 3 | Real community (pagination, cache, refresh) | Done |
| 4 | Real orders (drawer, summary card) | Done |
| 5 | Remove legacy home + cleanup report | Done — see `home_cleanup_report.md` |
| 6 | Accessibility QA | Code fixes applied; device QA recommended |
| 7 | Golden tests | Done — home light/dark/tablet + drawer |
| 8 | `SemanticsService.announce` deprecation | Fixed in `home_layout.dart` |
| 9 | Performance | Optimizations retained; no regression measured |
| 10 | Final verify + this report | Done |

---

## Data mapping notes

No dedicated `/marketplace`, `/community`, or e-commerce `/orders` APIs exist yet. Phase 2 maps:

- **Marketplace** → service categories + featured doctors (offers)
- **Community** → support help FAQ items (tips, articles, posts)
- **Orders** → service requests (`ServiceRequestStatus`)

When dedicated APIs ship, swap provider implementations only — section widgets and routes stay stable.

---

## Remaining risks

1. **Full test suite:** 3 failures unrelated to home work:
   - `settings_integration_test.dart` — theme assertion / inherited widget
   - `profile_completion_page_test.dart` (2 tests) — `inherited != null` assertion
2. **Device QA:** Drawer animation, RTL, and large-font overflow not exhaustively tested on hardware.
3. **Performance:** First-paint budget not measured with DevTools; recommend one profiling pass before store release.
4. **Community content:** FAQ-backed feed is functional but not a full social/community backend.
5. **Analyzer debt:** 393 info/warnings project-wide; home scope has 0 errors.

---

## Key files

```
lib/features/profile/presentation/profile_hero_tags.dart
lib/features/profile/presentation/widgets/profile_hero_avatar.dart
lib/features/home/presentation/providers/home_marketplace_provider.dart
lib/features/home/presentation/providers/home_community_provider.dart
lib/features/home/presentation/providers/home_orders_provider.dart
lib/features/home/presentation/pages/marketplace_page.dart
lib/features/home/presentation/pages/community_page.dart
lib/features/home/presentation/pages/orders_page.dart
test/golden/home_golden_test.dart
test/golden/drawer_golden_test.dart
docs/ui/home_cleanup_report.md
```

---

## Related docs

- Planning: `docs/ui/home_redesign_plan.md`
- Pre-Phase-2 state: `docs/ui/home_final_report.md`
- Cleanup detail: `docs/ui/home_cleanup_report.md`
