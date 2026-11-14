import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/auth/data/models/user_profile.dart';
import 'package:week34_project/features/borrowing/shared/repositories/borrowing_slips_repository.dart';
import 'package:week34_project/features/borrowing/shared/models/borrowing_slip.dart';
import 'package:week34_project/features/borrowing/slip_management/presentation/pages/borrowing_slip_detail_screen.dart';

import 'fake/fake_auth_repository.dart';
import 'fake/fake_borrowing_repository.dart';
import 'fake/fake_members_repository.dart';
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
    String memberId = 'mem-01',
  }) {
    authBloc.emit(
      AuthAuthenticated(
        user: UserProfile(
          id: 'user-01',
          memberId: memberId,
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
            membersRepository: FakeMembersRepository(),
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
      expect(find.text('Mã độc giả: mem-01'), findsOneWidget);
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

  testWidgets(
    'BorrowingSlipDetailScreen | Có memberName và memberCardNumber | Hiển thị tên và số thẻ, giữ copy ID',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.fakeSlipDetail = BorrowingSlip(
        id: 'slip-with-name',
        slipNumber: 'SLIP-2026-0002',
        memberId: 'mem-999',
        memberName: 'Nguyễn Văn An',
        memberCardNumber: 'CARD-12345',
        status: 'BORROWED',
        dueDate: DateTime.utc(2026, 11, 25),
        items: [],
      );

      await tester.pumpWidget(createApp(repository, role: 'LIBRARIAN'));
      await tester.pumpAndSettle();

      expect(find.text('Độc giả: Nguyễn Văn An'), findsOneWidget);
      expect(find.text('Số thẻ: CARD-12345'), findsOneWidget);
      expect(find.text('Mã độc giả: mem-999'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    },
  );

  testWidgets(
    'BorrowingSlipDetailScreen | LIBRARIAN duyệt thất bại do vượt hạn mức | Hiển thị cảnh báo và không đổi trạng thái',
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
      repository.approveSlipException = const BorrowLimitExceededException(
        message: 'Độc giả đã vượt quá hạn mức mượn sách',
        code: 'BORROW_LIMIT_EXCEEDED',
        details: {'maxBorrowLimit': 5, 'currentBorrowedCount': 5},
      );

      await tester.pumpWidget(createApp(repository, role: 'LIBRARIAN'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Duyệt phiếu'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận duyệt'));
      await tester.pumpAndSettle();

      expect(find.text('Không thể duyệt: Vượt hạn mức'), findsOneWidget);
      expect(find.text('Độc giả đã vượt quá hạn mức mượn sách'), findsWidgets);
      expect(find.text('• Hạn mức tối đa: 5 cuốn'), findsOneWidget);
      expect(find.text('• Đang mượn: 5 cuốn'), findsOneWidget);
      expect(find.text('Đóng'), findsOneWidget);

      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();

      // Màn hình chi tiết vẫn giữ trạng thái PENDING_APPROVAL với nút Duyệt phiếu
      expect(find.text('Duyệt phiếu'), findsOneWidget);
    },
  );

  testWidgets(
    'C5.5 | MEMBER xem phiếu PENDING_APPROVAL của mình | Hiển thị nút Hủy phiếu mượn',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.fakeSlipDetail = BorrowingSlip(
        id: 'slip-01',
        slipNumber: 'SLIP-2026-0001',
        memberId: 'mem-01',
        status: 'PENDING_APPROVAL',
        dueDate: DateTime.utc(2026, 11, 25),
        items: const [],
      );

      await tester.pumpWidget(
        createApp(repository, role: 'MEMBER', memberId: 'mem-01'),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('cancel_pending_slip_button')),
        findsOneWidget,
      );
      expect(find.text('Hủy phiếu mượn'), findsOneWidget);
    },
  );

  testWidgets(
    'C5.5 | MEMBER hủy phiếu mượn thành công | Gửi PATCH cancel, cập nhật trạng thái CANCELLED',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.fakeSlipDetail = BorrowingSlip(
        id: 'slip-01',
        slipNumber: 'SLIP-2026-0001',
        memberId: 'mem-01',
        status: 'PENDING_APPROVAL',
        dueDate: DateTime.utc(2026, 11, 25),
        items: const [],
      );

      await tester.pumpWidget(
        createApp(repository, role: 'MEMBER', memberId: 'mem-01'),
      );
      await tester.pumpAndSettle();

      // Bấm Hủy phiếu mượn -> mở dialog xác nhận
      await tester.tap(
        find.byKey(const ValueKey('cancel_pending_slip_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hủy phiếu mượn'), findsWidgets);
      expect(
        find.text('Bạn có chắc chắn muốn hủy phiếu mượn SLIP-2026-0001?'),
        findsOneWidget,
      );

      // Nhập lý do hủy tùy chọn
      await tester.enterText(find.byType(TextField), 'Đổi ý không mượn nữa');
      await tester.pumpAndSettle();

      // Bấm Xác nhận hủy
      await tester.tap(
        find.byKey(const ValueKey('confirm_cancel_slip_button')),
      );
      await tester.pumpAndSettle();

      expect(repository.cancelSlipCallCount, 1);
      expect(repository.lastCancelSlipReason, 'Đổi ý không mượn nữa');

      // Cập nhật trạng thái CANCELLED, hiển thị toast thành công
      expect(find.text('Đã hủy phiếu mượn thành công'), findsOneWidget);
      expect(find.text('Trạng thái: Đã hủy'), findsOneWidget);
      // Nút Hủy phiếu mượn không còn hiển thị khi trạng thái là CANCELLED
      expect(
        find.byKey(const ValueKey('cancel_pending_slip_button')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'C5.5 | Timeout khi hủy phiếu mượn | Không tự gửi PATCH lần hai, GET lại chi tiết để kiểm tra',
    (tester) async {
      final repository = FakeBorrowingRepository();
      final initialSlip = BorrowingSlip(
        id: 'slip-01',
        slipNumber: 'SLIP-2026-0001',
        memberId: 'mem-01',
        status: 'PENDING_APPROVAL',
        dueDate: DateTime.utc(2026, 11, 25),
        items: const [],
      );
      repository.fakeSlipDetail = initialSlip;

      // Giả lập lỗi timeout trên PATCH
      repository.cancelSlipError = DioException(
        requestOptions: RequestOptions(path: '/borrowing-slips/slip-01/cancel'),
        type: DioExceptionType.connectionTimeout,
        error: 'Connection timeout',
      );

      // Nhưng Backend thực tế đã xử lý thành công, sau khi gọi cancel thì GET lại trả về CANCELLED
      repository.fakeSlipDetailBuilder = (slipId) =>
          repository.cancelSlipCallCount > 0
          ? BorrowingSlip(
              id: slipId,
              slipNumber: 'SLIP-2026-0001',
              memberId: 'mem-01',
              status: 'CANCELLED',
              dueDate: DateTime.utc(2026, 11, 25),
              items: const [],
            )
          : initialSlip;

      await tester.pumpWidget(
        createApp(repository, role: 'MEMBER', memberId: 'mem-01'),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('cancel_pending_slip_button')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('confirm_cancel_slip_button')),
      );
      await tester.pumpAndSettle();

      // Chỉ gọi PATCH 1 lần duy nhất, KHÔNG tự gọi lần hai
      expect(repository.cancelSlipCallCount, 1);
      // Đã gọi GET để kiểm tra kết quả
      expect(repository.getBorrowingSlipByIdCallCount, greaterThanOrEqualTo(2));
      // Xác nhận thành công dựa trên GET
      expect(find.text('Đã hủy phiếu mượn thành công'), findsOneWidget);
      expect(find.text('Trạng thái: Đã hủy'), findsOneWidget);
    },
  );

  testWidgets(
    'C5.5 | MEMBER xem phiếu của người khác hoặc phiếu BORROWED/COMPLETED/REJECTED/CANCELLED | Không hiển thị nút Hủy phiếu',
    (tester) async {
      final repository = FakeBorrowingRepository();

      // Trường hợp 1: Phiếu của người khác
      repository.fakeSlipDetail = BorrowingSlip(
        id: 'slip-01',
        slipNumber: 'SLIP-2026-0001',
        memberId: 'mem-OTHER',
        status: 'PENDING_APPROVAL',
        dueDate: DateTime.utc(2026, 11, 25),
        items: const [],
      );

      await tester.pumpWidget(
        createApp(repository, role: 'MEMBER', memberId: 'mem-01'),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('cancel_pending_slip_button')),
        findsNothing,
      );

      // Trường hợp 2: Phiếu đã BORROWED
      repository.fakeSlipDetail = BorrowingSlip(
        id: 'slip-01',
        slipNumber: 'SLIP-2026-0001',
        memberId: 'mem-01',
        status: 'BORROWED',
        dueDate: DateTime.utc(2026, 11, 25),
        items: const [],
      );

      await tester.pumpWidget(
        createApp(repository, role: 'MEMBER', memberId: 'mem-01'),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('cancel_pending_slip_button')),
        findsNothing,
      );

      // Trường hợp 3: Phiếu đã CANCELLED
      repository.fakeSlipDetail = BorrowingSlip(
        id: 'slip-01',
        slipNumber: 'SLIP-2026-0001',
        memberId: 'mem-01',
        status: 'CANCELLED',
        dueDate: DateTime.utc(2026, 11, 25),
        items: const [],
      );

      await tester.pumpWidget(
        createApp(repository, role: 'MEMBER', memberId: 'mem-01'),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('cancel_pending_slip_button')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'C5.5 | LIBRARIAN xem phiếu PENDING_APPROVAL | Không hiển thị nút Hủy phiếu mượn của MEMBER',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.fakeSlipDetail = BorrowingSlip(
        id: 'slip-01',
        slipNumber: 'SLIP-2026-0001',
        memberId: 'mem-01',
        status: 'PENDING_APPROVAL',
        dueDate: DateTime.utc(2026, 11, 25),
        items: const [],
      );

      await tester.pumpWidget(
        createApp(repository, role: 'LIBRARIAN', memberId: 'mem-01'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Duyệt phiếu'), findsOneWidget);
      expect(find.text('Từ chối'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cancel_pending_slip_button')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'C5.5 | MEMBER hủy phiếu mượn không nhập lý do | Gửi reason null',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.fakeSlipDetail = BorrowingSlip(
        id: 'slip-01',
        slipNumber: 'SLIP-2026-0001',
        memberId: 'mem-01',
        status: 'PENDING_APPROVAL',
        dueDate: DateTime.utc(2026, 11, 25),
        items: const [],
      );

      await tester.pumpWidget(
        createApp(repository, role: 'MEMBER', memberId: 'mem-01'),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('cancel_pending_slip_button')),
      );
      await tester.pumpAndSettle();

      // Không nhập lý do, bấm Xác nhận hủy trực tiếp
      await tester.tap(
        find.byKey(const ValueKey('confirm_cancel_slip_button')),
      );
      await tester.pumpAndSettle();

      expect(repository.cancelSlipCallCount, 1);
      expect(repository.lastCancelSlipReason, isNull);
      expect(find.text('Đã hủy phiếu mượn thành công'), findsOneWidget);
    },
  );

  testWidgets(
    'C5.5 | MEMBER đóng dialog hủy phiếu | Không gọi cancel repository',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.fakeSlipDetail = BorrowingSlip(
        id: 'slip-01',
        slipNumber: 'SLIP-2026-0001',
        memberId: 'mem-01',
        status: 'PENDING_APPROVAL',
        dueDate: DateTime.utc(2026, 11, 25),
        items: const [],
      );

      await tester.pumpWidget(
        createApp(repository, role: 'MEMBER', memberId: 'mem-01'),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('cancel_pending_slip_button')),
      );
      await tester.pumpAndSettle();

      // Bấm nút Đóng
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();

      expect(repository.cancelSlipCallCount, 0);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
}
