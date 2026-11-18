import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowing/librarian_desk/presentation/pages/librarian_desk_screen.dart';
import 'package:week34_project/features/borrowing/shared/models/paginated_borrowing_slips.dart';

import 'fake/fake_borrowing_repository.dart';

void main() {
  Widget createApp(
    FakeBorrowingRepository repository, {
    VoidCallback? onNavigateToSlipsTab,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: LibrarianDeskScreen(
          repository: repository,
          onNavigateToSlipsTab: onNavigateToSlipsTab,
        ),
      ),
    );
  }

  group('LibrarianDeskScreen Tests', () {
    testWidgets(
      'Hiển thị đầy đủ thông tin ca trực và 4 thao tác nhanh tại quầy',
      (tester) async {
        final repository = FakeBorrowingRepository();

        await tester.pumpWidget(createApp(repository));
        await tester.pumpAndSettle();

        expect(find.text('THAO TÁC NHANH TẠI QUẦY'), findsOneWidget);
        expect(find.text('Quét Barcode / QR'), findsOneWidget);
        expect(find.text('Tra cứu bạn đọc'), findsOneWidget);
        expect(find.text('Tạo phiếu tại quầy'), findsOneWidget);
        expect(find.text('Quản lý mượn trả'), findsOneWidget);
        expect(find.text('Phiếu mượn cần duyệt'), findsOneWidget);
      },
    );

    testWidgets(
      'Nhấn Quản lý mượn trả kích hoạt callback onNavigateToSlipsTab',
      (tester) async {
        final repository = FakeBorrowingRepository();
        var didNavigate = false;

        await tester.pumpWidget(
          createApp(repository, onNavigateToSlipsTab: () => didNavigate = true),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Quản lý mượn trả'));
        await tester.pumpAndSettle();

        expect(didNavigate, isTrue);
      },
    );

    testWidgets(
      'Nhấn Tra cứu bạn đọc hiển thị dialog nhập mã độc giả',
      (tester) async {
        final repository = FakeBorrowingRepository();

        await tester.pumpWidget(createApp(repository));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Tra cứu bạn đọc'));
        await tester.pumpAndSettle();

        expect(find.text('Tra cứu bạn đọc'), findsNWidgets(2)); // Card + Dialog title
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Tra cứu'), findsOneWidget);
      },
    );

    testWidgets(
      'Có phiếu chờ duyệt | Hiển thị phiếu và danh sách',
      (tester) async {
        final repository = FakeBorrowingRepository();

        await tester.pumpWidget(createApp(repository));
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        final slipFinder = find.text('SLIP-2026-0001');
        expect(slipFinder, findsOneWidget);

        final approveFinder = find.text('Duyệt phiếu');
        expect(approveFinder, findsOneWidget);
        expect(find.text('Từ chối'), findsOneWidget);

        await tester.tap(approveFinder);
        await tester.pumpAndSettle();

        expect(find.text('Xác nhận duyệt phiếu'), findsOneWidget);
      },
    );

    testWidgets(
      'Danh sách rỗng | Hiển thị empty state thân thiện',
      (tester) async {
        final repository = FakeBorrowingRepository();
        repository.fakePendingSlipsPage = const PaginatedBorrowingSlips(
          slips: [],
          page: 1,
          limit: 10,
          totalItems: 0,
          totalPages: 1,
          hasNextPage: false,
        );

        await tester.pumpWidget(createApp(repository));
        await tester.pumpAndSettle();

        expect(find.text('Không có phiếu chờ duyệt'), findsOneWidget);
        expect(
          find.text('Tất cả yêu cầu mượn sách đã được xử lý xong'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Màn hình Tablet (width >= 900) | Hiển thị 2 cột: Phiếu cần duyệt và Thao tác nhanh',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repository = FakeBorrowingRepository();

        await tester.pumpWidget(createApp(repository));
        await tester.pumpAndSettle();

        expect(find.text('Phiếu mượn cần duyệt'), findsOneWidget);
        expect(find.text('THAO TÁC NHANH TẠI QUẦY'), findsOneWidget);
        expect(find.text('SLIP-2026-0001'), findsOneWidget);
        expect(find.text('Quét Barcode / QR'), findsOneWidget);
      },
    );
  });
}
