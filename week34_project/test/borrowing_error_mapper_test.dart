import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowings/data/borrowing_error_mapper.dart';

void main() {
  final requestOptions = RequestOptions(path: '/borrowings');

  test('HTTP 400 trả thông báo lỗi nghiệp vụ', () {
    final error = DioException(
      requestOptions: requestOptions,
      response: Response(requestOptions: requestOptions, statusCode: 400),
      type: DioExceptionType.badResponse,
    );

    final message = getBorrowingErrorMessage(error);

    expect(message, contains('Không đủ điều kiện'));
  });

  test('Connection timeout cảnh báo kiểm tra phiếu mượn', () {
    final error = DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.connectionTimeout,
    );

    final message = getBorrowingErrorMessage(error);

    expect(message, contains('kiểm tra phiếu mượn'));
  });
}
