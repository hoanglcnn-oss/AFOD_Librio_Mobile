import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/borrowings/bloc/my_borrowings_bloc.dart';
import 'package:week34_project/features/borrowings/bloc/my_borrowings_event.dart';
import 'package:week34_project/features/borrowings/bloc/my_borrowings_state.dart';

import 'fake/fake_borrowing_repository.dart';

void main() {
  group('MyBorrowingsBloc', () {
    test('LoadMyBorrowings emits Loading -> Loaded', () async {
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
    });
    test('LoadMyBorrowings emits Loading -> Failure', () async {
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
    });
  });
}
