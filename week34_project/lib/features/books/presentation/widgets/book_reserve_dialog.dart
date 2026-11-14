import 'package:flutter/material.dart';

import '../../data/models/book.dart';

class BookReserveDialogResult {
  final String? notes;

  const BookReserveDialogResult({this.notes});
}

class BookReserveDialog extends StatefulWidget {
  final Book book;

  const BookReserveDialog({
    super.key,
    required this.book,
  });

  @override
  State<BookReserveDialog> createState() => _BookReserveDialogState();
}

class _BookReserveDialogState extends State<BookReserveDialog> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đặt trước sách'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bạn có muốn đặt trước cuốn sách "${widget.book.title}"?'),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Ghi chú (tùy chọn)',
              border: OutlineInputBorder(),
              hintText: 'Nhập ghi chú cho thư viện...',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            final trimmed = _notesController.text.trim();
            Navigator.of(context).pop(
              BookReserveDialogResult(
                notes: trimmed.isNotEmpty ? trimmed : null,
              ),
            );
          },
          child: const Text('Xác nhận đặt trước'),
        ),
      ],
    );
  }
}
