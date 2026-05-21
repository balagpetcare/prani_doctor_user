class OtpRequestResultDto {
  const OtpRequestResultDto({required this.sent, required this.otpTtlSeconds});

  final bool sent;
  final int otpTtlSeconds;

  factory OtpRequestResultDto.fromJson(Map<String, dynamic> json) {
    return OtpRequestResultDto(
      sent: json['sent'] as bool? ?? true,
      otpTtlSeconds: json['otpTtlSeconds'] as int? ?? 300,
    );
  }
}

class AuthUserDto {
  const AuthUserDto({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    this.role = 'CUSTOMER',
  });

  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String role;

  factory AuthUserDto.fromJson(Map<String, dynamic> json) {
    return AuthUserDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'CUSTOMER',
    );
  }
}

class AuthTokensDto {
  const AuthTokensDto({
    required this.accessToken,
    required this.expiresInSeconds,
    this.refreshToken,
    this.refreshExpiresInSeconds,
    this.tokenType = 'Bearer',
    this.user,
  });

  final String accessToken;
  final int expiresInSeconds;
  final String? refreshToken;
  final int? refreshExpiresInSeconds;
  final String tokenType;
  final AuthUserDto? user;

  factory AuthTokensDto.fromJson(Map<String, dynamic> json) {
    return AuthTokensDto(
      accessToken: json['accessToken'] as String,
      expiresInSeconds: json['expiresInSeconds'] as int? ?? 3600,
      refreshToken: json['refreshToken'] as String?,
      refreshExpiresInSeconds: json['refreshExpiresInSeconds'] as int?,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      user: json['user'] is Map<String, dynamic>
          ? AuthUserDto.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}
