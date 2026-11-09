import 'package:flutter/material.dart';

import '../../data/models/borrowing.dart';

class BorrowingCard extends StatelessWidget {
  final Borrowing borrowing;
  final VoidCallback? onReturn;
  final bool isReturning;
  const BorrowingCard({
    super.key,
    required this.borrowing,
    this.onReturn,
    this.isReturning = false,
  });
  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final status = borrowing.status;

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
            if (borrowing.status != 'RETURNED' && onReturn != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: isReturning ? null : onReturn,
                  icon: isReturning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.assignment_turned_in_outlined),
                  label: Text(isReturning ? 'Đang xử lý...' : 'Trả sách'),
                ),
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
