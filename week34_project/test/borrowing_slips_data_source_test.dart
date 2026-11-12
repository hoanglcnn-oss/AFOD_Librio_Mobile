import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/borrowing_slips/data/datasources/borrowing_slips_remote_data_source.dart';

void main() {
  group('BorrowingSlipsRemoteDataSourceImpl', () {
    test(
      'createBorrowingSlip | Có 2 sách và JWT | POST /borrowing-slips, đúng body và Authorization',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              expect(options.method, 'POST');
              expect(options.path, '/borrowing-slips');
              expect(options.headers['Authorization'], 'Bearer test-token');

              final body = options.data as Map<String, dynamic>;

              expect(body['memberId'], 'mem-01');
              expect(body['expectedReturnDays'], 14);

              final items = body['items'] as List<dynamic>;
              expect(items.length, 2);
              expect(items[0], {'bookId': 'book-01', 'quantity': 1});
              expect(items[1], {'bookId': 'book-02', 'quantity': 2});

              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {'id': 'slip-01', 'status': 'PENDING_APPROVAL'},
                ),
              );
            },
          ),
        );

        final dataSource = BorrowingSlipsRemoteDataSourceImpl(dio: dio);

        final result = await dataSource.createBorrowingSlip(
          token: 'test-token',
          data: {
            'memberId': 'mem-01',
            'items': [
              {'bookId': 'book-01', 'quantity': 1},
              {'bookId': 'book-02', 'quantity': 2},
            ],
            'expectedReturnDays': 14,
          },
        );

        expect(result['id'], 'slip-01');
        expect(result['status'], 'PENDING_APPROVAL');
      },
    );
  });
}

