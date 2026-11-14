import 'package:flutter/material.dart';

import '../../data/models/reservation.dart';

class CancelReservationDialogResult {
  final String? reason;

  const CancelReservationDialogResult({this.reason});
}

class CancelReservationDialog extends StatefulWidget {
  final Reservation reservation;

  const CancelReservationDialog({
    super.key,
    required this.reservation,
  });

  @override
  State<CancelReservationDialog> createState() =>
      _CancelReservationDialogState();
}

class _CancelReservationDialogState extends State<CancelReservationDialog> {
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
      title: const Text('Hủy đặt trước'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bạn có chắc chắn muốn hủy đặt trước cuốn sách "${widget.reservation.bookTitle}"?',
          ),
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
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () {
            final trimmed = _reasonController.text.trim();
            Navigator.of(context).pop(
              CancelReservationDialogResult(
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
