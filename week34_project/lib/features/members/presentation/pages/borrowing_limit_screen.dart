import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/borrowing_slips/presentation/widgets/borrowing_slip_ui_helper.dart';

import '../../data/api_members_repository.dart';
import '../../data/member_resolver.dart';
import '../../data/members_repository.dart';
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
      final resolver = MemberResolver(membersRepository: _repository);
      final memberId = await resolver.resolve(
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
      appBar: AppBar(title: const Text('Hạn mức mượn sách')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isResolvingMember) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_resolveError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.orange),
              const SizedBox(height: 12),
              Text(
                _resolveError!,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _resolveMemberAndLoad,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
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
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text(
                    'Không thể tải thông tin hạn mức mượn sách',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _loadDebtSummary,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        final summary = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Theo dõi số sách đang mượn và điều kiện mượn thêm',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Thẻ tổng quan số sách đang mượn
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đang mượn',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${summary.currentBorrowedCount}/${summary.maxBorrowLimit} cuốn',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            summary.canBorrow
                                ? Icons.check_circle
                                : Icons.warning_amber_rounded,
                            size: 18,
                            color: summary.canBorrow
                                ? Colors.green
                                : Colors.orange,
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
                                    ? Colors.green.shade800
                                    : Colors.deepOrange.shade900,
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
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.bookmark_added_outlined),
                      title: const Text('Còn được mượn'),
                      trailing: Text(
                        '${summary.remainingBorrowLimit} cuốn',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.timer_off_outlined,
                        color: summary.overdueCount > 0 ? Colors.red : null,
                      ),
                      title: const Text('Sách quá hạn'),
                      trailing: Text(
                        '${summary.overdueCount}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: summary.overdueCount > 0
                                  ? Colors.red
                                  : null,
                            ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.payments_outlined,
                        color: summary.unpaidFineAmount > 0 ? Colors.red : null,
                      ),
                      title: const Text('Tiền phạt chưa thanh toán'),
                      trailing: Text(
                        BorrowingSlipUiHelper.formatMoney(
                          summary.unpaidFineAmount,
                        ),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: summary.unpaidFineAmount > 0
                                  ? Colors.red
                                  : null,
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
                    color: Theme.of(
                      context,
                    ).colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          summary.reasonIfNotAllowed!,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
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
