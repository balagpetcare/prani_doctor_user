import 'dart:convert';

/// Lightweight JWT payload decode (no signature verification — server validates).
class JwtUtils {
  JwtUtils._();

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

  static bool isExpired(String token, {Duration leeway = const Duration(seconds: 30)}) {
    final payload = decodePayload(token);
    final exp = payload?['exp'];
    if (exp is! num) return false;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    return DateTime.now().add(leeway).isAfter(expiresAt);
  }
}
