import 'models/auth_response.dart';
import 'models/user_profile.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(String email, String password);

  Future<AuthResponse> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  });

  Future<UserProfile> getCurrentUser(String token);
}
