import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/app_toast.dart';
import '../../bloc/slip_management_bloc.dart';
import '../../bloc/slip_management_event.dart';
import '../../bloc/slip_management_state.dart';
import '../../../shared/models/borrowing_slip.dart';
import '../../../shared/repositories/borrowing_slips_repository.dart';

/// Kết quả trả về từ dialog hủy phiếu mượn
class CancelSlipDialogResult {
  final String? reason;

  const CancelSlipDialogResult({this.reason});
}

/// Helper hiển thị dialog duyệt phiếu mượn
Future<bool?> showApproveSlipDialog(
  BuildContext context, {
  required BorrowingSlip slip,
  required BorrowingSlipsRepository repository,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ApproveSlipDialog(slip: slip, repository: repository),
  );
}

/// Helper hiển thị dialog hủy phiếu mượn
Future<CancelSlipDialogResult?> showCancelSlipDialog(
  BuildContext context, {
  required BorrowingSlip slip,
}) {
  return showDialog<CancelSlipDialogResult>(
    context: context,
    builder: (_) => CancelSlipDialog(slip: slip),
  );
}

/// Dialog xác nhận duyệt phiếu mượn (dành cho Thủ thư)
class ApproveSlipDialog extends StatelessWidget {
  final BorrowingSlip slip;
  final BorrowingSlipsRepository repository;

  const ApproveSlipDialog({
    super.key,
    required this.slip,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApproveSlipBloc(repository: repository),
      child: _ApproveSlipDialogContent(slip: slip),
    );
  }
}

class _ApproveSlipDialogContent extends StatefulWidget {
  final BorrowingSlip slip;

  const _ApproveSlipDialogContent({required this.slip});

  @override
  State<_ApproveSlipDialogContent> createState() =>
      _ApproveSlipDialogContentState();
}

class _ApproveSlipDialogContentState extends State<_ApproveSlipDialogContent> {
  late final TextEditingController _reasonController;
  bool _isRejectMode = false;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
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
    return widget.slip.memberId;
  }

  String _buildPrefilledReason(ApproveSlipLimitExceeded state) {
    final max = state.details?['maxBorrowLimit'];
    final current = state.details?['currentBorrowedCount'];
    if (max != null && current != null) {
      return 'Vượt hạn mức mượn sách ($current/$max cuốn). Vui lòng trả bớt sách hoặc tạo lại phiếu với số lượng phù hợp.';
    }
    return 'Vượt hạn mức mượn sách. Vui lòng trả bớt sách hoặc tạo lại phiếu với số lượng phù hợp.';
  }

  @override
  Widget build(BuildContext context) {
    final totalCopies = widget.slip.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

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
          Navigator.of(context).pop(true);
        }

        if (state is ApproveSlipLimitExceeded) {
          AppToast.warning(context, state.message);
        }
      },
      builder: (context, state) {
        final submitting = state is ApproveSlipSubmitting;
        final isLimitExceeded = state is ApproveSlipLimitExceeded;

        if (_isRejectMode) {
          return PopScope(
            canPop: !submitting,
            child: AlertDialog(
              title: const Text('Từ chối phiếu mượn'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mã phiếu: ${widget.slip.slipNumber}'),
                    const SizedBox(height: 8),
                    Text('Độc giả: ${_resolveMemberDisplay()}'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _reasonController,
                      enabled: !submitting,
                      autofocus: true,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Lý do từ chối',
                        hintText: 'Nhập lý do cụ thể',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (state is ApproveSlipFailure &&
                        !state.requiresRefresh) ...[
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
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
                      : () => setState(() => _isRejectMode = false),
                  child: const Text('Quay lại'),
                ),
                FilledButton(
                  key: const ValueKey('confirm_reject_from_exceeded_button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: submitting
                      ? null
                      : () => context.read<ApproveSlipBloc>().add(
                            RejectSlipRequested(
                              slipId: widget.slip.id,
                              reason: _reasonController.text,
                            ),
                          ),
                  child: Text(submitting ? 'Đang xử lý...' : 'Xác nhận từ chối'),
                ),
              ],
            ),
          );
        }

        return PopScope(
          canPop: !submitting,
          child: AlertDialog(
            title: const Text('Xác nhận duyệt phiếu'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mã phiếu: ${widget.slip.slipNumber}'),
                  const SizedBox(height: 8),
                  Text('Độc giả: ${_resolveMemberDisplay()}'),
                  Text('Số bản sách: $totalCopies'),
                  const SizedBox(height: 16),
                  const Text(
                    'Duyệt phiếu sẽ xuất kho và '
                    'chuyển trạng thái sang BORROWED.',
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

                  //nếu duyệt phải phiếu gây quá hạn mức
                  if (state is ApproveSlipLimitExceeded) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.errorContainer.withValues(alpha: 0.2),
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
              if (isLimitExceeded)
                TextButton(
                  key: const ValueKey('reject_exceeded_slip_button'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: submitting
                      ? null
                      : () {
                          setState(() {
                            _isRejectMode = true;
                            _reasonController.text =
                                _buildPrefilledReason(state);
                          });
                        },
                  child: const Text('Từ chối'),
                ),
              TextButton(
                onPressed: submitting
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: Text(isLimitExceeded ? 'Đóng' : 'Hủy'),
              ),
              if (!isLimitExceeded)
                FilledButton(
                  key: const ValueKey('confirm_approve_slip_button'),
                  onPressed: submitting
                      ? null
                      : () => context.read<ApproveSlipBloc>().add(
                          ApproveSlipRequested(widget.slip.id),
                        ),
                  child: Text(submitting ? 'Đang xử lý...' : 'Xác nhận duyệt'),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Dialog xác nhận hủy phiếu mượn (dành cho Độc giả)
class CancelSlipDialog extends StatefulWidget {
  final BorrowingSlip slip;

  const CancelSlipDialog({super.key, required this.slip});

  @override
  State<CancelSlipDialog> createState() => _CancelSlipDialogState();
}

class _CancelSlipDialogState extends State<CancelSlipDialog> {
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hủy phiếu mượn'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn hủy phiếu mượn ${widget.slip.slipNumber}?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do hủy (tùy chọn)',
                hintText: 'Nhập lý do nếu có',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
        FilledButton(
          key: const ValueKey('confirm_cancel_slip_button'),
          onPressed: () {
            final reason = _reasonController.text.trim();
            Navigator.of(context).pop(
              CancelSlipDialogResult(reason: reason.isEmpty ? null : reason),
            );
          },
          child: const Text('Xác nhận hủy'),
        ),
      ],
    );
  }
}
