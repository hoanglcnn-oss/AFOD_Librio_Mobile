import 'package:equatable/equatable.dart';

import '../../borrowing/shared/models/borrowing_slip.dart';

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

class ApproveSlipLimitExceeded extends ApproveSlipState {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;
  final String remediation;

  const ApproveSlipLimitExceeded({
    required this.message,
    this.code,
    this.details,
    this.remediation =
        'Độc giả cần trả bớt sách đang mượn trước khi có thể duyệt thêm phiếu này, hoặc từ chối phiếu để độc giả tạo lại với số lượng phù hợp.',
  });

  @override
  List<Object?> get props => [message, code, details, remediation];
}
