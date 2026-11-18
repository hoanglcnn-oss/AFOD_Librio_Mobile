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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.white,
      title: const Text(
        'Hủy đặt trước',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bạn có chắc chắn muốn hủy đặt trước cuốn sách "${widget.reservation.bookTitle}"?',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF334155),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              labelText: 'Lý do hủy (tùy chọn)',
              labelStyle: const TextStyle(color: Color(0xFF64748B)),
              hintText: 'Nhập lý do hủy...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
              ),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF64748B),
          ),
          child: const Text('Đóng'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
