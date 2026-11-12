import 'package:flutter/material.dart';

import '../../../borrowing_slips/data/models/borrowing_slip.dart';
import 'borrowing_slip_ui_helper.dart';

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

  @override
  Widget build(BuildContext context) {
    final overdue = BorrowingSlipUiHelper.isOverdue(slip);
    final totalCopies = slip.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            onTap: onTap,
            title: Text(slip.slipNumber),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showMember && slip.memberId.isNotEmpty)
                  Text(
                    'Độc giả: ${BorrowingSlipUiHelper.formatShortId(slip.memberId)}',
                  ),
                Text(
                  'Trạng thái: '
                  '${BorrowingSlipUiHelper.slipStatus(slip.status)}',
                ),
                Text(
                  'Hạn trả: '
                  '${BorrowingSlipUiHelper.formatDate(slip.dueDate)}',
                ),
                Text(
                  totalCopies > 0
                      ? '$totalCopies cuốn (${slip.items.length} đầu sách)'
                      : '${slip.items.length} đầu sách',
                ),
                if (overdue)
                  Text(
                    'Có sách quá hạn',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (BorrowingSlipUiHelper.hasUnpaidFine(slip))
                  Text(
                    'Chưa thanh toán: '
                    '${BorrowingSlipUiHelper.formatMoney(slip.totalFine)}',
                  ),
              ],
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
          ),
          if (actions != null) ...[
            const Divider(height: 1),
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
