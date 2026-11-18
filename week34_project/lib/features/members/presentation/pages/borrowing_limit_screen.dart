import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/borrowing/shared/widgets/borrowing_slip_ui_helper.dart';

import '../../data/repositories/api_members_repository.dart';
import '../../data/repositories/members_repository.dart';
import '../../data/models/member_debt_summary.dart';

class BorrowingLimitScreen extends StatefulWidget {
  final String? memberId;
  final MembersRepository? membersRepository;

  const BorrowingLimitScreen({
    super.key,
    this.memberId,
    this.membersRepository,
  });

  @override
  State<BorrowingLimitScreen> createState() => _BorrowingLimitScreenState();
}

class _BorrowingLimitScreenState extends State<BorrowingLimitScreen> {
  late final MembersRepository _repository;
  Future<MemberDebtSummary>? _debtSummaryFuture;
  String? _resolvedMemberId;
  bool _isResolvingMember = false;
  String? _resolveError;

  static const primaryNavy = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const borderHairline = Color(0xFFE2E8F0);
  static const tealAccent = Color(0xFF0D9488);
  static const tealBg = Color(0xFFF0FDFA);
  static const surfaceLow = Color(0xFFF8FAFC);
  static const errorRed = Color(0xFFDC2626);
  static const successGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _repository = widget.membersRepository ?? ApiMembersRepository();
    _initData();
  }

  void _initData() {
    if (widget.memberId != null && widget.memberId!.trim().isNotEmpty) {
      _resolvedMemberId = widget.memberId!.trim();
      _loadDebtSummary();
    } else {
      _resolveMemberAndLoad();
    }
  }

  Future<void> _resolveMemberAndLoad() async {
    setState(() {
      _isResolvingMember = true;
      _resolveError = null;
    });

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      setState(() {
        _isResolvingMember = false;
        _resolveError = 'Chưa đăng nhập tài khoản';
      });
      return;
    }

    final user = authState.user;
    try {
      final memberId = await _repository.resolveMemberId(
        memberId: user.memberId,
        email: user.email,
        role: user.role,
      );

      if (!mounted) return;

      if (memberId == null || memberId.isEmpty) {
        setState(() {
          _isResolvingMember = false;
          _resolveError = 'Không tìm thấy hồ sơ độc giả liên kết';
        });
        return;
      }

      _resolvedMemberId = memberId;
      _isResolvingMember = false;
      _loadDebtSummary();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isResolvingMember = false;
        _resolveError = 'Không thể tra cứu hồ sơ độc giả';
      });
    }
  }

  void _loadDebtSummary() {
    if (_resolvedMemberId == null) return;
    setState(() {
      _debtSummaryFuture = _repository.getDebtSummary(_resolvedMemberId!);
    });
  }

  Future<void> _refresh() async {
    if (_resolvedMemberId == null) {
      await _resolveMemberAndLoad();
    } else {
      _loadDebtSummary();
      await _debtSummaryFuture;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceLow,
      appBar: AppBar(
        title: const Text(
          'Hạn mức mượn sách',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryNavy,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(
            height: 1,
            thickness: 1,
            color: borderHairline,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isResolvingMember) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(tealAccent),
        ),
      );
    }

    if (_resolveError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFD97706)),
              const SizedBox(height: 12),
              Text(
                _resolveError!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _resolveMemberAndLoad,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryNavy,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_debtSummaryFuture == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<MemberDebtSummary>(
      future: _debtSummaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(tealAccent),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: errorRed),
                  const SizedBox(height: 12),
                  const Text(
                    'Không thể tải thông tin hạn mức mượn sách',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _loadDebtSummary,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryNavy,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final summary = snapshot.data!;
        final maxLimit = summary.maxBorrowLimit > 0 ? summary.maxBorrowLimit : 5;
        final progress = (summary.currentBorrowedCount / maxLimit).clamp(0.0, 1.0);

        return RefreshIndicator(
          color: tealAccent,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            children: [
              // 1. Thẻ tổng quan Hạn mức mượn (Hero Quota Card)
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: borderHairline),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.auto_stories_outlined,
                                size: 20,
                                color: tealAccent,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Đang mượn',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: summary.canBorrow
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: summary.canBorrow
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFFFECACA),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: summary.canBorrow
                                        ? successGreen
                                        : errorRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  summary.canBorrow
                                      ? 'Khả dụng'
                                      : 'Giới hạn',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: summary.canBorrow
                                        ? const Color(0xFF047857)
                                        : errorRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Số lượng sách lớn (Required by tests: '3/5 cuốn' or '5/5 cuốn')
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${summary.currentBorrowedCount}/${summary.maxBorrowLimit} cuốn',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: primaryNavy,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Thanh tiến trình Quota
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            summary.canBorrow ? tealAccent : errorRed,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Dòng diễn giải điều kiện
                      Row(
                        children: [
                          Icon(
                            summary.canBorrow
                                ? Icons.check_circle_rounded
                                : Icons.warning_amber_rounded,
                            size: 16,
                            color: summary.canBorrow ? successGreen : errorRed,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              summary.canBorrow
                                  ? 'Được mượn thêm'
                                  : (summary.reasonIfNotAllowed ??
                                        'Không đủ điều kiện mượn thêm'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: summary.canBorrow
                                    ? const Color(0xFF047857)
                                    : errorRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. Thẻ chi tiết điều kiện mượn (Conditions Card)
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'CHI TIẾT ĐIỀU KIỆN',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: textMuted,
                  ),
                ),
              ),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: borderHairline),
                ),
                elevation: 0,
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: tealBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.bookmark_added_outlined,
                          color: tealAccent,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Còn được mượn',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: primaryNavy,
                        ),
                      ),
                      trailing: Text(
                        '${summary.remainingBorrowLimit} cuốn',
                        style: const TextStyle(
                          color: tealAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
                    ListTile(
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: summary.overdueCount > 0
                              ? const Color(0xFFFEF2F2)
                              : surfaceLow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.timer_off_outlined,
                          color: summary.overdueCount > 0
                              ? errorRed
                              : textMuted,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Sách quá hạn',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: primaryNavy,
                        ),
                      ),
                      trailing: Text(
                        '${summary.overdueCount}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: summary.overdueCount > 0
                              ? errorRed
                              : primaryNavy,
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
                    ListTile(
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: summary.unpaidFineAmount > 0
                              ? const Color(0xFFFEF2F2)
                              : surfaceLow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.payments_outlined,
                          color: summary.unpaidFineAmount > 0
                              ? errorRed
                              : textMuted,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Tiền phạt chưa thanh toán',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: primaryNavy,
                        ),
                      ),
                      trailing: Text(
                        BorrowingSlipUiHelper.formatMoney(
                          summary.unpaidFineAmount,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: summary.unpaidFineAmount > 0
                              ? errorRed
                              : primaryNavy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Khung cảnh báo khi không đủ điều kiện
              if (!summary.canBorrow && summary.reasonIfNotAllowed != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFECACA),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: errorRed,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          summary.reasonIfNotAllowed!,
                          style: const TextStyle(
                            color: errorRed,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // 4. Khối Quy định mượn sách học thuật (Academic Policy Card)
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'QUY ĐỊNH LƯU HÀNH',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: textMuted,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderHairline),
                ),
                child: const Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_outline, size: 16, color: tealAccent),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Hạn mức mượn tối đa: 5 ấn bản tài liệu giấy cùng một thời điểm.',
                            style: TextStyle(fontSize: 12.5, color: textMuted),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_outline, size: 16, color: tealAccent),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Thời hạn mượn tiêu chuẩn: 14 đến 30 ngày (tùy theo loại tài liệu).',
                            style: TextStyle(fontSize: 12.5, color: textMuted),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_outline, size: 16, color: tealAccent),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Gia hạn: Được phép gia hạn tối đa 2 lần nếu sách chưa có người khác đặt trước.',
                            style: TextStyle(fontSize: 12.5, color: textMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
