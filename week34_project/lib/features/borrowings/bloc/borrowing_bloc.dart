import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/borrowing_error_mapper.dart';
import '../data/borrowing_repository.dart';
import 'borrowing_event.dart';
import 'borrowing_state.dart';

class BorrowingBloc extends Bloc<BorrowingEvent, BorrowingState> {
  final BorrowingRepository borrowingRepository;

  bool _isSubmitting = false;

  BorrowingBloc({required this.borrowingRepository})
    : super(const BorrowingInitial()) {
    on<BorrowBookRequested>(_onBorrowBookRequested);
  }

  Future<void> _onBorrowBookRequested(
    BorrowBookRequested event,
    Emitter<BorrowingState> emit,
  ) async {
    // Chặn event trùng trong lúc request chưa hoàn tất.
    if (_isSubmitting || state is BorrowingSuccess) {
      return;
    }

    _isSubmitting = true;
    emit(const BorrowingSubmitting());

    try {
      final borrowing = await borrowingRepository.borrowBook(event.request);

      emit(BorrowingSuccess(borrowing));
    } catch (error) {
      emit(BorrowingFailure(getBorrowingErrorMessage(error)));
    } finally {
      _isSubmitting = false;
    }
  }
}
