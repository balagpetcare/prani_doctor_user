# FIX_FEED_CATALOG_SHARED_NETWORK_REFACTOR_BREAKAGE_V1

## Problem

Flutter build fails because `feed_catalog_repository.dart` imports `ApiResult` and `AppException` from paths that no longer exist:

- `lib/core/network/api_result.dart` — **missing**
- `lib/core/network/app_exception.dart` — **missing**

## Root Cause

During a shared networking refactor, `ApiResult<T>` and `AppException` were moved from `lib/core/network/` to `lib/core/error/` (Freezed types with generated `.freezed.dart` parts). All other feature repositories were updated; `feed_catalog` was added afterward (or missed) and still references the old locations.

`dio_helpers.dart` and `dio_provider.dart` correctly remain under `lib/core/network/`.

## Active Network Abstraction

| Type | Location | Usage |
|------|----------|-------|
| `ApiResult<T>` | `lib/core/error/api_result.dart` | Repository return type; `success` / `failure` factories |
| `AppException` | `lib/core/error/app_exception.dart` | Typed error payload inside `ApiResult.failure` |
| `getJson` / Dio helpers | `lib/core/network/dio_helpers.dart` | HTTP GET with envelope parsing |
| `dioProvider` | `lib/core/network/dio_provider.dart` | Injected `Dio` instance |
| `ApiEnvelope` | `lib/core/network/api_envelope.dart` | Response parsing; throws `AppException` |

No alternate types (`Result<T>`, `NetworkResult`, etc.) are in use. Repositories standardize on `ApiResult<T>`.

## Affected Files

| File | Issue |
|------|-------|
| `lib/features/feed_catalog/data/feed_catalog_repository.dart` | Stale imports only |

## Callers (contract preserved)

| Caller | Expectation |
|--------|-------------|
| `feed_catalog_providers.dart` | `FutureProvider` calls `listCatalog()`, uses `result.when(success:, failure:)` — unchanged |
| `feedCatalogRepositoryProvider` | Returns `FeedCatalogRepositoryContract` — unchanged |

No offline queue or outbox integration for feed catalog at this time (read-only catalog list).

## Fix

Replace two import paths in `feed_catalog_repository.dart`:

```dart
// Before
import '../../../core/network/api_result.dart';
import '../../../core/network/app_exception.dart';

// After
import '../../../core/error/api_result.dart';
import '../../../core/error/app_exception.dart';
```

No API signature, constructor, or error-mapping changes required — types and factories are identical.

## Compatibility Notes

- **No duplicate classes** — reuses existing `core/error` types used by 30+ repositories.
- **Repository contract unchanged** — `Future<ApiResult<List<FeedCatalogItem>>> listCatalog({String? search})`.
- **Provider contract unchanged** — `feedCatalogListProvider` continues to unwrap via `.when()`.

## Verification

```bash
flutter pub get
flutter analyze
flutter run   # manual: confirm feed catalog screen loads
```

Expected: zero missing-import errors; feed catalog compiles and loads.

## Implementation Status

- [x] Plan documented
- [x] Import paths corrected
- [ ] `flutter analyze` clean
- [ ] Runtime smoke test
