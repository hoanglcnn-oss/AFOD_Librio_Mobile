import 'user_profile.dart';

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final UserProfile user;

  const AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      tokenType: json['tokenType'] as String,
      expiresIn: json['expiresIn'] as int,
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
