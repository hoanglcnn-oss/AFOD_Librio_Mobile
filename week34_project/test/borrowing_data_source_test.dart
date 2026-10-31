import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/borrowings/data/datasources/borrowings_remote_data_source.dart';

void main() {
  group('BorrowingsRemoteDataSourceImpl', () {
    test(
      'createBorrowing gửi đúng POST method, path, body và Authorization header',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              expect(options.method, 'POST');
              expect(options.path, '/borrowings');
              expect(
                options.headers['Authorization'],
                'Bearer secret-jwt-token',
              );

              final body = options.data as Map<String, dynamic>;
              expect(body['memberId'], 'mem-100');
              expect(body['bookId'], 'book-200');
              expect(body['durationDays'], 14);

              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'id': 'brw-999',
                    'transactionCode': 'BRW-2026-9999',
                    'memberId': 'mem-100',
                    'memberName': 'Test Member',
                    'bookId': 'book-200',
                    'bookTitle': 'Test Book',
                    'borrowDate': '2026-10-31T08:00:00.000Z',
                    'dueDate': '2026-11-14T08:00:00.000Z',
                    'status': 'BORROWED',
                  },
                ),
              );
            },
          ),
        );

        final dataSource = BorrowingsRemoteDataSourceImpl(dio: dio);
        final result = await dataSource.createBorrowing(
          data: {
            'memberId': 'mem-100',
            'bookId': 'book-200',
            'durationDays': 14,
          },
          token: 'secret-jwt-token',
        );

        expect(result['id'], 'brw-999');
        expect(result['transactionCode'], 'BRW-2026-9999');
        expect(result['status'], 'BORROWED');
      },
    );
  });
}
