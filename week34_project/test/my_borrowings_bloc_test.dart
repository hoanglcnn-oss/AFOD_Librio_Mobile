import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/core/models/renewal_eligibility.dart';
import 'package:week34_project/features/borrowings/bloc/my_borrowings_bloc.dart';
import 'package:week34_project/features/borrowings/bloc/my_borrowings_event.dart';
import 'package:week34_project/features/borrowings/bloc/my_borrowings_state.dart';
import 'package:week34_project/features/borrowings/data/models/borrowing.dart';

import 'fake/fake_borrowing_repository.dart';

void main() {
  group('MyBorrowingsBloc', () {
    test(
      'LoadMyBorrowings | Repository có 1 phiếu | Loading -> Loaded, dữ liệu đúng',
      () async {
        final repository = FakeBorrowingRepository();
        final bloc = MyBorrowingsBloc(borrowingRepository: repository);

        final states = <MyBorrowingsState>[];
        final subscription = bloc.stream.listen(states.add);

        bloc.add(const LoadMyBorrowings('mem-01'));

        await bloc.stream.firstWhere((state) => state is MyBorrowingsLoaded);

        expect(states.length, 2);
        expect(states[0], isA<MyBorrowingsLoading>());
        expect(states[1], isA<MyBorrowingsLoaded>());

        final loaded = states[1] as MyBorrowingsLoaded;

        expect(loaded.borrowingsPage.borrowings.length, 1);
        expect(loaded.borrowingsPage.borrowings.first.memberId, 'mem-01');
        expect(loaded.borrowingsPage.borrowings.first.status, 'BORROWED');

        await subscription.cancel();
        await bloc.close();
      },
    );

    test(
      'LoadMyBorrowings | Repository lỗi | Loading -> Failure, có thông báo',
      () async {
        final repository = FakeBorrowingRepository(shouldFail: true);
        final bloc = MyBorrowingsBloc(borrowingRepository: repository);

        final states = <MyBorrowingsState>[];
        final subscription = bloc.stream.listen(states.add);

        bloc.add(const LoadMyBorrowings('mem-01'));

        await bloc.stream.firstWhere((state) => state is MyBorrowingsFailure);

        expect(states.length, 2);
        expect(states[0], isA<MyBorrowingsLoading>());
        expect(states[1], isA<MyBorrowingsFailure>());

        final failure = states[1] as MyBorrowingsFailure;
        expect(failure.message, contains('Không thể tải danh sách mượn sách'));

        await subscription.cancel();
        await bloc.close();
      },
    );

    test(
      'ReturnBookRequested | Repository thành công | Returning -> ReturnSuccess, gọi 1 lần',
      () async {
        final repository = FakeBorrowingRepository();
        final bloc = MyBorrowingsBloc(borrowingRepository: repository);

        bloc.add(const LoadMyBorrowings('mem-01'));
        await bloc.stream.firstWhere((s) => s is MyBorrowingsLoaded);

        final states = <MyBorrowingsState>[];
        final subscription = bloc.stream.listen(states.add);

        bloc.add(const ReturnBookRequested('brw-01'));

        await bloc.stream.firstWhere((s) => s is MyBorrowingsReturnSuccess);

        expect(states.length, 2);
        expect(states[0], isA<MyBorrowingsReturning>());
        expect(states[1], isA<MyBorrowingsReturnSuccess>());
        expect(repository.returnCallCount, 1);

        await subscription.cancel();
        await bloc.close();
      },
    );

    test(
      'ReturnBookRequested | Repository lỗi | Returning -> ReturnFailure, có thông báo',
      () async {
        final repository = FakeBorrowingRepository()..shouldFailReturn = true;

        final bloc = MyBorrowingsBloc(borrowingRepository: repository);

        bloc.add(const LoadMyBorrowings('mem-01'));
        await bloc.stream.firstWhere((s) => s is MyBorrowingsLoaded);

        final states = <MyBorrowingsState>[];
        final subscription = bloc.stream.listen(states.add);

        bloc.add(const ReturnBookRequested('brw-01'));

        await bloc.stream.firstWhere((s) => s is MyBorrowingsReturnFailure);

        expect(states.length, 2);
        expect(states[0], isA<MyBorrowingsReturning>());
        expect(states[1], isA<MyBorrowingsReturnFailure>());

        final failure = states[1] as MyBorrowingsReturnFailure;
        expect(failure.message, contains('Không thể trả sách'));

        await subscription.cancel();
        await bloc.close();
      },
    );

    test(
      'ReturnBookRequested | BLoC chưa Loaded | giữ Initial, không gọi Repository',
      () async {
        final repository = FakeBorrowingRepository();
        final bloc = MyBorrowingsBloc(borrowingRepository: repository);

        bloc.add(const ReturnBookRequested('brw-01'));

        await bloc.stream.first.timeout(
          const Duration(milliseconds: 100),
          onTimeout: () => bloc.state,
        );

        expect(repository.returnCallCount, 0);
        expect(bloc.state, isA<MyBorrowingsInitial>());

        await bloc.close();
      },
    );

    group('RenewBorrowingRequested with safe flow & eligibility', () {
      test(
        'Phiếu hợp lệ (canRenew = true) | Lấy eligibility mới nhất -> gọi renewLoan -> RenewSuccess',
        () async {
          final repository = FakeBorrowingRepository();
          final bloc = MyBorrowingsBloc(borrowingRepository: repository);

          bloc.add(const LoadMyBorrowings('mem-01'));
          await bloc.stream.firstWhere((s) => s is MyBorrowingsLoaded);

          final states = <MyBorrowingsState>[];
          final subscription = bloc.stream.listen(states.add);

          bloc.add(
            const RenewBorrowingRequested(borrowingId: 'brw-01', extraDays: 7),
          );

          await bloc.stream.firstWhere((s) => s is MyBorrowingsRenewSuccess);

          expect(states, [
            isA<MyBorrowingsRenewing>(),
            isA<MyBorrowingsRenewSuccess>(),
          ]);
          expect(repository.getBorrowingByIdCallCount, 1);
          expect(repository.renewCallCount, 1);
          expect(repository.lastExtraDays, 7);
          expect(repository.fakeRenewCount, 1);

          await subscription.cancel();
          await bloc.close();
        },
      );

      test(
        'canRenew = false (ACTIVE_RESERVATION) | getBorrowingById gọi -> RenewFailure với lý do từ backend, KHÔNG gọi renewLoan',
        () async {
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

          final states = <MyBorrowingsState>[];
          final subscription = bloc.stream.listen(states.add);

          bloc.add(
            const RenewBorrowingRequested(borrowingId: 'brw-01', extraDays: 7),
          );

          await bloc.stream.firstWhere((s) => s is MyBorrowingsRenewFailure);

          expect(states[0], isA<MyBorrowingsRenewing>());
          expect(states[1], isA<MyBorrowingsRenewFailure>());

          final failure = states[1] as MyBorrowingsRenewFailure;
          expect(failure.message, contains('Sách đang có người đặt trước'));
          expect(repository.getBorrowingByIdCallCount, 1);
          expect(repository.renewCallCount, 0); // KHÔNG gọi POST renewLoan

          await subscription.cancel();
          await bloc.close();
        },
      );

      test(
        'canRenew = false (MAX_RENEWALS_REACHED) | RenewFailure, KHÔNG gọi renewLoan',
        () async {
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
            renewCount: 2,
            renewalEligibility: const RenewalEligibility(
              canRenew: false,
              reasonCode: 'MAX_RENEWALS_REACHED',
            ),
          );

          final bloc = MyBorrowingsBloc(borrowingRepository: repository);

          bloc.add(const LoadMyBorrowings('mem-01'));
          await bloc.stream.firstWhere((s) => s is MyBorrowingsLoaded);

          bloc.add(
            const RenewBorrowingRequested(borrowingId: 'brw-01', extraDays: 7),
          );

          await bloc.stream.firstWhere((s) => s is MyBorrowingsRenewFailure);

          expect(repository.getBorrowingByIdCallCount, 1);
          expect(repository.renewCallCount, 0);

          final failure = bloc.state as MyBorrowingsRenewFailure;
          expect(failure.message, 'Đã đạt giới hạn số lần gia hạn cho phép.');

          await bloc.close();
        },
      );

      test(
        'Concurrency guard | Chặn double-click khi request gia hạn đang pending',
        () async {
          final repository = FakeBorrowingRepository();
          final completer = Completer<void>();
          repository.renewCompleter = completer;

          final bloc = MyBorrowingsBloc(borrowingRepository: repository);

          bloc.add(const LoadMyBorrowings('mem-01'));
          await bloc.stream.firstWhere((s) => s is MyBorrowingsLoaded);

          // Gửi request 1
          bloc.add(const RenewBorrowingRequested(borrowingId: 'brw-01'));

          // Chờ sang trạng thái Renewing
          await bloc.stream.firstWhere((s) => s is MyBorrowingsRenewing);

          // Gửi request 2 trùng lặp khi request 1 đang pending
          bloc.add(const RenewBorrowingRequested(borrowingId: 'brw-01'));

          // Hoàn thành request 1
          completer.complete();

          await bloc.stream.firstWhere((s) => s is MyBorrowingsRenewSuccess);

          // Chỉ có 1 lần gọi renewLoan và 1 lần getBorrowingById
          expect(repository.renewCallCount, 1);
          expect(repository.getBorrowingByIdCallCount, 1);

          await bloc.close();
        },
      );

      test(
        'HTTP 409 Conflict | Hiển thị lỗi nghiệp vụ và lấy lại eligibility',
        () async {
          final repository = FakeBorrowingRepository();
          repository.renewLoanError = DioException(
            requestOptions: RequestOptions(path: '/borrowings/brw-01/renew'),
            response: Response(
              requestOptions: RequestOptions(path: '/borrowings/brw-01/renew'),
              statusCode: 409,
              data: {
                'message': 'Conflict',
                'reasonCode': 'ACTIVE_RESERVATION',
              },
            ),
          );

          final bloc = MyBorrowingsBloc(borrowingRepository: repository);

          bloc.add(const LoadMyBorrowings('mem-01'));
          await bloc.stream.firstWhere((s) => s is MyBorrowingsLoaded);

          bloc.add(const RenewBorrowingRequested(borrowingId: 'brw-01'));

          await bloc.stream.firstWhere((s) => s is MyBorrowingsRenewFailure);

          final failure = bloc.state as MyBorrowingsRenewFailure;
          expect(failure.message, 'Sách đang có người đặt trước, không thể gia hạn.');
          // Đã gọi getBorrowingById trước khi renew + sau khi gặp 409 để lấy lại eligibility
          expect(repository.getBorrowingByIdCallCount, 2);
          expect(repository.fakeRenewCount, 0);

          await bloc.close();
        },
      );

      test(
        'Timeout mạng | Không tự cộng ngày, không retry tự động, emit RenewFailure',
        () async {
          final repository = FakeBorrowingRepository();
          repository.renewLoanError = DioException(
            requestOptions: RequestOptions(path: '/borrowings/brw-01/renew'),
            type: DioExceptionType.connectionTimeout,
          );

          final bloc = MyBorrowingsBloc(borrowingRepository: repository);

          bloc.add(const LoadMyBorrowings('mem-01'));
          await bloc.stream.firstWhere((s) => s is MyBorrowingsLoaded);

          bloc.add(const RenewBorrowingRequested(borrowingId: 'brw-01'));

          await bloc.stream.firstWhere((s) => s is MyBorrowingsRenewFailure);

          final failure = bloc.state as MyBorrowingsRenewFailure;
          expect(failure.message, contains('Không thể kết nối đến máy chủ'));
          expect(repository.renewCallCount, 1);
          expect(repository.fakeRenewCount, 0);

          await bloc.close();
        },
      );

      test(
        'getBorrowingById lỗi | Emit RenewFailure, KHÔNG gọi renewLoan',
        () async {
          final repository = FakeBorrowingRepository();
          repository.shouldFailGetBorrowingById = true;

          final bloc = MyBorrowingsBloc(borrowingRepository: repository);

          bloc.add(const LoadMyBorrowings('mem-01'));
          await bloc.stream.firstWhere((s) => s is MyBorrowingsLoaded);

          bloc.add(const RenewBorrowingRequested(borrowingId: 'brw-01'));

          await bloc.stream.firstWhere((s) => s is MyBorrowingsRenewFailure);

          expect(repository.getBorrowingByIdCallCount, 1);
          expect(repository.renewCallCount, 0);
          expect(repository.fakeRenewCount, 0);

          await bloc.close();
        },
      );
    });
  });
}
