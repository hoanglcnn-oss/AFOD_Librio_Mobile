import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/auth/data/models/user_profile.dart';
import 'package:week34_project/features/borrowing_slips/data/models/borrowing_slip.dart';
import 'package:week34_project/features/borrowing_slips/presentation/pages/borrowing_slip_detail_screen.dart';

import 'fake/fake_auth_repository.dart';
import 'fake/fake_borrowing_repository.dart';
import 'fake/fake_token_storage.dart';

void main() {
  late FakeAuthRepository authRepository;
  late FakeTokenStorage tokenStorage;
  late AuthBloc authBloc;

  setUp(() {
    authRepository = FakeAuthRepository();
    tokenStorage = FakeTokenStorage();
    authBloc = AuthBloc(
      authRepository: authRepository,
      tokenStorage: tokenStorage,
    );
  });

  tearDown(() async {
    await authBloc.close();
  });

  Widget createApp(
    FakeBorrowingRepository repository, {
    String role = 'LIBRARIAN',
  }) {
    authBloc.emit(
      AuthAuthenticated(
        user: UserProfile(
          id: 'user-01',
          email: 'test@librio.vn',
          phone: '0901234567',
          fullName: 'Người dùng kiểm thử',
          role: role,
          isActive: true,
          createdAt: DateTime(2026, 1, 1),
        ),
      ),
    );

    return BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: MaterialApp(
        home: Scaffold(
          body: BorrowingSlipDetailScreen(
            slipId: 'slip-01',
            repository: repository,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'BorrowingSlipDetailScreen | LIBRARIAN xem phiếu PENDING_APPROVAL | Hiển thị nút Duyệt và Từ chối',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.fakeSlipDetail = BorrowingSlip(
        id: 'slip-01',
        slipNumber: 'SLIP-2026-0001',
        memberId: 'mem-01',
        status: 'PENDING_APPROVAL',
        dueDate: DateTime.utc(2026, 11, 25),
        items: const [
          BorrowingSlipItem(
            id: 'it-1',
            bookId: 'b-1',
            bookTitle: 'Clean Code',
            quantity: 1,
            status: 'PENDING',
          ),
        ],
      );

      await tester.pumpWidget(createApp(repository, role: 'LIBRARIAN'));
      await tester.pumpAndSettle();

      expect(find.text('SLIP-2026-0001'), findsOneWidget);
      expect(find.text('Độc giả: mem-01'), findsOneWidget);
      expect(find.text('Duyệt phiếu'), findsOneWidget);
      expect(find.text('Từ chối'), findsOneWidget);
    },
  );

  testWidgets(
    'BorrowingSlipDetailScreen | MEMBER xem phiếu PENDING_APPROVAL | Không hiển thị nút Duyệt và Từ chối',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.fakeSlipDetail = BorrowingSlip(
        id: 'slip-01',
        slipNumber: 'SLIP-2026-0001',
        memberId: 'mem-01',
        status: 'PENDING_APPROVAL',
        dueDate: DateTime.utc(2026, 11, 25),
        items: const [
          BorrowingSlipItem(
            id: 'it-1',
            bookId: 'b-1',
            bookTitle: 'Clean Code',
            quantity: 1,
            status: 'PENDING',
          ),
        ],
      );

      await tester.pumpWidget(createApp(repository, role: 'MEMBER'));
      await tester.pumpAndSettle();

      expect(find.text('SLIP-2026-0001'), findsOneWidget);
      expect(find.text('Duyệt phiếu'), findsNothing);
      expect(find.text('Từ chối'), findsNothing);
    },
  );

  testWidgets(
    'BorrowingSlipDetailScreen | LIBRARIAN duyệt phiếu | Mở dialog và gọi approve khi xác nhận',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.fakeSlipDetail = BorrowingSlip(
        id: 'slip-01',
        slipNumber: 'SLIP-2026-0001',
        memberId: 'mem-01',
        status: 'PENDING_APPROVAL',
        dueDate: DateTime.utc(2026, 11, 25),
        items: const [
          BorrowingSlipItem(
            id: 'it-1',
            bookId: 'b-1',
            bookTitle: 'Clean Code',
            quantity: 1,
            status: 'PENDING',
          ),
        ],
      );

      await tester.pumpWidget(createApp(repository, role: 'LIBRARIAN'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Duyệt phiếu'));
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận duyệt phiếu'), findsOneWidget);

      await tester.tap(find.text('Xác nhận duyệt'));
      await tester.pumpAndSettle();

      expect(repository.approveSlipCallCount, 1);
    },
  );

  testWidgets(
    'BorrowingSlipDetailScreen | LIBRARIAN xem phiếu có phạt chưa trả | Hiển thị nút Ghi nhận đã thu tiền phạt',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.fakeSlipDetail = BorrowingSlip(
        id: 'slip-01',
        slipNumber: 'SLIP-2026-0001',
        memberId: 'mem-01',
        status: 'COMPLETED',
        dueDate: DateTime.utc(2026, 11, 1),
        totalFine: 50000,
        finePaid: false,
        items: const [],
      );

      await tester.pumpWidget(createApp(repository, role: 'LIBRARIAN'));
      await tester.pumpAndSettle();

      expect(find.text('Ghi nhận đã thu tiền phạt'), findsOneWidget);
    },
  );

  testWidgets(
    'BorrowingSlipDetailScreen | MEMBER xem phiếu có phạt chưa trả | Hiển thị thông báo liên hệ thủ thư',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.fakeSlipDetail = BorrowingSlip(
        id: 'slip-01',
        slipNumber: 'SLIP-2026-0001',
        memberId: 'mem-01',
        status: 'COMPLETED',
        dueDate: DateTime.utc(2026, 11, 1),
        totalFine: 50000,
        finePaid: false,
        items: const [],
      );

      await tester.pumpWidget(createApp(repository, role: 'MEMBER'));
      await tester.pumpAndSettle();

      expect(find.text('Ghi nhận đã thu tiền phạt'), findsNothing);
      expect(
        find.text('Vui lòng liên hệ thủ thư để thanh toán tiền phạt.'),
        findsOneWidget,
      );
    },
  );
}
