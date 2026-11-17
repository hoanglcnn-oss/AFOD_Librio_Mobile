import 'package:equatable/equatable.dart';

import 'package:week34_project/features/borrowing/shared/models/borrowing_slip.dart';

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
