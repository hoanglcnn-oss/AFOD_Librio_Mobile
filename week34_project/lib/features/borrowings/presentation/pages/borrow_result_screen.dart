import 'package:flutter/material.dart';

import '../../data/models/borrowing.dart';

class BorrowResultScreen extends StatelessWidget {
  final Borrowing borrowing;

  const BorrowResultScreen({super.key, required this.borrowing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả mượn sách'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.check_circle, size: 72, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'Mượn sách thành công!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Mã phiếu mượn'),
                subtitle: Text(borrowing.transactionCode),
              ),
              ListTile(
                title: const Text('Tên sách'),
                subtitle: Text(borrowing.bookTitle),
              ),
              ListTile(
                title: const Text('Người mượn'),
                subtitle: Text(borrowing.memberName),
              ),
              ListTile(
                title: const Text('Ngày mượn'),
                subtitle: Text(_formatDate(borrowing.borrowDate)),
              ),
              ListTile(
                title: const Text('Hạn trả'),
                subtitle: Text(_formatDate(borrowing.dueDate)),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('Quay về danh sách sách'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year}';
  }
}

