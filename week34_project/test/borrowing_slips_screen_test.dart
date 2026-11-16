import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/auth/data/models/user_profile.dart';
import 'package:week34_project/features/borrowing/shared/models/borrowing_slip.dart';
import 'package:week34_project/features/borrowing/shared/models/paginated_borrowing_slips.dart';
import 'package:week34_project/features/borrowing/slip_management/presentation/pages/borrowing_slip_detail_screen.dart';
import 'package:week34_project/features/borrowing/slip_management/presentation/pages/borrowing_slip_list_screen.dart';

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
    String? memberId,
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
          body: BorrowingSlipsScreen(
            repository: repository,
            memberId: memberId,
          ),
        ),
      ),
    );
  }

  group('BorrowingSlipsScreen - Librarian View (memberId == null)', () {
    testWidgets(
      'Mặc định | Hiển thị phiếu, thông tin độc giả và filter Tất cả',
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
      'Chọn filter Chờ duyệt | Gọi getAllBorrowingSlips với status PENDING_APPROVAL',
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
      'Chọn filter Đang mượn rồi chọn Tất cả | Reset trang 1 và không gửi status',
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
      'Danh sách rỗng | Hiển thị thông báo không có phiếu mượn nào',
      (tester) async {
        final repository = FakeBorrowingRepository();
        repository.fakeAllSlipsPage = const PaginatedBorrowingSlips(
          slips: [],
          page: 1,
          limit: 10,
          totalItems: 0,
          totalPages: 1,
          hasNextPage: false,
        );

        await tester.pumpWidget(createApp(repository));
        await tester.pumpAndSettle();

        expect(find.text('Không có phiếu mượn nào'), findsOneWidget);
        expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'Tải danh sách lỗi | Hiển thị nút Thử lại và tải lại',
      (tester) async {
        final repository = FakeBorrowingRepository(shouldFail: true);
        repository.shouldFailGetAllSlips = true;

        await tester.pumpWidget(createApp(repository));
        await tester.pumpAndSettle();

        expect(
          find.text('Không thể tải danh sách phiếu mượn'),
          findsOneWidget,
        );
        expect(find.text('Thử lại'), findsOneWidget);

        repository.shouldFailGetAllSlips = false;
        repository.shouldFail = false;

        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();

        expect(find.text('SLIP-2026-0001'), findsOneWidget);
      },
    );

    testWidgets(
      'Nhiều trang | Chuyển sang trang tiếp theo khi nhấn nút',
      (tester) async {
        final repository = FakeBorrowingRepository();
        repository.fakeAllSlipsBuilder = (status, page, limit) {
          return PaginatedBorrowingSlips(
            slips: [
              BorrowingSlip(
                id: 'slip-$page',
                slipNumber: 'SLIP-PAGE-$page',
                memberId: 'mem-01',
                status: 'BORROWED',
                dueDate: DateTime.utc(2026, 11, 25),
                items: [],
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
      'Phiếu PENDING_APPROVAL | Chỉ hiển thị thông tin thẻ, không có nút inline duyệt nhanh',
      (tester) async {
        final repository = FakeBorrowingRepository();
        repository.fakeAllSlipsPage = PaginatedBorrowingSlips(
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

        expect(find.text('SLIP-PENDING-0001'), findsOneWidget);
        // Không còn các nút duyệt nhanh trên danh sách
        expect(find.text('Duyệt phiếu'), findsNothing);
        expect(find.text('Từ chối'), findsNothing);
      },
    );

    testWidgets(
      'Nhấn vào phiếu | Mở màn hình chi tiết phiếu',
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

    testWidgets(
      'Phiếu có memberName | Ưu tiên hiển thị họ tên thay vì ID',
      (tester) async {
        final repository = FakeBorrowingRepository();
        repository.fakeAllSlipsPage = PaginatedBorrowingSlips(
          slips: [
            BorrowingSlip(
              id: 'slip-with-name',
              slipNumber: 'SLIP-NAME-01',
              memberId: 'mem-99',
              memberName: 'Nguyễn Văn An',
              status: 'BORROWED',
              dueDate: DateTime.utc(2026, 11, 25),
              items: [],
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

        expect(find.text('Độc giả: Nguyễn Văn An'), findsOneWidget);
      },
    );
  });

  group('BorrowingSlipsScreen - Member View (memberId != null)', () {
    testWidgets(
      'Gọi getBorrowingSlips với memberId, ẩn thông tin độc giả trên card và hỗ trợ filter status',
      (tester) async {
        final repository = FakeBorrowingRepository();
        repository.fakeAllSlipsBuilder = (status, page, limit) {
          return PaginatedBorrowingSlips(
            slips: [
              BorrowingSlip(
                id: 'slip-mem-01',
                slipNumber: 'SLIP-MY-001',
                memberId: 'mem-123',
                status: status ?? 'BORROWED',
                dueDate: DateTime.utc(2026, 11, 25),
                items: [],
              ),
            ],
            page: page,
            limit: limit,
            totalItems: 1,
            totalPages: 1,
            hasNextPage: false,
          );
        };

        await tester.pumpWidget(createApp(repository, memberId: 'mem-123'));
        await tester.pumpAndSettle();

        // 1. Gọi đúng API của member
        expect(repository.getBorrowingSlipsCallCount, 1);
        expect(repository.lastGetSlipsMemberId, 'mem-123');
        expect(repository.lastGetSlipsStatus, isNull);

        // 2. Hiển thị số phiếu
        expect(find.text('SLIP-MY-001'), findsOneWidget);

        // 3. Ẩn thông tin độc giả vì là view cá nhân
        expect(find.textContaining('Độc giả:'), findsNothing);

        // 4. Chọn filter trạng thái
        await tester.tap(find.text('Đang mượn'));
        await tester.pumpAndSettle();

        expect(repository.getBorrowingSlipsCallCount, 2);
        expect(repository.lastGetSlipsStatus, 'BORROWED');
      },
    );
  });
}
