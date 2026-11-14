import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowing/return_slip/bloc/return_slip_bloc.dart';
import 'package:week34_project/features/borrowing/return_slip/bloc/return_slip_event.dart';
import 'package:week34_project/features/borrowing/return_slip/bloc/return_slip_state.dart';
import 'package:week34_project/features/borrowing/return_slip/models/return_slip_items_request.dart';

import 'fake/fake_borrowing_repository.dart';

void main() {
  const request = ReturnSlipItemsRequest(
    items: [
      ReturnSlipItemRequest(itemId: 'item-A'),
      ReturnSlipItemRequest(itemId: 'item-B'),
    ],
    isPaidNow: false,
  );

  // Event | Điều kiện đầu vào | Kết quả được kiểm chứng
  test(
    'ReturnSlipRequested | Trả A và B thành công | Submitting -> Success, PARTIAL_RETURNED',
    () async {
      final repository = FakeBorrowingRepository();
      final bloc = ReturnSlipBloc(repository: repository);

      final statesFuture = bloc.stream.take(2).toList();

      bloc.add(const ReturnSlipRequested(slipId: 'slip-01', request: request));

      final states = await statesFuture;

      expect(states[0], isA<ReturnSlipSubmitting>());
      expect(states[1], isA<ReturnSlipSuccess>());

      final success = states[1] as ReturnSlipSuccess;

      expect(success.slip.status, 'PARTIAL_RETURNED');
      expect(repository.returnSlipCallCount, 1);
      expect(repository.lastReturnSlipRequest!.items.length, 2);
      expect(repository.lastReturnSlipRequest!.isPaidNow, false);

      await bloc.close();
    },
  );

  test(
    'ReturnSlipRequested | Backend HTTP 400 | Failure, không phát Success',
    () async {
      final repository = FakeBorrowingRepository();

      final options = RequestOptions(
        path: '/borrowing-slips/slip-01/return-items',
      );

      repository.returnSlipError = DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: 400,
          data: {'message': 'Sách "Sách A" đã được hoàn tất trước đó'},
        ),
      );

      final bloc = ReturnSlipBloc(repository: repository);
      final statesFuture = bloc.stream.take(2).toList();

      bloc.add(const ReturnSlipRequested(slipId: 'slip-01', request: request));

      final states = await statesFuture;

      expect(states[0], isA<ReturnSlipSubmitting>());
      expect(states[1], isA<ReturnSlipFailure>());
      expect(
        (states[1] as ReturnSlipFailure).message,
        contains('đã được hoàn tất'),
      );
      expect(bloc.state, isNot(isA<ReturnSlipSuccess>()));

      await bloc.close();
    },
  );
}
