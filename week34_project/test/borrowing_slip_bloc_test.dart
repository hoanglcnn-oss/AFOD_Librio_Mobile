import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowings/bloc/borrowing_slip_bloc.dart';
import 'package:week34_project/features/borrowings/bloc/borrowing_slip_event.dart';
import 'package:week34_project/features/borrowings/bloc/borrowing_slip_state.dart';
import 'package:week34_project/features/borrowings/data/models/create_borrowing_slip_request.dart';

import 'fake/fake_borrowing_repository.dart';

void main() {
  const request = CreateBorrowingSlipRequest(
    memberId: 'mem-01',
    items: [
      BorrowingSlipItemRequest(bookId: 'book-01', quantity: 1),
      BorrowingSlipItemRequest(bookId: 'book-02', quantity: 2),
    ],
  );

  group('BorrowingSlipBloc', () {
    test(
      'CreateSlipRequested | Repository thành công | Submitting -> Success, trạng thái PENDING_APPROVAL',
      () async {
        final repository = FakeBorrowingRepository();
        final bloc = BorrowingSlipBloc(borrowingRepository: repository);

        final statesFuture = bloc.stream.take(2).toList();

        bloc.add(const CreateSlipRequested(request));

        final states = await statesFuture;

        expect(states[0], isA<BorrowingSlipSubmitting>());
        expect(states[1], isA<BorrowingSlipSuccess>());

        final success = states[1] as BorrowingSlipSuccess;

        expect(success.slip.memberId, 'mem-01');
        expect(success.slip.status, 'PENDING_APPROVAL');
        expect(success.slip.items.length, 2);
        expect(repository.createSlipCallCount, 1);

        await bloc.close();
      },
    );

    test(
      'CreateSlipRequested | Repository lỗi | Submitting -> Failure, có thông báo',
      () async {
        final repository = FakeBorrowingRepository()
          ..shouldFailCreateSlip = true;

        final bloc = BorrowingSlipBloc(borrowingRepository: repository);

        final statesFuture = bloc.stream.take(2).toList();

        bloc.add(const CreateSlipRequested(request));

        final states = await statesFuture;

        expect(states[0], isA<BorrowingSlipSubmitting>());
        expect(states[1], isA<BorrowingSlipFailure>());

        final failure = states[1] as BorrowingSlipFailure;

        expect(failure.message, isNotEmpty);
        expect(repository.createSlipCallCount, 1);

        await bloc.close();
      },
    );

    test(
      'CreateSlipRequested | Đã Success | bỏ qua event tiếp theo, không gọi lại Repository',
      () async {
        final repository = FakeBorrowingRepository();
        final bloc = BorrowingSlipBloc(borrowingRepository: repository);

        final successFuture = bloc.stream.firstWhere(
          (state) => state is BorrowingSlipSuccess,
        );

        bloc.add(const CreateSlipRequested(request));

        await successFuture;

        expect(repository.createSlipCallCount, 1);

        bloc.add(const CreateSlipRequested(request));

        // Cho BLoC xử lý event thứ hai.
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state, isA<BorrowingSlipSuccess>());
        expect(repository.createSlipCallCount, 1);

        await bloc.close();
      },
    );
  });
}
