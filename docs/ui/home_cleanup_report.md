# Home Legacy Cleanup Report

**Project:** `pranidoctor_user`  
**Date:** 2026-05-23  
**Scope:** Remove unused pre-redesign home widgets, duplicate routes, and dead providers after Phase 2 wiring.

---

## Summary

Legacy home widgets from the pre-redesign dashboard were removed. Placeholder module pages were replaced with real marketplace, community, and orders screens. No duplicate API clients were introduced — new home providers compose existing repositories.

---

## Deleted files

| File | Reason |
|------|--------|
| `lib/features/home/presentation/placeholder_module_page.dart` | Replaced by `marketplace_page.dart`, `community_page.dart`, `orders_page.dart` |
| `lib/features/home/presentation/widgets/home_activity_section.dart` | Not referenced on active home path |
| `lib/features/home/presentation/widgets/home_appointments_section.dart` | Superseded by inbox / tasks sections |
| `lib/features/home/presentation/widgets/home_greeting_header.dart` | Superseded by `welcome_card.dart` |
| `lib/features/home/presentation/widgets/home_health_alerts_section.dart` | Health alerts folded into tasks / vaccine providers |
| `lib/features/home/presentation/widgets/home_hero_banner.dart` | Superseded by `welcome_card.dart` |
| `lib/features/home/presentation/widgets/home_section_shell.dart` | Superseded by `HomeSectionScope` / `HomeLazySliver` |
| `lib/features/home/presentation/widgets/home_emergency_card.dart` | Superseded by `emergency_button.dart` |
| `lib/features/home/presentation/widgets/home_promo_card.dart` | Unused on home |
| `lib/features/home/presentation/widgets/home_skeleton.dart` | Superseded by `home_page_skeleton.dart` + `home_shimmer.dart` |
| `lib/features/home/presentation/widgets/home_quick_actions.dart` | Superseded by `quick_action_grid.dart` |
| `lib/features/home/presentation/widgets/home_summary_section.dart` | Superseded by `summary_card.dart` |

**Total removed:** 12 files (~2.4k lines of dead UI code).

---

## Routes & navigation

| Before | After |
|--------|-------|
| `/marketplace` → `HomePlaceholderPage` | `/marketplace` → `MarketplacePage` |
| `/community` → `HomePlaceholderPage` | `/community` → `CommunityPage` |
| `/orders` → `HomePlaceholderPage` | `/orders` → `OrdersPage` |

Drawer tile **Orders** now pushes `AppRoutes.orders` (was placeholder).

Home section **View all** links updated in `marketplace_section.dart` and `community_section.dart`.

---

## Provider consolidation

| New provider | Upstream (no duplicate HTTP) |
|--------------|------------------------------|
| `homeMarketplacePreviewProvider` | `serviceCategoriesProvider`, `doctorListProvider` |
| `homeMarketplaceCatalogProvider` | Delegates to preview provider |
| `homeCommunityPreviewProvider` | `supportHelpProvider` (FAQ → tips/articles/posts) |
| `homeCommunityFeedProvider` | Paginated FAQ mapping |
| `homeOrdersListProvider` | `serviceRequestRepository.listRequests` |
| `homeOrdersSummaryProvider` | Derived from orders list |

Invalidation centralized in `invalidateHomeSections()` (`home_section_providers.dart`) and `HomeNavigation._invalidateWidgetSections`.

---

## Verified no remaining references

Grep confirmed zero imports of:

- `HomePlaceholderPage`, `placeholder_module_page`
- `home_activity_section`, `home_appointments_section`, `home_greeting_header`
- `home_health_alerts_section`, `home_hero_banner`, `home_section_shell`
- `home_emergency_card`, `home_promo_card`, `home_skeleton`
- Legacy `home_quick_actions`, `home_summary_section`

---

## Shared profile hero (not deleted — new)

| File | Role |
|------|------|
| `lib/features/profile/presentation/profile_hero_tags.dart` | Single hero tag source |
| `lib/features/profile/presentation/widgets/profile_hero_avatar.dart` | Shared avatar + cache + fallback |
| `lib/features/home/presentation/theme/home_hero_tags.dart` | Re-exports profile tag; animal tags unchanged |

Used by `app_header.dart`, `drawer_menu.dart`, `profile_page.dart`.

---

## Intentionally kept

- `home_providers.dart` — dashboard core (unchanged business logic)
- `home_analytics.dart`, `home_page_controller.dart` — orchestration
- All active section widgets under `presentation/widgets/` (37 files post-cleanup)

---

## Rollback

Restore deleted files from git history and revert `app_router.dart` placeholder routes. Dashboard repositories are unchanged — rollback is UI-only.
