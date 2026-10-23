import 'package:dio/dio.dart';

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  try {
    // Tạo Map postData gồm:
    // title: 'Learning Dio'
    // body: 'My first POST request'
    // userId: 1
    final postData = {
      'title': 'Learning Dio',
      'body': 'My first POST request',
      'userId': 1,
    };

    // Gửi POST request đến 'posts'.
    // Truyền postData vào tham số data.
    // Lưu kết quả vào response.
    final response = await dio.post('posts', data: postData);

    // In HTTP status code.
    print('Status: ${response.statusCode}');

    // In response body.
    print('Response data: ${response.data}');

    // Nếu response.data là Map,
    // in id được server trả về.
    if (response.data is Map) {
      print('Created ID: ${response.data['id']}');
    }
  } on DioException catch (e) {
    print('Request failed: ${e.message}');
  } finally {
    dio.close();
  }
}
