import 'package:equatable/equatable.dart';

import '../data/models/borrowing_slip.dart';

abstract class PaySlipFineState extends Equatable {
  const PaySlipFineState();

  @override
  List<Object?> get props => [];
}

class PaySlipFineInitial extends PaySlipFineState {
  const PaySlipFineInitial();
}

class PaySlipFineSubmitting extends PaySlipFineState {
  const PaySlipFineSubmitting();
}

class PaySlipFineSuccess extends PaySlipFineState {
  final BorrowingSlip slip;

  const PaySlipFineSuccess(this.slip);

  @override
  List<Object?> get props => [slip];
}

class PaySlipFineFailure extends PaySlipFineState {
  final String message;

  const PaySlipFineFailure(this.message);

  @override
  List<Object?> get props => [message];
}
