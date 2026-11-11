import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/approve_slip_bloc.dart';
import '../../bloc/approve_slip_event.dart';
import '../../bloc/approve_slip_state.dart';
import '../../data/borrowing_repository.dart';
import '../../data/models/borrowing_slip.dart';
import '../../data/models/borrowing_slips_page.dart';
import '../widgets/borrowing_slip_card.dart';
import 'borrowing_slip_detail_screen.dart';

class PendingBorrowingSlipsScreen extends StatefulWidget {
  final BorrowingRepository repository;

  const PendingBorrowingSlipsScreen({super.key, required this.repository});

  @override
  State<PendingBorrowingSlipsScreen> createState() =>
      _PendingBorrowingSlipsScreenState();
}

class _PendingBorrowingSlipsScreenState
    extends State<PendingBorrowingSlipsScreen> {
  late Future<BorrowingSlipsPage> _future;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.repository.getPendingBorrowingSlips(page: _page);
  }

  Future<void> _refresh({bool resetPage = false}) async {
    setState(() {
      if (resetPage) _page = 1;
      _load();
    });

    try {
      await _future;
    } catch (_) {
      // FutureBuilder sẽ hiển thị lỗi và nút thử lại.
    }
  }

  Future<void> _changePage(int nextPage) async {
    if (nextPage < 1) return;

    setState(() {
      _page = nextPage;
      _load();
    });
  }

  Future<void> _openDetail(String slipId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BorrowingSlipDetailScreen(
          slipId: slipId,
          repository: widget.repository,
        ),
      ),
    );

    if (mounted) await _refresh();
  }

  Future<void> _processSlip(BorrowingSlip slip, {required bool approve}) async {
    final shouldRefresh = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider(
        create: (_) => ApproveSlipBloc(repository: widget.repository),
        child: _SlipDecisionDialog(slip: slip, approve: approve),
      ),
    );

    if (!mounted) return;

    if (shouldRefresh == true) {
      await _refresh(resetPage: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BorrowingSlipsPage>(
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
                const Text('Không thể tải phiếu chờ duyệt'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final result = snapshot.data!;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đang chờ: ${result.totalItems} phiếu',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tải lại',
                    onPressed: () => _refresh(),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _refresh(),
                child: result.slips.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 100),
                          Icon(Icons.task_alt, size: 52),
                          SizedBox(height: 16),
                          Center(child: Text('Không có phiếu chờ duyệt')),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        itemCount: result.slips.length,
                        itemBuilder: (context, index) {
                          final slip = result.slips[index];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              BorrowingSlipCard(
                                slip: slip,
                                onTap: () => _openDetail(slip.id),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                                child: Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () =>
                                          _processSlip(slip, approve: false),
                                      child: const Text('Từ chối'),
                                    ),
                                    FilledButton.icon(
                                      onPressed: () =>
                                          _processSlip(slip, approve: true),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Duyệt phiếu'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),
            if (result.totalPages > 1)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Trang trước',
                      onPressed: _page <= 1
                          ? null
                          : () => _changePage(_page - 1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('Trang $_page/${result.totalPages}'),
                    IconButton(
                      tooltip: 'Trang sau',
                      onPressed: result.hasNextPage
                          ? () => _changePage(_page + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// Mỗi lần mở dialog sẽ sử dụng một ApproveSlipBloc mới.
class _SlipDecisionDialog extends StatefulWidget {
  final BorrowingSlip slip;
  final bool approve;

  const _SlipDecisionDialog({required this.slip, required this.approve});

  @override
  State<_SlipDecisionDialog> createState() => _SlipDecisionDialogState();
}

class _SlipDecisionDialogState extends State<_SlipDecisionDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final bloc = context.read<ApproveSlipBloc>();

    if (widget.approve) {
      bloc.add(ApproveSlipRequested(widget.slip.id));
      return;
    }

    bloc.add(
      RejectSlipRequested(
        slipId: widget.slip.id,
        reason: _reasonController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ApproveSlipBloc, ApproveSlipState>(
      listener: (context, state) {
        if (state is ApproveSlipSuccess) {
          final message = state.slip.status == 'BORROWED'
              ? 'Đã duyệt phiếu thành công'
              : 'Đã từ chối phiếu';

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));

          Navigator.of(context).pop(true);
        }

        if (state is ApproveSlipFailure && state.requiresRefresh) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));

          // Không thử lại trên dữ liệu cũ.
          // Đóng dialog và yêu cầu GET danh sách mới.
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        final submitting = state is ApproveSlipSubmitting;

        return PopScope(
          canPop: !submitting,
          child: AlertDialog(
            title: Text(
              widget.approve ? 'Xác nhận duyệt phiếu' : 'Từ chối phiếu mượn',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mã phiếu: ${widget.slip.slipNumber}'),
                  const SizedBox(height: 8),
                  Text('Độc giả: ${widget.slip.memberId}'),
                  Text(
                    'Số bản sách: '
                    '${widget.slip.items.fold<int>(0, (sum, item) => sum + item.quantity)}',
                  ),
                  const SizedBox(height: 16),
                  if (widget.approve)
                    const Text(
                      'Duyệt phiếu sẽ xuất kho và '
                      'chuyển trạng thái sang BORROWED.',
                    )
                  else
                    TextField(
                      controller: _reasonController,
                      enabled: !submitting,
                      autofocus: true,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Lý do từ chối',
                        hintText: 'Nhập lý do cụ thể',
                      ),
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
                    : () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: submitting ? null : _submit,
                child: Text(
                  submitting
                      ? 'Đang xử lý...'
                      : widget.approve
                      ? 'Xác nhận duyệt'
                      : 'Xác nhận từ chối',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
