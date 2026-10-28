import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowings/bloc/borrowing_bloc.dart';
import 'package:week34_project/features/borrowings/bloc/borrowing_event.dart';
import 'package:week34_project/features/borrowings/bloc/borrowing_state.dart';
import 'package:week34_project/features/borrowings/data/models/create_borrowing_request.dart';

import 'fake/fake_borrowing_repository.dart';

void main() {
  const request = CreateBorrowingRequest(memberId: 'mem-01', bookId: 'book-01');

  test('Borrow thành công: Submitting → Success', () async {
    final bloc = BorrowingBloc(borrowingRepository: FakeBorrowingRepository());

    final statesFuture = bloc.stream.take(2).toList();

    bloc.add(const BorrowBookRequested(request));

    final states = await statesFuture;

    expect(states[0], isA<BorrowingSubmitting>());
    expect(states[1], isA<BorrowingSuccess>());

    final success = states[1] as BorrowingSuccess;

    expect(success.borrowing.memberId, 'mem-01');
    expect(success.borrowing.bookId, 'book-01');
    expect(success.borrowing.status, 'BORROWED');

    await bloc.close();
  });

  test('Borrow thất bại: Submitting → Failure', () async {
    final bloc = BorrowingBloc(
      borrowingRepository: FakeBorrowingRepository(shouldFail: true),
    );

    final statesFuture = bloc.stream.take(2).toList();

    bloc.add(const BorrowBookRequested(request));

    final states = await statesFuture;

    expect(states[0], isA<BorrowingSubmitting>());
    expect(states[1], isA<BorrowingFailure>());

    final failure = states[1] as BorrowingFailure;

    expect(failure.message, isNotEmpty);

    await bloc.close();
  });

  test('Không tạo lại phiếu khi đã Success', () async {
    final bloc = BorrowingBloc(borrowingRepository: FakeBorrowingRepository());

    final successFuture = bloc.stream.firstWhere(
      (state) => state is BorrowingSuccess,
    );

    bloc.add(const BorrowBookRequested(request));

    await successFuture;

    // Gửi event lần hai sau khi đã thành công.
    bloc.add(const BorrowBookRequested(request));

    expect(bloc.state, isA<BorrowingSuccess>());

    await bloc.close();
  });
}
