import 'package:dio/dio.dart';

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );

  try {
    // Gửi GET request đến endpoint '/posts'.
    // Dùng await, lưu kết quả vào biến response.
    final response = await dio.get('posts');

    // In HTTP status code.
    print('Status: ${response.statusCode}');

    // In kiểu dữ liệu thực tế của response.data.
    print('Data type: ${response.data.runtimeType}');

    // Nếu response.data là List và không rỗng, in phần tử đầu tiên.
    if (response.data is List && (response.data as List).isNotEmpty) {
      print('First post: ${response.data[0]}');
    }
  } on DioException catch (e) {
    print('Request failed: ${e.message}');
  } finally {
    dio.close();
  }
}
