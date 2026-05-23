import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options_accessor_stub.dart' as firebase_options;

/// Whether [Firebase.initializeApp] completed successfully.
bool firebaseAppReady = false;

/// Initializes Firebase before [ProviderScope] / any [FirebaseMessaging] access.
Future<bool> ensureFirebaseInitialized() async {
  if (Firebase.apps.isNotEmpty) {
    firebaseAppReady = true;
    if (kDebugMode) {
      debugPrint('[Firebase] initialized');
    }
    return true;
  }

  try {
    final options = firebase_options.platformFirebaseOptions;
    if (options != null) {
      await Firebase.initializeApp(options: options);
    } else {
      await Firebase.initializeApp();
    }
    firebaseAppReady = true;
    if (kDebugMode) {
      debugPrint('[Firebase] initialized');
    }
    return true;
  } on FirebaseException catch (e) {
    firebaseAppReady = false;
    if (kDebugMode) {
      debugPrint('[Firebase] init skipped: ${e.code} ${e.message}');
    }
    return false;
  } catch (e) {
    firebaseAppReady = false;
    if (kDebugMode) {
      debugPrint('[Firebase] init skipped: $e');
    }
    return false;
  }
}

bool get isFirebaseReady => firebaseAppReady && Firebase.apps.isNotEmpty;
