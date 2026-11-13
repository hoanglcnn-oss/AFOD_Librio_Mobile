import 'package:flutter/material.dart';

import '../../../shared/models/borrowing_slip.dart';

class CancelSlipDialogResult {
  final String? reason;

  const CancelSlipDialogResult({this.reason});
}

class CancelSlipDialog extends StatefulWidget {
  final BorrowingSlip slip;

  const CancelSlipDialog({
    super.key,
    required this.slip,
  });

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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bạn có chắc chắn muốn hủy phiếu mượn ${widget.slip.slipNumber}?'),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Lý do hủy (tùy chọn)',
              border: OutlineInputBorder(),
              hintText: 'Nhập lý do hủy...',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
        FilledButton(
          key: const ValueKey('confirm_cancel_slip_button'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () {
            final trimmed = _reasonController.text.trim();
            Navigator.of(context).pop(
              CancelSlipDialogResult(
                reason: trimmed.isNotEmpty ? trimmed : null,
              ),
            );
          },
          child: const Text('Xác nhận hủy'),
        ),
      ],
    );
  }
}
