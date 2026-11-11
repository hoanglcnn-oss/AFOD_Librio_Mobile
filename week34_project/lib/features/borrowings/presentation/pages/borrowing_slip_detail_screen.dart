import 'package:flutter/material.dart';

import '../../data/borrowing_repository.dart';
import '../../data/models/borrowing_slip.dart';
import '../widgets/borrowing_slip_item_card.dart';
import '../widgets/borrowing_slip_ui_helper.dart';

class BorrowingSlipDetailScreen extends StatefulWidget {
  final String slipId;
  final BorrowingRepository repository;

  const BorrowingSlipDetailScreen({
    super.key,
    required this.slipId,
    required this.repository,
  });

  @override
  State<BorrowingSlipDetailScreen> createState() =>
      _BorrowingSlipDetailScreenState();
}

class _BorrowingSlipDetailScreenState extends State<BorrowingSlipDetailScreen> {
  late Future<BorrowingSlip> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.repository.getBorrowingSlipById(slipId: widget.slipId);
  }

  void _refresh() {
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết phiếu mượn')),
      body: FutureBuilder<BorrowingSlip>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Không thể tải chi tiết phiếu'),
                  TextButton(onPressed: _refresh, child: const Text('Thử lại')),
                ],
              ),
            );
          }

          final slip = snapshot.data!;
          final overdue = BorrowingSlipUiHelper.isOverdue(slip);

          return RefreshIndicator(
            onRefresh: () async {
              _refresh();
              await _future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  slip.slipNumber,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Trạng thái: '
                  '${BorrowingSlipUiHelper.slipStatus(slip.status)}',
                ),
                Text(
                  'Hạn trả: '
                  '${BorrowingSlipUiHelper.formatDate(slip.dueDate)}',
                ),
                if (overdue) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Phiếu có sách chưa trả và đã quá hạn',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Danh sách sách',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final item in slip.items)
                  BorrowingSlipItemCard(item: item, isOverdue: overdue),
                const SizedBox(height: 16),
                const Divider(),
                Text(
                  'Tổng tiền phạt: '
                  '${BorrowingSlipUiHelper.formatMoney(slip.totalFine)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (slip.totalFine > 0)
                  Text(
                    slip.finePaid
                        ? 'Đã thanh toán tiền phạt'
                        : 'Chưa thanh toán tiền phạt',
                    style: TextStyle(
                      color: slip.finePaid
                          ? Colors.green
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Cập nhật trạng thái phiếu'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
