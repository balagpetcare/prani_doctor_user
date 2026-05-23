import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Lightweight JWT payload decode (no signature verification — server validates).
class JwtUtils {
  JwtUtils._();

  static const _expectedAudience = 'mobile-app';
  static const _legacyAudience = 'mobile';
  static const _expectedIssuer = 'pranidoctor';

  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded);
      if (json is Map<String, dynamic>) return json;
      return null;
    } catch (_) {
      return null;
    }
  }

  static String? subject(String token) {
    final payload = decodePayload(token);
    final sub = payload?['sub'];
    return sub is String ? sub : null;
  }

  static bool isDevToken(String token) {
    final lower = token.toLowerCase();
    return lower == 'dev-token' ||
        lower.startsWith('dev-') ||
        lower.contains('dev-token');
  }

  static bool hasExpectedMobileClaims(String token) {
    final payload = decodePayload(token);
    if (payload == null) return false;
    final aud = payload['aud'];
    final iss = payload['iss'];
    final audOk =
        aud == _expectedAudience ||
        aud == _legacyAudience ||
        (aud is List &&
            aud.any((a) => a == _expectedAudience || a == _legacyAudience));
    final issOk = iss == null || iss == _expectedIssuer;
    return audOk && issOk;
  }

  /// True when [token] is a three-part JWT with a decodable payload and `sub`.
  static bool isValidAccessToken(String token) {
    if (token.isEmpty) return false;
    if (isDevToken(token)) {
      if (kDebugMode) debugPrint('[AUTH] rejected dev-token pseudo JWT');
      return false;
    }
    if (token.split('.').length != 3) return false;
    final payload = decodePayload(token);
    if (payload == null) return false;
    final sub = payload['sub'];
    if (sub is! String || sub.isEmpty) return false;
    if (!hasExpectedMobileClaims(token)) {
      if (kDebugMode) debugPrint('[AUTH] rejected JWT — aud/iss mismatch');
      return false;
    }
    return true;
  }

  static bool isExpired(
    String token, {
    Duration leeway = const Duration(seconds: 30),
  }) {
    if (!isValidAccessToken(token)) return true;
    final payload = decodePayload(token)!;
    final exp = payload['exp'];
    if (exp is! num) return true;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    return DateTime.now().add(leeway).isAfter(expiresAt);
  }
}
