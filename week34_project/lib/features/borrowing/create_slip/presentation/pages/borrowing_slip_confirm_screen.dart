import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/app_toast.dart';
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
import '../../../shared/repositories/api_borrowing_slips_repository.dart';
import '../../../shared/repositories/borrowing_slips_repository.dart';
import '../../models/create_borrowing_slip_request.dart';
import '../widgets/borrow_debt_summary_card.dart';
import '../widgets/borrow_slip_form_card.dart';

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

  Future<void> _submit(String memberId) async {
    // Refresh getDebtSummary() trước khi gửi phiếu để tránh dữ liệu hạn mức cũ
    try {
      final freshSummary = await widget.membersRepository.getDebtSummary(
        memberId,
      );
      if (!mounted) return;
      setState(() {
        _debtSummaryFuture = Future.value(freshSummary);
      });

      final totalSelected = _quantities.values.isEmpty
          ? 0
          : _quantities.values.reduce((a, b) => a + b);

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

    if (!mounted) return;
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
                  final submitting = state is BorrowingSlipSubmitting;
                  final totalSelected = _quantities.values.isEmpty
                      ? 0
                      : _quantities.values.reduce((a, b) => a + b);

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
                      isDaysValid;

                  String? notAllowedReason;
                  if (debtSummary != null) {
                    if (!debtSummary.canBorrow) {
                      notAllowedReason = debtSummary.reasonIfNotAllowed ??
                          'Tài khoản hiện không đủ điều kiện mượn sách';
                    } else if (isExceedingLimit) {
                      notAllowedReason =
                          'Số lượng sách chọn ($totalSelected cuốn) vượt quá hạn mức còn lại (${debtSummary.remainingBorrowLimit} cuốn)';
                    }
                  }

                  return BorrowSlipFormCard(
                    books: widget.books,
                    quantities: _quantities,
                    days: _days,
                    daysController: _daysController,
                    isDaysValid: isDaysValid,
                    submitting: submitting,
                    canSubmit: canSubmit,
                    maxBorrowLimit: debtSummary?.maxBorrowLimit,
                    errorMessage: state is BorrowingSlipFailure
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
                    onDaysChanged: (days) => setState(() {
                      _days = days;
                    }),
                    onSubmit: () => _submit(memberId),
                  );
                },
              );
            },
          );
        },
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
