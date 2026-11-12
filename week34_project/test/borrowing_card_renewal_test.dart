import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/core/models/renewal_eligibility.dart';
import 'package:week34_project/features/borrowings/data/models/borrowing.dart';
import 'package:week34_project/features/borrowings/presentation/widgets/borrowing_card.dart';

void main() {
  group('BorrowingCard Renewal UI', () {
    final baseBorrowing = Borrowing(
      id: 'brw-01',
      transactionCode: 'BRW-2026-0001',
      memberId: 'mem-01',
      memberName: 'Nguyễn Văn An',
      bookId: 'book-01',
      bookTitle: 'Clean Code',
      borrowDate: DateTime.utc(2026, 10, 29),
      dueDate: DateTime.utc(2026, 11, 12),
      status: 'BORROWED',
      renewCount: 1,
    );

    testWidgets(
      'canRenew == null (chưa tải) | Hiển thị "Kiểm tra gia hạn", không hardcode /2',
      (tester) async {
        bool renewTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BorrowingCard(
                borrowing: baseBorrowing, // renewalEligibility is null
                onRenew: () => renewTapped = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Kiểm tra gia hạn'), findsOneWidget);
        expect(find.text('Đã gia hạn: 1 lần'), findsOneWidget);
        expect(find.textContaining('/2 lần'), findsNothing);

        await tester.tap(find.text('Kiểm tra gia hạn'));
        await tester.pumpAndSettle();
        expect(renewTapped, isTrue);
      },
    );

    testWidgets(
      'canRenew == true (được gia hạn) | Hiển thị nút "Gia hạn", enabled',
      (tester) async {
        bool renewTapped = false;
        final eligibleBorrowing = baseBorrowing.copyWith(
          renewalEligibility: const RenewalEligibility(canRenew: true),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BorrowingCard(
                borrowing: eligibleBorrowing,
                onRenew: () => renewTapped = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Gia hạn'), findsOneWidget);
        final button = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Gia hạn'),
        );
        expect(button.onPressed, isNotNull);

        await tester.tap(find.text('Gia hạn'));
        await tester.pumpAndSettle();
        expect(renewTapped, isTrue);
      },
    );

    testWidgets(
      'canRenew == false (bị từ chối) | Khóa nút và hiển thị lý do từ chối',
      (tester) async {
        final rejectedBorrowing = baseBorrowing.copyWith(
          renewalEligibility: const RenewalEligibility(
            canRenew: false,
            reasonCode: 'ACTIVE_RESERVATION',
            message: 'Sách đang có người đặt trước, không thể gia hạn.',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BorrowingCard(
                borrowing: rejectedBorrowing,
                onRenew: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Sách đang có người đặt trước, không thể gia hạn.'),
          findsOneWidget,
        );
        final button = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Gia hạn'),
        );
        expect(button.onPressed, isNull); // Nút bị khóa
      },
    );

    testWidgets(
      'canRenew == false với reasonCode fallback | Hiển thị đúng thông báo mapped',
      (tester) async {
        final rejectedBorrowing = baseBorrowing.copyWith(
          renewalEligibility: const RenewalEligibility(
            canRenew: false,
            reasonCode: 'MAX_RENEWALS_REACHED',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BorrowingCard(
                borrowing: rejectedBorrowing,
                onRenew: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Đã đạt giới hạn số lần gia hạn cho phép.'),
          findsOneWidget,
        );
        final button = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Gia hạn'),
        );
        expect(button.onPressed, isNull);
      },
    );

    testWidgets(
      'isRenewing == true | Hiển thị loading và "Đang gia hạn...", nút bị khóa',
      (tester) async {
        final eligibleBorrowing = baseBorrowing.copyWith(
          renewalEligibility: const RenewalEligibility(canRenew: true),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BorrowingCard(
                borrowing: eligibleBorrowing,
                isRenewing: true,
                isBusy: true,
                onRenew: () {},
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Đang gia hạn...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        final button = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Đang gia hạn...'),
        );
        expect(button.onPressed, isNull);
      },
    );

    testWidgets(
      'status == RETURNED | Không hiển thị nút gia hạn',
      (tester) async {
        final returnedBorrowing = baseBorrowing.copyWith(
          status: 'RETURNED',
          renewalEligibility: const RenewalEligibility(canRenew: true),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BorrowingCard(
                borrowing: returnedBorrowing,
                onRenew: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Gia hạn'), findsNothing);
        expect(find.text('Kiểm tra gia hạn'), findsNothing);
      },
    );
  });
}
