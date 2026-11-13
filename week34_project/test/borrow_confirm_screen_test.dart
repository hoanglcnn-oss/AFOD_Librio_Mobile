import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/core/constants/api_constants.dart';
import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/auth/data/models/user_profile.dart';
import 'package:week34_project/features/books/data/models/book.dart';
import 'package:week34_project/features/borrowing/shared/models/borrowing_slip.dart';
import 'package:week34_project/features/borrowing/create_slip/presentation/pages/borrow_confirm_screen.dart';
import 'package:week34_project/features/borrowing/create_slip/presentation/pages/borrow_result_screen.dart';
import 'package:week34_project/features/home/presentation/widgets/my_borrowings_tab.dart';
import 'package:week34_project/features/members/data/models/member.dart';

import 'fake/fake_auth_repository.dart';
import 'fake/fake_borrowing_repository.dart';
import 'fake/fake_members_repository.dart';
import 'fake/fake_token_storage.dart';

void main() {
  const sampleBook = Book(
    id: 'book-01',
    title: 'Clean Code',
    isbn: '9780132350884',
    authorName: 'Robert C. Martin',
    categoryName: 'Công nghệ',
    description: 'A handbook of agile software craftsmanship',
    coverUrl: null,
    copiesTotal: 5,
    copiesAvailable: 3,
    status: 'AVAILABLE',
  );

  final authUser = UserProfile(
    id: 'account-user-999', // ID tài khoản khác với memberId
    email: 'member@test.com',
    phone: '0901234567',
    fullName: 'Độc giả A',
    role: 'MEMBER',
    isActive: true,
    memberId: 'mem-actual-123', // ID độc giả thực tế
    createdAt: DateTime(2026, 1, 1),
  );

  final sampleMember = Member(
    id: 'mem-actual-123',
    fullName: 'Độc giả A',
    email: 'member@test.com',
    cardNumber: 'LIB-001',
    status: 'ACTIVE',
    membershipExpiry: DateTime(2027, 1, 1),
  );

  group('BorrowConfirmScreen & BorrowResultScreen - R1.1', () {
    late FakeBorrowingRepository borrowingSlipsRepository;
    late FakeMembersRepository membersRepository;
    late AuthBloc authBloc;

    setUp(() {
      borrowingSlipsRepository = FakeBorrowingRepository();
      membersRepository = FakeMembersRepository(members: [sampleMember]);
      authBloc = AuthBloc(
        authRepository: FakeAuthRepository(),
        tokenStorage: FakeTokenStorage()..savedToken = 'valid-jwt',
      )..emit(AuthAuthenticated(user: authUser));
    });

    tearDown(() {
      authBloc.close();
    });

    Widget createTestApp({Book book = sampleBook}) {
      return MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: BorrowConfirmScreen(
            book: book,
            borrowingSlipsRepository: borrowingSlipsRepository,
            membersRepository: membersRepository,
          ),
        ),
      );
    }

    testWidgets(
        'Mượn một sách | Tạo CreateBorrowingSlipRequest với items 1 cuốn, expectedReturnDays 14 và memberId từ MemberResolver',
        (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận mượn sách'), findsOneWidget);
      expect(find.text('Clean Code'), findsOneWidget);
      expect(find.text('Tác giả: Robert C. Martin'), findsOneWidget);
      expect(find.text('Số lượng còn: 3 cuốn'), findsOneWidget);
      expect(find.text('14 ngày'), findsOneWidget);
      expect(find.text('Gửi phiếu mượn'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('confirm_borrow_button')));
      await tester.pumpAndSettle();

      // Kiểm tra request gửi sang Backend
      expect(borrowingSlipsRepository.createSlipCallCount, 1);
      final req = borrowingSlipsRepository.createSlipRequests.single;
      expect(req.memberId, 'mem-actual-123'); // Không dùng 'account-user-999'
      expect(req.expectedReturnDays, 14);
      expect(req.items.length, 1);
      expect(req.items.first.bookId, 'book-01');
      expect(req.items.first.quantity, 1);

      // Chuyển sang màn kết quả
      expect(find.byType(BorrowResultScreen), findsOneWidget);
      expect(
        find.text('Đã gửi yêu cầu mượn, chờ thủ thư duyệt'),
        findsOneWidget,
      );
      expect(find.text('Mượn sách thành công!'), findsNothing);
      expect(find.text('PENDING_APPROVAL (Chờ duyệt)'), findsOneWidget);
      expect(find.text('SLIP-2026-0001'), findsOneWidget);
    });

    testWidgets('Chặn double-submit khi đang gửi phiếu mượn', (tester) async {
      final completer = Completer<void>();
      borrowingSlipsRepository.createSlipCompleter = completer;

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final buttonFinder = find.byKey(const ValueKey('confirm_borrow_button'));
      expect(buttonFinder, findsOneWidget);

      // Nhấn lần 1
      await tester.tap(buttonFinder);
      await tester.pump(); // Start request

      expect(borrowingSlipsRepository.createSlipCallCount, 1);

      // Thử nhấn tiếp lần 2 khi request đang in-flight
      await tester.tap(buttonFinder, warnIfMissed: false);
      await tester.pump();

      // Vẫn chỉ gọi 1 lần
      expect(borrowingSlipsRepository.createSlipCallCount, 1);

      // Hoàn tất request
      completer.complete();
      await tester.pumpAndSettle();

      expect(find.byType(BorrowResultScreen), findsOneWidget);
    });

    testWidgets('Timeout/ConnectionError | Báo kết quả chưa xác định, không tự POST lần 2',
        (tester) async {
      borrowingSlipsRepository.createSlipErrorOnce = DioException(
        requestOptions: RequestOptions(path: ApiConstants.borrowingSlips),
        type: DioExceptionType.connectionTimeout,
      );

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('confirm_borrow_button')));
      await tester.pumpAndSettle();

      // Chỉ gọi POST 1 lần, không retry
      expect(borrowingSlipsRepository.createSlipCallCount, 1);

      // Hiển thị thông báo chưa xác định kết quả
      expect(
        find.textContaining('Không thể xác nhận kết quả tạo phiếu mượn'),
        findsOneWidget,
      );
      // Không mở màn BorrowResultScreen
      expect(find.byType(BorrowResultScreen), findsNothing);
    });

    testWidgets('BorrowResultScreen | Hiển thị đúng thông tin PENDING_APPROVAL và danh sách sách',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final slip = BorrowingSlip(
        id: 'slip-xyz',
        slipNumber: 'SLIP-999',
        memberId: 'mem-actual-123',
        memberName: 'Độc giả A',
        status: 'PENDING_APPROVAL',
        dueDate: DateTime.now().add(const Duration(days: 14)),
        items: const [
          BorrowingSlipItem(
            id: 'item-1',
            bookId: 'book-01',
            bookTitle: 'Clean Code',
            quantity: 1,
            status: 'PENDING',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BorrowResultScreen(slip: slip),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đã gửi yêu cầu mượn, chờ thủ thư duyệt'), findsOneWidget);
      expect(find.text('SLIP-999'), findsOneWidget);
      expect(find.text('PENDING_APPROVAL (Chờ duyệt)'), findsOneWidget);
      expect(find.text('Clean Code'), findsOneWidget);
      expect(find.text('Số lượng: 1 cuốn'), findsOneWidget);
      expect(find.text('Quay về danh sách sách'), findsOneWidget);

      // Không hiển thị ngày mượn hoặc hạn trả như đã nhận sách
      expect(find.text('Ngày mượn'), findsNothing);
      expect(find.text('Hạn trả'), findsNothing);
    });
  });

  group('MyBorrowingsTab - R1.1', () {
    late FakeBorrowingRepository borrowingSlipsRepository;
    late FakeMembersRepository membersRepository;
    late AuthBloc authBloc;

    setUp(() {
      borrowingSlipsRepository = FakeBorrowingRepository();
      membersRepository = FakeMembersRepository(members: [sampleMember]);
      authBloc = AuthBloc(
        authRepository: FakeAuthRepository(),
        tokenStorage: FakeTokenStorage()..savedToken = 'valid-jwt',
      )..emit(AuthAuthenticated(user: authUser));
    });

    tearDown(() {
      authBloc.close();
    });

    testWidgets(
        'Không còn tab Mượn lẻ và Phiếu nhiều sách, hiển thị BorrowingSlipsScreen và nút Đặt trước của tôi',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<AuthBloc>.value(
              value: authBloc,
              child: MyBorrowingsTab(
                onReturnSucceeded: () {},
                borrowingSlipsRepository: borrowingSlipsRepository,
                membersRepository: membersRepository,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra: Đã bỏ tab "Mượn lẻ" và "Phiếu nhiều sách"
      expect(find.text('Mượn lẻ'), findsNothing);
      expect(find.text('Phiếu nhiều sách'), findsNothing);

      // Nút "Đặt trước của tôi" vẫn còn
      expect(find.byKey(const ValueKey('my_reservations_entry_button')), findsOneWidget);
      expect(find.text('Đặt trước của tôi'), findsOneWidget);
    });
  });
}
