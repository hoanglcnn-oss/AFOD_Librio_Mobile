import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/app_toast.dart';
import '../../../slip_management/bloc/slip_management_bloc.dart';
import '../../../slip_management/bloc/slip_management_event.dart';
import '../../../slip_management/bloc/slip_management_state.dart';
import '../../../shared/repositories/borrowing_slips_repository.dart';
import '../../../shared/models/borrowing_slip.dart';

Future<bool?> showSlipDecisionDialog(
  BuildContext context, {
  required BorrowingSlip slip,
  required BorrowingSlipsRepository repository,
  required bool approve,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider(
      create: (_) => ApproveSlipBloc(repository: repository),
      child: SlipDecisionDialog(slip: slip, approve: approve),
    ),
  );
}

class SlipDecisionDialog extends StatefulWidget {
  final BorrowingSlip slip;
  final bool approve;

  const SlipDecisionDialog({
    super.key,
    required this.slip,
    required this.approve,
  });

  @override
  State<SlipDecisionDialog> createState() => _SlipDecisionDialogState();
}

class _SlipDecisionDialogState extends State<SlipDecisionDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final bloc = context.read<ApproveSlipBloc>();

    if (widget.approve) {
      bloc.add(ApproveSlipRequested(widget.slip.id));
      return;
    }

    bloc.add(
      RejectSlipRequested(
        slipId: widget.slip.id,
        reason: _reasonController.text,
      ),
    );
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
    return widget.slip.memberId;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ApproveSlipBloc, ApproveSlipState>(
      listener: (context, state) {
        if (state is ApproveSlipSuccess) {
          final message = state.slip.status == 'BORROWED'
              ? 'Đã duyệt phiếu thành công'
              : 'Đã từ chối phiếu';

          AppToast.success(context, message);

          Navigator.of(context).pop(true);
        }

        if (state is ApproveSlipFailure && state.requiresRefresh) {
          AppToast.error(context, state.message);

          // Không thử lại trên dữ liệu cũ.
          // Đóng dialog và yêu cầu GET danh sách mới.
          Navigator.of(context).pop(true);
        }

        if (state is ApproveSlipLimitExceeded) {
          AppToast.warning(context, state.message);
        }
      },
      builder: (context, state) {
        final submitting = state is ApproveSlipSubmitting;
        final isLimitExceeded = state is ApproveSlipLimitExceeded;

        return PopScope(
          canPop: !submitting,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            title: Text(
              widget.approve ? 'Xác nhận duyệt phiếu' : 'Từ chối phiếu mượn',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mã phiếu: ${widget.slip.slipNumber}',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Độc giả: ${_resolveMemberDisplay()}',
                    style: const TextStyle(color: Color(0xFF334155)),
                  ),
                  Text(
                    'Số bản sách: '
                    '${widget.slip.items.fold<int>(0, (sum, item) => sum + item.quantity)}',
                    style: const TextStyle(color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 16),
                  if (widget.approve)
                    const Text(
                      'Duyệt phiếu sẽ xuất kho và '
                      'chuyển trạng thái sang "Đã mượn".',
                      style: TextStyle(color: Color(0xFF334155)),
                    )
                  else
                    TextField(
                      controller: _reasonController,
                      enabled: !submitting,
                      autofocus: true,
                      maxLines: 3,
                      maxLength: 500,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        labelText: 'Lý do từ chối',
                        labelStyle: const TextStyle(color: Color(0xFF64748B)),
                        hintText: 'Nhập lý do cụ thể',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                        ),
                      ),
                    ),
                  if (state is ApproveSlipFailure &&
                      !state.requiresRefresh) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                  if (state is ApproveSlipLimitExceeded) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFECACA),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFDC2626),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Không thể duyệt: Vượt hạn mức',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (state.details != null &&
                              state.details!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            if (state.details!['maxBorrowLimit'] != null)
                              Text(
                                '• Hạn mức tối đa: ${state.details!['maxBorrowLimit']} cuốn',
                              ),
                            if (state.details!['currentBorrowedCount'] != null)
                              Text(
                                '• Đang mượn: ${state.details!['currentBorrowedCount']} cuốn',
                              ),
                            if (state.details!['remainingBorrowLimit'] != null)
                              Text(
                                '• Hạn mức còn lại: ${state.details!['remainingBorrowLimit']} cuốn',
                              ),
                            if (state.details!['requestQuantity'] != null ||
                                state.details!['quantity'] != null)
                              Text(
                                '• Số lượng yêu cầu: ${state.details!['requestQuantity'] ?? state.details!['quantity']} cuốn',
                              ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            state.remediation,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (submitting) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting
                    ? null
                    : () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                ),
                child: Text(isLimitExceeded ? 'Đóng' : 'Hủy'),
              ),
              if (!isLimitExceeded)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.approve
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: submitting ? null : _submit,
                  child: Text(
                    submitting
                        ? 'Đang xử lý...'
                        : widget.approve
                        ? 'Xác nhận duyệt'
                        : 'Xác nhận từ chối',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
