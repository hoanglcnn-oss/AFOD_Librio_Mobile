import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/borrowing/renewal/errors/renewal_error_mapper.dart';

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

    test('Không hiển thị trực tiếp "Conflict", mapping theo reasonCode khi message kỹ thuật', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/borrowings/1/renew'),
        response: Response(
          requestOptions: RequestOptions(path: '/borrowings/1/renew'),
          statusCode: 409,
          data: {
            'message': 'Conflict',
            'reasonCode': 'ACTIVE_RESERVATION',
          },
        ),
      );

      final message = getRenewalErrorMessage(error);
      expect(message, 'Sách đang có người đặt trước, không thể gia hạn.');
      expect(message, isNot(contains('Conflict')));
    });

    test('Không hiển thị trực tiếp "Forbidden", fallback HTTP 403 khi không có reasonCode', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/borrowings/1/renew'),
        response: Response(
          requestOptions: RequestOptions(path: '/borrowings/1/renew'),
          statusCode: 403,
          data: {'error': 'Forbidden'},
        ),
      );

      final message = getRenewalErrorMessage(error);
      expect(message, 'Bạn không có quyền gia hạn hoặc sách không đủ điều kiện gia hạn.');
      expect(message, isNot(contains('Forbidden')));
    });

    group('Ánh xạ các mã reasonCode nghiệp vụ', () {
      test('ACTIVE_RESERVATION -> Sách đang có người đặt trước', () {
        expect(
          mapRenewalReasonCode('ACTIVE_RESERVATION'),
          'Sách đang có người đặt trước, không thể gia hạn.',
        );
      });

      test('MAX_RENEWALS_REACHED -> Đã đạt giới hạn số lần gia hạn', () {
        expect(
          mapRenewalReasonCode('MAX_RENEWALS_REACHED'),
          'Đã đạt giới hạn số lần gia hạn cho phép.',
        );
      });

      test('OVERDUE -> Sách đã quá hạn mượn', () {
        expect(
          mapRenewalReasonCode('OVERDUE'),
          'Sách đã quá hạn mượn, không thể gia hạn.',
        );
      });

      test('INVALID_STATUS -> Trạng thái mượn sách không hợp lệ', () {
        expect(
          mapRenewalReasonCode('INVALID_STATUS'),
          'Trạng thái mượn sách không hợp lệ để gia hạn.',
        );
      });

      test('OUTSIDE_RENEWAL_WINDOW -> Chưa đến hoặc đã qua khoảng thời gian được phép', () {
        expect(
          mapRenewalReasonCode('OUTSIDE_RENEWAL_WINDOW'),
          'Chưa đến hoặc đã qua khoảng thời gian được phép gia hạn.',
        );
      });

      test('NOT_OWNER -> Bạn không phải người mượn cuốn sách này', () {
        expect(
          mapRenewalReasonCode('NOT_OWNER'),
          'Bạn không phải người mượn cuốn sách này.',
        );
      });

      test('Lấy reasonCode từ data.code hoặc data.details.reasonCode', () {
        final errorNested = DioException(
          requestOptions: RequestOptions(path: '/borrowings/1/renew'),
          response: Response(
            requestOptions: RequestOptions(path: '/borrowings/1/renew'),
            statusCode: 400,
            data: {
              'details': {'reasonCode': 'OVERDUE'},
            },
          ),
        );

        expect(
          getRenewalErrorMessage(errorNested),
          'Sách đã quá hạn mượn, không thể gia hạn.',
        );
      });
    });

    test('Fallback HTTP status codes khi không có backend message (400, 403, 404, 409, 500)', () {
      final cases = [
        (400, 'Yêu cầu gia hạn không hợp lệ. Vui lòng kiểm tra lại điều kiện gia hạn.'),
        (403, 'Bạn không có quyền gia hạn hoặc sách không đủ điều kiện gia hạn.'),
        (404, 'Không tìm thấy thông tin lượt mượn hoặc phiếu mượn.'),
        (409, 'Yêu cầu gia hạn bị xung đột hoặc trạng thái phiếu đã thay đổi. Vui lòng tải lại.'),
        (500, 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.'),
      ];

      for (final (statusCode, expectedMessage) in cases) {
        final error = DioException(
          requestOptions: RequestOptions(path: '/borrowings/1/renew'),
          response: Response(
            requestOptions: RequestOptions(path: '/borrowings/1/renew'),
            statusCode: statusCode,
            data: null,
          ),
        );

        final message = getRenewalErrorMessage(error);
        expect(message, expectedMessage);
      }
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
