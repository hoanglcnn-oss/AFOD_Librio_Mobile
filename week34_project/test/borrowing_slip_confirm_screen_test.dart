import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/auth/data/models/user_profile.dart';
import 'package:week34_project/features/books/data/models/book.dart';
import 'package:week34_project/features/borrowing/create_slip/presentation/pages/borrowing_slip_confirm_screen.dart';
import 'package:week34_project/features/members/data/models/member_debt_summary.dart';

import 'fake/fake_auth_repository.dart';
import 'fake/fake_borrowing_repository.dart';
import 'fake/fake_members_repository.dart';
import 'fake/fake_token_storage.dart';

void main() {
  late AuthBloc authBloc;
  late FakeMembersRepository membersRepository;
  late FakeBorrowingRepository borrowingSlipsRepository;

  final sampleBooks = <Book>[
    const Book(
      id: 'book-01',
      title: 'Clean Code',
      isbn: '9780132350884',
      authorName: 'Robert C. Martin',
      categoryName: 'Công nghệ',
      description: 'Clean code handbook',
      coverUrl: null,
      copiesTotal: 5,
      copiesAvailable: 3,
      status: 'AVAILABLE',
    ),
    const Book(
      id: 'book-02',
      title: 'The Pragmatic Programmer',
      isbn: '9780201616224',
      authorName: 'Andy Hunt',
      categoryName: 'Công nghệ',
      description: 'Pragmatic handbook',
      coverUrl: null,
      copiesTotal: 4,
      copiesAvailable: 2,
      status: 'AVAILABLE',
    ),
  ];

  final authUser = UserProfile(
    id: 'user-01',
    email: 'member@example.com',
    fullName: 'Độc giả A',
    phone: '0901234567',
    role: 'MEMBER',
    isActive: true,
    memberId: 'mem-01',
    createdAt: DateTime(2026, 1, 1),
  );

  Widget createApp({List<Book>? books}) {
    authBloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      tokenStorage: FakeTokenStorage(),
    )..emit(AuthAuthenticated(user: authUser));

    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: BorrowingSlipConfirmScreen(
          books: books ?? sampleBooks,
          membersRepository: membersRepository,
          borrowingSlipsRepository: borrowingSlipsRepository,
        ),
      ),
    );
  }

  void setLargeScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  setUp(() {
    membersRepository = FakeMembersRepository();
    borrowingSlipsRepository = FakeBorrowingRepository();
  });

  tearDown(() async {
    await authBloc.close();
  });

  group('BorrowingSlipConfirmScreen - F1 Hạn mức mượn sách', () {
    testWidgets(
      'Đủ hạn mức | Hiển thị thông tin rút gọn và nút Gửi phiếu enabled',
      (tester) async {
        setLargeScreen(tester);

        membersRepository.fakeDebtSummary = const MemberDebtSummary(
          maxBorrowLimit: 5,
          currentBorrowedCount: 2,
          remainingBorrowLimit: 3,
          canBorrow: true,
          overdueCount: 0,
          unpaidFineAmount: 0,
        );

        await tester.pumpWidget(createApp());
        await tester.pumpAndSettle();

        expect(find.text('Hạn mức mượn sách'), findsOneWidget);
        expect(find.text('• Đang mượn: 2/5 cuốn'), findsOneWidget);
        expect(find.text('• Còn được mượn: 3 cuốn'), findsOneWidget);
        expect(find.text('• Đang chọn: 2 cuốn'), findsOneWidget);
        expect(find.text('Đủ điều kiện gửi phiếu mượn'), findsOneWidget);

        final submitButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Gửi phiếu mượn'),
        );
        expect(submitButton.onPressed, isNotNull);

        // Gửi phiếu
        await tester.tap(find.widgetWithText(FilledButton, 'Gửi phiếu mượn'));
        await tester.pumpAndSettle();

        expect(borrowingSlipsRepository.createSlipCallCount, 1);
        expect(find.text('Đã gửi phiếu mượn!'), findsOneWidget);
      },
    );

    testWidgets('Vượt hạn mức | Disable nút gửi và hiển thị lý do cụ thể', (
      tester,
    ) async {
      setLargeScreen(tester);

      // Chỉ còn được mượn 1 cuốn, nhưng chọn 2 cuốn (mỗi cuốn số lượng 1)
      membersRepository.fakeDebtSummary = const MemberDebtSummary(
        maxBorrowLimit: 5,
        currentBorrowedCount: 4,
        remainingBorrowLimit: 1,
        canBorrow: true,
        overdueCount: 0,
        unpaidFineAmount: 0,
      );

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      expect(find.text('• Đang mượn: 4/5 cuốn'), findsOneWidget);
      expect(find.text('• Còn được mượn: 1 cuốn'), findsOneWidget);
      expect(find.text('• Đang chọn: 2 cuốn'), findsOneWidget);
      expect(
        find.text(
          'Số lượng sách chọn (2 cuốn) vượt quá hạn mức còn lại (1 cuốn)',
        ),
        findsOneWidget,
      );

      final submitButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Gửi phiếu mượn'),
      );
      expect(submitButton.onPressed, isNull);
    });

    testWidgets(
      'Tăng số lượng vượt hạn mức rồi giảm lại | Nút tự động chuyển trạng thái',
      (tester) async {
        setLargeScreen(tester);

        // Còn được mượn 2 cuốn, ban đầu chọn 2 cuốn (1 + 1) => Đủ điều kiện
        membersRepository.fakeDebtSummary = const MemberDebtSummary(
          maxBorrowLimit: 5,
          currentBorrowedCount: 3,
          remainingBorrowLimit: 2,
          canBorrow: true,
          overdueCount: 0,
          unpaidFineAmount: 0,
        );

        await tester.pumpWidget(createApp());
        await tester.pumpAndSettle();

        var submitButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Gửi phiếu mượn'),
        );
        expect(submitButton.onPressed, isNotNull);

        // Tăng số lượng cuốn đầu tiên lên 2 (tổng = 3 cuốn > 2)
        await tester.tap(find.byIcon(Icons.add_circle_outline).first);
        await tester.pumpAndSettle();

        expect(find.text('• Đang chọn: 3 cuốn'), findsOneWidget);
        expect(
          find.text(
            'Số lượng sách chọn (3 cuốn) vượt quá hạn mức còn lại (2 cuốn)',
          ),
          findsOneWidget,
        );

        submitButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Gửi phiếu mượn'),
        );
        expect(submitButton.onPressed, isNull);

        // Giảm số lượng cuốn đầu tiên về 1 (tổng = 2 cuốn <= 2)
        await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
        await tester.pumpAndSettle();

        expect(find.text('• Đang chọn: 2 cuốn'), findsOneWidget);
        expect(find.text('Đủ điều kiện gửi phiếu mượn'), findsOneWidget);

        submitButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Gửi phiếu mượn'),
        );
        expect(submitButton.onPressed, isNotNull);
      },
    );

    testWidgets(
      'Tài khoản không đủ điều kiện mượn | Hiển thị lý do và disable nút',
      (tester) async {
        setLargeScreen(tester);

        membersRepository.fakeDebtSummary = const MemberDebtSummary(
          maxBorrowLimit: 5,
          currentBorrowedCount: 1,
          remainingBorrowLimit: 4,
          canBorrow: false,
          reasonIfNotAllowed:
              'Thẻ độc giả đã hết hạn. Vui lòng liên hệ thư viện.',
          overdueCount: 0,
          unpaidFineAmount: 0,
        );

        await tester.pumpWidget(createApp());
        await tester.pumpAndSettle();

        expect(
          find.text('Thẻ độc giả đã hết hạn. Vui lòng liên hệ thư viện.'),
          findsOneWidget,
        );

        final submitButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Gửi phiếu mượn'),
        );
        expect(submitButton.onPressed, isNull);
      },
    );

    testWidgets('Tải hạn mức lỗi | Hiển thị Thử lại và không cho gửi phiếu', (
      tester,
    ) async {
      setLargeScreen(tester);

      membersRepository.shouldFailDebtSummary = true;

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      expect(
        find.text('Không thể tải thông tin hạn mức mượn sách'),
        findsOneWidget,
      );
      expect(find.text('Thử lại'), findsOneWidget);

      final submitButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Gửi phiếu mượn'),
      );
      expect(submitButton.onPressed, isNull);

      // Thử lại thành công
      membersRepository.shouldFailDebtSummary = false;
      membersRepository.fakeDebtSummary = const MemberDebtSummary(
        maxBorrowLimit: 5,
        currentBorrowedCount: 0,
        remainingBorrowLimit: 5,
        canBorrow: true,
      );

      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.text('• Đang mượn: 0/5 cuốn'), findsOneWidget);
      expect(find.text('Đủ điều kiện gửi phiếu mượn'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Gửi phiếu mượn'),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets(
      'Thời hạn mượn tùy chỉnh | Chọn chip 1 ngày hoặc nhập số ngày | Gửi đúng expectedReturnDays',
      (tester) async {
        setLargeScreen(tester);

        membersRepository.fakeDebtSummary = const MemberDebtSummary(
          maxBorrowLimit: 5,
          currentBorrowedCount: 0,
          remainingBorrowLimit: 5,
          canBorrow: true,
        );

        await tester.pumpWidget(createApp());
        await tester.pumpAndSettle();

        // Mặc định là 14 ngày
        expect(find.text('14'), findsOneWidget);

        // Chọn chip 1 ngày để test ngắn ngày
        await tester.tap(find.widgetWithText(ChoiceChip, '1 ngày'));
        await tester.pumpAndSettle();

        expect(find.text('1'), findsWidgets);

        // Nhập tùy ý 3 ngày
        final daysField = find.widgetWithText(TextFormField, 'Số ngày mượn');
        await tester.enterText(daysField, '3');
        await tester.pumpAndSettle();

        // Gửi phiếu
        await tester.tap(find.widgetWithText(FilledButton, 'Gửi phiếu mượn'));
        await tester.pumpAndSettle();

        expect(borrowingSlipsRepository.createSlipCallCount, 1);
        expect(
          borrowingSlipsRepository.createSlipRequests.first.expectedReturnDays,
          3,
        );
      },
    );

    testWidgets(
      'Thời hạn mượn không hợp lệ | Nhập 0 hoặc > 30 | Báo lỗi và disable nút gửi',
      (tester) async {
        setLargeScreen(tester);

        membersRepository.fakeDebtSummary = const MemberDebtSummary(
          maxBorrowLimit: 5,
          currentBorrowedCount: 0,
          remainingBorrowLimit: 5,
          canBorrow: true,
        );

        await tester.pumpWidget(createApp());
        await tester.pumpAndSettle();

        final daysField = find.widgetWithText(TextFormField, 'Số ngày mượn');

        // Nhập 0 ngày
        await tester.enterText(daysField, '0');
        await tester.pumpAndSettle();

        expect(
          find.text('Thời hạn mượn phải từ 1 đến 30 ngày'),
          findsOneWidget,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Gửi phiếu mượn'),
              )
              .onPressed,
          isNull,
        );

        // Nhập 45 ngày
        await tester.enterText(daysField, '45');
        await tester.pumpAndSettle();

        expect(
          find.text('Thời hạn mượn phải từ 1 đến 30 ngày'),
          findsOneWidget,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Gửi phiếu mượn'),
              )
              .onPressed,
          isNull,
        );
      },
    );
  });
}
