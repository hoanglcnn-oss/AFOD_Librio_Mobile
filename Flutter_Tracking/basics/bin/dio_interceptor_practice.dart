import 'package:dio/dio.dart';

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  // Gắn một InterceptorsWrapper vào dio.interceptors.
  dio.interceptors.add(
    InterceptorsWrapper(
      // Trong onRequest:
      // In method + URL của request.
      // Gọi handler.next(options).
      onRequest: (options, handler) {
        print('Request: ${options.method} ${options.uri}');
        handler.next(options);
      },

      // Trong onResponse:
      // In HTTP status code.
      // Gọi handler.next(response).
      onResponse: (response, handler) {
        print('Response: ${response.statusCode}');
        handler.next(response);
      },

      // Trong onError:
      // In loại lỗi và HTTP status nếu có.
      // Gọi handler.next(error).
      onError: (error, handler) {
        print('Error: ${error.type}');
        print('Error: ${error.message}');
        handler.next(error);
      },
    ),
  );

  try {
    // GET tới 'posts/1'.
    // In 'GET 1 hoàn thành' nếu thành công.
    await dio.get('posts/1');
    print('GET 1 hoàn thành');

    // GET tới 'posts/999999'.
    // Request này dự kiến ném DioException.
    await dio.get('posts/999999');
  } on DioException catch (e) {
    print('Caught in main: ${e.type}');
  } finally {
    dio.close();
  }
}
