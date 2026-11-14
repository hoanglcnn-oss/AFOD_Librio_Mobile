import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/app_toast.dart';
import '../../../../auth/bloc/auth_bloc.dart';
import '../../../../auth/bloc/auth_state.dart';
import '../../../../books/data/models/book.dart';
import '../../../../members/data/api_members_repository.dart';
import '../../../../members/data/member_resolver.dart';
import '../../../../members/data/members_repository.dart';
import '../../bloc/borrowing_slip_bloc.dart';
import '../../bloc/borrowing_slip_event.dart';
import '../../bloc/borrowing_slip_state.dart';
import '../../../shared/repositories/api_borrowing_slips_repository.dart';
import '../../../shared/repositories/borrowing_slips_repository.dart';
import '../../models/create_borrowing_slip_request.dart';
import '../widgets/borrow_confirm_card.dart';
import 'borrow_result_screen.dart';

class BorrowConfirmScreen extends StatelessWidget {
  final Book book;
  final BorrowingSlipsRepository? borrowingSlipsRepository;
  final MembersRepository? membersRepository;

  const BorrowConfirmScreen({
    super.key,
    required this.book,
    this.borrowingSlipsRepository,
    this.membersRepository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BorrowingSlipBloc(
        borrowingSlipsRepository:
            borrowingSlipsRepository ?? ApiBorrowingSlipsRepository(),
      ),
      child: _BorrowConfirmContent(
        book: book,
        membersRepository: membersRepository ?? ApiMembersRepository(),
      ),
    );
  }
}

class _BorrowConfirmContent extends StatefulWidget {
  final Book book;
  final MembersRepository membersRepository;

  const _BorrowConfirmContent({
    required this.book,
    required this.membersRepository,
  });

  @override
  State<_BorrowConfirmContent> createState() => _BorrowConfirmContentState();
}

class _BorrowConfirmContentState extends State<_BorrowConfirmContent> {
  late final MemberResolver _resolver;
  late Future<String?> _memberIdFuture;

  @override
  void initState() {
    super.initState();
    _resolver = MemberResolver(membersRepository: widget.membersRepository);
    _memberIdFuture = _resolveMember();
  }

  Future<String?> _resolveMember() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return null;
    }

    final user = authState.user;
    return _resolver.resolve(
      memberId: user.memberId,
      email: user.email,
      role: user.role,
    );
  }

  void _retryResolve() {
    setState(() {
      _memberIdFuture = _resolveMember();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BorrowingSlipBloc, BorrowingSlipState>(
      listener: (context, state) {
        if (state is BorrowingSlipSuccess) {
          Navigator.of(context)
              .push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => BorrowResultScreen(slip: state.slip),
                ),
              )
              .then((_) {
                if (!context.mounted) return;
                Navigator.of(context).pop(true);
              });
        }

        if (state is BorrowingSlipFailure) {
          AppToast.error(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Xác nhận mượn sách')),
        body: FutureBuilder<String?>(
          future: _memberIdFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildResolveError('Không thể tra cứu hồ sơ độc giả.');
            }

            final memberId = snapshot.data;

            if (memberId == null || memberId.isEmpty) {
              return _buildResolveError(
                'Không tìm thấy hồ sơ độc giả liên kết với tài khoản này.',
              );
            }

            return _buildConfirmation(memberId);
          },
        ),
      ),
    );
  }

  Widget _buildResolveError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _retryResolve,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmation(String memberId) {
    return BlocBuilder<BorrowingSlipBloc, BorrowingSlipState>(
      builder: (context, state) {
        final isSubmitting = state is BorrowingSlipSubmitting;
        final isSuccess = state is BorrowingSlipSuccess;

        return BorrowConfirmCard(
          book: widget.book,
          memberId: memberId,
          isSubmitting: isSubmitting,
          isSuccess: isSuccess,
          onConfirm: () {
            context.read<BorrowingSlipBloc>().add(
              CreateSlipRequested(
                CreateBorrowingSlipRequest(
                  memberId: memberId,
                  expectedReturnDays: 14,
                  items: [
                    BorrowingSlipItemRequest(
                      bookId: widget.book.id,
                      quantity: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
