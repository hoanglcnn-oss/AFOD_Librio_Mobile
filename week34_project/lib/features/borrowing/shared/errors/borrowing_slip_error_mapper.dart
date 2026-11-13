import 'package:dio/dio.dart';

/// Ánh xạ lỗi khi tạo phiếu mượn nhiều sách (/borrowing-slips)
String getBorrowingSlipErrorMessage(Object error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Không thể xác nhận kết quả tạo phiếu mượn. '
          'Vui lòng kiểm tra danh sách phiếu mượn trước khi thử lại.';
    }

    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    String? backendMessage;

    if (data is Map) {
      final message = data['message'];

      if (message is String) {
        backendMessage = message.trim();
      } else if (message is List) {
        backendMessage = message.whereType<String>().join('\n').trim();
        if (backendMessage.isEmpty) backendMessage = null;
      }
    }

    switch (statusCode) {
      case 400:
        if (backendMessage != null &&
            (backendMessage.contains('hết bản in sẵn có') ||
                backendMessage.contains('không còn đủ bản in'))) {
          return 'Rất tiếc, một số sách trong phiếu hiện đã hết hoặc không đủ số lượng. '
              'Vui lòng kiểm tra lại.';
        }

        if (backendMessage != null && backendMessage.isNotEmpty) {
          return backendMessage;
        }

        return 'Không đủ điều kiện tạo phiếu mượn. '
            'Vui lòng kiểm tra hạn thẻ, hạn mức hoặc số lượng sách.';

      case 401:
        return 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn. '
            'Vui lòng đăng nhập lại.';

      case 404:
        return 'Không tìm thấy sách hoặc hồ sơ độc giả.';

      case 409:
        if (backendMessage != null &&
            (backendMessage.contains('vừa được độc giả khác mượn hết') ||
                backendMessage.contains('cuốn khả dụng trong kho') ||
                backendMessage.contains('không đủ số lượng'))) {
          return 'Rất tiếc, sách trong phiếu không còn đủ số lượng '
              'để mượn. Có thể sách vừa được thành viên khác mượn. '
              'Vui lòng tải lại.';
        }

        return 'Yêu cầu tạo phiếu mượn bị xung đột. '
            'Vui lòng kiểm tra lại trạng thái.';

      case 500:
        return 'Máy chủ đang gặp sự cố.';

      default:
        return 'Không thể tạo phiếu mượn sách. Vui lòng thử lại sau.';
    }
  }

  return 'Đã xảy ra lỗi khi xử lý yêu cầu tạo phiếu mượn.';
}

