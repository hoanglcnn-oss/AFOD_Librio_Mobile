import 'package:flutter/material.dart';

import '../../data/models/borrowing_slip.dart';
import 'borrowing_slip_ui_helper.dart';

//card của phiếu mượn
class BorrowingSlipCard extends StatelessWidget {
  final BorrowingSlip slip;
  final VoidCallback onTap;
  final bool showMember;

  const BorrowingSlipCard({
    super.key,
    required this.slip,
    required this.onTap,
    this.showMember = false,
  });

  @override
  Widget build(BuildContext context) {
    final overdue = BorrowingSlipUiHelper.isOverdue(slip);
    final totalCopies = slip.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(slip.slipNumber),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showMember && slip.memberId.isNotEmpty)
              Text('Độc giả: ${slip.memberId}'),
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
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
    );
  }
}
