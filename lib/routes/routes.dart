/// Standardized barrel for app navigation.
///
/// The router implementation continues to live under `lib/routing/`. This
/// barrel gives a single canonical import (`routes/routes.dart`) while keeping
/// existing `routing/*` imports working (backward compatible).
library;

export '../routing/app_router.dart';
export '../routing/app_routes.dart';
export '../routing/nav_guard.dart';
