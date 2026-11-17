import 'package:flutter/material.dart';

import '../../../../books/data/repositories/api_books_repository.dart';
import '../../../../books/data/repositories/books_repository.dart';
import '../../../../books/presentation/pages/barcode_scanner_screen.dart';
import '../../../../books/presentation/pages/books_screen.dart';
import '../../../../borrowing/pending_slips/presentation/pages/pending_borrowing_slips_screen.dart';
import '../../../../borrowing/shared/models/paginated_borrowing_slips.dart';
import '../../../../borrowing/shared/repositories/api_borrowing_slips_repository.dart';
import '../../../../borrowing/shared/repositories/borrowing_slips_repository.dart';
import '../../../../borrowing/slip_management/presentation/pages/borrowing_slip_list_screen.dart';
import '../../../../members/data/repositories/api_members_repository.dart';
import '../../../../members/data/repositories/members_repository.dart';
import '../../../../members/presentation/pages/borrowing_limit_screen.dart';

class LibrarianCounterSection extends StatefulWidget {
  final BorrowingSlipsRepository? borrowingSlipsRepository;
  final BooksRepository? booksRepository;
  final MembersRepository? membersRepository;

  const LibrarianCounterSection({
    super.key,
    this.borrowingSlipsRepository,
    this.booksRepository,
    this.membersRepository,
  });

  @override
  State<LibrarianCounterSection> createState() =>
      _LibrarianCounterSectionState();
}

class _LibrarianCounterSectionState extends State<LibrarianCounterSection> {
  late final BorrowingSlipsRepository _borrowingSlipsRepository;
  late final BooksRepository _booksRepository;
  late final MembersRepository _membersRepository;

  Future<PaginatedBorrowingSlips>? _pendingSlipsFuture;

  static const primaryNavy = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const tealAccent = Color(0xFF0D9488);
  static const errorRed = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    _borrowingSlipsRepository =
        widget.borrowingSlipsRepository ?? ApiBorrowingSlipsRepository();
    _booksRepository = widget.booksRepository ?? ApiBooksRepository();
    _membersRepository = widget.membersRepository ?? ApiMembersRepository();
    _loadPendingSlips();
  }

  void _loadPendingSlips() {
    _pendingSlipsFuture = _borrowingSlipsRepository
        .getPendingBorrowingSlips(page: 1, limit: 1)
        .catchError((_) {
      return const PaginatedBorrowingSlips(
        slips: [],
        page: 1,
        limit: 1,
        totalItems: 0,
        totalPages: 1,
        hasNextPage: false,
      );
    });
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
        builder: (_) => Scaffold(
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
    );
  }

  void _handleManageSlips(BuildContext context) {
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
            repository: _borrowingSlipsRepository,
          ),
        ),
      ),
    );
  }

  Widget _buildLibrarianActionCard({
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
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nghiệp vụ quầy & ca trực',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
            color: primaryNavy,
          ),
        ),
        const SizedBox(height: 12),

        // 1. Thẻ tóm tắt ca trực (Shift Overview Banner)
        FutureBuilder<PaginatedBorrowingSlips>(
          future: _pendingSlipsFuture,
          builder: (context, snapshot) {
            final pendingCount = snapshot.data?.totalItems ??
                (snapshot.data?.slips.length ?? 0);
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;

            return InkWell(
              onTap: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      backgroundColor: const Color(0xFFF8FAFC),
                      appBar: AppBar(
                        title: const Text(
                          'Phiếu chờ duyệt',
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
                      body: PendingBorrowingSlipsScreen(
                        repository: _borrowingSlipsRepository,
                      ),
                    ),
                  ),
                )
                    .then((_) {
                  if (mounted) {
                    setState(() {
                      _loadPendingSlips();
                    });
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFEF3C7)),
                      ),
                      child: const Icon(
                        Icons.assignment_late_outlined,
                        color: Color(0xFFD97706),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Phiếu mượn cần duyệt',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isLoading
                                ? 'Đang đồng bộ dữ liệu...'
                                : pendingCount > 0
                                    ? 'Có $pendingCount phiếu đang chờ thủ thư xử lý'
                                    : 'Không có phiếu mượn tồn đọng',
                            style: const TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pendingCount > 0
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: pendingCount > 0
                              ? const Color(0xFFFECACA)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        isLoading ? '...' : '$pendingCount',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: pendingCount > 0 ? errorRed : textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // 2. Lưới tác vụ nhanh tại quầy (Grid of Quick Actions)
        Row(
          children: [
            Expanded(
              child: _buildLibrarianActionCard(
                icon: Icons.qr_code_scanner_rounded,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                title: 'Quét Barcode / QR',
                subtitle: 'Kiểm tra tài liệu & thẻ',
                onTap: () => _handleScanBarcode(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLibrarianActionCard(
                icon: Icons.person_search_rounded,
                iconBg: const Color(0xFFF0FDFA),
                iconColor: const Color(0xFF0D9488),
                title: 'Tra cứu bạn đọc',
                subtitle: 'Hạn mức, sách & phạt',
                onTap: () => _handleLookupMember(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildLibrarianActionCard(
                icon: Icons.note_add_outlined,
                iconBg: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFEA580C),
                title: 'Tạo phiếu tại quầy',
                subtitle: 'Lập phiếu mượn sách',
                onTap: () => _handleCreateSlip(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLibrarianActionCard(
                icon: Icons.receipt_long_outlined,
                iconBg: const Color(0xFFF8FAFC),
                iconColor: const Color(0xFF475569),
                title: 'Quản lý mượn trả',
                subtitle: 'Toàn bộ phiếu thư viện',
                onTap: () => _handleManageSlips(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
