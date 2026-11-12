import 'package:flutter/material.dart';

import '../../data/models/borrowing.dart';
import 'borrowing_ui_helper.dart';

class BorrowingCard extends StatelessWidget {
  final Borrowing borrowing;
  final VoidCallback? onReturn;
  final VoidCallback? onRenew;
  final VoidCallback? onPayFine;
  final bool isReturning;
  final bool isRenewing;
  final bool isPayingFine;
  final bool isBusy;
  final bool showMember;

  const BorrowingCard({
    super.key,
    required this.borrowing,
    this.onReturn,
    this.onRenew,
    this.onPayFine,
    this.isReturning = false,
    this.isRenewing = false,
    this.isPayingFine = false,
    this.isBusy = false,
    this.showMember = false,
  });
  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  bool get _hasUnpaidFine =>
      (borrowing.fineAmount != null && borrowing.fineAmount! > 0) &&
      (borrowing.finePaid != true);

  bool _hasActions({required String status, required bool canRenew}) {
    final showReturn = status != 'RETURNED' && onReturn != null;
    final showRenew = status != 'RETURNED' && canRenew && onRenew != null;
    final showPayFine = _hasUnpaidFine && onPayFine != null;
    return showReturn || showRenew || showPayFine;
  }

  @override
  Widget build(BuildContext context) {
    final status = borrowing.status;
    final canRenew =
        status == 'BORROWED' &&
        borrowing.renewCount < 2 &&
        !DateTime.now().isAfter(borrowing.dueDate);
    final statusLabel = switch (status) {
      'BORROWED' => 'Đang mượn',
      'OVERDUE' => 'Quá hạn',
      'RETURNED' => 'Đã trả',
      _ => status,
    };

    final statusColor = switch (status) {
      'BORROWED' => Colors.orange,
      'OVERDUE' => Colors.red,
      'RETURNED' => Colors.green,
      _ => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    borrowing.bookTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(statusLabel),
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  side: BorderSide.none,
                ),
              ],
            ),
            Text(
              borrowing.transactionCode,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Ngày mượn',
              value: _formatDate(borrowing.borrowDate),
            ),
            const SizedBox(height: 6),
            _InfoRow(label: 'Hạn trả', value: _formatDate(borrowing.dueDate)),
            if (showMember &&
                (borrowing.memberName.isNotEmpty ||
                    borrowing.memberId.isNotEmpty)) ...[
              const SizedBox(height: 6),
              _InfoRow(
                label: 'Độc giả',
                value: borrowing.memberName.isNotEmpty
                    ? borrowing.memberName
                    : BorrowingUiHelper.formatShortId(borrowing.memberId),
              ),
            ],
            if (borrowing.fineAmount != null && borrowing.fineAmount! > 0) ...[
              const SizedBox(height: 6),
              _InfoRow(
                label: 'Tiền phạt',
                value:
                    '${BorrowingUiHelper.formatMoney(borrowing.fineAmount!)} '
                    '(${borrowing.finePaid == true ? 'Đã thu' : 'Chưa thu'})',
              ),
            ],
            if (status != 'RETURNED') ...[
              const SizedBox(height: 6),
              Text(
                'Đã gia hạn: ${borrowing.renewCount}/2 lần',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (_hasActions(status: status, canRenew: canRenew)) ...[
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (canRenew && onRenew != null && status != 'RETURNED')
                    OutlinedButton.icon(
                      onPressed: isBusy ? null : onRenew,
                      icon: isRenewing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.update),
                      label: Text(isRenewing ? 'Đang gia hạn...' : 'Gia hạn'),
                    ),
                  if (onReturn != null && status != 'RETURNED')
                    OutlinedButton.icon(
                      onPressed: isBusy ? null : onReturn,
                      icon: isReturning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.assignment_turned_in_outlined),
                      label: Text(isReturning ? 'Đang trả...' : 'Trả sách'),
                    ),
                  if (_hasUnpaidFine && onPayFine != null)
                    FilledButton.icon(
                      onPressed: isBusy ? null : onPayFine,
                      icon: isPayingFine
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.payments_outlined),
                      label: Text(
                        isPayingFine ? 'Đang thu...' : 'Thu tiền phạt',
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Text(value),
      ],
    );
  }
}
