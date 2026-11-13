import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/renewal/models/renewal_eligibility.dart';
import 'package:week34_project/features/borrowings/bloc/my_borrowings_bloc.dart';
import 'package:week34_project/features/borrowings/bloc/my_borrowings_event.dart';
import 'package:week34_project/features/borrowings/bloc/my_borrowings_state.dart';
import 'package:week34_project/features/borrowings/data/models/borrowing.dart';
import 'package:week34_project/features/borrowings/presentation/pages/my_borrowings_screen.dart';
import 'package:week34_project/features/borrowings/presentation/widgets/borrowing_card.dart';

import 'fake/fake_borrowing_repository.dart';

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

  group('BorrowingCard Component', () {
    testWidgets(
      'onReturn và onRenew null (MEMBER) | Không hiển thị nút Trả sách hoặc Gia hạn',
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
        expect(find.text('Kiểm tra gia hạn'), findsNothing);
      },
    );

    testWidgets(
      'onReturn có giá trị (LIBRARIAN) | Hiển thị nút Trả sách',
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
  });

  group('MyBorrowingsScreen Integration', () {
    testWidgets(
      'Hiển thị danh sách và mở dialog gia hạn khi bấm nút',
      (tester) async {
        final repository = FakeBorrowingRepository();
        final bloc = MyBorrowingsBloc(borrowingRepository: repository);

        bloc.add(const LoadMyBorrowings('mem-01'));
        await bloc.stream.firstWhere((s) => s is MyBorrowingsLoaded);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<MyBorrowingsBloc>.value(
              value: bloc,
              child: Scaffold(
                body: MyBorrowingsScreen(
                  memberId: 'mem-01',
                  allowActions: true,
                  onReturnSucceeded: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Clean Code'), findsOneWidget);
        expect(find.text('Kiểm tra gia hạn'), findsOneWidget);

        // Bấm nút mở dialog gia hạn
        await tester.tap(find.text('Kiểm tra gia hạn'));
        await tester.pumpAndSettle();

        expect(find.text('Gia hạn mượn sách'), findsOneWidget);
        expect(find.text('Chọn số ngày muốn gia hạn:'), findsOneWidget);
        expect(find.textContaining('tối đa 2 lần'), findsNothing);

        // Xác nhận gia hạn
        await tester.tap(find.text('Xác nhận'));
        await tester.pumpAndSettle();

        // Kiểm tra AppToast thành công hiển thị
        expect(find.text('Gia hạn sách thành công'), findsOneWidget);
      },
    );

    testWidgets(
      'Khi Backend từ chối gia hạn | Hiển thị AppToast lỗi và cập nhật thẻ với lý do',
      (tester) async {
        final repository = FakeBorrowingRepository();
        repository.fakeBorrowingDetail = Borrowing(
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
          renewalEligibility: const RenewalEligibility(
            canRenew: false,
            reasonCode: 'ACTIVE_RESERVATION',
            message: 'Sách đang có người đặt trước, không thể gia hạn.',
          ),
        );

        final bloc = MyBorrowingsBloc(borrowingRepository: repository);

        bloc.add(const LoadMyBorrowings('mem-01'));
        await bloc.stream.firstWhere((s) => s is MyBorrowingsLoaded);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<MyBorrowingsBloc>.value(
              value: bloc,
              child: Scaffold(
                body: MyBorrowingsScreen(
                  memberId: 'mem-01',
                  allowActions: true,
                  onReturnSucceeded: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Kiểm tra gia hạn'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Xác nhận'));
        await tester.pumpAndSettle();

        // AppToast báo lỗi từ chối
        expect(
          find.text('Sách đang có người đặt trước, không thể gia hạn.'),
          findsAtLeastNWidgets(1),
        );
      },
    );
  });
}
