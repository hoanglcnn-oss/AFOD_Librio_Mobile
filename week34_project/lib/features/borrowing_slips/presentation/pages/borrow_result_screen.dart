import 'package:flutter/material.dart';

import '../../data/models/borrowing_slip.dart';

class BorrowResultScreen extends StatelessWidget {
  final BorrowingSlip slip;

  const BorrowResultScreen({super.key, required this.slip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả gửi phiếu mượn'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.schedule, size: 72, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Đã gửi yêu cầu mượn, chờ thủ thư duyệt',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Phiếu của bạn đang ở trạng thái chờ duyệt. Vui lòng đợi thủ thư phê duyệt trước khi đến nhận sách.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Mã phiếu mượn'),
                subtitle: Text(slip.slipNumber),
              ),
              ListTile(
                title: const Text('Trạng thái'),
                subtitle: Text(
                  slip.status == 'PENDING_APPROVAL'
                      ? 'PENDING_APPROVAL (Chờ duyệt)'
                      : slip.status,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
              if (slip.memberName != null && slip.memberName!.isNotEmpty)
                ListTile(
                  title: const Text('Người mượn'),
                  subtitle: Text(slip.memberName!),
                ),
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Danh sách sách (${slip.items.length} đầu sách)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final item in slip.items)
                ListTile(
                  leading: const Icon(Icons.menu_book),
                  title: Text(item.bookTitle),
                  subtitle: Text('Số lượng: ${item.quantity} cuốn'),
                  trailing: Text(
                    item.status,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                key: const ValueKey('return_to_books_button'),
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
}
