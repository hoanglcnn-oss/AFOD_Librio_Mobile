import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowings/data/models/paginated_borrowings.dart';
import 'package:week34_project/features/borrowings/presentation/pages/librarian_manage_screen.dart';
import 'package:week34_project/features/borrowings/presentation/pages/manage_single_borrowings_screen.dart';

import 'fake/fake_borrowing_repository.dart';

void main() {
  Widget createApp(Widget home) {
    return MaterialApp(home: Scaffold(body: home));
  }

  testWidgets(
    'ManageSingleBorrowingsScreen | Mặc định | Hiển thị danh sách mượn lẻ, độc giả và filter Tất cả',
    (tester) async {
      final repository = FakeBorrowingRepository();

      await tester.pumpWidget(
        createApp(ManageSingleBorrowingsScreen(repository: repository)),
      );
      await tester.pumpAndSettle();

      expect(find.text('BRW-2026-0001'), findsOneWidget);
      expect(find.text('Clean Code'), findsOneWidget);
      expect(find.text('Độc giả'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Đang mượn'), findsWidgets);
      expect(repository.getAllBorrowingsCallCount, 1);
      expect(repository.lastGetAllBorrowingsStatus, isNull);
    },
  );

  testWidgets(
    'ManageSingleBorrowingsScreen | Chọn filter Đang mượn | Gọi getAllBorrowings với status BORROWED',
    (tester) async {
      final repository = FakeBorrowingRepository();

      await tester.pumpWidget(
        createApp(ManageSingleBorrowingsScreen(repository: repository)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Đang mượn'));
      await tester.pumpAndSettle();

      expect(repository.getAllBorrowingsCallCount, 2);
      expect(repository.lastGetAllBorrowingsStatus, 'BORROWED');
      expect(repository.lastGetAllBorrowingsPage, 1);
    },
  );

  testWidgets(
    'ManageSingleBorrowingsScreen | Sách đang mượn | Hiển thị nút Trả sách và gọi returnBook khi xác nhận',
    (tester) async {
      final repository = FakeBorrowingRepository();

      await tester.pumpWidget(
        createApp(ManageSingleBorrowingsScreen(repository: repository)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trả sách'), findsOneWidget);

      await tester.tap(find.text('Trả sách'));
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận trả sách'), findsOneWidget);
      expect(repository.returnCallCount, 0);

      await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
      await tester.pumpAndSettle();

      expect(repository.returnCallCount, 1);
      expect(repository.lastReturnFinePaid, false);
      expect(find.text('Đã ghi nhận trả sách thành công'), findsOneWidget);
    },
  );

  testWidgets(
    'ManageSingleBorrowingsScreen | Danh sách rỗng | Hiển thị thông báo không có lượt mượn',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.fakeAllBorrowingsPage = const BorrowingsPage(
        borrowings: [],
        page: 1,
        limit: 10,
        totalItems: 0,
        totalPages: 1,
        hasNextPage: false,
      );

      await tester.pumpWidget(
        createApp(ManageSingleBorrowingsScreen(repository: repository)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không có lượt mượn nào'), findsOneWidget);
    },
  );

  testWidgets(
    'ManageSingleBorrowingsScreen | Tải danh sách lỗi | Hiển thị nút Thử lại và tải lại',
    (tester) async {
      final repository = FakeBorrowingRepository();
      repository.shouldFailGetAllBorrowings = true;

      await tester.pumpWidget(
        createApp(ManageSingleBorrowingsScreen(repository: repository)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không thể tải danh sách mượn sách'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      repository.shouldFailGetAllBorrowings = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.text('BRW-2026-0001'), findsOneWidget);
    },
  );

  testWidgets(
    'LibrarianManageScreen | Mặc định | Hiển thị 2 sub-tab Mượn lẻ và Phiếu nhiều sách',
    (tester) async {
      final repository = FakeBorrowingRepository();

      await tester.pumpWidget(
        createApp(LibrarianManageScreen(repository: repository)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mượn lẻ'), findsOneWidget);
      expect(find.text('Phiếu nhiều sách'), findsOneWidget);
      expect(find.text('BRW-2026-0001'), findsOneWidget);

      // Chuyển sang sub-tab "Phiếu nhiều sách"
      await tester.tap(find.text('Phiếu nhiều sách'));
      await tester.pumpAndSettle();

      expect(find.text('SLIP-2026-0001'), findsOneWidget);
    },
  );
}
