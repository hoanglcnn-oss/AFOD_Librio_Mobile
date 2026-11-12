import 'package:dio/dio.dart';

/// Ánh xạ mã lý do từ chối gia hạn của Backend sang thông báo tiếng Việt dễ hiểu
String? mapRenewalReasonCode(String? reasonCode) {
  if (reasonCode == null) return null;
  switch (reasonCode.trim().toUpperCase()) {
    case 'ACTIVE_RESERVATION':
      return 'Sách đang có người đặt trước, không thể gia hạn.';
    case 'MAX_RENEWALS_REACHED':
      return 'Đã đạt giới hạn số lần gia hạn cho phép.';
    case 'OVERDUE':
      return 'Sách đã quá hạn mượn, không thể gia hạn.';
    case 'INVALID_STATUS':
      return 'Trạng thái mượn sách không hợp lệ để gia hạn.';
    case 'OUTSIDE_RENEWAL_WINDOW':
      return 'Chưa đến hoặc đã qua khoảng thời gian được phép gia hạn.';
    case 'NOT_OWNER':
      return 'Bạn không phải người mượn cuốn sách này.';
    default:
      return null;
  }
}

/// Lấy thông báo lỗi thân thiện cho chức năng gia hạn
String getRenewalErrorMessage(Object error, {String? reasonCode}) {
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
    String? extractedReasonCode = reasonCode;

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

      if (extractedReasonCode == null || extractedReasonCode.isEmpty) {
        final code = data['reasonCode'] ??
            data['code'] ??
            (data['details'] is Map ? data['details']['reasonCode'] : null) ??
            (data['details'] is Map ? data['details']['code'] : null);
        if (code is String && code.isNotEmpty) {
          extractedReasonCode = code;
        }
      }
    }

    // Lọc bỏ các từ kỹ thuật chung chung của HTTP status code, không hiển thị trực tiếp cho người dùng
    const technicalWords = {
      'conflict',
      'forbidden',
      'bad request',
      'unauthorized',
      'not found',
      'internal server error',
    };

    if (backendMessage != null &&
        technicalWords.contains(backendMessage.toLowerCase())) {
      backendMessage = null;
    }

    // Ưu tiên hiển thị thông báo nghiệp vụ cụ thể từ Backend
    if (backendMessage != null && backendMessage.isNotEmpty) {
      return backendMessage;
    }

    // Ánh xạ theo reasonCode nếu có
    final mappedReason = mapRenewalReasonCode(extractedReasonCode);
    if (mappedReason != null && mappedReason.isNotEmpty) {
      return mappedReason;
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

  final mappedReason = mapRenewalReasonCode(reasonCode);
  if (mappedReason != null && mappedReason.isNotEmpty) {
    return mappedReason;
  }

  return 'Đã xảy ra lỗi khi xử lý gia hạn.';
}
