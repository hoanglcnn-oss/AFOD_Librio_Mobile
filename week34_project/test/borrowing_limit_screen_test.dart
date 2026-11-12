import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/members/data/models/member_debt_summary.dart';
import 'package:week34_project/features/members/presentation/pages/borrowing_limit_screen.dart';

import 'fake/fake_members_repository.dart';

void main() {
  Widget createApp({
    required FakeMembersRepository repository,
    String memberId = 'mem-01',
  }) {
    return MaterialApp(
      home: BorrowingLimitScreen(
        memberId: memberId,
        membersRepository: repository,
      ),
    );
  }

  group('BorrowingLimitScreen', () {
    testWidgets(
      'Tải thành công | Hiển thị đầy đủ thông tin hạn mức và điều kiện',
      (tester) async {
        final repository = FakeMembersRepository(
          fakeDebtSummary: const MemberDebtSummary(
            maxBorrowLimit: 5,
            currentBorrowedCount: 3,
            remainingBorrowLimit: 2,
            canBorrow: true,
            overdueCount: 0,
            unpaidFineAmount: 0,
          ),
        );

        await tester.pumpWidget(createApp(repository: repository));
        await tester.pumpAndSettle();

        expect(find.text('Hạn mức mượn sách'), findsOneWidget);
        expect(find.text('3/5 cuốn'), findsOneWidget);
        expect(find.text('Được mượn thêm'), findsOneWidget);
        expect(find.text('2 cuốn'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
        expect(find.text('0 VNĐ'), findsOneWidget);
      },
    );

    testWidgets('Không đủ điều kiện mượn | Hiển thị cảnh báo và lý do', (
      tester,
    ) async {
      final repository = FakeMembersRepository(
        fakeDebtSummary: const MemberDebtSummary(
          maxBorrowLimit: 5,
          currentBorrowedCount: 5,
          remainingBorrowLimit: 0,
          canBorrow: false,
          reasonIfNotAllowed: 'Đã đạt giới hạn mượn sách tối đa',
          overdueCount: 1,
          unpaidFineAmount: 50000,
        ),
      );

      await tester.pumpWidget(createApp(repository: repository));
      await tester.pumpAndSettle();

      expect(find.text('5/5 cuốn'), findsOneWidget);
      expect(find.text('Đã đạt giới hạn mượn sách tối đa'), findsWidgets);
      expect(find.text('0 cuốn'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('50.000 VNĐ'), findsOneWidget);
    });

    testWidgets('Tải dữ liệu lỗi | Hiển thị nút Thử lại và tải lại khi bấm', (
      tester,
    ) async {
      final repository = FakeMembersRepository(shouldFailDebtSummary: true);

      await tester.pumpWidget(createApp(repository: repository));
      await tester.pumpAndSettle();

      expect(
        find.text('Không thể tải thông tin hạn mức mượn sách'),
        findsOneWidget,
      );
      expect(find.text('Thử lại'), findsOneWidget);

      // Sửa lỗi và bấm Thử lại
      repository.shouldFailDebtSummary = false;
      repository.fakeDebtSummary = const MemberDebtSummary(
        maxBorrowLimit: 5,
        currentBorrowedCount: 1,
        remainingBorrowLimit: 4,
        canBorrow: true,
        overdueCount: 0,
        unpaidFineAmount: 0,
      );

      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.text('1/5 cuốn'), findsOneWidget);
      expect(find.text('4 cuốn'), findsOneWidget);
    });
  });
}
