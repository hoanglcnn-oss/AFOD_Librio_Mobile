import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/borrowing_repository.dart';
import '../../data/models/borrowing_slip.dart';
import '../widgets/borrowing_slip_item_card.dart';
import '../widgets/borrowing_slip_ui_helper.dart';
import '../widgets/slip_decision_dialog.dart';
import 'borrowing_slip_return_screen.dart';
import '../../../auth/data/models/app_role.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import 'pay_slip_fine_screen.dart';

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

  Future<void> _openReturn(BorrowingSlip slip) async {
    final returned = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BorrowingSlipReturnScreen(
          slip: slip,
          repository: widget.repository,
        ),
      ),
    );

    if (!mounted) return;

    // Luôn lấy lại dữ liệu Backend khi quay về,
    // kể cả khi user thoát mà chưa xác nhận.
    _refresh();

    if (returned == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã ghi nhận trả sách thành công')),
      );
    }
  }

  Future<void> _openPayFine(BorrowingSlip slip) async {
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            PaySlipFineScreen(slip: slip, repository: widget.repository),
      ),
    );

    if (!mounted) return;

    // Không tin trạng thái cũ; gọi API lại để xác minh.
    _refresh();

    if (paid == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã ghi nhận thanh toán tiền phạt')),
      );
    }
  }

  Future<void> _processSlip(BorrowingSlip slip, {required bool approve}) async {
    final shouldRefresh = await showSlipDecisionDialog(
      context,
      slip: slip,
      repository: widget.repository,
      approve: approve,
    );

    if (!mounted) return;

    if (shouldRefresh == true) {
      _refresh();
    }
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

          final authState = context.read<AuthBloc>().state;
          final role = authState is AuthAuthenticated
              ? authState.user.role.toUpperCase()
              : '';

          final canManageSlip = AppRole.fromString(
            role,
          ).canManageBorrowingSlips;
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
                Text('Độc giả: ${slip.memberId}'),
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

                if (BorrowingSlipUiHelper.hasUnpaidFine(slip)) ...[
                  const SizedBox(height: 12),
                  if (canManageSlip)
                    FilledButton.icon(
                      onPressed: () => _openPayFine(slip),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Ghi nhận đã thu tiền phạt'),
                    )
                  else
                    const Text(
                      'Vui lòng liên hệ thủ thư để thanh toán tiền phạt.',
                    ),
                ],

                if (canManageSlip && slip.status == 'PENDING_APPROVAL') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _processSlip(slip, approve: false),
                          child: const Text('Từ chối'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _processSlip(slip, approve: true),
                          icon: const Icon(Icons.check),
                          label: const Text('Duyệt phiếu'),
                        ),
                      ),
                    ],
                  ),
                ],

                if (canManageSlip &&
                    (slip.status == 'BORROWED' ||
                        slip.status == 'PARTIAL_RETURNED') &&
                    slip.items.any((item) => item.remainingQuantity > 0)) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _openReturn(slip),
                    icon: const Icon(Icons.assignment_return),
                    label: const Text('Xác nhận trả sách'),
                  ),
                ],

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
