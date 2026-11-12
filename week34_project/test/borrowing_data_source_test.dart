import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/borrowings/data/datasources/borrowings_remote_data_source.dart';

void main() {
  group('BorrowingsRemoteDataSourceImpl', () {
    // Event | Điều kiện đầu vào | Kết quả được kiểm chứng
    test(
      'createBorrowing | Dữ liệu mượn hợp lệ | POST /borrowings, đúng body và JWT',
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
    test(
      'getBorrowings | Có memberId và phân trang | GET /borrowings, đúng queryParameters và JWT',
      () async {
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
      },
    );
    test(
      'returnBook | Có borrowingId và JWT | POST /borrowings/:id/return, đúng body',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              expect(options.method, 'POST');
              expect(options.path, '/borrowings/brw-01/return');
              expect(options.headers['Authorization'], 'Bearer test-token');
              expect(options.data, {'finePaid': false});

              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'id': 'brw-01', 'status': 'RETURNED'},
                ),
              );
            },
          ),
        );

        final dataSource = BorrowingsRemoteDataSourceImpl(dio: dio);

        final result = await dataSource.returnBook(
          borrowingId: 'brw-01',
          token: 'test-token',
          data: {'finePaid': false},
        );

        expect(result['status'], 'RETURNED');
      },
    );
    test(
      'renewLoan | Có borrowingId và extraDays = 7 | POST /borrowings/:id/renew, đúng body và JWT',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              expect(options.method, 'POST');
              expect(options.path, '/borrowings/brw-01/renew');
              expect(options.headers['Authorization'], 'Bearer test-token');
              expect(options.data, {'extraDays': 7});

              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'id': 'brw-01',
                    'dueDate': '2026-11-21T08:00:00Z',
                    'renewCount': 1,
                  },
                ),
              );
            },
          ),
        );

        final dataSource = BorrowingsRemoteDataSourceImpl(dio: dio);

        final result = await dataSource.renewLoan(
          borrowingId: 'brw-01',
          token: 'test-token',
          extraDays: 7,
        );

        expect(result['renewCount'], 1);
      },
    );

    test(
      'payFine | Có borrowingId | POST /borrowings/:id/pay-fine, đúng JWT và parse response',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              expect(options.method, 'POST');
              expect(options.path, '/borrowings/brw-01/pay-fine');
              expect(options.headers['Authorization'], 'Bearer test-token');

              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'id': 'brw-01',
                    'status': 'RETURNED',
                    'fineAmount': 50000,
                    'finePaid': true,
                  },
                ),
              );
            },
          ),
        );

        final dataSource = BorrowingsRemoteDataSourceImpl(dio: dio);

        final result = await dataSource.payFine(
          borrowingId: 'brw-01',
          token: 'test-token',
        );

        expect(result['id'], 'brw-01');
        expect(result['finePaid'], true);
        expect(result['fineAmount'], 50000);
      },
    );

    test(
      'getBorrowingById | Có borrowingId | GET /borrowings/:id, đúng JWT và trả về dữ liệu',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              expect(options.method, 'GET');
              expect(options.path, '/borrowings/brw-01');
              expect(options.headers['Authorization'], 'Bearer test-token');

              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'id': 'brw-01',
                    'transactionCode': 'BRW-2026-0001',
                    'memberId': 'mem-01',
                    'memberName': 'Nguyễn Văn An',
                    'bookId': 'book-01',
                    'bookTitle': 'Clean Code',
                    'borrowDate': '2026-10-29T08:00:00.000Z',
                    'dueDate': '2026-11-12T08:00:00.000Z',
                    'status': 'BORROWED',
                    'renewCount': 0,
                    'canRenew': true,
                  },
                ),
              );
            },
          ),
        );

        final dataSource = BorrowingsRemoteDataSourceImpl(dio: dio);

        final result = await dataSource.getBorrowingById(
          borrowingId: 'brw-01',
          token: 'test-token',
        );

        expect(result['id'], 'brw-01');
        expect(result['status'], 'BORROWED');
        expect(result['canRenew'], isTrue);
      },
    );
  });
}
