import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowing_slips/data/api_borrowing_slips_repository.dart';
import 'package:week34_project/features/borrowing_slips/data/borrow_limit_exceeded_exception.dart';
import 'package:week34_project/features/borrowing_slips/data/models/create_borrowing_slip_request.dart';
import 'fake/fake_token_storage.dart';

void main() {
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

      final repository = ApiBorrowingSlipsRepository(
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

      final repository = ApiBorrowingSlipsRepository(
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

      final repository = ApiBorrowingSlipsRepository(
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

      final repository = ApiBorrowingSlipsRepository(
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

      final repository = ApiBorrowingSlipsRepository(
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

  test(
    'paySlipFine | Có JWT và slipId | POST /pay-fine, parse finePaid = true',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveToken('test-token');

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'POST');
            expect(options.path, '/borrowing-slips/slip-01/pay-fine');
            expect(options.headers['Authorization'], 'Bearer test-token');
            expect(options.data, isNull);

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
                  'finePaid': true,
                  'finePaidAt': '2026-11-20T08:00:00Z',
                  'items': [],
                },
              ),
            );
          },
        ),
      );

      final repository = ApiBorrowingSlipsRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      final slip = await repository.paySlipFine(slipId: 'slip-01');

      expect(slip.totalFine, 25000);
      expect(slip.finePaid, true);
      expect(slip.finePaidAt, isNotNull);
      expect(slip.status, 'COMPLETED');
    },
  );

  test('getPendingBorrowingSlips | Có JWT | GET phiếu chờ duyệt', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

    final tokenStorage = FakeTokenStorage();
    await tokenStorage.saveToken('test-token');

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'GET');
          expect(options.path, '/borrowing-slips');
          expect(options.queryParameters['status'], 'PENDING_APPROVAL');
          expect(options.queryParameters['page'], 1);
          expect(options.queryParameters['limit'], 10);
          expect(options.queryParameters.containsKey('memberId'), false);
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
                    'status': 'PENDING_APPROVAL',
                    'dueDate': '2026-11-25T08:00:00Z',
                    'items': [
                      {
                        'id': 'item-01',
                        'bookId': 'book-01',
                        'bookTitle': 'Clean Code',
                        'quantity': 2,
                        'status': 'PENDING',
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

    final repository = ApiBorrowingSlipsRepository(
      dio: dio,
      tokenStorage: tokenStorage,
    );

    final page = await repository.getPendingBorrowingSlips();

    expect(page.slips.length, 1);
    expect(page.slips.first.status, 'PENDING_APPROVAL');
    expect(page.slips.first.items.first.quantity, 2);
  });

  test(
    'getAllBorrowingSlips | Không có filter status | GET /borrowing-slips không truyền status và memberId',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveToken('test-token');

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'GET');
            expect(options.path, '/borrowing-slips');
            expect(options.queryParameters.containsKey('status'), false);
            expect(options.queryParameters['page'], 1);
            expect(options.queryParameters['limit'], 10);
            expect(options.queryParameters.containsKey('memberId'), false);
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
                      'status': 'BORROWED',
                      'dueDate': '2026-11-25T08:00:00Z',
                      'items': [
                        {
                          'id': 'item-01',
                          'bookId': 'book-01',
                          'bookTitle': 'Clean Code',
                          'quantity': 1,
                          'status': 'BORROWING',
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

      final repository = ApiBorrowingSlipsRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      final page = await repository.getAllBorrowingSlips();

      expect(page.slips.length, 1);
      expect(page.slips.first.status, 'BORROWED');
      expect(page.slips.first.memberId, 'mem-01');
    },
  );

  test(
    'getAllBorrowingSlips | Có filter status BORROWED | GET /borrowing-slips có status=BORROWED',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveToken('test-token');

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'GET');
            expect(options.path, '/borrowing-slips');
            expect(options.queryParameters['status'], 'BORROWED');
            expect(options.queryParameters['page'], 2);
            expect(options.queryParameters['limit'], 5);
            expect(options.queryParameters.containsKey('memberId'), false);
            expect(options.headers['Authorization'], 'Bearer test-token');

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': [],
                  'meta': {
                    'page': 2,
                    'limit': 5,
                    'totalItems': 0,
                    'totalPages': 1,
                    'hasNextPage': false,
                  },
                },
              ),
            );
          },
        ),
      );

      final repository = ApiBorrowingSlipsRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      final page = await repository.getAllBorrowingSlips(
        status: 'BORROWED',
        page: 2,
        limit: 5,
      );

      expect(page.slips.isEmpty, true);
      expect(page.page, 2);
    },
  );

  test(
    'approveBorrowingSlip | Phiếu chờ duyệt | PATCH approve, BORROWED',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveToken('test-token');

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'PATCH');
            expect(options.path, '/borrowing-slips/slip-01/approve');
            expect(options.headers['Authorization'], 'Bearer test-token');
            expect(options.data, isNull);

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'slip-01',
                  'slipNumber': 'SLIP-2026-0001',
                  'memberId': 'mem-01',
                  'status': 'BORROWED',
                  'dueDate': '2026-11-25T08:00:00Z',
                  'items': [
                    {
                      'id': 'item-01',
                      'bookId': 'book-01',
                      'bookTitle': 'Clean Code',
                      'quantity': 2,
                      'status': 'BORROWING',
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

      final repository = ApiBorrowingSlipsRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      final slip = await repository.approveBorrowingSlip(slipId: 'slip-01');

      expect(slip.status, 'BORROWED');
      expect(slip.items.first.status, 'BORROWING');
    },
  );

  test('rejectBorrowingSlip | Có lý do | PATCH reject, REJECTED', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

    final tokenStorage = FakeTokenStorage();
    await tokenStorage.saveToken('test-token');

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'PATCH');
          expect(options.path, '/borrowing-slips/slip-01/reject');
          expect(options.headers['Authorization'], 'Bearer test-token');
          expect(options.data, {'reason': 'Sách đang được kiểm kê'});

          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'id': 'slip-01',
                'slipNumber': 'SLIP-2026-0001',
                'memberId': 'mem-01',
                'status': 'REJECTED',
                'dueDate': '2026-11-25T08:00:00Z',
                'items': [],
              },
            ),
          );
        },
      ),
    );

    final repository = ApiBorrowingSlipsRepository(
      dio: dio,
      tokenStorage: tokenStorage,
    );

    final slip = await repository.rejectBorrowingSlip(
      slipId: 'slip-01',
      reason: '  Sách đang được kiểm kê  ',
    );

    expect(slip.status, 'REJECTED');
  });

  test(
    'approveBorrowingSlip | Lỗi BORROW_LIMIT_EXCEEDED từ Backend | throw BorrowLimitExceededException',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveToken('test-token');

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 409,
                  data: {
                    'code': 'BORROW_LIMIT_EXCEEDED',
                    'message': 'Độc giả đã vượt quá hạn mức mượn sách',
                    'details': {
                      'maxBorrowLimit': 5,
                      'currentBorrowedCount': 5,
                    },
                  },
                ),
              ),
            );
          },
        ),
      );

      final repository = ApiBorrowingSlipsRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      expect(
        () => repository.approveBorrowingSlip(slipId: 'slip-01'),
        throwsA(
          isA<BorrowLimitExceededException>()
              .having(
                (e) => e.message,
                'message',
                'Độc giả đã vượt quá hạn mức mượn sách',
              )
              .having((e) => e.code, 'code', 'BORROW_LIMIT_EXCEEDED')
              .having(
                (e) => e.details?['maxBorrowLimit'],
                'details.maxBorrowLimit',
                5,
              ),
        ),
      );
    },
  );

  test(
    'renewSlip | Có JWT và extraDays = 7 | PATCH /borrowing-slips/:id/renew, parse dueDate và renewCount',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
      final tokenStorage = FakeTokenStorage();
      await tokenStorage.saveToken('test-token');

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'PATCH');
            expect(options.path, '/borrowing-slips/slip-01/renew');
            expect(options.headers['Authorization'], 'Bearer test-token');
            expect(options.data, {'extraDays': 7});

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'slip-01',
                  'slipNumber': 'SLIP-2026-0001',
                  'memberId': 'mem-01',
                  'status': 'BORROWED',
                  'dueDate': '2026-12-02T08:00:00Z',
                  'renewCount': 1,
                  'items': [],
                  'renewalEligibility': {
                    'canRenew': false,
                    'reasonCode': 'MAX_RENEWALS_REACHED',
                    'message': 'Đã đạt giới hạn gia hạn tối đa',
                  },
                },
              ),
            );
          },
        ),
      );

      final repository = ApiBorrowingSlipsRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      final slip = await repository.renewSlip(slipId: 'slip-01', extraDays: 7);

      expect(slip.id, 'slip-01');
      expect(slip.renewCount, 1);
      expect(slip.dueDate, DateTime.parse('2026-12-02T08:00:00Z'));
      expect(slip.canRenew, isFalse);
      expect(slip.renewalReasonCode, 'MAX_RENEWALS_REACHED');
      expect(slip.renewalMessage, 'Đã đạt giới hạn gia hạn tối đa');
    },
  );

  test('renewSlip | Thiếu JWT | throw StateError', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
    final tokenStorage = FakeTokenStorage();

    final repository = ApiBorrowingSlipsRepository(
      dio: dio,
      tokenStorage: tokenStorage,
    );

    await expectLater(
      repository.renewSlip(slipId: 'slip-01'),
      throwsA(isA<StateError>()),
    );
  });

  test('renewSlip | slipId rỗng | throw ArgumentError', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
    final tokenStorage = FakeTokenStorage();
    await tokenStorage.saveToken('test-token');

    final repository = ApiBorrowingSlipsRepository(
      dio: dio,
      tokenStorage: tokenStorage,
    );

    expect(() => repository.renewSlip(slipId: '  '), throwsArgumentError);
  });

  test('renewSlip | extraDays không hợp lệ (< 1 hoặc > 14) | throw ArgumentError', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
    final tokenStorage = FakeTokenStorage();
    await tokenStorage.saveToken('test-token');

    final repository = ApiBorrowingSlipsRepository(
      dio: dio,
      tokenStorage: tokenStorage,
    );

    expect(() => repository.renewSlip(slipId: 'slip-01', extraDays: 0), throwsArgumentError);
    expect(() => repository.renewSlip(slipId: 'slip-01', extraDays: 15), throwsArgumentError);
  });

  test('getBorrowingSlipById | Parse được eligibility từ backend', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
    final tokenStorage = FakeTokenStorage();
    await tokenStorage.saveToken('test-token');

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'GET');
          expect(options.path, '/borrowing-slips/slip-01');

          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'id': 'slip-01',
                'slipNumber': 'SLIP-2026-0001',
                'memberId': 'mem-01',
                'status': 'BORROWED',
                'dueDate': '2026-11-25T08:00:00Z',
                'items': [],
                'canRenew': true,
                'reasonCode': null,
                'message': null,
              },
            ),
          );
        },
      ),
    );

    final repository = ApiBorrowingSlipsRepository(
      dio: dio,
      tokenStorage: tokenStorage,
    );

    final slip = await repository.getBorrowingSlipById(slipId: 'slip-01');

    expect(slip.canRenew, isTrue);
    expect(slip.renewalReasonCode, isNull);
  });
}
