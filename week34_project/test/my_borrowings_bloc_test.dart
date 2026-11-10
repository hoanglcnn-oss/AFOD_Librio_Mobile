import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/borrowings/bloc/my_borrowings_bloc.dart';
import 'package:week34_project/features/borrowings/bloc/my_borrowings_event.dart';
import 'package:week34_project/features/borrowings/bloc/my_borrowings_state.dart';

import 'fake/fake_borrowing_repository.dart';

void main() {
  group('MyBorrowingsBloc', () {
    // Event | Điều kiện đầu vào | Kết quả được kiểm chứng
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

        // Đợi xử lý event trong hàng đợi.
        await bloc.stream.first.timeout(
          const Duration(milliseconds: 100),
          onTimeout: () => bloc.state,
        );

        expect(repository.returnCallCount, 0);
        expect(bloc.state, isA<MyBorrowingsInitial>());

        await bloc.close();
      },
    );
    test(
      'RenewBorrowingRequested | Phiếu hợp lệ | Renewing -> RenewSuccess, tăng renewCount',
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
        expect(repository.renewCallCount, 1);
        expect(repository.lastExtraDays, 7);
        expect(repository.fakeRenewCount, 1);

        await subscription.cancel();
        await bloc.close();
      },
    );
    test(
      'RenewBorrowingRequested | Repository lỗi | Renewing -> RenewFailure, không tăng renewCount',
      () async {
        final repository = FakeBorrowingRepository()..shouldFailRenew = true;

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
        expect(repository.renewCallCount, 1);
        expect(repository.fakeRenewCount, 0);

        await subscription.cancel();
        await bloc.close();
      },
    );
    test(
      'RenewBorrowingRequested | renewCount = 2 | RenewFailure, không gọi Repository',
      () async {
        final repository = FakeBorrowingRepository()..fakeRenewCount = 2;

        final bloc = MyBorrowingsBloc(borrowingRepository: repository);

        bloc.add(const LoadMyBorrowings('mem-01'));
        await bloc.stream.firstWhere((s) => s is MyBorrowingsLoaded);

        bloc.add(
          const RenewBorrowingRequested(borrowingId: 'brw-01', extraDays: 7),
        );

        await bloc.stream.firstWhere((s) => s is MyBorrowingsRenewFailure);

        expect(repository.renewCallCount, 0);
        expect(bloc.state, isA<MyBorrowingsRenewFailure>());

        await bloc.close();
      },
    );
  });
}
