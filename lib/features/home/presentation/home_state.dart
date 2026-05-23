/// Dashboard connectivity / data freshness for the home screen.
enum HomeState {
  /// Initial load — no cached dashboard yet.
  loading,

  /// Fresh data from network.
  ready,

  /// Showing disk cache while network unavailable or stale.
  cached,

  /// Network failed and only cached data is shown.
  offline,

  /// No cache and network failed.
  error,
}

extension HomeStateX on HomeState {
  bool get showsCachedContent =>
      this == HomeState.cached || this == HomeState.offline;

  bool get isBlockingError => this == HomeState.error;
}
