import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../data/borrowing_repository.dart';
import '../../data/models/borrowing.dart';
import '../../data/models/paginated_borrowings.dart';
import '../widgets/borrowing_card.dart';
import '../widgets/borrowing_ui_helper.dart';

class ManageSingleBorrowingsScreen extends StatefulWidget {
  final BorrowingRepository repository;

  const ManageSingleBorrowingsScreen({super.key, required this.repository});

  @override
  State<ManageSingleBorrowingsScreen> createState() =>
      _ManageSingleBorrowingsScreenState();
}

class _ManageSingleBorrowingsScreenState
    extends State<ManageSingleBorrowingsScreen> {
  static const List<({String label, String? value})> _statusFilters = [
    (label: 'Tất cả', value: null),
    (label: 'Đang mượn', value: 'BORROWED'),
    (label: 'Quá hạn', value: 'OVERDUE'),
    (label: 'Đã trả', value: 'RETURNED'),
  ];

  late Future<PaginatedBorrowings> _future;
  String? _selectedStatus;
  int _page = 1;
  String? _processingBorrowingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.repository.getAllBorrowings(
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

  Future<void> _confirmReturn(Borrowing borrowing) async {
    bool finePaid = false;
    final isOverdue = borrowing.status == 'OVERDUE';
    final hasFine = borrowing.fineAmount != null && borrowing.fineAmount! > 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Xác nhận trả sách'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sách: ${borrowing.bookTitle}'),
                  const SizedBox(height: 4),
                  Text(
                    'Độc giả: ${borrowing.memberName.isNotEmpty ? borrowing.memberName : borrowing.memberId}',
                  ),
                  if (hasFine || isOverdue) ...[
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: finePaid,
                      onChanged: (val) {
                        setDialogState(() {
                          finePaid = val ?? false;
                        });
                      },
                      title: Text(
                        hasFine
                            ? 'Đã thu tiền phạt: ${BorrowingUiHelper.formatMoney(borrowing.fineAmount!)}'
                            : 'Đã thu tiền phạt quá hạn',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _processingBorrowingId = borrowing.id;
    });

    try {
      await widget.repository.returnBook(
        borrowingId: borrowing.id,
        finePaid: finePaid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã ghi nhận trả sách thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e is DioException
            ? (e.response?.data is Map &&
                      (e.response!.data as Map)['message'] != null)
                  ? (e.response!.data as Map)['message'].toString()
                  : 'Không thể ghi nhận trả sách'
            : 'Đã xảy ra lỗi khi ghi nhận trả sách';

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingBorrowingId = null;
        });
        await _refresh();
      }
    }
  }

  Future<void> _confirmPayFine(Borrowing borrowing) async {
    if (_processingBorrowingId != null) return;

    final fineText = borrowing.fineAmount != null
        ? BorrowingUiHelper.formatMoney(borrowing.fineAmount!)
        : '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Thu tiền phạt'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xác nhận đã nhận tiền phạt cho cuốn "${borrowing.bookTitle}"?',
              ),
              const SizedBox(height: 12),
              if (fineText.isNotEmpty)
                Text(
                  'Số tiền cần thu: $fineText',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xác nhận đã thu'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _processingBorrowingId = borrowing.id;
    });

    try {
      await widget.repository.payFine(borrowing.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thu tiền phạt thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e is DioException
            ? (e.response?.data is Map &&
                      (e.response!.data as Map)['message'] != null)
                  ? (e.response!.data as Map)['message'].toString()
                  : 'Không thể thu tiền phạt'
            : 'Đã xảy ra lỗi khi thu tiền phạt';

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingBorrowingId = null;
        });
        await _refresh();
      }
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
          child: FutureBuilder<PaginatedBorrowings>(
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
                      const Text('Không thể tải danh sách mượn sách'),
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
                            'Tổng số: ${result.totalItems} lượt mượn',
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
                      child: result.borrowings.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 80),
                                Icon(Icons.menu_book_outlined, size: 52),
                                SizedBox(height: 16),
                                Center(child: Text('Không có lượt mượn nào')),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(12),
                              itemCount: result.borrowings.length,
                              itemBuilder: (context, index) {
                                final borrowing = result.borrowings[index];
                                final isBusy =
                                    _processingBorrowingId == borrowing.id;
                                final canReturn =
                                    borrowing.status == 'BORROWED' ||
                                    borrowing.status == 'OVERDUE';
                                final hasUnpaidFine =
                                    (borrowing.fineAmount != null &&
                                        borrowing.fineAmount! > 0) &&
                                    (borrowing.finePaid != true);

                                return BorrowingCard(
                                  borrowing: borrowing,
                                  showMember: true,
                                  isBusy: _processingBorrowingId != null,
                                  isReturning: isBusy && canReturn,
                                  isPayingFine: isBusy && hasUnpaidFine,
                                  onReturn: canReturn
                                      ? () => _confirmReturn(borrowing)
                                      : null,
                                  onPayFine: hasUnpaidFine
                                      ? () => _confirmPayFine(borrowing)
                                      : null,
                                  onRenew: null,
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
