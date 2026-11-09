import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/borrowing_repository.dart';
import 'my_borrowings_event.dart';
import 'my_borrowings_state.dart';

class MyBorrowingsBloc extends Bloc<MyBorrowingsEvent, MyBorrowingsState> {
  final BorrowingRepository borrowingRepository;

  MyBorrowingsBloc({required this.borrowingRepository})
    : super(const MyBorrowingsInitial()) {
    on<LoadMyBorrowings>(_onLoadMyBorrowings);
    on<ReturnBookRequested>(_onReturnBookRequested);
  }

  Future<void> _onLoadMyBorrowings(
    LoadMyBorrowings event,
    Emitter<MyBorrowingsState> emit,
  ) async {
    emit(const MyBorrowingsLoading());

    try {
      final result = await borrowingRepository.getBorrowings(
        memberId: event.memberId,
      );

      emit(MyBorrowingsLoaded(result));
    } catch (error) {
      emit(MyBorrowingsFailure(error.toString()));
    }
  }

  Future<void> _onReturnBookRequested(
    ReturnBookRequested event,
    Emitter<MyBorrowingsState> emit,
  ) async {
    final currentState = state;

    final page = switch (currentState) {
      MyBorrowingsLoaded s => s.borrowingsPage,
      MyBorrowingsReturnFailure s => s.borrowingsPage,
      _ => null,
    };

    if (page == null) {
      return;
    }
    // Không cho phép trả lại phiếu đã RETURNED.
    final matches = page.borrowings.where(
      (borrowing) => borrowing.id == event.borrowingId,
    );

    if (matches.isEmpty || matches.first.status == 'RETURNED') {
      return;
    }

    emit(
      MyBorrowingsReturning(
        borrowingsPage: page,
        borrowingId: event.borrowingId,
      ),
    );

    try {
      await borrowingRepository.returnBook(borrowingId: event.borrowingId);

      emit(MyBorrowingsReturnSuccess(page));
    } catch (error) {
      emit(
        MyBorrowingsReturnFailure(
          borrowingsPage: page,
          message: error.toString(),
        ),
      );
    }
  }
}
