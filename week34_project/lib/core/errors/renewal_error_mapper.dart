import 'package:dio/dio.dart';

String getRenewalErrorMessage(Object error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng và thử lại.';
    }

    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    String? backendMessage;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        backendMessage = message.trim();
      } else if (message is List) {
        backendMessage = message.whereType<String>().join('\n').trim();
        if (backendMessage.isEmpty) backendMessage = null;
      }
      backendMessage ??=
          (data['error'] is String ? (data['error'] as String).trim() : null);
    }

    // Luôn ưu tiên hiển thị lỗi nghiệp vụ từ Backend
    if (backendMessage != null && backendMessage.isNotEmpty) {
      return backendMessage;
    }

    switch (statusCode) {
      case 400:
        return 'Yêu cầu gia hạn không hợp lệ. Vui lòng kiểm tra lại điều kiện gia hạn.';
      case 401:
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      case 403:
        return 'Bạn không có quyền gia hạn hoặc sách không đủ điều kiện gia hạn.';
      case 404:
        return 'Không tìm thấy thông tin lượt mượn hoặc phiếu mượn.';
      case 409:
        return 'Yêu cầu gia hạn bị xung đột hoặc trạng thái phiếu đã thay đổi. Vui lòng tải lại.';
      case 500:
      case 502:
      case 503:
        return 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.';
      default:
        return 'Không thể gia hạn sách. Vui lòng thử lại sau.';
    }
  }

  if (error is ArgumentError) {
    return error.message?.toString() ?? 'Thông tin gia hạn không hợp lệ.';
  }

  if (error is StateError) {
    return error.message;
  }

  return 'Đã xảy ra lỗi khi xử lý gia hạn.';
}
