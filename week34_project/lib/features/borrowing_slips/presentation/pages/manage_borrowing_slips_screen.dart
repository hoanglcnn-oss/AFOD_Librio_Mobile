import 'package:flutter/material.dart';

import '../../data/borrowing_slips_repository.dart';
import '../../data/models/borrowing_slip.dart';
import '../../data/models/paginated_borrowing_slips.dart';
import '../widgets/borrowing_slip_card.dart';
import '../widgets/slip_decision_dialog.dart';
import 'borrowing_slip_detail_screen.dart';

class ManageBorrowingSlipsScreen extends StatefulWidget {
  final BorrowingSlipsRepository repository;

  const ManageBorrowingSlipsScreen({super.key, required this.repository});

  @override
  State<ManageBorrowingSlipsScreen> createState() =>
      _ManageBorrowingSlipsScreenState();
}

class _ManageBorrowingSlipsScreenState
    extends State<ManageBorrowingSlipsScreen> {
  static const List<({String label, String? value})> _statusFilters = [
    (label: 'Tất cả', value: null),
    (label: 'Chờ duyệt', value: 'PENDING_APPROVAL'),
    (label: 'Đang mượn', value: 'BORROWED'),
    (label: 'Đã trả một phần', value: 'PARTIAL_RETURNED'),
    (label: 'Đã hoàn tất', value: 'COMPLETED'),
    (label: 'Bị từ chối', value: 'REJECTED'),
    (label: 'Đã hủy', value: 'CANCELLED'),
  ];

  late Future<BorrowingSlipsPage> _future;
  String? _selectedStatus;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.repository.getAllBorrowingSlips(
      status: _selectedStatus,
      page: _page,
    );
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

  void _onStatusSelected(String? status) {
    if (_selectedStatus == status) return;
    setState(() {
      _selectedStatus = status;
      _page = 1;
      _load();
    });
  }

  void _changePage(int nextPage) {
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
    return Column(
      children: [
        // Thanh bộ lọc trạng thái
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: _statusFilters.map((filter) {
                final isSelected = _selectedStatus == filter.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    label: Text(filter.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _onStatusSelected(filter.value);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        Expanded(
          child: FutureBuilder<BorrowingSlipsPage>(
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
                      const Text('Không thể tải danh sách phiếu mượn'),
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tổng số: ${result.totalItems} phiếu',
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
                                SizedBox(height: 80),
                                Icon(Icons.assignment_outlined, size: 52),
                                SizedBox(height: 16),
                                Center(child: Text('Không có phiếu mượn nào')),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(12),
                              itemCount: result.slips.length,
                              itemBuilder: (context, index) {
                                final slip = result.slips[index];

                                final isPending =
                                    slip.status == 'PENDING_APPROVAL';

                                return BorrowingSlipCard(
                                  slip: slip,
                                  showMember: true,
                                  onTap: () => _openDetail(slip.id),
                                  actions: isPending
                                      ? Wrap(
                                          alignment: WrapAlignment.end,
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            OutlinedButton(
                                              onPressed: () => _processSlip(
                                                slip,
                                                approve: false,
                                              ),
                                              child: const Text('Từ chối'),
                                            ),
                                            FilledButton.icon(
                                              onPressed: () => _processSlip(
                                                slip,
                                                approve: true,
                                              ),
                                              icon: const Icon(
                                                Icons.check,
                                                size: 18,
                                              ),
                                              label: const Text('Duyệt phiếu'),
                                            ),
                                          ],
                                        )
                                      : null,
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
          ),
        ),
      ],
    );
  }
}

