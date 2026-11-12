import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowings/data/api_borrowing_repository.dart';
import 'package:week34_project/features/borrowings/data/models/create_borrowing_request.dart';
import 'fake/fake_token_storage.dart';

void main() {
  test(
    'borrowBook | Có JWT và request hợp lệ | POST /borrowings, parse đúng Borrowing',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveToken('test-token');

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'POST');
            expect(options.path, '/borrowings');
            expect(options.headers['Authorization'], 'Bearer test-token');

            final body = options.data as Map<String, dynamic>;
            expect(body['memberId'], 'mem-01');
            expect(body['bookId'], 'book-01');
            expect(body['durationDays'], 14);

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 201,
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
                },
              ),
            );
          },
        ),
      );

      final repository = ApiBorrowingRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      const request = CreateBorrowingRequest(
        memberId: 'mem-01',
        bookId: 'book-01',
        durationDays: 14,
      );

      final borrowing = await repository.borrowBook(request);

      expect(borrowing.id, 'brw-01');
      expect(borrowing.transactionCode, 'BRW-2026-0001');
      expect(borrowing.memberName, 'Nguyễn Văn An');
      expect(borrowing.bookTitle, 'Clean Code');
      expect(borrowing.status, 'BORROWED');
      expect(borrowing.dueDate.day, 12);
    },
  );

  test(
    'borrowBook | Thiếu JWT | throw StateError, không gửi request',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
      final tokenStorage = FakeTokenStorage();

      var requestSent = false;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestSent = true;
            handler.next(options);
          },
        ),
      );

      final repository = ApiBorrowingRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      const request = CreateBorrowingRequest(
        memberId: 'mem-01',
        bookId: 'book-01',
      );

      await expectLater(
        repository.borrowBook(request),
        throwsA(isA<StateError>()),
      );

      expect(requestSent, false);
    },
  );

  test(
    'getBorrowings | Có JWT và memberId | GET /borrowings, parse đúng BorrowingsPage',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveToken('test-token');

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'GET');
            expect(options.path, '/borrowings');
            expect(options.headers['Authorization'], 'Bearer test-token');
            expect(options.queryParameters['memberId'], 'mem-01');
            expect(options.queryParameters['page'], 1);
            expect(options.queryParameters['limit'], 10);

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': [
                    {
                      'id': 'brw-01',
                      'transactionCode': 'BRW-2026-0001',
                      'memberId': 'mem-01',
                      'memberName': 'Nguyễn Văn An',
                      'bookId': 'book-01',
                      'bookTitle': 'Clean Code',
                      'borrowDate': '2026-10-29T08:00:00.000Z',
                      'dueDate': '2026-11-12T08:00:00.000Z',
                      'status': 'BORROWED',
                    },
                  ],
                  'meta': {
                    'page': 1,
                    'limit': 10,
                    'totalItems': 1,
                    'totalPages': 1,
                    'hasNextPage': false,
                  },
                },
              ),
            );
          },
        ),
      );

      final repository = ApiBorrowingRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      final page = await repository.getBorrowings(memberId: 'mem-01');

      expect(page.borrowings.length, 1);
      expect(page.borrowings.first.id, 'brw-01');
      expect(page.page, 1);
      expect(page.totalPages, 1);
      expect(page.hasNextPage, false);
    },
  );

  test(
    'getBorrowings | Thiếu JWT | throw StateError, không gửi request',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
      final tokenStorage = FakeTokenStorage();

      var requestSent = false;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestSent = true;
            handler.next(options);
          },
        ),
      );

      final repository = ApiBorrowingRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      await expectLater(
        repository.getBorrowings(memberId: 'mem-01'),
        throwsA(isA<StateError>()),
      );

      expect(requestSent, false);
    },
  );

  test(
    'returnBook | Có JWT và borrowingId | POST /borrowings/:id/return, parse trạng thái RETURNED',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveToken('test-token');

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'POST');
            expect(options.path, '/borrowings/brw-01/return');
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
                  'status': 'RETURNED',
                },
              ),
            );
          },
        ),
      );

      final repository = ApiBorrowingRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      final borrowing = await repository.returnBook(borrowingId: 'brw-01');

      expect(borrowing.status, 'RETURNED');
    },
  );

  test(
    'returnBook | Thiếu JWT | throw StateError, không gửi request',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
      final tokenStorage = FakeTokenStorage();

      var requestSent = false;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestSent = true;
            handler.next(options);
          },
        ),
      );

      final repository = ApiBorrowingRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      await expectLater(
        repository.returnBook(borrowingId: 'brw-01'),
        throwsA(isA<StateError>()),
      );

      expect(requestSent, false);
    },
  );

  test(
    'renewLoan | Có JWT và extraDays = 7 | POST /borrowings/:id/renew, parse dueDate và renewCount',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveToken('test-token');

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'POST');
            expect(options.path, '/borrowings/brw-01/renew');
            expect(options.headers['Authorization'], 'Bearer test-token');

            final body = options.data as Map<String, dynamic>;
            expect(body['extraDays'], 7);

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
                  'dueDate': '2026-11-19T08:00:00.000Z',
                  'status': 'BORROWED',
                  'renewCount': 1,
                },
              ),
            );
          },
        ),
      );

      final repository = ApiBorrowingRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      final borrowing = await repository.renewLoan(borrowingId: 'brw-01');

      expect(borrowing.renewCount, 1);
      expect(borrowing.dueDate.day, 19);
    },
  );

  test('renewLoan | Thiếu JWT | throw StateError, không gửi request', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
    final tokenStorage = FakeTokenStorage();

    var requestCount = 0;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestCount++;
          handler.next(options);
        },
      ),
    );

    final repository = ApiBorrowingRepository(
      dio: dio,
      tokenStorage: tokenStorage,
    );

    await expectLater(
      repository.renewLoan(borrowingId: 'brw-01'),
      throwsA(isA<StateError>()),
    );

    expect(requestCount, 0);
  });

  test(
    'renewLoan | extraDays = 0 hoặc 15 | throw ArgumentError, không gửi request',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveToken('test-token');

      var requestCount = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestCount++;
            handler.next(options);
          },
        ),
      );

      final repository = ApiBorrowingRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      for (final invalidDays in [0, 15, -1, 100]) {
        await expectLater(
          repository.renewLoan(borrowingId: 'brw-01', extraDays: invalidDays),
          throwsA(isA<ArgumentError>()),
        );
      }

      expect(requestCount, 0);
    },
  );

  test(
    'getAllBorrowings | Có JWT và status filter | GET /borrowings với query status và page, parse đúng BorrowingsPage',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveToken('test-token');

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'GET');
            expect(options.path, '/borrowings');
            expect(options.headers['Authorization'], 'Bearer test-token');
            expect(options.queryParameters['status'], 'BORROWED');
            expect(options.queryParameters['page'], 1);
            expect(options.queryParameters['limit'], 10);

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': [
                    {
                      'id': 'brw-01',
                      'transactionCode': 'BRW-2026-0001',
                      'memberId': 'mem-01',
                      'memberName': 'Nguyễn Văn An',
                      'bookId': 'book-01',
                      'bookTitle': 'Clean Code',
                      'borrowDate': '2026-10-29T08:00:00.000Z',
                      'dueDate': '2026-11-12T08:00:00.000Z',
                      'status': 'BORROWED',
                    },
                  ],
                  'meta': {
                    'page': 1,
                    'limit': 10,
                    'totalItems': 1,
                    'totalPages': 1,
                    'hasNextPage': false,
                  },
                },
              ),
            );
          },
        ),
      );

      final repository = ApiBorrowingRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      final page = await repository.getAllBorrowings(
        status: 'BORROWED',
        page: 1,
        limit: 10,
      );

      expect(page.borrowings.length, 1);
      expect(page.borrowings.first.id, 'brw-01');
      expect(page.borrowings.first.status, 'BORROWED');
    },
  );

  test(
    'returnBook | Có finePaid true | POST /borrowings/:id/return gửi data finePaid true',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveToken('test-token');

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'POST');
            expect(options.path, '/borrowings/brw-01/return');
            expect(options.headers['Authorization'], 'Bearer test-token');
            expect(options.data, {'finePaid': true});

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
                  'status': 'RETURNED',
                  'finePaid': true,
                },
              ),
            );
          },
        ),
      );

      final repository = ApiBorrowingRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      final borrowing = await repository.returnBook(
        borrowingId: 'brw-01',
        finePaid: true,
      );

      expect(borrowing.status, 'RETURNED');
      expect(borrowing.finePaid, true);
    },
  );

  group('payFine', () {
    test(
      'payFine | Có JWT và borrowingId hợp lệ | POST /borrowings/:id/pay-fine, parse đúng Borrowing',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

        final tokenStorage = FakeTokenStorage();
        await tokenStorage.saveToken('test-token');

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
                    'transactionCode': 'BRW-2026-0001',
                    'memberId': 'mem-01',
                    'memberName': 'Nguyễn Văn An',
                    'bookId': 'book-01',
                    'bookTitle': 'Clean Code',
                    'borrowDate': '2026-10-29T08:00:00.000Z',
                    'dueDate': '2026-11-12T08:00:00.000Z',
                    'status': 'RETURNED',
                    'fineAmount': 50000,
                    'finePaid': true,
                    'finePaidAt': '2026-11-20T10:00:00.000Z',
                  },
                ),
              );
            },
          ),
        );

        final repository = ApiBorrowingRepository(
          dio: dio,
          tokenStorage: tokenStorage,
        );

        final borrowing = await repository.payFine('brw-01');

        expect(borrowing.id, 'brw-01');
        expect(borrowing.finePaid, true);
        expect(borrowing.fineAmount, 50000);
        expect(borrowing.status, 'RETURNED');
      },
    );

    test('payFine | Thiếu JWT | throw StateError, không gửi request', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
      final tokenStorage = FakeTokenStorage();

      var requestSent = false;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestSent = true;
            handler.next(options);
          },
        ),
      );

      final repository = ApiBorrowingRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      await expectLater(
        repository.payFine('brw-01'),
        throwsA(isA<StateError>()),
      );
      expect(requestSent, false);
    });

    test('payFine | borrowingId rỗng | throw ArgumentError', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveToken('test-token');

      final repository = ApiBorrowingRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      expect(() => repository.payFine('  '), throwsArgumentError);
    });
  });
}
