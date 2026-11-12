import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/borrowing_error_mapper.dart';
import '../../borrowing_slips/data/borrowing_slips_repository.dart';
import 'borrowing_slip_event.dart';
import 'borrowing_slip_state.dart';

class BorrowingSlipBloc extends Bloc<BorrowingSlipEvent, BorrowingSlipState> {
  final BorrowingSlipsRepository borrowingRepository;

  BorrowingSlipsRepository get borrowingSlipsRepository => borrowingRepository;

  bool _isSubmitting = false;

  BorrowingSlipBloc({
    BorrowingSlipsRepository? borrowingSlipsRepository,
    BorrowingSlipsRepository? borrowingRepository,
  })  : borrowingRepository =
            borrowingSlipsRepository ?? borrowingRepository!,
        super(const BorrowingSlipInitial()) {
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
      final slip = await borrowingRepository.createBorrowingSlip(event.request);

      emit(BorrowingSlipSuccess(slip));
    } catch (error) {
      emit(BorrowingSlipFailure(getBorrowingErrorMessage(error)));
    } finally {
      _isSubmitting = false;
    }
  }
}
