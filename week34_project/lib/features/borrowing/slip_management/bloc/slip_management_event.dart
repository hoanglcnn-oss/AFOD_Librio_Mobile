import 'package:equatable/equatable.dart';

abstract class ApproveSlipEvent extends Equatable {
  const ApproveSlipEvent();

  @override
  List<Object?> get props => [];
}

class ApproveSlipRequested extends ApproveSlipEvent {
  final String slipId;

  const ApproveSlipRequested(this.slipId);

  @override
  List<Object?> get props => [slipId];
}

class RejectSlipRequested extends ApproveSlipEvent {
  final String slipId;
  final String reason;

  const RejectSlipRequested({required this.slipId, required this.reason});

  @override
  List<Object?> get props => [slipId, reason];
}

typedef SlipManagementEvent = ApproveSlipEvent;
