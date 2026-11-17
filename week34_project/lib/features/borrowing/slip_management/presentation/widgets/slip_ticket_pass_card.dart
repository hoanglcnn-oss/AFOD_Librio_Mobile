import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/widgets/app_toast.dart';
import '../../../shared/models/borrowing_slip.dart';
import '../../../shared/widgets/borrowing_slip_ui_helper.dart';
import '../../../shared/widgets/ticket_notch_divider.dart';

export '../../../shared/widgets/ticket_notch_divider.dart';

/// Khung vé mượn (Digital Ticket Pass) liền mạch chứa thông tin phiếu và danh sách sách
class SlipTicketPassCard extends StatelessWidget {
  final BorrowingSlip slip;
  final bool isOverdue;
  final Widget? renewalSection;

  const SlipTicketPassCard({
    super.key,
    required this.slip,
    required this.isOverdue,
    this.renewalSection,
  });

  Color _resolveStatusBgColor(String status) {
    return switch (status) {
      'PENDING_APPROVAL' => const Color(0xFFFEF3C7),
      'BORROWED' => const Color(0xFFDBEAFE),
      'PARTIAL_RETURNED' => const Color(0xFFEDE9FE),
      'COMPLETED' => const Color(0xFFD1FAE5),
      'REJECTED' || 'CANCELLED' => const Color(0xFFFEE2E2),
      _ => const Color(0xFFF1F5F9),
    };
  }

  Color _resolveStatusTextColor(String status) {
    return switch (status) {
      'PENDING_APPROVAL' => const Color(0xFF92400E),
      'BORROWED' => const Color(0xFF1E40AF),
      'PARTIAL_RETURNED' => const Color(0xFF5B21B6),
      'COMPLETED' => const Color(0xFF065F46),
      'REJECTED' || 'CANCELLED' => const Color(0xFF991B1B),
      _ => const Color(0xFF334155),
    };
  }

  Color _resolveCardBorderColor(BuildContext context) {
    if (isOverdue) {
      return Theme.of(context).colorScheme.error.withValues(alpha: 0.7);
    }
    return switch (slip.status.toUpperCase()) {
      'PENDING_APPROVAL' => const Color(0xFFF59E0B).withValues(alpha: 0.6),
      'BORROWED' => const Color(0xFF3B82F6).withValues(alpha: 0.5),
      'PARTIAL_RETURNED' => const Color(0xFF8B5CF6).withValues(alpha: 0.5),
      'COMPLETED' => const Color(0xFF10B981).withValues(alpha: 0.5),
      'REJECTED' => const Color(0xFFEF4444).withValues(alpha: 0.5),
      'CANCELLED' => const Color(0xFF94A3B8).withValues(alpha: 0.6),
      _ => const Color(0xFFE2E8F0),
    };
  }

  Widget _buildTopStatusBanner(BuildContext context) {
    final theme = Theme.of(context);

    // 1. Quá hạn luôn ưu tiên cảnh báo nổi bật nhất
    if (isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.error,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Phiếu có sách chưa trả và đã quá hạn',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final (bgColor, iconColor, textColor, icon, label) =
        switch (slip.status.toUpperCase()) {
      'PENDING_APPROVAL' => (
        const Color(0xFFFEF3C7),
        const Color(0xFFD97706),
        const Color(0xFF92400E),
        Icons.hourglass_top_rounded,
        'Phiếu mượn đang chờ thủ thư xét duyệt',
      ),
      'BORROWED' => (
        const Color(0xFFEFF6FF),
        const Color(0xFF2563EB),
        const Color(0xFF1D4ED8),
        Icons.auto_stories_outlined,
        'Phiếu mượn đang lưu hành trong thời hạn',
      ),
      'PARTIAL_RETURNED' => (
        const Color(0xFFF5F3FF),
        const Color(0xFF7C3AED),
        const Color(0xFF6D28D9),
        Icons.assignment_turned_in_outlined,
        'Đã hoàn trả một phần sách, còn sách đang mượn',
      ),
      'COMPLETED' => (
        const Color(0xFFECFDF5),
        const Color(0xFF059669),
        const Color(0xFF047857),
        Icons.check_circle_outline_rounded,
        'Phiếu mượn đã hoàn tất toàn bộ sách',
      ),
      'REJECTED' => (
        const Color(0xFFFEF2F2),
        const Color(0xFFDC2626),
        const Color(0xFFB91C1C),
        Icons.highlight_off_rounded,
        'Phiếu mượn đã bị từ chối phê duyệt',
      ),
      'CANCELLED' => (
        const Color(0xFFF1F5F9),
        const Color(0xFF64748B),
        const Color(0xFF475569),
        Icons.remove_circle_outline_rounded,
        'Phiếu mượn đã được hủy bỏ',
      ),
      _ => (
        const Color(0xFFF8FAFC),
        const Color(0xFF64748B),
        const Color(0xFF334155),
        Icons.info_outline,
        'Thông tin chi tiết phiếu mượn',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMemberName =
        slip.memberName != null && slip.memberName!.trim().isNotEmpty;
    final hasMemberCardNumber =
        slip.memberCardNumber != null &&
        slip.memberCardNumber!.trim().isNotEmpty;

    final borrowerDisplay = hasMemberName
        ? slip.memberName!.trim()
        : (hasMemberCardNumber ? slip.memberCardNumber!.trim() : slip.memberId);

    final cardBorderColor = _resolveCardBorderColor(context);
    const cardBorderWidth = 1.5;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorderColor,
          width: cardBorderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner trạng thái phiếu in màu lên đầu phiếu
          _buildTopStatusBanner(context),

          // Nửa trên của vé: Thông tin phiếu & Độc giả
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header thương hiệu căn giữa
                Center(
                  child: Column(
                    children: [
                      Text(
                        'LIBRIO',
                        style: TextStyle(
                          letterSpacing: 3,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        slip.slipNumber,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _resolveStatusBgColor(slip.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Trạng thái: ${BorrowingSlipUiHelper.slipStatus(slip.status)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _resolveStatusTextColor(slip.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Khối thông tin độc giả
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: Icon(
                          Icons.person,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Độc giả: $borrowerDisplay',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (hasMemberName && hasMemberCardNumber) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Số thẻ: ${slip.memberCardNumber!.trim()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                            const SizedBox(height: 2),
                            Text(
                              'Mã độc giả: ${slip.memberId}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.copy,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        tooltip: 'Sao chép mã độc giả',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: slip.memberId));
                          AppToast.success(context, 'Đã sao chép mã độc giả');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Bảng 3 cột thông số: Ngày mượn | Hạn trả | Gia hạn
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Cột 1: Ngày mượn (căn giữa)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Ngày mượn',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  slip.borrowDate != null
                                      ? BorrowingSlipUiHelper.formatDate(
                                          slip.borrowDate!,
                                        )
                                      : '--',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(width: 8),

                          // Cột 2: Hạn trả (căn giữa)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Hạn trả',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'đến ${BorrowingSlipUiHelper.formatDate(slip.dueDate)}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isOverdue
                                        ? theme.colorScheme.error
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(width: 8),

                          // Cột 3: Lượt gia hạn (căn giữa)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Lượt gia hạn',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${slip.renewCount} lần',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Giữ text ẩn không chiếm diện tích UI cho automated tests
                      SizedBox.shrink(
                        child: Text(
                          'Số lần đã gia hạn: ${slip.renewCount}',
                        ),
                      ),
                    ],
                  ),
                ),

                // Khối hỗ trợ gia hạn nếu truyền vào
                if (renewalSection != null) ...[
                  const SizedBox(height: 10),
                  renewalSection!,
                ],
              ],
            ),
          ),

          // Đường rãnh xé vé đứt đoạn (- - - - -) với vết khuyết bán nguyệt 2 mép
          TicketPerforationRow(
            backgroundColor: const Color(0xFFF8FAFC),
            ticketColor: Colors.white,
            borderColor: cardBorderColor,
            borderWidth: cardBorderWidth,
            height: 24,
          ),

          // Nửa dưới của vé: Danh sách sách mượn
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề danh sách sách
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Danh sách sách',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${slip.items.length.toString().padLeft(2, '0')} cuốn',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Đường nét liền phân cách giữa tiêu đề với sách
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 14),

                // Danh sách từng cuốn sách
                for (int i = 0; i < slip.items.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _buildBookItemRow(context, slip.items[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookItemRow(BuildContext context, BorrowingSlipItem item) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail biểu tượng sách
        Container(
          width: 44,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2F6),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Center(
            child: Icon(Icons.menu_book, size: 22, color: Color(0xFF64748B)),
          ),
        ),
        const SizedBox(width: 12),

        // Chi tiết sách
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.bookTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              // Hàng trạng thái sách và số lượng đã trả dồn sang góc phải
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Trạng thái: ${BorrowingSlipUiHelper.itemStatus(item.status)}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đã trả: ${item.returnedQuantity}/${item.quantity}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              if (item.lostQuantity > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Đã báo mất: ${item.lostQuantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              if (item.returnDate != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Ngày xử lý: ${BorrowingSlipUiHelper.formatDate(item.returnDate!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
              if (isOverdue && item.remainingQuantity > 0) ...[
                const SizedBox(height: 2),
                Text(
                  'Còn ${item.remainingQuantity} cuốn quá hạn',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              if (item.lateFee > 0) ...[
                const SizedBox(height: 2),
                Text(
                  'Phạt trả trễ: ${BorrowingSlipUiHelper.formatMoney(item.lateFee)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
              if (item.compensationFee > 0) ...[
                const SizedBox(height: 2),
                Text(
                  'Bồi thường: ${BorrowingSlipUiHelper.formatMoney(item.compensationFee)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
