import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/core/constants/api_constants.dart';
import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/auth/data/models/user_profile.dart';
import 'package:week34_project/features/books/data/books_repository.dart';
import 'package:week34_project/features/books/data/models/book.dart';
import 'package:week34_project/features/books/data/models/paginated_books.dart';
import 'package:week34_project/features/books/presentation/pages/books_detail_screen.dart';
import 'package:week34_project/features/reservations/data/models/reservation.dart';

import 'fake/fake_auth_repository.dart';
import 'fake/fake_reservations_repository.dart';
import 'fake/fake_token_storage.dart';

class CustomFakeBooksRepository implements BooksRepository {
  final Book book;

  CustomFakeBooksRepository(this.book);

  @override
  Future<PaginatedBooks> getBooks({int page = 1, int limit = 10, String? search}) async {
    return PaginatedBooks(
      page: 1,
      totalPages: 1,
      hasNextPage: false,
      books: [book],
    );
  }

  @override
  Future<Book> getBookById(String id) async => book;

  @override
  Future<Book> getBookByIsbn(String isbn) async => book;
}

void main() {
  final memberUser = UserProfile(
    id: 'user-01',
    email: 'member@test.com',
    phone: '0901234567',
    fullName: 'Nguyen Van Member',
    role: 'MEMBER',
    isActive: true,
    memberId: 'mem-01',
    createdAt: DateTime(2026, 1, 1),
  );

  const availableBook = Book(
    id: 'b-1',
    isbn: '1234567890',
    title: 'Flutter in Action',
    authorName: 'Eric Windmill',
    categoryName: 'Programming',
    description: 'Learn Flutter from scratch',
    coverUrl: null,
    status: 'AVAILABLE',
    copiesAvailable: 2,
    copiesTotal: 5,
  );

  const outOfStockBook = Book(
    id: 'b-2',
    isbn: '0987654321',
    title: 'Out of Stock Book',
    authorName: 'Unknown',
    categoryName: 'Tech',
    description: 'All copies are checked out',
    coverUrl: null,
    status: 'BORROWED',
    copiesAvailable: 0,
    copiesTotal: 3,
  );

  group('BookDetailScreen Reservation', () {
    late FakeAuthRepository authRepository;
    late AuthBloc authBloc;
    late FakeReservationsRepository reservationsRepository;

    setUp(() {
      authRepository = FakeAuthRepository();
      authBloc = AuthBloc(
        authRepository: authRepository,
        tokenStorage: FakeTokenStorage()..savedToken = 'valid-jwt',
      )..emit(AuthAuthenticated(user: memberUser));
      reservationsRepository = FakeReservationsRepository();
    });

    tearDown(() {
      authBloc.close();
    });

    testWidgets('Hiển thị cả 2 nút Đặt trước và Mượn sách', (tester) async {
      final booksRepo = CustomFakeBooksRepository(availableBook);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: BookDetailScreen(
              bookId: 'b-1',
              repository: booksRepo,
              reservationsRepository: reservationsRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('reserve_book_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('borrow_book_button')), findsOneWidget);
      expect(find.text('Mượn sách'), findsOneWidget);
      expect(find.text('Đặt trước'), findsOneWidget);
    });

    testWidgets('Khi sách hết bản khả dụng | Nút Mượn sách bị disabled, nút Đặt trước vẫn enabled', (tester) async {
      final booksRepo = CustomFakeBooksRepository(outOfStockBook);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: BookDetailScreen(
              bookId: 'b-2',
              repository: booksRepo,
              reservationsRepository: reservationsRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final borrowButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('borrow_book_button')),
      );
      expect(borrowButton.onPressed, isNull);

      final reserveButton = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('reserve_book_button')),
      );
      expect(reserveButton.onPressed, isNotNull);
    });

    testWidgets('Bấm Đặt trước mở Dialog xác nhận và gửi request thành công với PENDING', (tester) async {
      final booksRepo = CustomFakeBooksRepository(outOfStockBook);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: BookDetailScreen(
              bookId: 'b-2',
              repository: booksRepo,
              reservationsRepository: reservationsRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Bấm nút Đặt trước
      await tester.tap(find.byKey(const ValueKey('reserve_book_button')));
      await tester.pumpAndSettle();

      // Kiểm tra dialog
      expect(find.text('Đặt trước sách'), findsOneWidget);
      expect(find.textContaining('Bạn có muốn đặt trước cuốn sách "Out of Stock Book"?'), findsOneWidget);

      // Bấm Hủy
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(reservationsRepository.createCallCount, 0);

      // Mở lại và nhập ghi chú
      await tester.tap(find.byKey(const ValueKey('reserve_book_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Ghi chú cho bạn đọc');
      await tester.pumpAndSettle();

      // Xác nhận đặt trước
      await tester.tap(find.text('Xác nhận đặt trước'));
      await tester.pumpAndSettle();

      expect(reservationsRepository.createCallCount, 1);
      expect(find.textContaining('Đặt trước thành công (Đang chờ sách)'), findsOneWidget);
    });

    testWidgets('Khi Backend trả về trạng thái READY | Hiển thị thông báo Sách đã sẵn sàng nhận', (tester) async {
      final booksRepo = CustomFakeBooksRepository(availableBook);

      final readyRepository = FakeReservationsRepository();
      readyRepository.reservations = [
        Reservation(
          id: 'res-ready',
          reservationCode: 'RSV-RDY',
          memberId: 'mem-01',
          bookId: 'b-1',
          bookTitle: 'Flutter in Action',
          status: 'READY',
          reservedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: BookDetailScreen(
              bookId: 'b-1',
              repository: booksRepo,
              reservationsRepository: readyRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('reserve_book_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận đặt trước'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Đặt trước thành công'), findsOneWidget);
    });

    testWidgets('Xử lý xung đột 409 | Hiển thị thông báo lỗi từ backend', (tester) async {
      final booksRepo = CustomFakeBooksRepository(outOfStockBook);

      reservationsRepository.createError = DioException(
        requestOptions: RequestOptions(path: ApiConstants.reservations),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.reservations),
          statusCode: 409,
          data: {'message': 'Bạn đã có lượt đặt trước đang chờ cho sách này.'},
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: BookDetailScreen(
              bookId: 'b-2',
              repository: booksRepo,
              reservationsRepository: reservationsRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('reserve_book_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận đặt trước'));
      await tester.pumpAndSettle();

      expect(find.text('Bạn đã có lượt đặt trước đang chờ cho sách này.'), findsOneWidget);
    });

    testWidgets('POST timeout không xác minh được | Hiển thị kết quả chưa xác định và hướng dẫn kiểm tra danh sách', (tester) async {
      final booksRepo = CustomFakeBooksRepository(outOfStockBook);

      reservationsRepository.createError = DioException(
        requestOptions: RequestOptions(path: ApiConstants.reservations),
        type: DioExceptionType.connectionTimeout,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: BookDetailScreen(
              bookId: 'b-2',
              repository: booksRepo,
              reservationsRepository: reservationsRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('reserve_book_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận đặt trước'));
      await tester.pumpAndSettle();

      expect(reservationsRepository.createCallCount, 1); // Không tự retry POST
      expect(find.textContaining('chưa được xác định'), findsOneWidget);
      expect(find.textContaining('danh sách đặt trước'), findsOneWidget);
    });

    testWidgets('Chặn double submit khi đang trong quá trình đặt trước', (tester) async {
      final booksRepo = CustomFakeBooksRepository(availableBook);

      reservationsRepository.createCompleter = Completer<void>();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: BookDetailScreen(
              bookId: 'b-1',
              repository: booksRepo,
              reservationsRepository: reservationsRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('reserve_book_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận đặt trước'));
      await tester.pump();

      expect(reservationsRepository.createCallCount, 1);
      expect(find.text('Đang xử lý...'), findsOneWidget);

      reservationsRepository.createCompleter!.complete();
      await tester.pumpAndSettle();

      expect(reservationsRepository.createCallCount, 1);
      expect(find.textContaining('Đặt trước thành công'), findsOneWidget);
    });
  });
}
