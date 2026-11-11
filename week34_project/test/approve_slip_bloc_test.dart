import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowings/bloc/approve_slip_bloc.dart';
import 'package:week34_project/features/borrowings/bloc/approve_slip_event.dart';
import 'package:week34_project/features/borrowings/bloc/approve_slip_state.dart';

import 'fake/fake_borrowing_repository.dart';

void main() {
  test(
    'ApproveSlipRequested | Phiếu PENDING_APPROVAL | Submitting -> Success BORROWED',
    () async {
      final repository = FakeBorrowingRepository();
      final bloc = ApproveSlipBloc(repository: repository);

      final statesFuture = bloc.stream.take(2).toList();

      bloc.add(const ApproveSlipRequested('slip-01'));

      final states = await statesFuture;

      expect(states[0], isA<ApproveSlipSubmitting>());
      expect(states[1], isA<ApproveSlipSuccess>());

      final slip = (states[1] as ApproveSlipSuccess).slip;

      expect(slip.status, 'BORROWED');
      expect(slip.items.first.status, 'BORROWING');
      expect(repository.approveSlipCallCount, 1);
      expect(repository.rejectSlipCallCount, 0);

      await bloc.close();
    },
  );

  test(
    'RejectSlipRequested | Có lý do | Submitting -> Success REJECTED',
    () async {
      final repository = FakeBorrowingRepository();
      final bloc = ApproveSlipBloc(repository: repository);

      final statesFuture = bloc.stream.take(2).toList();

      bloc.add(
        const RejectSlipRequested(
          slipId: 'slip-01',
          reason: '  Sách đang kiểm kê  ',
        ),
      );

      final states = await statesFuture;

      expect(states[0], isA<ApproveSlipSubmitting>());
      expect(states[1], isA<ApproveSlipSuccess>());

      final slip = (states[1] as ApproveSlipSuccess).slip;

      expect(slip.status, 'REJECTED');
      expect(repository.rejectSlipCallCount, 1);
      expect(repository.lastRejectionReason, 'Sách đang kiểm kê');
      expect(repository.approveSlipCallCount, 0);

      await bloc.close();
    },
  );

  test(
    'ApproveSlipRequested | HTTP 409 đã xử lý | Failure và yêu cầu refresh',
    () async {
      final repository = FakeBorrowingRepository();

      final options = RequestOptions(path: '/borrowing-slips/slip-01/approve');

      repository.approveSlipError = DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: 409,
          data: {
            'statusCode': 409,
            'message':
                'DOCUMENT_ALREADY_PROCESSED: '
                'Phiếu mượn đã được xử lý trước đó',
          },
        ),
      );

      final bloc = ApproveSlipBloc(repository: repository);
      final statesFuture = bloc.stream.take(2).toList();

      bloc.add(const ApproveSlipRequested('slip-01'));

      final states = await statesFuture;

      expect(states[0], isA<ApproveSlipSubmitting>());
      expect(states[1], isA<ApproveSlipFailure>());

      final failure = states[1] as ApproveSlipFailure;

      expect(failure.message, contains('DOCUMENT_ALREADY_PROCESSED'));
      expect(failure.requiresRefresh, true);
      expect(bloc.state, isNot(isA<ApproveSlipSuccess>()));
      expect(repository.approveSlipCallCount, 1);

      await bloc.close();
    },
  );

  test(
    'ApproveSlipRequested | Mất kết nối | Không xác nhận Success, yêu cầu refresh',
    () async {
      final repository = FakeBorrowingRepository();

      repository.approveSlipError = DioException(
        requestOptions: RequestOptions(
          path: '/borrowing-slips/slip-01/approve',
        ),
        type: DioExceptionType.connectionError,
        message: 'Connection lost',
      );

      final bloc = ApproveSlipBloc(repository: repository);
      final statesFuture = bloc.stream.take(2).toList();

      bloc.add(const ApproveSlipRequested('slip-01'));

      final states = await statesFuture;

      expect(states[0], isA<ApproveSlipSubmitting>());
      expect(states[1], isA<ApproveSlipFailure>());

      final failure = states[1] as ApproveSlipFailure;

      expect(failure.requiresRefresh, true);
      expect(failure.message, contains('Chưa xác nhận được kết quả'));

      await bloc.close();
    },
  );
}
