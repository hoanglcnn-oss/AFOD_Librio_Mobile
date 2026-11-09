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
    test('getBorrowings gửi đúng GET, query parameters và JWT', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // 1. Kiểm tra HTTP request
            expect(options.method, 'GET');
            expect(options.path, '/borrowings');

            // 2. Kiểm tra query parameters
            expect(options.queryParameters['memberId'], 'mem-01');
            expect(options.queryParameters['page'], 2);
            expect(options.queryParameters['limit'], 5);

            // 3. Kiểm tra JWT
            expect(options.headers['Authorization'], 'Bearer test-jwt');

            // 4. Giả lập API trả về JSON phân trang
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': [
                    {
                      'id': 'brw-02',
                      'bookTitle': 'Flutter Basics',
                      'status': 'BORROWED',
                    },
                  ],
                  'meta': {
                    'page': 2,
                    'limit': 5,
                    'totalItems': 6,
                    'totalPages': 2,
                    'hasNextPage': false,
                  },
                },
              ),
            );
          },
        ),
      );

      final dataSource = BorrowingsRemoteDataSourceImpl(dio: dio);

      final result = await dataSource.getBorrowings(
        memberId: 'mem-01',
        token: 'test-jwt',
        page: 2,
        limit: 5,
      );

      // 5. Kiểm tra dữ liệu DataSource trả về
      expect((result['data'] as List).length, 1);
      expect(result['meta']['page'], 2);
      expect(result['meta']['totalItems'], 6);
      expect(result['meta']['hasNextPage'], false);
    });
  });
}
