import 'package:flutter/material.dart';

import 'package:week34_project/features/members/data/models/member_debt_summary.dart';

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
    const primaryNavy = Color(0xFF0F172A);
    const borderHairline = Color(0xFFE2E8F0);
    const greenSuccess = Color(0xFF16A34A);
    const greenBg = Color(0xFFF0FDF4);
    const greenBorder = Color(0xFFBBF7D0);
    const errorRed = Color(0xFFDC2626);
    const errorBg = Color(0xFFFEF2F2);
    const errorBorder = Color(0xFFFECACA);

    if (isDebtLoading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderHairline),
        ),
        padding: const EdgeInsets.all(16),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: primaryNavy),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đang kiểm tra hạn mức mượn sách...',
                style: TextStyle(color: primaryNavy),
              ),
            ),
          ],
        ),
      );
    }

    if (isDebtError || debtSummary == null) {
      return Container(
        decoration: BoxDecoration(
          color: errorBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: errorBorder),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline, color: errorRed, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Không thể tải thông tin hạn mức mượn sách',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: errorRed,
                    ),
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
      );
    }

    final maxLimit = debtSummary!.maxBorrowLimit;
    final currentlyBorrowed = debtSummary!.currentBorrowedCount;
    final totalAfterBorrow = currentlyBorrowed + totalSelected;
    final progress = maxLimit > 0
        ? (totalAfterBorrow / maxLimit).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: canSubmit ? borderHairline : errorBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                canSubmit ? Icons.verified_user_outlined : Icons.info_outline,
                size: 20,
                color: canSubmit ? greenSuccess : errorRed,
              ),
              const SizedBox(width: 8),
              const Text(
                'Hạn mức mượn sách',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primaryNavy,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: canSubmit ? greenBg : errorBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: canSubmit ? greenBorder : errorBorder),
                ),
                child: Text(
                  canSubmit ? 'Hợp lệ' : 'Cần xử lý',
                  style: TextStyle(
                    color: canSubmit ? greenSuccess : errorRed,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Thanh tiến trình hạn mức theo DESIGN.md
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(
                canSubmit ? primaryNavy : errorRed,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            '• Đang mượn: $currentlyBorrowed/$maxLimit cuốn',
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 2),
          Text(
            '• Còn được mượn: ${debtSummary!.remainingBorrowLimit} cuốn',
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 2),
          Text(
            '• Đang chọn: $totalSelected cuốn',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryNavy,
            ),
          ),
          const SizedBox(height: 8),

          if (canSubmit)
            const Text(
              'Đủ điều kiện gửi phiếu mượn',
              style: TextStyle(
                color: greenSuccess,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            )
          else
            Text(
              notAllowedReason ?? 'Không đủ điều kiện gửi phiếu mượn',
              style: const TextStyle(
                color: errorRed,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: borderHairline),
          const SizedBox(height: 10),

          // Lưu ý quy trình mượn sách tích hợp
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                size: 18,
                color: Color(0xFF0D9488),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Phiếu mượn cần được thủ thư phê duyệt trước khi bạn đến nhận sách tại quầy.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
