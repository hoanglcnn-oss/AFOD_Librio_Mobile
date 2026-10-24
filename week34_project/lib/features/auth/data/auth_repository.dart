abstract class AuthRepository {
  Future<void> login(String email, String password);

  Future<void> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  });
}
