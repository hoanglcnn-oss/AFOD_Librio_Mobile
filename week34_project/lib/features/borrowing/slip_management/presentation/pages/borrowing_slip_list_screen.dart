import 'package:flutter/material.dart';

import '../../../shared/repositories/borrowing_slips_repository.dart';
import '../../../shared/models/paginated_borrowing_slips.dart';
import '../widgets/borrowing_slip_card.dart';
import 'borrowing_slip_detail_screen.dart';

class BorrowingSlipsScreen extends StatefulWidget {
  final BorrowingSlipsRepository repository;
  final String? memberId;
  final VoidCallback? onReturnSucceeded;

  const BorrowingSlipsScreen({
    super.key,
    required this.repository,
    this.memberId,
    this.onReturnSucceeded,
  });

  @override
  State<BorrowingSlipsScreen> createState() => _BorrowingSlipsScreenState();
}

class _BorrowingSlipsScreenState extends State<BorrowingSlipsScreen> {
  static const List<({String label, String? value})> _statusFilters = [
    (label: 'Tất cả', value: null),
    (label: 'Chờ duyệt', value: 'PENDING_APPROVAL'),
    (label: 'Đang mượn', value: 'BORROWED'),
    (label: 'Đã trả một phần', value: 'PARTIAL_RETURNED'),
    (label: 'Đã hoàn tất', value: 'COMPLETED'),
    (label: 'Bị từ chối', value: 'REJECTED'),
    (label: 'Đã hủy', value: 'CANCELLED'),
  ];

  late Future<PaginatedBorrowingSlips> _future;
  String? _selectedStatus;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final memberId = widget.memberId?.trim();
    if (memberId != null && memberId.isNotEmpty) {
      _future = widget.repository.getBorrowingSlips(
        memberId: memberId,
        status: _selectedStatus,
        page: _page,
      );
    } else {
      _future = widget.repository.getAllBorrowingSlips(
        status: _selectedStatus,
        page: _page,
      );
    }
  }

  Future<void> _refresh({bool resetPage = false}) async {
    setState(() {
      if (resetPage) _page = 1;
      _load();
    });

    try {
      await _future;
    } catch (_) {
      // FutureBuilder sẽ hiển thị thông báo lỗi và nút thử lại
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

    if (mounted) {
      await _refresh();
      widget.onReturnSucceeded?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLibrarian =
        widget.memberId == null || widget.memberId!.trim().isEmpty;

    return Column(
      children: [
        // Thanh bộ lọc trạng thái dùng chung
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
          child: FutureBuilder<PaginatedBorrowingSlips>(
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

                                return BorrowingSlipCard(
                                  slip: slip,
                                  showMember: isLibrarian,
                                  onTap: () => _openDetail(slip.id),
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
