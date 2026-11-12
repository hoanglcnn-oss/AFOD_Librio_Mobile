import 'package:flutter/material.dart';

import '../../../borrowing_slips/data/models/borrowing_slip.dart';
import 'borrowing_slip_ui_helper.dart';

//card từng sách
class BorrowingSlipItemCard extends StatelessWidget {
  final BorrowingSlipItem item;
  final bool isOverdue;

  const BorrowingSlipItemCard({
    super.key,
    required this.item,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.bookTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Trạng thái: '
              '${BorrowingSlipUiHelper.itemStatus(item.status)}',
            ),
            Text('Đã trả: ${item.returnedQuantity}/${item.quantity}'),
            if (item.lostQuantity > 0) Text('Đã báo mất: ${item.lostQuantity}'),
            if (item.returnDate != null)
              Text(
                'Ngày xử lý: '
                '${BorrowingSlipUiHelper.formatDate(item.returnDate!)}',
              ),
            if (isOverdue && item.remainingQuantity > 0)
              Text(
                'Còn ${item.remainingQuantity} cuốn quá hạn',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (item.lateFee > 0)
              Text(
                'Phạt trả trễ: '
                '${BorrowingSlipUiHelper.formatMoney(item.lateFee)}',
              ),
            if (item.compensationFee > 0)
              Text(
                'Bồi thường: '
                '${BorrowingSlipUiHelper.formatMoney(item.compensationFee)}',
              ),
          ],
        ),
      ),
    );
  }
}
