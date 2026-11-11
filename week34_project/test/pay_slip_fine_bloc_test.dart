import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowings/bloc/pay_slip_fine_bloc.dart';
import 'package:week34_project/features/borrowings/bloc/pay_slip_fine_event.dart';
import 'package:week34_project/features/borrowings/bloc/pay_slip_fine_state.dart';

import 'fake/fake_borrowing_repository.dart';

void main() {
  // Event | Điều kiện đầu vào | Kết quả được kiểm chứng
  test(
    'PaySlipFineRequested | Backend ghi nhận thành công | Submitting -> Success, finePaid true',
    () async {
      final repository = FakeBorrowingRepository();
      final bloc = PaySlipFineBloc(repository: repository);

      final statesFuture = bloc.stream.take(2).toList();

      bloc.add(const PaySlipFineRequested('slip-01'));

      final states = await statesFuture;

      expect(states[0], isA<PaySlipFineSubmitting>());
      expect(states[1], isA<PaySlipFineSuccess>());

      final slip = (states[1] as PaySlipFineSuccess).slip;

      expect(slip.status, 'COMPLETED');
      expect(slip.totalFine, 25000);
      expect(slip.finePaid, true);
      expect(slip.finePaidAt, isNotNull);
      expect(repository.paySlipFineCallCount, 1);

      await bloc.close();
    },
  );

  test(
    'PaySlipFineRequested | HTTP 400 đã thanh toán | Failure, không phát Success',
    () async {
      final repository = FakeBorrowingRepository();

      final options = RequestOptions(path: '/borrowing-slips/slip-01/pay-fine');

      repository.paySlipFineError = DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: 400,
          data: {
            'message':
                'Tiền phạt của phiếu mượn này '
                'đã được thanh toán trước đó',
          },
        ),
      );

      final bloc = PaySlipFineBloc(repository: repository);
      final statesFuture = bloc.stream.take(2).toList();

      bloc.add(const PaySlipFineRequested('slip-01'));

      final states = await statesFuture;

      expect(states[0], isA<PaySlipFineSubmitting>());
      expect(states[1], isA<PaySlipFineFailure>());

      final failure = states[1] as PaySlipFineFailure;

      expect(failure.message, contains('đã được thanh toán'));
      expect(bloc.state, isNot(isA<PaySlipFineSuccess>()));
      expect(repository.paySlipFineCallCount, 1);

      await bloc.close();
    },
  );
}
