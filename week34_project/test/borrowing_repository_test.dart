import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowings/data/api_borrowing_repository.dart';
import 'package:week34_project/features/borrowings/data/models/create_borrowing_request.dart';

import 'fake/fake_token_storage.dart';

void main() {
  test('borrowBook gửi POST kèm JWT và parse response', () async {
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
  });

  test('borrowBook không gửi POST nếu thiếu JWT', () async {
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
  });
  test('getBorrowings gửi GET kèm JWT và parse danh sách', () async {
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
  });
  test('getBorrowings không gửi GET nếu thiếu JWT', () async {
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
  });
  test('returnBook gửi JWT và parse RETURNED', () async {
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
  });
  test('returnBook thiếu JWT không gửi request', () async {
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
  });
}
