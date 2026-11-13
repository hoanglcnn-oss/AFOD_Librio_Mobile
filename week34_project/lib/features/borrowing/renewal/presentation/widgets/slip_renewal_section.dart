import 'package:flutter/material.dart';

import '../../../shared/models/borrowing_slip.dart';
import '../../bloc/renew_slip_state.dart';
import '../../errors/renewal_error_mapper.dart';

/// Presentation widget rendering the renewal status badge and action button
/// based on [BorrowingSlip.canRenew] and [RenewSlipState].
class SlipRenewalSection extends StatelessWidget {
  final BorrowingSlip slip;
  final RenewSlipState renewState;
  final VoidCallback onRenewPressed;
  final VoidCallback onCheckEligibility;

  const SlipRenewalSection({
    super.key,
    required this.slip,
    required this.renewState,
    required this.onRenewPressed,
    required this.onCheckEligibility,
  });

  @override
  Widget build(BuildContext context) {
    final isProcessing =
        renewState is RenewSlipSubmitting || renewState is RenewSlipChecking;

    if (isProcessing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              renewState is RenewSlipChecking
                  ? 'Đang kiểm tra điều kiện gia hạn...'
                  : 'Đang xử lý gia hạn...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    if (slip.canRenew == true) {
      return Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: onRenewPressed,
          icon: const Icon(Icons.update, size: 18),
          label: const Text('Gia hạn'),
        ),
      );
    }

    if (slip.canRenew == false) {
      final reason =
          slip.renewalMessage ??
          mapRenewalReasonCode(slip.renewalReasonCode) ??
          'Phiếu mượn không đủ điều kiện để gia hạn.';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.update, size: 18),
              label: const Text('Gia hạn'),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reason,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    // canRenew == null: nút Kiểm tra gia hạn, không tự cho phép PATCH
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onCheckEligibility,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Kiểm tra gia hạn'),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Chưa có thông tin gia hạn. Bấm để kiểm tra điều kiện.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
