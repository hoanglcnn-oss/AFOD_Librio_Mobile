import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowings/data/borrowing_error_mapper.dart';

void main() {
  final requestOptions = RequestOptions(path: '/borrowings');

  // Event | Điều kiện đầu vào | Kết quả được kiểm chứng
  test('BorrowingErrorMapper | HTTP 400 | trả thông báo lỗi nghiệp vụ', () {
    final error = DioException(
      requestOptions: requestOptions,
      response: Response(requestOptions: requestOptions, statusCode: 400),
      type: DioExceptionType.badResponse,
    );

    final message = getBorrowingErrorMessage(error);

    expect(message, contains('Không đủ điều kiện'));
  });

  test(
    'BorrowingErrorMapper | Connection timeout | cảnh báo kiểm tra trạng thái phiếu mượn',
    () {
      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionTimeout,
      );

      final message = getBorrowingErrorMessage(error);

      expect(message, contains('kiểm tra phiếu mượn'));
    },
  );

  test(
    'BorrowingErrorMapper | HTTP 400 vượt hạn mức | hiển thị thông báo Backend',
    () {
      final options = RequestOptions(path: '/borrowing-slips');

      const backendMessage =
          'Vượt quá hạn mức mượn: độc giả đang giữ '
          '4/5 cuốn, chỉ còn được mượn thêm 1 cuốn '
          'nhưng yêu cầu 2 cuốn';

      final error = DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 400,
          data: {
            'statusCode': 400,
            'message': backendMessage,
            'error': 'Bad Request',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final message = getBorrowingErrorMessage(error);

      expect(message, backendMessage);
    },
  );

  test(
    'BorrowingErrorMapper | HTTP 400 lỗi nghiệp vụ khác | ưu tiên hiển thị message từ Backend',
    () {
      final options = RequestOptions(path: '/borrowing-slips');

      const customBackendMessage =
          'Thẻ độc giả đã hết hạn. Vui lòng gia hạn thẻ để tiếp tục mượn sách.';

      final error = DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 400,
          data: {
            'statusCode': 400,
            'message': customBackendMessage,
            'error': 'Bad Request',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final message = getBorrowingErrorMessage(error);

      expect(message, customBackendMessage);
    },
  );

  test('BorrowingErrorMapper | HTTP 400 hết sách | hiển thị hết hàng', () {
    final options = RequestOptions(path: '/borrowings');

    final error = DioException(
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: 400,
        data: {
          'message':
              'Cuốn sách "Clean Code" hiện tại đã hết bản in sẵn có để mượn',
        },
      ),
      type: DioExceptionType.badResponse,
    );

    final message = getBorrowingErrorMessage(error);

    expect(message, contains('đã hết'));
  });

  test(
    'BorrowingErrorMapper | HTTP 409 tranh bản cuối | hiển thị không đủ sách',
    () {
      final options = RequestOptions(path: '/borrowings');

      final error = DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 409,
          data: {
            'message':
                'Sách "Clean Code" vừa được độc giả khác mượn hết. '
                'Số lượng khả dụng không còn đủ 1 cuốn, '
                'giao dịch đã được hủy bỏ',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final message = getBorrowingErrorMessage(error);

      expect(message, contains('không còn đủ số lượng'));
      expect(message, contains('thành viên khác'));
    },
  );

  test(
    'BorrowingErrorMapper | HTTP 409 thiếu tồn kho | hiển thị không đủ sách',
    () {
      final options = RequestOptions(path: '/borrowing-slips');

      final error = DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 409,
          data: {
            'message':
                'Sách "Clean Code" chỉ còn 1 cuốn khả dụng trong kho, '
                'không đủ số lượng yêu cầu (2)',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final message = getBorrowingErrorMessage(error);

      expect(message, contains('không còn đủ số lượng'));
    },
  );

  test(
    'BorrowingErrorMapper | HTTP 409 phiếu đã xử lý | không báo hết sách',
    () {
      final options = RequestOptions(path: '/borrowing-slips/slip-01/approve');

      final error = DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 409,
          data: {
            'message': 'DOCUMENT_ALREADY_PROCESSED: Phiếu mượn đã được xử lý',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final message = getBorrowingErrorMessage(error);

      expect(message, contains('xung đột'));
      expect(message, isNot(contains('không còn đủ số lượng')));
    },
  );
}
