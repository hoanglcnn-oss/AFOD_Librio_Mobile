import 'package:week34_project/features/auth/data/auth_repository.dart';
import 'package:week34_project/features/auth/data/models/auth_response.dart';
import 'package:week34_project/features/auth/data/models/user_profile.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthResponse> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    if (email == 'test@example.com' && password == '123456') {
      return _fakeResponse(email);
    }

    throw Exception('Email hoặc mật khẩu không đúng');
  }

  @override
  Future<AuthResponse> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    return _fakeResponse(email, fullName: fullName, phone: phone);
  }

  AuthResponse _fakeResponse(
    String email, {
    String fullName = 'Test User',
    String phone = '0901234567',
  }) {
    return AuthResponse(
      accessToken: 'fake_token',
      tokenType: 'Bearer',
      expiresIn: 86400,
      user: UserProfile(
        id: 'fake-user-01',
        email: email,
        phone: phone,
        fullName: fullName,
        role: 'MEMBER',
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  }

  @override
  Future<UserProfile> getCurrentUser(String token) async {
    if (token != 'fake_token') {
      throw Exception('Token không hợp lệ');
    }

    return UserProfile(
      id: 'fake-user-01',
      email: 'test@example.com',
      phone: '0901234567',
      fullName: 'Test User',
      role: 'MEMBER',
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    );
  }
}
