import 'package:flutter/material.dart';

import '../../../shared/models/borrowing_slip.dart';
import '../../../shared/widgets/borrowing_slip_ui_helper.dart';

class SlipDetailActions extends StatelessWidget {
  final BorrowingSlip slip;
  final bool canManageSlip;
  final bool canCancelSlip;
  final bool isCancelling;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;
  final VoidCallback? onReturn;
  final VoidCallback? onPayFine;
  final VoidCallback? onRefresh;

  const SlipDetailActions({
    super.key,
    required this.slip,
    required this.canManageSlip,
    required this.canCancelSlip,
    this.isCancelling = false,
    this.onApprove,
    this.onReject,
    this.onCancel,
    this.onReturn,
    this.onPayFine,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (BorrowingSlipUiHelper.hasUnpaidFine(slip)) ...[
          const SizedBox(height: 12),
          if (canManageSlip)
            FilledButton.icon(
              onPressed: onPayFine,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Ghi nhận đã thu tiền phạt'),
            )
          else
            const Text(
              'Vui lòng liên hệ thủ thư để thanh toán tiền phạt.',
            ),
        ],
        if (canManageSlip && slip.status == 'PENDING_APPROVAL') ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  child: const Text('Từ chối'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check),
                  label: const Text('Duyệt phiếu'),
                ),
              ),
            ],
          ),
        ],
        if (canCancelSlip) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('cancel_pending_slip_button'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onPressed: isCancelling ? null : onCancel,
              icon: isCancelling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: Text(
                isCancelling ? 'Đang hủy...' : 'Hủy phiếu mượn',
              ),
            ),
          ),
        ],
        if (canManageSlip &&
            (slip.status == 'BORROWED' ||
                slip.status == 'PARTIAL_RETURNED') &&
            slip.items.any((item) => item.remainingQuantity > 0)) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onReturn,
            icon: const Icon(Icons.assignment_return),
            label: const Text('Xác nhận trả sách'),
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Cập nhật trạng thái phiếu'),
        ),
      ],
    );
  }
}
