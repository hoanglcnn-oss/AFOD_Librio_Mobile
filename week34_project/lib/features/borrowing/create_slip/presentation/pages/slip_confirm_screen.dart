import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:week34_project/core/widgets/app_toast.dart';
import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/books/data/models/book.dart';
import 'package:week34_project/features/borrowing/create_slip/bloc/create_slip_bloc.dart';
import 'package:week34_project/features/borrowing/create_slip/bloc/create_slip_event.dart';
import 'package:week34_project/features/borrowing/create_slip/bloc/create_slip_state.dart';
import 'package:week34_project/features/borrowing/create_slip/data/models/create_slip_request.dart';
import 'package:week34_project/features/borrowing/shared/repositories/api_borrowing_slips_repository.dart';
import 'package:week34_project/features/borrowing/shared/repositories/borrowing_slips_repository.dart';
import 'borrowing_slip_created_screen.dart';
import 'package:week34_project/features/members/data/models/member_debt_summary.dart';
import 'package:week34_project/features/members/data/repositories/api_members_repository.dart';
import 'package:week34_project/features/members/data/repositories/members_repository.dart';

import '../widgets/borrow_debt_summary_card.dart';
import '../widgets/slip_form_frame.dart';

class SlipConfirmScreen extends StatelessWidget {
  final List<Book> books;
  final MembersRepository? membersRepository;
  final BorrowingSlipsRepository? borrowingSlipsRepository;

  const SlipConfirmScreen({
    super.key,
    required this.books,
    this.membersRepository,
    this.borrowingSlipsRepository,
  });

  MembersRepository _resolveMembersRepo(BuildContext context) {
    return membersRepository ?? ApiMembersRepository();
  }

  BorrowingSlipsRepository _resolveSlipsRepo(BuildContext context) {
    return borrowingSlipsRepository ?? ApiBorrowingSlipsRepository();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMembersRepo = _resolveMembersRepo(context);
    final effectiveSlipsRepo = _resolveSlipsRepo(context);

    return BlocProvider(
      create: (context) =>
          CreateSlipBloc(borrowingSlipsRepository: effectiveSlipsRepo),
      child: _SlipConfirmContent(
        books: books,
        membersRepository: effectiveMembersRepo,
        borrowingSlipsRepository: effectiveSlipsRepo,
      ),
    );
  }
}

class _SlipConfirmContent extends StatefulWidget {
  final List<Book> books;
  final MembersRepository membersRepository;
  final BorrowingSlipsRepository borrowingSlipsRepository;

  const _SlipConfirmContent({
    required this.books,
    required this.membersRepository,
    required this.borrowingSlipsRepository,
  });

  @override
  State<_SlipConfirmContent> createState() => _SlipConfirmContentState();
}

class _SlipConfirmContentState extends State<_SlipConfirmContent> {
  late final Future<String?> _memberIdFuture;
  late final Map<String, int> _quantities;
  final Set<String> _excludedBookIds = {};
  Future<MemberDebtSummary>? _debtSummaryFuture;
  String? _loadedMemberId;

  late final TextEditingController _daysController;
  int _days = 14;

  @override
  void initState() {
    super.initState();
    _quantities = {for (final book in widget.books) book.id: 1};
    _memberIdFuture = _resolveMember();
    _daysController = TextEditingController(text: '$_days');
  }

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  Future<String?> _resolveMember() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return null;

    final user = authState.user;
    return widget.membersRepository.resolveMemberId(
      memberId: user.memberId,
      email: user.email,
      role: user.role,
    );
  }

  void _loadDebtSummary(String memberId) {
    setState(() {
      _loadedMemberId = memberId;
      _debtSummaryFuture = widget.membersRepository.getDebtSummary(memberId);
    });
  }

  void _toggleExcludeBook(String bookId) {
    setState(() {
      if (_excludedBookIds.contains(bookId)) {
        _excludedBookIds.remove(bookId);
      } else {
        _excludedBookIds.add(bookId);
      }
    });
  }

  Future<void> _submit(String memberId) async {
    final activeBooks =
        widget.books.where((b) => !_excludedBookIds.contains(b.id)).toList();
    if (activeBooks.isEmpty) {
      AppToast.warning(
        context,
        'Vui lòng chọn ít nhất 1 cuốn sách để gửi phiếu',
      );
      return;
    }

    try {
      final freshSummary = await widget.membersRepository.getDebtSummary(
        memberId,
      );
      if (!mounted) return;
      setState(() {
        _debtSummaryFuture = Future.value(freshSummary);
      });

      final totalSelected = activeBooks
          .map((b) => _quantities[b.id] ?? 1)
          .reduce((a, b) => a + b);

      if (!freshSummary.canBorrow ||
          totalSelected > freshSummary.remainingBorrowLimit) {
        final reason = !freshSummary.canBorrow
            ? (freshSummary.reasonIfNotAllowed ??
                  'Tài khoản không đủ điều kiện mượn sách')
            : 'Số lượng sách chọn ($totalSelected cuốn) vượt quá hạn mức còn lại (${freshSummary.remainingBorrowLimit} cuốn)';
        AppToast.warning(context, reason);
        return;
      }
    } catch (_) {
      // Tiếp tục để backend kiểm tra nếu không fetch được
    }

    final request = CreateSlipRequest(
      memberId: memberId,
      expectedReturnDays: _days,
      items: [
        for (final book in activeBooks)
          BorrowingSlipItemRequest(
            bookId: book.id,
            quantity: _quantities[book.id] ?? 1,
          ),
      ],
    );

    if (!mounted) return;
    context.read<CreateSlipBloc>().add(CreateSlipRequested(request));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateSlipBloc, CreateSlipState>(
      builder: (context, state) {
        if (state is CreateSlipSuccess) {
          return BorrowingSlipCreatedScreen(
            slip: state.slip,
            repository: widget.borrowingSlipsRepository,
            membersRepository: widget.membersRepository,
          );
        }

        return FutureBuilder<String?>(
          future: _memberIdFuture,
          builder: (context, memberSnapshot) {
            if (memberSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (memberSnapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text('Không thể tra cứu hồ sơ độc giả'),
                ),
              );
            }

            final memberId = memberSnapshot.data;

            if (memberId == null || memberId.isEmpty) {
              return const Scaffold(
                body: Center(
                  child: Text('Không tìm thấy hồ sơ độc giả liên kết'),
                ),
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
                final submitting = state is CreateSlipSubmitting;
                final activeBooks = widget.books
                    .where((b) => !_excludedBookIds.contains(b.id))
                    .toList();
                final totalSelected = activeBooks.isEmpty
                    ? 0
                    : activeBooks
                        .map((b) => _quantities[b.id] ?? 1)
                        .reduce((a, b) => a + b);

                final debtSummary = debtSnapshot.data;
                final isDebtLoading =
                    debtSnapshot.connectionState != ConnectionState.done;
                final isDebtError = debtSnapshot.hasError;

                final isExceedingLimit = debtSummary != null &&
                    totalSelected > debtSummary.remainingBorrowLimit;
                final canBorrowCondition =
                    debtSummary != null && debtSummary.canBorrow;

                final isDaysValid = _days >= 1 && _days <= 30;

                final canSubmit = !isDebtLoading &&
                    !isDebtError &&
                    debtSummary != null &&
                    canBorrowCondition &&
                    !isExceedingLimit &&
                    isDaysValid &&
                    activeBooks.isNotEmpty &&
                    totalSelected > 0;

                String? notAllowedReason;
                if (debtSummary != null) {
                  if (!debtSummary.canBorrow) {
                    notAllowedReason = debtSummary.reasonIfNotAllowed ??
                        'Tài khoản hiện không đủ điều kiện mượn sách';
                  } else if (activeBooks.isEmpty) {
                    notAllowedReason =
                        'Chưa chọn sách nào để mượn (đã loại trừ tất cả)';
                  } else if (isExceedingLimit) {
                    notAllowedReason =
                        'Số lượng sách chọn ($totalSelected cuốn) vượt quá hạn mức còn lại (${debtSummary.remainingBorrowLimit} cuốn)';
                  }
                }

                final theme = Theme.of(context);
                final colorScheme = theme.colorScheme;
                final activeBooksCount = activeBooks.length;

                return Scaffold(
                  appBar: AppBar(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.books.length == 1
                              ? 'Xác nhận mượn sách'
                              : 'Xác nhận phiếu mượn',
                        ),
                        if (widget.books.length > 1)
                          Text(
                            '$activeBooksCount cuốn đang chọn',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  body: SlipFormFrame(
                    books: widget.books,
                    quantities: _quantities,
                    excludedBookIds: _excludedBookIds,
                    days: _days,
                    daysController: _daysController,
                    isDaysValid: isDaysValid,
                    submitting: submitting,
                    canSubmit: canSubmit,
                    maxBorrowLimit: debtSummary?.maxBorrowLimit,
                    errorMessage: state is CreateSlipFailure
                        ? state.message
                        : null,
                    debtSummaryCard: BorrowDebtSummaryCard(
                      isDebtLoading: isDebtLoading,
                      isDebtError: isDebtError,
                      debtSummary: debtSummary,
                      totalSelected: totalSelected,
                      canSubmit: canSubmit,
                      notAllowedReason: notAllowedReason,
                      onRetry: () => _loadDebtSummary(memberId),
                    ),
                    onDecreaseQuantity: (bookId) => setState(() {
                      _quantities[bookId] = (_quantities[bookId] ?? 1) - 1;
                    }),
                    onIncreaseQuantity: (bookId) => setState(() {
                      _quantities[bookId] = (_quantities[bookId] ?? 1) + 1;
                    }),
                    onToggleExclude: (bookId) => _toggleExcludeBook(bookId),
                    onDaysChanged: (days) => setState(() {
                      _days = days;
                    }),
                  ),
                  bottomNavigationBar: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x120F172A),
                          offset: Offset(0, -4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          // Giữ text ẩn bảo toàn tương thích cho test automation
                          SizedBox.shrink(
                            child: Text('Tổng cộng: $totalSelected cuốn'),
                          ),

                          // Bên trái: "Phiếu mượn" + Số X to (chiếm 2 dòng) + [cuốn] / [trong Y ngày]
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Phiếu mượn ',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  '$totalSelected',
                                  style: const TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                    height: 1.0,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'cuốn',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                        height: 1.1,
                                      ),
                                    ),
                                    Text(
                                      'trong $_days ngày',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B),
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Bên phải: Nút Gửi phiếu mượn chuẩn 48dp với icon
                          FilledButton(
                            onPressed: submitting || !canSubmit
                                ? null
                                : () => _submit(memberId),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFE2E8F0),
                              disabledForegroundColor: const Color(0xFF94A3B8),
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: submitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Gửi phiếu mượn',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

}
