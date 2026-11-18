import 'package:flutter/material.dart';

import '../../../shared/models/borrowing_slip.dart';
import '../../../shared/widgets/borrowing_slip_ui_helper.dart';

class BorrowingSlipCard extends StatefulWidget {
  final BorrowingSlip slip;
  final VoidCallback onTap;
  final bool showMember;
  final bool? showStatus;
  final Widget? actions;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const BorrowingSlipCard({
    super.key,
    required this.slip,
    required this.onTap,
    this.showMember = false,
    this.showStatus,
    this.actions,
    this.onApprove,
    this.onReject,
  });

  @override
  State<BorrowingSlipCard> createState() => _BorrowingSlipCardState();
}

class _BorrowingSlipCardState extends State<BorrowingSlipCard> {
  final ValueNotifier<bool> _isSwipingNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isSwipingNotifier.dispose();
    super.dispose();
  }

  String _resolveMemberDisplay() {
    if (widget.slip.memberName != null &&
        widget.slip.memberName!.trim().isNotEmpty) {
      return widget.slip.memberName!.trim();
    }
    if (widget.slip.memberCardNumber != null &&
        widget.slip.memberCardNumber!.trim().isNotEmpty) {
      return widget.slip.memberCardNumber!.trim();
    }
    if (widget.slip.memberId.isNotEmpty) {
      return BorrowingSlipUiHelper.formatShortId(widget.slip.memberId);
    }
    return '';
  }

  ({Color bg, Color text, String label}) _resolveStatusStyle(
      String status, bool overdue) {
    if (overdue) {
      return (
        bg: const Color(0xFFFEF2F2),
        text: const Color(0xFFDC2626),
        label: 'Quá hạn',
      );
    }

    switch (status) {
      case 'PENDING_APPROVAL':
        return (
          bg: const Color(0xFFFEF3C7),
          text: const Color(0xFFD97706),
          label: 'Chờ duyệt',
        );
      case 'BORROWED':
        return (
          bg: const Color(0xFFF0FDFA),
          text: const Color(0xFF0D9488),
          label: 'Đang mượn',
        );
      case 'PARTIAL_RETURNED':
        return (
          bg: const Color(0xFFEFF6FF),
          text: const Color(0xFF2563EB),
          label: 'Trả một phần',
        );
      case 'COMPLETED':
        return (
          bg: const Color(0xFFECFDF5),
          text: const Color(0xFF10B981),
          label: 'Đã hoàn tất',
        );
      case 'REJECTED':
        return (
          bg: const Color(0xFFFEF2F2),
          text: const Color(0xFFDC2626),
          label: 'Bị từ chối',
        );
      case 'CANCELLED':
        return (
          bg: const Color(0xFFF1F5F9),
          text: const Color(0xFF64748B),
          label: 'Đã hủy',
        );
      default:
        return (
          bg: const Color(0xFFF8FAFC),
          text: const Color(0xFF334155),
          label: BorrowingSlipUiHelper.slipStatus(status),
        );
    }
  }

  Widget _buildTallActionButton({
    required String label,
    required String hint,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    required Color fgColor,
    required Color hintColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              left: BorderSide(color: borderColor, width: 1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Dòng trên: Gợi ý cử chỉ gạt (↶ Gạt trái / Gạt phải ↷)
              Text(
                hint,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: hintColor,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              // Dòng dưới: Icon + Nhãn nút (Từ chối / Duyệt phiếu)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13.5, color: fgColor),
                  const SizedBox(width: 3),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: fgColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overdue = BorrowingSlipUiHelper.isOverdue(widget.slip);
    final isSwipeable = widget.onApprove != null || widget.onReject != null;
    final effectiveShowStatus = widget.showStatus ??
        (!isSwipeable || widget.slip.status != 'PENDING_APPROVAL');
    final statusStyle = _resolveStatusStyle(widget.slip.status, overdue);

    final totalCopies = (widget.slip.status == 'BORROWED' ||
            widget.slip.status == 'PARTIAL_RETURNED')
        ? widget.slip.items.fold<int>(
            0,
            (sum, item) =>
                sum +
                (item.quantity - item.returnedQuantity - item.lostQuantity),
          )
        : widget.slip.items.fold<int>(
            0,
            (sum, item) => sum + item.quantity,
          );

    Widget cardWidget = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: overdue ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Thân thẻ bên trái: Thông tin phiếu
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InkWell(
                          onTap: widget.onTap,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Dòng 1: Mã phiếu + Độc giả
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 2,
                                  children: [
                                    Text(
                                      widget.slip.slipNumber,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    if (widget.showMember &&
                                        _resolveMemberDisplay().isNotEmpty) ...[
                                      const Text(
                                        '•',
                                        style:
                                            TextStyle(color: Color(0xFF94A3B8)),
                                      ),
                                      Text(
                                        'Độc giả: ${_resolveMemberDisplay()}',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 5),

                                // Dòng 2: Hạn trả + Số lượng sách
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 2,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 12,
                                          color: overdue
                                              ? const Color(0xFFDC2626)
                                              : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Hạn: ${BorrowingSlipUiHelper.formatDate(widget.slip.dueDate)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: overdue
                                                ? const Color(0xFFDC2626)
                                                : const Color(0xFF64748B),
                                            fontWeight: overdue
                                                ? FontWeight.w700
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Text(
                                      '•',
                                      style: TextStyle(
                                        color: Color(0xFFCBD5E1),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.menu_book_rounded,
                                          size: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          totalCopies > 0
                                              ? '$totalCopies cuốn'
                                              : '${widget.slip.items.length} đầu sách',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                // Cảnh báo nợ phạt (nếu có)
                                if (BorrowingSlipUiHelper.hasUnpaidFine(
                                    widget.slip)) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded,
                                          size: 12,
                                          color: Color(0xFFD97706)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Nợ: ${BorrowingSlipUiHelper.formatMoney(widget.slip.totalFine)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFD97706),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Actions Bar mở rộng bên dưới (nếu có truyền vào và không phải swipeable inline)
                        if (widget.actions != null && !isSwipeable) ...[
                          const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFF1F5F9)),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            child: widget.actions!,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 2. Bên phải:
                  // TH1: Có thao tác duyệt/từ chối -> Nút dài cả chiều dọc (Full Height Pastel)
                  if (isSwipeable) ...[
                    if (widget.onReject != null)
                      _buildTallActionButton(
                        label: 'Từ chối',
                        hint: '↶ Gạt trái',
                        icon: Icons.close_rounded,
                        bgColor: const Color(0xFFFEF2F2),
                        borderColor: const Color(0xFFFECACA),
                        fgColor: const Color(0xFFDC2626),
                        hintColor: const Color(0xFFB91C1C),
                        onTap: widget.onReject!,
                      ),
                    if (widget.onApprove != null)
                      _buildTallActionButton(
                        label: 'Duyệt phiếu',
                        hint: 'Gạt phải ↷',
                        icon: Icons.check_rounded,
                        bgColor: const Color(0xFFECFDF5),
                        borderColor: const Color(0xFFA7F3D0),
                        fgColor: const Color(0xFF047857),
                        hintColor: const Color(0xFF065F46),
                        onTap: widget.onApprove!,
                      ),
                  ]
                  // TH2: Trạng thái thông thường (không phải swipeable)
                  else if (effectiveShowStatus) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusStyle.bg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusStyle.text,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusStyle.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: statusStyle.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 3. Overlay gợi ý khi đang vuốt trên card (ValueListenableBuilder để không rebuild lại toàn bộ card)
            ValueListenableBuilder<bool>(
              valueListenable: _isSwipingNotifier,
              builder: (context, isSwiping, _) {
                if (!isSwiping) return const SizedBox.shrink();
                return Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF0D9488),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '👉 Vuốt phải [✓ Duyệt]',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF047857),
                                ),
                              ),
                              Text(
                                '   •   ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              Text(
                                'Vuốt trái [✕ Từ chối] 👈',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

    if (!isSwipeable) {
      return cardWidget;
    }

    return Dismissible(
      key: ValueKey('slip_${widget.slip.id}'),
      direction: DismissDirection.horizontal,
      onUpdate: (details) {
        final swiping = details.progress > 0.02;
        if (_isSwipingNotifier.value != swiping) {
          _isSwipingNotifier.value = swiping;
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.only(left: 20),
        alignment: Alignment.centerLeft,
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Duyệt phiếu',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Từ chối',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.cancel_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        _isSwipingNotifier.value = false;
        // Hoãn lại sau frame hiện tại để Dismissible hoàn tất animation trả về an toàn,
        // tránh lỗi InheritedElement deactivation khi mở dialog bất đồng bộ
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (direction == DismissDirection.startToEnd) {
            widget.onApprove?.call();
          } else if (direction == DismissDirection.endToStart) {
            widget.onReject?.call();
          }
        });
        return false;
      },
      child: cardWidget,
    );
  }
}
