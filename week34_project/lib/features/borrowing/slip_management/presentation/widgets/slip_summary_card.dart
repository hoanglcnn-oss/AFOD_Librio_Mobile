import 'package:flutter/material.dart';

import '../../../shared/models/borrowing_slip.dart';
import '../../../shared/widgets/borrowing_slip_ui_helper.dart';

/// Thẻ tổng kết tài chính và trạng thái hoàn tất của phiếu mượn
class SlipSummaryCard extends StatelessWidget {
  final BorrowingSlip slip;

  const SlipSummaryCard({super.key, required this.slip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = slip.status.toUpperCase() == 'COMPLETED';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'TỔNG KẾT PHIẾU',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Trạng thái phiếu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trạng thái',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  BorrowingSlipUiHelper.slipStatus(slip.status),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Ngày hoàn tất dự kiến (hoặc ngày hoàn tất nếu đã xong)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCompleted ? 'Ngày hoàn tất' : 'Hoàn tất dự kiến',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isCompleted
                      ? BorrowingSlipUiHelper.formatDate(slip.dueDate)
                      : 'Trước ${BorrowingSlipUiHelper.formatDate(slip.dueDate)}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Tổng tiền phạt
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng tiền phạt',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  BorrowingSlipUiHelper.formatMoney(slip.totalFine),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: slip.totalFine > 0
                        ? theme.colorScheme.error
                        : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Trạng thái thanh toán phạt
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thanh toán phạt',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  slip.finePaid
                      ? 'Đã thanh toán tiền phạt'
                      : 'Chưa thanh toán tiền phạt',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: slip.finePaid
                        ? const Color(0xFF16A34A)
                        : (slip.totalFine > 0
                              ? theme.colorScheme.error
                              : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ],
          ),

          // Banner Checkbox nổi bật khi phiếu đã hoàn tất
          if (isCompleted) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF059669), size: 20),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '✓ PHIẾU ĐÃ HOÀN TẤT',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF065F46),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
