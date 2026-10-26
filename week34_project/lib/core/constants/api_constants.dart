class ApiConstants {
  //private constructor, ngăn việc tạo object không cần thiết từ class này.
  ApiConstants._();

  static const String baseUrl = 'https://api.leorank.site/api';

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
}
