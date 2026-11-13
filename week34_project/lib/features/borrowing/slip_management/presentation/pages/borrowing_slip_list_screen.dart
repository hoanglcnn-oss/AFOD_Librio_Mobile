import 'package:flutter/material.dart';

import '../../../shared/repositories/borrowing_slips_repository.dart';
import '../../../shared/models/paginated_borrowing_slips.dart';
import '../widgets/borrowing_slip_card.dart';
import 'borrowing_slip_detail_screen.dart';

class BorrowingSlipsScreen extends StatefulWidget {
  final String memberId;
  final BorrowingSlipsRepository repository;
  final VoidCallback? onReturnSucceeded;

  const BorrowingSlipsScreen({
    super.key,
    required this.memberId,
    required this.repository,
    this.onReturnSucceeded,
  });

  @override
  State<BorrowingSlipsScreen> createState() => _BorrowingSlipsScreenState();
}

class _BorrowingSlipsScreenState extends State<BorrowingSlipsScreen> {
  late Future<PaginatedBorrowingSlips> _future;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.repository.getBorrowingSlips(
      memberId: widget.memberId,
      page: _page,
    );
  }

  void _refresh() {
    setState(_load);
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
      _refresh();
      widget.onReturnSucceeded?.call();
    }
  }

  void _changePage(int page) {
    setState(() {
      _page = page;
      _load();
    });
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
                const Text('Không thể tải danh sách phiếu mượn'),
                TextButton(onPressed: _refresh, child: const Text('Thử lại')),
              ],
            ),
          );
        }

        final result = snapshot.data!;

        if (result.slips.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Chưa có phiếu mượn ở trang này'),
                TextButton(onPressed: _refresh, child: const Text('Tải lại')),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _refresh();
                  await _future;
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: result.slips.length,
                  itemBuilder: (context, index) {
                    final slip = result.slips[index];

                    return BorrowingSlipCard(
                      slip: slip,
                      onTap: () => _openDetail(slip.id),
                    );
                  },
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Trang trước',
                  onPressed: _page <= 1 ? null : () => _changePage(_page - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Trang $_page/${result.totalPages}'),
                IconButton(
                  tooltip: 'Trang tiếp',
                  onPressed: result.hasNextPage
                      ? () => _changePage(_page + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
