import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/repositories/borrowing_slips_repository.dart';
import '../../shared/errors/borrowing_slip_error_mapper.dart';
import 'borrowing_slip_event.dart';
import 'borrowing_slip_state.dart';

class BorrowingSlipBloc extends Bloc<BorrowingSlipEvent, BorrowingSlipState> {
  final BorrowingSlipsRepository borrowingSlipsRepository;

  bool _isSubmitting = false;

  BorrowingSlipBloc({required this.borrowingSlipsRepository})
    : super(const BorrowingSlipInitial()) {
    on<CreateSlipRequested>(_onCreateSlipRequested);
  }

  Future<void> _onCreateSlipRequested(
    CreateSlipRequested event,
    Emitter<BorrowingSlipState> emit,
  ) async {
    if (_isSubmitting || state is BorrowingSlipSuccess) {
      return;
    }

    _isSubmitting = true;
    emit(const BorrowingSlipSubmitting());

    try {
      final slip = await borrowingSlipsRepository.createBorrowingSlip(
        event.request,
      );

      emit(BorrowingSlipSuccess(slip));
    } catch (error) {
      emit(BorrowingSlipFailure(getBorrowingSlipErrorMessage(error)));
    } finally {
      _isSubmitting = false;
    }
  }
}
