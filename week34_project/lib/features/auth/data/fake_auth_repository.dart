import 'auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<void> login(String email, String password) async {
    // Giả lập thời gian chờ server
    await Future.delayed(const Duration(seconds: 1));

    if (email == 'test@example.com' && password == '123456') {
      return;
    }

    throw Exception('Email hoặc mật khẩu không đúng');
  }
}
