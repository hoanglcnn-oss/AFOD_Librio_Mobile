import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/auth/data/models/user_profile.dart';
import 'package:week34_project/features/books/data/books_repository.dart';
import 'package:week34_project/features/books/data/models/book.dart';
import 'package:week34_project/features/books/data/models/paginated_books.dart';
import 'package:week34_project/features/books/presentation/pages/books_detail_screen.dart';

import 'fake/fake_auth_repository.dart';
import 'fake/fake_reservations_repository.dart';
import 'fake/fake_token_storage.dart';

class SingleBookFakeRepository implements BooksRepository {
  final Book book;

  SingleBookFakeRepository(this.book);

  @override
  Future<PaginatedBooks> getBooks({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
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
  final testMember = UserProfile(
    id: 'user-01',
    email: 'member@test.com',
    phone: '0901234567',
    fullName: 'Nguyen Van Member',
    role: 'MEMBER',
    isActive: true,
    memberId: 'mem-01',
    createdAt: DateTime(2026, 1, 1),
  );

  const sampleBookAvailable = Book(
    id: 'book-ai-01',
    isbn: '978-604-0-12345-6',
    title: 'Nhập môn Trí tuệ Nhân tạo và Học máy',
    authorName: 'GS. TS. Nguyễn Văn An',
    categoryName: 'Khoa học Máy tính & AI',
    description:
        'Giáo trình chuẩn hóa toàn bộ khối kiến thức cốt lõi và hiện đại về Trí tuệ Nhân tạo cùng Học máy ứng dụng, kết hợp chặt chẽ giữa cơ sở toán học giải thuật và hướng dẫn lập trình thực nghiệm. Nội dung được biên soạn chuẩn theo đề cương môn học chuyên ngành.',
    coverUrl: null,
    status: 'AVAILABLE',
    copiesAvailable: 4,
    copiesTotal: 6,
  );

  const sampleBookOutOfStock = Book(
    id: 'book-ai-02',
    isbn: '978-604-0-65432-1',
    title: 'Học máy Nâng cao',
    authorName: 'TS. Tran B',
    categoryName: 'AI & Data Science',
    description: 'Tài liệu chuyên sâu.',
    coverUrl: null,
    status: 'BORROWED',
    copiesAvailable: 0,
    copiesTotal: 3,
  );

  const sampleBookEmptyDesc = Book(
    id: 'book-ai-03',
    isbn: '978-604-0-00000-0',
    title: 'Sách Không Có Mô Tả',
    authorName: 'Tác giả X',
    categoryName: 'Tổng hợp',
    description: '',
    coverUrl: null,
    status: 'AVAILABLE',
    copiesAvailable: 2,
    copiesTotal: 2,
  );

  final sampleBookLongContent = Book(
    id: 'book-ai-04',
    isbn: '978-604-0-99999-9',
    title:
        'Giáo Trình Cực Kỳ Dài Dài Dài Dài Dài Dài Dài Dài Dài Dài Dài Về Cấu Trúc Dữ Liệu Và Giải Thuật Ứng Dụng Trong Hệ Thống Phân Tán',
    authorName:
        'Đồng Tác Giả: GS. TS. Nguyễn Văn A, PGS. TS. Trần Thị B, ThS. Lê Văn C',
    categoryName:
        'Công Nghệ Phần Mềm & An Toàn Thông Tin Mạng Quốc Gia & Trí Tuệ Nhân Tạo',
    description:
        'Đoạn mô tả siêu dài kiểm tra tính co giãn linh hoạt của giao diện khi văn bản chiếm rất nhiều dòng, đảm bảo không xảy ra hiện tượng RenderFlex overflow ở bất kỳ viewport nào từ 360x800 đến 390x844 dp và kể cả khi text scale 150%. ' *
        5,
    coverUrl: null,
    status: 'AVAILABLE',
    copiesAvailable: 5,
    copiesTotal: 10,
  );

  group('BookDetailScreen Stitch Final Design & Responsive Tests', () {
    late FakeAuthRepository authRepository;
    late AuthBloc authBloc;
    late FakeReservationsRepository reservationsRepository;

    setUp(() {
      authRepository = FakeAuthRepository();
      authBloc = AuthBloc(
        authRepository: authRepository,
        tokenStorage: FakeTokenStorage()..savedToken = 'valid-jwt',
      )..emit(AuthAuthenticated(user: testMember));
      reservationsRepository = FakeReservationsRepository();
    });

    tearDown(() {
      authBloc.close();
    });

    testWidgets(
      'Kiểm tra Compact Side-by-side Hero & Availability Badge khi còn sách',
      (tester) async {
        final repo = SingleBookFakeRepository(sampleBookAvailable);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: authBloc,
              child: BookDetailScreen(
                bookId: sampleBookAvailable.id,
                repository: repo,
                reservationsRepository: reservationsRepository,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Chi tiết sách'), findsOneWidget);
        expect(
          find.text('Nhập môn Trí tuệ Nhân tạo và Học máy'),
          findsOneWidget,
        );
        expect(find.text('Tác giả: GS. TS. Nguyễn Văn An'), findsOneWidget);
        expect(find.text('Khoa học Máy tính & AI'), findsOneWidget);
        expect(find.text('ISBN: 978-604-0-12345-6'), findsOneWidget);
        expect(find.text('Còn 4 / 6 cuốn'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      },
    );

    testWidgets('Kiểm tra Availability Badge khi hết sách khả dụng', (
      tester,
    ) async {
      final repo = SingleBookFakeRepository(sampleBookOutOfStock);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: BookDetailScreen(
              bookId: sampleBookOutOfStock.id,
              repository: repo,
              reservationsRepository: reservationsRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Hiện không thể mượn (đã hết bản khả dụng)'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Nút mượn bị disabled, nút đặt trước vẫn enabled
      final borrowBtn = tester.widget<FilledButton>(
        find.byKey(const ValueKey('borrow_book_button')),
      );
      expect(borrowBtn.onPressed, isNull);

      final reserveBtn = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('reserve_book_button')),
      );
      expect(reserveBtn.onPressed, isNotNull);
    });

    testWidgets('Kiểm tra Expand & Collapse Mô tả', (tester) async {
      final repo = SingleBookFakeRepository(sampleBookAvailable);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: BookDetailScreen(
              bookId: sampleBookAvailable.id,
              repository: repo,
              reservationsRepository: reservationsRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mô tả'), findsOneWidget);
      expect(find.text('Xem thêm'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);

      // Bấm Xem thêm -> chuyển sang Thu gọn
      await tester.tap(find.byKey(const ValueKey('toggle_description_button')));
      await tester.pumpAndSettle();

      expect(find.text('Thu gọn'), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);

      // Bấm Thu gọn -> trở lại Xem thêm
      await tester.tap(find.byKey(const ValueKey('toggle_description_button')));
      await tester.pumpAndSettle();

      expect(find.text('Xem thêm'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets(
      'Kiểm tra khi sách không có mô tả -> Hiển thị Chưa có mô tả và không có nút Xem thêm',
      (tester) async {
        final repo = SingleBookFakeRepository(sampleBookEmptyDesc);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: authBloc,
              child: BookDetailScreen(
                bookId: sampleBookEmptyDesc.id,
                repository: repo,
                reservationsRepository: reservationsRepository,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Chưa có mô tả'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('toggle_description_button')),
          findsNothing,
        );
      },
    );

    testWidgets('Kiểm tra khi mô tả ngắn (<= 3 dòng) -> Hiển thị mô tả và KHÔNG có nút Xem thêm', (tester) async {
      final repo = SingleBookFakeRepository(sampleBookOutOfStock);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: BookDetailScreen(
              bookId: sampleBookOutOfStock.id,
              repository: repo,
              reservationsRepository: reservationsRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tài liệu chuyên sâu.'), findsOneWidget);
      expect(find.byKey(const ValueKey('toggle_description_button')), findsNothing);
      expect(find.text('Xem thêm'), findsNothing);
    });

    testWidgets(
      'Kiểm tra khi mô tả ngắn (<= 3 dòng) -> Hiển thị mô tả và KHÔNG có nút Xem thêm',
      (tester) async {
        final repo = SingleBookFakeRepository(sampleBookOutOfStock);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: authBloc,
              child: BookDetailScreen(
                bookId: sampleBookOutOfStock.id,
                repository: repo,
                reservationsRepository: reservationsRepository,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tài liệu chuyên sâu.'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('toggle_description_button')),
          findsNothing,
        );
        expect(find.text('Xem thêm'), findsNothing);
      },
    );

    testWidgets(
      'Kiểm tra Responsive Viewport 360x800 & 390x844 với nội dung dài',
      (tester) async {
        final repo = SingleBookFakeRepository(sampleBookLongContent);

        // Test 360x800
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: authBloc,
              child: BookDetailScreen(
                bookId: sampleBookLongContent.id,
                repository: repo,
                reservationsRepository: reservationsRepository,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Test 390x844
        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Kiểm tra Text Scaling 150% (TextScaler.linear(1.5))', (
      tester,
    ) async {
      final repo = SingleBookFakeRepository(sampleBookAvailable);

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(1.5),
          ),
          child: MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: authBloc,
              child: BookDetailScreen(
                bookId: sampleBookAvailable.id,
                repository: repo,
                reservationsRepository: reservationsRepository,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('reserve_book_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('borrow_book_button')), findsOneWidget);
    });
  });
}
