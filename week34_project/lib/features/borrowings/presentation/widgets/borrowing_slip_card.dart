import 'package:flutter/material.dart';

import '../../data/models/borrowing_slip.dart';
import 'borrowing_slip_ui_helper.dart';

//card của phiếu mượn
class BorrowingSlipCard extends StatelessWidget {
  final BorrowingSlip slip;
  final VoidCallback onTap;

  const BorrowingSlipCard({super.key, required this.slip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final overdue = BorrowingSlipUiHelper.isOverdue(slip);

    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(slip.slipNumber),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trạng thái: '
              '${BorrowingSlipUiHelper.slipStatus(slip.status)}',
            ),
            Text(
              'Hạn trả: '
              '${BorrowingSlipUiHelper.formatDate(slip.dueDate)}',
            ),
            Text('${slip.items.length} đầu sách'),
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
