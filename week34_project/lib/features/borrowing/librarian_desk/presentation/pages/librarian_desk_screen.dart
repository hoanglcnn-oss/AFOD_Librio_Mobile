import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:week34_project/features/books/bloc/books_bloc.dart';
import 'package:week34_project/features/books/bloc/books_event.dart';
import 'package:week34_project/features/books/data/repositories/api_books_repository.dart';
import 'package:week34_project/features/books/data/repositories/books_repository.dart';
import 'package:week34_project/features/books/presentation/pages/barcode_scanner_screen.dart';
import 'package:week34_project/features/books/presentation/pages/books_screen.dart';
import 'package:week34_project/features/borrowing/shared/models/borrowing_slip.dart';
import 'package:week34_project/features/borrowing/shared/models/paginated_borrowing_slips.dart';
import 'package:week34_project/features/borrowing/shared/repositories/borrowing_slips_repository.dart';
import 'package:week34_project/features/borrowing/slip_management/presentation/pages/borrowing_slip_detail_screen.dart';
import 'package:week34_project/features/borrowing/slip_management/presentation/pages/borrowing_slip_list_screen.dart';
import 'package:week34_project/features/borrowing/slip_management/presentation/widgets/slip_list_card.dart';
import 'package:week34_project/features/members/data/repositories/api_members_repository.dart';
import 'package:week34_project/features/members/data/repositories/members_repository.dart';
import 'package:week34_project/features/members/presentation/pages/borrowing_limit_screen.dart';
import '../widgets/slip_decision_dialog.dart';

class LibrarianDeskScreen extends StatefulWidget {
  final BorrowingSlipsRepository repository;
  final BooksRepository? booksRepository;
  final MembersRepository? membersRepository;
  final VoidCallback? onNavigateToSlipsTab;

  const LibrarianDeskScreen({
    super.key,
    required this.repository,
    this.booksRepository,
    this.membersRepository,
    this.onNavigateToSlipsTab,
  });

  @override
  State<LibrarianDeskScreen> createState() => _LibrarianDeskScreenState();
}

class _LibrarianDeskScreenState extends State<LibrarianDeskScreen> {
  late Future<PaginatedBorrowingSlips> _future;
  late final BooksRepository _booksRepository;
  late final MembersRepository _membersRepository;
  int _page = 1;

  static const primaryNavy = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const borderHairline = Color(0xFFE2E8F0);
  static const tealAccent = Color(0xFF0D9488);
  static const tealBg = Color(0xFFF0FDFA);

  @override
  void initState() {
    super.initState();
    _booksRepository = widget.booksRepository ?? ApiBooksRepository();
    _membersRepository = widget.membersRepository ?? ApiMembersRepository();
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
      // FutureBuilder sẽ hiển thị lỗi và nút thử lại
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

  Future<void> _handleLookupMember(BuildContext context) async {
    final navigator = Navigator.of(context);
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_search_rounded, color: tealAccent),
            SizedBox(width: 8),
            Text(
              'Tra cứu bạn đọc',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: primaryNavy,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập mã độc giả (Member ID) để kiểm tra hạn mức và tình trạng mượn trả:',
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ví dụ: mem-01 hoặc UUID',
                hintStyle:
                    const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy', style: TextStyle(color: textMuted)),
          ),
          FilledButton(
            onPressed: () {
              final id = textController.text.trim();
              if (id.isNotEmpty) {
                Navigator.of(ctx).pop(id);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: primaryNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Tra cứu'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => BorrowingLimitScreen(
            memberId: result,
            membersRepository: _membersRepository,
          ),
        ),
      );
    }
  }

  void _handleScanBarcode(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BarcodeScannerScreen(
          repository: _booksRepository,
        ),
      ),
    );
  }

  void _handleCreateSlip(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<BooksBloc>(
          create: (_) => BooksBloc(booksRepository: _booksRepository)
            ..add(const LoadBooks()),
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              title: const Text(
                'Chọn sách lập phiếu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              elevation: 0,
              scrolledUnderElevation: 0,
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1.0),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE2E8F0),
                ),
              ),
            ),
            body: BooksScreen(
              repository: _booksRepository,
            ),
          ),
        ),
      ),
    );
  }

  void _handleManageSlips(BuildContext context) {
    if (widget.onNavigateToSlipsTab != null) {
      widget.onNavigateToSlipsTab!();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'Quản lý mượn trả',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            elevation: 0,
            scrolledUnderElevation: 0,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1.0),
              child: Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE2E8F0),
              ),
            ),
          ),
          body: BorrowingSlipsScreen(
            repository: widget.repository,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderHairline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: primaryNavy,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFD97706)),
            SizedBox(width: 4),
            Text(
              'THAO TÁC NHANH TẠI QUẦY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.qr_code_scanner_rounded,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                title: 'Quét Barcode / QR',
                subtitle: 'Kiểm tra sách & thẻ',
                onTap: () => _handleScanBarcode(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.person_search_rounded,
                iconBg: tealBg,
                iconColor: tealAccent,
                title: 'Tra cứu bạn đọc',
                subtitle: 'Xem nợ & hạn mức',
                onTap: () => _handleLookupMember(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.add_shopping_cart_rounded,
                iconBg: const Color(0xFFF5F3FF),
                iconColor: const Color(0xFF7C3AED),
                title: 'Tạo phiếu tại quầy',
                subtitle: 'Lập phiếu trực tiếp',
                onTap: () => _handleCreateSlip(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.receipt_long_rounded,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                title: 'Quản lý mượn trả',
                subtitle: 'Toàn bộ danh sách',
                onTap: () => _handleManageSlips(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPendingHeader(int totalCount) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.pending_actions_rounded,
                  size: 20, color: primaryNavy),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Phiếu mượn cần duyệt',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                    color: primaryNavy,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tealBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCCFBF1)),
                ),
                child: Text(
                  '$totalCount',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: tealAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Tải lại danh sách',
          onPressed: () => _refresh(),
          icon: const Icon(Icons.refresh_rounded, color: primaryNavy, size: 20),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderHairline),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.task_alt_rounded, size: 48, color: Color(0xFF10B981)),
          SizedBox(height: 12),
          Text(
            'Không có phiếu chờ duyệt',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: primaryNavy,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tất cả yêu cầu mượn sách đã được xử lý xong',
            style: TextStyle(fontSize: 13, color: textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(PaginatedBorrowingSlips result) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Trang trước',
            onPressed: _page <= 1 ? null : () => _changePage(_page - 1),
            icon: const Icon(Icons.chevron_left_rounded, color: primaryNavy),
          ),
          Text(
            'Trang $_page/${result.totalPages}',
            style: const TextStyle(
              color: textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            tooltip: 'Trang sau',
            onPressed: result.hasNextPage ? () => _changePage(_page + 1) : null,
            icon: const Icon(Icons.chevron_right_rounded, color: primaryNavy),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PaginatedBorrowingSlips>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError && !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 40, color: Color(0xFFDC2626)),
                const SizedBox(height: 12),
                const Text(
                  'Không thể tải dữ liệu bàn trực',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: primaryNavy,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _refresh(resetPage: true),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final result = snapshot.data ??
            const PaginatedBorrowingSlips(
              slips: [],
              page: 1,
              limit: 10,
              totalItems: 0,
              totalPages: 1,
              hasNextPage: false,
            );

        return LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 900;

            return Material(
              color: Colors.transparent,
              child: RefreshIndicator(
                color: tealAccent,
                onRefresh: () => _refresh(resetPage: true),
                child: isTablet
                    ? _buildTabletLayout(context, result)
                    : _buildMobileLayout(context, result),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    PaginatedBorrowingSlips result,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // 1. Nghiệp vụ quầy (Quick Actions Grid)
        _buildQuickActionsGrid(context),
        const SizedBox(height: 20),

        // 2. Header danh sách chờ duyệt
        _buildPendingHeader(result.totalItems),
        const SizedBox(height: 10),

        // 3. Danh sách các phiếu chờ duyệt hoặc Empty state
        if (result.slips.isEmpty)
          _buildEmptyState()
        else ...[
          ...result.slips.map((slip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: BorrowingSlipCard(
                key: ValueKey('slip_${slip.id}'),
                slip: slip,
                showMember: true,
                onTap: () => _openDetail(slip.id),
                onApprove: () => _processSlip(slip, approve: true),
                onReject: () => _processSlip(slip, approve: false),
              ),
            );
          }),
          if (result.totalPages > 1) _buildPagination(result),
        ],
      ],
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    PaginatedBorrowingSlips result,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cột trái (flex: 7): "Phiếu mượn cần duyệt"
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPendingHeader(result.totalItems),
                      const SizedBox(height: 12),
                      if (result.slips.isEmpty)
                        _buildEmptyState()
                      else ...[
                        ...result.slips.map((slip) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: BorrowingSlipCard(
                              key: ValueKey('slip_${slip.id}'),
                              slip: slip,
                              showMember: true,
                              onTap: () => _openDetail(slip.id),
                              onApprove: () =>
                                  _processSlip(slip, approve: true),
                              onReject: () =>
                                  _processSlip(slip, approve: false),
                            ),
                          );
                        }),
                        if (result.totalPages > 1) _buildPagination(result),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // Cột phải (flex: 5): "Thao tác nhanh tại quầy"
                Expanded(
                  flex: 5,
                  child: _buildQuickActionsGrid(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
