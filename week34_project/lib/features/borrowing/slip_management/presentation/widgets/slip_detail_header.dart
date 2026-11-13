import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/widgets/app_toast.dart';
import '../../../shared/models/borrowing_slip.dart';
import '../../../shared/widgets/borrowing_slip_ui_helper.dart';

class SlipDetailHeader extends StatelessWidget {
  final BorrowingSlip slip;
  final bool? isOverdue;

  const SlipDetailHeader({
    super.key,
    required this.slip,
    this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    final overdue = isOverdue ?? BorrowingSlipUiHelper.isOverdue(slip);

    final hasMemberName =
        slip.memberName != null && slip.memberName!.trim().isNotEmpty;
    final hasMemberCardNumber =
        slip.memberCardNumber != null &&
        slip.memberCardNumber!.trim().isNotEmpty;

    final borrowerDisplay = hasMemberName
        ? slip.memberName!.trim()
        : (hasMemberCardNumber
            ? slip.memberCardNumber!.trim()
            : slip.memberId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          slip.slipNumber,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Độc giả: $borrowerDisplay'),
                  if (hasMemberName && hasMemberCardNumber) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Số thẻ: ${slip.memberCardNumber!.trim()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    'Mã độc giả: ${slip.memberId}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Sao chép mã độc giả',
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: slip.memberId),
                );
                AppToast.success(context, 'Đã sao chép mã độc giả');
              },
            ),
          ],
        ),
        Text(
          'Trạng thái: ${BorrowingSlipUiHelper.slipStatus(slip.status)}',
        ),
        Text(
          'Hạn trả: ${BorrowingSlipUiHelper.formatDate(slip.dueDate)}',
        ),
        Text('Số lần đã gia hạn: ${slip.renewCount}'),
        if (overdue) ...[
          const SizedBox(height: 8),
          Text(
            'Phiếu có sách chưa trả và đã quá hạn',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
