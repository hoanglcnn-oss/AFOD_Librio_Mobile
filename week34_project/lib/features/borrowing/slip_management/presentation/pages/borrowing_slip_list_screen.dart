import 'package:flutter/material.dart';

import '../../../shared/models/borrowing_slip.dart';
import '../../../shared/repositories/borrowing_slips_repository.dart';
import '../../../shared/models/paginated_borrowing_slips.dart';
import '../widgets/slip_list_card.dart';
import 'borrowing_slip_detail_screen.dart';

class BorrowingSlipsScreen extends StatefulWidget {
  final BorrowingSlipsRepository repository;
  final String? memberId;
  final VoidCallback? onReturnSucceeded;
  final String? initialStatus;

  const BorrowingSlipsScreen({
    super.key,
    required this.repository,
    this.memberId,
    this.onReturnSucceeded,
    this.initialStatus,
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
  final _scrollController = ScrollController();
  final List<BorrowingSlip> _slips = [];
  int _requestVersion = 0;
  bool _hasNextPage = false;
  bool _isLoadingMore = false;
  bool _paginationError = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<PaginatedBorrowingSlips> _fetchPage(int page) {
    final memberId = widget.memberId?.trim();
    if (memberId != null && memberId.isNotEmpty) {
      return widget.repository.getBorrowingSlips(
        memberId: memberId,
        status: _selectedStatus,
        page: page,
      );
    } else {
      return widget.repository.getAllBorrowingSlips(
        status: _selectedStatus,
        page: page,
      );
    }
  }

  void _load() {
    final version = ++_requestVersion;
    _page = 1;
    _hasNextPage = false;
    _isLoadingMore = false;
    _paginationError = false;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _future = _fetchPage(1).then((result) {
      if (mounted && version == _requestVersion) {
        _slips
          ..clear()
          ..addAll(result.slips);
        _hasNextPage = result.hasNextPage;
      }
      return result;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _paginationError) return;
    if (_scrollController.position.extentAfter <= 200) _loadMore();
  }

  Future<void> _loadMore() async {
    if (!_hasNextPage || _isLoadingMore) return;
    final version = _requestVersion;
    setState(() {
      _isLoadingMore = true;
      _paginationError = false;
    });
    try {
      final result = await _fetchPage(_page + 1);
      if (!mounted || version != _requestVersion) return;
      setState(() {
        final ids = _slips.map((slip) => slip.id).toSet();
        _slips.addAll(result.slips.where((slip) => ids.add(slip.id)));
        _page++;
        _hasNextPage = result.hasNextPage;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _isLoadingMore = false;
        _paginationError = true;
      });
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
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
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
                    label: Text(
                      filter.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF334155),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0F172A),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFE2E8F0),
                    ),
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
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF0D9488),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Không thể tải danh sách phiếu mượn',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _refresh(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Tải lại',
                          onPressed: () => _refresh(),
                          icon: const Icon(
                            Icons.refresh,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: const Color(0xFF0D9488),
                      onRefresh: () => _refresh(),
                      child: _slips.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 80),
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 52,
                                  color: Color(0xFF94A3B8),
                                ),
                                SizedBox(height: 16),
                                Center(
                                  child: Text(
                                    'Không có phiếu mượn nào',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(12),
                              itemCount: _slips.length + 1,
                              itemBuilder: (context, index) {
                                if (index == _slips.length) {
                                  return _buildPaginationFooter();
                                }
                                final slip = _slips[index];

                                return BorrowingSlipCard(
                                  slip: slip,
                                  showMember: isLibrarian,
                                  onTap: () => _openDetail(slip.id),
                                );
                              },
                            ),
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

  Widget _buildPaginationFooter() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF0D9488),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Đang tải thêm...',
              style: TextStyle(fontSize: 13, color: Color(0xFF0D9488)),
            ),
          ],
        ),
      );
    }
    if (_paginationError) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Không thể tải thêm phiếu mượn.',
                style: TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
              ),
            ),
            TextButton(
              onPressed: _loadMore,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (!_hasNextPage) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Đã hiển thị tất cả phiếu mượn',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ),
            Expanded(child: Divider(color: Color(0xFFE2E8F0))),
          ],
        ),
      );
    }
    return Center(
      child: TextButton(
        onPressed: _loadMore,
        child: const Text('Tải thêm phiếu mượn'),
      ),
    );
  }
}
