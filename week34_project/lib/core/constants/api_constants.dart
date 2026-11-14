class ApiConstants {
  //private constructor, ngăn việc tạo object không cần thiết từ class này.
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.leorank.site/api',
  );

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String forgotPassword = '/auth/forgot-password';

  static const String books = '/books';
  static const String borrowings = '/borrowings';
  static const String borrowingSlips = '/borrowing-slips';
  static const String members = '/members';
  static const String reservations = '/reservations';
}
