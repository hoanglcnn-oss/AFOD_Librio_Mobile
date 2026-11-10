import 'package:equatable/equatable.dart';

import '../data/models/borrowing_slip.dart';

abstract class BorrowingSlipState extends Equatable {
  const BorrowingSlipState();

  @override
  List<Object?> get props => [];
}

class BorrowingSlipInitial extends BorrowingSlipState {
  const BorrowingSlipInitial();
}

class BorrowingSlipSubmitting extends BorrowingSlipState {
  const BorrowingSlipSubmitting();
}

class BorrowingSlipSuccess extends BorrowingSlipState {
  final BorrowingSlip slip;

  const BorrowingSlipSuccess(this.slip);

  @override
  List<Object?> get props => [slip.id, slip.status];
}

class BorrowingSlipFailure extends BorrowingSlipState {
  final String message;

  const BorrowingSlipFailure(this.message);

  @override
  List<Object?> get props => [message];
}
