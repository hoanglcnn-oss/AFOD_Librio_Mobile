import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowings/data/models/borrowing.dart';
import 'package:week34_project/features/borrowings/presentation/widgets/borrowing_card.dart';

void main() {
  final borrowing = Borrowing(
    id: 'brw-01',
    transactionCode: 'BRW-2026-0001',
    memberId: 'mem-01',
    memberName: 'Nguyễn Văn An',
    bookId: 'book-01',
    bookTitle: 'Clean Code',
    borrowDate: DateTime.utc(2026, 10, 29),
    dueDate: DateTime.utc(2026, 11, 29),
    status: 'BORROWED',
  );

  testWidgets(
    'BorrowingCard | onReturn và onRenew null (MEMBER) | Không hiển thị nút Trả sách hoặc Gia hạn',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BorrowingCard(
              borrowing: borrowing,
              onReturn: null,
              onRenew: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clean Code'), findsOneWidget);
      expect(find.text('BRW-2026-0001'), findsOneWidget);
      expect(find.text('Trả sách'), findsNothing);
      expect(find.text('Gia hạn'), findsNothing);
    },
  );

  testWidgets(
    'BorrowingCard | onReturn có giá trị (LIBRARIAN) | Hiển thị nút Trả sách',
    (tester) async {
      bool returnTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BorrowingCard(
              borrowing: borrowing,
              onReturn: () => returnTapped = true,
              onRenew: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trả sách'), findsOneWidget);
      await tester.tap(find.text('Trả sách'));
      await tester.pumpAndSettle();

      expect(returnTapped, true);
    },
  );
}
