import 'package:dio/dio.dart';

class ReservationErrorMapper {
  ReservationErrorMapper._();

  static bool isTimeout(Object error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout;
    }
    return false;
  }

  static String mapError(Object error, {String fallback = 'Đã xảy ra lỗi, vui lòng thử lại'}) {
    if (error is ArgumentError) {
      return error.message.toString();
    }

    if (error is StateError) {
      return error.message;
    }

    if (error is DioException) {
      if (isTimeout(error)) {
        return 'Hết thời gian kết nối tới máy chủ. Vui lòng kiểm tra lại.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Lỗi kết nối mạng, vui lòng kiểm tra đường truyền.';
      }

      final response = error.response;
      if (response != null) {
        final data = response.data;
        if (data is Map) {
          final msg = data['message'];
          if (msg is String && msg.trim().isNotEmpty) {
            return msg.trim();
          } else if (msg is List && msg.isNotEmpty) {
            return msg.join(', ');
          }
          final err = data['error'];
          if (err is String && err.trim().isNotEmpty) {
            return err.trim();
          }
        }

        switch (response.statusCode) {
          case 400:
            return 'Yêu cầu không hợp lệ. Vui lòng kiểm tra lại.';
          case 403:
            return 'Bạn không có quyền thực hiện thao tác này.';
          case 404:
            return 'Không tìm thấy thông tin đặt trước.';
          case 409:
            return 'Bạn đã có lượt đặt trước đang chờ cho sách này.';
          case 500:
            return 'Máy chủ gặp sự cố, vui lòng thử lại sau.';
        }
      }
    }

    return fallback;
  }
}
