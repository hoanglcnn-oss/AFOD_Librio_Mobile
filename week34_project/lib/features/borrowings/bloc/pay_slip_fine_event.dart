import 'package:equatable/equatable.dart';

abstract class PaySlipFineEvent extends Equatable {
  const PaySlipFineEvent();

  @override
  List<Object?> get props => [];
}

class PaySlipFineRequested extends PaySlipFineEvent {
  final String slipId;

  const PaySlipFineRequested(this.slipId);

  @override
  List<Object?> get props => [slipId];
}
