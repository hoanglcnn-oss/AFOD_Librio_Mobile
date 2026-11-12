import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/core/errors/renewal_error_mapper.dart';

void main() {
  group('RenewalErrorMapper', () {
    test('Ưu tiên thông báo nghiệp vụ Backend khi HTTP 400', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/borrowings/1/renew'),
        response: Response(
          requestOptions: RequestOptions(path: '/borrowings/1/renew'),
          statusCode: 400,
          data: {'message': 'Đã đạt giới hạn gia hạn tối đa (2 lần).'},
        ),
      );

      final message = getRenewalErrorMessage(error);
      expect(message, 'Đã đạt giới hạn gia hạn tối đa (2 lần).');
    });

    test('Ưu tiên thông báo nghiệp vụ Backend khi HTTP 403', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/borrowing-slips/1/renew'),
        response: Response(
          requestOptions: RequestOptions(path: '/borrowing-slips/1/renew'),
          statusCode: 403,
          data: {'message': 'Thẻ độc giả đã hết hạn, không thể gia hạn.'},
        ),
      );

      final message = getRenewalErrorMessage(error);
      expect(message, 'Thẻ độc giả đã hết hạn, không thể gia hạn.');
    });

    test('Ưu tiên thông báo nghiệp vụ Backend khi HTTP 409', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/borrowing-slips/1/renew'),
        response: Response(
          requestOptions: RequestOptions(path: '/borrowing-slips/1/renew'),
          statusCode: 409,
          data: {'message': 'Phiếu mượn đã bị thay đổi hoặc sách đã trả.'},
        ),
      );

      final message = getRenewalErrorMessage(error);
      expect(message, 'Phiếu mượn đã bị thay đổi hoặc sách đã trả.');
    });

    test('Xử lý message dạng List từ Backend (NestJS ValidationPipe)', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/borrowings/1/renew'),
        response: Response(
          requestOptions: RequestOptions(path: '/borrowings/1/renew'),
          statusCode: 400,
          data: {
            'message': ['extraDays must not be less than 1', 'extraDays must be an integer'],
          },
        ),
      );

      final message = getRenewalErrorMessage(error);
      expect(message, contains('extraDays must not be less than 1'));
      expect(message, contains('extraDays must be an integer'));
    });

    test('Fallback HTTP 400 khi không có backend message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/borrowings/1/renew'),
        response: Response(
          requestOptions: RequestOptions(path: '/borrowings/1/renew'),
          statusCode: 400,
          data: null,
        ),
      );

      final message = getRenewalErrorMessage(error);
      expect(message, 'Yêu cầu gia hạn không hợp lệ. Vui lòng kiểm tra lại điều kiện gia hạn.');
    });

    test('Fallback HTTP 403 khi không có backend message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/borrowings/1/renew'),
        response: Response(
          requestOptions: RequestOptions(path: '/borrowings/1/renew'),
          statusCode: 403,
          data: null,
        ),
      );

      final message = getRenewalErrorMessage(error);
      expect(message, 'Bạn không có quyền gia hạn hoặc sách không đủ điều kiện gia hạn.');
    });

    test('Fallback HTTP 409 khi không có backend message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/borrowings/1/renew'),
        response: Response(
          requestOptions: RequestOptions(path: '/borrowings/1/renew'),
          statusCode: 409,
          data: null,
        ),
      );

      final message = getRenewalErrorMessage(error);
      expect(message, 'Yêu cầu gia hạn bị xung đột hoặc trạng thái phiếu đã thay đổi. Vui lòng tải lại.');
    });

    test('Fallback HTTP 404 khi không tìm thấy', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/borrowings/1/renew'),
        response: Response(
          requestOptions: RequestOptions(path: '/borrowings/1/renew'),
          statusCode: 404,
          data: null,
        ),
      );

      final message = getRenewalErrorMessage(error);
      expect(message, 'Không tìm thấy thông tin lượt mượn hoặc phiếu mượn.');
    });

    test('Fallback HTTP 500 khi server lỗi', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/borrowings/1/renew'),
        response: Response(
          requestOptions: RequestOptions(path: '/borrowings/1/renew'),
          statusCode: 500,
          data: null,
        ),
      );

      final message = getRenewalErrorMessage(error);
      expect(message, 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.');
    });

    test('Lỗi kết nối mạng: connectionTimeout, receiveTimeout, connectionError', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.connectionError,
      ]) {
        final error = DioException(
          requestOptions: RequestOptions(path: '/borrowings/1/renew'),
          type: type,
        );

        final message = getRenewalErrorMessage(error);
        expect(
          message,
          'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng và thử lại.',
        );
      }
    });

    test('ArgumentError và StateError', () {
      expect(
        getRenewalErrorMessage(ArgumentError('Số ngày gia hạn không hợp lệ')),
        contains('Số ngày gia hạn không hợp lệ'),
      );
      expect(
        getRenewalErrorMessage(StateError('Phiên đăng nhập không tồn tại')),
        'Phiên đăng nhập không tồn tại',
      );
    });
  });
}

