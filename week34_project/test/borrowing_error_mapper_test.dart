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
}
