import 'package:equatable/equatable.dart';

import '../data/models/borrowing_slip.dart';

abstract class ApproveSlipState extends Equatable {
  const ApproveSlipState();

  @override
  List<Object?> get props => [];
}

class ApproveSlipInitial extends ApproveSlipState {
  const ApproveSlipInitial();
}

class ApproveSlipSubmitting extends ApproveSlipState {
  const ApproveSlipSubmitting();
}

class ApproveSlipSuccess extends ApproveSlipState {
  final BorrowingSlip slip;

  const ApproveSlipSuccess(this.slip);

  @override
  List<Object?> get props => [slip];
}

class ApproveSlipFailure extends ApproveSlipState {
  final String message;
  final bool requiresRefresh;

  const ApproveSlipFailure(this.message, {this.requiresRefresh = false});

  @override
  List<Object?> get props => [message, requiresRefresh];
}
