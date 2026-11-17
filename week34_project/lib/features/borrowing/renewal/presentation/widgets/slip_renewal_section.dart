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
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              renewState is RenewSlipChecking
                  ? 'Đang kiểm tra điều kiện gia hạn...'
                  : 'Đang xử lý gia hạn...',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.update, size: 18),
              label: const Text('Gia hạn'),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reason,
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 12,
              fontWeight: FontWeight.w500,
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
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.search, size: 18, color: Color(0xFF0D9488)),
            label: const Text('Kiểm tra gia hạn'),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Chưa có thông tin gia hạn. Bấm để kiểm tra điều kiện.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}
