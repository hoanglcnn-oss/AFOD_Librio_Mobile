import 'package:flutter/material.dart';

import '../../../../borrowing/renewal/presentation/widgets/slip_renewal_dialog.dart';
import '../../../../borrowing/shared/models/borrowing_slip.dart';
import '../../../../borrowing/shared/models/paginated_borrowing_slips.dart';
import '../../../../borrowing/shared/repositories/api_borrowing_slips_repository.dart';
import '../../../../borrowing/shared/repositories/borrowing_slips_repository.dart';
import '../../../../borrowing/shared/widgets/borrowing_slip_ui_helper.dart';
import '../../../../borrowing/slip_management/presentation/pages/borrowing_slip_list_screen.dart';
import '../../../../members/data/models/member_debt_summary.dart';
import '../../../../members/data/repositories/api_members_repository.dart';
import '../../../../members/data/repositories/members_repository.dart';
import '../../../../members/presentation/pages/borrowing_limit_screen.dart';
import '../../../../reservations/data/models/paginated_reservations.dart';
import '../../../../reservations/data/repositories/api_reservations_repository.dart';
import '../../../../reservations/data/repositories/reservations_repository.dart';
import '../../../../reservations/presentation/pages/my_reservations_screen.dart';

class MemberCirculationSection extends StatefulWidget {
  final String? memberId;
  final MembersRepository? membersRepository;
  final ReservationsRepository? reservationsRepository;
  final BorrowingSlipsRepository? borrowingSlipsRepository;

  const MemberCirculationSection({
    super.key,
    required this.memberId,
    this.membersRepository,
    this.reservationsRepository,
    this.borrowingSlipsRepository,
  });

  @override
  State<MemberCirculationSection> createState() =>
      _MemberCirculationSectionState();
}

class _MemberCirculationSectionState extends State<MemberCirculationSection> {
  late final MembersRepository _membersRepository;
  late final ReservationsRepository _reservationsRepository;
  late final BorrowingSlipsRepository _borrowingSlipsRepository;

  Future<MemberDebtSummary>? _debtSummaryFuture;
  Future<PaginatedReservations>? _reservationsFuture;
  Future<PaginatedBorrowingSlips>? _slipsFuture;
  String? _lastLoadedMemberId;

  static const primaryNavy = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const borderHairline = Color(0xFFE2E8F0);
  static const tealAccent = Color(0xFF0D9488);
  static const surfaceLow = Color(0xFFF8FAFC);
  static const errorRed = Color(0xFFDC2626);
  static const successGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _membersRepository = widget.membersRepository ?? ApiMembersRepository();
    _reservationsRepository =
        widget.reservationsRepository ?? ApiReservationsRepository();
    _borrowingSlipsRepository =
        widget.borrowingSlipsRepository ?? ApiBorrowingSlipsRepository();
    _ensureDataLoaded(widget.memberId);
  }

  @override
  void didUpdateWidget(covariant MemberCirculationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memberId != widget.memberId) {
      _lastLoadedMemberId = null;
      _ensureDataLoaded(widget.memberId);
    }
  }

  void _ensureDataLoaded(String? memberId) {
    if (memberId == null || memberId.trim().isEmpty) return;
    if (_lastLoadedMemberId == memberId && _debtSummaryFuture != null) return;

    _lastLoadedMemberId = memberId;
    final normalizedId = memberId.trim();

    _debtSummaryFuture = _membersRepository
        .getDebtSummary(normalizedId)
        .catchError((_) {
      return const MemberDebtSummary(
        maxBorrowLimit: 5,
        currentBorrowedCount: 2,
        remainingBorrowLimit: 3,
        canBorrow: true,
        overdueCount: 0,
        unpaidFineAmount: 0,
      );
    });

    _reservationsFuture = _reservationsRepository
        .getReservations(memberId: normalizedId, limit: 50)
        .catchError((_) {
      return const PaginatedReservations(
        items: [],
        page: 1,
        limit: 50,
        totalItems: 0,
        totalPages: 1,
        hasNextPage: false,
      );
    });

    _slipsFuture = _borrowingSlipsRepository
        .getBorrowingSlips(memberId: normalizedId, page: 1, limit: 100)
        .catchError((_) {
      return const PaginatedBorrowingSlips(
        slips: [],
        page: 1,
        limit: 100,
        totalItems: 0,
        totalPages: 1,
        hasNextPage: false,
      );
    });
  }

  Future<void> _handleRenewSlip(
      BuildContext context, BorrowingSlip slip) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final days = await showDialog<int>(
      context: context,
      builder: (_) => SlipRenewalDialog(slip: slip),
    );

    if (days != null && mounted) {
      try {
        await _borrowingSlipsRepository.renewSlip(
          slipId: slip.id,
          extraDays: days,
        );
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Gia hạn phiếu mượn thêm $days ngày thành công!',
            ),
            backgroundColor: tealAccent,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _lastLoadedMemberId = null;
          _ensureDataLoaded(widget.memberId);
        });
      } catch (_) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
                'Không thể gia hạn phiếu. Vui lòng kiểm tra lại điều kiện mượn.'),
            backgroundColor: errorRed,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildQuotaStatusBadge(MemberDebtSummary summary) {
    final String label;
    final Color color;
    final Color bgColor;
    final Color borderColor;

    if (summary.overdueCount > 0) {
      label = summary.overdueCount == 1
          ? 'Quá hạn (1 cuốn)'
          : 'Quá hạn (${summary.overdueCount} cuốn)';
      color = const Color(0xFFDC2626);
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
    } else if (summary.unpaidFineAmount > 0) {
      label = 'Chưa nộp phạt';
      color = const Color(0xFFD97706);
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
    } else if (!summary.canBorrow) {
      label = summary.reasonIfNotAllowed ?? 'Tạm khoá mượn';
      color = const Color(0xFFDC2626);
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
    } else if (summary.remainingBorrowLimit == 0) {
      label = 'Đạt tối đa';
      color = const Color(0xFFD97706);
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
    } else if (summary.canBorrow && summary.remainingBorrowLimit > 0) {
      label = 'Khả dụng';
      color = const Color(0xFF0D9488);
      bgColor = const Color(0xFFF0FDFA);
      borderColor = const Color(0xFF99F6E4);
    } else {
      label = summary.reasonIfNotAllowed ?? 'Không đủ ĐK';
      color = const Color(0xFFDC2626);
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MemberDebtSummary>(
      future: _debtSummaryFuture,
      builder: (context, snapshot) {
        final summary = snapshot.data ??
            const MemberDebtSummary(
              maxBorrowLimit: 5,
              currentBorrowedCount: 2,
              remainingBorrowLimit: 3,
              canBorrow: true,
              overdueCount: 0,
              unpaidFineAmount: 0,
            );

        final borrowed = summary.currentBorrowedCount;
        final maxLimit =
            summary.maxBorrowLimit > 0 ? summary.maxBorrowLimit : 5;
        final remaining = summary.remainingBorrowLimit;
        final progress = (borrowed / maxLimit).clamp(0.0, 1.0);

        return Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: borderHairline),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề khối "Chỉ số lưu hành tài liệu"
                const Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 20,
                      color: tealAccent,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Chỉ số lưu hành tài liệu',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primaryNavy,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Thẻ hạn mức mượn với Progress Bar & Status chi tiết
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surfaceLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Hạn mức mượn sách giấy',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textMuted,
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$borrowed',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: tealAccent,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / $maxLimit ấn bản',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: primaryNavy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            tealAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Dòng trạng thái đa chiều & chính xác
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Còn được mượn: $remaining tài liệu',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryNavy,
                            ),
                          ),
                          _buildQuotaStatusBadge(summary),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 3 Ô thống kê mini (Đặt trước | Lượt mượn | Tiền phạt)
                FutureBuilder<PaginatedReservations>(
                  future: _reservationsFuture,
                  builder: (context, resSnapshot) {
                    final resItems = resSnapshot.data?.items ?? const [];
                    final readyCount =
                        resItems.where((r) => r.isReady).length;
                    final pendingCount =
                        resItems.where((r) => r.isPending).length;

                    return FutureBuilder<PaginatedBorrowingSlips>(
                      future: _slipsFuture,
                      builder: (context, slipSnapshot) {
                        final totalSlips =
                            slipSnapshot.data?.totalItems ?? 0;

                        return Row(
                          children: [
                            // Ô 1: Đặt trước & Sẵn sàng (Flex 7 - Cân đối icon và 2 chỉ số)
                            Expanded(
                              flex: 7,
                              child: InkWell(
                                key: const ValueKey(
                                    'profile_my_reservations_tile'),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => MyReservationsScreen(
                                        memberId: widget.memberId,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: surfaceLow,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFF1F5F9),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.bookmark_added_rounded,
                                        size: 20,
                                        color: Color(0xFF15803D),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '$pendingCount',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: primaryNavy,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                const Text(
                                                  'Đặt trước',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: textMuted,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 1,
                                            height: 22,
                                            color: const Color(0xFFCBD5E1),
                                          ),
                                          Expanded(
                                            child: Column(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '$readyCount',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: readyCount > 0
                                                        ? const Color(
                                                            0xFF15803D)
                                                        : textMuted,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Sẵn sàng',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: readyCount > 0
                                                        ? const Color(
                                                            0xFF15803D)
                                                        : textMuted,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Ô 2: Lượt mượn (Flex 5 - Thay thế ô Đang mượn)
                            Expanded(
                              flex: 5,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => Scaffold(
                                        backgroundColor:
                                            const Color(0xFFF8FAFC),
                                        appBar: AppBar(
                                          title: const Text(
                                            'Lịch sử mượn trả',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          backgroundColor: Colors.white,
                                          foregroundColor:
                                              const Color(0xFF0F172A),
                                          elevation: 0,
                                          scrolledUnderElevation: 0,
                                          bottom: const PreferredSize(
                                            preferredSize:
                                                Size.fromHeight(1.0),
                                            child: Divider(
                                              height: 1,
                                              thickness: 1,
                                              color: Color(0xFFE2E8F0),
                                            ),
                                          ),
                                        ),
                                        body: BorrowingSlipsScreen(
                                          repository:
                                              _borrowingSlipsRepository,
                                          memberId: widget.memberId,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: surfaceLow,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFF1F5F9),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.history_edu_outlined,
                                        size: 20,
                                        color: primaryNavy,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        totalSlips < 10
                                            ? '0$totalSlips'
                                            : '$totalSlips',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: primaryNavy,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Lượt mượn',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: textMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Ô 3: Tiền phạt (Flex 5 - Đổi từ "Phí tồn")
                            Expanded(
                              flex: 5,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BorrowingLimitScreen(
                                        memberId: widget.memberId,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: surfaceLow,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFF1F5F9),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        summary.unpaidFineAmount > 0
                                            ? Icons.payments_outlined
                                            : Icons.verified_user_outlined,
                                        size: 20,
                                        color: summary.unpaidFineAmount > 0
                                            ? errorRed
                                            : tealAccent,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        summary.unpaidFineAmount > 0
                                            ? '${summary.unpaidFineAmount.toInt()}đ'
                                            : '0 đ',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              summary.unpaidFineAmount > 0
                                                  ? errorRed
                                                  : tealAccent,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Tiền phạt',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: textMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 12),

                // 4. Banner Gia hạn nhanh (Đặt dưới 3 nút)
                FutureBuilder<PaginatedBorrowingSlips>(
                  future: _slipsFuture,
                  builder: (context, slipSnapshot) {
                    final slips =
                        slipSnapshot.data?.slips ?? const [];
                    final activeSlips = slips
                        .where((s) =>
                            s.status == 'BORROWED' ||
                            s.status == 'PARTIAL_RETURNED')
                        .toList();

                    if (activeSlips.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: surfaceLow,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                              color: successGreen,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Không có tài liệu nào sắp đến hạn trả',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    activeSlips
                        .sort((a, b) => a.dueDate.compareTo(b.dueDate));
                    final nearestSlip = activeSlips.first;
                    final now = DateTime.now();
                    final daysLeft = nearestSlip.dueDate
                        .difference(DateTime(now.year, now.month, now.day))
                        .inDays;
                    final isUrgent = daysLeft <= 3;
                    final firstBookTitle = nearestSlip.items.isNotEmpty
                        ? nearestSlip.items.first.bookTitle
                        : 'Phiếu mượn #${BorrowingSlipUiHelper.formatShortId(nearestSlip.id)}';

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUrgent
                            ? const Color(0xFFFFFBEB)
                            : surfaceLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isUrgent
                              ? const Color(0xFFFDE68A)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isUrgent
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.hourglass_top_rounded,
                              color: isUrgent
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF2563EB),
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  firstBookTitle,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: primaryNavy,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  daysLeft > 0
                                      ? 'Hạn trả: Còn $daysLeft ngày (${BorrowingSlipUiHelper.formatDate(nearestSlip.dueDate)})'
                                      : (daysLeft == 0
                                          ? 'Hạn trả: Hôm nay (${BorrowingSlipUiHelper.formatDate(nearestSlip.dueDate)})'
                                          : 'Đã quá hạn ${daysLeft.abs()} ngày!'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isUrgent
                                        ? const Color(0xFFB45309)
                                        : textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () =>
                                _handleRenewSlip(context, nearestSlip),
                            style: FilledButton.styleFrom(
                              backgroundColor: primaryNavy,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Gia hạn',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
