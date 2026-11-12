import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/books/data/models/book.dart';
import 'package:week34_project/features/members/data/api_members_repository.dart';
import 'package:week34_project/features/members/data/member_resolver.dart';
import 'package:week34_project/features/members/data/members_repository.dart';
import 'package:week34_project/features/members/data/models/member_debt_summary.dart';

import '../../bloc/borrowing_slip_bloc.dart';
import '../../bloc/borrowing_slip_event.dart';
import '../../bloc/borrowing_slip_state.dart';
import '../../data/api_borrowing_slips_repository.dart';
import '../../data/borrowing_slips_repository.dart';
import '../../data/models/create_borrowing_slip_request.dart';

class BorrowingSlipConfirmScreen extends StatelessWidget {
  final List<Book> books;
  final MembersRepository? membersRepository;
  final BorrowingSlipsRepository? borrowingSlipsRepository;

  const BorrowingSlipConfirmScreen({
    super.key,
    required this.books,
    this.membersRepository,
    this.borrowingSlipsRepository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BorrowingSlipBloc(
        borrowingSlipsRepository:
            borrowingSlipsRepository ?? ApiBorrowingSlipsRepository(),
      ),
      child: _SlipConfirmContent(
        books: books,
        membersRepository: membersRepository ?? ApiMembersRepository(),
      ),
    );
  }
}

class _SlipConfirmContent extends StatefulWidget {
  final List<Book> books;
  final MembersRepository membersRepository;

  const _SlipConfirmContent({
    required this.books,
    required this.membersRepository,
  });

  @override
  State<_SlipConfirmContent> createState() => _SlipConfirmContentState();
}

class _SlipConfirmContentState extends State<_SlipConfirmContent> {
  late final Future<String?> _memberIdFuture;
  late final Map<String, int> _quantities;
  Future<MemberDebtSummary>? _debtSummaryFuture;
  String? _loadedMemberId;

  int _days = 14;

  @override
  void initState() {
    super.initState();
    _quantities = {for (final book in widget.books) book.id: 1};
    _memberIdFuture = _resolveMember();
  }

  Future<String?> _resolveMember() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return null;

    final user = authState.user;
    return MemberResolver(
      membersRepository: widget.membersRepository,
    ).resolve(memberId: user.memberId, email: user.email, role: user.role);
  }

  void _loadDebtSummary(String memberId) {
    setState(() {
      _loadedMemberId = memberId;
      _debtSummaryFuture = widget.membersRepository.getDebtSummary(memberId);
    });
  }

  void _submit(String memberId) {
    final request = CreateBorrowingSlipRequest(
      memberId: memberId,
      expectedReturnDays: _days,
      items: [
        for (final book in widget.books)
          BorrowingSlipItemRequest(
            bookId: book.id,
            quantity: _quantities[book.id]!,
          ),
      ],
    );

    context.read<BorrowingSlipBloc>().add(CreateSlipRequested(request));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận phiếu mượn')),
      body: BlocBuilder<BorrowingSlipBloc, BorrowingSlipState>(
        builder: (context, state) {
          if (state is BorrowingSlipSuccess) {
            return _buildSuccess(state);
          }

          return FutureBuilder<String?>(
            future: _memberIdFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text('Không thể tra cứu hồ sơ độc giả'),
                );
              }

              final memberId = snapshot.data;

              if (memberId == null || memberId.isEmpty) {
                return const Center(
                  child: Text('Không tìm thấy hồ sơ độc giả liên kết'),
                );
              }

              if (_debtSummaryFuture == null || _loadedMemberId != memberId) {
                _loadedMemberId = memberId;
                _debtSummaryFuture = widget.membersRepository.getDebtSummary(
                  memberId,
                );
              }

              return FutureBuilder<MemberDebtSummary>(
                future: _debtSummaryFuture,
                builder: (context, debtSnapshot) {
                  return _buildForm(memberId, state, debtSnapshot);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildForm(
    String memberId,
    BorrowingSlipState state,
    AsyncSnapshot<MemberDebtSummary> debtSnapshot,
  ) {
    final submitting = state is BorrowingSlipSubmitting;
    final totalSelected = _quantities.values.isEmpty
        ? 0
        : _quantities.values.reduce((a, b) => a + b);

    final debtSummary = debtSnapshot.data;
    final isDebtLoading = debtSnapshot.connectionState != ConnectionState.done;
    final isDebtError = debtSnapshot.hasError;

    final isExceedingLimit =
        debtSummary != null && totalSelected > debtSummary.remainingBorrowLimit;
    final canBorrowCondition = debtSummary != null && debtSummary.canBorrow;

    final canSubmit =
        !isDebtLoading &&
        !isDebtError &&
        debtSummary != null &&
        canBorrowCondition &&
        !isExceedingLimit;

    String? notAllowedReason;
    if (debtSummary != null) {
      if (!debtSummary.canBorrow) {
        notAllowedReason =
            debtSummary.reasonIfNotAllowed ??
            'Tài khoản hiện không đủ điều kiện mượn sách';
      } else if (isExceedingLimit) {
        notAllowedReason =
            'Số lượng sách chọn ($totalSelected cuốn) vượt quá hạn mức còn lại (${debtSummary.remainingBorrowLimit} cuốn)';
      }
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Sách đã chọn', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            for (final book in widget.books)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('Còn ${book.copiesAvailable} cuốn'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Số lượng:'),
                          const Spacer(),
                          IconButton(
                            onPressed: submitting || _quantities[book.id]! <= 1
                                ? null
                                : () => setState(() {
                                    _quantities[book.id] =
                                        _quantities[book.id]! - 1;
                                  }),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('${_quantities[book.id]}'),
                          IconButton(
                            onPressed:
                                submitting ||
                                    _quantities[book.id]! >=
                                        book.copiesAvailable ||
                                    _quantities[book.id]! >= 5
                                ? null
                                : () => setState(() {
                                    _quantities[book.id] =
                                        _quantities[book.id]! + 1;
                                  }),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Card Hạn mức mượn sách
            _buildDebtSummaryCard(
              memberId: memberId,
              isDebtLoading: isDebtLoading,
              isDebtError: isDebtError,
              debtSummary: debtSummary,
              totalSelected: totalSelected,
              canSubmit: canSubmit,
              notAllowedReason: notAllowedReason,
            ),

            const SizedBox(height: 20),

            Text(
              'Thời hạn mượn',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            DropdownButton<int>(
              value: _days,
              isExpanded: true,
              onChanged: submitting
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _days = value);
                      }
                    },
              items: const [
                DropdownMenuItem(value: 7, child: Text('7 ngày')),
                DropdownMenuItem(value: 14, child: Text('14 ngày')),
                DropdownMenuItem(value: 30, child: Text('30 ngày')),
              ],
            ),

            const SizedBox(height: 16),

            const Text(
              'Phiếu sẽ được gửi để chờ duyệt. '
              'Sách chưa được mượn ngay sau khi gửi.',
            ),

            if (state is BorrowingSlipFailure) ...[
              const SizedBox(height: 12),
              Text(
                state.message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],

            const SizedBox(height: 24),

            FilledButton(
              onPressed: submitting || !canSubmit
                  ? null
                  : () => _submit(memberId),
              child: submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Gửi phiếu mượn'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtSummaryCard({
    required String memberId,
    required bool isDebtLoading,
    required bool isDebtError,
    required MemberDebtSummary? debtSummary,
    required int totalSelected,
    required bool canSubmit,
    required String? notAllowedReason,
  }) {
    if (isDebtLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Đang kiểm tra hạn mức mượn sách...')),
            ],
          ),
        ),
      );
    }

    if (isDebtError || debtSummary == null) {
      return Card(
        color: Theme.of(
          context,
        ).colorScheme.errorContainer.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Không thể tải thông tin hạn mức mượn sách',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _loadDebtSummary(memberId),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: canSubmit
          ? Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  canSubmit ? Icons.verified_outlined : Icons.info_outline,
                  size: 20,
                  color: canSubmit
                      ? Colors.green
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Hạn mức mượn sách',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• Đang mượn: ${debtSummary.currentBorrowedCount}/${debtSummary.maxBorrowLimit} cuốn',
            ),
            Text('• Còn được mượn: ${debtSummary.remainingBorrowLimit} cuốn'),
            Text('• Đang chọn: $totalSelected cuốn'),
            const SizedBox(height: 6),
            if (canSubmit)
              const Text(
                'Đủ điều kiện gửi phiếu mượn',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                notAllowedReason ?? 'Không đủ điều kiện gửi phiếu mượn',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess(BorrowingSlipSuccess state) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Đã gửi phiếu mượn!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text('Mã phiếu: ${state.slip.slipNumber}'),
              const SizedBox(height: 8),
              const Text('Trạng thái: Chờ duyệt', textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('${state.slip.items.length} đầu sách'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Quay về danh sách sách'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
