import 'package:equatable/equatable.dart';

import '../../borrowing/shared/models/borrowing_slip.dart';

abstract class RenewSlipState extends Equatable {
  const RenewSlipState();

  @override
  List<Object?> get props => [];
}

class RenewSlipInitial extends RenewSlipState {
  const RenewSlipInitial();
}

class RenewSlipChecking extends RenewSlipState {
  const RenewSlipChecking();
}

class RenewSlipChecked extends RenewSlipState {
  final BorrowingSlip slip;

  const RenewSlipChecked(this.slip);

  @override
  List<Object?> get props => [slip];
}

class RenewSlipSubmitting extends RenewSlipState {
  const RenewSlipSubmitting();
}

class RenewSlipSuccess extends RenewSlipState {
  final BorrowingSlip slip;
  final String message;

  const RenewSlipSuccess(
    this.slip, {
    this.message = 'Gia hạn phiếu mượn thành công',
  });

  @override
  List<Object?> get props => [slip, message];
}

class RenewSlipFailure extends RenewSlipState {
  final String message;
  final BorrowingSlip? latestSlip;

  const RenewSlipFailure(this.message, {this.latestSlip});

  @override
  List<Object?> get props => [message, latestSlip];
}

