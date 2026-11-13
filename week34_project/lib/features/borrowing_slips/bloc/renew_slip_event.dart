import 'package:equatable/equatable.dart';

import '../data/models/borrowing_slip.dart';

abstract class RenewSlipEvent extends Equatable {
  const RenewSlipEvent();

  @override
  List<Object?> get props => [];
}

/// Yêu cầu kiểm tra điều kiện gia hạn mới nhất từ Backend (dùng khi canRenew == null)
class CheckSlipRenewalRequested extends RenewSlipEvent {
  final String slipId;

  const CheckSlipRenewalRequested(this.slipId);

  @override
  List<Object?> get props => [slipId];
}

/// Yêu cầu thực hiện gia hạn phiếu mượn
class RenewSlipRequested extends RenewSlipEvent {
  final String slipId;
  final int extraDays;
  final BorrowingSlip? currentSlip;

  const RenewSlipRequested(
    this.slipId, {
    this.extraDays = 7,
    this.currentSlip,
  });

  @override
  List<Object?> get props => [slipId, extraDays, currentSlip];
}
