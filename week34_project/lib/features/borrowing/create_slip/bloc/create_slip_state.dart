import 'package:equatable/equatable.dart';

import '../../shared/models/borrowing_slip.dart';

abstract class CreateSlipState extends Equatable {
  const CreateSlipState();

  @override
  List<Object?> get props => [];
}

class CreateSlipInitial extends CreateSlipState {
  const CreateSlipInitial();
}

class CreateSlipSubmitting extends CreateSlipState {
  const CreateSlipSubmitting();
}

class CreateSlipSuccess extends CreateSlipState {
  final BorrowingSlip slip;

  const CreateSlipSuccess(this.slip);

  @override
  List<Object?> get props => [slip];
}

class CreateSlipFailure extends CreateSlipState {
  final String message;

  const CreateSlipFailure(this.message);

  @override
  List<Object?> get props => [message];
}
