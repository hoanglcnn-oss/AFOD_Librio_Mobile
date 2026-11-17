import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:week34_project/features/borrowing/shared/repositories/borrowing_slips_repository.dart';
import 'package:week34_project/features/borrowing/shared/errors/borrowing_slip_error_mapper.dart';
import 'create_slip_event.dart';
import 'create_slip_state.dart';

class CreateSlipBloc extends Bloc<CreateSlipEvent, CreateSlipState> {
  final BorrowingSlipsRepository borrowingSlipsRepository;

  bool _isSubmitting = false;

  CreateSlipBloc({required this.borrowingSlipsRepository})
    : super(const CreateSlipInitial()) {
    on<CreateSlipRequested>(_onCreateSlipRequested);
  }

  Future<void> _onCreateSlipRequested(
    CreateSlipRequested event,
    Emitter<CreateSlipState> emit,
  ) async {
    if (_isSubmitting || state is CreateSlipSuccess) {
      return;
    }

    _isSubmitting = true;
    emit(const CreateSlipSubmitting());

    try {
      final slip = await borrowingSlipsRepository.createBorrowingSlip(
        event.request,
      );

      emit(CreateSlipSuccess(slip));
    } catch (error) {
      emit(CreateSlipFailure(getBorrowingSlipErrorMessage(error)));
    } finally {
      _isSubmitting = false;
    }
  }
}
