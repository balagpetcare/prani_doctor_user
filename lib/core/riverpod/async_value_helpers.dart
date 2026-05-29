import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/app_exception.dart';
import '../error/http_error_mapper.dart';

/// Convenience extensions on [AsyncValue] for safe data access and UI mapping.
extension AsyncValueX<T> on AsyncValue<T> {
  /// Returns the data if available, or [fallback] otherwise — never throws.
  T dataOrElse(T fallback) => valueOrNull ?? fallback;

  /// True when loading with no prior data (i.e., first-fetch skeleton state).
  bool get isLoadingFresh => isLoading && valueOrNull == null;

  /// True when an error is present with no prior data.
  bool get isErrorFresh => hasError && valueOrNull == null;

  /// User-readable error message suitable for display in an [AppErrorView].
  String? get errorMessage {
    final e = error;
    if (e == null) return null;
    if (e is AppException) return e.message;
    return HttpErrorMapper.fromStatus(statusCode: null).message;
  }

  /// Collapses to [AsyncValue.data(null)] when [T] is nullable and no data
  /// exists, to avoid thrashing `loading → data(null) → loading` in
  /// optimistic-update flows.
  AsyncValue<T?> asNullableData() {
    return when(
      data: AsyncValue.data,
      loading: () => const AsyncValue.data(null),
      error: AsyncValue.error,
    );
  }
}

/// Extension on [AsyncValue<List<T>>] for paginated / filterable list
/// providers.
extension AsyncListValueX<T> on AsyncValue<List<T>> {
  /// Returns the list (or empty list if not yet loaded) without throwing.
  List<T> get listOrEmpty => valueOrNull ?? const [];

  /// Returns the list length, 0 if not loaded.
  int get countOrZero => valueOrNull?.length ?? 0;
}
