import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/auth/data/models/user_profile.dart';
import 'package:week34_project/features/borrowings/data/models/borrowing_slip.dart';
import 'package:week34_project/features/borrowings/data/models/borrowing_slips_page.dart';
import 'package:week34_project/features/borrowings/presentation/pages/borrowing_slip_detail_screen.dart';
import 'package:week34_project/features/borrowings/presentation/pages/manage_borrowing_slips_screen.dart';

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
          email: 'librarian@librio.vn',
          phone: '0901234567',
          fullName: 'Nguyễn Thủ Thư',
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
          body: ManageBorrowingSlipsScreen(repository: repository),
        ),
      ),
    );
  }

  testWidgets(
    'ManageBorrowingSlipsScreen | Mặc định | Hiển thị phiếu, thông tin độc giả và filter Tất cả',
    (tester) async {
      final repository = FakeBorrowingRepository();

      await tester.pumpWidget(createApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Chờ duyệt'), findsOneWidget);
      expect(find.text('Đang mượn'), findsOneWidget);
      expect(find.text('SLIP-2026-0001'), findsOneWidget);
      expect(find.text('Độc giả: mem-01'), findsOneWidget);
      expect(repository.getAllSlipsCallCount, 1);
      expect(repository.lastGetAllSlipsStatus, isNull);
    },
  );

  testWidgets(
    'ManageBorrowingSlipsScreen | Chọn filter Chờ duyệt | Gọi getAllBorrowingSlips với status PENDING_APPROVAL',
    (tester) async {
      final repository = FakeBorrowingRepository();

      await tester.pumpWidget(createApp(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chờ duyệt'));
      await tester.pumpAndSettle();

      expect(repository.getAllSlipsCallCount, 2);
      expect(repository.lastGetAllSlipsStatus, 'PENDING_APPROVAL');
      expect(repository.lastGetAllSlipsPage, 1);
    },
  );

  testWidgets(
    'ManageBorrowingSlipsScreen | Chọn filter Đang mượn rồi chọn Tất cả | Reset trang 1 và không gửi status',
    (tester) async {
      final repository = FakeBorrowingRepository();

      await tester.pumpWidget(createApp(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đang mượn'));
      await tester.pumpAndSettle();
      expect(repository.lastGetAllSlipsStatus, 'BORROWED');

      await tester.tap(find.text('Tất cả'));
      await tester.pumpAndSettle();

      expect(repository.lastGetAllSlipsStatus, isNull);
      expect(repository.lastGetAllSlipsPage, 1);
    },
  );

  testWidgets(
    'ManageBorrowingSlipsScreen | Danh sách rỗng | Hiển thị thông báo không có phiếu mượn nào',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.fakeAllSlipsPage = const BorrowingSlipsPage(
        slips: [],
        page: 1,
        limit: 10,
        totalItems: 0,
        totalPages: 0,
        hasNextPage: false,
      );

      await tester.pumpWidget(createApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('Không có phiếu mượn nào'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
      expect(find.text('Tổng số: 0 phiếu'), findsOneWidget);
    },
  );

  testWidgets(
    'ManageBorrowingSlipsScreen | Tải danh sách lỗi | Hiển thị nút Thử lại và tải lại',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.shouldFailGetAllSlips = true;

      await tester.pumpWidget(createApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('Không thể tải danh sách phiếu mượn'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      repository.shouldFailGetAllSlips = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.text('SLIP-2026-0001'), findsOneWidget);
      expect(repository.getAllSlipsCallCount, 2);
    },
  );

  testWidgets(
    'ManageBorrowingSlipsScreen | Nhiều trang | Chuyển sang trang tiếp theo khi nhấn nút',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.fakeAllSlipsBuilder = (status, page, limit) {
        return BorrowingSlipsPage(
          slips: [
            BorrowingSlip(
              id: 'slip-$page',
              slipNumber: 'SLIP-PAGE-$page',
              memberId: 'mem-$page',
              status: 'BORROWED',
              dueDate: DateTime.utc(2026, 11, 25),
              items: const [],
            ),
          ],
          page: page,
          limit: limit,
          totalItems: 20,
          totalPages: 2,
          hasNextPage: page == 1,
        );
      };

      await tester.pumpWidget(createApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('Trang 1/2'), findsOneWidget);
      expect(find.text('SLIP-PAGE-1'), findsOneWidget);

      await tester.tap(find.byTooltip('Trang sau'));
      await tester.pumpAndSettle();

      expect(find.text('Trang 2/2'), findsOneWidget);
      expect(find.text('SLIP-PAGE-2'), findsOneWidget);
      expect(repository.lastGetAllSlipsPage, 2);
    },
  );

  testWidgets(
    'ManageBorrowingSlipsScreen | Phiếu PENDING_APPROVAL | Hiển thị Duyệt/Từ chối và gọi approve khi xác nhận',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.fakeAllSlipsPage = BorrowingSlipsPage(
        slips: [
          BorrowingSlip(
            id: 'slip-pending-01',
            slipNumber: 'SLIP-PENDING-0001',
            memberId: 'mem-99',
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
          ),
        ],
        page: 1,
        limit: 10,
        totalItems: 1,
        totalPages: 1,
        hasNextPage: false,
      );

      await tester.pumpWidget(createApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('Duyệt phiếu'), findsOneWidget);
      expect(find.text('Từ chối'), findsOneWidget);

      await tester.tap(find.text('Duyệt phiếu'));
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận duyệt phiếu'), findsOneWidget);

      await tester.tap(find.text('Xác nhận duyệt'));
      await tester.pumpAndSettle();

      expect(repository.approveSlipCallCount, 1);
    },
  );

  testWidgets(
    'ManageBorrowingSlipsScreen | Nhấn vào phiếu | Mở màn hình chi tiết phiếu',
    (tester) async {
      final repository = FakeBorrowingRepository();

      await tester.pumpWidget(createApp(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SLIP-2026-0001'));
      await tester.pumpAndSettle();

      expect(find.byType(BorrowingSlipDetailScreen), findsOneWidget);
      expect(find.text('Chi tiết phiếu mượn'), findsOneWidget);
    },
  );
}
