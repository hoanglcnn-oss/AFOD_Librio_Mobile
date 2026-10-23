import 'package:dio/dio.dart';

void main() {
  // Tạo Dio instance bằng Dio(BaseOptions(...)).
  final dio = Dio(
    BaseOptions(
      // Base URL của API giả lập dùng để thực hành. https://jsonplaceholder.typicode.com/
      baseUrl: 'https://jsonplaceholder.typicode.com/',
      // Khai báo connectTimeout 10 giây.
      connectTimeout: Duration(seconds: 10),
      // Khai báo receiveTimeout 15 giây.
      receiveTimeout: Duration(seconds: 15),
      // Thêm header Accept: application/json.
      headers: {'Accept': 'application/json'},
    ),
  );

  // Đọc cấu hình, KHÔNG gửi HTTP request.
  print('Base URL: ${dio.options.baseUrl}');
  print('Connect timeout: ${dio.options.connectTimeout}');
  print('Receive timeout: ${dio.options.receiveTimeout}');
  print('Headers: ${dio.options.headers}');

  dio.close();
}
