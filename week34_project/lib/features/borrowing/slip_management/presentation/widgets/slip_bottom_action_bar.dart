import 'package:flutter/material.dart';

import '../../../renewal/bloc/renew_slip_state.dart';
import '../../../renewal/errors/renewal_error_mapper.dart';
import '../../../shared/models/borrowing_slip.dart';
import '../../../shared/widgets/borrowing_slip_ui_helper.dart';

/// Thanh hành động cố định ở đáy màn hình (Fixed Bottom Action Bar)
/// Tối ưu công thái học ngón tay cái (Thumb-zone) theo vai trò và trạng thái phiếu
class SlipBottomActionBar extends StatelessWidget {
  final BorrowingSlip slip;
  final bool canManageSlip;
  final bool canCancelSlip;
  final bool isCancelling;
  final bool canRenew;
  final RenewSlipState? renewState;
  final bool isCard;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;
  final VoidCallback? onReturn;
  final VoidCallback? onPayFine;
  final VoidCallback? onRenew;
  final VoidCallback? onCheckEligibility;
  final VoidCallback? onRefresh;

  const SlipBottomActionBar({
    super.key,
    required this.slip,
    required this.canManageSlip,
    required this.canCancelSlip,
    this.isCancelling = false,
    this.canRenew = false,
    this.renewState,
    this.isCard = false,
    this.onApprove,
    this.onReject,
    this.onCancel,
    this.onReturn,
    this.onPayFine,
    this.onRenew,
    this.onCheckEligibility,
    this.onRefresh,
  });

  bool get hasActions {
    final hasUnpaidFine = BorrowingSlipUiHelper.hasUnpaidFine(slip);
    final canApproveReject = canManageSlip && slip.status == 'PENDING_APPROVAL';
    final canReturnBooks =
        canManageSlip &&
        (slip.status == 'BORROWED' || slip.status == 'PARTIAL_RETURNED') &&
        slip.items.any((item) => item.remainingQuantity > 0);

    return hasUnpaidFine ||
        canApproveReject ||
        canCancelSlip ||
        canReturnBooks ||
        canRenew;
  }

  @override
  Widget build(BuildContext context) {
    if (!hasActions) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final hasUnpaidFine = BorrowingSlipUiHelper.hasUnpaidFine(slip);
    final canApproveReject = canManageSlip && slip.status == 'PENDING_APPROVAL';
    final canReturnBooks =
        canManageSlip &&
        (slip.status == 'BORROWED' || slip.status == 'PARTIAL_RETURNED') &&
        slip.items.any((item) => item.remainingQuantity > 0);

    final isRenewProcessing =
        renewState is RenewSlipSubmitting || renewState is RenewSlipChecking;

    return Container(
      decoration: isCard
          ? BoxDecoration(
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
            )
          : const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0F0F172A),
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
      padding: isCard
          ? const EdgeInsets.all(16)
          : EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).padding.bottom + 12,
            ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tiêu đề card khi hiển thị trên tablet
          if (isCard) ...[
            Row(
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'THAO TÁC XỬ LÝ',
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
          ],
          // 1. Thu tiền phạt nếu có phạt chưa thanh toán
          if (hasUnpaidFine) ...[
            if (canManageSlip)
              FilledButton.icon(
                onPressed: onPayFine,
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: const Text('Ghi nhận đã thu tiền phạt'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Vui lòng liên hệ thủ thư để thanh toán tiền phạt.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            if (canApproveReject || canCancelSlip || canReturnBooks || canRenew)
              const SizedBox(height: 10),
          ],

          // 2. Thủ thư duyệt hoặc từ chối phiếu PENDING_APPROVAL
          if (canApproveReject)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onApprove,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Duyệt phiếu'),
                  ),
                ),
              ],
            ),

          // 3. Độc giả hủy phiếu khi đang PENDING_APPROVAL
          if (canCancelSlip)
            OutlinedButton.icon(
              key: const ValueKey('cancel_pending_slip_button'),
              onPressed: isCancelling ? null : onCancel,
              icon: isCancelling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                      ),
                    )
                  : const Icon(Icons.cancel_outlined, size: 18),
              label: Text(isCancelling ? 'Đang hủy...' : 'Hủy phiếu mượn'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFECACA)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

          // 4. Thủ thư xác nhận trả sách khi phiếu đang BORROWED hoặc PARTIAL_RETURNED
          if (canReturnBooks)
            FilledButton.icon(
              onPressed: onReturn,
              icon: const Icon(Icons.assignment_return, size: 18),
              label: const Text('Xác nhận trả sách'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

          // 5. Độc giả yêu cầu gia hạn phiếu khi đang mượn (được push xuống Action Bar)
          if (canRenew) ...[
            if (isRenewProcessing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      renewState is RenewSlipChecking
                          ? 'Đang kiểm tra điều kiện gia hạn...'
                          : 'Đang xử lý gia hạn...',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              )
            else if (slip.canRenew == true)
              FilledButton.icon(
                onPressed: onRenew,
                icon: const Icon(Icons.update, size: 18),
                label: const Text('Gia hạn'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            else if (slip.canRenew == false) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  slip.renewalMessage ??
                      mapRenewalReasonCode(slip.renewalReasonCode) ??
                      'Sách đang có người đặt trước, không thể gia hạn.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.update, size: 18),
                label: const Text('Gia hạn'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Chưa có thông tin gia hạn. Bấm để kiểm tra điều kiện.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onCheckEligibility,
                icon: const Icon(Icons.search, size: 18, color: Color(0xFF0D9488)),
                label: const Text('Kiểm tra gia hạn'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
