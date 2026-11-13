import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowing/shared/repositories/borrowing_slips_repository.dart';
import 'package:week34_project/features/borrowing/shared/models/borrowing_slip.dart';
import 'package:week34_project/features/borrowing/shared/models/paginated_borrowing_slips.dart';
import 'package:week34_project/features/borrowing_slips/presentation/pages/pending_borrowing_slips_screen.dart';

import 'fake/fake_borrowing_repository.dart';

void main() {
  Widget createApp(FakeBorrowingRepository repository) {
    return MaterialApp(
      home: Scaffold(body: PendingBorrowingSlipsScreen(repository: repository)),
    );
  }
  // Event | Điều kiện đầu vào | Kết quả được kiểm chứng

  testWidgets('PendingSlipsScreen | Có phiếu chờ | Hiển thị Duyệt và Từ chối', (
    tester,
  ) async {
    final repository = FakeBorrowingRepository();

    await tester.pumpWidget(createApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('SLIP-2026-0001'), findsOneWidget);
    expect(find.text('Duyệt phiếu'), findsOneWidget);
    expect(find.text('Từ chối'), findsOneWidget);
  });

  testWidgets('PendingSlipsScreen | Xác nhận duyệt | Gọi approve một lần', (
    tester,
  ) async {
    final repository = FakeBorrowingRepository();

    await tester.pumpWidget(createApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Duyệt phiếu'));
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận duyệt phiếu'), findsOneWidget);

    // Chưa xác nhận thì chưa được gọi API.
    expect(repository.approveSlipCallCount, 0);

    await tester.tap(find.text('Xác nhận duyệt'));
    await tester.pumpAndSettle();

    expect(repository.approveSlipCallCount, 1);
    expect(find.text('Xác nhận duyệt phiếu'), findsNothing);
  });

  testWidgets('PendingSlipsScreen | Từ chối có lý do | Gửi reason đã trim', (
    tester,
  ) async {
    final repository = FakeBorrowingRepository();

    await tester.pumpWidget(createApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Từ chối'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  Sách đang kiểm kê  ');

    await tester.tap(find.text('Xác nhận từ chối'));
    await tester.pumpAndSettle();

    expect(repository.rejectSlipCallCount, 1);
    expect(repository.lastRejectionReason, 'Sách đang kiểm kê');
  });

  testWidgets('PendingSlipsScreen | Từ chối thiếu lý do | Không gọi API', (
    tester,
  ) async {
    final repository = FakeBorrowingRepository();

    await tester.pumpWidget(createApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Từ chối'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Xác nhận từ chối'));
    await tester.pumpAndSettle();

    expect(repository.rejectSlipCallCount, 0);
    expect(find.text('Cần nhập lý do từ chối phiếu.'), findsOneWidget);
  });

  testWidgets(
    'PendingSlipsScreen | Danh sách rỗng | Hiển thị thông báo không có phiếu chờ duyệt',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.fakePendingSlipsPage = const PaginatedBorrowingSlips(
        slips: [],
        page: 1,
        limit: 10,
        totalItems: 0,
        totalPages: 0,
        hasNextPage: false,
      );

      await tester.pumpWidget(createApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('Không có phiếu chờ duyệt'), findsOneWidget);
      expect(find.byIcon(Icons.task_alt), findsOneWidget);
      expect(find.text('Đang chờ: 0 phiếu'), findsOneWidget);
    },
  );

  testWidgets(
    'PendingSlipsScreen | Tải danh sách lỗi | Hiển thị nút thử lại và tải lại khi bấm',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.shouldFailGetPendingSlips = true;

      await tester.pumpWidget(createApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('Không thể tải phiếu chờ duyệt'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      repository.shouldFailGetPendingSlips = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.text('SLIP-2026-0001'), findsOneWidget);
      expect(repository.getPendingSlipsCallCount, 2);
    },
  );

  testWidgets(
    'PendingSlipsScreen | Duyệt bị xung đột 409 | Đóng dialog và tự động tải lại danh sách',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.approveSlipError = DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 409,
          data: {'message': 'Phiếu vừa được xử lý hoặc tồn kho đã thay đổi.'},
        ),
      );

      await tester.pumpWidget(createApp(repository));
      await tester.pumpAndSettle();

      expect(repository.getPendingSlipsCallCount, 1);

      await tester.tap(find.text('Duyệt phiếu'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác nhận duyệt'));
      await tester.pumpAndSettle();

      // Dialog đã đóng
      expect(find.text('Xác nhận duyệt phiếu'), findsNothing);
      // Hiển thị thông báo
      expect(
        find.text('Phiếu vừa được xử lý hoặc tồn kho đã thay đổi.'),
        findsOneWidget,
      );
      // Danh sách được tự động refresh
      expect(repository.getPendingSlipsCallCount, 2);
    },
  );

  testWidgets(
    'PendingSlipsScreen | Nhiều trang | Chuyển sang trang tiếp theo khi nhấn nút',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.fakePendingSlipsBuilder = (page, limit) {
        return PaginatedBorrowingSlips(
          slips: [
            BorrowingSlip(
              id: 'slip-$page',
              slipNumber: 'SLIP-PAGE-$page',
              memberId: 'mem-$page',
              status: 'PENDING_APPROVAL',
              dueDate: DateTime.utc(2026, 11, 25),
              items: const [],
            ),
          ],
          page: page,
          limit: limit,
          totalItems: 12,
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
      expect(repository.getPendingSlipsCallCount, 2);
    },
  );

  testWidgets(
    'PendingSlipsScreen | Phiếu có memberName | Hiển thị tên độc giả trên thẻ',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.fakePendingSlipsPage = PaginatedBorrowingSlips(
        slips: [
          BorrowingSlip(
            id: 'slip-pending-name',
            slipNumber: 'SLIP-PEND-01',
            memberId: 'mem-99',
            memberName: 'Trần Thị Bình',
            status: 'PENDING_APPROVAL',
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

      expect(find.text('Độc giả: Trần Thị Bình'), findsOneWidget);
    },
  );

  testWidgets(
    'PendingSlipsScreen | Duyệt thất bại do vượt hạn mức | Hiển thị lý do, chi tiết số lượng và không đổi sang BORROWED',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.approveSlipException = const BorrowLimitExceededException(
        message: 'Độc giả đã vượt quá hạn mức mượn sách',
        code: 'BORROW_LIMIT_EXCEEDED',
        details: {
          'maxBorrowLimit': 5,
          'currentBorrowedCount': 4,
          'remainingBorrowLimit': 1,
          'requestQuantity': 2,
        },
      );

      await tester.pumpWidget(createApp(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Duyệt phiếu'));
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận duyệt phiếu'), findsOneWidget);

      await tester.tap(find.text('Xác nhận duyệt'));
      await tester.pumpAndSettle();

      // Hiển thị dialog cảnh báo vượt hạn mức với chi tiết
      expect(find.text('Không thể duyệt: Vượt hạn mức'), findsOneWidget);
      expect(find.text('Độc giả đã vượt quá hạn mức mượn sách'), findsWidgets);
      expect(find.text('• Hạn mức tối đa: 5 cuốn'), findsOneWidget);
      expect(find.text('• Đang mượn: 4 cuốn'), findsOneWidget);
      expect(find.text('• Hạn mức còn lại: 1 cuốn'), findsOneWidget);
      expect(find.text('• Số lượng yêu cầu: 2 cuốn'), findsOneWidget);

      // Nút đóng xuất hiện thay vì cho phép duyệt tiếp
      expect(find.text('Đóng'), findsOneWidget);
      expect(find.text('Xác nhận duyệt'), findsNothing);

      // Đóng dialog
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();

      // UI trên danh sách vẫn giữ nguyên phiếu ở trạng thái PENDING_APPROVAL, không chuyển sang BORROWED
      expect(find.text('SLIP-2026-0001'), findsOneWidget);
      expect(find.text('Trạng thái: Chờ duyệt'), findsOneWidget);
      expect(find.text('Duyệt phiếu'), findsOneWidget);
    },
  );
}
