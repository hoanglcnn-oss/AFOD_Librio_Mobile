import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/borrowing_repository.dart';
import 'my_borrowings_event.dart';
import 'my_borrowings_state.dart';

class MyBorrowingsBloc extends Bloc<MyBorrowingsEvent, MyBorrowingsState> {
  final BorrowingRepository borrowingRepository;

  MyBorrowingsBloc({required this.borrowingRepository})
    : super(const MyBorrowingsInitial()) {
    on<LoadMyBorrowings>(_onLoadMyBorrowings);
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
}
