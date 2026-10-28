import 'package:dio/dio.dart';

String getBorrowingErrorMessage(Object error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Không thể xác nhận kết quả mượn sách. '
          'Vui lòng kiểm tra phiếu mượn trước khi thử lại.';
    }

    final statusCode = error.response?.statusCode;

    switch (statusCode) {
      case 400:
        return 'Không đủ điều kiện mượn sách. '
            'Vui lòng kiểm tra hạn thẻ, hạn mức hoặc số lượng sách.';
      case 404:
        return 'Không tìm thấy sách hoặc hồ sơ độc giả.';
      case 409:
        return 'Yêu cầu mượn sách bị xung đột.';
      case 500:
        return 'Máy chủ đang gặp sự cố.';
      default:
        return 'Không thể tạo phiếu mượn sách.';
    }
  }

  return 'Đã xảy ra lỗi khi xử lý yêu cầu mượn sách.';
}
