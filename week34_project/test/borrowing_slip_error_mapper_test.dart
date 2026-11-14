import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowing/shared/errors/borrowing_slip_error_mapper.dart';

void main() {
  final requestOptions = RequestOptions(path: '/borrowing-slips');

  group('BorrowingSlipErrorMapper', () {
    test('HTTP 400 | trả thông báo lỗi nghiệp vụ mặc định khi không có message', () {
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 400),
        type: DioExceptionType.badResponse,
      );

      final message = getBorrowingSlipErrorMessage(error);
      expect(message, contains('Không đủ điều kiện tạo phiếu mượn'));
    });

    test('Connection timeout | cảnh báo kiểm tra danh sách phiếu mượn', () {
      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionTimeout,
      );

      final message = getBorrowingSlipErrorMessage(error);
      expect(message, contains('kiểm tra danh sách phiếu mượn'));
    });

    test('HTTP 400 vượt hạn mức | hiển thị thông báo Backend', () {
      const backendMessage =
          'Vượt quá hạn mức mượn: độc giả đang giữ 4/5 cuốn, chỉ còn được mượn thêm 1 cuốn nhưng yêu cầu 2 cuốn';

      final error = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 400,
          data: {
            'statusCode': 400,
            'message': backendMessage,
            'error': 'Bad Request',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final message = getBorrowingSlipErrorMessage(error);
      expect(message, backendMessage);
    });

    test('HTTP 400 hết sách | hiển thị không đủ số lượng', () {
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 400,
          data: {
            'message': 'Sách hiện tại không còn đủ bản in để mượn',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final message = getBorrowingSlipErrorMessage(error);
      expect(message, contains('không đủ số lượng'));
    });

    test('HTTP 409 tranh chấp tồn kho | hiển thị thông báo tải lại', () {
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 409,
          data: {
            'message': 'Sách vừa được độc giả khác mượn hết',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final message = getBorrowingSlipErrorMessage(error);
      expect(message, contains('không còn đủ số lượng'));
    });

    test('HTTP 409 xung đột khác | hiển thị thông báo xung đột', () {
      final error = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 409,
          data: {
            'message': 'Phiếu mượn đã bị thay đổi',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final message = getBorrowingSlipErrorMessage(error);
      expect(message, contains('xung đột'));
    });
  });
}

