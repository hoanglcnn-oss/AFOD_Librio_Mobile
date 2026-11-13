import 'package:flutter/material.dart';

import '../../../shared/repositories/borrowing_slips_repository.dart';
import '../../../shared/models/borrowing_slip.dart';
import '../../../shared/models/paginated_borrowing_slips.dart';
import '../../../../borrowing_slips/presentation/widgets/borrowing_slip_card.dart';
import '../widgets/slip_decision_dialog.dart';
import '../../../../borrowing_slips/presentation/pages/borrowing_slip_detail_screen.dart';

class PendingBorrowingSlipsScreen extends StatefulWidget {
  final BorrowingSlipsRepository repository;

  const PendingBorrowingSlipsScreen({super.key, required this.repository});

  @override
  State<PendingBorrowingSlipsScreen> createState() =>
      _PendingBorrowingSlipsScreenState();
}

class _PendingBorrowingSlipsScreenState
    extends State<PendingBorrowingSlipsScreen> {
  late Future<PaginatedBorrowingSlips> _future;
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
    final shouldRefresh = await showSlipDecisionDialog(
      context,
      slip: slip,
      repository: widget.repository,
      approve: approve,
    );

    if (!mounted) return;

    if (shouldRefresh == true) {
      await _refresh(resetPage: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PaginatedBorrowingSlips>(
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

                          return BorrowingSlipCard(
                            slip: slip,
                            showMember: true,
                            onTap: () => _openDetail(slip.id),
                            actions: Wrap(
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
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Duyệt phiếu'),
                                ),
                              ],
                            ),
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
