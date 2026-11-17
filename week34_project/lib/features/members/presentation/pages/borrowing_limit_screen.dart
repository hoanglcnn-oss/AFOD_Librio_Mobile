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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Hạn mức mượn sách',
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isResolvingMember) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
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
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _resolveMemberAndLoad,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
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
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
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
                  const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
                  const SizedBox(height: 12),
                  const Text(
                    'Không thể tải thông tin hạn mức mượn sách',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _loadDebtSummary,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final summary = snapshot.data!;
        return RefreshIndicator(
          color: const Color(0xFF0D9488),
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Theo dõi số sách đang mượn và điều kiện mượn thêm',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),

              // Thẻ tổng quan số sách đang mượn
              Card(
                elevation: 0,
                color: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đang mượn',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${summary.currentBorrowedCount}/${summary.maxBorrowLimit} cuốn',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            summary.canBorrow
                                ? Icons.check_circle
                                : Icons.warning_amber_rounded,
                            size: 18,
                            color: summary.canBorrow
                                ? const Color(0xFF34D399)
                                : const Color(0xFFF87171),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              summary.canBorrow
                                  ? 'Được mượn thêm'
                                  : (summary.reasonIfNotAllowed ??
                                        'Không đủ điều kiện mượn thêm'),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: summary.canBorrow
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFFFCA5A5),
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

              // Thẻ chi tiết điều kiện mượn
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.bookmark_added_outlined,
                        color: Color(0xFF0D9488),
                      ),
                      title: const Text(
                        'Còn được mượn',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Text(
                        '${summary.remainingBorrowLimit} cuốn',
                        style: const TextStyle(
                          color: Color(0xFF0D9488),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    ListTile(
                      leading: Icon(
                        Icons.timer_off_outlined,
                        color: summary.overdueCount > 0
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF64748B),
                      ),
                      title: const Text(
                        'Sách quá hạn',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Text(
                        '${summary.overdueCount}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: summary.overdueCount > 0
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    ListTile(
                      leading: Icon(
                        Icons.payments_outlined,
                        color: summary.unpaidFineAmount > 0
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF64748B),
                      ),
                      title: const Text(
                        'Tiền phạt chưa thanh toán',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Text(
                        BorrowingSlipUiHelper.formatMoney(
                          summary.unpaidFineAmount,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: summary.unpaidFineAmount > 0
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (!summary.canBorrow && summary.reasonIfNotAllowed != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFECACA),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          summary.reasonIfNotAllowed!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
