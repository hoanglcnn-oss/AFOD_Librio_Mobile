import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/borrowing/renewal/bloc/renew_slip_bloc.dart';
import 'package:week34_project/features/borrowing/renewal/bloc/renew_slip_event.dart';
import 'package:week34_project/features/borrowing/renewal/bloc/renew_slip_state.dart';
import 'package:week34_project/features/borrowing/shared/models/borrowing_slip.dart';
import 'package:week34_project/features/borrowing/renewal/models/renewal_eligibility.dart';

import 'fake/fake_borrowing_repository.dart';

void main() {
  group('RenewSlipBloc', () {
    test(
      'canRenew = true | Lấy eligibility mới nhất -> gọi renewSlip -> RenewSlipSuccess',
      () async {
        final repository = FakeBorrowingRepository();
        final initialSlip = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'mem-01',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          renewalEligibility: const RenewalEligibility(canRenew: true),
          items: const [],
        );
        repository.fakeSlipDetail = initialSlip;

        final bloc = RenewSlipBloc(repository: repository);
        final states = <RenewSlipState>[];
        final subscription = bloc.stream.listen(states.add);

        bloc.add(const RenewSlipRequested('slip-01', extraDays: 7));

        await bloc.stream.firstWhere((s) => s is RenewSlipSuccess);

        expect(states[0], isA<RenewSlipSubmitting>());
        expect(states[1], isA<RenewSlipSuccess>());

        final success = states[1] as RenewSlipSuccess;
        expect(success.slip.renewCount, 1);
        expect(success.slip.dueDate.isAfter(initialSlip.dueDate), true);
        expect(repository.renewSlipCallCount, 1);
        expect(repository.lastRenewSlipExtraDays, 7);

        await subscription.cancel();
        await bloc.close();
      },
    );

    test(
      'canRenew = false (ACTIVE_RESERVATION) | getBorrowingSlipById gọi -> RenewSlipFailure, KHÔNG gọi renewSlip',
      () async {
        final repository = FakeBorrowingRepository();
        repository.fakeSlipDetail = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'mem-01',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          renewalEligibility: const RenewalEligibility(
            canRenew: false,
            reasonCode: 'ACTIVE_RESERVATION',
            message: 'Sách đang có người đặt trước, không thể gia hạn.',
          ),
          items: const [],
        );

        final bloc = RenewSlipBloc(repository: repository);
        final states = <RenewSlipState>[];
        final subscription = bloc.stream.listen(states.add);

        bloc.add(const RenewSlipRequested('slip-01'));

        await bloc.stream.firstWhere((s) => s is RenewSlipFailure);

        expect(states[0], isA<RenewSlipSubmitting>());
        expect(states[1], isA<RenewSlipFailure>());

        final failure = states[1] as RenewSlipFailure;
        expect(failure.message, contains('Sách đang có người đặt trước'));
        expect(repository.renewSlipCallCount, 0); // KHÔNG gọi PATCH renewSlip

        await subscription.cancel();
        await bloc.close();
      },
    );

    test(
      'canRenew = false (MAX_RENEWALS_REACHED) | RenewSlipFailure, KHÔNG gọi renewSlip',
      () async {
        final repository = FakeBorrowingRepository();
        repository.fakeSlipDetail = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'mem-01',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 2,
          renewalEligibility: const RenewalEligibility(
            canRenew: false,
            reasonCode: 'MAX_RENEWALS_REACHED',
          ),
          items: const [],
        );

        final bloc = RenewSlipBloc(repository: repository);

        bloc.add(const RenewSlipRequested('slip-01'));

        await bloc.stream.firstWhere((s) => s is RenewSlipFailure);

        expect(repository.renewSlipCallCount, 0);
        final failure = bloc.state as RenewSlipFailure;
        expect(failure.message, 'Đã đạt giới hạn số lần gia hạn cho phép.');

        await bloc.close();
      },
    );

    test(
      'canRenew == null | Không gọi renewSlip, emit RenewSlipFailure thông báo chưa xác định',
      () async {
        final repository = FakeBorrowingRepository();
        repository.fakeSlipDetail = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'mem-01',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          renewalEligibility: null, // Chưa có eligibility
          items: const [],
        );

        final bloc = RenewSlipBloc(repository: repository);

        bloc.add(const RenewSlipRequested('slip-01'));

        await bloc.stream.firstWhere((s) => s is RenewSlipFailure);

        final failure = bloc.state as RenewSlipFailure;
        expect(
          failure.message,
          contains('Chưa xác định được điều kiện gia hạn'),
        );
        expect(repository.renewSlipCallCount, 0);

        await bloc.close();
      },
    );

    test(
      'PARTIAL_RETURNED với eligibility hợp lệ | Gọi renewSlip -> RenewSlipSuccess',
      () async {
        final repository = FakeBorrowingRepository();
        repository.fakeSlipDetail = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'mem-01',
          status: 'PARTIAL_RETURNED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          renewalEligibility: const RenewalEligibility(canRenew: true),
          items: const [
            BorrowingSlipItem(
              id: 'it-1',
              bookId: 'b-1',
              bookTitle: 'Book 1',
              quantity: 2,
              returnedQuantity: 1,
              status: 'PARTIAL_RETURNED',
            ),
          ],
        );

        final bloc = RenewSlipBloc(repository: repository);

        bloc.add(const RenewSlipRequested('slip-01', extraDays: 7));

        await bloc.stream.firstWhere((s) => s is RenewSlipSuccess);

        final success = bloc.state as RenewSlipSuccess;
        expect(success.slip.renewCount, 1);
        expect(repository.renewSlipCallCount, 1);

        await bloc.close();
      },
    );

    test(
      'Concurrency guard | Double-click chỉ gửi một request PATCH renewSlip',
      () async {
        final repository = FakeBorrowingRepository();
        final completer = Completer<void>();
        repository.renewSlipCompleter = completer;
        repository.fakeSlipDetail = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'mem-01',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          renewalEligibility: const RenewalEligibility(canRenew: true),
          items: const [],
        );

        final bloc = RenewSlipBloc(repository: repository);

        // Gửi request 1
        bloc.add(const RenewSlipRequested('slip-01'));
        await bloc.stream.firstWhere((s) => s is RenewSlipSubmitting);

        // Gửi request 2 trùng lặp
        bloc.add(const RenewSlipRequested('slip-01'));

        completer.complete();

        await bloc.stream.firstWhere((s) => s is RenewSlipSuccess);

        expect(repository.renewSlipCallCount, 1);

        await bloc.close();
      },
    );

    test(
      'HTTP 409 Conflict | Hiển thị lý do và lấy lại eligibility',
      () async {
        final repository = FakeBorrowingRepository();
        repository.fakeSlipDetail = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'mem-01',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          renewalEligibility: const RenewalEligibility(canRenew: true),
          items: const [],
        );

        repository.renewSlipError = DioException(
          requestOptions: RequestOptions(path: '/borrowing-slips/slip-01/renew'),
          response: Response(
            requestOptions: RequestOptions(
              path: '/borrowing-slips/slip-01/renew',
            ),
            statusCode: 409,
            data: {
              'message': 'Sách trong phiếu vừa có độc giả khác đặt trước',
              'reasonCode': 'ACTIVE_RESERVATION',
            },
          ),
          type: DioExceptionType.badResponse,
        );

        final bloc = RenewSlipBloc(repository: repository);

        bloc.add(const RenewSlipRequested('slip-01'));

        await bloc.stream.firstWhere((s) => s is RenewSlipFailure);

        final failure = bloc.state as RenewSlipFailure;
        expect(
          failure.message,
          'Sách trong phiếu vừa có độc giả khác đặt trước',
        );

        await bloc.close();
      },
    );

    test(
      'Timeout mạng nhưng Backend đã gia hạn | GET lại kiểm tra thấy dueDate/renewCount tăng -> RenewSlipSuccess',
      () async {
        final repository = FakeBorrowingRepository();
        final initialSlip = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'mem-01',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          renewalEligibility: const RenewalEligibility(canRenew: true),
          items: const [],
        );
        repository.fakeSlipDetail = initialSlip;

        final updatedSlip = initialSlip.copyWith(
          renewCount: 1,
          dueDate: DateTime.utc(2026, 11, 22),
        );

        int getSlipCalls = 0;
        repository.fakeSlipDetailBuilder = (slipId) {
          getSlipCalls++;
          if (getSlipCalls == 1) {
            return initialSlip;
          }
          return updatedSlip;
        };

        // Mô phỏng: request PATCH timeout, nhưng backend đã thực thi xong
        repository.renewSlipError = DioException(
          requestOptions: RequestOptions(path: '/borrowing-slips/slip-01/renew'),
          type: DioExceptionType.connectionTimeout,
        );

        final bloc = RenewSlipBloc(repository: repository);

        bloc.add(RenewSlipRequested('slip-01', currentSlip: initialSlip));

        await bloc.stream.firstWhere((s) => s is RenewSlipSuccess);

        final success = bloc.state as RenewSlipSuccess;
        expect(success.slip.renewCount, 1);
        expect(success.slip.dueDate, DateTime.utc(2026, 11, 22));

        await bloc.close();
      },
    );

    test(
      'Timeout mạng và Backend chưa gia hạn (kết quả chưa xác định) | Emit RenewSlipFailure',
      () async {
        final repository = FakeBorrowingRepository();
        final initialSlip = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'mem-01',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          renewalEligibility: const RenewalEligibility(canRenew: true),
          items: const [],
        );
        repository.fakeSlipDetail = initialSlip;

        repository.renewSlipError = DioException(
          requestOptions: RequestOptions(path: '/borrowing-slips/slip-01/renew'),
          type: DioExceptionType.receiveTimeout,
        );

        final bloc = RenewSlipBloc(repository: repository);

        bloc.add(RenewSlipRequested('slip-01', currentSlip: initialSlip));

        await bloc.stream.firstWhere((s) => s is RenewSlipFailure);

        final failure = bloc.state as RenewSlipFailure;
        expect(
          failure.message,
          contains('Không thể xác nhận kết quả gia hạn'),
        );

        await bloc.close();
      },
    );

    test(
      'GET refresh lỗi sau PATCH thành công | Không làm mất kết quả thành công',
      () async {
        final repository = FakeBorrowingRepository();
        final initialSlip = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'mem-01',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          renewalEligibility: const RenewalEligibility(canRenew: true),
          items: const [],
        );

        int getSlipCalls = 0;
        repository.fakeSlipDetailBuilder = (slipId) {
          getSlipCalls++;
          if (getSlipCalls == 1) {
            // Lần 1: trước khi PATCH để kiểm tra eligibility
            return initialSlip;
          }
          // Lần 2: sau khi PATCH renewSlip -> ném lỗi mạng để giả lập GET refresh thất bại
          throw DioException(
            requestOptions: RequestOptions(path: '/borrowing-slips/slip-01'),
            type: DioExceptionType.connectionError,
          );
        };

        final bloc = RenewSlipBloc(repository: repository);

        bloc.add(const RenewSlipRequested('slip-01', extraDays: 7));

        await bloc.stream.firstWhere((s) => s is RenewSlipSuccess);

        final success = bloc.state as RenewSlipSuccess;
        expect(success.slip.renewCount, 1);
        expect(repository.renewSlipCallCount, 1);
        expect(getSlipCalls, 2); // Xác nhận đã gọi GET refresh lần 2 và bị lỗi

        await bloc.close();
      },
    );

    test(
      'CheckSlipRenewalRequested | Tải lại eligibility thành công -> RenewSlipChecked',
      () async {
        final repository = FakeBorrowingRepository();
        repository.fakeSlipDetail = BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'mem-01',
          status: 'BORROWED',
          dueDate: DateTime.utc(2026, 11, 15),
          renewCount: 0,
          renewalEligibility: const RenewalEligibility(canRenew: true),
          items: const [],
        );

        final bloc = RenewSlipBloc(repository: repository);
        final states = <RenewSlipState>[];
        final subscription = bloc.stream.listen(states.add);

        bloc.add(const CheckSlipRenewalRequested('slip-01'));

        await bloc.stream.firstWhere((s) => s is RenewSlipChecked);

        expect(states[0], isA<RenewSlipChecking>());
        expect(states[1], isA<RenewSlipChecked>());

        final checked = states[1] as RenewSlipChecked;
        expect(checked.slip.canRenew, true);

        await subscription.cancel();
        await bloc.close();
      },
    );
  });
}
