import 'package:flutter/material.dart';

import '../../../shared/models/borrowing_slip.dart';
import '../../../shared/widgets/borrowing_slip_ui_helper.dart';

//card của phiếu mượn
class BorrowingSlipCard extends StatelessWidget {
  final BorrowingSlip slip;
  final VoidCallback onTap;
  final bool showMember;
  final Widget? actions;

  const BorrowingSlipCard({
    super.key,
    required this.slip,
    required this.onTap,
    this.showMember = false,
    this.actions,
  });

  String _resolveMemberDisplay() {
    if (slip.memberName != null && slip.memberName!.trim().isNotEmpty) {
      return slip.memberName!.trim();
    }
    if (slip.memberCardNumber != null &&
        slip.memberCardNumber!.trim().isNotEmpty) {
      return slip.memberCardNumber!.trim();
    }
    if (slip.memberId.isNotEmpty) {
      return BorrowingSlipUiHelper.formatShortId(slip.memberId);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final overdue = BorrowingSlipUiHelper.isOverdue(slip);
    final totalCopies =
        (slip.status == 'BORROWED' || slip.status == 'PARTIAL_RETURNED')
            ? slip.items.fold<int>(
                0,
                (sum, item) =>
                    sum +
                    (item.quantity -
                        item.returnedQuantity -
                        item.lostQuantity),
              )
            : slip.items.fold<int>(
                0,
                (sum, item) => sum + item.quantity,
              );

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: overdue ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            onTap: onTap,
            title: Text(
              slip.slipNumber,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showMember && _resolveMemberDisplay().isNotEmpty)
                  Text(
                    'Độc giả: ${_resolveMemberDisplay()}',
                    style: const TextStyle(color: Color(0xFF334155)),
                  ),
                Text(
                  'Trạng thái: '
                  '${BorrowingSlipUiHelper.slipStatus(slip.status)}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                Text(
                  'Hạn trả: '
                  '${BorrowingSlipUiHelper.formatDate(slip.dueDate)}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                Text(
                  totalCopies > 0
                      ? '$totalCopies cuốn (${slip.items.length} đầu sách)'
                      : '${slip.items.length} đầu sách',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                if (overdue)
                  const Text(
                    'Có sách quá hạn',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (BorrowingSlipUiHelper.hasUnpaidFine(slip))
                  Text(
                    'Chưa thanh toán: '
                    '${BorrowingSlipUiHelper.formatMoney(slip.totalFine)}',
                    style: const TextStyle(
                      color: Color(0xFFD97706),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            isThreeLine: true,
            trailing: const Icon(
              Icons.chevron_right,
              color: Color(0xFF94A3B8),
            ),
          ),
          if (actions != null) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: actions!,
            ),
          ],
        ],
      ),
    );
  }
}
