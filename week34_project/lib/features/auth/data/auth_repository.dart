abstract class AuthRepository {
  // Khai báo phương thức login()
  // - nhận String email
  // - nhận String password
  // - trả Future<void>
  // - không có phần thân hàm
  Future<void> login(String email, String password);
}
