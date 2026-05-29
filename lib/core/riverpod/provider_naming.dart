// Provider naming conventions for the PraniDoctor app.
//
// Following these conventions makes providers discoverable and avoids
// rebuild-ambiguity when reading vs. watching.
//
// Naming convention
// ─────────────────
// {feature}ListProvider          AsyncNotifier: paginated list + meta
// {feature}DetailProvider        FutureProvider.autoDispose.family: single record by id
// {feature}SearchProvider        StateProvider.autoDispose: search query string
// {feature}FilterProvider        StateProvider.autoDispose: enum filter (nullable)
// {feature}SortProvider          StateProvider.autoDispose: sort enum
// {feature}FromDateProvider      StateProvider.autoDispose: date-range start
// {feature}ToDateProvider        StateProvider.autoDispose: date-range end
// {feature}UploadProgressProvider StateProvider.autoDispose: upload progress (0.0–1.0)
// {feature}SummaryProvider       FutureProvider(.autoDispose): aggregated stats
// {feature}AnalyticsProvider     FutureProvider.autoDispose: chart/report data
// {feature}RefreshProvider       StateProvider<int>: tick counter (never autoDispose)
//
// Rules:
// - Scoped (per-entity detail, paginated analytics, form state) → autoDispose
// - Global singletons (session, settings, theme, connectivity, notification
//   badge, animal list) → persistProvider (keepAlive) without autoDispose
// - Refresh-tick counters → never autoDispose
// - Upload progress → autoDispose (scoped to upload flow)
