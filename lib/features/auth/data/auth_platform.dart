import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

abstract final class AuthPlatform {
  AuthPlatform._();

  static String current() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }
}
