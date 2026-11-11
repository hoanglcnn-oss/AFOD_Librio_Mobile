import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowings/presentation/pages/pending_borrowing_slips_screen.dart';

import 'fake/fake_borrowing_repository.dart';

void main() {
  Widget createApp(FakeBorrowingRepository repository) {
    return MaterialApp(
      home: Scaffold(body: PendingBorrowingSlipsScreen(repository: repository)),
    );
  }

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
}
