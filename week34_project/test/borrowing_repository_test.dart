import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowings/data/api_borrowing_repository.dart';
import 'package:week34_project/features/borrowings/data/models/create_borrowing_request.dart';
import 'package:week34_project/features/borrowings/data/models/create_borrowing_slip_request.dart';

import 'fake/fake_token_storage.dart';

void main() {
  // Event | Điều kiện đầu vào | Kết quả được kiểm chứng
  test(
    'borrowBook | Có JWT và request hợp lệ | POST /borrowings, parse đúng Borrowing',
    () async {
      // 1. Tạo Dio giả, không gọi API thật
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      // 2. Tạo token giả giống như sau khi Login thành công
      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveToken('test-token');

      // 3. Giả lập server trả về HTTP 201
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // Kiểm tra HTTP method và endpoint
            expect(options.method, 'POST');
            expect(options.path, '/borrowings');

            // Kiểm tra Authorization header
            expect(options.headers['Authorization'], 'Bearer test-token');

            // Kiểm tra request body
            final body = options.data as Map<String, dynamic>;

            expect(body['memberId'], 'mem-01');
            expect(body['bookId'], 'book-01');
            expect(body['durationDays'], 14);

            // Trả về response giả lập, không gửi request thật
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

      // 4. Inject Dio giả và TokenStorage giả
      final repository = ApiBorrowingRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      // 5. Tạo request mượn sách
      const request = CreateBorrowingRequest(
        memberId: 'mem-01',
        bookId: 'book-01',
        durationDays: 14,
      );

      // 6. Gọi Repository
      final result = await repository.borrowBook(request);

      // 7. Kiểm tra kết quả
      expect(result.id, 'brw-01');
      expect(result.transactionCode, 'BRW-2026-0001');
      expect(result.memberId, 'mem-01');
      expect(result.bookId, 'book-01');
      expect(result.status, 'BORROWED');
    },
  );

  test(
    'borrowBook | Thiếu JWT | throw StateError, không gửi request',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      final tokenStorage = FakeTokenStorage();

      // Không lưu token
      var requestCount = 0;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestCount++;
            handler.reject(
              DioException(
                requestOptions: options,
                message: 'Request không được phép gửi',
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
      );

      await expectLater(
        repository.borrowBook(request),
        throwsA(isA<StateError>()),
      );

      expect(requestCount, 0);
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
            expect(options.queryParameters['memberId'], 'mem-01');
            expect(options.queryParameters['page'], 1);
            expect(options.queryParameters['limit'], 10);
            expect(options.headers['Authorization'], 'Bearer test-token');

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

      final result = await repository.getBorrowings(memberId: 'mem-01');

      expect(result.borrowings.length, 1);
      expect(result.borrowings.first.bookTitle, 'Clean Code');
      expect(result.borrowings.first.status, 'BORROWED');
      expect(result.totalItems, 1);
      expect(result.hasNextPage, false);
    },
  );
  test(
    'getBorrowings | Thiếu JWT | throw StateError, không gửi request',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
      final tokenStorage = FakeTokenStorage();

      var requestCount = 0;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestCount++;
            handler.reject(
              DioException(
                requestOptions: options,
                message: 'Không được gửi request',
              ),
            );
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

      expect(requestCount, 0);
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
            expect(options.data, {'finePaid': false});

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
                  'borrowDate': '2026-10-29T08:00:00Z',
                  'dueDate': '2026-11-12T08:00:00Z',
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

      final result = await repository.returnBook(borrowingId: 'brw-01');

      expect(result.id, 'brw-01');
      expect(result.status, 'RETURNED');
    },
  );
  test(
    'returnBook | Thiếu JWT | throw StateError, không gửi request',
    () async {
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
        repository.returnBook(borrowingId: 'brw-01'),
        throwsA(isA<StateError>()),
      );

      expect(requestCount, 0);
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
            expect(options.data, {'extraDays': 7});

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
                  'borrowDate': '2026-11-01T08:00:00Z',
                  'dueDate': '2026-11-22T08:00:00Z',
                  'renewCount': 1,
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

      final result = await repository.renewLoan(
        borrowingId: 'brw-01',
        extraDays: 7,
      );

      expect(result.renewCount, 1);
      expect(result.dueDate, DateTime.utc(2026, 11, 22, 8));
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

      for (final days in [0, 15]) {
        await expectLater(
          repository.renewLoan(borrowingId: 'brw-01', extraDays: days),
          throwsA(isA<ArgumentError>()),
        );
      }

      expect(requestCount, 0);
    },
  );

  test(
    'createBorrowingSlip | Có JWT và 2 sách hợp lệ | POST API, parse BorrowingSlip',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveToken('test-token');

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'POST');
            expect(options.path, '/borrowing-slips');
            expect(options.headers['Authorization'], 'Bearer test-token');

            final body = options.data as Map<String, dynamic>;
            expect(body['memberId'], 'mem-01');
            expect((body['items'] as List).length, 2);
            expect(body['expectedReturnDays'], 14);

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'id': 'slip-01',
                  'slipNumber': 'SLIP-2026-0001',
                  'memberId': 'mem-01',
                  'status': 'PENDING_APPROVAL',
                  'dueDate': '2026-11-24T08:00:00Z',
                  'items': [
                    {
                      'id': 'item-01',
                      'bookId': 'book-01',
                      'bookTitle': 'Clean Code',
                      'quantity': 1,
                      'status': 'PENDING',
                    },
                    {
                      'id': 'item-02',
                      'bookId': 'book-02',
                      'bookTitle': 'Flutter Basics',
                      'quantity': 2,
                      'status': 'PENDING',
                    },
                  ],
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

      const request = CreateBorrowingSlipRequest(
        memberId: 'mem-01',
        items: [
          BorrowingSlipItemRequest(bookId: 'book-01', quantity: 1),
          BorrowingSlipItemRequest(bookId: 'book-02', quantity: 2),
        ],
      );

      final result = await repository.createBorrowingSlip(request);

      expect(result.id, 'slip-01');
      expect(result.status, 'PENDING_APPROVAL');
      expect(result.items.length, 2);
      expect(result.items[0].bookTitle, 'Clean Code');
      expect(result.items[1].quantity, 2);
    },
  );

  test(
    'createBorrowingSlip | Thiếu JWT | throw StateError, không gửi request',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
      final tokenStorage = FakeTokenStorage();

      var requestCount = 0;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestCount++;
            handler.reject(
              DioException(
                requestOptions: options,
                message: 'Không được gửi request',
              ),
            );
          },
        ),
      );

      final repository = ApiBorrowingRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      const request = CreateBorrowingSlipRequest(
        memberId: 'mem-01',
        items: [BorrowingSlipItemRequest(bookId: 'book-01', quantity: 1)],
      );

      await expectLater(
        repository.createBorrowingSlip(request),
        throwsA(isA<StateError>()),
      );

      expect(requestCount, 0);
    },
  );

  test(
    'createBorrowingSlip | Request không hợp lệ | throw ArgumentError, không gửi request',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveToken('test-token');

      var requestCount = 0;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestCount++;
            handler.reject(
              DioException(
                requestOptions: options,
                message: 'Không được gửi request',
              ),
            );
          },
        ),
      );

      final repository = ApiBorrowingRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      const invalidRequests = [
        // Không có memberId
        CreateBorrowingSlipRequest(
          memberId: '   ',
          items: [BorrowingSlipItemRequest(bookId: 'book-01', quantity: 1)],
        ),

        // Danh sách sách rỗng
        CreateBorrowingSlipRequest(memberId: 'mem-01', items: []),

        // Số ngày mượn ngoài khoảng 1-30
        CreateBorrowingSlipRequest(
          memberId: 'mem-01',
          items: [BorrowingSlipItemRequest(bookId: 'book-01', quantity: 1)],
          expectedReturnDays: 0,
        ),

        CreateBorrowingSlipRequest(
          memberId: 'mem-01',
          items: [BorrowingSlipItemRequest(bookId: 'book-01', quantity: 1)],
          expectedReturnDays: 31,
        ),

        // bookId rỗng
        CreateBorrowingSlipRequest(
          memberId: 'mem-01',
          items: [BorrowingSlipItemRequest(bookId: '  ', quantity: 1)],
        ),

        // Quantity ngoài khoảng 1-5
        CreateBorrowingSlipRequest(
          memberId: 'mem-01',
          items: [BorrowingSlipItemRequest(bookId: 'book-01', quantity: 0)],
        ),

        CreateBorrowingSlipRequest(
          memberId: 'mem-01',
          items: [BorrowingSlipItemRequest(bookId: 'book-01', quantity: 6)],
        ),
      ];

      for (final request in invalidRequests) {
        await expectLater(
          repository.createBorrowingSlip(request),
          throwsA(isA<ArgumentError>()),
        );
      }

      expect(requestCount, 0);
    },
  );

  test(
    'getBorrowingSlips | Có JWT và memberId | GET danh sách phiếu, parse phân trang',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveToken('test-token');

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'GET');
            expect(options.path, '/borrowing-slips');
            expect(options.queryParameters['memberId'], 'mem-01');
            expect(options.queryParameters['page'], 1);
            expect(options.queryParameters['limit'], 10);
            expect(options.headers['Authorization'], 'Bearer test-token');

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': [
                    {
                      'id': 'slip-01',
                      'slipNumber': 'SLIP-2026-0001',
                      'memberId': 'mem-01',
                      'status': 'PARTIAL_RETURNED',
                      'dueDate': '2026-11-15T08:00:00Z',
                      'totalFine': 0,
                      'finePaid': true,
                      'items': [
                        {
                          'id': 'item-01',
                          'bookId': 'book-01',
                          'bookTitle': 'Sách A',
                          'quantity': 1,
                          'returnedQuantity': 1,
                          'status': 'RETURNED',
                        },
                      ],
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

      final result = await repository.getBorrowingSlips(memberId: 'mem-01');

      expect(result.slips.length, 1);
      expect(result.slips.first.status, 'PARTIAL_RETURNED');
      expect(result.slips.first.items.first.status, 'RETURNED');
      expect(result.totalItems, 1);
      expect(result.hasNextPage, false);
    },
  );

  test(
    'getBorrowingSlipById | Có JWT và slipId | GET chi tiết phiếu, parse tiền phạt',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveToken('test-token');

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'GET');
            expect(options.path, '/borrowing-slips/slip-01');
            expect(options.headers['Authorization'], 'Bearer test-token');

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'slip-01',
                  'slipNumber': 'SLIP-2026-0001',
                  'memberId': 'mem-01',
                  'status': 'COMPLETED',
                  'dueDate': '2026-11-15T08:00:00Z',
                  'totalFine': 25000,
                  'finePaid': false,
                  'items': [
                    {
                      'id': 'item-C',
                      'bookId': 'book-C',
                      'bookTitle': 'Sách C',
                      'quantity': 1,
                      'returnedQuantity': 1,
                      'status': 'RETURNED',
                      'lateFee': 25000,
                      'fineAmount': 25000,
                    },
                  ],
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

      final slip = await repository.getBorrowingSlipById(slipId: 'slip-01');

      expect(slip.status, 'COMPLETED');
      expect(slip.totalFine, 25000);
      expect(slip.finePaid, false);
      expect(slip.items.first.lateFee, 25000);
    },
  );
}
