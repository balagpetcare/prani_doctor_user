/// Contract for product analytics (Firebase Analytics, Mixpanel, etc.).
abstract interface class AnalyticsReporter {
  void logEvent(String name, {Map<String, Object?>? parameters});

  void setUserProperty(String name, String? value);

  void setUserId(String? userId);
}

/// No-op until analytics SDK is wired.
final class NoOpAnalyticsReporter implements AnalyticsReporter {
  const NoOpAnalyticsReporter();

  @override
  void logEvent(String name, {Map<String, Object?>? parameters}) {}

  @override
  void setUserProperty(String name, String? value) {}

  @override
  void setUserId(String? userId) {}
}

/// Placeholder for `firebase_analytics` integration.
final class FirebaseAnalyticsReporter implements AnalyticsReporter {
  const FirebaseAnalyticsReporter();

  @override
  void logEvent(String name, {Map<String, Object?>? parameters}) {
    // FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
  }

  @override
  void setUserProperty(String name, String? value) {
    // FirebaseAnalytics.instance.setUserProperty(name: name, value: value);
  }

  @override
  void setUserId(String? userId) {
    // FirebaseAnalytics.instance.setUserId(id: userId);
  }
}
