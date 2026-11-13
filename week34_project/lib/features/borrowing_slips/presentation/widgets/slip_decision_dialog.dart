import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_toast.dart';
import '../../bloc/approve_slip_bloc.dart';
import '../../bloc/approve_slip_event.dart';
import '../../bloc/approve_slip_state.dart';
import '../../../borrowing/shared/repositories/borrowing_slips_repository.dart';
import '../../../borrowing/shared/models/borrowing_slip.dart';

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
            title: Text(
              widget.approve ? 'Xác nhận duyệt phiếu' : 'Từ chối phiếu mượn',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mã phiếu: ${widget.slip.slipNumber}'),
                  const SizedBox(height: 8),
                  Text('Độc giả: ${_resolveMemberDisplay()}'),
                  Text(
                    'Số bản sách: '
                    '${widget.slip.items.fold<int>(0, (sum, item) => sum + item.quantity)}',
                  ),
                  const SizedBox(height: 16),
                  if (widget.approve)
                    const Text(
                      'Duyệt phiếu sẽ xuất kho và '
                      'chuyển trạng thái sang BORROWED.',
                    )
                  else
                    TextField(
                      controller: _reasonController,
                      enabled: !submitting,
                      autofocus: true,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Lý do từ chối',
                        hintText: 'Nhập lý do cụ thể',
                      ),
                    ),
                  if (state is ApproveSlipFailure &&
                      !state.requiresRefresh) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (state is ApproveSlipLimitExceeded) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .errorContainer
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Theme.of(context).colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Không thể duyệt: Vượt hạn mức',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
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
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: Text(isLimitExceeded ? 'Đóng' : 'Hủy'),
              ),
              if (!isLimitExceeded)
                FilledButton(
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
