import 'package:flutter/material.dart';

import '../../../../members/data/models/member_debt_summary.dart';

class BorrowDebtSummaryCard extends StatelessWidget {
  final bool isDebtLoading;
  final bool isDebtError;
  final MemberDebtSummary? debtSummary;
  final int totalSelected;
  final bool canSubmit;
  final String? notAllowedReason;
  final VoidCallback? onRetry;

  const BorrowDebtSummaryCard({
    super.key,
    required this.isDebtLoading,
    required this.isDebtError,
    required this.debtSummary,
    required this.totalSelected,
    required this.canSubmit,
    this.notAllowedReason,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isDebtLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Đang kiểm tra hạn mức mượn sách...')),
            ],
          ),
        ),
      );
    }

    if (isDebtError || debtSummary == null) {
      return Card(
        color: Theme.of(
          context,
        ).colorScheme.errorContainer.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Không thể tải thông tin hạn mức mượn sách',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Thử lại'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Card(
      color: canSubmit
          ? Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  canSubmit ? Icons.verified_outlined : Icons.info_outline,
                  size: 20,
                  color: canSubmit
                      ? Colors.green
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Hạn mức mượn sách',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• Đang mượn: ${debtSummary!.currentBorrowedCount}/${debtSummary!.maxBorrowLimit} cuốn',
            ),
            Text('• Còn được mượn: ${debtSummary!.remainingBorrowLimit} cuốn'),
            Text('• Đang chọn: $totalSelected cuốn'),
            const SizedBox(height: 6),
            if (canSubmit)
              const Text(
                'Đủ điều kiện gửi phiếu mượn',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                notAllowedReason ?? 'Không đủ điều kiện gửi phiếu mượn',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
