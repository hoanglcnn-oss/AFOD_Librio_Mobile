import 'package:flutter/material.dart';
import 'package:week34_project/features/books/data/models/book.dart';

class BorrowConfirmCard extends StatelessWidget {
  final Book book;
  final String memberId;
  final bool isSubmitting;
  final bool isSuccess;
  final VoidCallback onConfirm;

  const BorrowConfirmCard({
    super.key,
    required this.book,
    required this.memberId,
    required this.isSubmitting,
    required this.isSuccess,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(book.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text('Tác giả: ${book.authorName}'),
            Text('Số lượng còn: ${book.copiesAvailable}'),
            const SizedBox(height: 24),
            const ListTile(
              leading: Icon(Icons.event),
              title: Text('Thời hạn mượn'),
              subtitle: Text('14 ngày'),
            ),
            const ListTile(
              leading: Icon(Icons.verified_user_outlined),
              title: Text('Hồ sơ độc giả'),
              subtitle: Text('Đã xác định'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isSubmitting || isSuccess || !book.canBorrow
                  ? null
                  : onConfirm,
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Xác nhận mượn'),
            ),
          ],
        ),
      ),
    );
  }
}
