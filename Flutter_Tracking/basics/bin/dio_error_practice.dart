import 'package:dio/dio.dart';

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  try {
    // TODO 1:
    // Gửi GET request tới 'posts/999999'.
    // Lưu kết quả vào biến response.
    final response = await dio.get('posts/999999');

    print('Success: ${response.statusCode}');
  } on DioException catch (e) {
    // Nếu e.type là badResponse:
    //   - Nếu statusCode == 404: in 'Không tìm thấy dữ liệu'
    //   - Ngược lại: in 'Lỗi HTTP: <statusCode>'

    if (e.type == DioExceptionType.badResponse) {
      if (e.response?.statusCode == 404) {
        print('Không tìm thấy dữ liệu');
      } else {
        print('Lỗi HTTP: ${e.response?.statusCode}');
      }

      // Nếu là connectionError:
      // In 'Không thể kết nối tới server'
    } else if (e.type == DioExceptionType.connectionError) {
      print('Không thể kết nối tới server');

      // Nếu là receiveTimeout:
      // In 'Server phản hồi quá chậm'
    } else if (e.type == DioExceptionType.receiveTimeout) {
      print('Server phản hồi quá chậm');

      // Các lỗi còn lại:
      // In 'Đã xảy ra lỗi không xác định'
    } else {
      print('Đã xảy ra lỗi không xác định');
    }
  } finally {
    dio.close();
  }
}
