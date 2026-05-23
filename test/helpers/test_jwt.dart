import 'dart:convert';

/// Builds unsigned JWT-shaped tokens for client-side session tests.
String testJwt({
  required String sub,
  DateTime? expiresAt,
  String role = 'CUSTOMER',
  String aud = 'mobile',
}) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final exp =
      (expiresAt ?? DateTime.now().add(const Duration(hours: 1)))
          .millisecondsSinceEpoch ~/
      1000;
  final payload = base64Url.encode(
    utf8.encode(jsonEncode({'sub': sub, 'exp': exp, 'aud': aud, 'role': role})),
  );
  return '${_trimPad(header)}.${_trimPad(payload)}.test_signature';
}

String _trimPad(String value) => value.replaceAll('=', '');
