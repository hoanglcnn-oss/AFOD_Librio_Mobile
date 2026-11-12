import 'package:equatable/equatable.dart';

import '../data/models/borrowing_slip.dart';

abstract class ReturnSlipState extends Equatable {
  const ReturnSlipState();

  @override
  List<Object?> get props => [];
}

class ReturnSlipInitial extends ReturnSlipState {
  const ReturnSlipInitial();
}

class ReturnSlipSubmitting extends ReturnSlipState {
  const ReturnSlipSubmitting();
}

class ReturnSlipSuccess extends ReturnSlipState {
  final BorrowingSlip slip;

  const ReturnSlipSuccess(this.slip);

  @override
  List<Object?> get props => [slip];
}

class ReturnSlipFailure extends ReturnSlipState {
  final String message;

  const ReturnSlipFailure(this.message);

  @override
  List<Object?> get props => [message];
}

