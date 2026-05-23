import 'package:firebase_core/firebase_core.dart';

/// No `lib/firebase_options.dart` yet — [Firebase.initializeApp] uses platform config.
///
/// After `flutterfire configure`, add `lib/firebase_options.dart` and point
/// [firebase_bootstrap] at `DefaultFirebaseOptions.currentPlatform`.
FirebaseOptions? get platformFirebaseOptions => null;
